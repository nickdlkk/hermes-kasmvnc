#!/usr/bin/env bash
set -euo pipefail

# ── 环境变量初始化 ──
export HOME="${HOME:-/home/node}"
export USER="${USER:-node}"
export DISPLAY="${HERMES_KASMVNC_DISPLAY:-:1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-runtime}"
# Fcitx5 输入法环境变量（GTK/Qt/X11 三端）
export GTK_IM_MODULE="${GTK_IM_MODULE:-fcitx}"
export QT_IM_MODULE="${QT_IM_MODULE:-fcitx}"
export XMODIFIERS="${XMODIFIERS:-@im=fcitx}"
export BROWSER="/usr/local/bin/chromium-kasm"

# 获取 OpenClaw 版本号用于界面显示
if [ -z "${HERMES_VERSION:-}" ]; then
  HERMES_VERSION=$(hermes --version 2>/dev/null | head -n1 || echo "dev")
  export HERMES_VERSION
fi

# KasmVNC 配置参数
KASMVNC_USER="${HERMES_KASMVNC_USER:-node}"
KASMVNC_PASSWORD="${HERMES_KASMVNC_PASSWORD:-}"
RESOLUTION="${HERMES_KASMVNC_RESOLUTION:-1920x1080}"
DEPTH="${HERMES_KASMVNC_DEPTH:-24}"

# 修复挂载卷时 /home/node 或子目录可能归 root 所有的问题（每次启动都修，幂等）
sudo chown "$(id -u):$(id -g)" "${HOME}" 2>/dev/null || true
[ -e "${HOME}/.hermes" ] && sudo chown -R "$(id -u):$(id -g)" "${HOME}/.hermes" 2>/dev/null || true
[ -e "${HOME}/.vnc" ] && sudo chown -R "$(id -u):$(id -g)" "${HOME}/.vnc" 2>/dev/null || true
[ -e "${HOME}/.config" ] && sudo chown -R "$(id -u):$(id -g)" "${HOME}/.config" 2>/dev/null || true
[ -e "${HOME}/Desktop" ] && sudo chown -R "$(id -u):$(id -g)" "${HOME}/Desktop" 2>/dev/null || true

# 创建 VNC 和 XDG 运行时目录
mkdir -p "${HOME}/.vnc" "${XDG_RUNTIME_DIR}" "${HOME}/.hermes"
chmod 700 "${HOME}/.vnc" "${XDG_RUNTIME_DIR}" "${HOME}/.hermes" 2>/dev/null || true

# 后台启动 Docker 守护进程（DinD 支持），等待 socket 就绪（仅在未禁用 DinD 时）
if [ "${NO_DIND:-0}" != "1" ] && command -v dockerd >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
  (sudo nohup dockerd >/tmp/hermes-dockerd.log 2>&1 &) || true
  for i in $(seq 1 30); do
    [ -S /var/run/docker.sock ] && break
    sleep 1
  done
fi

# 清理可能残留的 hermes 别名（历史版本遗留）
sed -i '/^alias hermes=/d' "${HOME}/.bashrc" 2>/dev/null || true

