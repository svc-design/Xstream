# 在 Windows 上通过任务计划程序运行 Xray

本文档介绍如何通过 Windows 的任务计划程序启动 Xray，相比注册服务方式，这种做法更适合仅提供 CLI 的工具。

## 准备

1. 确保 `xray.exe` 已放在 `C:\Program Files\Xstream` 目录中。
2. 准备好相应配置文件，如 `C:\Program Files\Xstream\xray-vpn-node-jp.json`。

## 创建计划任务

1. 打开 **任务计划程序**，选择 **创建基本任务**。
2. 触发器选择 **当计算机启动时**。
3. 操作选择 **启动程序**，并填写：
   - **程序或脚本**：`C:\Program Files\Xstream\xray.exe`
   - **添加参数**：`run -c "C:\Program Files\Xstream\xray-vpn-node-jp.json"`
4. 完成向导后勾选 **打开此任务的属性对话框**，在弹出的窗口中启用 **使用最高权限运行**。
5. 保存并退出后，Xray 会在下次开机时自动运行。

若需停止或删除此任务，可在任务计划程序中找到对应条目进行管理。
