FROM rlespinasse/drawio-export:4.2.0
COPY drawio-export.sh /opt/drawio-export-action/drawio-export.sh
ENV DRAWIO_DESKTOP_RUNNER_COMMAND_LINE "/opt/drawio-export-action/drawio-export.sh"
