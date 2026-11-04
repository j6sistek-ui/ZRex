const path = require('node:path');
const { spawnSync } = require('node:child_process');
const project = path.resolve(__dirname, '..');
const cli = process.env.FENGARI_CLI || require.resolve('fengari-node-cli/src/lua-cli.js');
const addon = path.join(project, 'addons/twins-armory');
const result = spawnSync(process.execPath, [cli,
  path.join(addon, 'tests/menu.lua'), path.join(addon, 'mod/lua/owner_twins_armory_post.lua'),
  '500', path.join(addon, 'tests/game-mode-fixture.lua')], { encoding: 'utf8' });
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
if (result.status !== 0 || !result.stdout.includes('ALL TWINS MENU CHECKS PASSED 28')) process.exit(1);
