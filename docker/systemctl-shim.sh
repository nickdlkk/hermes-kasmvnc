#!/usr/bin/env bash
# systemctl shim — 容器内 systemd 替代方案
# 将 hermes CLI 发出的 systemctl 调用转换为进程信号操作
set -euo pipefail

# 标记文件
DISABLED_MARKER="/tmp/hermes-gateway.disabled"
STOP_MARKER="/tmp/hermes-gateway.stopped"

# 查找网关进程 PID
# 使用 lsof 检测监听端口的进程，这是唯一可靠的方法：
# Python/Gateway processes can have similar command lines, lsof on port is reliable
find_gateway_pid() {
  local pid
  pid="$(lsof -i :${HERMES_GATEWAY_INTERNAL_PORT:-8642} -sTCP:LISTEN -t 2>/dev/null | head -1 || true)"
  if [ -n "$pid" ] && [ "$pid" != "1" ]; then
    echo "$pid"
    return 0
  fi
  return 1
}

# 从 hermes-agent 的 package.json 解析版本号并导出为环境变量
resolve_hermes_version() {
  local ver
  ver="$(python3 -c "import json; print(json.load(open('/usr/local/lib/hermes-agent/package.json'))['version'])" 2>/dev/null || true)"
  if [ -n "$ver" ]; then export HERMES_VERSION="$ver"; fi
}

# 等待网关进程启动就绪（检查端口监听）
wait_gateway_ready() {
  local pid
  for _ in $(seq 1 120); do
    pid="$(find_gateway_pid || true)"
    [ -n "$pid" ] && return 0
    sleep 0.5
  done
  echo "systemctl shim: gateway failed to start (timeout waiting for port)" >&2
  return 1
}

# ── 解析命令行参数，提取 systemctl 动作 ──
args=("$@"); action=""
for a in "${args[@]}"; do
  case "$a" in
    --version) echo "systemd 252 (shim)"; exit 0 ;;
    status|restart|start|stop|is-enabled|is-active|show|daemon-reload|enable|disable) [ -z "$action" ] && action="$a" ;;
  esac
done

# ── 根据动作执行对应操作 ──
case "$action" in
  daemon-reload|status)
    # 始终返回 0：hermes CLI 调用 "systemctl --user status" 检测 systemd 是否可用
    # 返回非零 = "systemctl 不可用" = 所有命令都会失败
    exit 0 ;;
  enable)
    rm -f "$DISABLED_MARKER"; exit 0 ;;
  disable)
    touch "$DISABLED_MARKER"; exit 0 ;;
  is-enabled)
    [ -f "$DISABLED_MARKER" ] && exit 1
    exit 0 ;;
  is-active)
    pid=$(find_gateway_pid || true)
    [ -n "$pid" ] && { echo "active"; exit 0; } || { echo "inactive"; exit 3; } ;;
  start)
    rm -f "$DISABLED_MARKER" "$STOP_MARKER"
    wait_gateway_ready; exit $? ;;
  restart)
    pid=$(find_gateway_pid || true)
    if [ -z "$pid" ]; then
      rm -f "$DISABLED_MARKER" "$STOP_MARKER"
      wait_gateway_ready; exit $?
    fi
    rm -f "$DISABLED_MARKER" "$STOP_MARKER"
    kill -TERM "$pid" 2>/dev/null || true
    for _ in $(seq 1 60); do
      if ! kill -0 "$pid" 2>/dev/null; then break; fi
      sleep 0.25
    done
    kill -KILL "$pid" 2>/dev/null || true
    sleep 0.5
    wait_gateway_ready; exit $? ;;
  stop)
    touch "$STOP_MARKER"
    pid=$(find_gateway_pid || true)
    [ -z "$pid" ] && exit 0
    kill -TERM "$pid" 2>/dev/null || true
    for _ in $(seq 1 60); do
      if ! kill -0 "$pid" 2>/dev/null; then exit 0; fi
      sleep 0.25
    done
    kill -KILL "$pid" 2>/dev/null || true
    exit 0 ;;
  show)
    pid=$(find_gateway_pid || true)
    if [ -n "$pid" ]; then
      printf 'ActiveState=active\nSubState=running\nMainPID=%s\nExecMainStatus=0\nExecMainCode=exited\n' "$pid"
    else
      printf 'ActiveState=inactive\nSubState=dead\nMainPID=0\nExecMainStatus=0\nExecMainCode=exited\n'
    fi; exit 0 ;;
  *) exit 0 ;;
esac
