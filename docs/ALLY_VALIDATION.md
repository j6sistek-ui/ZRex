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

Use the mod's private local receipts to distinguish creation, initialization, conversion, targeting, damage, expiry and confirmed retirement. For candidate 0.3.4-poc, confirm build `ally5` and the `native_ready`, `converted`, `accepted` and `retire_confirmed` stages. Natural death must record the captured actor's `native_death` event; forced retirement records the fenced native despawn and its return. A `readiness_timeout` receipt records individual startup checks. Navigation rejection counters distinguish missing projection, excessive snap distance, empty path, endpoint mismatch and a too-close exit. The new `nav_attractor_defined`, `nav_actor_defined`, `nav_nearest_defined` and `nav_accepted_source` fields distinguish the attempted projection routes. A script fault or missing receipt remains unresolved. Compilation and mocked checks cannot replace the steps above.

The first owner test reached a live Klaus in Ashes, but its factory rejected setup immediately and generic deletion left its handle alive. The version 0.3.1 Totenreich retest passed every factory check; the owner saw Klaus spawn and fight, and a hostile-damage callback was recorded. Setup still timed out after about 15 seconds without recording readiness, conversion or acceptance. The despawn helper returned with a dead, defined handle and matching native slot, and the next summon stayed locked. This is partial evidence, not full-controller acceptance.

The 0.3.2-poc retest on `zm_sat_hornet` passed native readiness and recorded the turn-helper return, then failed the creature exit query. Native despawn left the same dead agent and cleared its custom ownership field; no `accepted` or `retire_confirmed` stage was recorded. The exact navigation rejection was not logged.

The **0.3.3-poc (`ally4`) retests on Paradox and Ashes** recorded `native_ready` and `converted`, then all 24 actor-reachable queries returned undefined. Each failed setup recorded native death and `retire_confirmed` with the slot released. Ashes also created a second summon in the same match after the first release, then encountered the same navigation failure and retired. These receipts confirm forced-failure cleanup and same-match recreation only; they do not prove natural death, accepted movement or the 240-second lifetime.

**0.3.4-poc (`ally5`): first Ashes pass accepted on November 10, 2026.** The stock Zombie-attractor query returned a complete usable path. Both summons reached `accepted`, moved and recorded damage against hostile AI.

The first summon lived for 80.032 seconds. The mod had not requested despawn, and cleanup released the slot 5.12 seconds after the game recorded his death. These receipts prove an observed death and recovery, but do not identify the killer or distinguish combat from another native scripted death.

The second summon remained alive beyond the first ticket's deadline, reached its own four-minute limit, and retired with `240-second absolute limit`. Native despawn returned 32 milliseconds later; the slot released 5.248 seconds after the limit. This confirms same-match resummoning after early death, survival past the stale deadline, and timed cleanup for this run. The tester also reported the ally fighting Ashes' normal enemy Klaus without preventing that enemy from appearing.

The owner approved publishing this first pass. Other maps, detailed visuals, player-damage protection, duplicate activation, disconnect handling, a further summon after timed expiry and the first death's cause remain open. Twins is a separate addon whose native menu and purchase still need a live test. Private receipts and footage are not part of the install package.

## Research boundaries

The stock Viper/Uber Klaus scripts contain turned-AI handling, and the stock exfil cleanup uses a per-instance flag to suppress mini-core ejection. The prototype uses that flag only on its own summon. These source observations do not establish player safety or every attack's team filtering in the installed runtime. The common player-damage guard remains active.

Relevant reference build: PC S6L 20261016, pinned [Viper behavior source](https://github.com/ProjectHiNAtyu/CoDs_GSC_Wiki_Library_IW8Plus/blob/55d02741d078eaeeaeeaffa433deef4a439608f8/07_SAT/PC_S6L_20261016/Source/scripts/common/ai/aitypes/zombie_viper/zombie_viper.gsc) and [shared conversion helper](https://github.com/ProjectHiNAtyu/CoDs_GSC_Wiki_Library_IW8Plus/blob/55d02741d078eaeeaeeaffa433deef4a439608f8/07_SAT/PC_S6L_20261016/Source/scripts/common/ai/aitypes/shared/zombie/zombie_utils.gsc#L504-L525).
