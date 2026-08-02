#!/usr/bin/env bats

setup() {
  load 'test_helper'
  load_lib
  reset_inputs
}

@test "a full clone is not detected as shallow" {
  setup_git_repository >/dev/null
  run is_shallow_repository
  [ "${status}" -eq 1 ]
}

@test "a shallow clone is detected as shallow" {
  local repository
  repository="$(setup_git_repository)"
  git clone --quiet --depth 1 "file://${repository}" "${BATS_TEST_TMPDIR}/shallow"
  cd "${BATS_TEST_TMPDIR}/shallow" || return 1
  run is_shallow_repository
  [ "${status}" -eq 0 ]
}

@test "git_branch_contains lists the branches of a known commit" {
  setup_git_repository >/dev/null
  run git_branch_contains "$(git rev-parse HEAD~1)"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"main"* ]]
}

@test "git_branch_contains reports the error of an unknown commit" {
  setup_git_repository >/dev/null
  run git_branch_contains "0000000000000000000000000000000000000000"
  [ -n "${output}" ]
}

@test "git_merge_base_of_head needs a merge commit to work" {
  # 'git merge-base' needs at least two commits, so a HEAD with a single
  # parent makes it fail. It only happens outside of a pull request, where
  # 'actions/checkout' always checks out a merge commit.
  setup_git_repository >/dev/null
  run git_merge_base_of_head
  [ "${status}" -ne 0 ]
}

@test "git_merge_base_of_head is the common ancestor on a merge commit" {
  setup_git_repository >/dev/null
  local base
  base="$(git rev-parse HEAD)"
  git checkout --quiet -b a-branch
  git commit --quiet --allow-empty -m "branch commit"
  git checkout --quiet main
  git commit --quiet --allow-empty -m "main commit"
  git merge --quiet --no-ff -m "merge commit" a-branch
  run git_merge_base_of_head
  [ "${status}" -eq 0 ]
  [ "${output}" == "${base}" ]
}

@test "report_error writes the message to the action output file" {
  export GITHUB_OUTPUT="${BATS_TEST_TMPDIR}/github_output"
  : >"${GITHUB_OUTPUT}"
  run report_error "This is a shallow git repository."
  [ "${status}" -eq 0 ]
  [ "${output}" == "::error ::This is a shallow git repository." ]
  [ "$(cat "${GITHUB_OUTPUT}")" == "error_message=This is a shallow git repository." ]
}

@test "report_error falls back on set-output without an action output file" {
  export GITHUB_OUTPUT="${BATS_TEST_TMPDIR}/missing_file"
  run report_error "Unknown action-mode."
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == "::set-output name=error_message::Unknown action-mode." ]
  [ "${lines[1]}" == "::error ::Unknown action-mode." ]
}
