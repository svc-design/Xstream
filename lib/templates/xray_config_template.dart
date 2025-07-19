// lib/templates/xray_config_template.dart

const String defaultXrayJsonTemplate = r'''
{
  "log": {
    "loglevel": "info"
  },
  "dns": {
    "servers": [
      {
        "address": "https://1.1.1.1/dns-query",
        "queryStrategy": "UseIPv4"
      },
      {
        "tag": "localDnsQuery",
        "address": "223.5.5.5",
        "domains": [
          "geosite:PRIVATE",
          "geosite:CN"
        ],
        "queryStrategy": "UseIPv4"
      }
    ],
    "queryStrategy": "UseIPv4",
    "disableFallbackIfMatch": true,
    "tag": "dnsQuery"
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "domainMatcher": "hybrid",
    "rules": [
      {
        "domainMatcher": "hybrid",
        "inboundTag": [
          "dnsQuery"
        ],
        "outboundTag": "proxy",
        "ruleTag": "dnsQuery"
      },
      {
        "domainMatcher": "hybrid",
        "port": "53",
        "inboundTag": [
          "socksIn"
        ],
        "outboundTag": "dnsOut",
        "ruleTag": "dnsOut"
      },
      {
        "domainMatcher": "hybrid",
        "inboundTag": [
          "localDnsQuery"
        ],
        "outboundTag": "direct",
        "ruleTag": "custom"
      }
    ]
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "listen": "127.0.0.1",
      "port": 1081,
      "protocol": "http",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "<SERVER_DOMAIN>",
            "port": <PORT>,
            "users": [
              {
                "id": "<UUID>",
                "encryption": "none",
                "flow": "xtls-rprx-vision"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "serverName": "<SERVER_DOMAIN>",
          "allowInsecure": false,
          "fingerprint": "chrome"
        }
      },
      "tag": "proxy"
    },
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    },
    {
      "protocol": "dns",
      "settings": {
        "nonIPQuery": "skip"
      },
      "tag": "dnsOut",
      "streamSettings": {
        "sockopt": {
          "dialerProxy": "proxy"
        }
      }
    }
  ]
}
''';
