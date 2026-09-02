# frozen_string_literal: true

# BrainLayer formula.
class Brainlayer < Formula
  desc "Persistent memory layer and MCP tools for AI agents"
  homepage "https://github.com/EtanHey/brainlayer"
  url "https://files.pythonhosted.org/packages/28/7f/246f54fe9ddd7b37a5b58a919c8b4cf4497055798561bb0f784ff8d84da9/brainlayer-1.5.11.tar.gz"
  sha256 "98d24069aed22f5a01c9389f61e6b9b046a46d70971fc7f69617e901335fe1a4"
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
    # FNM_DOTMATCH: wheels ship dylibs in dot-dirs (PIL/.dylibs), which a plain glob skips.
    native_extensions = Dir.glob("#{venv}/**/*.{so,dylib}", File::FNM_DOTMATCH)
    odie "no native extensions found under #{venv}" if native_extensions.empty?
    system "codesign", "-f", "-s", "-", *native_extensions
    system "codesign", "--verify", *native_extensions
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
