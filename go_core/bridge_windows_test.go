//go:build windows

package main

import (
    "os"
    "testing"
    "unsafe"
    "C"
)

func TestServiceExists(t *testing.T) {
    if serviceExists("DefinitelyNotAService") {
        t.Fatal("expected service to not exist")
    }
}

func TestUpdateVpnNodesConfig(t *testing.T) {
    tmpFile, err := os.CreateTemp("", "nodes-*.json")
    if err != nil {
        t.Fatal(err)
    }
    path := C.CString(tmpFile.Name())
    defer func() {
        C.free(unsafe.Pointer(path))
        os.Remove(tmpFile.Name())
    }()
    content := C.CString(`[{"name":"n","serviceName":"s","configPath":"c","enabled":true,"countryCode":"US"}]`)
    defer C.free(unsafe.Pointer(content))
    res := updateVpnNodesConfig(path, content)
    if C.GoString(res) != "success" {
        t.Fatalf("unexpected result: %s", C.GoString(res))
    }
    FreeCString(res)
}
