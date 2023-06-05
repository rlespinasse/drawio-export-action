#!/usr/bin/env bash

echo "::debug::Configuring args"
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

if [ "${INPUT_ENABLE_PLUGINS}" == "true" ]; then
  args_array+=("--enable-plugins")
fi

if [ "${INPUT_EMBED_SVG_IMAGES}" == "true" ]; then
  args_array+=("--embed-svg-images")
fi

# Need of full clone execpt for 'all' action mode
if [ "${INPUT_ACTION_MODE}" != "all" ]; then
  # To correctly configure git setup inside a container
  # See https://github.com/actions/checkout/issues/1169
  git config --system --add safe.directory '/github/workspace'
  # Need a classic clone of the repository to work with
  # but 'actions/checkout' make a shallow clone by default
  if [ "$(git rev-parse --is-shallow-repository)" == "true" ]; then
    error_message="This is a shallow git repository."
    if [ -f "$GITHUB_OUTPUT" ]; then
      echo "error_message=${error_message}" >>"$GITHUB_OUTPUT"
    else
      echo "::set-output name=error_message::${error_message}"
    fi
    echo "::error ::${error_message}"
    echo "Add 'fetch-depth: 0' to 'actions/checkout' step to use the '${INPUT_ACTION_MODE}' mode."
    exit 1
  fi
fi

# Try to calculate the correct action_mode to apply
echo "::debug::Calculating action mode to apply"

git_contains_output="$(git branch --contains "${INPUT_INTERNAL_PUSH_BEFORE}" 2>&1)"
action_mode="none"
error_message=""

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
  elif [ "${GITHUB_EVENT_NAME}" == "push" ] && [ -n "${INPUT_INTERNAL_PUSH_BEFORE}" ] && [ -n "${git_contains_output}" ]; then
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
        echo "::notice ::The first commit on this branch, can't work with it. Stopping the export."
        exit 0
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
echo "::debug::< calculated action-mode   : ${action_mode}"
echo "::debug::< error message            : ${error_message}"

# Try to calculate the correct reference to use
echo "::debug::Calculating reference to use"
if [ "${action_mode}" == "none" ]; then
  if [ -f "$GITHUB_OUTPUT" ]; then
    echo "error_message=${error_message}" >>"$GITHUB_OUTPUT"
  else
    echo "::set-output name=error_message::${error_message}"
  fi
  echo "::error ::${error_message}"
  echo "::error ::The choosen action mode '${INPUT_ACTION_MODE}' can't be used. Consider switching to 'auto' (default value)."
  exit 1
elif [ "$action_mode" == "reference" ]; then
  reference="${INPUT_SINCE_REFERENCE}"
elif [ "$action_mode" == "pull_request" ]; then
  # shellcheck disable=SC2046
  reference="$(git merge-base $(git rev-list --parents -n 1 HEAD | cut -d' ' -f2-))"
elif [ "$action_mode" == "push" ]; then
  reference="${INPUT_INTERNAL_PUSH_BEFORE}"
fi
echo "::debug::< calculated reference    : ${reference}"

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
