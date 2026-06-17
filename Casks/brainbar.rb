cask "brainbar" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/EtanHey/brainlayer/releases/download/v#{version}/BrainBar.zip"
  name "BrainBar"
  desc "BrainLayer menu-bar app and local MCP socket"
  homepage "https://github.com/EtanHey/brainlayer"

  depends_on macos: :sonoma
  depends_on formula: "brainlayer"

  app "BrainBar.app"

  postflight do
    system_command "#{HOMEBREW_PREFIX}/bin/brainlayer",
                   args:         ["setup"],
                   print_stdout: true,
                   print_stderr: true
  end

  uninstall launchctl: [
              "com.brainlayer.brainbar",
              "com.brainlayer.brainbar-daemon",
            ],
            quit:      "com.brainlayer.BrainBar",
            delete:    [
              "~/Library/LaunchAgents/com.brainlayer.brainbar-daemon.plist",
              "~/Library/LaunchAgents/com.brainlayer.brainbar.plist",
            ]

  zap trash: [
    "~/.config/brainlayer",
    "~/.local/share/brainlayer/logs",
    "~/Library/Logs/brainlayer",
  ]

  caveats <<~EOS
    BrainBar connects agents to BrainLayer over /tmp/brainbar.sock.

    If setup did not complete during cask install, run:
      brainlayer setup
  EOS
end
