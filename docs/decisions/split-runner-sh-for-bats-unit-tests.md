# Split `runner.sh` into a pure `lib.sh` and add a `bats` unit-test suite

- Status: Accepted
- Date: 2026-08-02

## Context

`src/runner.sh` used to hold all of the entrypoint's logic in one file: Git
setup side effects (`git config --system --add safe.directory`), control
flow (`exit 1` on error, `exit 0` on skip), the action-mode/reference
resolution logic, the `drawio-exporter` argument building, and finally the
call to the packaged `/opt/drawio-exporter/runner.sh` binary.

Because that logic was entangled with side effects and process exits, the
only way to exercise it was to actually run the Docker action end-to-end
(`make test`, which builds the image and runs `tests/*.bats` against it, and
the `os-testing-*` jobs in `.github/workflows/drawio-export-action.yml`).
That made even small logic changes (e.g. a one-line fix to the action-mode
decision table) slow to verify and hard to cover exhaustively — every edge
case (auto/reference/recent/push/pull_request/skip/none, shallow-clone
detection, arg building for every input combination) required a full Docker
build and, in practice, a GitHub Actions run to be sure.

## Decision

- Extract all pure logic into a new `src/lib.sh`: `resolve_action_mode`,
  `resolve_reference`, `build_args_array`, `is_shallow_repository`,
  `report_error`, plus small wrappers around external Git calls
  (`git_branch_contains`, `git_merge_base_of_head`) so they can be stubbed
  in tests. `src/lib.sh` only defines functions — sourcing it has no side
  effect, no `exit`, no Git config mutation, no process invocation.
- `src/runner.sh` now only does orchestration: it sources `lib.sh`, performs
  the actual side-effecting steps (Git safe.directory config, shallow-clone
  check with `exit 1`, skip/none handling with `exit 0`/`exit 1`), and
  finally invokes `/opt/drawio-exporter/runner.sh` with the built args.
- Added a `bats` unit-test suite under `tests/unit/` (`action_mode.bats`,
  `reference.bats`, `args_array.bats`, `git_helpers.bats`,
  `test_helper.bash`) that sources `src/lib.sh` directly and exercises every
  branch of the logic without Docker, without a real GitHub Actions context,
  and largely without a real Git repository (using stubs for
  `git_branch_contains`/`git_merge_base_of_head`, and a throwaway repository
  via `setup_git_repository` only where the Git plumbing itself is under test).
- Wired via `make unit-test` (`npx bats -r tests/unit`), documented in
  `CONTRIBUTING.md` as the fast, no-build path, distinct from `make test`
  (build the Docker image, run `tests/*.bats` — the pre-existing integration
  suite that exercises the packaged composite action end-to-end).

## Why `bats`

The project already used `bats-core` for its Docker-based integration tests
(`tests/*.bats`, run via `make test`). Reusing the same framework for the
new unit tests means:

- One test runner, one syntax, one dependency (`npm install bats`) for both
  layers — no second framework (e.g. `shunit2`, `shellspec`) to learn or
  maintain.
- Unit tests and integration tests live side by side conceptually
  (`tests/unit/` vs `tests/*.bats`), and can share conventions (`setup()`,
  `run`, `[ "${status}" -eq 0 ]`, etc.).

Alternatives considered: `shunit2` and `shellspec` were not evaluated in
depth — bats being already in use made it the default choice, and nothing
in the new tests' requirements (stubbing functions, per-test temp dirs via
`BATS_TEST_TMPDIR`) needed a different framework.

## Relation to the existing integration tests

- **Unit tests** (`tests/unit/*.bats`, `make unit-test`): fast, no Docker
  build, cover every branch/edge case of the pure logic in `lib.sh`
  (action-mode decision table, reference resolution, argument building for
  every input, `is_shallow_repository`, `report_error`). Run outside of any
  container, directly on the host's Bash.
- **Integration tests** (`tests/*.bats`, `make test`, and the
  `os-testing-with-shallow-clone` / `os-testing-with-full-clone` jobs in
  `.github/workflows/drawio-export-action.yml`): slower, build the Docker
  image and run the actual composite action, checking real exported files.
  These remain the safety net for packaging/wiring issues (Docker build,
  `action.yml` inputs mapping, the real `drawio-exporter` binary) that the
  unit tests cannot catch since they never touch Docker or the real
  exporter.

The two suites are complementary, not redundant: unit tests give fast,
exhaustive coverage of decision logic; integration tests give confidence
that the packaged action still works end-to-end.
