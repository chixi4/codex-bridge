# Codex Bridge

让一台远端 Windows/WSL 机器在不安装翻墙软件的情况下，借用 Mac 上的代理联网，并在远端 WSL 里运行 Codex。

这个仓库是一个实验性运维桥，不绑定某个代码项目。它的默认假设是：Mac 负责科学上网和浏览器登录，Windows 负责 SSH 入口，真正的开发/训练环境在 WSL。

当前链路：

```text
Mac EZ4Connect SOCKS 11080 -> SSH 到 Windows 10.251.1.15
Mac Clash/Mixed 7897 -> SSH 反向隧道 -> Windows 127.0.0.1:17897
Windows portproxy -> WSL 网关 172.17.x.1:17898
WSL codex wrapper -> OpenAI / npm / Google
```

## 日常使用

Mac 上确认 EZ4Connect 和 Clash 在：

```bash
nc -zv 127.0.0.1 11080
nc -zv 127.0.0.1 7897
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

需要保守模式时：

```bat
codex --safe
```

## 登录

本机 Mac 不劫持 `codex` 命令。远端 Codex 登录统一用：

```bash
win-codex login
win-codex status
win-codex logout
```

`win-codex login` 会在 Mac 上开 `localhost:1455` 到远端 WSL 的临时回调隧道，并自动打开本机浏览器登录 OpenAI/Google。

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

这通常是 SSH 经过 EZ4Connect/SOCKS 后半断：画面还在，但输入通道死了。不要继续等，开新窗口用 `win-ssh` 重新连。`win-ssh` 已经带 keepalive，后续会话要么保持活跃，要么快速断开，不会长期假活。

## 查看完整回复

不要依赖 Mac 终端原生滚动条看 Codex 长回复。按 `Ctrl+T` 打开 transcript/pager，然后用 `Ctrl+U` / `Ctrl+D` 上下半页滚动，按 `q` 回主界面。

详细说明见 [docs/troubleshooting.md](docs/troubleshooting.md)。

## 文档

- [docs/operations.md](docs/operations.md): 最短运维手册。
- [docs/architecture.md](docs/architecture.md): 网络链路和控制流。
- [docs/troubleshooting.md](docs/troubleshooting.md): 断联、DNS、登录、滚动问题。
- [docs/current-machine-notes.md](docs/current-machine-notes.md): 当前机器实际落点。
- [docs/wsl-targets.md](docs/wsl-targets.md): 如何选择正确的 WSL 目标。
- [docs/ai-handoff.md](docs/ai-handoff.md): 交给另一个 AI 时先读这个。
- [docs/github-upload.md](docs/github-upload.md): 上传 GitHub 前的检查和命令。
