# Publishing to the Kronos Workshop

This package follows the [Kronos mod submission guide](https://github.com/Divity/kronos-data/wiki), edited November 3, 2026 and checked November 10, 2026.

## Release files

The first-pass release is `v0.3.4-poc`. Upload these original source files as individual GitHub release assets:

| File in this repo | Release asset | Installed path |
| --- | --- | --- |
| `mod/mod.json` | `mod.json` | `mod.json` |
| `mod/scripts/zm_owner_zrex_poc.gsc` | `zm_owner_zrex_poc.gsc` | `scripts/zm_owner_zrex_poc.gsc` |
| `mod/scripts/owner_zrex_receiver.gsc` | `owner_zrex_receiver.gsc` | `scripts/owner_zrex_receiver.gsc` |
| `mod/lua/owner_zrex_menu_post.lua` | `owner_zrex_menu_post.lua` | `lua/owner_zrex_menu_post.lua` |

Use `owner_zrex_poc` as the catalog ID so existing installs keep the same folder. The display name is **ALLY -FieldUpgrade**. The metadata and catalog use version `0.3.4-poc` and author `j6sistek-ui`.

Upload a separate `preview.png` made from the tester's gameplay footage. It must be 16:9 and under 16 MB. Link it as the catalog image; it is not an installed mod file. Do not upload compiled `.gscc`/`.luac` caches, test tools, private receipts, saves or game resources. Twins is separate and is not included in this release.

## Catalog submission

Fork `Divity/kronos-data` and add one entry to `index.json`, preserving every existing entry. Use type `script`, the exact source-file byte sizes, direct HTTPS release download links, and an empty `hash` for each file. Kronos fills in hashes during review. The launcher installs the source; the game compiles GSC when it loads.

The first-pass description should say what it does and what was tested:

> Replace Dark Flare with Uber Klaus fighting on your side for up to four minutes. First pass tested on Ashes of the Damned; other maps still need testing.

Before submission, verify every download against the staged file and check that the ID does not already exist. The owner requested a prepared comparison with the title and description filled in, leaving the final upstream pull-request submission for their review and click. Preparing the fork or release is not Workshop approval.

For updates, publish new versioned release assets and a new catalog PR. Never replace an asset behind an already accepted download link.
