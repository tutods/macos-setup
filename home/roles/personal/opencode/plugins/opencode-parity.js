// opencode-parity: one Claude Code hook that has no opencode config key.
// Plain JS, no imports (the supacode-presence pattern): this must load even
// when node_modules/@opencode-ai/plugin is missing or version-skewed. The
// Plugin shape is duck-typed and the hook is optional, so a future API change
// degrades to a logged warning instead of a broken startup.
//
//  - tool.execute.before                     ~ Claude PreToolUse:
//    runs bash commands through the same block-ai-attribution.sh Claude uses
//    (deny → throw, so opencode blocks the call; every failure path allows),
//    then rewrites them through rtk when the binary is present.
//  - config                                  ~ project-local skill bridge:
//    registers .claude/settings.json skills entries into skills.paths.
//
// If this plugin fails to load, check ~/.local/share/opencode/log/opencode.log
// (the old crg-plugin.ts died there on an API skew: "app.on is not a function").

export default async () => {
  const hookPath = (name) => `${process.env.HOME ?? ""}/.claude/hooks/${name}`

  return {
    "tool.execute.before": async (input, output) => {
      if (input?.tool !== "bash") return
      if (!output || typeof output.args?.command !== "string") return

      // ~ Claude PreToolUse block-ai-attribution.sh: the SAME deployed script
      // (home/common/ai/settings.nix's home.file entry), fed the same
      // PreToolUse JSON on stdin. The script owns every regex — which
      // commands are candidates (git commit / gh pr / gh api) and what counts
      // as attribution — nothing is duplicated here; the crude git/gh
      // substring test only skips the spawn for commands the script would
      // ignore anyway. Deny contract: on a hit the script prints
      // {"hookSpecificOutput":{"permissionDecision":"deny",
      // "permissionDecisionReason":...}} and exits 0; empty stdout is allow.
      // Fail open: script missing/unreadable/error/bad JSON → allow.
      let denyReason
      if (/\b(git|gh)\b/.test(output.args.command)) {
        try {
          const { execFile } = await import("node:child_process")
          const { promisify } = await import("node:util")
          const run = promisify(execFile)
          const proc = run(hookPath("block-ai-attribution.sh"), { timeout: 10000 })
          proc.child.stdin?.end(JSON.stringify({ tool_name: "Bash", tool_input: { command: output.args.command } }))
          const result = await proc
          if (result.stdout && result.stdout.trim()) {
            const decision = JSON.parse(result.stdout).hookSpecificOutput
            if (decision?.permissionDecision === "deny") {
              denyReason = decision.permissionDecisionReason || "Blocked by block-ai-attribution.sh"
            }
          }
        } catch (e) {
          console.error("opencode-parity attribution guard:", e?.message ?? e)
        }
      }
      // Thrown outside the try/catch above: the catch is the fail-open path
      // for script failures and must never swallow the deny itself.
      if (denyReason) throw new Error(denyReason)

      try {
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
    // Project-local skill bridge, ~ Claude reading a project's settings. The
    // `event` hook gets no mutable output, so this rides the `config` hook,
    // which receives the loaded Config to mutate in place: each skills entry
    // from the project's .claude/settings.json[.local] is appended to
    // skills.paths. Entries point at a single skill dir (SKILL.md at its
    // root); the skills.paths scan glob is "**/SKILL.md", which matches at
    // depth zero, so a direct skill-dir path registers that one skill.
    config: async (config) => {
      try {
        if (!config || typeof config !== "object") return
        const { readFile } = await import("node:fs/promises")
        const { join } = await import("node:path")
        const { cwd } = await import("node:process")
        const files = [join(cwd(), ".claude/settings.json"), join(cwd(), ".claude/settings.local.json")]
        for (const file of files) {
          try {
            const settings = JSON.parse(await readFile(file, "utf8"))
            if (!settings?.skills || typeof settings.skills !== "object") continue
            config.skills ??= {}
            config.skills.paths ??= []
            for (const skillPath of Object.values(settings.skills)) {
              if (typeof skillPath !== "string") continue
              if (!config.skills.paths.includes(skillPath)) config.skills.paths.push(skillPath)
            }
          } catch {}
        }
      } catch (e) {
        console.error("opencode-parity config skills bridge:", e?.message ?? e)
      }
    },
  }
}
