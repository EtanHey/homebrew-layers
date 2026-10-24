class Cmuxlayer < Formula
  desc "Terminal multiplexer MCP server for AI agent workspace orchestration"
  homepage "https://github.com/EtanHey/cmuxlayer"
  url "https://github.com/EtanHey/cmuxlayer/archive/refs/tags/v0.4.109.tar.gz"
  sha256 "c95c9875e6e6b19479dfb45f08a922bd16f608794fd91ea1ccabdfdfc4fce13f"
  license "Apache-2.0"
  head "https://github.com/EtanHey/cmuxlayer.git", branch: "main"

  depends_on "bun" => :build
  # Runtime: the compiled MCP server runs on node (engines: node >= 20).
  depends_on "node"

  depends_on "jq"

  def install
    # Install deps and compile TypeScript -> dist/ with the project's toolchain.
    system "bun", "install", "--frozen-lockfile"
    system "bun", "run", "build"
    # Prune to runtime deps before vendoring node_modules into the cellar.
    system "bun", "install", "--frozen-lockfile", "--production"

    libexec.install "dist", "node_modules", "package.json"

    # BEGIN cmux-resource-guard packaging
    system ENV.cc, "-Wall", "-Wextra", "-Werror",
           "-DGUARD_NODE=#{(formula_opt_bin("node")/"node").to_s.dump}",
           "-DGUARD_PATH=#{[formula_opt_bin("node"), formula_opt_bin("jq"), HOMEBREW_PREFIX/"bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"].join(":").dump}",
           "-DGUARD_ENTRY=#{(libexec/"dist/resource-guard.js").to_s.dump}",
           "launchd/resource-guard/cmux-resource-guard.c", "-o", "cmux-resource-guard"
    bin.install "cmux-resource-guard"
    libexec.install "launchd"
    (libexec/"scripts").install "scripts/install-mcp-reaper.sh"
    (libexec/"resource-guard-node-path").write "#{formula_opt_bin("node")}/node\n"
    # END cmux-resource-guard packaging

    entries = {
      "cmuxlayer"            => "index.js",
      "cmuxlayer-app-server" => "app-server-index.js",
      "cmuxlayer-proxy"      => "proxy.js",
    }
    entries.each do |cmd, entry|
      (bin/cmd).write <<~SH
        #!/bin/bash
        exec "#{formula_opt_bin("node")}/node" "#{libexec}/dist/#{entry}" "$@"
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
