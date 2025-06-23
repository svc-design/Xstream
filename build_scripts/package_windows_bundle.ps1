#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

# 确保目标目录存在
$releaseDir = "build/windows/x64/runner/Release"
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

# 查找并复制 dll
$source = Get-ChildItem -Recurse -Filter "libgo_native_bridge.dll" | Select-Object -First 1
if ($source) {
    Copy-Item $source.FullName -Destination $releaseDir -Force
    Write-Host "Found and copied: $($source.FullName)"
} else {
    Write-Error "Error: libgo_native_bridge.dll not found!"
    exit 1
}

# 打包
Compress-Archive -Path "$releaseDir/*" -DestinationPath "$releaseDir/xstream-windows.zip" -Force

# 简单验证打包结果
if (!(Test-Path "$releaseDir/xstream-windows.zip")) {
    Write-Error "Error: Zip package not created!"
    exit 1
}

Write-Host "Package created successfully: $releaseDir/xstream-windows.zip"
