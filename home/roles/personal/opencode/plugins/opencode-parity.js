// opencode-parity: one Claude Code hook that has no opencode config key.
// Plain JS, no imports (the supacode-presence pattern): this must load even
// when node_modules/@opencode-ai/plugin is missing or version-skewed. The
// Plugin shape is duck-typed and the hook is optional, so a future API change
// degrades to a logged warning instead of a broken startup.
//
//  - experimental.chat.system.transform      ~ Claude SessionStart:
//    appends the Obsidian vault title index to the system prompt.
//  - tool.execute.before                     ~ Claude PreToolUse:
//    rewrites bash commands through rtk when the binary is present.
//
// If this plugin fails to load, check ~/.local/share/opencode/log/opencode.log
// (the old crg-plugin.ts died there on an API skew: "app.on is not a function").

export default async () => {
  return {
    "experimental.chat.system.transform": async (input, output) => {
      try {
        if (!output || !Array.isArray(output.system)) return
        const { execFile } = await import("node:child_process")
        const { promisify } = await import("node:util")
        const run = promisify(execFile)
        // The hook reads Claude's SessionStart JSON off stdin; execFile leaves
        // that pipe open, so close it or its `cat` blocks until the timeout.
        const proc = run("$HOME/.claude/hooks/vault-context.sh".replace("$HOME", process.env.HOME ?? ""), { timeout: 25000 })
        proc.child.stdin?.end()
        const index = await proc
        if (index.stdout && index.stdout.trim()) {
          output.system.push(index.stdout.trim())
        }
      } catch (e) {
        console.error("opencode-parity system.transform:", e?.message ?? e)
      }
    },
    "tool.execute.before": async (input, output) => {
      try {
        if (input?.tool !== "bash") return
        if (!output || typeof output.args?.command !== "string") return
        const { execFile } = await import("node:child_process")
        const { promisify } = await import("node:util")
        const run = promisify(execFile)
        const which = await run("/bin/sh", ["-c", "command -v rtk"], { timeout: 3000 }).catch(() => null)
        const rtk = which?.stdout.trim()
        if (!rtk) return
        const proc = run(rtk, ["hook", "claude"], { timeout: 3000 })
        proc.child.stdin?.end(JSON.stringify({ tool_name: "Bash", tool_input: { command: output.args.command } }))
        const result = await proc
        // Empty stdout is rtk's "no rewrite for this command" signal, not an error.
        if (!result.stdout || !result.stdout.trim()) return
        const rewritten = JSON.parse(result.stdout).hookSpecificOutput?.updatedInput?.command
        if (typeof rewritten === "string") output.args.command = rewritten
      } catch (e) {
        console.error("opencode-parity tool.execute.before:", e?.message ?? e)
      }
    },
  }
}
