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

看完整长回复时按 `Ctrl+T` 进入 transcript/pager，再用 `Ctrl+U` / `Ctrl+D` 上下半页滚动，按 `q` 回主界面。

## 3. 远端 Codex 登录

Mac：

```bash
win-codex login
win-codex status
```

如果登录掉了，不要用 device code。Team 禁用了 device code，走普通网页登录即可。

如果需要清掉远端登录态：

```bash
win-codex logout
```

它默认只移走远端 WSL 的 `auth.json`，不会退出 Mac 本机 Codex。只有明确要调用上游 Codex 退出登录时才用 `win-codex logout --revoke`。

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

这会先退出 EZ4Connect GUI，避免 GUI 用旧参数重新拉起子进程；然后停止现有 `zju-connect`，打开一个新 Terminal 运行不带 `-disable-keep-alive` 的启动命令。启动器默认还会优先把 VPN 域名解析到 IPv4，绕开目前见过的 IPv6/gVisor `panic: EOF` 路径。短信验证码仍然需要你在新窗口里输入。

## 5. 半断窗口处理

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

## 6. 上传前检查

不要把真实密钥、Codex 登录态、EZ4Connect 日志原文传上去：

```bash
bash scripts/check.sh
```
