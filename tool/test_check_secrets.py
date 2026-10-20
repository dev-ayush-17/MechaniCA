import unittest
from pathlib import Path

from check_secrets import findings, scan_file

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tool" / "testdata" / "secret_scan_fixture.txt"


class SecretScanTest(unittest.TestCase):
    def test_secret_scan_fails_on_a_fixture(self) -> None:
        self.assertTrue(FIXTURE.is_file())
        self.assertTrue(scan_file(FIXTURE))

    def test_repo_scan_skips_the_fixture(self) -> None:
        hits = findings(ROOT)
        self.assertNotIn("tool/testdata/secret_scan_fixture.txt", hits)


if __name__ == "__main__":
    unittest.main()
