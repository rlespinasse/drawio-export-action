#checkov:skip=CKV_DOCKER_2
#checkov:skip=CKV_DOCKER_3
FROM rlespinasse/drawio-export:v4.45.0
RUN apt-get update && apt-get install --no-install-recommends -y git=1:2.47.3-0+deb13u1 && rm -rf /var/lib/apt/lists/*
COPY src/* /opt/drawio-export-action/
ENV DRAWIO_DESKTOP_RUNNER_COMMAND_LINE "/opt/drawio-export-action/runner.sh"
