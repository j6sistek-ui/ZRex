# ALLY -FieldUpgrade scope

This is newly authored mod source, tests and documentation. Keep stock game files, third-party mod source, saves, captures, downloaded compilers and credentials outside this project. Never target the retail Steam tree.

The exact package and field-upgrade display name is `ALLY -FieldUpgrade`. Preserve the existing `owner_zrex_poc` folder, source filenames, engine identifiers and `owner_ally_profile` values; this display rename does not migrate the installation or change profile selection.

The owner requires full-size Z-Rex on every Zombies map. Version 0.3 explicitly defaults to Uber Klaus as an interim validation profile for the same one-per-player, 240-second controller; `owner_ally_profile=zrex` retains the original actor. Never silently substitute profiles. Test actual native dependencies, initialized AI, creature navigation, allegiance and deletion; there is no fixed Rex-only allowlist. Gate Z-Rex-only legs/mount/encounter handling by profile. Suppress only the owned Klaus's core ejection, without changing map enemies. Cross-map loading and gameplay remain unverified. Both profiles replace Dark Flare and its augment aliases. The separately installed Blood Burner/Healing Aura package is independent. A source or mocked-menu pass is not gameplay acceptance.

The first Klaus runtime failed setup immediately and generic `delete()` left a live agent. Version 0.3.1 uses a unique summon-key reservation and stock agent despawn. Its Totenreich retest passed factory checks and produced a fighting actor, then failed the 15-second readiness gate and retained a dead handle with the owner locked. No full-controller acceptance was recorded.

Version 0.3.2-poc (`ally3`) recorded native readiness and the turn-helper return on `zm_sat_hornet`, then rejected the creature exit query. Native despawn left the same dead agent handle while clearing its custom ownership field; requiring a non-agent type and that post-death field could not release the reservation.

The 0.3.3-poc (`ally4`) retests on Paradox and Ashes passed native readiness and conversion, but all 24 actor-reachable projection queries returned undefined. Both maps confirmed forced setup retirement and release; Ashes then created and retired a second summon in the same match. Successful navigation, natural death and the full 240-second lifetime remain unverified.

Candidate 0.3.4-poc (`ally5`) tries the stock-attractor query, actor-reachable query and nearest-point query for Klaus, storing native point/path results on the ticket. Preserve snap and complete-path endpoint checks for every distant projection, plus the separate exit minimum. Z-Rex retains only its original generic route. Do not describe this as a proven compiler fix: installed bytecode used the same cached slot for both branch stores and the following read.

Klaus retirement accepts captured pre-death ownership plus either a fenced native despawn request/return or the captured actor's native death event, followed by two distinct-time dead observations of the same retained/fresh actor. Do not require native agent type or erased ownership fields to change after death. Keep the absent-handle/empty-slot proof and the separate, stricter Z-Rex path. Never release on a bare dead-state reading, elapsed time or helper return alone; never touch another slot occupant. Released tickets must stop old expiry/despawn work. Retest natural death, expiry and a replacement surviving the old ticket's deadline.

`addons/twins-armory` is a separate authored package for a fixed 500-salvage native Twins Mask purchase on Rex Infernus. It appends one cloned record to the native Ammo Mods category and lets the stock grid own focus, scrolling and input. Preserve all original records, category/filter contracts and other purchase menus. The former floating button and manual focus-edge splice were inaccessible in an owner test and are superseded. Keep server checks and do not broaden map support or bundle third-party Blood Burner source.

## Checks and container workflow

Prefer `docker build -t zrex-ally-tests .` followed by `docker run --rm zrex-ally-tests` for menu tests. The image installs only the lockfile-pinned test dependency with lifecycle scripts disabled. Do not install host system packages. If Docker is unavailable, an existing Node runtime and workspace-only dependencies can run `npm test`.

The lifecycle tests execute the actual pure GSC predicates and the removal wrapper with mocked lookup/time/state boundaries and a narrow receiver-call syntax translation. They verify policy branches, not native event delivery, actual actor retirement or engine frame timing.

The navigation tests execute the actual profile and reachable-point helper with mocked query/path boundaries and narrow receiver-call/array syntax adaptation. They verify fallback order and path rejection rules, not native navigation or compiler behavior. Both suites run through `npm test` in the existing container workflow.

Native game compilation requires the existing publisher-bundled Windows ACTS compiler. Compile into an artifact directory outside `mod/`, with `--noUpdater -N -H -t gscc <source> -g bo7 --name custom_scripts/zm_owner_zrex_poc.gsc -o <output>` and `--noUpdater -N -H -t hksc <lua-source> <output.luac>`. Do not run compilation from an installation currently being moved.

Compilation does not validate production linkage. Run `python tests/audit-production-imports.py --exe <installed-offline-game.exe> --output <local-report.json> <main.gscc> <receiver.gscc>` with an existing Python runtime before a game retest. The check reads the supplied BO7 VM 0x1a artifacts and PE builtin metadata, rejecting developer-only functions, unresolved native calls and invalid argument counts. It explicitly allows three separately verified Kronos v1.41 storage builtins. Revalidate custom registration for another version. Loaded-script export resolution and actual linking still need a fresh match. Keep reports and all supplied binaries outside the repo.

For integration tests, `BIKE_MENU_LUA` may point to a user's separately supplied local Blood Burner menu source. It is not committed here. Default tests use an original minimal hook fixture.

Run a fresh offline match to validate native linking, asset residency before the quest, clearance, actual hostile HP reduction, player protection, wave accounting, timeout, disconnect and cleanup. Preserve the authentic boss and its map objects. Do not claim these gates from mocks or compilation. Do not shrink the actor until the full-size proof passes.

Use the existing [source PR](https://github.com/j6sistek-ui/ZRex/pull/1) for repository changes. Keep it draft and unmerged pending owner validation; never merge automatically. Publish only authored source, tests and documentation.
