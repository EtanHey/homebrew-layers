# frozen_string_literal: true

cask "voicebar" do
  version "2.2.0"
  sha256 "f57fb94e779d7f03a71f92250507b2b67e1f9eab345fcb2b1cb18fd52e94ae2d"

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
                   env:          { "PATH" => "#{HOMEBREW_PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin" },
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

    To sync voices, vocabulary, and the VoiceLayer daemon secret from another Mac:
      voicelayer update --data-mode direct --data-source <source-host>:/Users/<source-user>
  EOS
end
