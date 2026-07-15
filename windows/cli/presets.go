package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type preset struct {
	displayName  string
	tzEnvKey     string
	processNames []string // without .exe; matched case-insensitively
	candidates   []string // may contain %ENV% or $env: style — we expand %VAR%
	exeNames     []string // if APP_PATH is a directory
}

func presetFeishu() preset {
	return preset{
		displayName:  "Feishu/Lark",
		tzEnvKey:     "LARK_TZ",
		processNames: []string{"Feishu", "Lark", "LarkShell"},
		candidates: []string{
			`%LOCALAPPDATA%\Feishu\Feishu.exe`,
			`%LOCALAPPDATA%\Lark\Lark.exe`,
			`%LOCALAPPDATA%\Bytedance\Feishu\Feishu.exe`,
			`%LOCALAPPDATA%\LarkShell\Lark.exe`,
			`%ProgramFiles%\Feishu\Feishu.exe`,
			`%ProgramFiles%\Lark\Lark.exe`,
			`%ProgramFiles(x86)%\Feishu\Feishu.exe`,
			`%ProgramFiles(x86)%\Lark\Lark.exe`,
		},
		exeNames: []string{"Feishu.exe", "Lark.exe"},
	}
}

func presetWeChat() preset {
	return preset{
		displayName:  "WeChat",
		tzEnvKey:     "WECHAT_TZ",
		processNames: []string{"WeChat", "Weixin", "WeChatAppEx"},
		candidates: []string{
			`%ProgramFiles%\Tencent\WeChat\WeChat.exe`,
			`%ProgramFiles(x86)%\Tencent\WeChat\WeChat.exe`,
			`%LOCALAPPDATA%\Tencent\WeChat\WeChat.exe`,
			`%ProgramFiles%\Tencent\Weixin\Weixin.exe`,
			`%ProgramFiles(x86)%\Tencent\Weixin\Weixin.exe`,
			`%LOCALAPPDATA%\Tencent\Weixin\Weixin.exe`,
		},
		exeNames: []string{"WeChat.exe", "Weixin.exe"},
	}
}

func presetSlack() preset {
	return preset{
		displayName:  "Slack",
		tzEnvKey:     "SLACK_TZ",
		processNames: []string{"slack"},
		candidates: []string{
			`%LOCALAPPDATA%\slack\slack.exe`,
			`%LOCALAPPDATA%\slack\app-*\slack.exe`,
		},
		exeNames: []string{"slack.exe"},
	}
}

func presetLINE() preset {
	return preset{
		displayName:  "LINE",
		tzEnvKey:     "LINE_TZ",
		processNames: []string{"LINE", "LineLauncher"},
		candidates: []string{
			`%LOCALAPPDATA%\LINE\bin\LineLauncher.exe`,
			`%LOCALAPPDATA%\LINE\bin\LINE.exe`,
			`%ProgramFiles%\LINE\bin\LineLauncher.exe`,
			`%ProgramFiles(x86)%\LINE\bin\LineLauncher.exe`,
		},
		exeNames: []string{"LineLauncher.exe", "LINE.exe"},
	}
}

type launchOpts struct {
	tz    string
	exe   string
	force bool
}

func parseFlags(args []string) (launchOpts, []string, error) {
	opts := launchOpts{}
	var rest []string
	for i := 0; i < len(args); i++ {
		a := args[i]
		switch {
		case a == "--force":
			opts.force = true
		case a == "--tz" && i+1 < len(args):
			i++
			opts.tz = args[i]
		case strings.HasPrefix(a, "--tz="):
			opts.tz = strings.TrimPrefix(a, "--tz=")
		case a == "--exe" && i+1 < len(args):
			i++
			opts.exe = args[i]
		case strings.HasPrefix(a, "--exe="):
			opts.exe = strings.TrimPrefix(a, "--exe=")
		case a == "-h" || a == "--help":
			return opts, nil, errHelp
		case strings.HasPrefix(a, "-"):
			return opts, nil, fmt.Errorf("unknown flag: %s", a)
		default:
			rest = append(rest, a)
		}
	}
	return opts, rest, nil
}

var errHelp = fmt.Errorf("help")

