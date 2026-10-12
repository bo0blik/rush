# Traffic sprites

Generated with the built-in imagegen tool, after the earlier connection failures. Original RGBA PNGs copied intact into the project; no image editing or API fallback.

- `traffic_vaz2106.png`: cream VAZ-2106 sedan.
- `traffic_gaz3307.png`: blue GAZ-3307 truck with olive canvas.

Both are 1536x1024, with three views in each of two rows. Top row: rear center, rear showing left side, rear showing right side. Bottom row: front center, front showing left side, front showing right side. Generated poses are not aligned to exact 512px columns: use the twelve fitted AtlasTexture resources in `demo/resources/traffic/` instead of uniform grid slicing. Regions were measured from alpha at the 0.5 cutoff and include 2px padding. No source PNG pixels were modified. Use nearest filtering and alpha discard at 0.5 to suppress faint background alpha. Vehicle scenes anchor the fitted frame bottoms to the road and keep a common pixel scale. Working traffic is integrated in `scenes/traffic.tscn`.

## Final sedan prompt

Draw a production pixel-art traffic sprite sheet of a cream Soviet VAZ-2106 sedan for a classic motorcycle racing game. 1536x1024 canvas, genuine transparent background. Exactly 3 columns x 2 rows, six equally sized cells with transparent margins. Top row rear view: straight, gently turned showing left side, gently turned showing right side. Bottom row front view: straight, gently turned showing left side, gently turned showing right side. Same vehicle, consistent scale, boxy Zhiguli proportions, chrome bumpers, four round headlights, blue-reflecting windows, dark tires, rectangular red tail lights. Slightly elevated chase-camera perspective, not isometric. Crisp detailed 16-bit pixel art, clear dark outlines, warm sunlight, chunky deliberate pixel clusters, rich colors, matching Road Rash-inspired Russian forest road concepts. Center each sprite, tire contact at 88 percent cell height. No ground, scenery, shadows cast on ground, text, labels, logos, grid, HUD. Transparent alpha outside cars.

## Final truck prompt

Draw a production pixel-art traffic sprite sheet of a blue Soviet GAZ-3307 cargo truck with gray olive canvas-covered cargo bed for a classic motorcycle racing game. 1536x1024 canvas, genuine transparent background. Exactly 3 columns x 2 rows, six equally sized cells with transparent margins. Top row rear view: straight, gently turned showing left side, gently turned showing right side. Bottom row front view: straight, gently turned showing left side, gently turned showing right side. Same vehicle and consistent scale across cells, square blue cab, round headlights, dark grille and bumper, heavy black tires, blue cargo-bed rails, taut olive gray canvas. Slightly elevated chase-camera perspective, not isometric. Crisp detailed 16-bit pixel art, clear dark outlines, warm sunlight, chunky deliberate pixel clusters, rich colors, matching Road Rash-inspired Russian mountain forest road concepts. Center each sprite, tire contact at 88 percent cell height. No ground, scenery, shadows cast on ground, text, labels, logos, grid, HUD. Transparent alpha outside trucks.
