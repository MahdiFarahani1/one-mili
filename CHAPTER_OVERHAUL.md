# One Millimeter — Five-chapter challenge overhaul (phase 1)

This branch begins the requested skill-based difficulty overhaul. It does **not** yet replace UI art or certify that the stages are beatable.

| Chapter | Primary skill | Gameplay direction | Visual art direction |
| --- | --- | --- | --- |
| 1 Sky Islands | Precision | Narrow landings, timing, learning gravity | Parallax clouds, floating ruins, airy warm light |
| 2 Enchanted Jungle | Rhythm | Oscillating hazards, safe timing windows | Deep layered foliage, glowing plants, mist |
| 3 Crystal Depths | Route reading | Multiple routes and hazard positioning | Refractive crystals, luminescent caves |
| 4 Orbital Void | Gravity mastery | Zero-gravity zones, portals, directional control | Nebulae, asteroids, dramatic rim lighting |
| 5 Clockwork Furnace | Full mastery | Moving hazards, tight gates, rapid decisions | Industrial machinery, sparks, molten light |

## Implemented
- A reusable chapter profile data source with named skills and distinct difficulty curves.
- Chapter-dependent gate-width adjustments and par-time/par-turn targets.
- Additional hazard patterns in later chapters, using existing stage hazard types.
- No modifications to the default branch; changes are proposed in a review branch.

## Next steps before merging
1. Run `godot --headless --path . --script res://tests/validate_all.gd`.
2. Run automated route solving and actual device playtesting for every stage; reject impossible and unfair patterns.
3. Redesign stages as authored encounters, not only parameterized gate layouts.
4. Build layered chapter-specific backgrounds, platform art, VFX, UI scenes and transitions; profile Android frame times.
5. Validate controls, tutorial, difficulty progression, accessibility, reward pacing and save compatibility.

**Important:** The current game already has five worlds and 60 levels. This work differentiates those existing worlds rather than claiming five brand-new worlds were added.
