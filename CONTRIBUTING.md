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

The entrypoint logic lives in `src/lib.sh` (pure bash functions) and is wired up by `src/runner.sh` inside the Docker image.

* Install the test dependencies once with `make setup-test` ([bats][6]).

* Run the unit tests of `src/lib.sh` with `make unit-test`.
They run outside of the Docker image, so they are fast and need no build.
Add your test cases to `tests/unit`.

* Run the integration tests with `make test`.
They build the Docker image first and run against it.

## Do you have questions about the source code

* [open an issue][3] with your question.

Thanks!

[1]: https://github.com/rlespinasse/drawio-export-action/security/policy
[2]: https://github.com/rlespinasse/drawio-export-action/issues
[3]: https://github.com/rlespinasse/drawio-export-action/issues/new
[4]: https://github.com/rlespinasse/drawio-export-action/issues/new?assignees=&labels=bug&template=bug_report.md&title=
[5]: https://github.com/rlespinasse/drawio-export-action/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=
[6]: https://github.com/bats-core/bats-core
