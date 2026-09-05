# frozen_string_literal: true

# BrainLayer formula.
class Brainlayer < Formula
  desc "Persistent memory layer and MCP tools for AI agents"
  homepage "https://github.com/EtanHey/brainlayer"
  url "https://files.pythonhosted.org/packages/4d/68/4eb054dc76a272c41b49f11ad0ae7d36f29be522f104272002bd4eb010d9/brainlayer-1.5.14.tar.gz"
  sha256 "1f28b81a62bf074e803f4d4eb81151eb98f89104ba552fe93aac7a672040f7cd"
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
    bin.install_symlink venv/"bin/brainlayer-mcp-stdio-bridge"
  end

  # Sweep AFTER relocation, not during `install`.
  #
  # `FormulaInstaller#finish` runs `fix_dynamic_linkage` (formula_installer.rb:1014)
  # before `post_install` (formula_installer.rb:1031), so an `install`-time sweep is
  # always upstream of relocation and cannot be the last word on signatures.
  #
  # On this keg relocation also aborts partway: `change_dylib_id` on
  # `cramjam.cpython-313-darwin.so` raises `MachO::HeaderPadError` and
  # extend/os/mac/keg.rb:56 re-raises it out of the `mach_o_files.each` loop in
  # extend/os/mac/keg_relocate.rb:81-125. `codesign_patched_binaries`
  # (keg_relocate.rb:129) sits after that loop, so it never runs, and every file
  # already rewritten by `file.save_changes` (keg_relocate.rb:122) keeps a stale
  # signature: `invalid signature (code or signature have been modified)`. That is
  # 1.5.11 on an M4 Max — 442 files signed during `install`, 20 invalid afterwards.
  # `FormulaInstaller` only `ofail`s that (formula_installer.rb:1391-1393), which
  # just sets a flag (utils/output.rb:122-125), so `finish` continues and
  # `post_install` still runs. Signing last is therefore both necessary and
  # sufficient.
  #
  # Idempotent by construction (`brew postinstall brainlayer` re-runs it) and
  # fail-closed: empty glob is fatal, and `--verify` raises on any invalid file.
  def post_install
    venv = libexec/"venv"
    # FNM_DOTMATCH: wheels ship dylibs in dot-dirs (PIL/.dylibs), which a plain glob skips.
    native_extensions = Dir.glob("#{venv}/**/*.{so,dylib}", File::FNM_DOTMATCH)
    odie "no native extensions found under #{venv}" if native_extensions.empty?
    system "codesign", "-f", "-s", "-", *native_extensions
    system "codesign", "--verify", *native_extensions
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
