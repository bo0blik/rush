# Screen-by-screen reference specification

**Original:** The Road Rash trilogy presents races, menus, progression and bike purchasing through distinct screens; exact screen content and sequence vary by installment. **Proposed:** The following is a practical implementation-oriented screen map, emphasizing Road Rash 3.

## 1. Title / main menu
**Purpose:** Enter campaign, access options and continue progress.
**Proposed elements:** Title artwork, start/continue, options, input legend. Keep typography legible at low resolution.

## 2. Track / level selection
**Purpose:** Show available events and progression.
**Proposed elements:** Map or location list, current level, track preview, eligibility and previous best placement. Clearly distinguish locked and unlocked courses.

## 3. Garage / motorcycle purchase
**Purpose:** Spend winnings to improve competitive capability.
**Original:** Purchasing better motorcycles is a series pillar; Road Rash 3 is the primary reference for repairs and upgrades.
**Proposed elements:** Bike image, model/name, price, owned/available state, speed/acceleration/handling/durability comparison, buy/repair/upgrade actions, wallet balance and confirmation. Do not claim these exact stats or layout are copied from the original.

## 4. Race intro / start
**Purpose:** Communicate location, race context and player readiness.
**Proposed elements:** Course name, level, competitors, countdown/start signal.

## 5. Racing HUD
**Purpose:** Preserve road visibility while presenting urgent information.
**Original:** Chase-view road, rider sprite, opponents and race indicators are the signature presentation.
**Proposed elements:** Position, speed, progress/distance, damage/condition if applicable, police warning and compact weapon indicator. Prioritize road/traffic legibility over UI density.

## 6. Crash / recovery
**Purpose:** Communicate impact and lost time without confusing the player.
**Proposed elements:** Falling rider, separated bike if appropriate, recovery animation, temporary input restriction and restored camera.

## 7. Police bust
**Purpose:** Show race interruption and its economic/progression consequence.
**Proposed elements:** Clear bust message, police visual, fine or penalty and continuation route.

## 8. Results
**Purpose:** Make placement, payout and progression transparent.
**Proposed elements:** Rank, elapsed time, prize, damage/repair, fines, net cash change, advancement state and next action.

## 9. Options / pause
**Purpose:** Pause and configure sound, input and accessibility.
**Proposed elements:** Resume, restart/quit confirmation, controls, audio and reduced motion.

## Screen transitions (proposed)
`TITLE → TRACK_SELECT → GARAGE → RACE_INTRO → RACING → RESULTS → GARAGE/TRACK_SELECT`
Exceptions: `RACING → CRASH_RECOVERY → RACING`; `RACING → BUST → RESULTS`; `RACING → PAUSE → RACING`.

## Visual review checklist
- Distinguish original screenshots from new mockups.
- Record resolution, aspect ratio, typography hierarchy, palette and spacing.
- Verify every menu path with keyboard/controller.
- Ensure status is conveyed by text and icon, not color alone.
- Cross-reference [VISUAL_REFERENCES.md](VISUAL_REFERENCES.md) for gallery sources and [ASSET_LIST.md](ASSET_LIST.md) for required UI assets.
