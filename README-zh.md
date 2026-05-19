# Hermes Agent + KasmVNC 一键部署

基于 [ddong8/openclaw-kasmvnc](https://github.com/ddong8/openclaw-kasmvnc) fork 改造，将 OpenClaw 替换为 Hermes Agent，支持中文输入法优化。

## 功能

- **Hermes Gateway** — 消息网关，支持飞书、Telegram、Discord 等平台，HTTP API Server（`0.0.0.0:8642`）
- **Hermes Dashboard** — Web 管理界面（`0.0.0.0:9119`）
- **KasmVNC** — 浏览器内 VNC 桌面，无需安装客户端
- **XFCE4** — 轻量级 Linux 桌面环境
- **Chromium** — 浏览器，支持远程调试
- **Fcitx5 + 雾凇拼音** — 中文输入法
- **Docker-in-Docker** — 内置 dockerd，Hermes 可在容器内创建管理子容器

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
| Hermes Gateway API | `18642` | HTTP API Server |
| Hermes Webhook | `18643` | Webhook 回调 |
| Hermes Dashboard | `8919` | Web 管理界面 |
| KasmVNC HTTPS | `8443` | VNC 桌面访问 |
| KasmVNC WebSocket | `8444` | VNC WebSocket |

## 环境变量

```bash
HERMES_GATEWAY_PORT=18642      # Gateway 宿主机端口
HERMES_KASMVNC_HTTPS_PORT=8443 # VNC HTTPS 端口
HERMES_DATA_DIR=./hermes-data  # 数据目录（挂载到容器 /home/node）
HERMES_HTTP_PROXY=             # 容器内 HTTP 代理
HERMES_ENABLE_GPU=0            # 启用 GPU 支持
NO_DIND=1                      # 禁用 Docker-in-Docker（更安全）

# API Server（默认自动生成，也可手动指定）
API_SERVER_KEY=<your-key>      # Gateway API 访问密钥
API_SERVER_HOST=0.0.0.0        # 绑定地址（容器外访问需 0.0.0.0）
GATEWAY_ALLOW_ALL_USERS=true   # 允许无认证访问
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
  --privileged \
  --shm-size=2g \
  -p 18642:8642 \
  -p 18643:8643 \
  -p 8919:9119 \
  -p 8443:8444 \
  -v $(pwd)/hermes-data:/home/node \
  -e API_SERVER_KEY=$(openssl rand -hex 32) \
  -e API_SERVER_HOST=0.0.0.0 \
  -e GATEWAY_ALLOW_ALL_USERS=true \
  hermes:kasmvnc
```

访问：
- KasmVNC：`https://localhost:8443`（用户 `node`，密码 `hermesvnc`）
- Gateway API：`http://localhost:18642`
- Dashboard：`http://localhost:8919`

## 禁用 DinD（更安全）

如果不需要 Hermes 在容器内管理子容器，可禁用 Docker-in-Docker：

```bash
./hermes-kasmvnc-zh.sh install --no-dind
```

禁用后：
- 容器不需要 `--privileged`
- `security_opt: [seccomp:unconfined]` 自动添加（Docker < 23.0 需要）
- Hermes 无法创建子容器

## FAQ

### 端口映射不生效（宿主机无法访问 Gateway API）

如果使用 DinD 模式，发现 `curl localhost:18642` 连接被 RST，请确认镜像已包含 DinD NAT 修复（保存并恢复 `iptables -t nat` 规则）。较旧镜像可重建解决。

### HTTPS 证书警告

KasmVNC 使用自签名证书，浏览器首次访问时会警告，点击继续即可。也可配置 Nginx/Caddy 反向代理使用真实证书。
