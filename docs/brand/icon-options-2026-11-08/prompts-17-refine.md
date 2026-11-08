# Refinement prompts for option 17 (codex exec, built-in image generation, 8 November 2026)

You are refining one approved app-icon concept for "Bin Day NZ", an iPhone app that tells New Zealand households which council kerbside bins go out and when. Use your built-in image generation tool (the latest GPT Image model) once per image below. Do not write code, do not create SVGs, do not ask questions.

The approved concept (keep it exactly): two horizontal rows of seven small matte spheres, a fortnight of days. The fourth sphere in the top row is recycling yellow (#F5C016) and floats raised above its row, casting a soft shadow on the ground where it would sit. The fifth sphere in the bottom row is food-scraps green (#2E8B42) and sits in line with its row. All other twelve spheres are matte off-white (#F3F2EE). Soft 3D render, gentle matte shading with a broad soft highlight from the upper left, no reflections, no specular hot spots, soft contact shadows. Rows are centred vertically in the square with generous empty space above and below. Nothing else in the image.

Rules for every image:
- Square 1024x1024 artwork, full bleed, no rounded corners (iOS adds them), no border, no text, no letters, no numbers, no watermark.
- Strong silhouette that still reads at 60 px. Clean edges, no clutter, no extra decorative elements.
- Finished production-quality icon art, one icon per image, no device frames, no mockup sheets.

Generate these two images. After each image is generated, copy the PNG file from your generated-images folder into the current working directory with the exact filename given (for example `cp "<generated path>" ./17b-week-dots-bold.png`).

17b-week-dots-bold.png
Primary request: the approved concept, but bolder for small sizes: the spheres are larger so the two rows together fill 84 percent of the width with small even gaps between spheres, the contact shadows are a little stronger and the backdrop is a slightly deeper warm grey (#D9D4CC) so the off-white spheres separate clearly from it
Style/medium: soft matte 3D render, gentle shading, soft contact shadows, no reflections
Backdrop: warm grey #D9D4CC, smooth, no texture, no vignette
Composition: both rows centred, grid fills 84 percent of the width, rows close together
Mood: a calendar abstracted, calm, modern

17c-week-dots-dark.png
Primary request: the approved concept at the same bold scale, on a near-black charcoal backdrop, the off-white spheres gently lit from the upper left, the yellow and green spheres the same colours as in the light version
Style/medium: soft matte 3D render, gentle shading, soft contact shadows on the dark ground, no reflections
Backdrop: near-black charcoal #15181B, smooth, no texture, no vignette
Composition: identical to the bold light version, grid fills 84 percent of the width
Mood: the same calendar at night, calm, modern

When both files exist in the current working directory, finish with a short list of the filenames and one line each on what was generated.
