from __future__ import annotations

import json
import os
import plistlib
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
CASK = REPO_ROOT / "Casks" / "brainbar.rb"
FORMULA = REPO_ROOT / "Formula" / "brainlayer.rb"


class BrainbarCaskDeferredActivationTest(unittest.TestCase):
    def test_postflight_only_writes_agents_and_migrates_config(self) -> None:
        ruby = """
require "fileutils"; require "json"
HOMEBREW_PREFIX = "/fixture"
class String; def csv; [self]; end; end
Process.define_singleton_method(:uid) { 424242 }
File.define_singleton_method(:socket?) { |_| true }
class FixtureCask
  def version(*); "1"; end
  def appdir; File.join(ENV.fetch("HOME"), "Applications"); end
  def system_command(command, **options)
    puts JSON.generate([command, options.fetch(:args)])
    Struct.new(:success?).new(ENV["ACTIVATION_AVAILABLE"] != "0")
  end
  def opoo(message); warn message; end
  def method_missing(name, *, &block); instance_eval(&block) if name == :postflight; end
end
def cask(*, &block); FixtureCask.new.instance_eval(&block); end
load ARGV.fetch(0)
"""
        with tempfile.TemporaryDirectory() as home:
            result = subprocess.run(
                ["ruby", "-e", ruby, str(CASK)],
                env=dict(os.environ, HOME=home),
                capture_output=True,
                text=True,
                check=True,
                timeout=10,
            )
            for name, binary in (
                ("brainbar-daemon", "BrainBarDaemon"),
                ("brainbar", "BrainBar"),
            ):
                label = f"com.brainlayer.{name}"
                plist = plistlib.loads(
                    (
                        Path(home) / "Library/LaunchAgents" / f"{label}.plist"
                    ).read_bytes()
                )
                self.assertEqual(plist["Label"], label)
                self.assertEqual(
                    plist["ProgramArguments"],
                    [f"{home}/Applications/BrainBar.app/Contents/MacOS/{binary}"],
                )
                self.assertEqual(
                    plist["AssociatedBundleIdentifiers"], ["com.brainlayer.brainbar"]
                )
        with tempfile.TemporaryDirectory() as home:
            unavailable = subprocess.run(
                ["ruby", "-e", ruby, str(CASK)],
                env=dict(os.environ, HOME=home, ACTIVATION_AVAILABLE="0"),
                capture_output=True,
                text=True,
                check=True,
                timeout=10,
            )
        self.assertIn(
            "upgrade the brainlayer formula first", unavailable.stderr.lower()
        )
        commands = [json.loads(line) for line in result.stdout.splitlines()]
        self.assertEqual(
            commands,
            [
                [
                    "/fixture/bin/brainlayer",
                    ["setup", "--migrate-mcp", "--no-launchd", "--no-verify-mcp"],
                ],
                ["/fixture/bin/brainlayer", ["brainbar", "activate", "--help"]],
            ],
        )

    def test_postflight_has_no_launch_or_verification(self) -> None:
        source = CASK.read_text()
        postflight = source.split("  postflight do\n", 1)[1].split("\n  uninstall", 1)[
            0
        ]
        for forbidden in (
            '"bootstrap"',
            '"kickstart"',
            '"bootout"',
            '"--verify-mcp"',
            '"restart"',
            '"/bin/launchctl"',
            '"open"',
            "`",
            "system(",
        ):
            self.assertNotIn(forbidden, postflight)
        self.assertIn("brainlayer brainbar activate --verify", source)
        self.assertIn("uninstall launchctl:", source)
        self.assertIn("zap trash:", source)
        self.assertIn('quit:      "com.brainlayer.brainbar"', source)
        self.assertIn("the cask upgrade stops BrainBar", source)
        self.assertIn("supervisor re-activates it automatically", source)
        self.assertNotIn('"jobs", "restart"', FORMULA.read_text())


if __name__ == "__main__":
    unittest.main()
