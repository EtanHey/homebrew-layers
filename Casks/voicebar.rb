cask "voicebar" do
  version "2.1.7"
  sha256 "4b8f7e7661833edab0dbe31fcaf66e77b23ab7ff8a4ddf16baaf02203d71c03d"

  url "https://github.com/EtanHey/voicelayer/releases/download/v#{version}/VoiceBar.zip"
  name "VoiceBar"
  desc "VoiceLayer menu-bar app and local voice daemon"
  homepage "https://github.com/EtanHey/voicelayer"

  depends_on macos: :sonoma
  depends_on formula: "voicelayer"

  app "VoiceBar.app"

  postflight do
    system_command "#{HOMEBREW_PREFIX}/bin/voicelayer",
                   args:         ["setup"],
                   print_stdout: true,
                   print_stderr: true
  end

  uninstall launchctl: [
              "com.voicelayer.f5-to-f18-hidutil",
              "com.voicelayer.mcp-daemon",
              "com.voicelayer.voicebar",
            ],
            quit:      "com.voicelayer.voicebar",
            delete:    [
              "~/Library/LaunchAgents/com.voicelayer.f5-to-f18-hidutil.plist",
              "~/Library/LaunchAgents/com.voicelayer.mcp-daemon.plist",
              "~/Library/LaunchAgents/com.voicelayer.voicebar.plist",
            ]

  zap trash: [
    "~/.local/state/voicelayer",
    "~/.voicelayer",
    "~/Library/Application Support/VoiceLayer",
  ]

  caveats <<~EOS
    VoiceBar connects agents to VoiceLayer over /tmp/voicelayer-mcp.sock.

    If setup did not complete during cask install, run:
      voicelayer setup
  EOS
end
