#!/usr/bin/env bash
#
# Tortil intern lab - automated grader.
#
# Run from anywhere:  bash scripts/grade.sh
#
# Exits 0 only when every check below passes. Candidates must not edit this
# file, scripts/scan_secrets.py, or anything under tests/.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2

# sha256 of scripts/scan_secrets.py and tests/test_worker.py as handed out,
# computed over the file with CRLF normalised to LF.
EXPECTED_SCANNER_SHA256="58492f9ed906221b7555b3346fa74114e81051218ffb93ca6ce8a3035e9d9211"
EXPECTED_TESTS_SHA256="bada24fc9785d1bf3b5b6c4eb8a492c349b2eb27856b723d3020066a61094251"

FAILURES=0

pass() { printf 'PASS  [%s/5] %s\n' "$1" "$2"; }
fail() { printf 'FAIL  [%s/5] %s\n' "$1" "$2"; FAILURES=$((FAILURES + 1)); }
detail() { printf '            %s\n' "$1"; }

sha_of() {
  python3 - "$1" <<'PY'
import hashlib, sys
try:
    data = open(sys.argv[1], "rb").read()
except OSError:
    print("MISSING")
    raise SystemExit(0)
print(hashlib.sha256(data.replace(b"\r\n", b"\n")).hexdigest())
PY
}

echo "Tortil intern lab - grading $REPO_ROOT"
echo "---------------------------------------------------------------"

# ---------------------------------------------------------------------------
# 1. The secret scan must be clean across the whole repository.
# ---------------------------------------------------------------------------
SCAN_OUTPUT="$(python3 scripts/scan_secrets.py 2>&1)"
SCAN_STATUS=$?
if [ "$SCAN_STATUS" -eq 0 ]; then
  pass 1 "secret scan is clean over the whole repository"
else
  fail 1 "secret scan still reports findings over the whole repository"
  while IFS= read -r line; do detail "$line"; done <<< "$SCAN_OUTPUT"
fi

# ---------------------------------------------------------------------------
# 2. The scanner itself must be untouched - no weakening the check.
# ---------------------------------------------------------------------------
ACTUAL_SCANNER_SHA256="$(sha_of scripts/scan_secrets.py)"
if [ "$ACTUAL_SCANNER_SHA256" = "$EXPECTED_SCANNER_SHA256" ]; then
  pass 2 "scripts/scan_secrets.py is unmodified"
else
  fail 2 "scripts/scan_secrets.py has been modified or removed"
  detail "expected sha256 $EXPECTED_SCANNER_SHA256"
  detail "actual   sha256 $ACTUAL_SCANNER_SHA256"
  detail "restore the scanner - the fix belongs in the code it scans"
fi

# ---------------------------------------------------------------------------
# 3. The pre-commit hook must scan the same ground CI does.
# ---------------------------------------------------------------------------
HOOK_OUTPUT="$(python3 - <<'PY'
import re
import sys

CONFIG = ".pre-commit-config.yaml"
# The file the secret used to live in. The local hook must be able to see it.
MUST_BE_SCANNED = "app/config_loader.py"

try:
    lines = open(CONFIG, "r", encoding="utf-8").read().splitlines()
except OSError:
    print("no {0} found".format(CONFIG))
    sys.exit(1)

# Split the file into per-hook blocks so we only judge the secret-scan hook.
blocks, current = [], []
for line in lines:
    if re.match(r"\s*-\s+(id|repo):", line):
        if current:
            blocks.append(current)
        current = []
    current.append(line)
if current:
    blocks.append(current)


def field(block, key):
    for line in block:
        match = re.match(r"\s*{0}:\s*(.*?)\s*$".format(key), line)
        if match:
            return match.group(1).strip().strip("'\"")
    return None


scan_blocks = [b for b in blocks if "scan_secrets.py" in "\n".join(b)]
if not scan_blocks:
    print("the pre-commit config no longer runs scripts/scan_secrets.py")
    sys.exit(1)

for block in scan_blocks:
    files = field(block, "files")
    exclude = field(block, "exclude")
    if files:
        try:
            matches = re.search(files, MUST_BE_SCANNED) is not None
        except re.error as exc:
            print("files: pattern {0!r} is not a valid regex ({1})".format(files, exc))
            sys.exit(1)
        if not matches:
            print(
                "hook is still narrowed: files: {0!r} does not match {1}".format(
                    files, MUST_BE_SCANNED
                )
            )
            sys.exit(1)
    if exclude:
        try:
            excluded = re.search(exclude, MUST_BE_SCANNED) is not None
        except re.error as exc:
            print("exclude: pattern {0!r} is not a valid regex ({1})".format(exclude, exc))
            sys.exit(1)
        if excluded:
            print(
                "hook excludes {0}: exclude: {1!r}".format(MUST_BE_SCANNED, exclude)
            )
            sys.exit(1)

print("hook runs the scanner and would scan {0}".format(MUST_BE_SCANNED))
sys.exit(0)
PY
)"
HOOK_STATUS=$?
if [ "$HOOK_STATUS" -eq 0 ]; then
  pass 3 "pre-commit hook covers the same files CI does"
  detail "$HOOK_OUTPUT"
else
  fail 3 "pre-commit hook does not cover what CI scans"
  while IFS= read -r line; do detail "$line"; done <<< "$HOOK_OUTPUT"
fi

# ---------------------------------------------------------------------------
# 4. Unit tests must pass, and must be the tests we handed out.
# ---------------------------------------------------------------------------
ACTUAL_TESTS_SHA256="$(sha_of tests/test_worker.py)"
if [ "$ACTUAL_TESTS_SHA256" != "$EXPECTED_TESTS_SHA256" ]; then
  fail 4 "tests/test_worker.py has been modified or removed"
  detail "expected sha256 $EXPECTED_TESTS_SHA256"
  detail "actual   sha256 $ACTUAL_TESTS_SHA256"
else
  TEST_OUTPUT="$(python3 -m unittest discover -s tests -t . 2>&1)"
  TEST_STATUS=$?
  if [ "$TEST_STATUS" -eq 0 ]; then
    pass 4 "unit tests pass"
  else
    fail 4 "unit tests fail"
    while IFS= read -r line; do detail "$line"; done <<< "$TEST_OUTPUT"
  fi
fi

# ---------------------------------------------------------------------------
# 5. The worker must still run.
# ---------------------------------------------------------------------------
WORKER_OUTPUT="$(python3 -m app.worker 2>&1)"
WORKER_STATUS=$?
if [ "$WORKER_STATUS" -eq 0 ]; then
  pass 5 "python3 -m app.worker runs"
  detail "$WORKER_OUTPUT"
else
  fail 5 "python3 -m app.worker does not run"
  while IFS= read -r line; do detail "$line"; done <<< "$WORKER_OUTPUT"
fi

echo "---------------------------------------------------------------"
if [ "$FAILURES" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
fi
echo "RESULT: FAIL ($FAILURES check(s) failed)"
exit 1
