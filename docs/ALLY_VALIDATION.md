# ALLY -FieldUpgrade validation

The objective is to exercise the shared four-minute summon controller with Uber Klaus before depending on Z-Rex's unresolved cross-map resources. The game is not started by installation, and no actor spawns until Dark Flare is activated.

## Select a profile

In the offline console before starting a fresh match:

```text
set owner_ally_profile uber_klaus
```

This is the default when the setting is absent. The original experimental actor is selected explicitly with `set owner_ally_profile zrex`. There is no automatic fallback between them. An unknown value or unavailable actor rejects the activation. The menu displays **ALLY -FieldUpgrade** in the Dark Flare slot and supports its two original augment aliases. The package remains in `owner_zrex_poc`; the display rename does not change these profile commands.

## What the next gameplay test must demonstrate

1. Start a fresh solo match and activate once on open ground. Confirm the named creature appears and actually walks.
2. Observe it damaging enemies while the player remains unharmed by its attacks. A team flag, green outline or damage callback alone is not proof of health loss or protection.
3. Move away and around obstacles. Confirm pursuit/follow behavior instead of stationary attacks or constant path retries.
4. Attempt another activation while the first ally exists. Confirm no duplicate is created.
5. Observe the ally disappear by its 240-second deadline measured from creation, or earlier if it dies, its owner dies/disconnects, or setup fails. In the same match, recharge and activate again. Confirm a second ally appears only after the first cleanup completes. Repeat once after the ally dies early, and keep the replacement alive beyond the original ticket's deadline to check that stale cleanup cannot remove it. A returned despawn call or a hidden body alone is not a successful cleanup result.
6. For Klaus, check that destruction does not leave an exploding mini core or owned accessories. Confirm normal round enemies, round completion, quest actors and the separate Healing Aura bike remain functional.
7. Repeat on each target map. Shared package declarations and a successful test on one map do not establish every-map runtime compatibility.

Visual retest: after readiness, check for the green owner-screen `ALLY: Uber Klaus` label and its removal on retirement. Aim at the ally to check that its native target name/health bar is hidden while ordinary enemies remain unchanged. A green overhead name is not implemented; this candidate has not been visually verified.

Use the mod's private local receipts to distinguish creation, initialization, conversion, targeting, damage, expiry and confirmed retirement. For candidate 0.3.3-poc, confirm build `ally4` and the `native_ready`, `converted`, `accepted` and `retire_confirmed` stages. Natural death must record the captured actor's `native_death` event; forced retirement records the fenced native despawn and its return. A `readiness_timeout` receipt records individual startup checks. Navigation rejection counters distinguish missing projection, excessive snap distance, empty path, endpoint mismatch and a too-close exit. A script fault or missing receipt remains unresolved. Compilation and menu checks cannot replace the steps above.

The first owner test reached a live Klaus in Ashes, but its factory rejected setup immediately and generic deletion left its handle alive. The version 0.3.1 Totenreich retest passed every factory check; the owner saw Klaus spawn and fight, and a hostile-damage callback was recorded. Setup still timed out after about 15 seconds without recording readiness, conversion or acceptance. The despawn helper returned with a dead, defined handle and matching native slot, and the next summon stayed locked. This is partial evidence, not full-controller acceptance.

The 0.3.2-poc retest on `zm_sat_hornet` passed native readiness and recorded the turn-helper return, then failed the creature exit query. Native despawn left the same dead agent and cleared its custom ownership field; no `accepted` or `retire_confirmed` stage was recorded. The exact navigation rejection was not logged.

Candidate **0.3.3-poc is runtime unverified**. Klaus uses its actor's reachable-point query and eight exit directions. It retains the missing-handle/empty-slot proof; the added Klaus proof captures exact ownership before a fenced native despawn or a watched native death event, then requires the same dead actor through retained and fresh lookups on separate frames. It permits a retained dead agent and erased post-death fields, while rejecting another slot occupant. Z-Rex keeps its separate proof. Check `removal_proof`: a bare dead-state reading or a helper return alone is insufficient. Actual navigation, natural-death notification, timed retirement and the same-match second activation remain test gates. Keep the source PR draft and unmerged.

## Research boundaries

The stock Viper/Uber Klaus scripts contain turned-AI handling, and the stock exfil cleanup uses a per-instance flag to suppress mini-core ejection. The prototype uses that flag only on its own summon. These source observations do not establish player safety or every attack's team filtering in the installed runtime. The common player-damage guard remains active.

Relevant reference build: PC S6L 20261016, pinned [Viper behavior source](https://github.com/ProjectHiNAtyu/CoDs_GSC_Wiki_Library_IW8Plus/blob/55d02741d078eaeeaeeaffa433deef4a439608f8/07_SAT/PC_S6L_20261016/Source/scripts/common/ai/aitypes/zombie_viper/zombie_viper.gsc) and [shared conversion helper](https://github.com/ProjectHiNAtyu/CoDs_GSC_Wiki_Library_IW8Plus/blob/55d02741d078eaeeaeeaffa433deef4a439608f8/07_SAT/PC_S6L_20261016/Source/scripts/common/ai/aitypes/shared/zombie/zombie_utils.gsc#L504-L525).
