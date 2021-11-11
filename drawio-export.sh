#!/usr/bin/env bash

args_array+=(
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

# Try to calculate the correct action_mode to apply
action_mode="none"
error_message=""
if [ "${INPUT_ACTION_MODE}" == "all" ]; then
  action_mode="all"
elif [ "${INPUT_ACTION_MODE}" == "auto" ]; then
  if [ -n "${INPUT_SINCE_REFERENCE}" ]; then
    action_mode="reference"
  elif [ -n "${GITHUB_HEAD_REF}" ]; then
    action_mode="pull_request"
  elif [ "${GITHUB_EVENT_NAME}" == "push" ] && [ -n "${INPUT_INTERNAL_PUSH_BEFORE}" ] && [ -z "$(git branch --contains "${INPUT_INTERNAL_PUSH_BEFORE}" 2>&1)" ]; then
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
      if [ -z "$(git branch --contains "${INPUT_INTERNAL_PUSH_BEFORE}" 2>&1)" ]; then
        action_mode="push"
      elif [ "${INPUT_INTERNAL_PUSH_FORCED}" == "true" ]; then
        echo "::notice ::The commit have been force push, can't work with it. Stopping the export."
        exit 0
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

# Try to calculate the correct reference to used
if [ "${action_mode}" == "none" ]; then
  echo "::set-output name=error_message::${error_message}"
  printf "::error ::%s\n\n%s" \
    "${error_message}" \
    "The choosen action mode '${INPUT_ACTION_MODE}' can't be used. Consider switching to 'auto' (default value)."
  exit 1
elif [ "${action_mode}" != "all" ]; then
  # Need a classic clone of the repository to work with
  # but 'actions/checkout' make a shallow clone by default
  if [ "$(git rev-parse --is-shallow-repository)" == "true" ]; then
    error_message="This is a shallow git repository."
    echo "::set-output name=error_message::${error_message}"
    printf "::error ::%s\n\nAdd 'fetch-depth: 0' to 'actions/checkout' step to use the '%s' mode." \
      "${error_message}" \
      "${INPUT_ACTION_MODE}"
    exit 1
  fi

  if [ "$action_mode" == "reference" ]; then
    reference="${INPUT_SINCE_REFERENCE}"
  elif [ "$action_mode" == "pull_request" ]; then
    # shellcheck disable=SC2046
    reference="$(git merge-base $(git rev-list --parents -n 1 HEAD | cut -d' ' -f2-))"
  elif [ "$action_mode" == "push" ]; then
    reference="${INPUT_INTERNAL_PUSH_BEFORE}"
  fi
fi

# If a reference is set, we can active the on-changes option for git repository
if [ -n "${reference}" ]; then
  args_array+=(
    "--on-changes"
    "--git-ref" "${reference}"
  )
fi

args_array+=("${INPUT_PATH}")

echo Options: "${args_array[@]}"

/opt/drawio-exporter/runner-no-security-warnings.sh "${args_array[@]}"
