//go:build windows

package main

import "C"
import (
	"archive/zip"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
)

var downloadMu sync.Mutex
var downloading bool

func serviceExists(name string) bool {
	out, _ := exec.Command("sc", "query", name).CombinedOutput()
	return strings.Contains(string(out), "SERVICE_NAME")
}

func cStringOrError(err error) *C.char {
	if err != nil {
		return C.CString("error:" + err.Error())
	}
	return C.CString("success")
}

//export WriteConfigFiles
func WriteConfigFiles(xrayPath, xrayContent, servicePath, serviceContent, vpnPath, vpnContent, password *C.char) *C.char {
	if res := writeConfigFile(xrayPath, xrayContent); res != nil {
		return res
	}
	if res := writeConfigFile(servicePath, serviceContent); res != nil {
		return res
	}
	return updateVpnNodesConfig(vpnPath, vpnContent)
}

func writeConfigFile(pathC, contentC *C.char) *C.char {
	p := C.GoString(pathC)
	c := C.GoString(contentC)
	if err := os.MkdirAll(filepath.Dir(p), 0755); err != nil {
		return C.CString("error:" + err.Error())
	}
	if err := os.WriteFile(p, []byte(c), 0644); err != nil {
		return C.CString("error:" + err.Error())
	}
	return nil
}

func updateVpnNodesConfig(pathC, contentC *C.char) *C.char {
	p := C.GoString(pathC)
	c := C.GoString(contentC)
	if err := os.MkdirAll(filepath.Dir(p), 0755); err != nil {
		return C.CString("error:" + err.Error())
	}
	var nodes []map[string]interface{}
	if data, err := os.ReadFile(p); err == nil {
		json.Unmarshal(data, &nodes)
	}
	var newNodes []map[string]interface{}
	if err := json.Unmarshal([]byte(c), &newNodes); err != nil {
		return C.CString("error:" + err.Error())
	}
	nodes = append(nodes, newNodes...)
	out, err := json.MarshalIndent(nodes, "", "  ")
	if err != nil {
		return C.CString("error:" + err.Error())
	}
	if err := os.WriteFile(p, out, 0644); err != nil {
		return C.CString("error:" + err.Error())
	}
	return C.CString("success")
}

func downloadAndExtractXray(destDir string) error {
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return err
	}
	resp, err := http.Get("https://artifact.onwalk.net/xray-core/v25.3.6/Xray-windows-64.zip")
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	tmp, err := os.CreateTemp("", "xray-*.zip")
	if err != nil {
		return err
	}
	if _, err := io.Copy(tmp, resp.Body); err != nil {
		tmp.Close()
		os.Remove(tmp.Name())
		return err
	}
	tmp.Close()
	defer os.Remove(tmp.Name())
	zr, err := zip.OpenReader(tmp.Name())
	if err != nil {
		return err
	}
	defer zr.Close()
	var xrayFile *zip.File
	for _, f := range zr.File {
		name := strings.ToLower(filepath.Base(f.Name))
		if name == "xray.exe" {
			xrayFile = f
			break
		}
	}
	if xrayFile == nil {
		return errors.New("xray.exe not found")
	}
	rc, err := xrayFile.Open()
	if err != nil {
		return err
	}
	defer rc.Close()
	out, err := os.Create(filepath.Join(destDir, "xray.exe"))
	if err != nil {
		return err
	}
	defer out.Close()
	if _, err := io.Copy(out, rc); err != nil {
		return err
	}
	return nil
}

//export CreateWindowsService
func CreateWindowsService(nameC, execC, configC *C.char) *C.char {
	name := C.GoString(nameC)
	execPath := C.GoString(execC)
	cfg := C.GoString(configC)

	if serviceExists(name) {
		return C.CString("success")
	}

	binPath := fmt.Sprintf("\"%s\" run -c \"%s\"", execPath, cfg)
	out, err := exec.Command("sc", "create", name, "binPath=", binPath, "start=", "auto").CombinedOutput()
	if err != nil {
		return C.CString("error:" + string(out))
	}
	return C.CString("success")
}

