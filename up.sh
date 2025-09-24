#!/usr/bin/env bash
set -euo pipefail

# Exporta TODO lo que hay en ./env al entorno del host
# (para que docker compose pueda interpolar ${HTTP_PORT}, etc.)
set -a
source ./env
set +a

# corre compose normalmente
docker compose up -d --build