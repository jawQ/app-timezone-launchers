//go:build windows

package main

import (
	"os/exec"
	"syscall"
)

func processRunning(names []string) bool {
	if len(names) == 0 {
		return false
	}
	// tasklist is always available on desktop Windows.
	cmd := exec.Command("tasklist", "/FO", "CSV", "/NH")
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	out, err := cmd.Output()
	if err != nil {
		return false
	}
	return tasklistHasImage(string(out), names)
}
