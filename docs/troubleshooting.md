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

曾经试过默认加 `--no-alt-screen`，但副作用是退出 transcript 后主界面变得很空，不像 Codex 原生界面。后来又试过强制 `tui.alternate_screen="always"`，能改善退出 transcript 后空屏的问题，但在 Windows conhost/SSH/Mac 终端这条链路上仍可能留下边缘 `[` / `]`。

现在默认让 Codex 使用原生 TUI，不额外强制 alternate screen。若画面边缘仍出现很多 `[` / `]`，通常是终端和 TUI 重绘状态不一致，不代表上文丢了。先退出当前 Codex，重新运行一次 `codex`。如果还想试不同显示策略，可以在 WSL 里临时设置：

```bash
CODEX_TUI_MODE=native codex      # 默认，最接近官方 CLI
CODEX_TUI_MODE=alternate codex   # 强制 alternate screen
CODEX_TUI_MODE=inline codex      # 让输出更接近普通 scrollback
```

如果是从 Windows `cmd` 里启动，优先先用默认 `codex`；这个项目不再默认强行加 `--no-alt-screen`。

## 画面还在但完全输不进去

最可能是 SSH 半断。EZ4Connect/SOCKS/VPN 路径断开时，TCP 会话可能没有立刻让终端知道，表现为界面停着但输入不进。

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
ServerAliveInterval=15
ServerAliveCountMax=2
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

它直接运行 `/Applications/EZ4Connect.app/Contents/MacOS/zju-connect`，默认不加 `-disable-keep-alive`，并且会把 VPN 域名优先解析成 IPv4，避免日志里这种容易崩的 IPv6 路径：

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
