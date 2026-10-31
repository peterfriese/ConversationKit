# DocC starter templates

This directory provides starter templates and bundled placeholder assets for building documentation catalogs (`.docc`) with Swift DocC.

## Contents

- `tutorials/TableOfContents.tutorial`: Complete `@Tutorials` table of contents curriculum page.
- `tutorials/StepByStep.tutorial`: Complete `@Tutorial` step-by-step page with synchronized code steps and assessments.
- `tutorials/MicroPrototype.tutorial`: Rapid 5-minute single-file prototype tutorial page adhering to the 3–5 step rule.
- `tutorials/ConceptualArticle.article`: Complete `@Article` page for conceptual topics with `@ContentAndMedia` stacks and assessments.
- `tutorials/WrapUp.article`: Standard conclusion `@Article` celebrating milestones and curating next-step resources.
- `tutorials/DiagramTemplate.svg`: Vector diagram starter canvas pre-configured with the Apple Cupertino palette and the 10px defensive bounding-box rule.
- `reference/PackageLandingPage.md`: Module landing page with curated `## Topics`.
- `Resources/`:
  - `images/`: Cupertino-grade SVG vector graphics and diagrams with automatic `~dark.svg` pairing for hero slots, chapter cards, and conceptual workflows.
  - `code/`: Sequential Swift code step files for tutorial diffing.
  - `downloads/`: Sample starter and completed project zip archives.

## Usage

1. Copy the desired `.tutorial` or `.article` file into your `.docc/Tutorials/` folder.
2. Copy or replace the corresponding assets in your `.docc/Resources/` folder.
3. Replace the placeholder titles, descriptions, and media with your project's content.
