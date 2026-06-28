cask "brainbar" do
  version "1.4.1"
  sha256 "5ba9d5dcc9c67b101efd2bfe5fda2e5c88c90b18421a5c922b36eee326c4a5b8"

  url "https://github.com/EtanHey/brainlayer/releases/download/v#{version.csv.first}/BrainBar.zip"
  name "BrainBar"
  desc "BrainLayer menu-bar app and local MCP socket"
  homepage "https://github.com/EtanHey/brainlayer"

  depends_on macos: :sonoma
  depends_on formula: "brainlayer"

  app "BrainBar.app"

  # #1: self-heal localaiengine-tainted dangling Caskroom symlinks left by a machine
  # rename, so a reinstall is not blocked by a dead "already installed" artifact.
  # User-owned only — no sudo. Root-owned leftovers still need manual sudo (caveats).
  preflight do
    caskroom = "#{HOMEBREW_PREFIX}/Caskroom/brainbar"
    next unless Dir.exist?(caskroom)

    Dir.glob("#{caskroom}/**/*", File::FNM_DOTMATCH).each do |path|
      next unless File.symlink?(path)

      target = File.readlink(path)
      next unless target.start_with?("/Users/localaiengine/")
      next if File.exist?(path) # only remove DANGLING (dead-target) tainted links

      File.delete(path)
    end
  end

  postflight do
    system_command "#{HOMEBREW_PREFIX}/bin/brainlayer",
                   args:         ["setup"],
                   print_stdout: true,
                   print_stderr: true

    # #7c: BrainBar.app does not spawn its daemon on launch (it only discovers an
    # existing one), and the daemon/UI LaunchAgents are removed on uninstall and
    # never recreated — so the fleet brain_search socket /tmp/brainbar.sock stays
    # dead after a reinstall. Write + (re)bootstrap both agents here so launchd
    # keeps them alive. Idempotent.
    launch_agents = File.expand_path("~/Library/LaunchAgents")
    FileUtils.mkdir_p(launch_agents)
    FileUtils.mkdir_p(File.expand_path("~/Library/Logs/brainlayer"))
    app_path = "#{appdir}/BrainBar.app"
    domain = "gui/#{Process.uid}"

    {
      "com.brainlayer.brainbar-daemon" => "#{app_path}/Contents/MacOS/BrainBarDaemon",
      "com.brainlayer.brainbar"        => "#{app_path}/Contents/MacOS/BrainBar",
    }.each do |label, executable|
      plist_path = "#{launch_agents}/#{label}.plist"
      File.write(plist_path, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key><string>#{label}</string>
          <key>ProgramArguments</key><array><string>#{executable}</string></array>
          <key>RunAtLoad</key><true/>
          <key>KeepAlive</key><true/>
          <key>ProcessType</key><string>Interactive</string>
          <key>ThrottleInterval</key><integer>10</integer>
        </dict>
        </plist>
      XML
      system_command "/bin/launchctl", args: ["bootout", "#{domain}/#{label}"], must_succeed: false
      system_command "/bin/launchctl", args: ["bootstrap", domain, plist_path], must_succeed: false
      system_command "/bin/launchctl", args: ["kickstart", "-k", "#{domain}/#{label}"], must_succeed: false
    end
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
    The install bootstraps the com.brainlayer.brainbar-daemon LaunchAgent so the
    socket survives reinstalls. Verify with: launchctl list | grep brainbar

    If setup did not complete during cask install, run:
      brainlayer setup

    If a previous uninstall failed on a root-owned leftover (e.g. after a macOS
    account/computer rename), remove it once with sudo, then reinstall:
      sudo rm -rf /opt/homebrew/Caskroom/brainbar
      brew install --cask brainbar

    On a CLONED/RENAMED Mac, "brew upgrade --cask brainbar" may demand sudo to
    remove the old BrainBar.app even when every file is user-owned (a Homebrew
    clone heuristic). Avoid sudo by replacing the upgrade with a clean reinstall:
      mv "/Applications/BrainBar.app" ~/.Trash/ 2>/dev/null
      mv "$(brew --prefix)/Caskroom/brainbar" ~/.Trash/ 2>/dev/null
      brew install --cask brainbar
  EOS
end
