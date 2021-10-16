#!/usr/bin/env bash

args_array+=(
  "--format" "${INPUT_FORMAT}"
  "--output" "${INPUT_OUTPUT}"
  "--border" "${INPUT_BORDER}"
  "--quality" "${INPUT_QUALITY}"
)

if [ "${INPUT_EMBED_DIAGRAM}" == "true" ]; then
  args_array+=("--embed-diagram")
fi

if [ "${INPUT_REMOVE_PAGE_SUFFIX}" == "true" ]; then
  args_array+=("--remove-page-suffix")
fi

if [ "${INPUT_TRANSPARENT}" == "true" ]; then
  args_array+=("--transparent")
fi

if [ "${INPUT_UNCOMPRESSED}" == "true" ]; then
  args_array+=("--uncompressed")
fi

if [ "${INPUT_CROP}" == "true" ]; then
  args_array+=("--crop")
fi

if [ -n "${INPUT_SCALE}" ]; then
  args_array+=("--scale" "${INPUT_SCALE}")
fi

if [ -n "${INPUT_HEIGHT}" ]; then
  args_array+=("--height" "${INPUT_HEIGHT}")
fi

if [ -n "${INPUT_WIDTH}" ]; then
  args_array+=("--width" "${INPUT_WIDTH}")
fi

args_array+=("${INPUT_PATH}")

echo Options: "${args_array[@]}"

/opt/drawio-exporter/runner-no-security-warnings.sh "${args_array[@]}"
