#!/usr/bin/env bats

setup() {
  load 'test_helper'
  load_lib
  reset_inputs
  # By default, the pushed commit is unknown to any branch
  stub_git_branch_contains ""
}

@test "action-mode 'all' is used as is" {
  INPUT_ACTION_MODE="all"
  resolve_action_mode
  [ "${action_mode}" == "all" ]
  [ -z "${error_message}" ]
}

@test "unknown action-mode is an error" {
  INPUT_ACTION_MODE="whatever"
  resolve_action_mode
  [ "${action_mode}" == "none" ]
  [ "${error_message}" == "Unknown action-mode." ]
}

#
# auto
#

@test "auto with a since-reference resolves to reference" {
  INPUT_ACTION_MODE="auto"
  INPUT_SINCE_REFERENCE="HEAD~2"
  resolve_action_mode
  [ "${action_mode}" == "reference" ]
}

@test "auto on a pull request resolves to pull_request" {
  INPUT_ACTION_MODE="auto"
  GITHUB_HEAD_REF="a-branch"
  GITHUB_EVENT_NAME="pull_request"
  resolve_action_mode
  [ "${action_mode}" == "pull_request" ]
}

@test "auto with a since-reference takes precedence over a pull request" {
  INPUT_ACTION_MODE="auto"
  INPUT_SINCE_REFERENCE="HEAD~2"
  GITHUB_HEAD_REF="a-branch"
  GITHUB_EVENT_NAME="pull_request"
  resolve_action_mode
  [ "${action_mode}" == "reference" ]
}

@test "auto on a push of a known commit resolves to push" {
  INPUT_ACTION_MODE="auto"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE="c0ffee"
  INPUT_INTERNAL_PUSH_FORCED="false"
  stub_git_branch_contains "* main"
  resolve_action_mode
  [ "${action_mode}" == "push" ]
}

@test "auto on a first commit push falls back to all" {
  INPUT_ACTION_MODE="auto"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE="0000000000000000000000000000000000000000"
  INPUT_INTERNAL_PUSH_FORCED="false"
  stub_git_branch_contains "error: no such commit"
  resolve_action_mode
  [ "${action_mode}" == "all" ]
}

@test "auto on a force push falls back to all" {
  INPUT_ACTION_MODE="auto"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE="c0ffee"
  INPUT_INTERNAL_PUSH_FORCED="true"
  stub_git_branch_contains "* main"
  resolve_action_mode
  [ "${action_mode}" == "all" ]
}

@test "auto on an unknown pushed commit falls back to all" {
  INPUT_ACTION_MODE="auto"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE="c0ffee"
  INPUT_INTERNAL_PUSH_FORCED="false"
  resolve_action_mode
  [ "${action_mode}" == "all" ]
}

@test "auto on another event falls back to all" {
  INPUT_ACTION_MODE="auto"
  GITHUB_EVENT_NAME="schedule"
  resolve_action_mode
  [ "${action_mode}" == "all" ]
}

#
# reference
#

@test "reference with a since-reference resolves to reference" {
  INPUT_ACTION_MODE="reference"
  INPUT_SINCE_REFERENCE="HEAD~2"
  resolve_action_mode
  [ "${action_mode}" == "reference" ]
}

@test "reference without a since-reference is an error" {
  INPUT_ACTION_MODE="reference"
  resolve_action_mode
  [ "${action_mode}" == "none" ]
  [ "${error_message}" == "The 'since-reference' option is mandatory." ]
}

#
# recent
#

@test "recent on a pull request resolves to pull_request" {
  INPUT_ACTION_MODE="recent"
  GITHUB_HEAD_REF="a-branch"
  GITHUB_EVENT_NAME="pull_request"
  resolve_action_mode
  [ "${action_mode}" == "pull_request" ]
}

@test "recent on a push of a known commit resolves to push" {
  INPUT_ACTION_MODE="recent"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE="c0ffee"
  INPUT_INTERNAL_PUSH_FORCED="false"
  stub_git_branch_contains "* main"
  resolve_action_mode
  [ "${action_mode}" == "push" ]
}

@test "recent on a first commit push skips the export" {
  INPUT_ACTION_MODE="recent"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE="0000000000000000000000000000000000000000"
  INPUT_INTERNAL_PUSH_FORCED="false"
  resolve_action_mode
  [ "${action_mode}" == "skip" ]
  [ "${notice_message}" == "The first commit on this branch, can't work with it. Stopping the export." ]
}

@test "recent on a force push skips the export" {
  INPUT_ACTION_MODE="recent"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE="c0ffee"
  INPUT_INTERNAL_PUSH_FORCED="true"
  resolve_action_mode
  [ "${action_mode}" == "skip" ]
  [ "${notice_message}" == "The commit have been force push, can't work with it. Stopping the export." ]
}

@test "recent on a push of a missing commit is an error" {
  INPUT_ACTION_MODE="recent"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE="c0ffee"
  INPUT_INTERNAL_PUSH_FORCED="false"
  resolve_action_mode
  [ "${action_mode}" == "none" ]
  [ "${error_message}" == "The latest pushed commit c0ffee need to be an existing git reference." ]
}

@test "recent on a push without a previous reference is an error" {
  INPUT_ACTION_MODE="recent"
  GITHUB_EVENT_NAME="push"
  INPUT_INTERNAL_PUSH_BEFORE=""
  resolve_action_mode
  [ "${action_mode}" == "none" ]
  [ "${error_message}" == "Can't get the previous reference to rely on." ]
}

@test "recent on another event is an error" {
  INPUT_ACTION_MODE="recent"
  GITHUB_EVENT_NAME="schedule"
  resolve_action_mode
  [ "${action_mode}" == "none" ]
  [ "${error_message}" == "Can't find any reference to rely on for the event 'schedule'." ]
}
