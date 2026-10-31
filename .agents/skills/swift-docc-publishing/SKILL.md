---
name: swift-docc-publishing
description: Complete deployment guide for Swift DocC documentation: CLI compilation flags, static hosting transforms, base paths, local live preview servers, and automated GitHub Pages workflows.
---

# Swift DocC Static Hosting & Publishing

- Compile static documentation archives with `--transform-for-static-hosting` and `--hosting-base-path`.
- Preview documentation locally with `swift package --disable-sandbox preview-documentation`.
- Automate documentation builds and GitHub Pages deployments in CI workflows with zero broken link warnings.

---

# Swift DocC publishing and deployment

This skill provides step-by-step instructions, CLI flag references, and CI/CD pipelines for compiling Swift DocC documentation into static websites, previewing them locally, and hosting them on GitHub Pages or static web servers.

# References
- `references/hosting-and-ci-cd.md`: Consult when configuring CLI compilation flags, setting `--hosting-base-path` for GitHub Pages, previewing static sites locally, configuring GitHub Actions workflows, or troubleshooting 404/SPA routing issues.

---

## 1. Compilation methods overview

DocC documentation can be compiled using either the **Swift Package Manager DocC Plugin** (`swift-docc-plugin`) or direct invocations of **`xcrun docc`** / **`docc`**.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          DocC compilation pipeline                       │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │
         ┌───────────────────────────┴───────────────────────────┐
         ▼                                                       ▼
┌─────────────────────────────────┐             ┌─────────────────────────────────┐
│     Swift Package Manager       │             │       Direct DocC CLI           │
│  swift package                  │             │  xcrun docc convert             │
│  generate-documentation         │             │  (lower-level, custom pipelines)│
└────────────────┬────────────────┘             └────────────────┬────────────────┘
                 │                                               │
                 └───────────────────────┬───────────────────────┘
                                         ▼
                        ┌─────────────────────────────────┐
                        │     Static hosting transform    │
                        │  --transform-for-static-hosting │
                        │  --hosting-base-path <repo>     │
                        │  --output-path <dir>            │
                        └────────────────┬────────────────┘
                                         ▼
                        ┌─────────────────────────────────┐
                        │     Deployment targets          │
                        │  GitHub Pages, Cloudflare, S3   │
                        └─────────────────────────────────┘
```

---

## 2. Essential CLI flags reference

When generating static documentation for the web, three flags are essential:

| Flag | Description | When to Use |
| :--- | :--- | :--- |
| `--transform-for-static-hosting` | Generates a static HTML/JS/CSS client-side router build ready for standard web servers. | **Mandatory** for hosting on GitHub Pages, Cloudflare Pages, Netlify, or Amazon S3. |
| `--hosting-base-path <path>` | Sets the base URL path prefix for all routing, scripts, and media requests (e.g., `<repo-name>`). | **Mandatory** when hosting on GitHub Pages under a project repository URL (`https://<user>.github.io/<repo-name>/`). Omit for root user/org domains. |
| `--output-path <path>` | Specifies the output destination folder where HTML, CSS, JavaScript, and JSON data are written. | Always specify an explicit path (e.g., `.build/docc-static` or `docs`). |
| `--disable-indexing` | Skips client-side search index generation (`index/`). | Optional: use in resource-constrained CI to accelerate builds when search is not needed. |

---

## 3. Compiling with Swift Package Manager

### Using the Swift-DocC plugin

Add the official Swift-DocC plugin to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
]
```

### Compiling static documentation for GitHub Pages

Run `swift package generate-documentation` with the static hosting flags:

```bash
swift package --allow-writing-to-directory ./docs \
    generate-documentation \
    --target MyLibrary \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path my-repo-name \
    --output-path ./docs
```

> [!IMPORTANT]
> **Base Path Formatting**:
> - **Project Pages** (`https://<user>.github.io/<repo-name>/`): Pass `--hosting-base-path <repo-name>` (omit leading and trailing slashes). For `https://peterfriese.github.io/swift-docc-skills/`, use `--hosting-base-path swift-docc-skills`.
> - **User or Organization Pages** (`https://<user>.github.io/`): Omit `--hosting-base-path` entirely so all asset paths resolve from the root domain `/`.

---

## 4. Compiling with `xcrun docc` directly

If you prefer compiling directly using Xcode's embedded toolchain:

```bash
# 1. Dump symbol graphs
swift package dump-symbol-graph

# 2. Convert documentation catalog and symbols into static web output
xcrun docc convert Sources/MyLibrary/MyLibrary.docc \
    --fallback-display-name MyLibrary \
    --fallback-bundle-identifier com.example.MyLibrary \
    --fallback-bundle-version 0.1.0 \
    --additional-symbol-graph-dir .build/extracted-symbols \
    --transform-for-static-hosting \
    --hosting-base-path my-repo-name \
    --output-path ./docs
```

---

## 5. Local live preview

### Option A: Built-in SwiftPM live preview server

The Swift-DocC plugin includes a live development server that automatically rebuilds and refreshes when files change:

```bash
swift package --disable-sandbox preview-documentation --target MyLibrary
```

This starts a local server at `http://localhost:8080/documentation/mylibrary`.

### Option B: Previewing static export via Python HTTP server

To preview the exact static artifact that will be deployed to GitHub Pages:

```bash
# Generate static build with root base path
swift package --allow-writing-to-directory .build/docc-static \
    generate-documentation \
    --target MyLibrary \
    --transform-for-static-hosting \
    --output-path .build/docc-static

# Run local HTTP server
python3 -m http.server 8000 --directory .build/docc-static
```

Open `http://localhost:8000/documentation/mylibrary` or `http://localhost:8000/tutorials/mycurriculum` in your browser.

---

## 6. Automated GitHub Pages CI/CD workflow

Create `.github/workflows/documentation.yml` in your repository:

```yaml
name: Deploy DocC Documentation to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

# Sets permissions of the GITHUB_TOKEN to allow deployment to GitHub Pages
permissions:
  contents: read
  pages: write
  id-token: write

# Allow one concurrent deployment
concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: macos-15
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.2.app

      - name: Generate Static DocC Documentation
        run: |
          swift package --allow-writing-to-directory ./docs \
            generate-documentation \
            --target MyLibrary \
            --disable-indexing \
            --transform-for-static-hosting \
            --hosting-base-path "${{ github.event.repository.name }}" \
            --output-path ./docs

      - name: Verify Myers Diff Highlights
        run: |
          if [ -f "scripts/audit-docc-highlights.py" ]; then
            python3 scripts/audit-docc-highlights.py ./docs/data/tutorials --allow-empty
          fi

      - name: Upload GitHub Pages Artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./docs

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## 7. Common deployment troubleshooting

### Issue 1: Blank screen or 404 on CSS/JS assets
- **Cause**: Incorrect `--hosting-base-path`. If your GitHub repository is `username/my-lib`, the site lives at `https://username.github.io/my-lib/`.
- **Solution**: Pass `--hosting-base-path my-lib` during generation.

### Issue 2: Direct page links return 404 on static hosts
- **Cause**: DocC produces a Single Page App (SPA). Navigating directly to `https://site.com/documentation/target/symbol` requires fallback routing to `index.html`.
- **Solution**: `--transform-for-static-hosting` creates routing fallback index files automatically. Ensure your web server does not rewrite paths or strip HTML extensions.

### Issue 3: Interactive tutorials fail to display code highlights
- **Cause**: Myers diff brace shift defect in compiled tutorial JSON files.
- **Solution**: Run `scripts/audit-docc-highlights.py ./docs/data/tutorials` in CI to catch and remediate brace shifts before publishing.
