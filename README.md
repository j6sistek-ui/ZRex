# ALLY -FieldUpgrade

Dark Flare summons one ally for up to 240 seconds. The default validation profile is **Uber Klaus**, using existing creature assets to test the same ownership, conversion, movement, damage and cleanup controller. The experimental full-size Z-Rex profile remains available explicitly; its cross-map loading is unfinished. The base upgrade and both augment variants keep their native identity, cost and loadout selection. This is original offline mod source; no game assets or third-party mod packages are included.

The display name covers both ally profiles. The existing `owner_zrex_poc` installation folder, source filenames, internal IDs and profile settings stay unchanged.

The separate [Twins Mask Arsenal addon](addons/twins-armory/README.md) extends the native Ammo Mods catalog on Rex Infernus. Its source and 36 native-contract checks are included independently of ALLY -FieldUpgrade; actual selection and purchase still need an owner retest.

The controller keeps the owner reserved until native absence or a guarded terminal agent transition is confirmed, schedules native despawn independently of accessory cleanup, and attempts reachable hostile and owner-follow goals. A stuck close target can trigger a repositioning attempt. Z-Rex-specific parts, encounter guards and offspring cleanup apply only to that profile. The Klaus profile suppresses its own exploding-core ejection. The visual candidate refreshes the native friendly outline, hides only the summoned ally's native aim-target name/health bar, and adds a green owner-screen `ALLY: Uber Klaus` label after readiness, removed on retirement. A green overhead name is not implemented; these visuals require an in-game retest.

## Compatibility and status

The requested target is every Zombies map. There is no fixed map allowlist. The selected profile must resolve to available AI/settings and usable creature navigation in the current match. Missing definitions produce a refunded attempt; an unavailable Z-Rex never silently becomes Klaus. This code does not provide a general fastfile loader or prove every map is supported. The passive receiver script remains a Z-Rex inventory and never spawns anything.

The earlier owner-run Ashes test confirmed that the previous scripts linked, but its candidate Z-Rex chain was unavailable. The bike worked there. The first Klaus test produced a live actor and a hostile-damage callback, but immediately rejected setup and later blocked another summon. That test did not reach friendly conversion or controller acceptance. The inspected Z-Rex donor is in Rex's map package; a usable all-map import/load route remains unfinished. See [cross-map status](docs/CROSS_MAP_STATUS.md).

Version 0.3.0 adds an explicit resident-enemy validation profile. Both profiles use the same four-minute limit, one-owner reservation, friendly conversion, player-damage guard and native retirement checks. Klaus uses smaller placement distances and its own initialization checks. Only Z-Rex waits for its two native leg helpers. A successful Klaus test would validate the shared controller for Klaus; it would not validate Z-Rex's size, attacks, navigation or foreign asset loading.

Version 0.3.1 changed reservations to a unique summon key and replaced generic deletion with the stock agent-despawn helper. The owner then saw Klaus spawn and fight on Totenreich. All factory checks passed, but setup timed out after about 15 seconds without recording readiness, conversion or controller acceptance. Despawn left a dead, defined handle and the owner slot stayed locked.

Candidate **0.3.2-poc (`ally3`) is runtime unverified**. Klaus readiness now requests string states explicitly with `getscriptablepartstate(..., 1)` and records the individual startup checks. Cleanup retains the absent-handle/empty-slot checks and adds a guarded agent-to-non-agent transition: only after an identity-checked despawn returns, both retained and fresh views must identify the same dead, non-agent instance on separate frames. Death, a hidden body, elapsed time or the helper return alone never unlocks another summon. The failed readiness condition and whether this terminal transition occurs still need a fresh test, including two summons in the same match. Keep the source PR draft and unmerged during validation.

Native compilation, shared-script dependency inspection, source review and menu tests are separate from gameplay acceptance. Retest movement, actual enemy damage, one-ally ownership, four-minute expiry and each receiver map. Keep full size until this proof works.

## Offline installation

Close the game. Back up the existing `owner_zrex_poc` package, then put the contents of `mod/` in the **offline** `cod25/kronos/mods/owner_zrex_poc` folder. Enable **ALLY -FieldUpgrade** in Kronos Library and restart. Choose **ALLY -FieldUpgrade** in the original Dark Flare slot and use it once on open ground. Nothing spawns automatically on map load. Never install into the retail Steam copy. Disable the package and restart to restore the native Dark Flare behavior.

The `owner_ally_profile` console setting defaults to `uber_klaus`; `zrex` selects the original full-size experimental actor. Unknown profile values are rejected. Set the desired profile before starting a fresh match. The generic menu name covers both profiles; the activation message and receipts identify the selected creature. See [validation steps](docs/ALLY_VALIDATION.md).

If creation has an unknown result, the owner slot deliberately stays locked for that match; start a fresh match after diagnosis rather than repeatedly creating adults. Do not infer allegiance from nameplate color alone.

## Checks

Prefer the Docker commands in `AGENTS.md`. The test dependency is lockfile-pinned and installed with lifecycle scripts disabled. The menu suite checks actual Lua behavior with opaque mode keys, reentrant menu calls, multiplayer isolation and both hook orders. `BIKE_MENU_LUA` can point to a separately supplied Blood Burner menu for local integration; it is never bundled here. `FENGARI_CLI` can select an existing workspace-only test runtime.

Compile the GSC/HKS sources with the existing verified ACTS tool as described in `AGENTS.md`. Keep generated binaries outside `mod/`. A compiler or mocked-menu pass does not establish successful in-game loading or pathing.

Run the static production-import audit in `AGENTS.md` against the supplied offline game executable and compiled GSCs. It catches developer-only imports that a normal compile can accept. It does not replace a fresh-match link and gameplay test.
