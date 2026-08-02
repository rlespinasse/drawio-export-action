#!/usr/bin/env bats

setup() {
  load 'test_helper'
  load_lib
  reset_inputs
  stub_git_merge_base_of_head "merge-base-sha"
}

@test "reference action mode uses the since-reference input" {
  action_mode="reference"
  INPUT_SINCE_REFERENCE="HEAD~2"
  resolve_reference
  [ "${reference}" == "HEAD~2" ]
}

@test "pull_request action mode uses the merge base of HEAD" {
  action_mode="pull_request"
  resolve_reference
  [ "${reference}" == "merge-base-sha" ]
}

@test "push action mode uses the previously pushed commit" {
  action_mode="push"
  INPUT_INTERNAL_PUSH_BEFORE="c0ffee"
  resolve_reference
  [ "${reference}" == "c0ffee" ]
}

@test "all action mode uses no reference" {
  action_mode="all"
  INPUT_SINCE_REFERENCE="HEAD~2"
  INPUT_INTERNAL_PUSH_BEFORE="c0ffee"
  resolve_reference
  [ -z "${reference}" ]
}
