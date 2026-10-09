# Controls and input reference

**Important:** These are **semantic gameplay actions**, not asserted exact Genesis button mappings. The original three-button controller and six-button controller, as well as game/version-specific combinations, require verification from manuals or recorded gameplay. Do not copy mappings from PlayStation or 3DO versions.

## Required action set

| Action | Behavior | Context |
|---|---|---|
| Accelerate | Increase speed toward motorcycle-specific top speed | Racing |
| Brake | Reduce speed; prepare for sharp turns or traffic | Racing |
| Steer left / right | Change lateral road position and rider lean | Racing |
| Attack left / right | Strike an opponent within side-specific range | Racing near rider |
| Kick / punch | Select melee move according to input and equipment | Racing near rider |
| Use held weapon | Perform weapon-specific attack, if equipped | Racing near rider |
| Pause | Suspend active simulation and show options | Racing |
| Confirm / cancel | Navigate menus, garage and race results | Menus |

**Original:** Directional steering, throttle/braking and side-oriented fighting are central. Some attacks depend on button combinations and held weapons. Exact combinations differ across versions and must be verified.

## Proposed modern keyboard layout (not original)
- Arrow Up: accelerate; Arrow Down: brake.
- Arrow Left/Right: steer.
- A / D: attack left/right.
- S: kick; Space: punch/weapon action.
- Escape: pause; Enter: confirm.

## Proposed controller layout (not original)
- Left stick or D-pad: steering.
- Right trigger: accelerate; left trigger: brake.
- Left/right shoulder: side-specific attacks.
- Face buttons: kick and punch/weapon action.
- Start: pause.

## Input design rules
1. Racing and attack actions must be independently buffered for a short, configurable interval.
2. Attacks must not reverse steering direction or steal throttle input.
3. Menu input should repeat only after an initial delay.
4. Allow remapping, readable prompts and reduced-motion options in a new implementation.
5. Document actual original inputs only after manual or gameplay evidence is attached.

## Source starting points
- [Road Rash 3 game entry](https://www.mobygames.com/game/12343/road-rash-3/)
- [Road Rash 3 manual archive search](https://archive.org/search?query=Road+Rash+3+manual)
