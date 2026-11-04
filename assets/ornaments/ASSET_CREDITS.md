# World ornaments

Five transparent environment illustrations were generated with OpenAI ImageGen for this project on 2026-11-03. The large originals are in `raw/`; the optimized game textures are in this folder.

| World | Source | Game texture | Creative brief |
| --- | --- | --- | --- |
| Sky | `raw/sky_shrine.png` | `sky_shrine.png` | Floating golden sky shrine with turquoise cloud and delicate ornaments |
| Forest | `raw/forest_tree.png` | `forest_tree.png` | Luminous enchanted forest tree with glowing mushrooms |
| Crystal | `raw/crystal_obelisk.png` | `crystal_obelisk.png` | Faceted blue violet crystal obelisk with ancient gold framing |
| Cosmic | `raw/cosmic_observatory.png` | `cosmic_observatory.png` | Magical brass observatory and celestial rings |
| Factory | `raw/factory_drone.png` | `factory_drone.png` | Friendly ornate clockwork drone with warm lights |

Each brief requested a single isolated, game ready illustration on a transparent background. `tests/process_ornaments.gd` crops transparent margins and reduces the maximum dimension to 512 pixels for runtime use. The `raw/` folder is ignored by Godot's importer and excluded from the Android export. These props are decorative and have no collision.
