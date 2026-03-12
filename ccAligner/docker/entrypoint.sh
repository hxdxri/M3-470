#!/usr/bin/env bash
set -euo pipefail
cd /workspace

if [ ! -d /workspace/tools/ccaligner_artifact/.git ]; then
    echo "CCAligner artifact not found in workspace/tools; fetching..."
    bash /workspace/scripts/01_fetch_artifact.sh
fi

exec "$@"
