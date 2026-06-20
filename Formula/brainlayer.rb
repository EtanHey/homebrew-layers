class Brainlayer < Formula
  desc "Persistent memory layer and MCP tools for AI agents"
  homepage "https://github.com/EtanHey/brainlayer"
  url "https://files.pythonhosted.org/packages/1d/ae/b20e3dc5f2c3de05fa77171b38a1fb90d9d28769b3146b6dfe3e515485d6/brainlayer-1.3.0.tar.gz"
  sha256 "2aad76603a99c8c76c8b68964f468d0cd1c57923928d8efeaa37179a66d0c460"
  license "Apache-2.0"

  depends_on "python"

  def install
    venv = libexec/"venv"
    python = Formula["python"].opt_bin/"python3"
    system python, "-m", "venv", venv
    system venv/"bin/python", "-m", "pip", "install", "--disable-pip-version-check", "brainlayer==#{version}"
    bin.install_symlink venv/"bin/brainlayer"
    bin.install_symlink venv/"bin/brainlayer-mcp"
  end

  service do
    run [opt_bin/"brainlayer", "watch"]
    keep_alive true
    log_path var/"log/brainlayer/watch.log"
    error_log_path var/"log/brainlayer/watch.err.log"
    environment_variables BRAINLAYER_SYSTEM_ENABLED: "1"
  end

  def caveats
    <<~EOS
      Run setup after install:
        brainlayer setup

      To install the full packaged LaunchAgent set:
        brainlayer setup --launchd
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/brainlayer --help")
    assert_path_exists bin/"brainlayer-mcp"
  end
end
