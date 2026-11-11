# Z-Rex cross-map status

This tracks the experimental `zrex` profile of **ALLY -FieldUpgrade**; the shared controller also has a separate Uber Klaus validation profile.

Every-map support is requested but unfinished. In the owner-run Ashes test, both corrected scripts link and the activation reaches the availability check. The known direct actor references do not resolve to a usable candidate chain. Passive literal-name failure alone is not a complete alias diagnosis.

Inspection of the patched Rex Infernus client package identifies modern `sat_spawner_zombie_phobos_zm` and legacy `t10_spawner_zombie_phobos` AI definitions, both referencing `character_t10_zombie_phobos`. The body model is `c_t10_zmb_phobos`; one required leg definition is `scriptable_t10_zombie_phobos_leg`. The inspected common Zombies and carry-forward AI lists do not include either donor. Asset files on disk do not make their definitions resident in every map.

Cross-map use requires the complete model/animation/behavior/scriptable/FX dependency set to be loaded and registered, then validated with the actor's own navigation. The full dependency closure and a working selective BO7 asset importer/live loader have not been established. Current public readers and selective exporters are not a demonstrated game-ready writer. Copying the whole donor world is not an implemented portability recipe.

The Z-Rex profile preserves its capability guard and refunds unsupported attempts. It does not silently substitute a different creature, force a missing type, or claim that removing a map-name restriction supplies the assets. Native loading, movement, damage, expiry and every receiving map remain separate runtime gates. No game assets or extracted binary payload are included in this repository.

## Separate controller validation

Version 0.3.0 defaults to the explicitly named Uber Klaus profile so existing resident resources can exercise the shared summon controller. This is temporary validation, not a solution to cross-map Z-Rex loading. An accepted Klaus test can demonstrate its own spawn, conversion, damage, follow/pursuit, owner limit and timed cleanup. Z-Rex-specific resource availability, enormous collision bounds, attacks and accessory cleanup remain independent unresolved gates. See [the test checklist](ALLY_VALIDATION.md).

The 2026-11-09 installed-package inspection found no known Klaus resource exception among Ashes of the Damned, Astra Malorum, Paradox Junction, Totenreich, Kowakujo and Rex Infernus: all six declare the shared Zombies package containing the inspected Klaus resources. Shared declarations do not prove runtime availability or behavior. The November 10 Ashes test confirmed accepted movement, hostile damage, cleanup after early death, a second summon and its four-minute retirement. Earlier Totenreich spawning does not establish the current controller there. Every other map still needs a fresh test. Dead Ops Arcade, Endgame and uninstalled/custom maps need separate validation.
