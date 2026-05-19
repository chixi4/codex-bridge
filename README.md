# Codex Bridge

让一台远端 Windows/WSL 机器在不安装翻墙软件的情况下，借用 Mac 上的代理联网，并在远端 WSL 里运行 Codex。

这个仓库是一个实验性运维桥，不绑定某个代码项目。它的默认假设是：Mac 负责科学上网和浏览器登录，Windows 负责 SSH 入口，真正的开发/训练环境在 WSL。

当前链路：

```text
Mac 校园网直连 -> SSH 到 Windows 10.251.1.15
Mac Clash/Mixed 7897 -> SSH 反向隧道 -> Windows 127.0.0.1:17897
Windows portproxy -> WSL 网关 172.17.x.1:17898
WSL codex wrapper -> OpenAI / npm / Google
```

离开校园网时，SSH 这一层可以切回 `SSH_PROXY_MODE=socks`，通过 EZ4Connect SOCKS `127.0.0.1:11080` 访问 Windows。

## 日常使用

Mac 上校园网直连时确认：

```bash
nc -zv 10.251.1.15 22
nc -zv 127.0.0.1 7897
win-codex-diagnose
```

如果离开校园网，需要先切回 EZ4Connect 模式并确认 SOCKS 在：

```bash
# 把 ~/.config/codex-bridge/env 里的 SSH_PROXY_MODE 改成 socks
ez4-vpn status
nc -zv 127.0.0.1 11080
```

从 Mac 连远端 Windows：

```bash
win-ssh
```

在远端 Windows 里进入任意项目目录后直接启动 Codex：

```bat
cd C:\Users\Administrator\Documents\dev\2T1
codex
```

远端 `codex` 默认就是 YOLO：

```text
codex --dangerously-bypass-approvals-and-sandbox
```

远端 `codex` 默认还会放进 WSL tmux 会话。Mac 切 Wi-Fi/热点导致 SSH 断开时，Codex 进程仍留在远端；网络恢复后重新 `win-ssh`，回到同一个项目目录再运行 `codex`，会接回原来的会话。临时不想用 tmux 时：

```bat
codex --no-tmux
```

管理远端 Codex tmux 会话：

```bat
codex --tmux-list
codex --tmux-kill-current
codex --tmux-kill codex_xxxxxxxxxxxx
codex --tmux-kill-all
```

需要保守模式时：

```bat
codex --safe
```

## 登录

本机 Mac 不劫持 `codex` 命令。远端 Codex 登录统一用：

```bash
win-codex login
win-codex reauth
win-codex hard-reauth
win-codex status
win-codex logout
```

`win-codex login` 会在 Mac 上开 `localhost:1455` 到远端 WSL 的临时回调隧道，并自动打开本机浏览器登录 OpenAI/Google。

`win-codex reauth` 用于 Mac 本机 `codex logout/login` 之后远端旧 Codex 报 token 被撤销的情况：它会清掉主力远端 WSL 的旧 `auth.json`，杀掉旧的 `codex_*` tmux 会话，然后重新走一次网页登录。

`win-codex hard-reauth` 用于更顽固的登录异常，例如浏览器 OAuth 已经打开但远端报 `Token exchange failed`、或者登录后迟迟没有生成 `~/.codex/auth.json`。它会把远端 WSL 的整个 `~/.codex` 移到 `~/.codex-bridge-backups/codex-reset-<时间>`，创建干净的新 `~/.codex`，再重新走网页登录。

`win-codex logout` 默认移走远端 WSL 里的 `~/.codex/auth.json`，并杀掉旧的远端 Codex tmux 会话；它不会运行 Mac 本机的 `codex logout`，也尽量避免影响同账号的 Mac Codex app/CLI。只有明确要执行上游 Codex 退出登录时才用：

```bash
win-codex logout --revoke
```

如果只是想忘记 auth、暂时保留远端 tmux 会话：

