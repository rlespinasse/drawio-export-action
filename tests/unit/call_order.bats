#!/usr/bin/env bats
#
# The functions of 'src/lib.sh' communicate through globals and must be called
# in order: resolve_action_mode -> resolve_reference -> build_args_array.

setup() {
  load 'test_helper'
  load_lib
  reset_inputs
  stub_git_merge_base_of_head "merge-base-sha"
}

@test "resolve_reference fails when resolve_action_mode has not been called" {
  run resolve_reference
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"resolve_reference called before resolve_action_mode."* ]]
}

@test "resolve_reference succeeds once action_mode is set, even to an empty value" {
  action_mode=""
  run resolve_reference
  [ "${status}" -eq 0 ]
}

@test "build_args_array fails when resolve_reference has not been called" {
  action_mode="all"
  run build_args_array
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"build_args_array called before resolve_reference."* ]]
}

@test "the full call order builds the args without any guard error" {
  INPUT_ACTION_MODE="all"
  INPUT_PATH="."
  INPUT_FORMAT="pdf"
  INPUT_OUTPUT="export"
  INPUT_BORDER="0"
  INPUT_QUALITY="90"
  stub_git_branch_contains ""

  resolve_action_mode
  resolve_reference
  build_args_array

  [ "${action_mode}" == "all" ]
  [ -z "${reference}" ]
  [ "${args_array[*]}" == "--format pdf --output export --border 0 --quality 90 ." ]
}
