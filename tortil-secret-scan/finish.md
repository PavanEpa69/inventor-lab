# Done — CI is green for the right reason

You found both halves of this:

1. **The secret itself.** `app/config_loader.py` shipped a default database URL
   with the password inlined. Defaults are convenient and they are also how
   credentials get committed — a default that cannot be a credential is the
   only safe kind.

2. **The scope divergence.** The pre-commit hook had been narrowed with
   `files: ^app/worker\.py$` to quiet down some noise. From that moment the
   laptop check and the CI check were different checks wearing the same name.
   The local hook could not see the file the secret lived in, so it passed;
   CI scanned everything, so it failed.

The thing worth carrying out of this: **a check that runs in two places is only
one check if both places look at the same thing.** A narrowed hook does not
report that it is narrowed — it just quietly goes green. When a gate disagrees
with itself, compare scopes before you blame the environment.

And on the credential: the fix was to remove it, not to move it. Anything the
scanner skips is a fixture directory, not a hiding place. Production database
credentials belong in the environment, injected at deploy time from a secret
manager, never in a source file and never in a default.

If you have not written `NOTES.md` yet, do that now — three sentences.
