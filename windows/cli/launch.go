package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// startWithTZ starts exe with TZ set for the child only.
func startWithTZ(exe, tz string, extraArgs ...string) error {
	if strings.TrimSpace(tz) == "" {
		return fmt.Errorf("empty time zone")
	}
	cmd := exec.Command(exe, extraArgs...)
	cmd.Dir = filepath.Dir(exe)

	// Build environment: current env with TZ overridden.
	env := os.Environ()
	found := false
	for i, e := range env {
		if strings.HasPrefix(strings.ToUpper(e), "TZ=") {
			env[i] = "TZ=" + tz
			found = true
			break
		}
	}
	if !found {
		env = append(env, "TZ="+tz)
	}
	cmd.Env = env

	// Detach-ish: do not wait; inherit no console blocking if possible.
	cmd.Stdout = nil
	cmd.Stderr = nil
	cmd.Stdin = nil

	if err := cmd.Start(); err != nil {
		return err
	}

	// Brief settle; report if process exits immediately.
	done := make(chan error, 1)
	go func() {
		done <- cmd.Wait()
	}()

	select {
	case err := <-done:
		if err != nil {
			return fmt.Errorf("process exited immediately: %w", err)
		}
		// Exited 0 very quickly — still treat as suspicious for GUI apps
		// but allow (some apps hand off to another process).
		return nil
	case <-time.After(800 * time.Millisecond):
		// Still running — good for GUI apps.
		return nil
	}
}
