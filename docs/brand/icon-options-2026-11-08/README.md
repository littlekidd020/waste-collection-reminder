# App icon options, 8 November 2026

Twenty-four 1024 x 1024 icon candidates for Bin Day NZ, generated with Codex image generation (GPT Image 2) from written concepts, then reviewed at 180, 60 and 29 px on the design canvas (https://claude.ai/artifact/NtCiPULTBksHVGKeso8vim).

- `01` to `12`: round one, illustrative and 3D (prompts in `prompts-01-08.md` and `prompts-09-12.md`).
- `13` to `24`: round two, abstract and modern, drawn from the reference set's language (prompts in `prompts-13-24.md`).

None is approved yet. The chosen one needs a cleanup pass, alternates in the other lid colours, a wordmark, and a trademark search before it replaces `BinDayNZ/Assets.xcassets/AppIcon.appiconset`. Option 21 (two overlapping circles) sits close to a well-known payment mark and should not ship as drawn.

## Decision, 8 November 2026

Option 17, Week dots, was chosen. A refinement round (`17b-week-dots-bold.png`,
`17c-week-dots-dark.png`, prompts in `prompts-17-refine.md`) tested a bolder scale and a
dark ground; the production icon was then rebuilt as geometry in `../icon/` and
`scripts/make-app-icon.py`, and the asset catalog now carries light, dark and tinted
1024 px variants. The other twenty-three options stay here as the record of the exploration.
