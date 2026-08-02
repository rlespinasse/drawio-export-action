#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/lib.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib.sh"

# Need of full clone except for 'all' action mode
if [ "${INPUT_ACTION_MODE}" != "all" ]; then
  # To correctly configure git setup inside a container
  # See https://github.com/actions/checkout/issues/1169
  git config --system --add safe.directory '/github/workspace'
  # Need a classic clone of the repository to work with
  # but 'actions/checkout' make a shallow clone by default
  if is_shallow_repository; then
    report_error "This is a shallow git repository."
    echo "Add 'fetch-depth: 0' to 'actions/checkout' step to use the '${INPUT_ACTION_MODE}' mode."
    exit 1
  fi
fi

# Try to calculate the correct action_mode to apply
resolve_action_mode

if [ "${action_mode}" == "skip" ]; then
  echo "::notice ::${notice_message}"
  exit 0
fi

if [ "${action_mode}" == "none" ]; then
  report_error "${error_message}"
  echo "::error ::The chosen action mode '${INPUT_ACTION_MODE}' can't be used. Consider switching to 'auto' (default value)."
  exit 1
fi

# Try to calculate the correct reference to use
resolve_reference || exit 1

build_args_array || exit 1

echo Options: "${args_array[@]}"

/opt/drawio-exporter/runner.sh "${args_array[@]}"
