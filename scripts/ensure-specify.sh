#!/usr/bin/env bash
# ensure-specify.sh — 检测并安装 specify-cli
# 用法: bash scripts/ensure-specify.sh
#
# 特性：支持网络重试、超时保护、跨平台兼容

set -euo pipefail

# ---- 颜色定义（兼容 Windows cmd） ----
RED=''
GREEN=''
YELLOW=''
NC=''
# 检测终端是否支持颜色
if [ -t 1 ]; then
  case "$TERM" in
    xterm*|rxvt*|urxvt*|linux*|vt100|screen*)
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      NC='\033[0m' # No Color
      ;;
  esac
fi

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---- 重试辅助函数 ----
# 用法: retry <最大次数> <间隔秒> <命令...>
retry() {
  local max_attempts=$1
  local sleep_sec=$2
  shift 2
  local attempt=1
  local exit_code=0

  while [ $attempt -le "$max_attempts" ]; do
    if [ $attempt -gt 1 ]; then
      log_warn "第 $attempt 次重试（共 $max_attempts 次）..."
    fi
    if "$@"; then
      return 0
    fi
    exit_code=$?
    attempt=$((attempt + 1))
    if [ $attempt -le "$max_attempts" ]; then
      sleep "$sleep_sec"
    fi
  done
  log_error "重试 $max_attempts 次后仍失败"
  return $exit_code
}

# ---- 检测 uv ----
if ! command -v uv &>/dev/null; then
    log_error "uv 未安装。"
    echo ""
    echo "uv 是 Python 包管理工具，specify-cli 需要通过它安装。"
    echo "安装方法（选其一）："
    echo "  Windows (PowerShell): powershell -c \"irm https://astral.sh/uv/install.ps1 | iex\""
    echo "  macOS/Linux:          curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "  详见: https://docs.astral.sh/uv/"
    echo ""
    echo "  > 当前终端为 Git Bash。如 PowerShell 命令不工作，请手动打开 PowerShell 执行。"
    echo ""
    exit 1
fi
log_info "uv 已安装: $(uv --version)"

# ---- 检测 specify ----
if command -v specify &>/dev/null; then
    INSTALLED_VERSION=$(specify --version 2>&1 || echo "unknown")
    log_info "specify 已安装: ${INSTALLED_VERSION}"
    exit 0
fi

# ---- 安装 specify（带重试） ----
log_warn "specify 未安装，正在通过 uv 安装..."
echo ""

# 网络操作设置超时（避免 hang）
export UV_HTTP_TIMEOUT=${UV_HTTP_TIMEOUT:-60}

if retry 3 5 uv tool install specify-cli --from git+https://github.com/github/spec-kit.git; then
    log_info "specify 安装成功"
    INSTALLED_VERSION=$(specify --version 2>&1 || echo "unknown")
    log_info "版本: ${INSTALLED_VERSION}"
    exit 0
else
    log_error "specify 安装失败（已尝试 3 次）。"
    echo ""
    echo "请检查："
    echo "  1. 网络连接是否正常"
    echo "  2. Git 是否已安装并配置"
    echo "  3. GitHub 是否可访问（GitHub 在中国大陆可能不稳定，配置代理可改善）"
    echo ""
    echo "代理配置示例："
    echo "  export HTTPS_PROXY=http://127.0.0.1:7890"
    echo "  export HTTP_PROXY=http://127.0.0.1:7890"
    echo "  然后重新运行本脚本即可。"
    echo ""
    echo "也可手动安装: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
    exit 1
fi
