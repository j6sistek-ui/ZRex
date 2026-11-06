# Z-Rex cross-map status

Every-map support is requested but unfinished. In the owner-run Ashes test, both corrected scripts link and the activation reaches the availability check. The known direct actor references do not resolve to a usable candidate chain. Passive literal-name failure alone is not a complete alias diagnosis.

Inspection of the patched Rex Infernus client package identifies modern `sat_spawner_zombie_phobos_zm` and legacy `t10_spawner_zombie_phobos` AI definitions, both referencing `character_t10_zombie_phobos`. The body model is `c_t10_zmb_phobos`; one required leg definition is `scriptable_t10_zombie_phobos_leg`. The inspected common Zombies and carry-forward AI lists do not include either donor. Asset files on disk do not make their definitions resident in every map.

Cross-map use requires the complete model/animation/behavior/scriptable/FX dependency set to be loaded and registered, then validated with the actor's own navigation. The full dependency closure and a working selective BO7 asset importer/live loader have not been established. Current public readers and selective exporters are not a demonstrated game-ready writer. Copying the whole donor world is not an implemented portability recipe.

The Z-Rex profile preserves its capability guard and refunds unsupported attempts. It does not silently substitute a different creature, force a missing type, or claim that removing a map-name restriction supplies the assets. Native loading, movement, damage, expiry and every receiving map remain separate runtime gates. No game assets or extracted binary payload are included in this repository.

## Separate controller validation

Version 0.3.0 defaults to the explicitly named Uber Klaus profile so existing resident resources can exercise the shared summon controller. This is temporary validation, not a solution to cross-map Z-Rex loading. An accepted Klaus test can demonstrate its own spawn, conversion, damage, follow/pursuit, owner limit and timed cleanup. Z-Rex-specific resource availability, enormous collision bounds, attacks and accessory cleanup remain independent unresolved gates. See [the test checklist](ALLY_VALIDATION.md).
