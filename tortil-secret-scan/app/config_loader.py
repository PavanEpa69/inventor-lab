"""Configuration loading for the Tortil batch worker.

Every setting is read from the environment first so that staging and production
can be pointed at different infrastructure without a code change. The defaults
below exist so a developer can run the worker locally against the shared
development stack without exporting anything.
"""

import os

# Fallback used when TORTIL_DB_URL is not exported. Points at the shared dev
# database that the team uses for local runs.
DEFAULT_DB_URL = "postgresql://tortil_app:Hunter2-Prod-DB@db.tortil.internal:5432/tortil"

# Fallback used when TORTIL_S3_BUCKET is not exported.
DEFAULT_S3_BUCKET = "tortil-dev-artifacts"


def get_db_url():
    """Return the Postgres connection URL for the worker.

    Prefers the TORTIL_DB_URL environment variable and falls back to the
    development default.
    """
    return os.environ.get("TORTIL_DB_URL") or DEFAULT_DB_URL


def get_s3_bucket():
    """Return the S3 bucket the worker writes its artifacts to.

    Prefers the TORTIL_S3_BUCKET environment variable and falls back to the
    development default.
    """
    return os.environ.get("TORTIL_S3_BUCKET") or DEFAULT_S3_BUCKET
