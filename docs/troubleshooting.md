# 故障排查

## Codex 长回复不好回看

不要依赖 Mac 终端原生滚动条。Codex 的主界面和 transcript 是 TUI 内部管理的，终端 scrollback 不一定包含完整内容。

正确方式：

```text
Ctrl+T    打开 transcript/pager
Ctrl+U    上半页
Ctrl+D    下半页
↑/↓       小幅滚动
pgup/pgdn 上下翻页
q         回到主界面
```

左右边缘的蓝灰色 `[` / `]` 不是 Codex，也不是远端 Windows/WSL 输出，而是 macOS Terminal 的 line marks。验证路径：

```bash
strings /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal | rg 'ShowLineMarks|Hide Marks'
```

关闭：

```bash
defaults write com.apple.Terminal ShowLineMarks -bool false
```

或者在 Terminal 菜单里选 `View -> Hide Marks`。如果当前窗口没有立刻刷新，开一个新 Terminal 窗口即可。

已经试过但无效的方向：

```text
--no-alt-screen
tui.alternate_screen="always"
CODEX_TUI_MODE=native/alternate/inline
Mac -> Windows SSH -> WSL sshd 的直连 Linux pty
```

这些实验都证明问题不在 Codex TUI 参数，也不在 Windows `cmd/conhost`。

## 画面还在但完全输不进去

最可能是 SSH 半断。无论是直连校园网还是 EZ4Connect/SOCKS/VPN 路径，底层 TCP 会话都可能没有立刻让终端知道，表现为界面停着但输入不进。

解决：

```text
关掉旧窗口，重新 win-ssh。
```

预防：

```bash
win-ssh
```

`win-ssh` 使用：

```text
ServerAliveInterval=60
ServerAliveCountMax=10
TCPKeepAlive=yes
```

如果链路坏了，大约 30 秒内会断开，避免长期假活。

## codex 在 Windows 里找不到

确认：

```bat
where codex
```

应能看到：

```text
C:\Users\Administrator\bin\codex.cmd
```

如果没有，把 `C:\Users\Administrator\bin` 加进用户 PATH，或者直接运行：

```bat
C:\Users\Administrator\bin\codex.cmd
```

## win-codex logout 会不会退出 Mac 账号

不会直接退出 Mac。本项目的 `win-codex logout` 只通过 SSH 进入远端 WSL，并移走远端 WSL 的 `~/.codex/auth.json`。它不会执行 Mac 本机的 `codex logout`，也不会删除 Mac 的 `~/.codex`。

可以在 Mac 上验证：

```bash
codex login status
```

如果你在同一个 OpenAI/ChatGPT 账号上频繁登录/退出不同 Codex 客户端，服务端 token 刷新有时会让另一个客户端要求重新登录。为了降低这种互相干扰，默认 `win-codex logout` 不再调用上游 `codex logout`，只做远端本地忘记登录。只有明确要真正执行上游退出登录时才用：

```bash
win-codex logout --revoke
```

## Mac 退出/重新登录后远端像是也掉了

这通常不是本项目脚本删除了远端登录文件，而是 OpenAI/ChatGPT OAuth 的服务端 token 被轮换或撤销后，已经开着的远端 Codex TUI 进程没有热更新新 token。

典型红字是：

```text
Your access token could not be refreshed because your refresh token was revoked.
```

这个现象可以发生在远端 `~/.codex/auth.json` 仍然存在、`win-codex status` 仍显示登录的情况下。原因是旧 TUI 进程手里缓存的是被服务端撤销的 refresh token；它不会因为磁盘上的 auth 文件后来变了就自动恢复。

判断顺序：

```bash
codex login status
win-codex status
win-ssh
```

如果 `win-codex status` 里主力 WSL 显示 `Logged in using ChatGPT`，远端并没有真正退出。旧的 Codex 窗口如果报 token/auth 错误，直接退出旧窗口，重新进入项目后运行：

```bat
codex resume
```

或者重新运行：

```bat
codex
```

如果 `win-codex status` 显示未登录，再从 Mac 跑：

```bash
win-codex login
```

如果你刚在 Mac 本地执行过 `codex logout/login`，或者不确定远端 token 是否已经被服务端撤销，用更直接的恢复命令：

```bash
win-codex reauth
```

它会清理远端 auth、杀掉旧的 `codex_*` tmux 会话，再重新网页登录。完成后重新 `codex resume`。不要指望旧 TUI 热切换账号或热加载新 token；目前 Codex CLI 的稳定恢复方式就是重启 TUI 进程。

## WSL 不能联网

在 WSL：

```bash
win-net-check
```

应看到 Google/npm 返回 HTTP 200。失败时按顺序查：

```bash
ip route | awk '/default/ {print $3; exit}'
cat /etc/resolv.conf
```

Windows：

```powershell
netsh interface portproxy show all
```

应有类似：

```text
172.17.x.1:17898 -> 127.0.0.1:17897
```

Mac：

```bash
nc -zv 127.0.0.1 11080
nc -zv 127.0.0.1 7897
```

## apt 不能走 SOCKS5

apt 不认识 SOCKS5，但本项目暴露给 WSL 的 `17898` 是 HTTP 可用的代理入口。如果需要让 apt 也走这条链路：

```bash
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
sudo tee /etc/apt/apt.conf.d/95codex-bridge-proxy >/dev/null <<EOF
Acquire::http::Proxy "http://${HOST_IP}:17898/";
Acquire::https::Proxy "http://${HOST_IP}:17898/";
EOF
```

如果只是清华源等国内源，DNS 修好后也可以不配 apt 代理。

