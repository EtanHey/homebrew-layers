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
require "fileutils"; require "json"; require "rbconfig"
HOMEBREW_PREFIX = File.join(ENV.fetch("HOME"), "prefix")
class String; def csv; [self]; end; end
prefix_bin = File.join(HOMEBREW_PREFIX, "bin")
FileUtils.mkdir_p(prefix_bin)
File.write(File.join(prefix_bin, "brainlayer"), <<~RUBY)
  #!#{RbConfig.ruby}
  require "json"
  puts JSON.generate([__FILE__, ARGV])
  exit(ENV["ACTIVATION_AVAILABLE"] == "0" && ARGV == ["brainbar", "activate", "--help"] ? 1 : 0)
RUBY
File.chmod(0755, File.join(prefix_bin, "brainlayer"))
caskroom = File.join(HOMEBREW_PREFIX, "Caskroom/brainbar")
FileUtils.mkdir_p(caskroom)
File.symlink("/Users/localaiengine/missing", File.join(caskroom, "tainted"))
File.symlink("/Users/another/missing", File.join(caskroom, "other"))
File.write(File.join(caskroom, "keep"), "keep")
class FixtureCask
  def version(*); "1"; end
  def appdir; File.join(ENV.fetch("HOME"), "Applications"); end
  def expand(value)
    value.to_s.gsub("{{HOMEBREW_PREFIX}}", HOMEBREW_PREFIX)
      .gsub("{{caskroom_path}}", File.join(HOMEBREW_PREFIX, "Caskroom/brainbar"))
      .gsub("{{appdir}}", appdir)
  end
  def mkdir_p(path, base:)
    raise "unexpected base" unless base == :home
    FileUtils.mkdir_p(File.join(ENV.fetch("HOME"), path))
  end
  def write_file(path, content, base:, **options)
    raise "unexpected base" unless base == :home
    File.write(File.join(ENV.fetch("HOME"), path), expand(content))
  end
  def run(command, args: [], must_succeed: true, **options)
    executable = command == "/usr/bin/ruby" ? RbConfig.ruby : expand(command)
    succeeded = Kernel.system(executable, *args.map { |arg| expand(arg) })
    raise "step failed" if must_succeed && !succeeded
  end
  def method_missing(name, *, &block)
    raise "deprecated flight block" if [:preflight, :postflight].include?(name)
    instance_eval(&block) if [:preflight_steps, :postflight_steps].include?(name)
  end
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
            caskroom = Path(home) / "prefix/Caskroom/brainbar"
            self.assertFalse((caskroom / "tainted").is_symlink())
            self.assertTrue((caskroom / "other").is_symlink())
            self.assertEqual((caskroom / "keep").read_text(), "keep")
            commands = [json.loads(line) for line in result.stdout.splitlines()]
            commands = [
                [command.replace(f"{home}/prefix", "/fixture"), args]
                for command, args in commands
            ]
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
            missing_commands = [
                json.loads(line) for line in unavailable.stdout.splitlines()
            ]
            missing_commands = [
                [command.replace(f"{home}/prefix", "/fixture"), args]
                for command, args in missing_commands
            ]
        self.assertEqual(missing_commands, commands)
        self.assertIn(
            "upgrade the brainlayer formula first", unavailable.stderr.lower()
        )
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
        postflight = source.split("  postflight_steps do\n", 1)[1].split(
            "\n  uninstall", 1
        )[0]
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
        self.assertIn("  preflight_steps do\n", source)
        self.assertNotIn("  preflight do\n", source)
        self.assertNotIn("  postflight do\n", source)
        self.assertIn("brainlayer brainbar activate --verify", source)
        self.assertIn("uninstall launchctl:", source)
        self.assertIn("zap trash:", source)
        self.assertIn('quit:      "com.brainlayer.brainbar"', source)
        self.assertIn("the cask upgrade stops BrainBar", source)
        self.assertIn("supervisor re-activates it automatically", source)
        self.assertNotIn('"jobs", "restart"', FORMULA.read_text())


if __name__ == "__main__":
    unittest.main()
