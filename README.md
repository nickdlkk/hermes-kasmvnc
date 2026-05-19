# hermes-kasmvnc

One-click deployment for Hermes Agent + KasmVNC (Windows / macOS / Linux).

> 🇨🇳 中文版 / Chinese version: [README-zh.md](README-zh.md)

## Key Advantages

### 🔗 Hermes Gateway with HTTP API

Built-in HTTP API server (`0.0.0.0:8642`) with Bearer token authentication, plus a Web Dashboard (`0.0.0.0:9119`) for monitoring.

### 🔧 Full Lifecycle Management Inside Container

**Solves the core limitation of official Hermes Docker deployment:**

- ❌ Cannot run `hermes gateway restart` inside container (no systemd)
- ❌ Must manually restart container after config changes

**This project solves it with systemctl shim + supervisor loop:**
- ✅ Supports `hermes gateway restart` inside container
- ✅ Supports `upgrade` command for hot updates (no image rebuild needed)
- ✅ Gateway auto-restarts on crash (VNC session stays connected)
- ✅ Complete `install / upgrade / restart / uninstall` lifecycle management

### 👁️ Visual Desktop Environment

**Solves the visibility problem of cloud vendor deployments:**

- ❌ Cannot watch the agent operate the browser in real-time
- ❌ Cannot observe task execution with visual feedback

**This project provides a complete desktop environment:**
- ✅ Browser-based XFCE desktop (KasmVNC) — no client install needed
- ✅ Watch the agent operate Chromium in real-time
- ✅ Full Linux desktop experience

### 🐳 Docker-in-Docker Support

Built-in dockerd lets Hermes Agent create and manage child containers directly inside the container — no extra configuration needed.

## Quick Start

### Option 1: Docker Image (Recommended)

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

**Data Persistence:** Mounting `hermes-data:/home/node` persists all user data including Hermes configs, skills, desktop files, Git credentials, and VNC sessions.

> 📖 Full documentation: [DOCKER-en.md](DOCKER-en.md)

### Option 2: One-Click Script

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/nickdlkk/hermes-kasmvnc/hermes-kasmvnc/openclaw-kasmvnc-zh.sh | bash -s -- install
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/nickdlkk/hermes-kasmvnc/hermes-kasmvnc/openclaw-kasmvnc-zh.ps1 | iex
```

### Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| KasmVNC Desktop | `https://127.0.0.1:8443` | User `node`, password `hermesvnc` |
| Hermes Gateway API | `http://127.0.0.1:18642` | Bearer token (auto-generated) |
| Hermes Dashboard | `http://127.0.0.1:8919` | None |

## Features

- **Environment isolation** — Hermes Agent, desktop, and all dependencies live inside the container
- **One-click deploy** — install, upgrade, and restart via a single script + Compose
- **Cross-platform** — identical container behavior on Windows, macOS, and Linux
- **Docker-in-Docker** — built-in dockerd lets Hermes create and manage child containers
- **GPU auto-detect** — automatically enables `nvidia` runtime when a host GPU is present
- **Hermes Dashboard** — Web UI for monitoring gateway status

## Prerequisites

- Docker (with Docker Compose v2)
- Windows: PowerShell 5+ / 7+
- macOS / Linux: Bash

## Common Commands

<details>
<summary><b>Linux / macOS (Bash)</b></summary>

```bash
chmod +x ./hermes-kasmvnc-zh.sh

./hermes-kasmvnc-zh.sh install              # Install
./hermes-kasmvnc-zh.sh uninstall            # Uninstall (stop services only)
./hermes-kasmvnc-zh.sh uninstall --purge    # Uninstall and remove install directory
./hermes-kasmvnc-zh.sh restart              # Restart
./hermes-kasmvnc-zh.sh upgrade              # Upgrade (hot reload, no rebuild)
./hermes-kasmvnc-zh.sh status               # Status
./hermes-kasmvnc-zh.sh logs --tail 200      # Logs
```

</details>

<details>
<summary><b>Windows (PowerShell)</b></summary>

```powershell
# Install
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 -Command install

# Uninstall (stop services only)
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 -Command uninstall

# Uninstall and remove install directory
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 -Command uninstall -Purge

# Restart
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 -Command restart

# Upgrade
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 -Command upgrade

# Status / Logs
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 -Command status
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 -Command logs -Tail 200
```

</details>

## Optional Parameters

| Parameter | Windows (PS1) | macOS/Linux (sh) | Default |
|-----------|---------------|-------------------|---------|
| Install directory | `-InstallDir` | `--install-dir` | `$HOME/hermes-kasmvnc` |
| Gateway port | `-GatewayPort` | `--gateway-port` | `18642` |
| VNC HTTPS port | `-HttpsPort` | `--https-port` | `8443` |
| Gateway token | `-GatewayToken` | `--gateway-token` | Auto-generated |
| VNC password | `-KasmPassword` | `--kasm-password` | `hermesvnc` |
| HTTP proxy | `-Proxy` | `--proxy` | None |
| Disable Docker-in-Docker | `-NoDinD` | `--no-dind` | DinD **enabled** |
| Disable Docker build cache | `-NoCache` | `--no-cache` | No |
| Log lines | `-Tail` | `--tail` | `200` |
| Purge install dir | `-Purge` | `--purge` | No |

<details>
<summary>Custom install examples</summary>

