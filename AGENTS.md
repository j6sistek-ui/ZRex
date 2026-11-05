# Prototype scope

This is newly authored mod source, tests and documentation. Keep stock game files, third-party mod source, saves, captures, downloaded compilers and credentials outside this project. Never target the retail Steam tree.

The owner requires full-size Z-Rex on every Zombies map. Version 0.3.0 explicitly defaults to Uber Klaus as an interim validation profile for the same one-per-player, 240-second controller; `owner_ally_profile=zrex` retains the original actor. Never silently substitute profiles. Test actual native dependencies, initialized AI, creature navigation, allegiance and deletion; there is no fixed Rex-only allowlist. Gate Z-Rex-only legs/mount/encounter handling by profile. Suppress only the owned Klaus's core ejection, without changing map enemies. Cross-map loading and gameplay remain unverified. Both profiles replace Dark Flare and its augment aliases. The separately installed Blood Burner/Healing Aura package is independent. A source or mocked-menu pass is not gameplay acceptance.

`addons/twins-armory` is a separate authored package for a fixed 500-salvage native Twins Mask purchase on Rex Infernus. It appends one cloned record to the native Ammo Mods category and lets the stock grid own focus, scrolling and input. Preserve all original records, category/filter contracts and other purchase menus. The former floating button and manual focus-edge splice were inaccessible in an owner test and are superseded. Keep server checks and do not broaden map support or bundle third-party Blood Burner source.

## Checks and container workflow

Prefer `docker build -t zrex-ally-tests .` followed by `docker run --rm zrex-ally-tests` for menu tests. The image installs only the lockfile-pinned test dependency with lifecycle scripts disabled. Do not install host system packages. If Docker is unavailable, an existing Node runtime and workspace-only dependencies can run `npm test`.

Native game compilation requires the existing publisher-bundled Windows ACTS compiler. Compile into an artifact directory outside `mod/`, with `--noUpdater -N -H -t gscc <source> -g bo7 --name custom_scripts/zm_owner_zrex_poc.gsc -o <output>` and `--noUpdater -N -H -t hksc <lua-source> <output.luac>`. Do not run compilation from an installation currently being moved.

Compilation does not validate production linkage. Run `python tests/audit-production-imports.py --exe <installed-offline-game.exe> --output <local-report.json> <main.gscc> <receiver.gscc>` with an existing Python runtime before a game retest. The check reads the supplied BO7 VM 0x1a artifacts and PE builtin metadata, rejecting developer-only functions, unresolved native calls and invalid argument counts. It explicitly allows three separately verified Kronos v1.41 storage builtins. Revalidate custom registration for another version. Loaded-script export resolution and actual linking still need a fresh match. Keep reports and all supplied binaries outside the repo.

For integration tests, `BIKE_MENU_LUA` may point to a user's separately supplied local Blood Burner menu source. It is not committed here. Default tests use an original minimal hook fixture.

Run a fresh offline match to validate native linking, asset residency before the quest, clearance, actual hostile HP reduction, player protection, wave accounting, timeout, disconnect and cleanup. Preserve the authentic boss and its map objects. Do not claim these gates from mocks or compilation. Do not shrink the actor until the full-size proof passes.

Create a PR for repository changes and never merge automatically. The owner must supply or approve a source repository before publishing this new project.
