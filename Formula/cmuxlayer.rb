class Cmuxlayer < Formula
  desc "Terminal multiplexer MCP server for AI agent workspace orchestration"
  homepage "https://github.com/EtanHey/cmuxlayer"
  url "https://github.com/EtanHey/cmuxlayer/archive/refs/tags/v0.2.2.tar.gz"
  sha256 "f1324ac7a77161fa1dd3366e6938056343b615bcbf420f18be10ca44f2bdd956"
  license "Apache-2.0"
  head "https://github.com/EtanHey/cmuxlayer.git", branch: "main"

  depends_on "bun" => :build
  # Runtime: the compiled MCP server runs on node (engines: node >= 20).
  depends_on "node"

  def install
    # Install deps and compile TypeScript -> dist/ with the project's toolchain.
    system "bun", "install", "--frozen-lockfile"
    system "bun", "run", "build"
    # Prune to runtime deps before vendoring node_modules into the cellar.
    system "bun", "install", "--frozen-lockfile", "--production"

    libexec.install "dist", "node_modules", "package.json"

    entries = {
      "cmuxlayer"            => "index.js",
      "cmuxlayer-app-server" => "app-server-index.js",
      "cmuxlayer-proxy"      => "proxy.js",
    }
    entries.each do |cmd, entry|
      (bin/cmd).write <<~SH
        #!/bin/bash
        exec "#{Formula["node"].opt_bin}/node" "#{libexec}/dist/#{entry}" "$@"
      SH
      chmod 0755, bin/cmd
    end
  end

  def caveats
    <<~EOS
      cmuxlayer is an MCP stdio server, normally launched by cmux / Claude Code.
      Point your MCP config command at:
        #{opt_bin}/cmuxlayer
      Pin it to a specific cmux instance (so panes never land in another app):
        CMUX_SOCKET_PATH=/path/to/cmux.sock

      Dogfood the latest main without cutting a release:
        brew install --HEAD etanhey/layers/cmuxlayer
        brew upgrade --fetch-HEAD etanhey/layers/cmuxlayer
    EOS
  end

  test do
    assert_match "cmuxlayer", shell_output("#{bin}/cmuxlayer --version")
  end
end
