//go:build ios

package main

/*
#include <stdlib.h>
*/
import "C"
import (
    "os"
    "os/exec"
    "path/filepath"
    "sync"
    "unsafe"
)

var procMap sync.Map

//export WriteConfigFiles
func WriteConfigFiles(xrayPathC, xrayContentC, servicePathC, serviceContentC, vpnPathC, vpnContentC, passwordC *C.char) *C.char {
    xrayPath := C.GoString(xrayPathC)
    xrayContent := C.GoString(xrayContentC)
    servicePath := C.GoString(servicePathC)
    serviceContent := C.GoString(serviceContentC)
    vpnPath := C.GoString(vpnPathC)
    vpnContent := C.GoString(vpnContentC)
    if err := os.WriteFile(xrayPath, []byte(xrayContent), 0644); err != nil {
        return C.CString("error:" + err.Error())
    }
    if err := os.WriteFile(servicePath, []byte(serviceContent), 0644); err != nil {
        return C.CString("error:" + err.Error())
    }
    if err := os.WriteFile(vpnPath, []byte(vpnContent), 0644); err != nil {
        return C.CString("error:" + err.Error())
    }
    return C.CString("success")
}

//export StartNodeService
func StartNodeService(name *C.char) *C.char {
    node := C.GoString(name)
    config := filepath.Join(os.TempDir(), node+".json")
    cmd := exec.Command("xray", "run", "-c", config)
    if err := cmd.Start(); err != nil {
        return C.CString("error:" + err.Error())
    }
    procMap.Store(node, cmd)
    go cmd.Wait()
    return C.CString("success")
}

//export StopNodeService
func StopNodeService(name *C.char) *C.char {
    node := C.GoString(name)
    if v, ok := procMap.Load(node); ok {
        cmd := v.(*exec.Cmd)
        cmd.Process.Kill()
        procMap.Delete(node)
    }
    return C.CString("success")
}

//export CheckNodeStatus
func CheckNodeStatus(name *C.char) C.int {
    node := C.GoString(name)
    if v, ok := procMap.Load(node); ok {
        cmd := v.(*exec.Cmd)
        if cmd.ProcessState == nil {
            return 1
        }
    }
    return 0
}

//export CreateWindowsService
func CreateWindowsService(name, execPath, configPath *C.char) *C.char {
    return C.CString("error:not supported")
}

//export PerformAction
func PerformAction(action, password *C.char) *C.char {
    act := C.GoString(action)
    if act == "isXrayDownloading" {
        return C.CString("0")
    }
    return C.CString("error:unsupported")
}

//export IsXrayDownloading
func IsXrayDownloading() C.int { return 0 }

//export FreeCString
func FreeCString(str *C.char) { C.free(unsafe.Pointer(str)) }

func main() {}
