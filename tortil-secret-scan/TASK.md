# Tortil Inc. — the secret scan that only fails in CI

**Time budget: 30–40 minutes.**

## The situation

Tortil runs a secret scanner (`scripts/scan_secrets.py`) in two places:

- **On every engineer's laptop**, as a `pre-commit` hook.
- **In CI**, as a job that scans the whole repository.

It is the *same scanner*, in the *same repo*, at the *same commit*.

This morning a change to the batch worker went up for review. The author ran
the hook locally — clean, committed, pushed. CI went red immediately:

```
$ python3 scripts/scan_secrets.py
scan_secrets: 8 file(s) scanned, 1 finding(s):
  app/config_loader.py:13: [inline-postgres-password] database URL with an inline username:password
scan_secrets: FAILED - remove the credential from source control
```

Nobody can reproduce it locally. The prevailing theory on the team channel is
"CI is being flaky again". It is not.

Your job: work out **why the two runs disagree**, and make CI green — properly.

## What "done" means

```bash
bash scripts/grade.sh
```

must print `RESULT: PASS`. It checks five things:

1. The secret scan is clean over the **whole** repository.
2. `scripts/scan_secrets.py` is **byte-for-byte unmodified**.
3. The pre-commit hook covers the same ground CI does.
4. The unit tests pass (and are unmodified).
5. `python3 -m app.worker` still runs.

Run it as often as you like — it is the same script we grade with.

## Rules

- **Do not edit** `scripts/grade.sh`, `scripts/scan_secrets.py`, or anything
  under `tests/`.
- **Do not weaken the scanner.** Deleting a rule, loosening a regex or adding
  your file to its skip list is not a fix. The grader hashes the scanner.
- **Do not relocate the secret.** Moving it into `scripts/`, `tests/`, an
  untracked file, a `.env` that gets committed, or a base64 blob is not a fix
  either. The scanner skips those directories precisely because they hold
  deliberate fixtures — using that as a hiding place is the wrong lesson.
- **Do not delete the code the tests cover.** `get_db_url()` and
  `get_s3_bucket()` must keep working, and the worker must keep running.
- Standard library only. No `pip install`, no new dependencies.

## Hints, if you want them

- Read the scanner. Understand exactly which files it looks at, and how it
  decides.
- Then read `.pre-commit-config.yaml` and `.github/workflows/ci.yml` side by
  side and ask what each one is actually pointing the scanner at.
- There is more than one thing wrong here. Fixing one of them is not enough —
  the grader will tell you.

## Finally: write `NOTES.md`

Three sentences, no more:

1. What was diverging between the laptop run and the CI run?
2. Why is moving the secret into a file the scanner skips *not* a fix?
3. Where should the production database credential actually come from?
