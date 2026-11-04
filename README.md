# Z-Rex Ally prototype

Dark Flare summons one full-size Z-Rex ally for up to 240 seconds. The base upgrade and both augment variants keep their native identity, cost and loadout selection. This is original offline mod source; no game assets or third-party mod packages are included.

The current revision addresses an observed failed setup that left adults behind, permitted repeated summons and never started the successful-use timer. It keeps the owner reserved until the tracked actor is actually gone, schedules deletion independently of accessory cleanup, and attempts reachable hostile and owner-follow goals. A stuck close target can trigger a repositioning attempt. Attributed toxic/roar offspring are removed. The native friendly outline is refreshed and only this ally's hostile boss bar is hidden; green overhead names are not verified.

## Compatibility and status

The requested target is every Zombies map. There is no fixed map allowlist. A map must actually have the donor AI, settings, required scriptables and usable creature navigation. Missing definitions produce a refunded attempt instead of a blind spawn. This code does not provide a general fastfile loader or prove every map is supported. The passive receiver script records available definitions without spawning anything.

Version 0.2.1 removes two development-only native functions that prevented the preceding build from linking during normal play. After creation, it waits for the owned actor's two native leg helpers before accepting use. The passive scan records a leg reference separately from unverified registration. Native construction and each map's complete asset dependencies still need runtime validation.

Native compilation, shared-script dependency inspection, source review and menu tests are separate from gameplay acceptance. Retest movement, actual enemy damage, one-adult ownership, four-minute expiry and each receiver map. Keep full size until this proof works.

## Offline installation

Close the game. Back up the existing `owner_zrex_poc` package, then put the contents of `mod/` in the **offline** `cod25/kronos/mods/owner_zrex_poc` folder. Enable the package in Kronos Library and restart. Choose the Dark Flare slot and use it once on open ground. Never install into the retail Steam copy. Disable the package and restart to restore the native Dark Flare behavior.

If creation has an unknown result, the owner slot deliberately stays locked for that match; start a fresh match after diagnosis rather than repeatedly creating adults. Do not infer allegiance from nameplate color alone.

## Checks

Prefer the Docker commands in `AGENTS.md`. The test dependency is lockfile-pinned and installed with lifecycle scripts disabled. The menu suite checks actual Lua behavior with opaque mode keys, reentrant menu calls, multiplayer isolation and both hook orders. `BIKE_MENU_LUA` can point to a separately supplied Blood Burner menu for local integration; it is never bundled here. `FENGARI_CLI` can select an existing workspace-only test runtime.

Compile the GSC/HKS sources with the existing verified ACTS tool as described in `AGENTS.md`. Keep generated binaries outside `mod/`. A compiler or mocked-menu pass does not establish successful in-game loading or pathing.

Run the static production-import audit in `AGENTS.md` against the supplied offline game executable and compiled GSCs. It catches developer-only imports that a normal compile can accept. It does not replace a fresh-match link and gameplay test.
