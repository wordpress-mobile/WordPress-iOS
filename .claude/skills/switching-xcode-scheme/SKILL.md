---
name: switching-xcode-scheme
description: Use when you need to change the active scheme of the running Xcode app (typically before invoking the Xcode MCP BuildProject/RunSomeTests/RunAllTests tools, which always operate on Xcode's currently-selected scheme), or when you need to discover what schemes or run destinations a workspace defines. Listing-only for run destinations — Xcode 26.x's AppleScript cannot persistently change the active destination, so destination switching must be done manually in the Xcode toolbar.
---

# Switching Xcode Scheme

## Overview

The Xcode MCP tools (`BuildProject`, `RunSomeTests`, `RunAllTests`) always act on the active scheme and active destination of the focused Xcode workspace. They take no scheme or destination arguments. To build a different target or run on a different simulator, you must change Xcode's selection first.

This skill wraps an AppleScript helper that:
- **Sets the active scheme** of the workspace document Xcode currently has focused (works reliably; verified by read-after-write).
- **Lists schemes and run destinations** for that workspace, with optional substring filtering.
- **Cannot change the active run destination** — see the limitation section below.

## When to use

- Before calling Xcode MCP `BuildProject` / `RunSomeTests` / `RunAllTests` tools and the active scheme isn't the target you want.
- The user asks to "build/test/run scheme X" and you don't know whether X is currently selected.
- The user asks "what schemes are in this project?" or "what simulators can I run on?" and you want a definitive list straight from Xcode (rather than parsing project files).

## When NOT to use

- Xcode is not running, or no workspace/project is open. The script will fail with a clear message — don't use it as a way to launch Xcode.
- You need to switch the active run destination (simulator/device). AppleScript silently no-ops on Xcode 26.x. Ask the user to pick the destination in Xcode's toolbar instead.
- You're working with `xcodebuild` (CLI) rather than driving the Xcode app. `xcodebuild` takes `-scheme` and `-destination` flags directly — this skill is for the IDE, not the CLI.

## Quick reference

The helper lives at `xcode-state.sh` in this skill's directory. Run it directly via its absolute path.

| Need to do | Command |
|---|---|
| See which workspace is focused | `xcode-state.sh workspace` |
| Read the current scheme | `xcode-state.sh scheme` |
| Switch the active scheme | `xcode-state.sh scheme "WordPress"` |
| List all schemes | `xcode-state.sh schemes` |
| Find schemes matching a pattern | `xcode-state.sh schemes Jetpack` |
| List all run destinations | `xcode-state.sh destinations` |
| Find destinations matching a pattern | `xcode-state.sh destinations "iPhone 17 Pro"` |

Run with no arguments or `help` to print full usage. Exit code 1 means Xcode is not running / no workspace open / item not found; exit code 2 means usage error.

The scheme `<name>` for `scheme <name>` must match exactly (use the listing command first if unsure). Destination names already include the OS version in parens, e.g. `iPhone 17 Pro (26.4.1)`.

## The run destination limitation

Xcode's AppleScript dictionary defines `active run destination` as a settable property of the workspace document. In Xcode 26.x this property is broken in both directions:
- **Reads** always return `missing value`, even immediately after a successful set and even when Xcode visibly has a destination selected.
- **Writes** don't error, but the underlying `xcuserstate` doesn't update and there's no observable change in subsequent Xcode behavior.

UI scripting via System Events can drive Xcode's toolbar dropdown, but it requires the invoker to have Accessibility permission, which Claude Code typically doesn't have. So this skill doesn't attempt destination writes. If destination switching is essential, ask the user to change it in the Xcode toolbar before running an MCP build.

## Common mistakes

- **Forgetting that scheme set is a precondition for the Xcode MCP tools.** If you call `BuildProject` without first switching scheme, it builds whatever was selected — possibly not what the user asked for. Read the current scheme first if you're unsure.
- **Passing a substring to `scheme <name>`.** That command requires an exact match. For substring search, use `schemes <pattern>` to find the full name first.
- **Treating "set destination" as a no-op safely.** The AppleScript `set` will not error, but the destination will not change. Don't claim success based on the absence of an error.
- **Operating on the wrong workspace.** The helper always targets `active workspace document`. If the user has multiple Xcode windows open, confirm with `xcode-state.sh workspace` before switching schemes.
