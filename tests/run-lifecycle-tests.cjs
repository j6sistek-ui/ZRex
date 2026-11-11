const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '..',
  'mod/scripts/zm_owner_zrex_poc.gsc'), 'utf8');
function extract(name, inputs) {
  const declarations = [...source.matchAll(new RegExp(
    'function ' + name + '\\s*\\(([^)]*)\\)\\s*\\{([\\s\\S]*?)^\\}', 'gm'))];
  assert.equal(declarations.length, 1, 'Extract exactly one authored ' + name);
  const declaration = declarations[0];
  assert.deepEqual(declaration[1].split(',').map(value => value.trim()), inputs);
  return declaration;
}
const inputs = ['created_agent', 'requested', 'returned', 'same_instance',
  'actor_alive', 'actor_agent', 'fresh_alive', 'fresh_agent'];

// Execute the actual, unchanged GSC helper body: this small function also has
// valid JavaScript syntax. These two stubs model only boolean/0/1/unknown input
// flags. This is not a GSC VM, native entity lookup, or a test of frame timing.
const istrue = value => value === true || value === 1;
const isdefined = value => value !== undefined && value !== null;
function pure(name, parameters) {
  const declaration = extract(name, parameters);
  assert.match(declaration[2].trim(), /^return[\s\S]*;$/,
    name + ' must remain a pure return expression');
  return new Function('istrue', 'isdefined',
    'return (' + declaration[0] + ');')(istrue, isdefined);
}
const terminal = pure('owner_zrex_terminal_transition', inputs);
let checked = 0;

// Only the first four flags true and the final four false may pass. This covers
// every alive/dead/agent combination in both views, including disagreement,
// missing request/return proof, and a different fresh entity.
for (const numeric of [false, true]) {
  for (let mask = 0; mask < 256; mask++) {
    const flags = inputs.map((_, bit) => numeric
      ? Number(Boolean(mask & (1 << bit))) : Boolean(mask & (1 << bit)));
    assert.equal(terminal(...flags), mask === 15,
      'Terminal truth table: ' + JSON.stringify(Object.fromEntries(
        inputs.map((input, index) => [input, flags[index]]))));
    checked++;
  }
}

const klausInputs = ['created_agent', 'fenced_despawn', 'requested', 'returned',
  'watched_death', 'same_instance', 'actor_alive', 'fresh_alive'];
const klaus = pure('owner_zrex_klaus_terminated', klausInputs);
// Accepted bit patterns: a proved completed despawn (47), or a captured death
// event (49..63 odd) independent of the three unused despawn flags. All require
// the originally observed agent, identical instance, and both views nonalive.
const acceptedMasks = new Set([47, 49, 51, 53, 55, 57, 59, 61, 63]);
for (const numeric of [false, true]) {
  for (let mask = 0; mask < 256; mask++) {
    const flags = klausInputs.map((_, bit) => numeric
      ? Number(Boolean(mask & (1 << bit))) : Boolean(mask & (1 << bit)));
    assert.equal(klaus(...flags), acceptedMasks.has(mask), 'Klaus truth table mask ' + mask);
    checked++;
  }
}
for (const route of [
  {name: 'fenced despawn', flags: [true, true, true, true, false, true, false, false], optional: [4]},
  {name: 'captured death', flags: [true, false, false, false, true, true, false, false], optional: [1, 2, 3]}
]) {
  for (const unknown of [undefined, null]) {
    for (let index = 0; index < klausInputs.length; index++) {
      const flags = route.flags.slice();
      flags[index] = unknown;
      assert.equal(klaus(...flags), route.optional.includes(index),
        route.name + ': unknown ' + klausInputs[index] + ' (' + String(unknown) + ')');
      checked++;
    }
  }
}

// Exercise the real removal wrapper against a SMALL MOCKED NATIVE BOUNDARY.
// Translate its one GSC receiver-call spelling and declare its implicit locals;
// do not implement threads, an engine VM, actor disposal, or real frame timing.
const removalBody = extract('owner_zrex_removed', ['ticket'])[2]
  .replace(/actor\s+getentitynumber\(\)/g, 'getentitynumber(actor)');
