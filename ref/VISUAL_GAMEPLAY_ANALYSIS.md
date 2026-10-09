# Visual gameplay and interface audit — Road Rash Genesis trilogy

**Issue:** #3. **Platform:** Sega Genesis / Mega Drive. **Priority:** Road Rash 3 (1995). **Method:** Inspect publicly visible gameplay stills and source screenshot descriptions; cross-check interface/navigation against original manuals. This is a still-image audit, **not** a frame-by-frame playtest or pixel-perfect measurement.

## Evidence key
- **V — visually observed:** an actual image was available and examined. Conclusions are limited to what a still image can establish.
- **C — caption/source verified:** MobyGames page or original manual describes the scene, but full original pixels were not reliably accessible for direct inspection.
- **D — design recommendation:** proposed new-game behavior or appearance; not a claim about the original.

## Directly inspected visual samples

| ID | Game / scene | Viewable image and source | Evidence |
|---|---|---|---|
| V1 | Road Rash (1991), two riders on a mountain road | [The Pixel Empire gameplay screenshot](https://www.thepixelempire.net/uploads/1/2/1/1/12119064/7370422_orig.jpg) ([article](https://www.thepixelempire.net/road-rash-smd-review.html)) | V |
| V2 | Road Rash (1991), roadside combat | [Retro Arcadia screenshot](https://retroarcadia.blog/wp-content/uploads/2024/02/road-rash-240208-164533-1.jpg?w=721) ([article](https://retroarcadia.blog/2024/05/15/my-life-with-road-rash-on-sega-mega-drive/)) | V; platform/game attribution should be checked against the article |
| V3 | Road Rash II (1992), desert traffic and rider combat | [Retro Arcadia image](https://i0.wp.com/retroarcadia.blog/wp-content/uploads/2024/02/road-rash-ii-240214-122852-1.png?fit=1200%2C840&ssl=1) ([article](https://retroarcadia.blog/2024/05/15/my-life-with-road-rash-on-sega-mega-drive/)) | V |
| V4 | Road Rash II (1992), riding among cars | [Games and Movies screenshot](https://gamesandmovies.it/media/catalog/product/cache/1/image/1800x/040ec09b1e35df139433887a97daa66f/s/c/sc895v/Road-Rash-II-%28Classic%29-%7C-Mega-Drive-Electronic-Arts-3329-30.jpg) ([page](https://gamesandmovies.it/road-rash-ii-classic-1258.html)) | V |
| V5 | Road Rash 3 (1995), snowy race and crash | [The King of Grabs screenshot](https://i0.wp.com/thekingofgrabs.com/wp-content/uploads/2020/06/road-rash-3-megadrive-036.png?fit=1200%2C840&ssl=1&w=640) ([article](https://thekingofgrabs.com/2020/08/05/road-rash-3-megadrive-genesis/)) | V |
| V6 | Road Rash 3 (1995), green roadside and racing HUD | [Time Extension image](https://images.timeextension.com/bdf70becbeb6a/road-rash-3.large.jpg) ([article](https://www.timeextension.com/news/2022/11/road-rash-games-get-handy-save-feature-thirty-years-later)) | V |

**Source caveat:** Public articles can rescale/crop images. The displayed files are sufficient for composition and qualitative UI analysis, not trustworthy native-pixel sampling. The [MobyGames Genesis screenshot index](VISUAL_REFERENCES.md) lists additional original captures; some full-size downloads are gated by MobyPlus.

## 1. Racing viewport and camera

### Observed composition [V1, V3, V5, V6]
- A **third-person chase camera** faces forward, with the rider near the lower central roadway. The player is visually large enough to show posture and attacks while the road vanishing point remains high enough to anticipate hazards.
- A continuous road ribbon tapers sharply toward the horizon. Its edges, dashed yellow centerline and scenery converge; bends appear as shifting road edges and lane markings. The scene relies on pseudo-3D perspective rather than realistic polygonal detail.
- Horizon scenery is **layered by distance**: sky and mountains/mesas; medium-distance trees/buildings; near roadside signs; traffic and riders. Large color fields maintain visual clarity at speed.
- Elevation changes are readable through a moving crest and shortened view of the road beyond it, not via a full 3D cockpit.
- Near-field rider silhouettes dominate action; small far-field sprites are simplified. Opponents overlap the player and each other during overtakes.

### Implementation implications [D]
Keep the playable viewport dominant and place the player bike at a stable, configurable lower-third anchor. Project roads by segment with perspective scaling, curvature and hills; use depth-aware ordering for vehicles and roadside sprites. Preserve readable road-edge contrast and the yellow centerline at high speeds. Avoid camera shake or blur that masks incoming traffic.

## 2. HUD evolution — the clearest difference between games

### Road Rash (1991) [V1, V2]
- The lower screen is occupied by a **substantial motorcycle-instrument console**, visually separated from the race scene by a hard horizontal boundary.
- Two **round analog gauges** dominate the panel. One carries a speed-like scale; the other reads as a tachometer-like dial. Small green digital displays provide secondary numeric feedback.
- A small **road preview / mini-map panel** sits at the lower left. At the upper edge of the console, green bars and adjacent rider-name labels communicate condition/duel context.
- Industrial dark grays, metallic borders, chrome-like rings, and bright green digits create a strong dashboard fantasy.
- **Trade-off:** strong motorcycle identity and period charm, but the large console takes a substantial fraction of the screen and limits vertical look-ahead.

### Road Rash II (1992) [V3, V4]
- The dashboard shifts toward a **broad rectangular digital console**: centered position label (e.g., '8TH PLACE'), large digital speed readout, timer, vertical colored bar graphic, bike-condition bar, and road preview at the left.
- Nameplates and bright green condition strips frame the main information. Segmented numerals are faster to parse than analog needles.
- **Trade-off:** denser quantitative information, clearer ranking and speed, still with a thick opaque console that competes with the road.

### Road Rash 3 (1995) [V5, V6]
- A similar central digital dashboard is visible: **time on the left, finishing position at the top center, speed numerals below, a BIKE health bar on the right**, and small left-side bar/road-preview regions.
- Nameplates appear at lateral edges. The racing view retains the same strong top/bottom split, but the interface is more purpose-driven than the first game's analog dials.
- In V5, the screen shows a rider falling while multiple bikes continue on a snowy road: the HUD persists during collision action, preserving continuity of race status.
- **Trade-off:** persistent telemetry is helpful, but speed, position and health compete for attention. The player must read both the road and the large dashboard.

### Modern HUD priority [D]
1. **Always visible:** position, speed, bike/rider condition and road look-ahead.
2. **Contextual:** opponent health/name and equipped weapon when close enough to fight.
3. **Secondary:** elapsed time, race progress, money and notifications.
4. Use compact high-contrast typography, restrained peripheral placement, and optional classic-dashboard mode. Never convey damage solely by color. Keep the road horizon and nearby rider unobstructed.

## 3. Combat readability and opponent targeting

### Observed [V2, V3, V5]
- Opponents ride immediately beside the player at a comparable screen scale. An extended arm or leg creates a distinct **horizontal action silhouette** against the road.
- The same scene may include oncoming or adjacent cars, turning combat into a risk/reward choice: strike now or avoid traffic.
- In V5, a falling rider and separate motorcycles convey a crash without requiring a dedicated cutscene.
- The HUD's named-rider labels and colored bars reinforce that opponents are persistent competitors, not disposable obstacles.

### Not provable from stills [C]
Exact attack hitboxes, input timing, damage values, whether an opponent is being stunned or merely leaning, and weapon acquisition rules cannot be established from a screenshot alone. Use the original manuals and captured video for those mechanics.

### Implementation implications [D]
Make left/right attacks visually distinct; exaggerate arm/weapon arcs but keep the silhouette inside the combat lane. Show brief contact sparks/pose changes and rider wobble. Display opponent name/condition only while in engagement range. Reserve full-screen effects for knockdowns and police busts, not every hit.

## 4. Roadside environment and visibility

### Observed [V1, V3, V4, V5, V6]
- **Region identity comes from silhouettes and palette**, not high-resolution textures: snowy mountains and firs, desert mesas, palms/fields, snow-covered road edges.
- Roads are usually broad, dark and visually uncluttered, with bright lane markings. Traffic vehicles are large enough to be recognized before impact.
- A few distinctive signs, trees and buildings convey location without sacrificing road contrast.
- In V5, white snow makes the dark asphalt especially readable; in V3, tan desert and blue sky clearly separate from the dark road.

### Implementation implications [D]
Create biome palettes and 5–10 signature prop silhouettes per region. Prioritize hazard recognition over surface detail. Use adaptive contrast on rainy/night courses and avoid placing bright VFX over the centerline.

## 5. Menus, garage and progression — source-caption/manual audit

The following are **not claimed as directly inspected screenshot pixels**; MobyGames provides descriptions and the original Road Rash 3 manual provides menu structure.

| Scene | Evidence | Confirmed source description / manual detail | Design consequence [D] |
|---|---|---|---|
| Road Rash 3 bike shop | [MobyGames 63476](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/63476/) [C] | Buy a different motorcycle or upgrade current one | Side-by-side current/target performance, cost and confirmation |
| Road Rash 3 track selection | [MobyGames 63477](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/63477/) [C] | Track selection; five stages with five tracks each | Stage grid/map with completion markers |
| Road Rash 3 progression | [MobyGames 63478](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/63478/) [C] | Finish top three on each track of a stage to advance | Visible qualification threshold and progress |
| Road Rash 3 character taunt | [MobyGames 63479](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/63479/) [C] | Opponents taunt after a race | Characterful results/reaction card |
| Road Rash 3 weapon combat | [MobyGames 63481](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/63481/) [C] | Heavy fighting with a weapon | Clear equipped-weapon state |
| Road Rash 3 race start | [MobyGames 63482](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/63482/) [C] | Start in Kenya | Track-specific start framing |
| Road Rash 3 police bust | [MobyGames 63484](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/63484/) [C] | Arrest by police officer | Distinct bust screen and penalty explanation |
| Road Rash 3 lost bike | [MobyGames 63485](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/63485/) [C] | Bike lost on a night course | Strong bike/rider separation and recovery cues |

The [Road Rash 3 Genesis manual](https://segaretro.org/images/3/3c/Road_Rash_3_MD_US_Manual.pdf) identifies a main menu with **START RACE, SELECT TRACK, BIKE SHOP, GAME OPTIONS, EXIT**, plus rider, level, cash and next-race location context. These are manual-backed screen semantics, **not direct pixel observations**.

## 6. Actionable modern interface specification [D]

| State | Visual priority | Placement recommendation | Anti-pattern |
|---|---|---|---|
| Race cruising | Road, hazards, speed, place | Compact corners; unobstructed center | Opaque panel covering bottom third |
| Rider duel | Enemy proximity, weapon, bike health | Brief contextual tag near rider; side-specific hit flash | Permanent floating text over every bike |
| Heavy traffic | Lane and collision warnings | Road-edge visual language, subtle audio | Big warning popup covering traffic |
| Crash | Rider trajectory, bike location, recovery | World-space animation plus small status cue | Full-screen camera shake |
| Police bust | Reason and cost | Separate concise results overlay | Unexplained instant transition |
| Garage | Cost, upgrade effect, available cash | Persistent bike model + comparison table | Hidden price or unlabelled stat bars |
| Stage select | Tracks, qualification, rewards | Location cards and completion markers | Unclear unlock rule |
| Results | Rank, money in/out, advancement | Single transaction breakdown | Only celebratory animation, no accounting |

## 7. Quality gates for an implementation [D]
- In a 2-second glance, a new player can identify their bike, the drivable road, nearest threat and current race position.
- Speed/position/condition remain legible at small desktop and handheld resolutions.
- Opponent attack direction and weapon reach are distinguishable in silhouette.
- Crash recovery never loses the player's bike off-screen without an intentional camera cue.
- Garage displays before/after changes and net currency.
- UI color contrast is sufficient without reliance on red/green discrimination.

## 8. Research limitations and next verification
1. Some MobyGames pages block automated fetching (HTTP 403) or gate native 320×224 downloads. Their descriptions are used as **C**, not misrepresented as inspected images.
2. Publicly viewable screenshots may be rescaled or cropped; no exact pixel dimensions, font measurements or frame timing are asserted.
3. A still cannot verify animation timing, weapon inventory rules, collision behavior or button combinations.
4. Re-check V2 article attribution before using that still as definitive Road Rash (1991) rather than Road Rash II.
5. For frame-accurate reproduction, capture lawful gameplay video and annotate HUD bounds, sprite anchors, lean frames and transitions.

## Sources
- [Road Rash (1991) Genesis manual](https://oldgamesdownload.com/wp-content/uploads/Road_Rash_Manual_Genesis_EN.pdf)
- [Road Rash 3 Genesis manual](https://segaretro.org/images/3/3c/Road_Rash_3_MD_US_Manual.pdf)
- [MobyGames Road Rash 3 screenshots](https://www.mobygames.com/game/12343/road-rash-3/screenshots/genesis/)
- [The King of Grabs Road Rash 3 screenshot gallery](https://thekingofgrabs.com/2020/08/05/road-rash-3-megadrive-genesis/)
- [Retro Arcadia Road Rash retrospective](https://retroarcadia.blog/2024/05/15/my-life-with-road-rash-on-sega-mega-drive/)
- [Time Extension Road Rash retrospective](https://www.timeextension.com/news/2022/11/road-rash-games-get-handy-save-feature-thirty-years-later)
