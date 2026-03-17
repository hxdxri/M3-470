#!/usr/bin/env bash
# 01_fetch_artifact.sh — Clone or update the official CCAligner artifact
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ARTIFACT_DIR="${ROOT_DIR}/tools/ccaligner_artifact"
LOG_DIR="${ROOT_DIR}/evidence/logs"

mkdir -p "$LOG_DIR"

REPO_URL="https://github.com/PCWcn/CCAligner.git"

echo "=== CCAligner Artifact Fetch ==="
echo "Repo URL : $REPO_URL"
echo "Target   : $ARTIFACT_DIR"
echo ""

if [ -d "$ARTIFACT_DIR/.git" ]; then
    echo "Artifact already cloned. Pulling latest..."
    cd "$ARTIFACT_DIR"
    git pull --ff-only 2>&1 || echo "Pull failed (possibly offline), using existing clone."
else
    echo "Cloning CCAligner artifact..."
    rm -rf "$ARTIFACT_DIR"
    mkdir -p "$(dirname "$ARTIFACT_DIR")"
    git clone "$REPO_URL" "$ARTIFACT_DIR" 2>&1
fi

cd "$ARTIFACT_DIR"
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

{
    echo "artifact_url=$REPO_URL"
    echo "commit_hash=$COMMIT_HASH"
    echo "fetch_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "fetch_method=git_clone"
    echo "target_dir=$ARTIFACT_DIR"
} > "$LOG_DIR/artifact.txt"

echo ""
echo "Commit hash: $COMMIT_HASH"
echo "Evidence written to $LOG_DIR/artifact.txt"
echo "=== Done ==="
