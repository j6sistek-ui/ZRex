# Resident ally validation

The objective is to exercise the shared four-minute summon controller with Uber Klaus before depending on Z-Rex's unresolved cross-map resources. The game is not started by installation, and no actor spawns until Dark Flare is activated.

## Select a profile

In the offline console before starting a fresh match:

```text
set owner_ally_profile uber_klaus
```

This is the default when the setting is absent. The original experimental actor is selected explicitly with `set owner_ally_profile zrex`. There is no automatic fallback between them. An unknown value or unavailable actor rejects the activation. The menu remains **Ally Summon (Prototype)** in the Dark Flare slot and supports its two original augment aliases.

## What the next gameplay test must demonstrate

1. Start a fresh solo match and activate once on open ground. Confirm the named creature appears and actually walks.
2. Observe it damaging enemies while the player remains unharmed by its attacks. A team flag, green outline or damage callback alone is not proof of health loss or protection.
3. Move away and around obstacles. Confirm pursuit/follow behavior instead of stationary attacks or constant path retries.
4. Attempt another activation while the first ally exists. Confirm no duplicate is created.
5. Observe the ally disappear by its 240-second deadline measured from creation, or earlier if it dies, its owner dies/disconnects, or setup fails. In the same match, recharge and activate again. Confirm a second ally appears only after the first cleanup completes. Repeat once after the ally dies early. A returned despawn call or a hidden body alone is not a successful cleanup result.
6. For Klaus, check that destruction does not leave an exploding mini core or owned accessories. Confirm normal round enemies, round completion, quest actors and the separate Healing Aura bike remain functional.
7. Repeat on each target map. Shared package declarations and a successful test on one map do not establish every-map runtime compatibility.

Use the mod's private local receipts to distinguish creation, initialization, conversion, targeting, damage, expiry and confirmed deletion. A script fault or missing receipt must remain an unresolved result. Compilation and menu checks cannot replace the steps above.

The first owner test reached a live Klaus in Ashes, but its factory rejected setup immediately and generic deletion left its handle alive. Version 0.3.1 targets those failures. The repaired acceptance, cleanup and second activation remain unverified until a fresh test; the earlier visible spawn is not acceptance of the full controller.

## Research boundaries

The stock Viper/Uber Klaus scripts contain turned-AI handling, and the stock exfil cleanup uses a per-instance flag to suppress mini-core ejection. The prototype uses that flag only on its own summon. These source observations do not establish player safety or every attack's team filtering in the installed runtime. The common player-damage guard remains active.

Relevant reference build: PC S6L 20261016, pinned [Viper behavior source](https://github.com/ProjectHiNAtyu/CoDs_GSC_Wiki_Library_IW8Plus/blob/55d02741d078eaeeaeeaffa433deef4a439608f8/07_SAT/PC_S6L_20261016/Source/scripts/common/ai/aitypes/zombie_viper/zombie_viper.gsc) and [shared conversion helper](https://github.com/ProjectHiNAtyu/CoDs_GSC_Wiki_Library_IW8Plus/blob/55d02741d078eaeeaeeaffa433deef4a439608f8/07_SAT/PC_S6L_20261016/Source/scripts/common/ai/aitypes/shared/zombie/zombie_utils.gsc#L504-L525).
