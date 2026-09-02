# frozen_string_literal: true

# BrainLayer formula.
class Brainlayer < Formula
  desc "Persistent memory layer and MCP tools for AI agents"
  homepage "https://github.com/EtanHey/brainlayer"
  url "https://files.pythonhosted.org/packages/71/b0/eff9cf7f22634333c08e66d72701aee1444faf9cc2d889839932b299e046/brainlayer-1.5.10.tar.gz"
  sha256 "ad65eab3741cdd0707d7869c5a83e449e3593a1ba0834e7e24f3d05fbfcb10d7"
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
    native_extensions = Dir.glob("#{venv}/**/*.{so,dylib}")
    # Keep signing and verification as separate complete sweeps.
    # rubocop:disable Style/CombinableLoops
    native_extensions.each { |path| system "codesign", "-f", "-s", "-", path }
    native_extensions.each { |path| system "codesign", "--verify", path }
    # rubocop:enable Style/CombinableLoops
    bin.install_symlink venv/"bin/brainlayer"
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
    assert_path_exists bin/"brainlayer-mcp-stdio-bridge"
  end
end
