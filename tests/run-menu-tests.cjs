const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const project = path.resolve(__dirname, '..');
const cli = process.env.FENGARI_CLI || require.resolve('fengari-node-cli/src/lua-cli.js');
const bike = process.env.BIKE_MENU_LUA || path.join(__dirname, 'bike-hook-fixture.lua');
if (!fs.existsSync(bike)) throw Error('The supplied bike menu source does not exist.');
for (const order of ['bike-first', 'rex-first']) {
  const result = spawnSync(process.execPath, [cli, path.join(__dirname, 'menu.lua'), order,
    path.join(project, 'mod/lua/owner_zrex_menu_post.lua'), bike,
    path.join(__dirname, 'game-mode-fixture.lua')], { encoding: 'utf8' });
  process.stdout.write(result.stdout || '');
  process.stderr.write(result.stderr || '');
  if (result.status !== 0 || !result.stdout.includes('ALL MENU CHECKS PASSED ' + order)) process.exit(1);
}
