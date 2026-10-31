# Static hosting, CLI compilation, and GitHub Actions CI/CD

This reference provides detailed deployment workflows, CLI flag specifications, local preview commands, and GitHub Actions configuration for hosting Swift DocC documentation on static web servers and GitHub Pages.

---

## 1. CLI compilation flags in depth

When publishing static DocC documentation for web servers, four flags govern routing, formatting, and search indexing:

| Flag | Purpose | Requirements & Behavior |
| :--- | :--- | :--- |
| `--transform-for-static-hosting` | Generates a static HTML/JS/CSS client-side router build. | **Mandatory** for GitHub Pages, Cloudflare Pages, S3, Netlify. Generates router fallback HTML files. |
| `--hosting-base-path <path>` | Sets the URL path prefix for all routing, scripts, styles, and images. | **Mandatory** for GitHub project sites (`https://<user>.github.io/<repo>/`). Must omit leading/trailing slashes. |
| `--output-path <path>` | Sets the destination directory for output files. | Required in custom build scripts (e.g., `./docs` or `.build/docc-static`). |
| `--disable-indexing` | Skips client-side search index compilation (`index/`). | Optional: Accelerates CI build times when full-text search is not required. |

---

## 2. Base path formatting rules

Incorrect base paths are the primary cause of blank screens and 404 errors on static sites.

### Project repository pages
- **Repository URL**: `https://github.com/peterfriese/swift-docc-skills`
- **Site URL**: `https://peterfriese.github.io/swift-docc-skills/`
- **Base path argument**: `--hosting-base-path swift-docc-skills`
- **Rule**: Never include leading or trailing slashes (e.g., use `swift-docc-skills`, not `/swift-docc-skills/`).

### User or organization root pages
- **Repository URL**: `https://github.com/username/username.github.io`
- **Site URL**: `https://username.github.io/`
- **Base path argument**: *Omit `--hosting-base-path` entirely*.
- **Rule**: When omitted, asset links resolve from the root domain `/`.

---

## 3. Local live preview options

### Option A: Built-in SwiftPM preview server
Automatically compiles documentation and starts a local development server that detects file changes:

```bash
swift package --disable-sandbox preview-documentation --target MyTarget
```
Access in your browser at `http://localhost:8080/documentation/mytarget`.

### Option B: Static export preview via Python
Simulates the exact production artifact that will be published to GitHub Pages:

```bash
# 1. Compile static documentation
swift package --allow-writing-to-directory .build/docc-static \
    generate-documentation \
    --target MyTarget \
    --transform-for-static-hosting \
    --output-path .build/docc-static

# 2. Run local HTTP server
python3 -m http.server 8000 --directory .build/docc-static
```
Open `http://localhost:8000/documentation/mytarget` in your browser.

---

## 4. Production GitHub Actions workflow

Create `.github/workflows/documentation.yml` with automated highlight validation:

```yaml
name: Deploy DocC Documentation to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

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
            --target MyTarget \
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
