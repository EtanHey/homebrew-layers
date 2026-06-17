class Brainlayer < Formula
  desc "Persistent memory layer and MCP tools for AI agents"
  homepage "https://github.com/EtanHey/brainlayer"
  url "https://files.pythonhosted.org/packages/3d/e7/0ab16efa00f40c0a0b5b7212c96806891a2e93eac0c44d20b432652ccf90/brainlayer-1.1.0.tar.gz"
  sha256 "279fbb02d2af978d231cf425e5ad826f2d54a921df41b3b0431d93f432c4f22b"
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
