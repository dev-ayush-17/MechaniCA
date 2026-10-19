import tempfile
import unittest
from pathlib import Path

from check_import_boundaries import scan


def _write(root: Path, relative: str, text: str) -> None:
    target = root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")


class BoundaryTest(unittest.TestCase):
    def test_flags_dart_vendor_import_in_presentation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(
                root,
                "app/lib/features/x/presentation/s.dart",
                "import 'package:cloud_firestore/cloud_firestore.dart';\n",
            )
            self.assertEqual(len(scan(root)), 1)

    def test_allows_dart_vendor_import_in_adapters(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(
                root,
                "app/lib/features/x/data/adapters/a.dart",
                "import 'package:cloud_firestore/cloud_firestore.dart';\n",
            )
            self.assertEqual(scan(root), [])

    def test_flags_python_vendor_import_in_domain(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "backend/app/domain/x.py", "import firebase_admin\n")
            _write(root, "backend/app/domain/y.py", "from google.cloud import firestore\n")
            self.assertEqual(len(scan(root)), 2)

    def test_allows_python_vendor_import_in_adapters(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "backend/app/adapters/firebase/x.py", "import firebase_admin\n")
            self.assertEqual(scan(root), [])

    def test_real_tree_is_clean(self) -> None:
        self.assertEqual(scan(Path(__file__).resolve().parent.parent), [])


if __name__ == "__main__":
    unittest.main()
