# The secret scan that only fails in CI

You have just joined the platform team at **Tortil Inc.**

Tortil runs one secret scanner in two places: as a `pre-commit` hook on every
engineer's laptop, and as a CI job on every push. Same script, same repo, same
commit.

This morning that stopped being true in practice. A change to the batch worker
passed the hook locally, was committed and pushed, and CI went red on the
secret scan. Nobody can reproduce it on their machine. The team has settled on
"CI is flaky".

It is not flaky. Your job is to find out what is actually diverging, and to
make CI green **without weakening the check and without hiding the secret**.

The repo is at `/root/tortil-lab` and the terminal already starts there.
Your work is graded by a script — `bash scripts/grade.sh` — which you can run
as many times as you want.

Budget about 30–40 minutes. Click **START**.
