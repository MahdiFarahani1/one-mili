# Asset credits

## Original generated art

The five background paintings, launcher icon and ten gameplay sprites were generated for this project using the built-in ImageGen tool. All are bundled locally; the game does not fetch imagery at runtime. Original transparent sprite images are kept in `assets/sprites/raw/`; trimmed and downscaled runtime textures are in `assets/sprites/`.

Prompt set, condensed:

- **Candy Clouds:** moody twilight fantasy kingdom, floating stone ruins, pink blossom trees, distant moonlit castle, waterfalls, amber lanterns and cyan crystal accents, open dark gameplay center, no UI or text.
- **Jelly Jungle:** enchanted night forest with mossy ruins, bioluminescent mushrooms, cyan leaves, amber fireflies and deep indigo shadows, open gameplay center, no UI or text.
- **Crystal Dreams:** ancient sapphire and amethyst crystal cathedral, reflective pools, waterfalls and cinematic cool rim light, open gameplay center, no UI or text.
- **Moonlight Magic:** enormous moon, gothic castle, suspended ruins, violet clouds, stars and warm lantern accents, open gameplay center, no UI or text.
- **Toy Factory:** night clockwork workshop with bronze gears, blue glass tubes, amber furnaces, magical steam and stone arches, open gameplay center, no UI or text.
- **Launcher icon:** a single smiling pink jelly creature among pastel clouds and gold stars, centered and readable at small size, no text.
- **World platforms (five):** side-view modular fantasy architecture, flat walkable top and detailed underside. Candy: moonlit masonry, blossoms and blue crystals. Jungle: moss, roots and luminous plants. Crystal: faceted blue-violet mineral arches. Moon: violet night stone and starlight. Factory: bronze clockwork, gears and amber highlights. Transparent backgrounds, no labels.
- **Saw:** ornate rotating bronze and dark-steel wheel with readable sharp teeth, glowing violet core, transparent background.
- **Portal:** luminous circular violet-blue magical stone gate, open transparent center, transparent background.
- **Collectible crystal:** faceted warm-gold gem with a crisp silhouette and transparent background.
- **Laser emitter:** side-view ornamental bronze mechanical projector with a bright red lens, transparent background.
- **Jelly body:** faceless pearlescent cyan-lavender magical orb with inner gold starlight, transparent background. The 15 skin color variants were derived locally from this original using `tests/process_jelly_skins.gd`; facial expressions and squash/stretch are rendered in Godot.

## Font

Vazirmatn by the Vazirmatn Project Authors, from [Google Fonts](https://github.com/google/fonts/tree/main/ofl/vazirmatn), licensed under SIL Open Font License 1.1. The license is bundled at `fonts/OFL.txt`.

## Audio

Original synthesized audio generated at runtime by `systems/sound.gd`; no third-party audio files are used.
