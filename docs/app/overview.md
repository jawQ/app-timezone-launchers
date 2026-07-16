# ZoneLaunch app overview

[Simplified Chinese](overview.zh-CN.md)

ZoneLaunch is an optional **GUI** for the same idea as the shell launchers: start a macOS app with a chosen `TZ`, independent of the system time zone.

**Why it exists:** AI tools such as Claude and ChatGPT often require a supported regional time zone, but changing the system zone shifts WeChat, Feishu/Lark, and other office or social apps too. ZoneLaunch (and the shell tools) let you set a time zone per app so AI software and everything else can coexist without conflict (or the reverse).

## When to use scripts vs the app

| | Shell launchers | ZoneLaunch.app |
| --- | --- | --- |
| Best for | A few fixed apps (Feishu, WeChat, …) | Many apps, drag-and-drop, time-zone groups |
| Weight | A few KB of shell | A normal macOS `.app` |
| Install | `./install.sh` | [Download a Release](install-from-release.md) or [build from source](build-from-source.md) |
| Needs | Terminal + `PATH` | macOS 14+ |

**Most people only need the scripts.** Use ZoneLaunch when you want a nicer UI, arbitrary apps, or multiple time-zone groups.

Both approaches inject `TZ` into the **new** process only. They can be installed side by side.

## What the app does

- Drag `.app` bundles into a time-zone group
- Create / rename / delete groups (IANA time zones)
- Launch with one click
- Put the same app in several groups when you need different zones
- Show a blue toolbar button for signed in-app updates, then restart automatically after installation

## Limits (same as scripts)

- Quit the target app first; already-running processes keep their old `TZ`
- Some app screens still follow account, server, or device settings
- Does not change macOS system time or other apps

## Get the app

1. **Preferred:** [Install from GitHub Releases](install-from-release.md) (ad-hoc signed zip, no paid Apple Developer account). **First open is blocked by Gatekeeper until you click Open Anyway** — see that page.
2. **Developers:** [Build from source](build-from-source.md)

## Identity

Every official build uses Bundle ID **`app.zonelaunch.launcher`**. Do not invent a personal Bundle ID if you redistribute builds from this repo.
