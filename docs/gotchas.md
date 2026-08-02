# Gotchas

## `make unit-test` (bats) is not wired into any CI workflow

- Date: 2026-08-02
- By: developer (with the user)
- Status: **Resolved** (2026-08-02)

`tests/unit/*.bats` (added for issue #36) only ran when someone ran
`make unit-test` locally. Neither `.github/workflows/drawio-export-action.yml`
(integration tests + release) nor `.github/workflows/linter.yml`
(`super-linter`) invoked `npx bats -r tests/unit`, so CI stayed green even if
`src/lib.sh` regressed in a way only the unit suite would catch.

Resolved by the `unit-testing` job in
`.github/workflows/drawio-export-action.yml`: it runs `make setup-test` then
`make unit-test` on `ubuntu-latest`, needs no Docker build, and is listed in
the `release` job's `needs` so a unit-test failure blocks the release just like
the `os-testing-*` jobs do.

## `src/lib.sh` globals must be reset between bats tests, or state leaks across cases

- Date: 2026-08-02
- By: developer (with the user)
- Status: **Resolved** (2026-08-02)

`resolve_action_mode`, `resolve_reference` and `build_args_array` in
`src/lib.sh` don't take arguments or return values the normal way — they read
`INPUT_*`/`GITHUB_*` env vars and set global variables (`action_mode`,
`error_message`, `notice_message`, `reference`, `args_array`) as their
"output". Because the unit tests `source` `lib.sh` directly into the bats test
process (via `tests/unit/test_helper.bash`'s `load_lib`, not in a subshell),
anything left over from one test bleeds into the next unless explicitly unset.

`reset_inputs()` used to enumerate every variable by hand, and that list had to
be kept in sync with `action.yml`/`lib.sh` — a new input without a matching
entry would silently leak, producing order-dependent failures that are hard to
trace back to a missing `unset`.

Resolved by making `reset_inputs()` unset by prefix (`compgen -v INPUT_` and
`compgen -v GITHUB_`) instead of by an enumerated list, so a new input is
covered automatically. This also makes the suite hermetic now that it runs
inside a real GitHub Actions job, where `GITHUB_EVENT_NAME` and friends are set
for real. `tests/unit/test_helper.bats` guards the behaviour, including a case
that sets every input declared in `action.yml` and asserts none survives a
reset.

The related implicit call-order dependency (`resolve_action_mode` →
`resolve_reference` → `build_args_array`, each consuming globals set by the
previous one) is now documented in the `src/lib.sh` header and enforced by a
guard at the top of the last two functions, which fail with an
`::error ::... called before ...` annotation instead of silently computing
wrong arguments. `src/runner.sh` propagates that failure with `|| exit 1`, and
`tests/unit/call_order.bats` covers it.
