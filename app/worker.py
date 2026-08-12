"""The Tortil nightly batch worker.

Nothing here talks to the network yet; summarise() is the piece the scheduler
logs on start-up so operators can see which backing services a run picked up.
"""

from app.config_loader import get_db_url, get_s3_bucket


def summarise():
    """Return a one-line description of the services this run will use."""
    return "tortil-worker | db={0} | bucket={1}".format(get_db_url(), get_s3_bucket())


def main():
    print(summarise())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