```bash
win-codex logout --keep-tmux
```

## EZ4Connect 稳定性

校园网直连时不需要开 EZ4Connect；它只是离校或无法直连 `10.251.1.15:22` 时的备用 SSH 入口。

`ez4-vpn start` / `ez4-vpn restart` 会打开一个带 terminal-loop + supervisor 的 EZ4Connect 终端。如果 `zju-connect` 因 `panic: EOF` 崩溃，supervisor 会自动重启它；如果 supervisor 自己异常退出，terminal-loop 会把 supervisor 再拉起来。如果重启需要短信验证码，就在那个终端里输入验证码。

```bash
ez4-vpn status
ez4-vpn restart
ez4-vpn stop
```

这不会让已经断掉的 SSH 原地复活，也不能修复 `zju-connect` 上游的 gvisor 崩溃 bug，但能避免 VPN 崩溃后一直停在 `11080` 不监听的状态。

## 安装

Mac：

```bash
cd codex-bridge
bash scripts/mac/install-mac-tools.sh
```

如果是全新机器，并且没有旧的同端口隧道，再启动后台隧道：

```bash
bash scripts/mac/install-mac-tools.sh --start
```

如果 EZ4Connect GUI 启动的 `zju-connect` 带了 `-disable-keep-alive`，用受控启动器替代：

```bash
ez4-vpn restart
```

它会开一个新的 Terminal，直接运行 `zju-connect`，沿用 EZ4Connect 配置文件里的账号/服务器，但不会默认关闭 keepalive。需要短信验证码时就在那个窗口里输入。

Windows PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\windows\setup-portproxy.ps1
powershell -ExecutionPolicy Bypass -File scripts\windows\install-codex-wrapper.ps1
```

WSL：

```bash
sudo bash scripts/wsl/install-wsl-network.sh
sudo -E bash scripts/wsl/install-codex-cli.sh
```

先在 `~/.config/codex-bridge/env` 里把 `WSL_DISTRO` 指到真正有项目依赖的 WSL。不要只看 distro 名字；例如当前 T1/IsaacGym 旧训练栈在 `Ubuntu-20.04`，不是那个名字叫 `IsaacLab-22.04` 的空环境。

第一次安装后检查：

```bash
win-codex-diagnose
```

## 空闲后输不进字

这通常是 SSH 半断：画面还在，但输入通道死了。不要继续等，开新窗口用 `win-ssh` 重新连。`win-ssh` 已经带 keepalive，后续会话要么保持活跃，要么快速断开，不会长期假活。

## 查看完整回复

不要依赖 Mac 终端原生滚动条看 Codex 长回复。按 `Ctrl+T` 打开 transcript/pager，然后用 `Ctrl+U` / `Ctrl+D` 上下半页滚动，按 `q` 回主界面。

如果 Terminal 窗口左右边缘出现蓝灰色的 `[` / `]`，那是 macOS Terminal 的 line marks，不是远端输出。关闭方式：

```bash
defaults write com.apple.Terminal ShowLineMarks -bool false
```

也可以在 Terminal 菜单里选 `View -> Hide Marks`。

详细说明见 [docs/troubleshooting.md](docs/troubleshooting.md)。

## 文档

- [docs/operations.md](docs/operations.md): 最短运维手册。
- [docs/architecture.md](docs/architecture.md): 网络链路和控制流。
- [docs/troubleshooting.md](docs/troubleshooting.md): 断联、DNS、登录、滚动问题。
- [docs/current-machine-notes.md](docs/current-machine-notes.md): 当前机器实际落点。
- [docs/wsl-targets.md](docs/wsl-targets.md): 如何选择正确的 WSL 目标。
- [docs/ai-handoff.md](docs/ai-handoff.md): 交给另一个 AI 时先读这个。
- [docs/github-upload.md](docs/github-upload.md): 上传 GitHub 前的检查和命令。