# 确保桌面图标存在（volume 挂载可能覆盖镜像中的图标）
mkdir -p "${HOME}/Desktop"
# 清理旧版可能遗留在挂载卷里的桌面图标
rm -f "${HOME}/Desktop/hermes-agent.desktop" 2>/dev/null || true
[ -f "${HOME}/Desktop/chromium.desktop" ] || cp /usr/share/applications/chromium-kasm.desktop "${HOME}/Desktop/chromium.desktop" 2>/dev/null || true
[ -f "${HOME}/Desktop/vscode.desktop" ] || cp /usr/share/applications/code.desktop "${HOME}/Desktop/vscode.desktop" 2>/dev/null || true
chmod +x "${HOME}/Desktop/chromium.desktop" "${HOME}/Desktop/vscode.desktop" 2>/dev/null || true
chmod +x "${HOME}/Desktop"/*.desktop 2>/dev/null || true

# 配置 npm 使用淘宝镜像源
cat > "${HOME}/.npmrc" <<'EONPMRC'
registry=https://registry.npmmirror.com
EONPMRC

# ── 配置 XFCE 默认浏览器为 chromium-kasm ──
mkdir -p "${HOME}/.config" "${HOME}/.config/xfce4"
cat > "${HOME}/.config/xfce4/helpers.rc" <<'EOH'
WebBrowser=chromium-kasm
EOH
# 配置 MIME 类型关联，使 http/https 链接默认用 chromium-kasm 打开
cat > "${HOME}/.config/mimeapps.list" <<'EOH'
[Default Applications]
x-scheme-handler/http=chromium-kasm.desktop
x-scheme-handler/https=chromium-kasm.desktop
text/html=chromium-kasm.desktop
EOH
mkdir -p "${HOME}/.config/autostart"

# 注册 Fcitx5 为当前用户的 X 会话输入法
cat > "${HOME}/.xinputrc" <<'EOH'
run_im fcitx5
EOH

# ── Fcitx5 自动激活 ──
# 创建 XFCE 自启动项：等待桌面加载完成后，强制激活 Fcitx5 并切换到 Rime 输入法
cat > "${HOME}/.config/autostart/fcitx5-activate-rime.desktop" <<'EOH'
[Desktop Entry]
Type=Application
Name=Activate Fcitx5 Rime
Exec=bash -c "for i in {1..120}; do if pgrep -x xfdesktop >/dev/null 2>&1; then break; fi; sleep 1; done; sleep 5; fcitx5-remote -o; sleep 0.5; fcitx5-remote -s rime; fcitx5-remote -o"
Terminal=false
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
EOH

# 配置 Fcitx5 输入法列表：keyboard-us（英文）+ rime（中文），默认使用 rime
mkdir -p "${HOME}/.config/fcitx5"
cat > "${HOME}/.config/fcitx5/profile" <<'EOH'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=rime

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=rime
Layout=

[GroupOrder]
0=Default
EOH

# 强制 Fcitx5 默认激活中文输入，所有窗口共享输入状态
cat > "${HOME}/.config/fcitx5/config" <<'EOH'
[Behavior]
ActiveByDefault=True
ShareInputState=All
PreeditEnabledByDefault=True
EOH

# 确保 Rime 自定义配置存在：默认中文模式（ascii_mode reset=0）
mkdir -p "${HOME}/.local/share/fcitx5/rime"
cat > "${HOME}/.local/share/fcitx5/rime/default.custom.yaml" <<'EOH'
patch:
  "switches/@0/reset": 0
EOH

# 验证 VNC 用户是否存在，不存在则回退到 node
if ! id -u "${KASMVNC_USER}" >/dev/null 2>&1; then
  KASMVNC_USER="node"
fi

# ── 生成 VNC 桌面启动脚本 xstartup ──
# 启动 D-Bus 会话总线 → 启动 Fcitx5 输入法守护进程 → 启动 XFCE4 桌面
cat > "${HOME}/.vnc/xstartup" <<'EOH'
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(dbus-launch --sh-syntax 2>/dev/null)" || true
  export DBUS_SESSION_BUS_ADDRESS
fi
if command -v fcitx5 >/dev/null 2>&1; then
  fcitx5 -d >/tmp/hermes-fcitx5.log 2>&1 || true
fi
exec startxfce4
EOH
chmod +x "${HOME}/.vnc/xstartup"

# 使用 KasmVNC 的桌面环境选择器注册 XFCE
if command -v /usr/lib/kasmvncserver/select-de.sh >/dev/null 2>&1; then
  /usr/lib/kasmvncserver/select-de.sh -y -s XFCE >/tmp/hermes-kasmvnc-selectde.log 2>&1 || true
fi

# 设置 VNC 登录密码
if [ -n "${KASMVNC_PASSWORD}" ]; then
  printf '%s\n%s\n' "${KASMVNC_PASSWORD}" "${KASMVNC_PASSWORD}" \
    | vncpasswd -u "${KASMVNC_USER}" -w -r >/dev/null || true
fi

# ── 清理残留的 VNC/X11 状态（防止容器重启后黑屏）──
if vncserver -list 2>/dev/null | grep -Eq "^[[:space:]]*${DISPLAY}[[:space:]]"; then
  vncserver -kill "${DISPLAY}" >/dev/null 2>&1 || true
fi
pkill -9 -f "Xvnc.*${DISPLAY}" 2>/dev/null || true
DISPLAY_NUM="${DISPLAY#:}"
rm -f "/tmp/.X${DISPLAY_NUM}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM}"
rm -f "${HOME}/.vnc/"*"${DISPLAY}"*.pid 2>/dev/null || true

# ── 覆写 KasmVNC 剪贴板配置 ──
# 移除默认的 chromium/x-web-custom-data MIME 类型，使 Xvnc 命令行不含 "chromium"
# 这样 pkill -f chromium 不会误杀 VNC 服务进程
sudo tee /etc/kasmvnc/kasmvnc.yaml >/dev/null <<'KASMCFG' || true
data_loss_prevention:
  clipboard:
    allow_mimetypes:
      - text/html
      - image/png
KASMCFG

# ── 启动 VNC 服务器 ──
vncserver "${DISPLAY}" -geometry "${RESOLUTION}" -depth "${DEPTH}" -xstartup "${HOME}/.vnc/xstartup" -publicIP 127.0.0.1 >/tmp/hermes-kasmvnc.log 2>&1 || true

# 如果 XFCE 会话未自动启动，手动拉起（兜底机制）
if ! pgrep -u "$(id -u)" -f "xfce4-session" >/dev/null 2>&1; then
  DISPLAY="${DISPLAY}" nohup sh "${HOME}/.vnc/xstartup" >/tmp/hermes-xfce-autostart.log 2>&1 &
fi

# 设置系统默认浏览器为 chromium-kasm
if command -v xdg-settings >/dev/null 2>&1; then
  DISPLAY="${DISPLAY}" xdg-settings set default-web-browser chromium-kasm.desktop >/dev/null 2>&1 || true
fi

# ── 清理配置文件中的平台指纹（保留 auth tokens）──
if [ -f "${HOME}/.hermes/hermes.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    # Use jq to surgically remove only platform fields
    jq 'del(.identity.pinnedPlatform, .identity.pinnedDeviceFamily)' \
      "${HOME}/.hermes/hermes.json" > "${HOME}/.hermes/hermes.json.tmp" 2>/dev/null \
      && mv "${HOME}/.hermes/hermes.json.tmp" "${HOME}/.hermes/hermes.json" || true
  else
    # Fallback: if non-Linux platform detected, backup entire config
    if grep -q '"pinnedPlatform".*"darwin"' "${HOME}/.hermes/hermes.json" 2>/dev/null || \
       grep -q '"pinnedPlatform".*"win32"' "${HOME}/.hermes/hermes.json" 2>/dev/null; then
      echo "Detected non-Linux platform config, backing up..." >&2
      mv "${HOME}/.hermes/hermes.json" "${HOME}/.hermes/hermes.json.bak" 2>/dev/null || true
    fi
  fi
fi

# ── 确保 systemd service 文件存在（支持 install/uninstall 命令）──
if [ ! -f "${HOME}/.config/systemd/user/hermes-gateway.service" ]; then
  mkdir -p "${HOME}/.config/systemd/user"
  cat > "${HOME}/.config/systemd/user/hermes-gateway.service" <<'EOSVC'
[Unit]
Description=OpenClaw Gateway (managed by supervisor)
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOSVC
fi

# Clear stop marker (auto-start after container restart)
rm -f /tmp/hermes-gateway.stopped

# 在启动前修复/补齐本地 gateway 配置。最近的 OpenClaw 版本会把
# “配置文件已存在但缺少 gateway.mode” 视为损坏配置，即使仍传了
# --allow-unconfigured 也可能拒绝启动。
mkdir -p "${HOME}/.hermes/workspace"
# hermes config set gateway.mode local >/dev/null 2>&1 || true
hermes config set agents.defaults.workspace "${HOME}/.hermes/workspace" >/dev/null 2>&1 || true

# 配置 gateway 允许非 loopback 绑定时的 Host-header 回退（远程访问必需）
hermes config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true >/dev/null 2>&1 || true
# 强制设置 gateway bind 配置（覆盖可能的 loopback 配置）
hermes config set gateway.bind "${HERMES_GATEWAY_BIND:-lan}" >/dev/null 2>&1 || true
# 启用 self-improvement hook
hermes hooks enable self-improvement >/dev/null 2>&1 || true

# 直接前台运行 supervisor 循环（不走 systemctl，避免双重后台化）
# 设置环境变量让 gateway 知道有 supervisor 管理
export HERMES_SERVICE_MARKER=1
unset HERMES_NO_RESPAWN 2>/dev/null || true

# Supervisor 循环：gateway 退出后自动重启（带最新版本号）
# 注意：不会因为 STOP_MARKER 而退出循环，只是暂停启动
while true; do
  # 检查停止标记：如果存在则等待它被清除
  while [ -f /tmp/hermes-gateway.stopped ]; do
    sleep 1
  done

  # 从 package.json 读取版本号并导出
  ver="$(python3 -c "import json; print(json.load(open('/usr/local/lib/hermes-agent/package.json'))['version'])" 2>/dev/null || true)"
  if [ -n "$ver" ]; then export HERMES_VERSION="$ver"; fi

  # 启动 gateway（前台运行）
  # 临时关闭 set -e 以便捕获退出码
  set +e
  if command -v hermes >/dev/null 2>&1; then
    # hermes gateway run — supports --token via .env / config
    hermes gateway run >>/tmp/hermes-gateway.log 2>&1
  else
    echo "kasmvnc-startup: cannot start gateway (hermes CLI not found)" >&2
    sleep infinity
  fi

  rc=$?
  set -e

  # exit 0 = 正常重启（SIGUSR1 supervised），短暂等待后重启
  # 非零退出 = 异常崩溃，等待更长时间后重试
  if [ $rc -eq 0 ]; then
    echo "kasmvnc-startup: gateway exited (supervised restart), restarting..." >&2
    sleep 1
  else
    echo "kasmvnc-startup: gateway crashed (exit $rc), restarting in 3s..." >&2
    sleep 3
  fi
done