```bash
# Linux/macOS
./hermes-kasmvnc-zh.sh install \
  --install-dir "$HOME/hermes-deploy" \
  --gateway-port 18642 \
  --https-port 8443

# With proxy
./hermes-kasmvnc-zh.sh install --proxy http://192.168.1.131:10808
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 `
  -Command install `
  -InstallDir "D:\hermes-deploy" `
  -GatewayPort "18642" `
  -HttpsPort "8443"
```

</details>

<details>
<summary>Disable Docker-in-Docker (more secure)</summary>

By default, the container runs with `--privileged` and installs Docker CE to support Docker-in-Docker. If you don't need Hermes to manage child containers, disable DinD for better security:

```bash
# Linux/macOS
./hermes-kasmvnc-zh.sh install --no-dind

# Windows
powershell -ExecutionPolicy Bypass -File .\hermes-kasmvnc-zh.ps1 -Command install -NoDinD
```

When `--no-dind` is enabled:
- Docker CE is not installed in the container
- Container runs without `privileged: true`
- The generated `docker-compose.yml` adds `security_opt: [seccomp:unconfined]` automatically — required on Docker < 23.0 so XFCE/GLib's `close_range` syscall works (otherwise the desktop renders as a black screen). Docker 23.0+ allows it by default.
- Hermes cannot create or manage child containers

</details>

## Project Structure

After running, the install directory contains:
```
<install-dir>/
├── .env                              # Environment config (token, password, ports, API keys)
├── hermes-data/                      # Persisted user data (hermes configs, desktop, etc.)
├── docker-compose.yml                # Compose service definition
├── Dockerfile.kasmvnc                # Image build (node:22 + KasmVNC + XFCE + hermes-agent)
└── scripts/docker/
    ├── kasmvnc-startup.sh            # Container entrypoint (VNC → desktop → gateway)
    └── systemctl-shim.sh              # systemctl shim (translates systemd calls to signals)
```

## Built-in Features

- **UTF-8, zh_CN locale** — `TZ=Asia/Shanghai`, `LANG=zh_CN.UTF-8`, Noto CJK fonts pre-installed
- **Fcitx5 + Rime** — Chinese input method (雾凇拼音) auto-configured
- **Gateway auto-restart** — supervisor loop restarts the gateway on crash; VNC session stays connected
- **X11 cleanup** — entrypoint clears stale X11 lock files and VNC processes to prevent black screens
- **systemctl shim** — no systemd in the container; the shim makes `hermes gateway restart/stop/start` work
- **API Server** — HTTP API on `0.0.0.0:8642` with Bearer token auth

## Managing the Gateway Inside the Container

Open a terminal in the VNC desktop and use standard Hermes commands:

```bash
hermes gateway restart          # Restart (reload latest code)
hermes gateway stop             # Stop
hermes gateway status --probe   # Check status
hermes dashboard --port 9119   # Start dashboard manually
```

> These commands work via the built-in systemctl shim — no real systemd required.

## Pre-installed Tools

The desktop environment comes with these development tools pre-installed:

- **Chromium** - Web browser (desktop icon)
- **Visual Studio Code** - Code editor (desktop icon)
- **vim** - Terminal text editor
- **Git** - Version control system
- **Node.js 22** - JavaScript runtime
- **npm** - Package manager (npmmirror configured for China)
- **Docker CE** - Container engine (DinD variants only)

Desktop icons are located in `/home/node/Desktop` and can be launched with a double-click.

## Configuration Changes

Config files: `<install-dir>/.env`, `<install-dir>/hermes-data/.hermes/config.yaml`

1. Edit the config file
2. Run `restart`
3. Verify with `status` and `logs --tail 200`

> If you changed image-level config (Dockerfile, system packages), run `upgrade` instead of `restart`.

## Known Issues

### Port mapping broken in DinD mode (Gateway API not reachable from host)

If `curl localhost:18642` returns connection refused/reset, this is caused by dockerd clearing iptables NAT rules on startup. The startup script includes a fix (save/restore NAT rules). Rebuild the image to apply the fix, or ensure you are using an image built after the fix was added.

### VNC flicker during `upgrade`

`npm install` causes high CPU/IO, which may trigger KasmVNC WebSocket heartbeat timeouts. This is temporary — the session recovers automatically. Run `upgrade` when the host has spare resources.

## FAQ

### 1. Build fails with package installation errors?

If you encounter errors during the Docker build process, try rebuilding without cache:

```bash
# Linux/macOS
./hermes-kasmvnc-zh.sh install --no-cache

# Windows
.\hermes-kasmvnc-zh.ps1 install -NoCache
```

This forces Docker to re-download all packages and can resolve transient network or repository issues.

### 2. Port conflict

Change ports at install time: `--gateway-port 28642 --https-port 9443`, then re-run `install`.

### 3. HTTPS certificate warning

KasmVNC uses a self-signed certificate by default. Click through the browser warning, or set up a reverse proxy (Nginx / Caddy) with a real cert.

### 4. Black screen after entering desktop

Try in order: `restart` → `status` → `logs --tail 200` → `upgrade`.

### 5. Container restart loop

Common causes: missing `.env` parameters, directory permission issues, port conflicts. Re-run `install` or change ports.

### 6. macOS `chown: Operation not permitted`

This warning may appear on Apple Silicon Macs for certain mount paths. If the container runs fine, it can be safely ignored.

### 7. Why Chromium instead of Chrome?

1. **Multi-arch** — Google does not ship ARM64 Chrome; Chromium supports both x86_64 and arm64
2. **License** — Chrome includes proprietary components (DRM, etc.) unsuitable for public images
3. **Clean dependencies** — `apt install chromium` integrates cleanly with system libraries

## License

[MIT](LICENSE)
