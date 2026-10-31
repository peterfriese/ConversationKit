# DocC interactive tutorial directives catalog

This reference provides a comprehensive catalog of all DocC tutorial directives, their parent-child nesting rules, supported attributes, and syntax examples.

---

## 1. Directive nesting hierarchy

DocC strictly validates parent-child directive trees at compile time. Violating these relationships produces fatal compilation errors.

```
@Tutorials (Curriculum Table of Contents)
├── @Intro (Required: Hero intro banner & image)
│   └── @Image or @Video
├── @Volume (Optional: Groups chapters)
│   └── @Chapter
├── @Chapter (Required: 1 or more chapters)
│   ├── @Image
│   └── @TutorialReference (Links to @Tutorial or @Article)
└── @Resources (Required: Resource footer)
    ├── @Downloads
    ├── @Documentation
    ├── @SampleCode
    ├── @Videos
    └── @Forums

@Tutorial (Interactive Step-by-Step Page)
├── @XcodeRequirement (Optional: Tool requirements notice)
├── @Intro (Required: Hero introduction banner & image)
│   └── @Image or @Video
├── @Section (Required: 1 or more task sections)
│   ├── @ContentAndMedia (Required: Section overview & illustration)
│   │   └── @Image or @Video
│   └── @Steps (Required: 3–5 ordered steps)
│       └── @Step (3-Sentence Step Anatomy)
│           ├── @Code (name: "...", file: "...")
│           └── @Image or @Video
└── @Assessments (Required: Knowledge checks)
    └── @MultipleChoice (1 or more questions)
        ├── @Choice(isCorrect: true)
        │   └── @Justification(reaction: "...")
        └── @Choice(isCorrect: false)
            └── @Justification(reaction: "...")

@Article (Conceptual Guide / Wrap-Up Article)
├── @Intro (Required: Hero intro banner & image)
│   └── @Image or @Video
├── @ContentAndMedia (1 or more conceptual overview blocks)
│   └── @Image or @Video
├── @Stack (Optional: 2-3 column responsive container)
│   └── @ContentAndMedia
└── @Assessments (Optional: Knowledge checks)
    └── @MultipleChoice
```

---

## 2. Directives reference index

### Curriculum level

| Directive | Parent | Parameters | Purpose |
| :--- | :--- | :--- | :--- |
| `@Tutorials` | Root | `name: String` | Declares the table of contents landing page for a tutorial series. |
| `@Intro` | `@Tutorials`, `@Tutorial`, `@Article` | `title: String` | Provides the introductory banner, title, summary, and hero media. |
| `@Volume` | `@Tutorials` | `name: String` | Groups multiple related `@Chapter` blocks into major curriculum volumes. |
| `@Chapter` | `@Tutorials`, `@Volume` | `name: String` | Groups sequential tutorials and conceptual articles under a cohesive milestone. |
| `@TutorialReference` | `@Chapter` | `tutorial: "doc:<Name>"` | Links to an interactive `@Tutorial` or conceptual `@Article` page. |
| `@Resources` | `@Tutorials` | None | Defines the footer section containing download links and documentation pointers. |
| `@Downloads` | `@Resources` | `destination: String` | Provides download links for starter and completed project archives. |
| `@Documentation` | `@Resources` | `destination: String` | Curates external Apple Developer framework documentation links. |
| `@SampleCode` | `@Resources` | `destination: String` | Links to GitHub or sample code repositories. |
| `@Videos` | `@Resources` | `destination: String` | Links to relevant WWDC session videos. |
| `@Forums` | `@Resources` | `destination: String` | Links to Apple Developer Forums tags or topics. |

### Page and step level

| Directive | Parent | Parameters | Purpose |
| :--- | :--- | :--- | :--- |
| `@Tutorial` | Root | `time: Int`, `projectFiles: String` | Root container for step-by-step interactive pages. `time` in minutes. |
| `@XcodeRequirement` | `@Tutorial` | `title: String`, `destination: String` | Displays an informational badge indicating the minimum required Xcode version. |
| `@Section` | `@Tutorial` | `title: String` | Encapsulates a focused sub-task containing 3 to 5 steps. |
| `@ContentAndMedia` | `@Section`, `@Article`, `@Stack` | None | Provides contextual prose and a supporting diagram or illustration. |
| `@Steps` | `@Section` | None | Container for ordered `@Step` instructions. |
| `@Step` | `@Steps` | None | An individual instruction adhering to the 3-Sentence Step Anatomy. |
| `@Code` | `@Step` | `name: String`, `file: String`, `reset: Bool?`, `previousFile: String?` | Synchronizes code diffs against the preceding step. `file` relative to `Resources/code/`. |
| `@Stack` | `@Section`, `@Article` | None | Responsive multi-column layout displaying 2 or 3 `@ContentAndMedia` blocks side-by-side. |

### Assessment level

| Directive | Parent | Parameters | Purpose |
| :--- | :--- | :--- | :--- |
| `@Assessments` | `@Tutorial`, `@Article` | None | Container for end-of-page interactive knowledge checks. |
| `@MultipleChoice` | `@Assessments` | None | Declares a multiple-choice question. |
| `@Choice` | `@MultipleChoice` | `isCorrect: Bool` | Represents an individual answer choice. Exactly one per question must be `isCorrect: true`. |
| `@Justification` | `@Choice` | `reaction: String` | Explains *why* the choice is correct (`reaction: "Correct!"`) or why it is wrong (`reaction: "Try again."`). |
