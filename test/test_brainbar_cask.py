from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CASK = REPO_ROOT / "Casks" / "brainbar.rb"
FORMULA = REPO_ROOT / "Formula" / "brainlayer.rb"


class BrainbarCaskRestartTest(unittest.TestCase):
    def test_postflight_prints_restart_all_result_after_brainbar_launch(self) -> None:
        source = CASK.read_text()
        postflight = source.split("  postflight do\n", 1)[1].split("\n  uninstall", 1)[0]
        kickstart = postflight.index('args: ["kickstart", "-k", "#{domain}/#{label}"]')

        restart = re.search(
            r'system_command "/opt/homebrew/opt/brainlayer/bin/brainlayer",'
            r'\s+args:\s*\["jobs", "restart", "--all", "--verify"\],'
            r'\s+print_stdout:\s*true,'
            r'\s+print_stderr:\s*true,'
            r'\s+must_succeed:\s*false',
            postflight,
        )
        self.assertIsNotNone(restart)
        assert restart is not None
        self.assertGreater(restart.start(), kickstart)
        self.assertNotIn('"jobs", "restart"', FORMULA.read_text())


if __name__ == "__main__":
    unittest.main()
