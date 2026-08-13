#!/usr/bin/env python3
"""Tortil secret scanner.

Walks every file tracked by git and reports credentials that have been
committed into source. Exits non-zero when anything is found so it can be used
both as a pre-commit hook and as a CI gate.

Usage:
    python3 scripts/scan_secrets.py              # scan every tracked file
    python3 scripts/scan_secrets.py app/x.py     # scan only the named files

Paths under scripts/ and tests/ are skipped: they hold deliberate fixtures and
the scanner's own patterns, which would otherwise report themselves.
"""

import re
import subprocess
import sys

# Prefixes that legitimately contain credential-shaped strings.
SKIP_PREFIXES = ("scripts/", "tests/")

RULES = (
    (
        "inline-postgres-password",
        re.compile(r"postgres(?:ql)?://[^\s:/@]+:[^\s:/@]+@"),
        "database URL with an inline username:password",
    ),
    (
        "aws-secret-access-key",
        re.compile(
            r"aws[_\-]?secret[_\-]?access[_\-]?key\W{0,4}[A-Za-z0-9/+=]{40}",
            re.IGNORECASE,
        ),
        "AWS secret access key",
    ),
)


def tracked_files():
    """Return every path git is tracking, relative to the repo root."""
    try:
        out = subprocess.run(
            ["git", "ls-files"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        ).stdout.decode("utf-8", "replace")
    except (OSError, subprocess.CalledProcessError) as exc:
        sys.stderr.write("scan_secrets: unable to list tracked files: {0}\n".format(exc))
        raise SystemExit(2)
    return [line for line in out.splitlines() if line.strip()]


def should_skip(path):
    normalised = path.replace("\\", "/")
    return normalised.startswith(SKIP_PREFIXES)


def scan_file(path):
    """Return a list of (line_number, rule_name, description, line) findings."""
    try:
        with open(path, "rb") as handle:
            raw = handle.read()
    except (IOError, OSError):
        return []
    if b"\x00" in raw:
        return []
    findings = []
    for number, line in enumerate(raw.decode("utf-8", "replace").splitlines(), 1):
        for name, pattern, description in RULES:
            if pattern.search(line):
                findings.append((number, name, description, line.strip()))
    return findings


def main(argv):
    paths = argv[1:] or tracked_files()
    findings = []
    scanned = 0
    for path in paths:
        if should_skip(path):
            continue
        scanned += 1
        for number, name, description, line in scan_file(path):
            findings.append((path, number, name, description, line))

    if not findings:
        print("scan_secrets: {0} file(s) scanned, no secrets found".format(scanned))
        return 0

    print("scan_secrets: {0} file(s) scanned, {1} finding(s):".format(scanned, len(findings)))
    for path, number, name, description, line in findings:
        print("  {0}:{1}: [{2}] {3}".format(path, number, name, description))
        print("      {0}".format(line[:120]))
    print("scan_secrets: FAILED - remove the credential from source control")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
