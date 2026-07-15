package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestExpandEnv(t *testing.T) {
	t.Setenv("LOCALAPPDATA", `C:\Users\test\AppData\Local`)
	t.Setenv("ProgramFiles(x86)", `C:\Program Files (x86)`)

	got := expandEnv(`%LOCALAPPDATA%\Feishu\Feishu.exe`)
	want := `C:\Users\test\AppData\Local\Feishu\Feishu.exe`
	if got != want {
		t.Fatalf("got %q want %q", got, want)
	}

	got = expandEnv(`%ProgramFiles(x86)%\Tencent\WeChat\WeChat.exe`)
	want = `C:\Program Files (x86)\Tencent\WeChat\WeChat.exe`
	if got != want {
		t.Fatalf("got %q want %q", got, want)
	}
}

func TestNamedBinaryDispatch(t *testing.T) {
	dir := t.TempDir()
	fake := filepath.Join(dir, "feishu-tz.exe")
	// Force a missing APP_PATH so Windows CI does not discover/start a real Feishu install.
	t.Setenv("APP_PATH", filepath.Join(dir, "missing.exe"))
	code := run([]string{fake})
	if code != 1 {
		t.Fatalf("expected exit 1 when Feishu not installed, got %d", code)
	}
}

func TestResolveUserPathFindsExecutableInDirectory(t *testing.T) {
	dir := t.TempDir()
	exe := filepath.Join(dir, "Feishu.exe")
	if err := os.WriteFile(exe, []byte("test"), 0o600); err != nil {
		t.Fatal(err)
	}

	got := resolveUserPath(dir, []string{"Feishu.exe", "Lark.exe"})
	if got != exe {
		t.Fatalf("got %q want %q", got, exe)
	}
}

func TestSlackPresetIncludesVersionedInstallCandidate(t *testing.T) {
	found := false
	for _, candidate := range presetSlack().candidates {
		if strings.Contains(candidate, `\slack\app-*\slack.exe`) {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("Slack preset is missing versioned app-* candidate")
	}
}

func TestFirstExistingChoosesNewestWildcardMatch(t *testing.T) {
	dir := t.TempDir()
	older := filepath.Join(dir, "app-4.9.0", "slack.exe")
	newer := filepath.Join(dir, "app-4.10.0", "slack.exe")
	for _, path := range []string{older, newer} {
		if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte("test"), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	oldTime := time.Unix(1_700_000_000, 0)
	newTime := oldTime.Add(time.Hour)
	if err := os.Chtimes(older, oldTime, oldTime); err != nil {
		t.Fatal(err)
	}
	if err := os.Chtimes(newer, newTime, newTime); err != nil {
		t.Fatal(err)
	}

	got := firstExisting([]string{filepath.Join(dir, "app-*", "slack.exe")})
	if got != newer {
		t.Fatalf("got %q want newest match %q", got, newer)
	}
}

func TestUsageHelp(t *testing.T) {
	code := run([]string{"zonelaunch", "--help"})
	if code != 0 {
		t.Fatalf("help exit: %d", code)
	}
}

func TestNormalizeProcessImageName(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"LINE", "line.exe"},
		{"line.exe", "line.exe"},
		{"  Slack  ", "slack.exe"},
		{"", ""},
		{"   ", ""},
		{".exe", ""},
		{"EXE", "exe.exe"}, // unusual but not empty
	}
	for _, tc := range cases {
		if got := normalizeProcessImageName(tc.in); got != tc.want {
			t.Errorf("normalizeProcessImageName(%q)=%q want %q", tc.in, got, tc.want)
		}
	}
}

func TestParseFlagsForce(t *testing.T) {
	opts, rest, err := parseFlags([]string{"--force", "--tz", "UTC"})
	if err != nil {
		t.Fatal(err)
	}
	if !opts.force {
		t.Fatal("expected force")
	}
	if opts.tz != "UTC" {
		t.Fatalf("tz=%q", opts.tz)
	}
	if len(rest) != 0 {
		t.Fatalf("rest=%v", rest)
	}
}

func TestTasklistHasImageExactQuotedOnly(t *testing.T) {
	// Substring traps: unquoted Contains would treat Online as LINE, myapp as app.
	onlineOnly := `"Online.exe","100","Console","1","10,000 K"
"chrome.exe","200","Console","1","50,000 K"
"myapp.exe","300","Console","1","1,000 K"
`
	if tasklistHasImage(onlineOnly, []string{"line"}) {
		t.Fatal(`looking for "line" must not match Online.exe`)
	}
	if tasklistHasImage(onlineOnly, []string{"app"}) {
		t.Fatal(`looking for "app" must not match myapp.exe`)
	}

	withLINE := onlineOnly + `"LINE.exe","400","Console","1","20,000 K"
"Feishu.exe","500","Console","1","30,000 K"
`
	if !tasklistHasImage(withLINE, []string{"LINE"}) {
		t.Fatal(`looking for "LINE" must match "LINE.exe"`)
	}
	if !tasklistHasImage(withLINE, []string{"line"}) {
		t.Fatal(`match is case-insensitive`)
	}
	if !tasklistHasImage(withLINE, []string{"Feishu", "Lark"}) {
		t.Fatal(`looking for Feishu must match`)
	}
	if tasklistHasImage(withLINE, []string{"Lark"}) {
		t.Fatal(`Lark alone must not match Feishu`)
	}
	if tasklistHasImage(withLINE, []string{""}) {
		t.Fatal(`empty name must never match`)
	}
	if tasklistHasImage(withLINE, []string{".exe"}) {
		t.Fatal(`degenerate ".exe" name must never match`)
	}
	if tasklistHasImage("", []string{"LINE"}) {
		t.Fatal(`empty tasklist must not match`)
	}
	if tasklistHasImage(withLINE, nil) {
		t.Fatal(`nil names must not match`)
	}

	// Unquoted occurrence of the basename elsewhere must not count.
	bad := `Session line.exe data without quotes around image field
"other.exe","1","Console","1","1 K"
`
	if tasklistHasImage(bad, []string{"line"}) {
		t.Fatal(`unquoted substring must not match`)
	}
}
