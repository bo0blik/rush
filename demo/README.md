# Forest riding demo

Open `scenes/forest_demo.tscn` and press F6, or press F5: it is the project's main scene.

- W / Up: throttle; S / Down: front brake; Space: rear brake.
- A / D / Left / Right: progressive lane changes; release to stabilize the chosen lane. The rider steers with the road. Sharp bends still require braking when tire grip is insufficient.
- R: restart at the beginning; Escape: pause/resume.
- F2: cycle five graphics presets; F3: toggle speed streaks and camera widening. Both work while paused.
- F4: switch motorcycle physics templates and restart; Q/E: shift manually; M: automatic/manual shifting.
- F5/F6/F7/F8 in the game window: helmet/jacket/pants/boots (two variants each, saved locally).
- Z/X: left/right punch; C/V: left/right kick. F9: staged parked-car crash; R restores the detached rider.
- Rider artwork, procedural skeletal animation, physical ragdoll and motorcycle artwork are separate. See [character system](CHARACTER_SYSTEM.md).
- Controller: left stick, right/left triggers, Start to pause, Y to reset.

The road is a closed circuit. A reduced physical motorcycle model computes engine/drivetrain forces, drag, braking, load transfer, roll/yaw and shared tire grip. Track coordinates only locate the bike; the road does not automatically steer it. Grass reduces grip and adds resistance without an artificial speed cap. Strong traffic collisions detach the rider into a 3D ragdoll and release a separate motorcycle body. Punches and kicks can hit adjacent cars. Jump controls and collisions with scenery are not implemented. Details, limitations and instructions for adding bike resources: `MOTORCYCLE_PHYSICS.md`.

## Traffic

Eight pooled vehicles follow the editable track: four slower vehicles in the right lane and four oncoming vehicles in the left lane. Sedans and trucks use the generated front/rear/angled views, with lighting and shadow geometry. They slow when approaching another vehicle in their lane. Passed vehicles recycle outside the view into a clear slot ahead; the pool does not grow.

Pass slower vehicles using A/D and watch for oncoming traffic. Swept overlap in track coordinates detects the initial encounter; strong impacts (>14 m/s relative speed) release the physical rider and bike. Sedan chassis/cabin and truck volumes then participate in Jolt contacts. Launch impulses are tuned for gameplay; vehicle deformation is not modeled. Light contact briefly cuts throttle and creates a balance reaction. Escape pauses traffic; R restores starting positions and clears physical crash bodies.

`scenes/traffic.tscn` owns the pool; `traffic_sedan.tscn` and `traffic_truck.tscn` are reusable vehicle scenes. Width, length, height and atlas views are editable on each vehicle scene. The composition root supplies the road/rider/camera references and connects the traffic collision signal to HUD.

Traffic checks: `Godot --headless --path . --script res://tests/traffic_smoke.gd`.

The engine sound is synthesized with AudioStreamGenerator and follows calculated engine RPM and throttle. Volume is editable on the motorcycle's Engine node.

## Visual upgrade

### Lighting and shadows

The main scene's Sun casts filtered shadows within 150 m, with four blended directional cascades. Warm sunlight is balanced by cool ambient fill. Road geometry has generated normals and a rough lit material; trees, bushes, rocks and roadside structures respond to light and cast shadows. Far mountain/forest layers retain their atmospheric art colors.

The motorcycle and articulated rider receive light and cast shadows. A soft contact shadow and a shadow-only motorcycle volume reinforce ground contact during riding. During a crash, independent body-part sprites and the falling motorcycle cast their own shadows. Sun settings are editable in `scenes/forest_demo.tscn`.

### Motion and scenery

The rider uses nine connected pixel art poses during riding and attacks, with palette customization for each clothing slot. Rider and motorcycle share one roll plane. A 19-bone skeleton fits contact points to each motorcycle and checks punch/kick contacts. Strong impacts transfer the seated pose to physical bones, rendered with a matching 20-part pixel art atlas; the rider flies, collides and lands independently of the bike. F9 stages a parked-sedan crash, R restores riding. See `CHARACTER_SYSTEM.md` for controls and limitations.

Each traffic model has 27 authored frames: six rear angles, six front angles, two six-frame rolling loops and three additional rear/side/front profiles. A continuous camera-relative azimuth selects views through the complete pass, with a shared side profile at 90 degrees. Vehicle orientation follows the road. Artwork uses uniform scaling: height 1.50 m for the sedan, 2.90 m for the truck; motorcycle artwork is 1.12–1.20 m high, with separate seated human proportions. Width comes from the natural artwork aspect ratio, without stretching sprites to projected body length. Collision dimensions remain sedan 1.75x4.2x1.5 m and truck 2.4x6.4x2.9 m. Pose blending remains a sprite approximation; authored silhouettes can retain minor geometry variation.

### Pixel rendering and speed

`scenes/screen_effects.tscn` applies one of five presets defined in `scripts/screen_effects.gd`. The dashboard is drawn above the filter to preserve text readability. Pixel grids divide the native 640x480 resolution into integer blocks; window scaling remains integer.

| F2 mode | World grid | Look |
| --- | --- | --- |
| 1. ОРИГИНАЛ | 640x480 | Native render, no palette reduction or speed distortion |
| 2. ЧИСТЫЙ ПИКСЕЛЬ | 320x240 | Clean pixels, 32 shade steps, no dithering; default |
| 3. РЕТРО 16-БИТ | 320x240 | 16 shade steps, ordered dithering, stronger saturation and light outlines |
| 4. КРУПНЫЙ ПИКСЕЛЬ | 160x120 | Large pixels, 8 shade steps and stronger outlines |
| 5. КИНО | 320x240 | Warm highlights, softer saturation, contrast and vignette |

