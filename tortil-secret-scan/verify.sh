#!/usr/bin/env bash
#
# Killercoda step verification: the step passes only when the grader passes.

LAB_DIR="/root/tortil-lab"

if [ ! -f "$LAB_DIR/scripts/grade.sh" ]; then
  echo "Could not find $LAB_DIR/scripts/grade.sh - is the lab repo still there?"
  exit 1
fi

cd "$LAB_DIR" || exit 1
bash scripts/grade.sh
exit $?
