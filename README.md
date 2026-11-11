# ALLY -FieldUpgrade

Replace Dark Flare with **Uber Klaus fighting on your side**. He stays for up to four minutes, or until he dies, and you can summon him again once the upgrade recharges and cleanup finishes. This first pass has been tested on Ashes of the Damned. Other maps still need testing.

The base upgrade and both augment variants keep their original loadout slots. The experimental full-size Z-Rex option is still available, but loading him across maps is unfinished. This repository contains original offline mod source, without game assets or third-party mod packages.

The display name covers both ally profiles. The existing `owner_zrex_poc` installation folder, source filenames, internal IDs and profile settings stay unchanged.

The separate [Twins Mask Arsenal addon](addons/twins-armory/README.md) extends the native Ammo Mods catalog on Rex Infernus. Its source and 36 native-contract checks are included independently of ALLY -FieldUpgrade; actual selection and purchase still need an owner retest.

The controller keeps the owner reserved until native absence or verified owned termination is confirmed, schedules native despawn independently of accessory cleanup, and attempts reachable hostile and owner-follow goals. A stuck close target can trigger a repositioning attempt. Z-Rex-specific parts, encounter guards and offspring cleanup apply only to that profile. The Klaus profile suppresses its own exploding-core ejection. The visual candidate refreshes the native friendly outline, hides only the summoned ally's native aim-target name/health bar, and adds a green owner-screen `ALLY: Uber Klaus` label after readiness, removed on retirement. A green overhead name is not implemented; these visuals require an in-game retest.

## Compatibility and status

The requested target is every Zombies map. There is no fixed map allowlist. The selected profile must resolve to available AI/settings and usable creature navigation in the current match. Missing definitions produce a refunded attempt; an unavailable Z-Rex never silently becomes Klaus. This code does not provide a general fastfile loader or prove every map is supported. The passive receiver script remains a Z-Rex inventory and never spawns anything.

The earlier owner-run Ashes test confirmed that the previous scripts linked, but its candidate Z-Rex chain was unavailable. The bike worked there. The first Klaus test produced a live actor and a hostile-damage callback, but immediately rejected setup and later blocked another summon. That test did not reach friendly conversion or controller acceptance. The inspected Z-Rex donor is in Rex's map package; a usable all-map import/load route remains unfinished. See [cross-map status](docs/CROSS_MAP_STATUS.md).

Version 0.3.0 adds an explicit resident-enemy validation profile. Both profiles use the same four-minute limit, one-owner reservation, friendly conversion, player-damage guard and native retirement checks. Klaus uses smaller placement distances and its own initialization checks. Only Z-Rex waits for its two native leg helpers. A successful Klaus test would validate the shared controller for Klaus; it would not validate Z-Rex's size, attacks, navigation or foreign asset loading.

Version 0.3.1 changed reservations to a unique summon key and replaced generic deletion with the stock agent-despawn helper. The owner then saw Klaus spawn and fight on Totenreich. All factory checks passed, but setup timed out after about 15 seconds without recording readiness, conversion or controller acceptance. Despawn left a dead, defined handle and the owner slot stayed locked.

The 0.3.2-poc (`ally3`) retest on `zm_sat_hornet` recorded native readiness and the turn-helper return, then rejected its creature exit query before acceptance. Native despawn killed the actor but retained its agent type and erased its ownership field, so the old cleanup proof could not release the slot.

The **0.3.3-poc (`ally4`) retests on Paradox and Ashes** reached native readiness and conversion, then rejected all 24 actor-reachable projection queries as undefined. Forced setup retirement recorded native death and confirmed slot release on both maps. Ashes also created a second summon in the same match after release; it hit the same navigation failure and retired. This confirms recovery from those setup failures, not successful movement, natural death or the full 240-second lifetime.

**0.3.4-poc (`ally5`) passed its first Ashes playtest on November 10, 2026.** Klaus spawned, walked and damaged enemies. The first summon died after about 80 seconds without a despawn request from this mod; the logs do not identify what killed him. Cleanup completed, and a second summon worked in the same match. That second Klaus survived the first summon's old deadline, reached his own four-minute limit, then despawned and released the slot correctly. The tester also reported him fighting the map's normal enemy Klaus.

Klaus now tries the stock Zombie-attractor navigation query before two checked fallbacks. The working Ashes test used that first route. This fixes the repeated placement rejection seen in earlier builds; it does not establish every-map support. Z-Rex keeps its original navigation route and separate resource checks.

Still to test: the other maps, all attacks against the player, detailed nameplate/HUD behavior, simultaneous activation, disconnect cleanup, and a new summon after timed expiry. The first summon's early death also needs a cause. Twins selection and purchase remain a separate test.

Compilation, source review and mocked menu checks are separate from gameplay results. See the [validation notes](docs/ALLY_VALIDATION.md) for what passed and what remains open, and the [publishing notes](docs/PUBLISHING.md) for the Kronos Workshop package.

## Offline installation

Close the game. Back up the existing `owner_zrex_poc` package, then put the contents of `mod/` in the **offline** `cod25/kronos/mods/owner_zrex_poc` folder. Enable **ALLY -FieldUpgrade** in Kronos Library and restart. Choose **ALLY -FieldUpgrade** in the original Dark Flare slot and use it once on open ground. Nothing spawns automatically on map load. Never install into the retail Steam copy. Disable the package and restart to restore the native Dark Flare behavior.

The `owner_ally_profile` console setting defaults to `uber_klaus`; `zrex` selects the original full-size experimental actor. Unknown profile values are rejected. Set the desired profile before starting a fresh match. The generic menu name covers both profiles; the activation message and receipts identify the selected creature. See [validation steps](docs/ALLY_VALIDATION.md).

If creation has an unknown result, the owner slot deliberately stays locked for that match; start a fresh match after diagnosis rather than repeatedly creating adults. Do not infer allegiance from nameplate color alone.

## Checks

Prefer the Docker commands in `AGENTS.md`. The test dependency is lockfile-pinned and installed with lifecycle scripts disabled. The menu suite checks actual Lua behavior with opaque mode keys, reentrant menu calls, multiplayer isolation and both hook orders. `BIKE_MENU_LUA` can point to a separately supplied Blood Burner menu for local integration; it is never bundled here. `FENGARI_CLI` can select an existing workspace-only test runtime.

Lifecycle checks execute the actual pure GSC predicates and removal wrapper with mocked lookup, time and actor-state inputs. These checks cover unknown states, both Klaus termination proofs, identity mismatch and repeated observations; they do not prove native event delivery or gameplay cleanup.

Navigation checks execute the actual profile and reachable-point helper with mocked query/path results and narrow receiver-call/array syntax adaptation. They cover fallback order, short-circuit success, missing or partial paths, snap and endpoint boundaries, stale-result reset and Z-Rex isolation. They do not test native query results or compiler behavior.

Compile the GSC/HKS sources with the existing verified ACTS tool as described in `AGENTS.md`. Keep generated binaries outside `mod/`. A compiler or mocked-menu pass does not establish successful in-game loading or pathing.

Run the static production-import audit in `AGENTS.md` against the supplied offline game executable and compiled GSCs. It catches developer-only imports that a normal compile can accept. It does not replace a fresh-match link and gameplay test.
