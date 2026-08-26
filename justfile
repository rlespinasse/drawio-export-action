#!/usr/bin/env -S just --justfile

set quiet := true

# Default docker image name
docker_image := env_var_or_default("DOCKER_IMAGE", "rlespinasse/drawio-export-action:local")

default:
  just --choose

# Build the Docker image
[group('Development mode')]
build:
  docker build -t {{docker_image}} .

# Run the Docker container
[group('Development mode')]
run *ARGS:
  docker run -it -v {{invocation_directory()}}:/data {{docker_image}} {{ARGS}}

# Install the test dependencies (bats)
[group('Testing mode')]
setup-test:
  npm install bats

# Unit tests of 'src/lib.sh', no Docker image needed
[group('Testing mode')]
unit-test:
  npx bats -r tests/unit

# Clean up test artifacts
[group('Testing mode')]
cleanup:
  find tests -name "export" | xargs -I {} rm -r "{}"
  find tests -name "test-*" | xargs -I {} rm -r "{}"
  rm -rf tests/output

# Run tests
[group('Testing mode')]
test: cleanup build
  mkdir -p tests/output
  DOCKER_IMAGE={{docker_image}} npx bats -r tests
