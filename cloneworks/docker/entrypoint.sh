#!/usr/bin/env bash
set -euo pipefail
cd /workspace

# If the artifact wasn't provided via volume mount, clone it at runtime
if [ ! -d /workspace/tools/cloneworks_artifact/src ]; then
    echo "CloneWorks artifact not found in workspace, cloning..."
    mkdir -p /workspace/tools
    git clone https://github.com/jeffsvajlenko/CloneWorks.git /workspace/tools/cloneworks_artifact
fi

exec "$@"