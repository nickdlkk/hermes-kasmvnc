# AGENTS.md

This file provides guidance to AI coding agents working on this repository.

## Project Overview

Fork of [ddong8/openclaw-kasmvnc](https://github.com/ddong8/openclaw-kasmvnc), adapted to run **Hermes Agent** instead of OpenClaw inside the KasmVNC desktop container.

Key changes from upstream:
- Replaces `openclaw gateway` with `hermes gateway run`
- Uses Hermes Agent's native install script (`curl | bash`)
- Gateway port: 8642 (Hermes API Server default)
- Always disables Docker-in-Docker (DinD)
- Volume mount: `./hermes-data` instead of `./openclaw-data`

## Architecture

The install script (`hermes-kasmvnc-zh.sh`) dynamically generates:
- `Dockerfile.kasmvnc` — Node 22 + KasmVNC + XFCE4 + Chromium + Fcitx5 + Hermes Agent
- `docker-compose.yml` — Service definition with port mappings, volumes
- `.env` — Auto-generated tokens, passwords, ports
- `scripts/docker/kasmvnc-startup.sh` — Container entrypoint (VNC → desktop → gateway)
- `scripts/docker/systemctl-shim.sh` — systemd emulation for hermes CLI

## Key Ports

| Port | Service |
|------|---------|
| 18642 | Hermes Gateway (host) → 8642 (container) |
| 18643 | Hermes Webhook (host) → 8643 (container) |
| 8443 | KasmVNC HTTPS |
| 8444 | KasmVNC WebSocket |

## Development

```bash
# Install
./hermes-kasmvnc-zh.sh install

# Restart container
./hermes-kasmvnc-zh.sh restart

# Upgrade hermes-agent inside running container
./hermes-kasmvnc-zh.sh upgrade

# Logs
./hermes-kasmvnc-zh.sh logs --tail 200
```

## Important Build Notes

- The `hermes-kasmvnc-zh.sh` script is the **single source of truth** — it embeds all generated files
- To modify the Dockerfile, edit the `ensure_build_context()` function inside the shell script
- The shell script generates files at runtime into the install directory
- Build args `HTTP_PROXY`/`HTTPS_PROXY` must be empty string `""` in docker-compose.yml to override host proxy inheritance during image build
