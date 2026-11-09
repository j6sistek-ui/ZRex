const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '..',
  'mod/scripts/zm_owner_zrex_poc.gsc'), 'utf8');
const name = 'owner_zrex_terminal_transition';
const declarations = [...source.matchAll(new RegExp(
  'function ' + name + '\\s*\\(([^)]*)\\)\\s*\\{([\\s\\S]*?)^\\}', 'gm'))];
assert.equal(declarations.length, 1, 'Extract exactly one authored terminal predicate');
const declaration = declarations[0];
const inputs = ['created_agent', 'requested', 'returned', 'same_instance',
  'actor_alive', 'actor_agent', 'fresh_alive', 'fresh_agent'];
assert.deepEqual(declaration[1].split(',').map(value => value.trim()), inputs);
assert.match(declaration[2].trim(), /^return[\s\S]*;$/,
  'The extracted helper must remain a pure return expression');

// Execute the actual, unchanged GSC helper body: this small function also has
// valid JavaScript syntax. These two stubs model only boolean/0/1/unknown input
// flags. This is not a GSC VM, native entity lookup, or a test of frame timing.
const istrue = value => value === true || value === 1;
const isdefined = value => value !== undefined && value !== null;
const terminal = new Function('istrue', 'isdefined',
  'return (' + declaration[0] + ');')(istrue, isdefined);
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
console.log('STRING-GETTER SOURCE CONTRACTS PASSED 2; native lifecycle and gameplay untested');
