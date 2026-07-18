class Brainlayer < Formula
  desc "Persistent memory layer and MCP tools for AI agents"
  homepage "https://github.com/EtanHey/brainlayer"
  url "https://files.pythonhosted.org/packages/c1/36/8377e7999638f356f600bb98fca627b242c60e428fd47572af598f4edd22/brainlayer-1.4.5.tar.gz"
  sha256 "8f2ec237fab287dc5f6d674581f44dca8e0f8d3602182b1ea0ff9bfd6fca305e"
  license "Apache-2.0"

  depends_on "rust" => :build
  depends_on "python@3.13"

  def install
    venv = libexec/"venv"
    python = Formula["python@3.13"].opt_bin/"python3.13"
    no_binary = "cbor2,orjson,pydantic-core,rpds-py,safetensors,tokenizers"
    ENV.append "RUSTFLAGS", "-C link-arg=-undefined -C link-arg=dynamic_lookup " \
                            "-C link-arg=-Wl,-headerpad_max_install_names"
    system python, "-m", "venv", venv
    system venv/"bin/python", "-m", "pip", "install", "--disable-pip-version-check", "--no-binary=#{no_binary}",
           "brainlayer[cloud]==#{version}"
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
