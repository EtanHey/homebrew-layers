class Voicelayer < Formula
  desc "Voice I/O layer and MCP tools for AI coding assistants"
  homepage "https://github.com/EtanHey/voicelayer"
  url "https://registry.npmjs.org/voicelayer-mcp/-/voicelayer-mcp-2.1.3.tgz"
  sha256 "acedc800de920fe907ae48eeac34a72e07f9c759d78de6308d13a999250901a4"
  license "Apache-2.0"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  service do
    run [opt_bin/"voicelayer", "serve"]
    keep_alive true
    log_path var/"log/voicelayer/daemon.log"
    error_log_path var/"log/voicelayer/daemon.err.log"
  end

  def caveats
    <<~EOS
      Run setup after install:
        voicelayer setup

      To connect MCP clients to the VoiceLayer daemon socket, use:
        socat STDIO UNIX-CONNECT:/tmp/voicelayer-mcp.sock
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/voicelayer --help")
    assert_path_exists bin/"voicelayer-mcp"
  end
end
