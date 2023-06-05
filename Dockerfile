FROM rlespinasse/drawio-export:v4.6.0
RUN apt-get update && apt-get install --no-install-recommends -y git=1:2.30.2-1+deb11u2 && rm -rf /var/lib/apt/lists/*
COPY drawio-export.sh /opt/drawio-export-action/drawio-export.sh
ENV DRAWIO_DESKTOP_RUNNER_COMMAND_LINE "/opt/drawio-export-action/drawio-export.sh"
