# Production asset inventory

This is a **proposed** asset checklist for an original pseudo-3D motorcycle combat racer inspired by the Sega Road Rash trilogy. It is **not** a dump of original EA assets.

| Priority | Category | Required assets | States / variants |
|---|---|---|---|
| P0 | Player motorcycle | Rear-view bike and rider | Neutral, lean L/R, accelerate, brake |
| P0 | Player rider | Body/arms and combat overlays | Punch L/R, kick L/R, weapon swing, hit, fall, remount |
| P0 | Opponent riders | Distinct bikes, outfits and helmets | Near/far scale, lean, attack, fall, recovery |
| P0 | Road renderer | Asphalt, shoulders, markings, horizon | Curves, crests, descents, surface palettes |
| P0 | Traffic | Cars, vans/trucks | Rear/front silhouettes, impact reactions |
| P0 | Roadside scenery | Trees, poles, signs, barriers, buildings | Depth scaling, region-specific sets |
| P0 | Race HUD | Speed, position, progress, condition indicators | Racing, damage, finish |
| P0 | Combat feedback | Hit sparks, wobble, stun, impact effects | Left/right hit, knockdown |
| P0 | Audio | Engine, tire, collision, punch, crowd, UI | Speed/pitch variations |
| P1 | Police | Police bike, officer, arrest visuals | Patrol, chase, contact, bust |
| P1 | Weapons | Fists, boots, clubs, chains, other verified weapons | Idle, swing, hit, dropped/held |
| P1 | Garage UI | Bike thumbnails, performance stats, price labels | Owned, locked, purchasable, repair |
| P1 | Results UI | Placement, prizes, penalties, level advancement | Success, failure, bust |
| P1 | Track selection | Map/location art and preview panels | Locked, unlocked, completed |
| P2 | Atmosphere | Parallax skies, weather-like palettes, road debris | Time/location variations |
| P2 | Polish | Transitions, title treatment, optional accessibility UI | Motion-reduced mode |

## Technical delivery recommendations (proposed)
- Sprite atlases should include transparent padding to prevent texture bleeding during scale changes.
- Define pivot/anchor per rider, bike, weapon and scenery sprite.
- Author hitboxes separately from visual silhouettes; test attacks at both sides of the bike.
- Keep roadside placement and road geometry data-driven.
- Record source, ownership and licensing for each newly created asset.
- Use original artwork rather than redistributing EA sprite sheets.

## Acceptance checks
Every P0 item has at least one visual source category in [VISUAL_REFERENCES.md](VISUAL_REFERENCES.md), a named in-game use, and an animation/state owner. See [GAMEPLAY.md](GAMEPLAY.md) for behavioral contracts and [SCREENS.md](SCREENS.md) for UI placement.
