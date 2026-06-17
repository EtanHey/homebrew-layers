class Brainlayer < Formula
  desc "Persistent memory layer and MCP tools for AI agents"
  homepage "https://github.com/EtanHey/brainlayer"
  url "https://files.pythonhosted.org/packages/c0/da/1633a237f63d4065b6ce475e222d530cb661bb79fad536fe63a2346aeff2/brainlayer-1.2.0.tar.gz"
  sha256 "d0263ae5f73ec3c0d53b15ee9a72431f9b22bdc61bf7e095313902ea7aaba8e7"
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
