#!/usr/bin/env bash
#
# Shared helpers for the unit tests of 'src/lib.sh'.

# Source the logic under test.
load_lib() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../src/lib.sh"
}

# Globals set by 'src/lib.sh' as the "output" of its functions.
LIB_OUTPUT_GLOBALS=(action_mode error_message notice_message reference args_array)

# Unset every input the logic under test relies on,
# so that each test only sets what it needs.
#
# Inputs are unset by prefix instead of by an enumerated list: 'src/lib.sh' is
# sourced into the bats process (not a subshell), so anything left over by a
# previous test - or inherited from a real GitHub Actions environment when this
# suite runs in CI - leaks into the next test. Unsetting 'INPUT_*' and
# 'GITHUB_*' wholesale keeps this helper correct when a new input is added to
# 'action.yml'/'src/lib.sh' without anyone remembering to update this file.
reset_inputs() {
  local name
  for name in $(compgen -v INPUT_ || true) $(compgen -v GITHUB_ || true); do
    unset "${name}"
  done
  unset "${LIB_OUTPUT_GLOBALS[@]}"
}

# Replace 'git branch --contains' by a canned output,
# to drive the action mode calculation without a real repository.
stub_git_branch_contains() {
  local output="$1"
  eval "git_branch_contains() { echo -n \"${output}\"; }"
}

# Replace the merge base calculation by a canned reference.
stub_git_merge_base_of_head() {
  local output="$1"
  eval "git_merge_base_of_head() { echo -n \"${output}\"; }"
}

# Create a git repository with two commits in the test temporary directory,
# and move into it.
setup_git_repository() {
  local repository="${BATS_TEST_TMPDIR}/repository"
  mkdir -p "${repository}"
  cd "${repository}" || return 1
  git init --quiet --initial-branch=main .
  git config user.email "unit-test@example.com"
  git config user.name "Unit Test"
  git commit --quiet --allow-empty -m "first commit"
  git commit --quiet --allow-empty -m "second commit"
  echo "${repository}"
}
