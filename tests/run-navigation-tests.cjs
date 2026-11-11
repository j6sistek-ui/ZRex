const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '..',
  'mod/scripts/zm_owner_zrex_poc.gsc'), 'utf8');
function extract(name, parameters) {
  const matches = [...source.matchAll(new RegExp(
    'function ' + name + '\\s*\\(([^)]*)\\)\\s*\\{([\\s\\S]*?)^\\}', 'gm'))];
  assert.equal(matches.length, 1, 'Extract exactly one authored ' + name);
  const inputs = matches[0][1].trim();
  assert.deepEqual(inputs ? inputs.split(',').map(value => value.trim()) : [], parameters);
  return matches[0][2];
}

// Execute the actual helper bodies with a small mocked native boundary. Declare
// GSC's implicit locals, translate its two actor-receiver call spellings and
// array .size access. This is not a GSC VM or a native pathfinding test; it cannot
// diagnose compiler behavior or prove that a query returns a point in a match.
const body = extract('owner_zrex_reachable', ['actor', 'position'])
  .replace(/actor\s+(getclosestreachablepointonnavmesh|findpath)\s*\(/g, 'actor.$1(')
  .replace(/ticket\.nav_path\.size\b/g, 'ticket.nav_path.length');
const isdefined = value => value !== undefined && value !== null;
const distanceSquared = (a, b) => a.reduce((sum, value, index) => sum + (value - b[index]) ** 2, 0);
const getProfile = new Function('getdvar', 'spawnstruct',
  '"use strict"; let kind, profile, rex;\n' + extract('owner_zrex_profile', []));
let cases = 0;
function run(name, test) {
  test();
  cases++;
  console.log('PASS navigation: ' + name);
}
function fixture(kind = 'uber_klaus', routes = {}) {
  const calls = [];
  const profile = getProfile(() => kind, () => ({}));
  const ticket = {profile};
  const actor = {origin: [0, 0, 0], owner_zrex_ticket: ticket};
  const position = [profile.exit_distance, 0, 0];
  let current;
  function project(route, target, receiver) {
    assert.strictEqual(target, position, 'Query receives the requested position');
    assert.strictEqual(receiver, actor, 'Query uses the summoned actor');
    calls.push(route);
    current = route;
    return routes[route]?.point;
  }
  actor.getclosestreachablepointonnavmesh = target => project('actor', target, actor);
  actor.findpath = (origin, point) => {
    assert.strictEqual(origin, actor.origin, 'Path begins at the current actor origin');
    assert.strictEqual(point, ticket.nav_point, 'Path tests the projected ticket point');
    calls.push('path:' + current);
    return routes[current]?.path;
  };
  const reachable = new Function('isdefined', 'isarray', 'distancesquared', 'distance', 'int',
    'function_9ad7279ee518d022', 'getclosestpointonnavmesh', 'actor', 'position',
    '"use strict"; let ticket, profile, routes, route;\n' + body)
    .bind(null, isdefined, Array.isArray, distanceSquared,
      (a, b) => Math.sqrt(distanceSquared(a, b)), Math.trunc,
      (target, receiver) => project('attractor', target, receiver),
      (target, receiver, ...options) => {
        assert.deepEqual(options, [1, 1, 1], 'Preserve the generic query arguments');
        return project('nearest', target, receiver);
      }, actor, position);
  return {actor, ticket, profile, position, routes, calls, reachable};
}
function full(f, route, point = f.position, endpoint = point) {
  f.routes[route] = {point, path: [f.actor.origin, endpoint]};
}
function reject(f, reason, count) {
  assert.equal(f.reachable(), undefined);
  assert.equal(f.ticket.nav_accepted_source, 'none');
  assert.equal(f.ticket[reason], count);
}

run('primary complete path short-circuits both fallbacks', () => {
  const f = fixture();
  full(f, 'attractor');
  assert.strictEqual(f.reachable(), f.position);
  assert.deepEqual(f.calls, ['attractor', 'path:attractor']);
  assert.equal(f.ticket.nav_accepted_source, 'zombie_attractor');
  assert.equal(f.ticket.nav_attractor_defined, true);
  assert.equal(f.ticket.nav_actor_defined, -1);
  assert.equal(f.ticket.nav_nearest_defined, -1);
});
run('missing primary falls back to the actor query', () => {
  const f = fixture();
  full(f, 'actor');
  assert.strictEqual(f.reachable(), f.position);
  assert.deepEqual(f.calls, ['attractor', 'actor', 'path:actor']);
  assert.equal(f.ticket.nav_no_projection, 1);
  assert.equal(f.ticket.nav_accepted_source, 'actor_reachable');
});
run('nearest fallback accepts only after a complete path', () => {
  const f = fixture();
  full(f, 'nearest');
  assert.strictEqual(f.reachable(), f.position);
  assert.deepEqual(f.calls, ['attractor', 'actor', 'nearest', 'path:nearest']);
  assert.equal(f.ticket.nav_no_projection, 2);
  assert.equal(f.ticket.nav_accepted_source, 'nearest_actor_nav');
});
run('partial primary and missing actor do not prevent a valid nearest path', () => {
  const f = fixture();
  full(f, 'attractor', f.position, f.actor.origin);
  full(f, 'nearest');
  assert.strictEqual(f.reachable(), f.position);
  assert.equal(f.ticket.nav_partial_path, 1);
  assert.equal(f.ticket.nav_no_projection, 1);
  assert.equal(f.ticket.nav_accepted_source, 'nearest_actor_nav');
});
run('all missing projections reject without calling findpath', () => {
  const f = fixture();
  reject(f, 'nav_no_projection', 3);
  assert.deepEqual(f.calls, ['attractor', 'actor', 'nearest']);
  assert.equal(f.ticket.nav_projection_attempts, 3);
});
for (const [name, result] of [['missing', undefined], ['empty', []], ['non-array', {}]]) {
  run(name + ' paths reject every defined projection', () => {
    const f = fixture();
    for (const route of ['attractor', 'actor', 'nearest']) {
      f.routes[route] = {point: f.position, path: result};
    }
    reject(f, 'nav_no_path', 3);
    assert.deepEqual(f.calls, ['attractor', 'path:attractor', 'actor', 'path:actor',
      'nearest', 'path:nearest']);
    assert.equal(f.ticket.nav_path_points, name === 'empty' ? 0 : -1);
  });
}
run('partial paths on every route cannot pass by projection alone', () => {
  const f = fixture();
  for (const route of ['attractor', 'actor', 'nearest']) full(f, route, f.position, f.actor.origin);
  reject(f, 'nav_partial_path', 3);
});
run('excessive snap rejects before any path call', () => {
  const f = fixture();
  const point = [f.position[0] + f.profile.nav_snap + 1, 0, 0];
  for (const route of ['attractor', 'actor', 'nearest']) full(f, route, point);
  reject(f, 'nav_snap_rejected', 3);
  assert.deepEqual(f.calls, ['attractor', 'actor', 'nearest']);
});
run('snap boundary is inclusive', () => {
  const f = fixture();
  const point = [f.position[0] + f.profile.nav_snap, 0, 0];
  full(f, 'nearest', point);
  assert.strictEqual(f.reachable(), point);
  assert.equal(f.ticket.nav_accepted_source, 'nearest_actor_nav');
});
run('path endpoint boundary is inclusive', () => {
  const f = fixture();
  full(f, 'nearest', f.position, [f.position[0] + f.profile.nav_close, 0, 0]);
  assert.strictEqual(f.reachable(), f.position);
});
run('nearest path ending beyond tolerance still rejects', () => {
  const f = fixture();
  full(f, 'nearest', f.position, [f.position[0] + f.profile.nav_close + 1, 0, 0]);
  reject(f, 'nav_partial_path', 1);
});
run('near-point shortcut cannot meet the separate exit minimum', () => {
  const f = fixture();
  // Query close enough to exercise the existing near-point shortcut itself;
  // ordinary exit queries are farther out and still retain their own minimum.
  f.position[0] = f.profile.nav_close - 1;
  full(f, 'attractor');
  const result = f.reachable();
  assert.strictEqual(result, f.position);
  assert.deepEqual(f.calls, ['attractor']);
  assert.ok(distanceSquared(result, f.actor.origin) < f.profile.exit_minimum ** 2);
  assert.ok(f.profile.nav_close < f.profile.exit_minimum);
});
run('Rex retains only its old generic route', () => {
  const f = fixture('zrex');
  full(f, 'nearest');
  assert.strictEqual(f.reachable(), f.position);
  assert.deepEqual(f.calls, ['nearest', 'path:nearest']);
  assert.equal(f.ticket.nav_projection_attempts, 1);
  assert.equal(f.ticket.nav_attractor_defined, -1);
  assert.equal(f.ticket.nav_actor_defined, -1);
});
run('missing Rex projection never invokes Klaus-specific fallbacks', () => {
  const f = fixture('zrex');
  full(f, 'attractor');
  full(f, 'actor');
  reject(f, 'nav_no_projection', 1);
  assert.deepEqual(f.calls, ['nearest']);
});
run('next query resets point/path state instead of reusing a prior success', () => {
  const f = fixture();
  full(f, 'attractor');
  assert.strictEqual(f.reachable(), f.position);
  delete f.routes.attractor;
  reject(f, 'nav_no_projection', 3);
  assert.equal(f.ticket.nav_point, undefined);
  assert.equal(f.ticket.nav_path, undefined);
  assert.equal(f.ticket.nav_queries, 2);
  assert.equal(f.ticket.nav_projection_attempts, 4);
});

console.log('MOCKED ACTUAL NAVIGATION HELPER CHECKS PASSED ' + cases +
  '; native query results, compiler behavior and gameplay untested');
