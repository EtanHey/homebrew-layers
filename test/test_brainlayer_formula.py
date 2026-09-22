from __future__ import annotations

import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
FORMULA = REPO_ROOT / "Formula" / "brainlayer.rb"


def formula_venv_options() -> list[str]:
    source = FORMULA.read_text()
    match = re.search(
        r'^\s*system python, "-m", "venv"(?P<arguments>(?:, "[^"]+")*), venv$',
        source,
        re.MULTILINE,
    )
    if match is None:
        raise AssertionError("BrainLayer venv construction command not found")
    return re.findall(r'"([^"]+)"', match.group("arguments"))


class BrainlayerFormulaVenvTest(unittest.TestCase):
    def test_venv_construction_discards_stale_package_metadata(self) -> None:
        options = formula_venv_options()
        self.assertIn("--clear", options)

        with tempfile.TemporaryDirectory() as temporary_directory:
            venv = Path(temporary_directory) / "venv"
            subprocess.run(
                [sys.executable, "-m", "venv", str(venv)],
                check=True,
            )
            venv_python = venv / "bin" / "python"
            site_packages = Path(
                subprocess.check_output(
                    [
                        str(venv_python),
                        "-c",
                        "import sysconfig; print(sysconfig.get_path('purelib'))",
                    ],
                    text=True,
                ).strip()
            )
            stale_metadata = site_packages / "idna-999.dist-info"
            stale_metadata.mkdir()
            (stale_metadata / "METADATA").write_text(
                "Metadata-Version: 2.1\nName: idna\nVersion: 999\n"
            )
            self.assertTrue(stale_metadata.exists())
            self.assertFalse((site_packages / "idna").exists())

            subprocess.run(
                [sys.executable, "-m", "venv", *options, str(venv)],
                check=True,
            )

            self.assertFalse(stale_metadata.exists())


if __name__ == "__main__":
    unittest.main()
