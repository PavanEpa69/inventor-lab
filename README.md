# Tortil intern lab — "the secret scan that only fails in CI"

A ~30–40 minute auto-graded infrastructure task for intern candidates.

A `pre-commit` secret scan passes on every engineer's laptop and fails in CI at
the same commit. The candidate has to find the divergence and make CI green
without weakening the scanner or hiding the secret.

Python 3, standard library only, no dependencies to install.

**Start with [TASK.md](TASK.md).**

## Layout

```
app/config_loader.py        # configuration defaults
app/worker.py               # summarise(); runnable via python3 -m app.worker
scripts/scan_secrets.py     # the secret scanner
scripts/grade.sh            # the automated grader — 5 checks, RESULT: PASS|FAIL
tests/test_worker.py        # unittest
.pre-commit-config.yaml     # the local hook wiring
.github/workflows/ci.yml    # the CI jobs
TASK.md                     # the brief (also the Killercoda step text)
index.json intro.md         # Killercoda scenario wrapper
background.sh verify.sh
finish.md
```

## Running it locally

The scanner enumerates files with `git ls-files`, so the repo must be a git
repo with the files tracked:

```bash
git init && git add -A && git commit -m init
bash scripts/grade.sh
```

## Grading split

| | What | Who |
|---|---|---|
| Functional | `bash scripts/grade.sh` → `RESULT: PASS` (exit 0) | Fully automated, no reading needed |
| Reasoning | `NOTES.md` (3 sentences) + shape of the diff | Human, in the crit |

The grader's five checks: secret scan clean over the whole repo; scanner
byte-for-byte unmodified (sha256 baked into `grade.sh`, CRLF-normalised); the
pre-commit hook covers the same ground CI does; unit tests pass and are
unmodified; `python3 -m app.worker` runs.

## Publishing to Killercoda

Killercoda scenarios are served straight out of a public GitHub repo.

1. Keep instructor notes **out of this repo** — it is public, and anything
   committed here stays in its history.
2. Point `REPO_URL` in `background.sh` at the public HTTPS clone URL of that
   repo (or set `TORTIL_LAB_REPO_URL`). `background.sh` clones it to
   `/root/tortil-lab` inside the VM, strips the instructor/wrapper files, and
   `git init`s it so the scanner works.
3. Push the repo to GitHub, public.
4. Sign in at <https://killercoda.com/creator> and connect the repository under
   *Creator → Repositories*. Killercoda installs a push webhook, so **every
   subsequent push re-syncs the scenario automatically** — there is no separate
   publish step after the first connect.
5. **Each top-level folder in the repo is one scenario**, keyed by its
   `index.json`. This repo is a single scenario served from the repository
   root; to host several labs side by side, move each into its own folder
   (`tortil-secret-scan/`, `next-lab/`, …) with its own `index.json`, and
   Killercoda will list them separately.
6. The scenario is reachable at
   `https://killercoda.com/<your-profile>/scenario/<folder-or-repo-name>`.
   Scenarios stay private to you until you mark them public in the creator
   area.

Wrapper details: `index.json` uses the `ubuntu` backend with the `ide` layout,
one step whose `verify` is `verify.sh`, which `cd`s to `/root/tortil-lab` and
runs `scripts/grade.sh` — so the step only completes on `RESULT: PASS`. The
step text is `TASK.md` itself, so the brief has a single source of truth.
