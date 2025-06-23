# Telemetry Server Implementation

本文档描述如何在自有服务器上部署接收匿名遥测数据的后端服务。客户端会向 `https://artifact.onwalk.net/telemetry` POST 一段 JSON 数据，包含应用版本、操作系统等基础信息。

## 数据格式

客户端发送的 JSON 结构如下：

```json
{
  "appVersion": "v1.2.3-2025-06-21-ab12cd3",
  "os": "linux",
  "osVersion": "Linux 5.15",
  "dartVersion": "3.2.0",
  "uptime": 3600
}
```

各字段含义：

- `appVersion`：构建版本号，由 CI/CD 生成
- `os`：操作系统名称，例如 `macos`、`windows`、`linux`
- `osVersion`：操作系统内核或版本描述
- `dartVersion`：运行时的 Dart 版本
- `uptime`：客户端启动至发送时经过的秒数

## Node.js 示例实现

以下示例基于 [Express](https://expressjs.com/) 和 [MongoDB](https://www.mongodb.com/) 构建，适合快速部署和收集数据。

1. 准备工作：
   ```bash
   npm init -y
   npm install express mongodb
   ```
2. 创建 `index.js`：
   ```js
   const express = require('express');
   const { MongoClient } = require('mongodb');

   const app = express();
   const uri = process.env.MONGO_URI || 'mongodb://localhost:27017';
   const client = new MongoClient(uri);

   app.use(express.json());

   app.post('/telemetry', async (req, res) => {
     try {
       const data = req.body;
       await client.db('xstream').collection('telemetry').insertOne({
         ...data,
         receivedAt: new Date(),
         ip: req.ip,
       });
       res.sendStatus(200);
     } catch (err) {
       console.error('telemetry error', err);
       res.sendStatus(500);
     }
   });

   client.connect().then(() => {
     app.listen(3000, () => console.log('Telemetry server running on 3000'));
   });
   ```
3. 运行服务：
   ```bash
   MONGO_URI="mongodb://127.0.0.1:27017" node index.js
   ```

该服务会在 `/telemetry` 路径接收 JSON 数据并写入 `xstream.telemetry` 集合，可根据需要调整存储方案或添加认证。

## 反向代理配置

将服务器部署在 `artifact.onwalk.net` 后，可通过 Nginx 反向代理至内网端口：

```nginx
server {
  listen 443 ssl;
  server_name artifact.onwalk.net;

  ssl_certificate     /path/to/fullchain.pem;
  ssl_certificate_key /path/to/privkey.pem;

  location /telemetry {
    proxy_pass http://127.0.0.1:3000/telemetry;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

## 隐私与数据保留

- 仅收集必要的系统信息，不包含任何个人可识别内容。
- 建议设置数据保留周期，定期清理旧记录。
- 如有需要，可在响应中返回匿名 `clientId` 以做区分，但需在客户端实现存储逻辑。

更多高级需求（如指标统计、可视化展示）可以结合 Elastic Stack、Prometheus 等工具进行扩展。
