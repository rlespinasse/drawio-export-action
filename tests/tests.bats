#!/usr/bin/env bats

@test "with adoc format" {
  docker_test 0 "adoc" -e INPUT_PATH=nominal -e INPUT_FORMAT=adoc -e INPUT_TRANSPARENT=true
}

@test "with jpg format" {
  docker_test 0 "jpg" -e INPUT_PATH=nominal -e INPUT_FORMAT=jpg -e INPUT_QUALITY=95
}

@test "with pdf format" {
  docker_test 0 "pdf" -e INPUT_PATH=nominal -e INPUT_FORMAT=pdf -e INPUT_CROP=true -e INPUT_EMBED-DIAGRAM=true
}

@test "with png format" {
  docker_test 0 "png" -e INPUT_PATH=nominal -e INPUT_FORMAT=png -e INPUT_TRANSPARENT=true -e INPUT_EMBED-DIAGRAM=true
}

@test "with svg format" {
  docker_test 0 "svg" -e INPUT_PATH=nominal -e INPUT_FORMAT=svg
}

@test "with vsdx format" {
  docker_test 0 "vsdx" -e INPUT_PATH=nominal -e INPUT_FORMAT=vsdx
}

@test "with xml format" {
  docker_test 0 "xml" -e INPUT_PATH=nominal -e INPUT_FORMAT=xml -e INPUT_UNCOMPRESSED=true
}

@test "with general options" {
  docker_test 0 "pdf" -e INPUT_PATH=nominal -e INPUT_OUTPUT=test-output -e INPUT_REMOVE-PAGE-SUFFIX=true -e INPUT_BORDER=1 -e INPUT_SCALE=1 -e INPUT_HEIGHT=100 -e INPUT_WIDTH=100
}

docker_test() {
  local status=$1
  local output_file=$2
  shift
  shift
  run docker container run -t -e INPUT_PATH=. -e INPUT_FORMAT=pdf -e INPUT_OUTPUT=export -e INPUT_BORDER=0 -e INPUT_QUALITY=90 "$@" -w /data -v $(pwd)/tests/data:/data ${DOCKER_IMAGE}

  echo "$output" > "tests/output/$output_file.log"

  [ "$status" -eq $status ]
  if [ -f "tests/expected/$output_file.log" ]; then
    [ "$(diff --strip-trailing-cr <(echo "$output") "tests/expected/$output_file.log")" = "" ]
  fi
}
