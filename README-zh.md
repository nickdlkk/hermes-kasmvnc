# Hermes Agent + KasmVNC 一键部署

基于 [ddong8/openclaw-kasmvnc](https://github.com/ddong8/openclaw-kasmvnc) fork 改造，将 OpenClaw 替换为 Hermes Agent。

## 功能

- **Hermes Gateway** — 消息网关，支持飞书、Telegram、Discord 等平台
- **KasmVNC** — 浏览器内 VNC 桌面，无需安装客户端
- **XFCE4** — 轻量级 Linux 桌面环境
- **Chromium** — 浏览器，支持远程调试
- **Fcitx5 + 雾凇拼音** — 中文输入法

## 快速开始

```bash
# 安装（自动构建镜像 + 启动容器）
./hermes-kasmvnc-zh.sh install

# 状态
./hermes-kasmvnc-zh.sh status

# 日志
./hermes-kasmvnc-zh.sh logs --tail 100

# 升级（容器内热升级，不中断 VNC 会话）
./hermes-kasmvnc-zh.sh upgrade

# 卸载
./hermes-kasmvnc-zh.sh uninstall
```

## 端口

| 服务 | 宿主机端口 | 说明 |
|------|-----------|------|
| Hermes Gateway | `18642` | API Server |
| Hermes Webhook | `18643` | Webhook 回调 |
| KasmVNC HTTPS | `8443` | VNC 桌面访问 |
| KasmVNC WS | `8444` | VNC WebSocket |

## 环境变量

```bash
HERMES_GATEWAY_PORT=18642     # Gateway 宿主机端口
HERMES_KASMVNC_HTTPS_PORT=8443 # VNC HTTPS 端口
HERMES_DATA_DIR=./hermes-data  # 数据目录（挂载到容器 /home/node）
HERMES_HTTP_PROXY=             # 容器内 HTTP 代理
HERMES_ENABLE_GPU=0            # 启用 GPU 支持
```

## 数据持久化

容器数据挂载到 `./hermes-data/`，包含：
- `~/.hermes/` — Hermes Agent 配置和会话
- `~/.vnc/` — VNC 配置
- `~/.config/` — 桌面配置

## Docker 独立使用

```bash
docker run -d \
  --name hermes-kasmvnc \
  -p 18642:8642 -p 18643:8643 -p 8443:8444 \
  -v $(pwd)/hermes-data:/home/node \
  -e HERMES_GATEWAY_TOKEN=your_token \
  hermes:kasmvnc
```
