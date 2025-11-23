# Linux 安装 Clash

## 快速开始

### 环境要求

- 用户权限：`root` 或 `sudo` 用户。
- `shell` 支持：`bash`、`zsh`、`fish`。

### 安装


```bash
git clone --branch master --depth 1 https://gh-proxy.com/https://github.com/kxf-scut/clash-for-linux.git
cd clash-for-linux
```
修改/work1/kxf/clash-for-linux/script/common.sh下的CLASH_BASE_DIR变量，一般指定为"/opt/clash/<用户名>"
```bash
sudo bash install.sh
```

### 命令一览

执行 `clashctl` 列出开箱即用的快捷命令。


```bash
$ clashctl
Usage:
    clashctl    COMMAND [OPTION]
    
Commands:
    on                   开启代理
    off                  关闭代理
    ui                   面板地址
    status               内核状况
    proxy    [on|off]    系统代理
    tun      [on|off]    Tun 模式
    mixin    [-e|-r]     Mixin 配置
    secret   [SECRET]    Web 密钥
    update   [auto|log]  更新订阅
```

💡`clashon` 等同于 `clashctl on`，`Tab` 补全更方便！

### 优雅启停

```bash
$ clashon
😼 已开启代理环境

$ clashoff
😼 已关闭代理环境
```
- 启停代理内核的同时，设置系统代理。
- 亦可通过 `clashproxy` 单独控制系统代理。

### Web 控制台

```bash
$ clashui
╔═══════════════════════════════════════════════╗
║                😼 Web 控制台                  ║
║═══════════════════════════════════════════════║
║                                               ║
║     🔓 注意放行端口：9090                      ║
║     🏠 内网：http://192.168.0.1:9090/ui       ║
║     🌏 公网：http://255.255.255.255:9090/ui   ║
║     ☁️ 公共：http://board.zash.run.place      ║
║                                               ║
╚═══════════════════════════════════════════════╝

$ clashsecret 666
😼 密钥更新成功，已重启生效

$ clashsecret
😼 当前密钥：666
```

- 通过浏览器打开 Web 控制台，实现可视化操作：切换节点、查看日志等。
- 若暴露到公网使用建议定期更换密钥。

### 切换节点

在${CLASH_BASE_DIR}/runtime.yaml下查看secret
```bash
$ SECRET=<secret> /work1/kxf/clash-for-linux/switch_node.sh "<节点名称>"
h "<节点名称>"
目标节点: 越南01【vip2】
目标代理组: 自动选择
控制器: http://127.0.0.1:9090
使用 secret (长度: 6)
请求 URL: ...
HTTP 状态: 204
切换请求成功。控制器返回:
```

### 更新订阅

```bash
$ clashupdate https://example.com
👌 正在下载：原配置已备份...
🍃 下载成功：内核验证配置...
🍃 订阅更新成功

$ clashupdate auto [url]
😼 已设置定时更新订阅

$ clashupdate log
✅ [2025-02-23 22:45:23] 订阅更新成功：https://example.com
```

- `clashupdate` 会记住上次更新成功的订阅链接，后续执行无需再指定。
- 可通过 `crontab -e` 修改定时更新频率及订阅链接。

### `Tun` 模式

```bash
$ clashtun
😾 Tun 状态：关闭

$ clashtun on
😼 Tun 模式已开启
```

- 作用：实现本机及 `Docker` 等容器的所有流量路由到 `clash` 代理、DNS 劫持等。
- 原理：[clash-verge-rev](https://www.clashverge.dev/guide/term.html#tun)、 [clash.wiki](https://clash.wiki/premium/tun-device.html)。
- 注意事项：[#100](https://github.com/nelvko/clash-for-linux-install/issues/100#issuecomment-2782680205)

### `Mixin` 配置

```bash
$ clashmixin
😼 less 查看 mixin 配置

$ clashmixin -e
😼 vim 编辑 mixin 配置

$ clashmixin -r
😼 less 查看 运行时 配置
```

- 持久化：将自定义配置项写入`Mixin`（`mixin.yaml`），而非原订阅配置（`config.yaml`），可避免更新订阅后丢失。
- 配置加载：代理内核启动时使用 `runtime.yaml`，它是订阅配置与 `Mixin` 配置的合并结果集，相同配置项以 `Mixin` 为准。
- 注意：因此直接修改 `config.yaml` 并不会生效。

### 卸载

```bash
sudo bash uninstall.sh
```

## 引用

- [Clash 知识库](https://clash.wiki/)
- [Clash 家族下载](https://www.clash.la/releases/)
- [Clash Premium](https://downloads.clash.wiki/ClashPremium/)
- [mihomo](https://github.com/MetaCubeX/mihomo)
- [clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install)
- [subconverter: 订阅转换](https://github.com/tindy2013/subconverter)
- [yacd: Web 控制台](https://github.com/haishanh/yacd)
- [yq: 处理 yaml](https://github.com/mikefarah/yq)