function fixture() {
  const actor = {id: 59, alive: true, agent: true};
  const world = {actor, fresh: actor, time: 1000};
  const ticket = {factory_returned: true, actor, actor_id: 59,
    profile: {kind: 'uber_klaus'}, created_as_agent: true};
  const removed = new Function('istrue', 'isdefined', 'isint', 'getentbynum', 'gettime',
    'isalive', 'isagent', 'getentitynumber', 'owner_zrex_klaus_terminated',
    'owner_zrex_terminal_transition', 'ticket',
    '"use strict"; let fresh, actor, fenced_kill, watched_death, terminal, same_owned_instance;\n' + removalBody)
    .bind(null, istrue, isdefined, Number.isInteger,
      id => id === 59 ? world.fresh : undefined, () => world.time,
      actor => actor.alive, actor => actor.agent, actor => actor.id, klaus, terminal, ticket);
  return {world, ticket, removed};
}
function fencedDeath(f) {
  f.ticket.despawn_actor = f.world.actor;
  f.ticket.despawn_fenced_alive = true;
  f.ticket.native_despawn_requested = true;
  f.ticket.native_despawn_returned = true;
  f.world.actor.alive = false;
  // Native retest: dead actor still isagent, and custom owner marker is gone.
}
let stateChecks = 0;
function state(f, expected, message) {
  assert.equal(f.removed(), expected, message);
  stateChecks++;
}
let f = fixture();
f.ticket.factory_returned = false;
f.ticket.actor = undefined;
state(f, false, 'Unresolved factory with no handle remains reserved');
f.ticket.factory_returned = true;
state(f, true, 'Known empty factory return can release');
f = fixture();
f.world.fresh = undefined;
state(f, true, 'Native slot absence remains a valid proof');
f = fixture();
fencedDeath(f);
state(f, false, 'Owned dead Klaus starts an observation despite retained agent type');
state(f, false, 'A repeated call at the same native timestamp cannot release');
f.world.time++;
state(f, true, 'Later matching dead observation accepts captured native termination');
assert.equal(f.world.actor.agent, true, 'The test did not simulate a change to non-agent');
f = fixture();
f.world.actor.alive = false;
f.ticket.death_watched_actor = f.world.actor;
f.ticket.native_death_seen = true;
state(f, false, 'Captured natural death starts observation without a despawn call');
f.world.time++;
state(f, true, 'Captured natural death can finish without unused despawn flags');
f = fixture();
fencedDeath(f);
state(f, false, 'Start a first sample before a state reversal');
f.world.time++;
f.world.actor.alive = true;
state(f, false, 'Living observation rejects and resets terminal evidence');
assert.equal(f.ticket.nonagent_observed_at, undefined, 'Nonterminal sample resets time');
f.world.actor.alive = false;
state(f, false, 'Return to dead state requires a new first sample');
f.world.time++;
state(f, true, 'A new later sample can finish after reset');
for (const [name, change] of [
  ['unproved death', f => {f.ticket.despawn_fenced_alive = false;}],
  ['wrong captured despawn actor', f => {f.ticket.despawn_actor = {};}],
  ['wrong watched actor', f => {f.ticket.despawn_fenced_alive = false; f.ticket.native_death_seen = true; f.ticket.death_watched_actor = {};}],
  ['different fresh slot occupant', f => {f.world.fresh = Object.freeze({id: 59, alive: false, agent: true});}],
  ['unknown actor alive state', f => {f.world.actor.alive = undefined;}],
  ['missing saved native ID', f => {f.ticket.actor_id = undefined;}],
  ['Z-Rex still-agent body', f => {f.ticket.profile.kind = 'zrex'; f.world.actor.owner_zrex_ticket = f.ticket;}]
]) {
  f = fixture();
  fencedDeath(f);
  change(f);
  state(f, false, 'Reject ' + name);
  f.world.time++;
  state(f, false, 'Elapsed time cannot repair ' + name);
}

// Unknown status must not silently become proof of a false native state.
for (const unknown of [undefined, null]) {
  for (let index = 0; index < inputs.length; index++) {
    const flags = [true, true, true, true, false, false, false, false];
    flags[index] = unknown;
    assert.equal(terminal(...flags), false,
      'Reject unknown ' + inputs[index] + ' (' + String(unknown) + ')');
    checked++;
  }
}

// A separate source-contract regression for the real startup defect: the
// readiness code compares string names, so both getters must request strings.
const readiness = source.match(
  /function owner_zrex_wait_for_klaus\s*\([^)]*\)\s*\{([\s\S]*?)^\}/m);
assert.ok(readiness, 'Find the Klaus readiness function');
for (const part of ['base', 'spawn_reveal']) {
  const calls = [...readiness[1].matchAll(new RegExp(
    'getscriptablepartstate\\s*\\(\\s*"' + part + '"([^)]*)\\)', 'g'))];
  assert.equal(calls.length, 1, 'One readiness getter for ' + part);
  assert.match(calls[0][1], /^\s*,\s*1\s*$/,
    part + ' getter must explicitly request its string state');
}

console.log('ALL LIFECYCLE PREDICATE CHECKS PASSED ' + checked);
console.log('MOCKED REMOVAL WRAPPER CHECKS PASSED ' + stateChecks);
console.log('STRING-GETTER SOURCE CONTRACTS PASSED 2; native lifecycle and gameplay untested');
