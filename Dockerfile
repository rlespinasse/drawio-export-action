FROM rlespinasse/drawio-export:4.1.0
COPY scripts/runner.sh /opt/drawio-export-action/runner.sh
ENV DRAWIO_DESKTOP_RUNNER_COMMAND_LINE "/opt/drawio-export-action/runner.sh"
