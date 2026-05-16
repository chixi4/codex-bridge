# AI Handoff

如果你是接手这个项目的 AI，先读这一页。

## 目标

让远端 Windows/WSL 在不安装翻墙软件的情况下，经由 Mac 的代理访问 OpenAI/Google/npm，并让用户在远端 Windows 任意目录里直接运行：

```bat
codex
```

默认行为必须是 YOLO、当前目录启动、无需二次询问目录，并保持 Codex 原生 TUI。

## 关键设计

Mac 不劫持 `codex`，避免和本机未来安装的 Codex CLI 冲突。Mac 只提供：

```bash
win-ssh
win-codex login
win-codex reauth
win-codex status
win-codex logout
ez4-vpn status
ez4-vpn restart
```

远端 Windows 才提供 `codex.cmd`，它把 Windows 当前目录转换成 WSL 路径，然后调用 WSL 的 `/usr/local/bin/codex`。

WSL 的 `/usr/local/bin/codex` 不是真正的 Codex CLI，而是代理包装器；真实 CLI 在 `/opt/node-current/bin/codex`。包装器只负责代理环境和本地-only logout，不再改 Codex TUI 参数。

如果 Terminal 窗口左右边缘出现蓝灰色 `[` / `]`，不要去改远端链路。那是 macOS Terminal 的 line marks，关闭 `ShowLineMarks` 或菜单 `View -> Hide Marks`。

## 不要回退的点

- 不要把 Mac 本机命令改成 `codex`。
- 不要让远端 Windows 的 `codex` 再询问目录。
- 不要默认加 `--no-alt-screen`。它会让 transcript 退出后的主界面变空。长回复回看用 `Ctrl+T` 的 transcript/pager。
- 不要再引入 `CODEX_TUI_MODE` 之类的 alternate-screen 切换。这个方向已经验证过不能解决边缘中括号。
- 不要为了边缘中括号保留 WSL sshd/`win-wsl-ssh`。直连 Linux pty 已验证仍会出现 marks，根因在 macOS Terminal。
- 不要让默认 logout 影响用户 Mac 端登录。`win-codex logout` 和远端 wrapper 的 `codex logout` 默认只移走远端 WSL 的 `auth.json`；真正上游退出登录必须显式 `--revoke`。
- 用户在 Mac 本地 `codex logout/login` 仍可能让已经打开的远端 Codex TUI 报 refresh token revoked。这是服务端 token 被撤销加旧进程不热更新；用 `win-codex reauth` 后重启远端 TUI/`codex resume`。
- 不要用 device-code 登录，当前 Team 禁用了。
- 不要把 EZ4Connect 密码、私钥、Codex auth 文件提交进仓库。
- 如果 GUI 启动的 `zju-connect` 带 `-disable-keep-alive`，用 `ez4-vpn restart` 切到受控启动器。这个命令沿用本机 EZ4Connect 配置文件，但仓库里不保存真实密码。

## 已定位问题

输入完全没反应但画面还在：优先当作 SSH/EZ4Connect 半断处理，不是 Codex 卡住。用 `win-ssh` 的 keepalive 让它快速断开或保持活跃。

长回复回看：用 `Ctrl+T` 的 transcript/pager，不依赖 Mac 终端 scrollback。

WSL DNS 不解析：固定 `/etc/wsl.conf` 和 `/etc/resolv.conf`。

apt 不会走 SOCKS5：本链路给 WSL 暴露的是 HTTP 代理端口 `17898`，让 apt/npm/curl/Codex 都可用。

## 验证顺序

1. Mac: `scripts/mac/diagnose.sh`
2. Windows: `powershell -ExecutionPolicy Bypass -File scripts\windows\diagnose.ps1`
3. WSL: `scripts/wsl/diagnose.sh`
4. 远端 Windows 任意项目目录: `codex --version`
5. 远端 Windows 项目目录: `codex`
