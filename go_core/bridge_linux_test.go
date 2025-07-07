//go:build linux

package main

import (
    "strings"
    "testing"
)

func TestRunCommand(t *testing.T) {
    out, err := runCommand("echo hello")
    if err != nil {
        t.Fatalf("runCommand error: %v", err)
    }
    if strings.TrimSpace(out) != "hello" {
        t.Fatalf("unexpected output: %q", out)
    }
}

func TestIsXrayDownloading(t *testing.T) {
    downloadMu.Lock()
    downloading = true
    downloadMu.Unlock()
    if IsXrayDownloading() != 1 {
        t.Fatal("expected downloading state")
    }
    downloadMu.Lock()
    downloading = false
    downloadMu.Unlock()
}