//export StartNodeService
func StartNodeService(name *C.char) *C.char {
	serviceName := C.GoString(name)
	programDir := filepath.Join(os.Getenv("ProgramFiles"), "Xstream")
	xrayPath := filepath.Join(programDir, "xray.exe")
	targetConfig := filepath.Join(programDir, serviceName+".json")
	configJson := filepath.Join(programDir, "config.json")

	// 强制复制 config.json ← service-specific json
	input, err := os.ReadFile(targetConfig)
	if err != nil {
		return C.CString("error: read "+targetConfig+" failed: " + err.Error())
	}
	if err := os.WriteFile(configJson, input, 0644); err != nil {
		return C.CString("error: write config.json failed: " + err.Error())
	}

	// 后台运行 xray.exe run -c config.json
	cmd := exec.Command(xrayPath, "run", "-c", configJson)
	cmd.SysProcAttr = &syscall.SysProcAttr{
		HideWindow:    true, // 避免弹出窗口
		CreationFlags: syscall.CREATE_NEW_PROCESS_GROUP,
	}
	if err := cmd.Start(); err != nil {
		return C.CString("error: xray start failed: " + err.Error())
	}

	// 成功启动
	processMap.Store(serviceName, cmd)
	return C.CString("success")
}

//export StopNodeService
func StopNodeService(name *C.char) *C.char {
	serviceName := C.GoString(name)

	// 精准结束进程
	if val, ok := processMap.Load(serviceName); ok {
		if cmd, ok := val.(*exec.Cmd); ok && cmd.Process != nil {
			if err := cmd.Process.Kill(); err != nil {
				return C.CString("error: kill failed: " + err.Error())
			}
			processMap.Delete(serviceName)
			return C.CString("success")
		}
	}

	// 兜底杀掉全部 xray.exe
	exec.Command("taskkill", "/F", "/IM", "xray.exe").Run()
	return C.CString("success")
}

//export CheckNodeStatus
func CheckNodeStatus(name *C.char) C.int {
	out, err := exec.Command("sc", "query", C.GoString(name)).Output()
	if err != nil {
		return -1
	}
	if strings.Contains(string(out), "RUNNING") {
		return 1
	}
	return 0
}

//export PerformAction
func PerformAction(action, password *C.char) *C.char {
	switch C.GoString(action) {
	case "initXray":
		return InitXray()
	case "updateXrayCore":
		return UpdateXrayCore()
	case "isXrayDownloading":
		if IsXrayDownloading() == 1 {
			return C.CString("1")
		}
		return C.CString("0")
	case "resetXrayAndConfig":
		return ResetXrayAndConfig(password)
	default:
		return C.CString("error:unknown action")
	}
}

//export InitXray
func InitXray() *C.char {
	destDir := filepath.Join(os.Getenv("ProgramFiles"), "Xstream")
	dest := filepath.Join(destDir, "xray.exe")
	if _, err := os.Stat(dest); err == nil {
		return C.CString("success")
	}

	downloadMu.Lock()
	defer downloadMu.Unlock()
	if downloading {
		return C.CString("info:downloading in background")
	}
	downloading = true
	go func() {
		defer func() {
			downloadMu.Lock()
			downloading = false
			downloadMu.Unlock()
		}()
		if err := downloadAndExtractXray(destDir); err != nil {
			fmt.Println("Download failed:", err)
		}
	}()
	return C.CString("info:download started")
}

//export UpdateXrayCore
func UpdateXrayCore() *C.char {
	destDir := filepath.Join(os.Getenv("ProgramFiles"), "Xstream")
	downloadMu.Lock()
	defer downloadMu.Unlock()
	if downloading {
		return C.CString("info:downloading in background")
	}
	downloading = true
	go func() {
		defer func() {
			downloadMu.Lock()
			downloading = false
			downloadMu.Unlock()
		}()
		if err := downloadAndExtractXray(destDir); err != nil {
			fmt.Println("Download failed:", err)
		}
	}()
	return C.CString("info:download started")
}

//export IsXrayDownloading
func IsXrayDownloading() C.int {
	downloadMu.Lock()
	d := downloading
	downloadMu.Unlock()
	if d {
		return 1
	}
	return 0
}

//export ResetXrayAndConfig
func ResetXrayAndConfig(password *C.char) *C.char {
	dir := filepath.Join(os.Getenv("ProgramFiles"), "Xstream")
	os.RemoveAll(dir)
	exec.Command("sc", "delete", "xray-node-jp").Run()
	exec.Command("sc", "delete", "xray-node-ca").Run()
	exec.Command("sc", "delete", "xray-node-us").Run()
	return C.CString("success")
}
