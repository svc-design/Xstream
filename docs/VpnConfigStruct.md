# VpnConfig 结构说明

1. VpnNode 类
VpnNode 类用于表示一个加速节点的数据结构。每个 VpnNode 实例代表一个加速配置节点，包含以下字段：

字段：
name：节点名称（如 "US-Node"）。
countryCode：节点所在国家的代码（如 "us"）。
configPath：配置文件路径（如 "/opt/homebrew/etc/xray-vpn-node-us.json"）。
serviceName：服务名称，macOS 为 LaunchAgent plist 名称，Linux 为 systemd 服务名，Windows 为 SC 服务名。
enabled：节点是否启用（默认 true）。

方法：
fromJson(Map<String, dynamic> json)：工厂构造函数，用于将 JSON 数据转换为 VpnNode 对象。
toJson()：将 VpnNode 对象转换为 JSON 格式。

2. VpnConfig 类
VpnConfig 类用于集中管理和操作加速配置，包括加速节点的加载、保存、更新、删除等功能。

静态变量：
_nodes：一个存储所有 VpnNode 实例的列表，用于管理加速节点。

静态方法：
2.1 _getBundleId()
从 macOS 配置文件中动态获取 PRODUCT_BUNDLE_IDENTIFIER。

返回值：String 类型，表示应用的 bundle id（默认 com.xstream）。

2.2 _getLocalConfigPath()
获取本地配置文件路径（vpn_nodes.json）的动态路径。此路径基于 PRODUCT_BUNDLE_IDENTIFIER 和 macOS 应用支持目录。

默认返回值示例：`~/Library/Application Support/xstream.svc.plus/com.xstream/vpn_nodes.json`。

返回值：String 类型，表示 vpn_nodes.json 文件的完整路径。

2.3 getConfigPath()
返回本地配置文件路径，调用 _getLocalConfigPath() 获取路径。

返回值：Future<String> 类型，表示本地配置路径。

2.4 load()
加载加速节点配置，仅读取本地文件，如不存在则返回空列表。

功能：从本地配置文件中加载节点信息。

2.5 getNodeByName(String name)
通过节点名称获取对应的 VpnNode 对象。

参数：name：节点名称。

返回值：VpnNode? 类型，表示找到的节点，若未找到则返回 null。

2.6 addNode(VpnNode node)
向节点列表中添加一个新的 VpnNode。

参数：node：需要添加的 VpnNode 对象。

2.7 removeNode(String name)
通过节点名称移除指定的 VpnNode。

参数：name：要移除的节点名称。

2.8 updateNode(VpnNode updated)
更新一个已存在的 VpnNode。

参数：updated：更新后的 VpnNode 对象。

2.9 exportToJson()
将所有的 VpnNode 对象导出为 JSON 格式的字符串。

返回值：String 类型，表示导出的 JSON 字符串。

2.10 saveToFile()
将所有的 VpnNode 数据保存到本地文件 vpn_nodes.json。

返回值：Future<String> 类型，表示保存的文件路径。

2.11 importFromJson(String jsonStr)
从给定的 JSON 字符串中导入 VpnNode 数据，并保存到本地文件。

参数：jsonStr：包含加速节点的 JSON 字符串。

2.12 deleteNodeFiles(VpnNode node)
删除与指定 VpnNode 相关的配置文件和 plist 文件。

参数：node：需要删除的 VpnNode 对象。

2.13 generateContent()
根据给定的节点信息生成配置文件，并保存到系统路径。包括生成的 plist 和 config 文件路径。

参数：

nodeName：节点名称。

domain：服务器域名。

port：端口号。

uuid：UUID。

password：sudo 密码。

bundleId：应用的 bundle ID。

platform：MethodChannel 实例，用于与原生代码交互。

setMessage：设置消息的回调函数。

logMessage：日志输出的回调函数。

3. 使用示例
获取配置文件路径：
dart
复制
编辑
final configPath = await VpnConfig.getConfigPath();
加载并管理加速节点：
dart
复制
编辑
// 加载加速节点配置
await VpnConfig.load();

// 获取某个节点
VpnNode? node = VpnConfig.getNodeByName("US-Node");

// 添加节点
VpnConfig.addNode(newNode);

// 更新节点
VpnConfig.updateNode(updatedNode);

// 删除节点文件
await VpnConfig.deleteNodeFiles(node);
生成配置文件并保存：
dart
复制
编辑
await VpnConfig.generateContent(
  nodeName: 'US-Node',
  domain: 'us.example.com',
  port: '443',
  uuid: 'uuid-1234',
  password: 'your-sudo-password',
  bundleId: 'com.xstream',
  platform: platform,
  setMessage: (message) => print(message),
  logMessage: (message) => print(message),
);
结论
合并后的 VpnConfig 类通过集中管理加速配置文件的读取、保存、更新、删除等操作，提供了统一的接口和管理方式，使得代码更加简洁、模块化。VpnNode 类专注于数据结构定义，VpnConfig 类负责对配置的管理和操作，符合单一职责原则。
