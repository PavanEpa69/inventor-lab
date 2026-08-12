"""Unit tests for the Tortil batch worker.

DO NOT EDIT. The grader runs these as-is.
"""

import os
import re
import unittest

from app import config_loader
from app.worker import summarise

# Matches "scheme://user:password@host", i.e. a credential inlined into a URL.
INLINE_CREDENTIALS = re.compile(r"://[^\s:/@]+:[^\s:/@]+@")

ENV_VARS = ("TORTIL_DB_URL", "TORTIL_S3_BUCKET")


class WorkerTestCase(unittest.TestCase):
    def setUp(self):
        self._saved = {name: os.environ.pop(name, None) for name in ENV_VARS}

    def tearDown(self):
        for name, value in self._saved.items():
            if value is None:
                os.environ.pop(name, None)
            else:
                os.environ[name] = value

    def test_summarise_returns_a_useful_line(self):
        line = summarise()
        self.assertIsInstance(line, str)
        self.assertIn("tortil-worker", line)
        self.assertIn(config_loader.get_db_url(), line)
        self.assertIn(config_loader.get_s3_bucket(), line)

    def test_environment_wins_over_the_default(self):
        os.environ["TORTIL_DB_URL"] = "postgresql://db.example.test:5432/from_env"
        os.environ["TORTIL_S3_BUCKET"] = "bucket-from-env"
        self.assertEqual(
            config_loader.get_db_url(), "postgresql://db.example.test:5432/from_env"
        )
        self.assertEqual(config_loader.get_s3_bucket(), "bucket-from-env")
        self.assertIn("from_env", summarise())
        self.assertIn("bucket-from-env", summarise())

    def test_default_db_url_still_exists_and_is_a_postgres_url(self):
        default = config_loader.get_db_url()
        self.assertTrue(default, "get_db_url() must return a value with no env var set")
        self.assertTrue(
            default.startswith("postgres"),
            "the default must still be a postgres URL, got: {0}".format(default),
        )

    def test_default_db_url_carries_no_inline_credentials(self):
        default = config_loader.get_db_url()
        self.assertIsNone(
            INLINE_CREDENTIALS.search(default),
            "the default DB URL must not contain inline user:password@ credentials",
        )

    def test_default_bucket_still_exists(self):
        self.assertTrue(config_loader.get_s3_bucket())


if __name__ == "__main__":
    unittest.main()
