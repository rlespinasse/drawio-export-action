#!/usr/bin/env bats
#
# Tests of the test isolation itself: 'src/lib.sh' is sourced into the bats
# process, so a leaking input silently changes the outcome of the next test.

setup() {
  load 'test_helper'
  load_lib
}

@test "reset_inputs unsets every INPUT_ variable, even an unknown one" {
  INPUT_ACTION_MODE="all"
  INPUT_A_BRAND_NEW_OPTION="leaking-value"
  reset_inputs
  [ -z "${INPUT_ACTION_MODE+set}" ]
  [ -z "${INPUT_A_BRAND_NEW_OPTION+set}" ]
}

@test "reset_inputs unsets the GITHUB_ variables inherited from a real workflow run" {
  GITHUB_EVENT_NAME="pull_request"
  GITHUB_HEAD_REF="a-branch"
  GITHUB_OUTPUT="/tmp/an-output-file"
  reset_inputs
  [ -z "${GITHUB_EVENT_NAME+set}" ]
  [ -z "${GITHUB_HEAD_REF+set}" ]
  [ -z "${GITHUB_OUTPUT+set}" ]
}

@test "reset_inputs unsets the globals set by src/lib.sh" {
  action_mode="push"
  error_message="an error"
  notice_message="a notice"
  reference="c0ffee"
  args_array=(--format pdf)
  reset_inputs
  [ -z "${action_mode+set}" ]
  [ -z "${error_message+set}" ]
  [ -z "${notice_message+set}" ]
  [ -z "${reference+set}" ]
  [ -z "${args_array+set}" ]
}

@test "reset_inputs covers every input declared in action.yml" {
  reset_inputs
  local input variable
  # Input names at the root of the 'inputs:' mapping, mapped to the env var
  # name GitHub Actions exposes them under
  while read -r input; do
    variable="INPUT_$(echo "${input}" | tr '[:lower:]-' '[:upper:]_')"
    export "${variable}=leaking-value"
  done < <(sed -n '/^inputs:/,/^outputs:/p' "${BATS_TEST_DIRNAME}/../../action.yml" |
    sed -n 's/^  \([a-z0-9_-]*\):$/\1/p')

  # More than a couple of inputs are expected, otherwise the parsing above broke
  [ "$(compgen -v INPUT_ | wc -l)" -gt 5 ]

  reset_inputs
  [ -z "$(compgen -v INPUT_ || true)" ]
}

@test "reset_inputs is safe to call twice in a row" {
  reset_inputs
  reset_inputs
}
