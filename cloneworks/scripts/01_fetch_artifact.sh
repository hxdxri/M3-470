#!/usr/bin/env bash
# 01_fetch_artifact.sh — Clone or update the official CloneWorks artifact
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ARTIFACT_DIR="${ROOT_DIR}/tools/cloneworks_artifact"
LOG_DIR="${ROOT_DIR}/evidence/logs"

mkdir -p "$LOG_DIR"

REPO_URL="https://github.com/jeffsvajlenko/CloneWorks.git"
# Alternate: https://github.com/chutgiet/CloneWorks.git

echo "=== CloneWorks Artifact Fetch ==="
echo "Repo URL : $REPO_URL"
echo "Target   : $ARTIFACT_DIR"
echo ""

if [ -d "$ARTIFACT_DIR/.git" ]; then
    echo "Artifact already cloned. Pulling latest..."
    cd "$ARTIFACT_DIR"
    git pull --ff-only 2>&1 || echo "Pull failed (possibly offline), using existing clone."
else
    echo "Cloning CloneWorks artifact..."
    rm -rf "$ARTIFACT_DIR"
    mkdir -p "$(dirname "$ARTIFACT_DIR")"
    git clone "$REPO_URL" "$ARTIFACT_DIR" 2>&1
fi

cd "$ARTIFACT_DIR"

# Record commit hash
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
echo ""
echo "Commit hash: $COMMIT_HASH"

# Write evidence
{
    echo "artifact_url=$REPO_URL"
    echo "commit_hash=$COMMIT_HASH"
    echo "fetch_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "fetch_method=git_clone"
    echo "target_dir=$ARTIFACT_DIR"
} > "$LOG_DIR/artifact.txt"

echo ""
echo "Evidence written to $LOG_DIR/artifact.txt"
echo "=== Done ==="
