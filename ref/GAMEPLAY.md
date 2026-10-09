# Gameplay specification — Road Rash on Sega Genesis

**Scope:** Road Rash (1991), Road Rash II (1992), Road Rash 3 (1995). **Primary reference:** Road Rash 3. **Original** denotes established series behavior; **Proposed** denotes a suggested implementation specification, not a historical claim.

## 1. Core fantasy and loop
**Original:** Compete in illegal motorcycle road races against a pack of aggressive riders, fight for position using physical attacks and weapons, avoid traffic and police, survive crashes, collect prize money, and upgrade to faster motorcycles. Race success unlocks tougher competition and more demanding roads.

**Proposed game loop:** Select track → inspect rider/bike/cash → enter race → accelerate, steer, overtake and fight → finish, crash, or get busted → settle reward and penalties → repair/upgrade or buy motorcycle → next race.

## 2. Race rules and state machine
- **Original:** Race on a public-road course with other motorcyclists, cars, obstacles, and police. Race placement matters for money and progression; race results and expenses affect the next event.
- **Proposed:** `MENU → PRE_RACE → COUNTDOWN → RACING → FINISHED | WRECKED | BUSTED → RESULTS → GARAGE → MENU`. Wrecked may lead to recovery and continuation when the game mode permits; do not treat every crash as a terminal state.
- **Proposed:** Track distance, remaining riders, finishing rank, cash awarded, penalties and progression flags should be explicit data, not embedded in rendering.

## 3. Pseudo-3D road rendering
**Original:** A forward-looking chase camera follows a motorcycle sprite on a road rendered with perspective. The road curves and changes elevation; roadside objects and traffic scale as they approach. The motorcycle and opponents are animated sprites rather than modern polygonal 3D models.

**Proposed renderer:** Segment-based road model with centerline, width, curvature, elevation and roadside objects. Project segments from world distance into screen-space horizontal position, width and vertical position; render far-to-near road strips with occlusion, then depth-sort vehicles and scenery. Preserve stable horizon, recognizable lane markings, and rapid but readable scale changes. Camera follow should use damping to communicate steering without obscuring collisions.

**Proposed tunables:** draw distance, field of view, camera height, lateral follow, curve strength, hill amplitude, object density, palette and parallax layers. Numerical values are implementation choices, not extracted original game constants.

## 4. Riding and collisions
**Original:** Players accelerate, brake, lean/steer, weave through cars and opponents, and may fall after heavy contact. Rider and bike can separate visually during crashes; recovery costs time and may affect race outcome. Roadside obstacles and oncoming or same-direction traffic increase risk.

**Proposed:** Track speed, acceleration, braking, lateral velocity, lean, surface grip, collision impulse, stun, knockdown and recovery independently. Collision types: rider-vs-rider, bike-vs-car, bike-vs-scenery, attack-vs-rider, police contact. Apply clear audio/visual hit confirmation; avoid arbitrary instant death.

## 5. Combat and weapons
**Original:** Road Rash's signature feature is attacking adjacent riders while both bikes move at speed. Punching and kicking, as well as melee weapons such as clubs and chains, feature across the series; weapon availability and commands differ by entry. Opponents can retaliate and unseat the player. Road Rash 3 notably expands weapon variety and interactions.

**Proposed:** Combat uses left/right target selection based on relative position, speed and reach. Attack phases: anticipation → active hit frames → recovery. Distinguish unarmed, short-reach and long-reach weapons by range, windup and stun. Opponents may block lanes, counterattack and disengage. Avoid representing a dedicated weapon shop as an original trilogy mechanic without source confirmation.

## 6. AI riders, vehicles and police
**Original:** Opponents contest racing positions and can fight; traffic cars occupy the road and police pose a separate risk, including arrest/bust states.

**Proposed:** AI rider states: CRUISE, OVERTAKE, DEFEND, ATTACK, RECOVER, EVADE_TRAFFIC. Traffic follows predictable lanes with occasional variation. Police use detection, pursuit and bust conditions; balance police risk against combat risk. Difficulty scales via rider speed, aggression, reaction delay and traffic density, not only raw top speed.

## 7. Economy, garage and upgrades
**Original:** Race earnings fund the purchase of increasingly capable motorcycles. Crashes and police encounters can carry financial consequences. **Road Rash 3** includes motorcycle performance upgrades and repairs; do not assume all upgrades exist in the earlier titles.

**Proposed economy:** Wallet; event entry/result; prize; damage/repair cost; police fine; bike purchase/resale; optional component upgrades. Each transaction should be visible on the results/garage screens. Suggested component axes: engine (acceleration/top speed), tires (grip), suspension (handling/stability), armor/protection (damage tolerance). These axes are reference-driven design categories; confirm exact labels and effects against the Road Rash 3 manual before claiming a faithful recreation.

## 8. Progression and difficulty
**Original:** Players compete across multiple locations and increasing difficulty tiers. Success in events unlocks later tiers, and faster bikes become more important. Road Rash 3 includes international race settings.

**Proposed:** Data-driven campaign with levels, track completion records, placement thresholds, prize tables and bike unlock conditions. Track completion and prize eligibility must be testable without running the renderer. Maintain a visible campaign map/track select screen.

## 9. Presentation and feedback
- Speed conveyed by rapid road-strip movement, passing scenery and opponent scale.
- HUD prioritizes speed, rank, progress/distance, rider/bike condition where present, and race context.
- Hit reactions: attack animation, knockback, opponent wobble, fall, and audio.
- Crash sequence: impact, rider displacement, recovery and loss of position.
- Post-race sequence: placement, earnings/penalties, advancement and garage decision.

## 10. Version comparison

| Feature | Road Rash (1991) | Road Rash II (1992) | Road Rash 3 (1995) |
|---|---|---|---|
| Pseudo-3D motorcycle racing | Original | Original | Original |
| Combat with other riders | Original | Original | Original |
| Bike purchasing / progression | Original | Original | Original |
| Expanded weapon interactions | Baseline | Expanded | Further expanded |
| Split-screen multiplayer | Not a defining feature | Notable addition | Verify mode details before implementation |
| Performance upgrades and repairs | Do not assume | Do not assume | Key reference |
| Geographic scope | US settings | US settings | International settings |

The table is a design-oriented overview, not a complete feature-by-feature audit.

## 11. Verification priorities
Before implementing a faithful clone, verify: original Genesis button mappings per game; Road Rash 3 weapon acquisition/retention rules; upgrade categories and pricing; exact progression thresholds; race termination conditions; motorcycle statistics; multiplayer modes; on-screen HUD fields. Record video timestamps or manual page numbers for any precision-sensitive claim.

## Sources
- [Road Rash (MobyGames)](https://www.mobygames.com/game/797/road-rash/)
- [Road Rash II (MobyGames)](https://www.mobygames.com/game/798/road-rash-ii/)
- [Road Rash 3 (MobyGames)](https://www.mobygames.com/game/12343/road-rash-3/)
- [Road Rash 3 screenshots](https://www.mobygames.com/game/12343/road-rash-3/screenshots/)
