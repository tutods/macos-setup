// opencode-parity: ports the Claude Code hook surface to opencode plugins.
// Plain JS, no imports (the supacode-presence pattern): this must load even
// when node_modules/@opencode-ai/plugin is missing or version-skewed. The
// Plugin shape is duck-typed, and every hook is optional, so a future API
// change degrades to a logged warning instead of a broken startup.
//
//  - chat.message                            ~ Claude UserPromptSubmit:
//    appends the delegation reminder to every user message.
//  - experimental.chat.system.transform      ~ Claude SessionStart:
//    appends the Obsidian vault title index to the system prompt.
//
// If this plugin fails to load, check ~/.local/share/opencode/log/opencode.log
// (the old crg-plugin.ts died there on an API skew: "app.on is not a function").

const DELEGATION_REMINDER = [
  "DELEGATION ACTIVE. Main thread orchestrates, it does not read/search/edit inline",
  "unless the work is one known file. 2+ independent units = multiple task calls in",
  "ONE message. Recon -> explore. Multi-file edit -> dev-lifecycle. Diff review ->",
  "code-reviewer. Vault -> vault-search. Not for user decisions, commits/PRs, or",
  "destructive ops.",
].join(" ")

export default async () => {
  return {
    "chat.message": async (input, output) => {
      try {
        if (!output || !Array.isArray(output.parts)) return
        output.parts.push({
          type: "text",
          text: DELEGATION_REMINDER,
        })
      } catch (e) {
        console.error("opencode-parity chat.message:", e?.message ?? e)
      }
    },

    "experimental.chat.system.transform": async (input, output) => {
      try {
        if (!output || !Array.isArray(output.system)) return
        const { execFile } = await import("node:child_process")
        const { promisify } = await import("node:util")
        const run = promisify(execFile)
        const index = await run("$HOME/.claude/hooks/vault-context.sh".replace("$HOME", process.env.HOME ?? ""), { timeout: 25 })
        if (index.stdout && index.stdout.trim()) {
          output.system.push(index.stdout.trim())
        }
      } catch (e) {
        console.error("opencode-parity system.transform:", e?.message ?? e)
      }
    },
  }
}