## EZ4Connect 断联

日志：

```text
~/Library/Application Support/EZ4Connect/zjuconnect.log
```

真正致命的模式：

```text
Error occurred while receiving, retrying: ... connection reset by peer
panic: EOF
github.com/mythologyli/zju-connect/stack/gvisor.(*Stack).Run
```

大量 `[SOCKS5] connection reset by peer` 不一定是整体断线，可能只是单条连接重置。

快速检查：

```bash
ez4-vpn status
ez4-vpn log 120
```

建议设置：

```ini
AutoReconnect=true
KeepAlive=true
```

当前实际见过的致命栈：

```text
Error occurred while receiving, retrying: EOF
panic: EOF
github.com/mythologyli/zju-connect/stack/gvisor.(*Stack).Run
```

如果 `ez4-vpn status` 看到当前进程带 `-disable-keep-alive`，说明 GUI 实际启动参数没有采用你期望的 keepalive 设置。切到受控启动器：

```bash
ez4-vpn restart
```

它直接运行 `/Applications/EZ4Connect.app/Contents/MacOS/zju-connect`，默认不加 `-disable-keep-alive`，并且会把 VPN 域名优先解析成 IPv4，避免日志里这种容易崩的 IPv6 路径。当前版本还会启动 terminal-loop；如果 `zju-connect` 因 EOF/panic 崩溃后把内层 supervisor 也带退出，外层 terminal-loop 会继续重启 supervisor。

```text
Socket: connected to: [2001:250:219:a0ff::2]:443
panic: EOF
```

如果重启后还经常断，优先怀疑客户端 gVisor 栈稳定性，而不是 Codex 本身。

## device code 被禁用

不要用：

```bash
codex login --device-auth
```

使用：

```bash
win-codex login
```

## 登录成功但会话历史为空

Codex 登录态和对话 session 都在各自 WSL 的 `~/.codex` 下。切换默认 WSL 后，可能出现新环境已登录，但旧 session 仍在另一个 distro 里的情况。

检查：

```bash
win-codex status
```

把旧 session 导入当前默认 WSL：

```bash
win-codex migrate-sessions IsaacLab-22.04 Ubuntu-20.04
```

这个命令只复制 `sessions/` 和 `history.jsonl`，不会覆盖目标 WSL 当前有效的 `auth.json`。

## 每天夜里像是远端重启/断连

先不要直接判断是远端 Windows 重启。按这个顺序看：

```bash
ez4-vpn status
win-reboot-report 96
```

如果 `ez4-vpn status` 显示 `zju-connect is running but the SOCKS port is not listening yet`，并提示等待短信验证码，说明是 Mac 侧 EZ4Connect 没完成登录，SSH 一定连不上。去 EZ4Connect 终端输入短信验证码。

如果 `win-reboot-report` 里看到：

- `User32 1074`：正常计划重启，看 `Message` 里的发起进程和原因。
- `WindowsUpdateClient` 加 `User32 1074`：大概率 Windows Update 自动重启。
- `EventLog 6008` 或 `Kernel-Power 41`：非正常关机/断电/崩溃，需要看蓝屏、驱动、电源和硬件。
- 多次 `BugCheck 0x113`、大量 `nvlddmkm`，或 `LiveKernelReports\WATCHDOG*.dmp`：优先按 NVIDIA/显卡驱动/图形栈 watchdog 排查。

恢复顺序：

```bash
# 学校内网直连时不需要 ez4-vpn；离校用 socks 模式时才先 ez4-vpn restart
win-ssh
win-codex status
win-codex reauth
```

最后一步只有 Codex 登录真的坏了才需要。训练任务恢复时优先找最新 checkpoint 和日志，不要在不确认旧进程是否还在时重复开训练。

## 切 Wi-Fi/热点一瞬间就断

这是普通 SSH 的物理限制：Mac 切网络接口时，旧 TCP socket 可能被立即关闭；如果还走 EZ4Connect，VPN socket 也可能一起被拆。`ServerAliveInterval` 只能延迟“没回包”的超时，不能让已经被系统关闭的 socket 迁移到新网络。

解决目标不是“原连接不断”，而是“断了立刻接回远端状态”。远端 Windows 的 `codex` 默认使用 WSL tmux：

```bat
codex
```

断线后重新：

```bash
win-ssh
```

回到同一个项目目录再运行：

```bat
codex
```

会 attach 回同一个 tmux 会话。临时不用 tmux：

```bat
codex --no-tmux
```

管理 tmux 会话：

```bat
codex --tmux-list
codex --tmux-kill-current
codex --tmux-kill codex_xxxxxxxxxxxx
codex --tmux-kill-all
```

tmux 只能保证远端 TUI 进程不因 SSH 断开而退出。Mac 断网期间，远端训练可以继续，但远端 Codex 访问 OpenAI 仍依赖 Mac 代理和反向隧道；如果它正在生成回复或执行联网操作，可能会报网络错误。Mac 恢复联网后重新 `win-ssh` 并 attach 回 tmux，会话本身还在。

如果你确认自己在某个 Windows 项目目录里运行了 `codex`，但 Codex 顶部仍显示 `directory: ~` 或 `/resume` 只看到 `/root` 的历史，说明可能 attach 到了旧 wrapper 创建的 tmux 会话。先在 WSL 查看：

```bash
tmux list-panes -a -F 'session=#{session_name} cwd=#{pane_current_path} cmd=#{pane_current_command}'
```

杀掉错误目录对应的会话后再从 Windows 项目目录运行 `codex`，新 wrapper 会显式传 `--cd <当前 WSL 目录>`。
