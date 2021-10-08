# Drawio Export Action

[![Build Status][1]][2]
![Linter Status][3]
[![Public workflows that use this action.][4]][5]
[![Licence][6]][7]

This GitHub Action will export Drawio Files based on [drawio-export][8] docker image.

## Inputs

### `path`

Path to the drawio files to export. Default `"."`.

### `format`

Exported format. Default `"pdf"`.

Possible values: adoc, jpg, pdf, png, svg, vsdx, xml

### `output`

Exported folder name. Default `"export"`.

### `remove_page_suffix`

Remove page suffix when possible (in case of single page file)

### `border`

Sets the border width around the diagram. Default `"0"`.

### `scale`

Scales the diagram size

### `width`

Fits the generated image/pdf into the specified width, preserves aspect ratio

### `height`

Fits the generated image/pdf into the specified height, preserves aspect ratio

### `crop`

crops PDF to diagram size

### `embed_diagram`

Includes a copy of the diagram for PNG or PDF

### `transparent`

Set transparent background for PNG

### `quality`

Output image quality for JPEG. Default `"90"`.

### `uncompressed`

Uncompressed XML output

## Example usage

> Export draw.io files inside folders tree of `folder/of/drawio/files` to png files using transparent background

```yaml
uses: rlespinasse/drawio-export-action@v1.x
with:
  path: folder/of/drawio/files
  format: png
  transparent: true
```

> `.github/workflows/drawio-export.yml` - Workflow to keep your draw.io export synchrinized

```yaml
name: Keep draw.io export synchronized
on:
  push:
    branches:
      - main
    paths:
      - "**.drawio"
      - .github/workflows/drawio-export.yml
jobs:
  drawio-export:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout sources
        uses: actions/checkout@v2
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Export drawio files to asciidoctor and png files
        uses: rlespinasse/drawio-export-action@v1.x
        with:
          format: adoc
          output: drawio-assets
          transparent: true

      - name: Get author and committer info from HEAD commit
        uses: rlespinasse/git-commit-data-action@v1.x

      - name: Commit changed files
        uses: stefanzweifel/git-auto-commit-action@v4.9.2
        with:
          commit_message: "docs: sync draw.io exported files"
          commit_user_name: "${{ env.GIT_COMMIT_COMMITTER_NAME }}"
          commit_user_email: "${{ env.GIT_COMMIT_COMMITTER_EMAIL }}"
          commit_author: "${{ env.GIT_COMMIT_AUTHOR }}"
```

[1]: https://github.com/rlespinasse/drawio-export-action/workflows/Build/badge.svg
[2]: https://github.com/rlespinasse/drawio-export-action/actions
[3]: https://github.com/rlespinasse/drawio-export-action/workflows/Lint/badge.svg
[4]: https://img.shields.io/endpoint?url=https%3A%2F%2Fapi-git-master.endbug.vercel.app%2Fapi%2Fgithub-actions%2Fused-by%3Faction%3Drlespinasse%2Fdrawio-export-action%26badge%3Dtrue
[5]: https://github.com/search?o=desc&q=rlespinasse/drawio-export-action+path%3A.github%2Fworkflows+language%3AYAML&s=&type=Code
[6]: https://img.shields.io/github/license/rlespinasse/drawio-export-action
[7]: https://github.com/rlespinasse/drawio-export-action/blob/v1.x/LICENSE
[8]: https://github.com/rlespinasse/drawio-export