F2 cycles and wraps through the presets; the HUD identifies the current look. F3 toggles screen speed effects and camera widening independently of the color filter. Restarting preserves the selected preset and motion toggle. Presets are remembered within the current play session.

Acceleration and speed drive eased peripheral streaks and a mild vignette. The road center and dashboard stay clear. Camera field of view increases smoothly from 55 to 59 degrees with speed. Pausing freezes screen motion; restarting clears streaks and camera state.

Wheel lock/spin or a fall can emit tire smoke above 3 m/s and leave bounded world-space skid marks. Riding on the verge emits dust. `scripts/tire_effects.gd` uses native CPUParticles3D and a pool of 160 skid meshes; reset clears the effects.

The forest has six depth bands and roughly 3,000 trees plus 9,000 ground/crop props. `scripts/dense_scenery.gd` uses seeded clusters and sections of approximately 95 m, combined into about 220 MultiMesh batches. Shared atlas materials, explicit shader bounds and distance culling keep the expanded scenery bounded. Trees and foliage sway gently. Six stretches vary between birch-lined farms, village fields, conifers, flower meadows, rocky forest and lakeside reeds.

Generated ground props include ferns, daisies/lupines, juniper, reeds, rowan, fallen birch logs, stumps, mossy rocks, firewood, rural direction signs, hay carts and haystacks. Five cabins with fences and six picnic spots complement the existing guardrail, road signs and four bus stops. Clearings keep trees out of buildings and picnic spots; decoration placement rejects nearby road bends. Objects are decorative and do not have collision bodies.

The village stretch adds 17 houses on both banks, a blue-domed white church, barn, windmill, sunflower and wheat fields, fences and a timber footbridge. A separate water mesh occupies a channel carved into terrain strips, with sandy banks and animated ripples. The starting point is now by the rural stretch. New rural source artwork and the complete prompt: `assets/RURAL_GENERATION.md`. Preview images: `previews/rural_start.png`, `previews/rural_river_church.png`.

Three physical mountain rings at different distances provide parallax while driving. The palette follows `ref/generated/gameplay-forest.png` and `gameplay-mountain.png`. New source art and its prompt are in `assets/SCENERY_GENERATION.md`; filter previews are in `previews/`.

The current animation assets and complete successful prompts are documented in `assets/ANIMATION_GENERATION.md`. Earlier two-frame art remains in the project as a source reference. `tools/build_animation_resources.py` regenerates fitted SpriteFrames and contact metadata by reading alpha without modifying PNG pixels.

## Scenes and editing

- `scenes/forest_demo.tscn`: composition root, environment and sun.
- `scenes/track.tscn`: editable Path3D and generated road/forest.
- `resources/forest_route.tres`: closed Curve3D; edit its points with Godot's Path3D gizmo.
- `scenes/motorcycle.tscn`: rider animation, shadow and movement parameters.
- `resources/bikes/`: motorcycle spec resources; optional per-bike animation art and physical height.
- `resources/rider_parts.tres`, `motorcycles_separate.tres`: fitted modular clothing and motorcycle atlases.
- `scenes/rider_physical_rig.tscn`: editable Auto Ragdoll skeleton; `scenes/rider_character.tscn`: reusable character.
- `resources/rider_animation_frames.tres`: archived original combined artwork, no longer used by the motorcycle scene.
- `resources/sedan_animation_frames.tres`, `truck_animation_frames.tres`: driving and viewing-angle sequences.
- `scenes/chase_camera.tscn`: chase distance, height and damping.
- `scenes/hud.tscn`: 640×480 instrument panel, route map, time and controls.

The main scene supplies dependencies to its children. HUD receives rider telemetry through a signal. Motion and camera use the physics tick with physics interpolation. Decoration is generated once with a fixed seed; roadside posts use MultiMesh. Pixel art renders at 640×480 with integer scaling and nearest filtering.

Generated art and complete prompts: `assets/GENERATION.md`. Atlas source PNGs retain their original alpha; frame regions and tire anchors are handled by Godot.

## Verification

`Godot --headless --path . --script res://tests/demo_smoke.gd`

Checks scene loading, road continuity, animations, input actions, throttle, braking, steering, verge slowdown, loop traversal, pause and reset.
Also checks eased lean reversal, braking smoke, dust, skid reset and generated parallax/roadside landmarks.

`Godot --headless --path . --script res://tests/animation_smoke.gd` checks traffic frame counts, relative scale, continuous viewing angles, side-view width, detached crash state, control lockout and reset.

`Godot --headless --path . --script res://tests/scenery_graphics_smoke.gd` checks density, section batch limits, custom bounds, landmarks, integer pixel grids, five-mode cycling, physical F2/F3 bindings, pause and reset behavior.

`Godot --headless --path . --script res://tests/motorcycle_physics_smoke.gd` checks torque/mass effects, shifting, drag, surface-dependent braking distances, load transfer, roll/yaw, shared grip and timestep stability.

`Godot --headless --path . --script tests/rider_character_smoke.gd` checks outfit retention, IK, all four strikes and hit windows, detached ragdoll flight, local ground contacts, vaulting a parked sedan and reset. Generated asset prompts: `assets/CHARACTER_GENERATION.md`.
