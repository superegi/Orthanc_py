#!/usr/bin/env bash
set -euo pipefail

# Render base
envsubst < /orthanc.tpl.json > /etc/orthanc/orthanc.base.json

# Merge opcional con conexiones locales
if [ -f /config/connections.local.json ]; then
  envsubst < /config/connections.local.json > /etc/orthanc/connections.rendered.json
  jq -s '.[0] * .[1]' \
    /etc/orthanc/orthanc.base.json \
    /etc/orthanc/connections.rendered.json \
    > /etc/orthanc/orthanc.json
else
  cp /etc/orthanc/orthanc.base.json /etc/orthanc/orthanc.json
fi

exec Orthanc /etc/orthanc/orthanc.json
