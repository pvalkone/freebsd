#!/bin/sh

portshaker && \
PORTS_TO_BUILD="${ADDITIONAL_PORTS} $(find ${CUSTOM_PORTS_DIR} -type d -not -path "*/\.*" -mindepth 2 -maxdepth 2 | sed "s|\\${CUSTOM_PORTS_DIR}/||")"; \
echo "Building $(echo -n ${PORTS_TO_BUILD} | tr -d '\n') using Synth"
synth just-build ${PORTS_TO_BUILD} && \
synth rebuild-repository
