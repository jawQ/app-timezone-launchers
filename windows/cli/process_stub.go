//go:build !windows

package main

// processRunning is a no-op stub so unit tests can compile on macOS/Linux.
// The released binary is GOOS=windows.
func processRunning(names []string) bool {
	_ = names
	return false
}
