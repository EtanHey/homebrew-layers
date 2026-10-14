from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CASK = REPO_ROOT / "Casks" / "brainbar.rb"
FORMULA = REPO_ROOT / "Formula" / "brainlayer.rb"


class BrainbarCaskRestartTest(unittest.TestCase):
    def test_postflight_preserves_both_freshly_bootstrapped_jobs(self) -> None:
        ruby = """
require "fileutils"; require "json"
HOMEBREW_PREFIX = "/fixture"
class String; def csv; [self]; end; end
Process.define_singleton_method(:uid) { 424242 }
File.define_singleton_method(:socket?) { |_| true }
class FixtureCask
  def version(*); "1"; end
  def appdir; File.join(ENV.fetch("HOME"), "Applications"); end
  def system_command(command, **options); puts JSON.generate([command, options.fetch(:args)]); end
  def method_missing(name, *, &block); instance_eval(&block) if name == :postflight; end
end
def cask(*, &block); FixtureCask.new.instance_eval(&block); end
load ARGV.fetch(0)
"""
        with tempfile.TemporaryDirectory() as home:
            result = subprocess.run(
                ["ruby", "-e", ruby, str(CASK)], env=dict(os.environ, HOME=home),
                capture_output=True, text=True, check=True, timeout=10,
            )
        commands = [json.loads(line) for line in result.stdout.splitlines()]
        launch = [args for command, args in commands if command == "/bin/launchctl"]
        self.assertEqual([args[0] for args in launch], ["bootout", "bootstrap", "kickstart"] * 2)
        targets = [f"gui/424242/com.brainlayer.{name}" for name in ("brainbar-daemon", "brainbar")]
        self.assertEqual([args for args in launch if args[0] == "kickstart"], [["kickstart", t] for t in targets])

    def test_postflight_prints_restart_all_result_after_brainbar_launch(self) -> None:
        source = CASK.read_text()
        postflight = source.split("  postflight do\n", 1)[1].split("\n  uninstall", 1)[0]
        kickstart = postflight.index('args: ["kickstart", "#{domain}/#{label}"]')

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
