# How to contribute to Drawio Export Action

## Did you find a bug

* **Do not open up a GitHub issue if the bug is a security vulnerability**, and instead to refer to our [security policy][1].

* **Ensure the bug was not already reported** by searching on GitHub under [Issues][2].

* If you're unable to find an open issue addressing the problem, [open a 'Bug' issue][4].
Be sure to include a **title and clear description**, as much relevant information as possible, and a **code sample** or an **executable test case** demonstrating the expected behavior that is not occurring.

## Did you write a patch that fixes a bug

* Open a new GitHub pull request with the patch.

* Ensure the PR description clearly describes the problem and solution.
Include the relevant issue number if applicable.

## Do you intend to add a new feature or change an existing one

* Suggest your change by [opening a 'Feature request' issue][5]

## How to test your changes

The entrypoint logic lives in `src/lib.sh` (pure Bash functions) and is wired up by `src/runner.sh` inside the Docker image.

* Install the test dependencies once with `make setup-test` ([bats][6]).

* Run the unit tests of `src/lib.sh` with `make unit-test`.
They run outside of the Docker image, so they are fast and need no build.
Add your test cases to `tests/unit`.
The `unit-testing` job of the `drawio-export-action` workflow runs them on every
pull request, and the release is gated on them.

* `make test` builds the Docker image (`make build`) and then runs `bats -r tests`,
which currently resolves to the same suite as `make unit-test` since no test
files exist yet outside of `tests/unit`. The target also exports a `DOCKER_IMAGE`
environment variable and prepares `tests/output` and the `tests/data` fixtures
(e.g. `tests/data/nominal.drawio`), in place for integration tests that exercise
the built image directly — add such tests under `tests/` (outside `tests/unit`)
once they're written.

* `make cleanup` removes generated export folders (`export`, `test-*`) and `tests/output`;
`make test` runs it automatically before building.

## Do you have questions about the source code

* [open an issue][3] with your question.

Thanks!

[1]: https://github.com/rlespinasse/drawio-export-action/security/policy
[2]: https://github.com/rlespinasse/drawio-export-action/issues
[3]: https://github.com/rlespinasse/drawio-export-action/issues/new
[4]: https://github.com/rlespinasse/drawio-export-action/issues/new?assignees=&labels=bug&template=bug_report.md&title=
[5]: https://github.com/rlespinasse/drawio-export-action/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=
[6]: https://github.com/bats-core/bats-core
