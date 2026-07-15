package main

import "strings"

// normalizeProcessImageName returns a lowercase tasklist image name (with .exe),
// or "" if name is empty/degenerate and must not be matched.
func normalizeProcessImageName(name string) string {
	n := strings.ToLower(strings.TrimSpace(name))
	if n == "" {
		return ""
	}
	if !strings.HasSuffix(n, ".exe") {
		n += ".exe"
	}
	// Basename was only ".exe" (or empty after trim) — never match.
	if n == ".exe" {
		return ""
	}
	return n
}

// tasklistHasImage reports whether any name appears as a tasklist CSV image name.
// tasklist /FO CSV /NH lines look like: "Feishu.exe","1234","Console","1","12,345 K"
// Matching is exact on the quoted image-name field only — no unquoted substring
// fallback (that would treat "Online.exe" as "line.exe", "myapp.exe" as "app.exe").
func tasklistHasImage(tasklistCSV string, names []string) bool {
	if tasklistCSV == "" || len(names) == 0 {
		return false
	}
	lower := strings.ToLower(tasklistCSV)
	for _, name := range names {
		n := normalizeProcessImageName(name)
		if n == "" {
			continue
		}
		if strings.Contains(lower, `"`+n+`"`) {
			return true
		}
	}
	return false
}
