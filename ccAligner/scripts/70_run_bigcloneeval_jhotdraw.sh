#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BCEVAL_DIR="$ROOT_DIR/bigcloneeval"
COMMANDS_DIR="$BCEVAL_DIR/commands"
TOOL_NAME="CCAligner-JHotDraw"
TOOL_DESC="CCAligner run on NiCad JHotDraw full example"
CLONES_FILE="$ROOT_DIR/out/ccaligner_ihotdraw_full/clones_bceval.csv"
EVAL_REPORT="$ROOT_DIR/out/ccaligner_ihotdraw_full/bceval_evaluate.txt"

if [ ! -f "$CLONES_FILE" ]; then
  echo "ERROR: clones file not found: $CLONES_FILE"
  exit 1
fi

cd "$COMMANDS_DIR"

echo "=== BigCloneEval helper: verify DB files ==="
if [ ! -f "$BCEVAL_DIR/bigclonebenchdb/bcb.mv.db" ] && [ ! -f "$BCEVAL_DIR/bigclonebenchdb/bcb.h2.db" ]; then
  echo "WARNING: BigCloneBench DB not found in $BCEVAL_DIR/bigclonebenchdb."
  echo "Please download and extract the official BigCloneBench H2 DB into this directory."
  echo "Evaluation cannot run without it."
fi

# Register tool if not already registered
EXISTING_TOOL_ID=$(./listTools | awk -v name="$TOOL_NAME" '$0 ~ name {print $1}' | head -n1 || true)
if [ -n "$EXISTING_TOOL_ID" ]; then
  echo "Tool already registered as ID $EXISTING_TOOL_ID"
  TOOL_ID="$EXISTING_TOOL_ID"
else
  TOOL_ID=$(./registerTool -n "$TOOL_NAME" -d "$TOOL_DESC")
  echo "Registered tool ID $TOOL_ID"
fi

echo "Importing clones file to tool $TOOL_ID..."
./importClones -t "$TOOL_ID" -c "$CLONES_FILE"

echo "Count clones now:"
./countClones -t "$TOOL_ID"

echo "Attempting evaluation (may fail if DB missing)..."
./evaluateTool -t "$TOOL_ID" -o "$EVAL_REPORT" || true

echo "Done. Tool ID=$TOOL_ID. Clones file=$CLONES_FILE. Report=$EVAL_REPORT"
