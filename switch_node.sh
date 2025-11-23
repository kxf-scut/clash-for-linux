#!/bin/bash
# switch_node.sh
# 用途: 通过 Clash external-controller API 将指定 proxy-group 切换到指定节点
# 用法: ./switch_node.sh "节点名称" ["代理组名称"]
# 环境变量:
#   CONTROLLER - 控制器地址，默认 127.0.0.1:9090
#   SECRET     - 如果控制器启用了 secret，可在此设置；脚本也会尝试通过 clashctl 或常见配置文件读取
. script/common.sh >&/dev/null
. script/clashctl.sh >&/dev/null

set -eu

NODE="$1" 2>/dev/null || {
  echo "用法: $0 \"目标节点名\" [\"proxy-group 名 (默认：自动选择)\"]"
  exit 1
}
GROUP="${2:-自动选择}"
CONTROLLER="${CONTROLLER:-127.0.0.1:9090}"

echo "目标节点: $NODE"
echo "目标代理组: $GROUP"
echo "控制器: http://$CONTROLLER"

# helper: 查找命令是否存在
have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# 获取 secret: 优先使用环境变量 SECRET
SECRET_VAL=""
if [ -n "${SECRET-}" ]; then
  SECRET_VAL="$SECRET"
else
  # 尝试使用 clashctl（如果在 PATH）获取
  if have_cmd clashctl; then
    # clashctl secret 会打印 '当前密钥：<val>' 或空行
    _s=$(clashctl secret 2>/dev/null || true)
    # 提取可能的密钥（冒号之后的内容）
    SECRET_VAL=$(printf "%s" "$_s" | awk -F'：|:' 'NF>1{print $2; exit}' | tr -d ' \"') || true
  fi
fi

# 若仍为空，尝试从常见 path 读取 runtime config 的 secret 字段
if [ -z "$SECRET_VAL" ]; then
  for p in /etc/clash/config.yaml /etc/clash/config.yml /usr/local/etc/clash/config.yaml ${CLASH_BASE_DIR}/runtime.yaml ${RESOURCES_BASE_DIR}/config.yaml; do
    [ -f "$p" ] || continue
    # 用 grep 简单提取 secret: "..."
  v=$(grep -E '^secret:' "$p" 2>/dev/null | head -n1 | sed 's/secret:[[:space:]]*//' | sed 's/^"//; s/"$//' | sed "s/^'//; s/'$//" | sed 's/[[:space:]]*$//') || true
    if [ -n "$v" ]; then
      SECRET_VAL="$v"
      break
    fi
  done
fi

if [ -n "$SECRET_VAL" ]; then
  echo "使用 secret (长度: $(printf "%s" "$SECRET_VAL" | wc -c))"
else
  echo "未发现 secret，脚本将首先尝试无鉴权请求；如返回 401/403，请通过环境变量 SECRET 提供或使用 clashctl 设置 web 密钥。"
fi

# URL-encode group 名（使用 python3，若没有 python3 则用简单替换）
if have_cmd python3; then
  GROUP_ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$GROUP")
else
  # 基本替换：空格->%20
  GROUP_ENC=$(printf "%s" "$GROUP" | sed -e 's/ /%20/g')
fi

URL="http://$CONTROLLER/proxies/$GROUP_ENC"

if ! have_cmd curl; then
  echo "错误：未找到 curl 命令，请安装 curl 再试" >&2
  exit 2
fi

BODY=$(printf '{"name":"%s"}' "$NODE")

echo "请求 URL: $URL"

# 先执行一次 PUT，捕获 HTTP 状态码与返回体
RESP_TMP=$(mktemp)
HTTP_CODE=000
if [ -n "$SECRET_VAL" ]; then
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "$RESP_TMP" -X PUT "${URL}" -H "Authorization: Bearer ${SECRET_VAL}" -H "Content-Type: application/json" -d "$BODY" )
else
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "$RESP_TMP" -X PUT "${URL}" -H "Content-Type: application/json" -d "$BODY" )
fi

echo "HTTP 状态: $HTTP_CODE"
case "$HTTP_CODE" in
  200|204)
    echo "切换请求成功。控制器返回:"
    cat "$RESP_TMP" || true
    rm -f "$RESP_TMP"
    exit 0
    ;;
  401|403)
    echo "鉴权失败 (HTTP $HTTP_CODE)。请提供正确的 SECRET 环境变量，或在控制面板/配置中关闭认证。" >&2
    echo "示例：export SECRET=your_secret_value" >&2
    cat "$RESP_TMP" || true
    rm -f "$RESP_TMP"
    exit 3
    ;;
  404)
    echo "未找到代理组或控制器地址错误 (HTTP 404)。请检查代理组名 '$GROUP' 是否存在，或检查 CONTROLLER=$CONTROLLER 是否正确。" >&2
    cat "$RESP_TMP" || true
    rm -f "$RESP_TMP"
    exit 4
    ;;
  000)
    echo "无法连接到控制器 http://$CONTROLLER，请检查 Clash 是否在运行以及端口是否可达。" >&2
    rm -f "$RESP_TMP"
    exit 5
    ;;
  *)
    echo "请求返回 HTTP $HTTP_CODE，响应:"
    cat "$RESP_TMP" || true
    rm -f "$RESP_TMP"
    exit 6
    ;;
esac
