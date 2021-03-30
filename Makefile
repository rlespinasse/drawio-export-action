.PHONY: build run setup-test test cleanup

DOCKER_IMAGE?=rlespinasse/drawio-export-action:local
build:
	@docker build -t ${DOCKER_IMAGE} .

RUN_ARGS?=
run:
	@docker run -it -v $(PWD):/data ${DOCKER_IMAGE} ${RUN_ARGS}

setup-test:
	@npm install bats

test: cleanup build
	@mkdir -p tests/output
	@export DOCKER_IMAGE=$(DOCKER_IMAGE); npx bats -r tests

cleanup:
	@find tests -name "export" | xargs -I {} rm -r "{}"
	@find tests -name "test-*" | xargs -I {} rm -r "{}"
	@rm -rf tests/output
