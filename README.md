# Drawio Export Action

This GitHub Action will export Drawio Files based on [drawio-export][1] Docker image.

## Example usage

> Export draw.io files inside folders tree of `folder/of/drawio/files` to png files using transparent background

```yaml
uses: rlespinasse/drawio-export-action@v2
with:
  path: folder/of/drawio/files
  format: png
  transparent: true
```

> `.github/workflows/drawio-export.yml` - Workflow to keep your draw.io export synchronized

```yaml
name: Keep draw.io export synchronized
on:
  push:
    branches:
      - main
    paths:
      - "**.drawio"
      - .github/workflows/drawio-export.yml
concurrency:
  group: drawio-export-${{ github.ref }}
  cancel-in-progress: true
jobs:
  drawio-export:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout sources
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Export drawio files to asciidoctor and png files
        uses: rlespinasse/drawio-export-action@v2
        with:
          format: adoc
          transparent: true
          output: drawio-assets

      - name: Get author and committer info from HEAD commit
        uses: rlespinasse/git-commit-data-action@v1
        if: github.ref == 'refs/heads/main'

      - name: Commit changed files
        uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: "docs: sync draw.io exported files"
          commit_user_name: "${{ env.GIT_COMMIT_COMMITTER_NAME }}"
          commit_user_email: "${{ env.GIT_COMMIT_COMMITTER_EMAIL }}"
          commit_author: "${{ env.GIT_COMMIT_AUTHOR }}"
        if: github.ref == 'refs/heads/main'
```

## Inputs

### `path`

Path to the drawio files to export. Default `"."`.

### `format`

Exported format. Default `"pdf"`.

Possible values: `adoc`, `md`, `jpg`, `pdf`, `png`, `svg`, `xml`

### `output`

Exported folder name. Default `"export"`.

> **Relative from the exported drawio file**
>
> A file from `/path/to/file.drawio` will be exported to `/path/to/export/file-{page}.{ext}` by default.

### `remove-page-suffix`

Remove page suffix when possible (in case of single page file)

### `border`

Sets the border width around the diagram. Default `"0"`.

### `scale`

Scales the diagram size

### `width`

Fits the generated `image/pdf` into the specified width, preserves aspect ratio

### `height`

Fits the generated `image/pdf` into the specified height, preserves aspect ratio

### `crop`

crops PDF to diagram size

### `embed-diagram`

Includes a copy of the diagram for PNG or PDF

### `transparent`

Set transparent background for PNG

### `quality`

Output image quality for JPEG. Default `"90"`.

### `uncompressed`

Uncompressed XML output

### `all-pages`

Export all pages (for PDF format only)

### `embed-svg-fonts`

Embed Fonts in SVG file. Default: `"true"`.

Possible values: `true`, `false`

### `svg-theme`

Theme of the exported SVG image. Default: `"light"`.

Possible values: `dark`, `light`

### `svg-links-target`

Target of links in the exported SVG image. Default: `"auto"`.

Possible values: `auto`, `new-win`, `same-win`

### `action-mode`

Export mode for this action. Default: auto

Possible values:

- **recent** export only the changed files since a calculated reference
  - previously pushed commit on `push` event
  - base commit on `pull request` event
- **all** export all drawio files without any filter
- **reference** export since the reference from `since-reference` option
- **auto** will choose the more appropriated mode
  - **reference** if `since-reference` option is set,
  - **recent** if the reference can be calculated,
  - **all** otherwise

CAUTION: When using a mode other than `all`, you need to checkout all the history.

  ```yaml
  - uses: actions/checkout@v3
    with:
      fetch-depth: 0
  ```

### `since-reference`

Git Reference serving as base for export. Only when action-mode is set to 'reference'.

## Miscellaneous

- [Additional fonts are available][2]

## Development

This action is being migrated to use pre-built Docker images hosted on GitHub Container Registry (ghcr.io) to provide fast execution without rebuilding the image on every run.

**Migration Status:**
- ✅ Workflow updated to build and push images to GHCR
- ⏳ action.yml still uses Dockerfile (will be updated after initial image publish)

**Planned Docker Image Tags:**
- `v2.x`: Will be updated on every push to the v2.x branch
- `v2`, `v2.X`, `v2.X.Y`: Will be created on releases for version pinning
- `pr-X`: Created for pull requests for verification

**After Migration:** Once the initial image is published to GHCR, action.yml will be updated to reference `docker://ghcr.io/rlespinasse/drawio-export-action:v2.x`, eliminating the ~1 minute build time for users.

**Note for maintainers**: Ensure the Docker image package on GHCR is set to public visibility so that users can pull the image when using the action.

[1]: https://github.com/rlespinasse/drawio-export
[2]: https://github.com/rlespinasse/drawio-export#additional-fonts
