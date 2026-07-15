// ZoneLaunch Windows CLI: launch an app with IANA TZ on the child process only.
// Does not change the Windows system time zone.
//
// Build (from this directory, on any OS with Go):
//
//	GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o feishu-tz.exe .
//
// The same binary can be renamed:
//
//	feishu-tz.exe   → Feishu/Lark preset
//	wechat-tz.exe   → WeChat preset
//	zonelaunch.exe  → multi-command CLI
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

const defaultTZ = "Asia/Shanghai"

func main() {
	os.Exit(run(os.Args))
}

func run(args []string) int {
	if len(args) < 1 {
		return usage(2)
	}

	base := strings.ToLower(filepath.Base(args[0]))
	base = strings.TrimSuffix(base, ".exe")

	// Named-exe mode (double-click / PATH shortcuts).
	switch {
	case base == "feishu-tz" || base == "lark-tz":
		return runPreset(presetFeishu(), args[1:])
	case base == "wechat-tz" || base == "weixin-tz":
		return runPreset(presetWeChat(), args[1:])
	case base == "slack-tz":
		return runPreset(presetSlack(), args[1:])
	case base == "line-tz":
		return runPreset(presetLINE(), args[1:])
	}

	if len(args) < 2 {
		return usage(2)
	}

	switch args[1] {
	case "-h", "--help", "help":
		return usage(0)
	case "feishu", "lark":
		return runPreset(presetFeishu(), args[2:])
	case "wechat", "weixin":
		return runPreset(presetWeChat(), args[2:])
	case "slack":
		return runPreset(presetSlack(), args[2:])
	case "line":
		return runPreset(presetLINE(), args[2:])
	case "run":
		return runGeneric(args[2:])
	case "version", "--version":
		fmt.Println("zonelaunch-windows", version)
		return 0
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n\n", args[1])
		return usage(2)
	}
}

func usage(code int) int {
	w := os.Stdout
	if code != 0 {
		w = os.Stderr
	}
	fmt.Fprint(w, `ZoneLaunch Windows CLI — inject TZ into a new process only.

Usage (multi-command binary, e.g. zonelaunch.exe):
  zonelaunch feishu
  zonelaunch wechat
  zonelaunch run --tz Asia/Shanghai --exe C:\path\to\app.exe

Named copies (same binary, different file name):
  feishu-tz.exe
  wechat-tz.exe

Environment (presets):
  LARK_TZ / WECHAT_TZ / SLACK_TZ / LINE_TZ   default Asia/Shanghai
  APP_PATH                                   full path to .exe (optional)
  TZ                                         used by "run" if --tz omitted

Flags for presets and run:
  --tz IANA          override time zone
  --exe PATH         override executable
  --force            launch even if a matching process is already running
  -h, --help         help

Notes:
  - Quit the target app first (unless --force).
  - Does not change the Windows system time zone.
  - Not every app honors POSIX TZ (Electron apps often do).
  - Platform: Windows. This binary is intended for GOOS=windows builds.

`)
	fmt.Fprintf(w, "Build host goos/goarch when compiled: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	return code
}

// Set at link time: -X main.version=0.1.0
var version = "0.1.0"
