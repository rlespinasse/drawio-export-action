#!/usr/bin/env bats

setup() {
  load 'test_helper'
  load_lib
  reset_inputs
  # Inputs having a default value in 'action.yml'
  INPUT_PATH="."
  INPUT_FORMAT="pdf"
  INPUT_OUTPUT="export"
  INPUT_BORDER="0"
  INPUT_QUALITY="90"
  INPUT_EMBED_SVG_FONTS="true"
  INPUT_SVG_THEME="light"
  INPUT_SVG_LINKS_TARGET="auto"
  # 'build_args_array' expects 'resolve_reference' to have run first,
  # an empty reference standing for "export the whole repository"
  reference=""
}

# Compare the built arguments to the expected ones
assert_args() {
  build_args_array
  local expected="$*"
  local actual="${args_array[*]}"
  if [ "${actual}" != "${expected}" ]; then
    echo "expected: ${expected}"
    echo "actual  : ${actual}"
    return 1
  fi
}

@test "default inputs" {
  assert_args --format pdf --output export --border 0 --quality 90 \
    --embed-svg-fonts true --svg-theme light --svg-links-target auto .
}

@test "mandatory inputs are always passed through" {
  INPUT_PATH="folder/of/drawio/files"
  INPUT_FORMAT="png"
  INPUT_OUTPUT="drawio-assets"
  INPUT_BORDER="10"
  INPUT_QUALITY="95"
  assert_args --format png --output drawio-assets --border 10 --quality 95 \
    --embed-svg-fonts true --svg-theme light --svg-links-target auto \
    folder/of/drawio/files
}

@test "boolean inputs set to true add their flag" {
  INPUT_EMBED_DIAGRAM="true"
  INPUT_REMOVE_PAGE_SUFFIX="true"
  INPUT_TRANSPARENT="true"
  INPUT_UNCOMPRESSED="true"
  INPUT_CROP="true"
  INPUT_ENABLE_PLUGINS="true"
  INPUT_EMBED_SVG_IMAGES="true"
  INPUT_ALL_PAGES="true"
  assert_args --format pdf --output export --border 0 --quality 90 \
    --embed-diagram --remove-page-suffix --transparent --uncompressed --crop \
    --enable-plugins --embed-svg-images --all-pages \
    --embed-svg-fonts true --svg-theme light --svg-links-target auto .
}

@test "boolean inputs set to false add no flag" {
  INPUT_EMBED_DIAGRAM="false"
  INPUT_REMOVE_PAGE_SUFFIX="false"
  INPUT_TRANSPARENT="false"
  INPUT_UNCOMPRESSED="false"
  INPUT_CROP="false"
  INPUT_ENABLE_PLUGINS="false"
  INPUT_EMBED_SVG_IMAGES="false"
  INPUT_ALL_PAGES="false"
  assert_args --format pdf --output export --border 0 --quality 90 \
    --embed-svg-fonts true --svg-theme light --svg-links-target auto .
}

@test "optional valued inputs are added when set" {
  INPUT_SCALE="2"
  INPUT_HEIGHT="100"
  INPUT_WIDTH="200"
  assert_args --format pdf --output export --border 0 --quality 90 \
    --scale 2 --height 100 --width 200 \
    --embed-svg-fonts true --svg-theme light --svg-links-target auto .
}

@test "svg inputs are added with their value" {
  INPUT_FORMAT="svg"
  INPUT_EMBED_SVG_FONTS="false"
  INPUT_SVG_THEME="dark"
  INPUT_SVG_LINKS_TARGET="new-win"
  assert_args --format svg --output export --border 0 --quality 90 \
    --embed-svg-fonts false --svg-theme dark --svg-links-target new-win .
}

@test "empty svg inputs are not added" {
  INPUT_EMBED_SVG_FONTS=""
  INPUT_SVG_THEME=""
  INPUT_SVG_LINKS_TARGET=""
  assert_args --format pdf --output export --border 0 --quality 90 .
}

@test "a reference activates the on-changes options" {
  reference="c0ffee"
  assert_args --format pdf --output export --border 0 --quality 90 \
    --embed-svg-fonts true --svg-theme light --svg-links-target auto \
    --on-changes --git-ref c0ffee .
}

@test "building the args twice does not accumulate them" {
  build_args_array
  assert_args --format pdf --output export --border 0 --quality 90 \
    --embed-svg-fonts true --svg-theme light --svg-links-target auto .
}
