# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Usage — manual, not automatic

There is **no** PreToolUse hook rewriting commands on this machine. Nothing is
intercepted for you, so nothing is saved unless you prefix commands yourself:

```bash
rtk git status        # not: git status
rtk ls src            # not: ls src
rtk cargo test        # not: cargo test
```

Prefix `rtk` on read-heavy commands whose output goes into context — git,
directory listings, greps, test runners, build output. Skip it for commands
whose output you do not read back.

Refer to CLAUDE.md for full command reference.
