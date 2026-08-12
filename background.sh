#!/usr/bin/env bash
#
# Killercoda background setup. Runs before the candidate sees the terminal.
#
# Puts the lab repo at /root/tortil-lab with git history initialised, because
# scripts/scan_secrets.py enumerates files via `git ls-files`.

set -u

LAB_DIR="/root/tortil-lab"

# Set this to the public HTTPS URL of the handout repo before publishing.
REPO_URL="${TORTIL_LAB_REPO_URL:-https://github.com/PavanEpa69/inventor-lab.git}"

# Scenario assets land here (see "assets" in index.json); used when REPO_URL
# has not been pointed at a real repository yet.
ASSET_DIR="/root/scenario-files"

export DEBIAN_FRONTEND=noninteractive

if ! command -v git >/dev/null 2>&1; then
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq git >/dev/null 2>&1
fi

rm -rf "$LAB_DIR"

if ! git clone --depth 1 --quiet "$REPO_URL" "$LAB_DIR" 2>/dev/null; then
  echo "background: clone failed, falling back to scenario assets" >&2
  mkdir -p "$LAB_DIR"
  if [ -d "$ASSET_DIR" ]; then
    cp -r "$ASSET_DIR"/. "$LAB_DIR"/
  fi
fi

cd "$LAB_DIR" || exit 1

# Instructor notes and the Killercoda wrapper are not part of the candidate's
# working copy.
rm -rf SOLUTION.md index.json intro.md finish.md background.sh verify.sh .git

git init --quiet .
git config user.email "ci@tortil.invalid"
git config user.name "Tortil CI"
git add -A
git commit --quiet -m "Tortil batch worker: nightly summary + secret scan wiring"

chmod +x scripts/grade.sh 2>/dev/null

# Leave the candidate sitting in the repo.
echo "cd $LAB_DIR" >> /root/.bashrc

touch /tmp/background-done
