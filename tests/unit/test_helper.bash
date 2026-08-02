#!/usr/bin/env bash
#
# Shared helpers for the unit tests of 'src/lib.sh'.

# Source the logic under test.
load_lib() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../src/lib.sh"
}

# Unset every input the logic under test relies on,
# so that each test only sets what it needs.
reset_inputs() {
  unset INPUT_PATH INPUT_FORMAT INPUT_OUTPUT INPUT_BORDER INPUT_QUALITY \
    INPUT_EMBED_DIAGRAM INPUT_REMOVE_PAGE_SUFFIX INPUT_TRANSPARENT \
    INPUT_UNCOMPRESSED INPUT_CROP INPUT_SCALE INPUT_HEIGHT INPUT_WIDTH \
    INPUT_ENABLE_PLUGINS INPUT_EMBED_SVG_IMAGES INPUT_ALL_PAGES \
    INPUT_EMBED_SVG_FONTS INPUT_SVG_THEME INPUT_SVG_LINKS_TARGET \
    INPUT_ACTION_MODE INPUT_SINCE_REFERENCE \
    INPUT_INTERNAL_PUSH_BEFORE INPUT_INTERNAL_PUSH_FORCED \
    GITHUB_HEAD_REF GITHUB_EVENT_NAME GITHUB_OUTPUT \
    action_mode error_message notice_message reference args_array
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
