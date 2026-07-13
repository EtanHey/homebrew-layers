# frozen_string_literal: true

# VoiceLayer formula.
class Voicelayer < Formula
  desc "Voice I/O layer and MCP tools for AI coding assistants"
  homepage "https://github.com/EtanHey/voicelayer"
  url "https://registry.npmjs.org/voicelayer-mcp/-/voicelayer-mcp-2.1.13.tgz"
  sha256 "3dcf750fafa47357a3b4c997104c7bae16ff82c30ee184c0bc69627bf1abbb7d"
  license "Apache-2.0"

  depends_on "bun"
  depends_on "node"
  depends_on "socat"
  depends_on "sox"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  # NOTE: intentionally NO `service do` block. Voice I/O is owned by VoiceBar.app
  # (the cask), which spawns the MCP daemon (src/mcp-server-daemon.ts) as a child
  # process so it inherits the app's microphone TCC grant. A brew service running
  # `voicelayer serve` would be a SECOND recorder (src/daemon.ts) competing for the
  # mic and the whisper-server port, and it served no MCP socket anyway (clients
  # connect via `socat UNIX-CONNECT:/tmp/voicelayer-mcp.sock`, which only the
  # VoiceBar-owned daemon serves). It also exited 127 under launchd (no PATH for
  # bun). See EtanHey/voicelayer self-living work, 2026-06.

  def caveats
    <<~EOS
      Run setup after install:
        voicelayer setup

      To connect MCP clients to the VoiceLayer daemon socket, use:
        socat STDIO UNIX-CONNECT:/tmp/voicelayer-mcp.sock

      To sync voices, vocabulary, and the VoiceLayer daemon secret from another Mac:
        voicelayer update --data-mode direct --data-source <source-host>:/Users/<source-user>
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/voicelayer --help")
    assert_path_exists bin/"voicelayer-mcp"
  end
end
