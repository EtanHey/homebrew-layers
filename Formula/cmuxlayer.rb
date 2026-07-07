class Cmuxlayer < Formula
  desc "Terminal multiplexer MCP server for AI agent workspace orchestration"
  homepage "https://github.com/EtanHey/cmuxlayer"
  url "https://github.com/EtanHey/cmuxlayer/archive/refs/tags/v0.3.24.tar.gz"
  sha256 "68ed60aa258f000ccb0106d037fe4236eff08f3dcfb5da858dcdd6c4cb291cb5"
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
