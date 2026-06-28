class Brainlayer < Formula
  desc "Persistent memory layer and MCP tools for AI agents"
  homepage "https://github.com/EtanHey/brainlayer"
  url "https://files.pythonhosted.org/packages/45/3b/18ca3387471ff862a76142d9ef386371d12e2d3557673cb4626bd47720ca/brainlayer-1.4.1.tar.gz"
  sha256 "e83411fa729db58c8e2cd2174314206d44ca8d3af7a3a2014057cec9767365e1"
  license "Apache-2.0"

  depends_on "python"

  def install
    venv = libexec/"venv"
    python = Formula["python"].opt_bin/"python3"
    system python, "-m", "venv", venv
    system venv/"bin/python", "-m", "pip", "install", "--disable-pip-version-check", "brainlayer[cloud]==#{version}"
    bin.install_symlink venv/"bin/brainlayer"
    bin.install_symlink venv/"bin/brainlayer-mcp"
    bin.install_symlink venv/"bin/brainlayer-mcp-stdio-bridge"
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
    assert_path_exists bin/"brainlayer-mcp-stdio-bridge"
  end
end