func runPreset(p preset, args []string) int {
	opts, _, err := parseFlags(args)
	if err == errHelp {
		return usage(0)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 2
	}

	tz := opts.tz
	if tz == "" {
		tz = strings.TrimSpace(os.Getenv(p.tzEnvKey))
	}
	if tz == "" {
		tz = defaultTZ
	}

	exe := opts.exe
	if exe == "" {
		exe = strings.TrimSpace(os.Getenv("APP_PATH"))
	}
	if exe == "" {
		exe = firstExisting(p.candidates)
	} else {
		exe = resolveUserPath(exe, p.exeNames)
	}

	if exe == "" || !fileExists(exe) {
		fmt.Fprintf(os.Stderr, "Executable not found for %s.\n", p.displayName)
		fmt.Fprintf(os.Stderr, "Set APP_PATH or pass --exe to the full path of the .exe.\n")
		return 1
	}

	if !opts.force && processRunning(p.processNames) {
		fmt.Printf("%s is already running.\n", p.displayName)
		fmt.Printf("Quit %s completely before running this command, otherwise the existing process will not pick up the new TZ value.\n", p.displayName)
		fmt.Println("Or pass --force to launch anyway.")
		return 2
	}

	if err := startWithTZ(exe, tz); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start %s: %v\n", p.displayName, err)
		return 3
	}

	fmt.Printf("Started %s with TZ=%s\n  %s\n", p.displayName, tz, exe)
	return 0
}

func runGeneric(args []string) int {
	opts, rest, err := parseFlags(args)
	if err == errHelp {
		return usage(0)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 2
	}

	tz := opts.tz
	if tz == "" {
		tz = strings.TrimSpace(os.Getenv("TZ"))
	}
	if tz == "" {
		tz = defaultTZ
	}

	exe := opts.exe
	if exe == "" && len(rest) > 0 {
		exe = rest[0]
		rest = rest[1:]
	}
	if exe == "" {
		exe = strings.TrimSpace(os.Getenv("APP_PATH"))
	}
	if exe == "" {
		fmt.Fprintln(os.Stderr, "run requires --exe PATH (or APP_PATH).")
		return 1
	}
	exe = expandEnv(exe)
	if !fileExists(exe) {
		fmt.Fprintf(os.Stderr, "Executable not found: %s\n", exe)
		return 1
	}

	// Optional process name from basename for running check.
	// Skip when basename is empty/degenerate (e.g. path ends with ".exe" only).
	base := strings.TrimSuffix(filepath.Base(exe), filepath.Ext(exe))
	if !opts.force && base != "" && processRunning([]string{base}) {
		fmt.Printf("%s is already running. Quit it first, or pass --force.\n", base)
		return 2
	}

	if err := startWithTZ(exe, tz, rest...); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start: %v\n", err)
		return 3
	}
	fmt.Printf("Started with TZ=%s\n  %s\n", tz, exe)
	return 0
}

func firstExisting(candidates []string) string {
	for _, c := range candidates {
		p := expandEnv(c)
		if fileExists(p) {
			return p
		}
		// Slack-style versioned dirs: %LOCALAPPDATA%\slack\app-*\slack.exe
		if strings.Contains(p, "*") {
			matches, _ := filepath.Glob(p)
			var newestMatch string
			var newestModTime time.Time
			for _, m := range matches {
				st, err := os.Stat(m)
				if err != nil || st.IsDir() {
					continue
				}
				if newestMatch == "" || st.ModTime().After(newestModTime) ||
					(st.ModTime().Equal(newestModTime) && m > newestMatch) {
					newestMatch = m
					newestModTime = st.ModTime()
				}
			}
			if newestMatch != "" {
				return newestMatch
			}
		}
	}
	return ""
}

func resolveUserPath(path string, exeNames []string) string {
	path = expandEnv(path)
	st, err := os.Stat(path)
	if err != nil || !st.IsDir() {
		return path
	}
	for _, name := range exeNames {
		c := filepath.Join(path, name)
		if fileExists(c) {
			return c
		}
	}
	return path
}

// expandEnv expands Windows-style %VAR% placeholders (including ProgramFiles(x86)).
func expandEnv(s string) string {
	out := s
	for {
		start := strings.Index(out, "%")
		if start < 0 {
			break
		}
		end := strings.Index(out[start+1:], "%")
		if end < 0 {
			break
		}
		end = start + 1 + end
		name := out[start+1 : end]
		val := os.Getenv(name)
		out = out[:start] + val + out[end+1:]
	}
	return out
}

func fileExists(path string) bool {
	if path == "" {
		return false
	}
	st, err := os.Stat(path)
	return err == nil && !st.IsDir()
}
