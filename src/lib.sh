#!/usr/bin/env bash
#
# Pure logic of the drawio-export-action entrypoint.
#
# This file is sourced by 'runner.sh' inside the Docker image,
# and by the bats unit tests (see 'tests/unit') outside of it.
# It only defines functions, so sourcing it has no side effect.
#
# Required call order, each step consuming the globals set by the previous one
# (enforced by the guards at the top of the two last functions):
#
#   resolve_action_mode  -> sets 'action_mode'
#   resolve_reference    -> reads 'action_mode', sets 'reference'
#   build_args_array     -> reads 'reference', sets 'args_array'

# Wrapper around 'git branch --contains' (stdout and stderr merged),
# isolated to be replaceable in the unit tests.
git_branch_contains() {
  git branch --contains "$1" 2>&1
}

# Reference of the commit the current HEAD is based on,
# isolated to be replaceable in the unit tests.
git_merge_base_of_head() {
  # shellcheck disable=SC2046
  git merge-base $(git rev-list --parents -n 1 HEAD | cut -d' ' -f2-)
}

# Is the current repository a shallow clone?
is_shallow_repository() {
  [ "$(git rev-parse --is-shallow-repository)" == "true" ]
}

# Report an error message as an action output and as an error annotation.
report_error() {
  local message="$1"
  if [ -f "$GITHUB_OUTPUT" ]; then
    echo "error_message=${message}" >>"$GITHUB_OUTPUT"
  else
    echo "::set-output name=error_message::${message}"
  fi
  echo "::error ::${message}"
}

# Calculate the action mode to apply from the inputs and the event context.
#
# Set the following global variables:
# - action_mode    : 'all', 'reference', 'pull_request', 'push',
#                    'skip' (nothing to export) or 'none' (error)
# - error_message  : reason of the 'none' action mode
# - notice_message : reason of the 'skip' action mode
#
# shellcheck disable=SC2034 # the globals are read by the callers
resolve_action_mode() {
  echo "::debug::Calculating action mode to apply"

  local git_contains_output
  git_contains_output="$(git_branch_contains "${INPUT_INTERNAL_PUSH_BEFORE}")"
  action_mode="none"
  error_message=""
  notice_message=""

  echo "::debug::> action-mode              : ${INPUT_ACTION_MODE}"
  echo "::debug::> since-reference          : ${INPUT_SINCE_REFERENCE}"
  echo "::debug::> head ref                 : ${GITHUB_HEAD_REF}"
  echo "::debug::> event name               : ${GITHUB_EVENT_NAME}"
  echo "::debug::> push before              : ${INPUT_INTERNAL_PUSH_BEFORE}"
  echo "::debug::> push forced              : ${INPUT_INTERNAL_PUSH_FORCED}"
  echo "::debug::> git contains push before : ${git_contains_output}"

  if [ "${INPUT_ACTION_MODE}" == "all" ]; then
    action_mode="all"
  elif [ "${INPUT_ACTION_MODE}" == "auto" ]; then
    if [ -n "${INPUT_SINCE_REFERENCE}" ]; then
      action_mode="reference"
    elif [ -n "${GITHUB_HEAD_REF}" ]; then
      action_mode="pull_request"
    elif [ "${GITHUB_EVENT_NAME}" == "push" ] && [ -n "${git_contains_output}" ] && [ "${INPUT_INTERNAL_PUSH_BEFORE}" != "0000000000000000000000000000000000000000" ] && [ "${INPUT_INTERNAL_PUSH_FORCED}" == "false" ]; then
      action_mode="push"
    else
      action_mode="all"
    fi
  elif [ "${INPUT_ACTION_MODE}" == "reference" ]; then
    if [ -n "${INPUT_SINCE_REFERENCE}" ]; then
      action_mode="reference"
    else
      error_message="The 'since-reference' option is mandatory."
    fi
  elif [ "${INPUT_ACTION_MODE}" == "recent" ]; then
    if [ -n "${GITHUB_HEAD_REF}" ]; then
      action_mode="pull_request"
    elif [ "${GITHUB_EVENT_NAME}" == "push" ]; then
      if [ -n "${INPUT_INTERNAL_PUSH_BEFORE}" ]; then
        if [ -n "${git_contains_output}" ]; then
          action_mode="push"
        elif [ "${INPUT_INTERNAL_PUSH_BEFORE}" == "0000000000000000000000000000000000000000" ]; then
          action_mode="skip"
          notice_message="The first commit on this branch, can't work with it. Stopping the export."
        elif [ "${INPUT_INTERNAL_PUSH_FORCED}" == "true" ]; then
          action_mode="skip"
          notice_message="The commit have been force push, can't work with it. Stopping the export."
        else
          error_message="The latest pushed commit ${INPUT_INTERNAL_PUSH_BEFORE} need to be an existing git reference."
        fi
      else
        error_message="Can't get the previous reference to rely on."
      fi
    else
      error_message="Can't find any reference to rely on for the event '${GITHUB_EVENT_NAME}'."
    fi
  else
    error_message="Unknown action-mode."
  fi

  echo "::debug::< calculated action-mode   : ${action_mode}"
  echo "::debug::< error message            : ${error_message}"
}

# Calculate the git reference to export from, based on the action mode.
#
# Set the global variable 'reference' (empty when the whole repository
# has to be exported).
#
# Requires 'resolve_action_mode' to have been called first.
resolve_reference() {
  if [ -z "${action_mode+set}" ]; then
    echo "::error ::resolve_reference called before resolve_action_mode."
    return 1
  fi

  echo "::debug::Calculating reference to use"

  reference=""
  if [ "${action_mode}" == "reference" ]; then
    reference="${INPUT_SINCE_REFERENCE}"
  elif [ "${action_mode}" == "pull_request" ]; then
    reference="$(git_merge_base_of_head)"
  elif [ "${action_mode}" == "push" ]; then
    reference="${INPUT_INTERNAL_PUSH_BEFORE}"
  fi

  echo "::debug::< calculated reference    : ${reference}"
}

# Build the drawio-exporter command line arguments from the inputs
# and the global variable 'reference'.
#
# Set the global variable 'args_array'.
#
# Requires 'resolve_reference' to have been called first.
build_args_array() {
  if [ -z "${reference+set}" ]; then
    echo "::error ::build_args_array called before resolve_reference."
    return 1
  fi

  echo "::debug::Configuring args"

  args_array=(
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

  if [ "${INPUT_ENABLE_PLUGINS}" == "true" ]; then
    args_array+=("--enable-plugins")
  fi

  if [ "${INPUT_EMBED_SVG_IMAGES}" == "true" ]; then
    args_array+=("--embed-svg-images")
  fi

  if [ "${INPUT_ALL_PAGES}" == "true" ]; then
    args_array+=("--all-pages")
  fi

  if [ -n "${INPUT_EMBED_SVG_FONTS}" ]; then
    args_array+=("--embed-svg-fonts" "${INPUT_EMBED_SVG_FONTS}")
  fi

  if [ -n "${INPUT_SVG_THEME}" ]; then
    args_array+=("--svg-theme" "${INPUT_SVG_THEME}")
  fi

  if [ -n "${INPUT_SVG_LINKS_TARGET}" ]; then
    args_array+=("--svg-links-target" "${INPUT_SVG_LINKS_TARGET}")
  fi

  # If a reference is set, we can active the on-changes option for git repository
  if [ -n "${reference}" ]; then
    args_array+=(
      "--on-changes"
      "--git-ref" "${reference}"
    )
  fi

  args_array+=("${INPUT_PATH}")
}
