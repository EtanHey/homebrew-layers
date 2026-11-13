# frozen_string_literal: true

cask "voicebar" do
  version "2.4.0"
  sha256 "98c0103dab696266324207eb313653592ad93128b6a3331cd23214b3f6955ed1"

  url "https://github.com/EtanHey/voicelayer/releases/download/v#{version}/VoiceBar.zip"
  name "VoiceBar"
  desc "VoiceLayer menu-bar app and local voice daemon"
  homepage "https://github.com/EtanHey/voicelayer"

  depends_on macos: :sonoma
  depends_on formula: "voicelayer"

  app "VoiceBar.app"

  postflight do
    system_command "#{HOMEBREW_PREFIX}/bin/voicelayer",
        args:         ["setup", "--cask-postflight"],
        env:          { "PATH" => "#{HOMEBREW_PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin" },
        must_succeed: false,
        print_stdout: true,
        print_stderr: true
    system_command "/bin/echo", args: ["VoiceBar bundle retained. If setup reported an error (formula/cask version mismatch or startup failure), update etanhey/layers/voicelayer and etanhey/layers/voicebar together, then run voicelayer setup --cask-postflight from a terminal outside brew. Do not delete update-gate evidence."], must_succeed: false, print_stdout: true
  end

  uninstall launchctl: [
              "com.voicelayer.f5-to-f18-hidutil",
              "com.voicelayer.mcp-daemon",
              "com.voicelayer.voicebar",
            ],
            quit:      "com.voicelayer.voicebar",
            # `delete:` always shells out to `sudo rm`, which has no TTY over ssh and
            # aborts the whole uninstall — including the upgrade path, which runs
            # uninstall first. Nothing in ~/Library/LaunchAgents is root-owned, so
            # `trash:` removes the same files without asking for a password.
            trash:     [
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
