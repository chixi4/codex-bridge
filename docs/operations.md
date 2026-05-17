# 运维手册

## 1. 启动前检查

Mac：

```bash
ez4-vpn status
nc -zv 127.0.0.1 11080
nc -zv 127.0.0.1 7897
win-codex status
win-codex-diagnose
```

如果后台隧道没有运行：

```bash
launchctl load ~/Library/LaunchAgents/com.codex-bridge.wsl-macproxy.plist
```

如果这是从旧 T1 隧道迁移来的机器，先确认没有两个隧道抢 `17897`。

远端 WSL：

```bash
win-net-check
```

## 2. 进入远端

Mac：

```bash
win-ssh
```

Windows：

```bat
cd C:\Users\Administrator\Documents\dev\你的项目
codex
```

`codex` 会在当前 Windows 目录对应的 WSL 路径下启动，不会再二次询问目录，默认 YOLO。

如果 Terminal 窗口左右边缘有蓝灰色 `[` / `]`，那是 macOS Terminal 的 line marks。运行 `defaults write com.apple.Terminal ShowLineMarks -bool false`，或菜单 `View -> Hide Marks`。

看完整长回复时按 `Ctrl+T` 进入 transcript/pager，再用 `Ctrl+U` / `Ctrl+D` 上下半页滚动，按 `q` 回主界面。

## 3. 远端 Codex 登录

Mac：

```bash
win-codex login
win-codex reauth
win-codex status
```

如果登录掉了，不要用 device code。Team 禁用了 device code，走普通网页登录即可。

如果需要清掉远端登录态：

```bash
win-codex logout
```

它默认只移走远端 WSL 的 `auth.json`，不会退出 Mac 本机 Codex。只有明确要调用上游 Codex 退出登录时才用 `win-codex logout --revoke`。

如果你在 Mac 本地做过 `codex logout/login`，远端已经打开的 Codex TUI 可能因为服务端 token 轮换而报 auth 错误。先跑：

```bash
win-codex status
```

主力 WSL 仍显示 `Logged in using ChatGPT` 时，关掉旧远端窗口后重新 `codex resume` 即可。

如果旧窗口明确报 `Your access token could not be refreshed because your refresh token was revoked`，直接跑：

```bash
win-codex reauth
```

然后重新打开远端项目里的 `codex resume`。这个命令不会让已经开着的 Codex TUI 热更新，只负责给主力远端 WSL 重新拿一份 auth。

如果登录成功但 `resume` 里看不到旧会话，通常是旧 session 留在另一个 WSL：

```bash
win-codex migrate-sessions IsaacLab-22.04 Ubuntu-20.04
```

## 4. EZ4Connect 设置

建议在 EZ4Connect 配置里保持：

```ini
AutoReconnect=true
KeepAlive=true
```

当前排查发现 `KeepAlive=false` 会让 `zju-connect` 启动时带 `-disable-keep-alive`，长时间空闲更容易被 VPN 网关 reset。

如果 `ez4-vpn status` 发现当前进程仍然带 `-disable-keep-alive`，直接切到受控启动：

```bash
ez4-vpn restart
```

如果 `ez4-vpn status` 显示进程在但 `11080/11081` 没有监听，并提示 `waiting for an SMS code`，说明 VPN 还停在短信验证码阶段。去新开的 EZ4Connect 终端输入短信验证码，端口起来之后再继续 `win-ssh`。

## 5. 夜间断连/重启后恢复

先分清是 Mac 侧 VPN 掉了，还是远端 Windows 真的重启了：

```bash
ez4-vpn status
win-reboot-report 96
```

`win-reboot-report` 会拉最近 96 小时的 Windows 启停、Kernel-Power、BugCheck、Windows Update 和 UpdateOrchestrator 事件。常见判断：

- `User32 1074`：有人或系统组件发起了正常重启，消息里通常会写 Windows Update 或进程名。
- `EventLog 6008` 或 `Kernel-Power 41`：非正常关机，偏向断电、蓝屏、强制重启或硬件/驱动问题。
- `WindowsUpdateClient` 搭配 `1074`：大概率是更新计划重启。

恢复顺序：

```bash
ez4-vpn restart
# 如果提示短信验证码，先在 EZ4Connect 终端输入验证码
win-ssh
win-codex status
win-codex reauth   # 仅当 Codex 报 token revoked 或未登录时需要
```

训练任务如果已经被远端重启杀掉，只能从最近 checkpoint 恢复；如果只是 SSH/VPN 断了，远端训练进程可能还在，重新 `win-ssh` 后先查任务管理器、日志或训练进度窗口，不要立刻重开同名训练。

## 6. 切 Wi-Fi/热点为什么会瞬断

`win-ssh` 是普通 SSH over SOCKS。Mac 切 Wi-Fi/热点时，旧网络接口和 EZ4Connect 到校园网的 TLS/TCP 会话可能被系统立即拆掉；这类 `EOF` 不是 keepalive 能救的。keepalive 只能处理“网络黑洞但 socket 还没关”的情况。

为了让体验可恢复，远端 Windows 的 `codex` 默认会把 Codex 放进 WSL tmux 会话。断线后：

```bash
win-ssh
```

然后在同一个 Windows 项目目录里：

```bat
codex
```

会重新 attach 到同一个远端会话。临时绕过 tmux：

```bat
codex --no-tmux
```

管理已经存在的 Codex tmux 会话：

```bat
codex --tmux-list
codex --tmux-kill-current
codex --tmux-kill codex_xxxxxxxxxxxx
codex --tmux-kill-all
```

日常建议：

- 想临时离开但保留会话：`Ctrl-b` 然后按 `d` detach。
- 想关掉当前项目目录的 Codex 会话：在该目录运行 `codex --tmux-kill-current`。
- 想清理全部 Codex tmux 会话：确认没有重要对话在跑，再运行 `codex --tmux-kill-all`。

tmux 能长期保留远端进程，时间上主要受 Windows/WSL 是否重启、tmux 进程是否被杀、Codex 自己是否崩溃限制。它不能让远端在 Mac 完全离线时继续访问 OpenAI；Mac 离线期间，远端训练可以继续跑，但 Codex 发消息、联网搜索、npm/pip 走代理等网络动作会失败或卡到超时。Mac 网络恢复后，反向代理隧道需要重新连上，随后重新 attach tmux 就能继续。

## 7. 半断窗口处理

现象：

```text
Codex 页面还在，但数字、英文、中文都输不进去。
重开窗口就好了。
```

处理：

```text
直接关掉旧窗口，重新 win-ssh。
```

预防：

```text
总是用 win-ssh，不要手敲裸 ssh。
```

## 8. 上传前检查

不要把真实密钥、Codex 登录态、EZ4Connect 日志原文传上去：

```bash
bash scripts/check.sh
```
