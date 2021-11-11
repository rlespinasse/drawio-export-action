FROM rlespinasse/drawio-export:4.2.0
RUN apt-get update && apt-get install --no-install-recommends -y git=1:2.20.1-2+deb10u3 && rm -rf /var/lib/apt/lists/*
COPY drawio-export.sh /opt/drawio-export-action/drawio-export.sh
ENV DRAWIO_DESKTOP_RUNNER_COMMAND_LINE "/opt/drawio-export-action/drawio-export.sh"
