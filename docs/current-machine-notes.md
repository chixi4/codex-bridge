# 当前机器记录

这份记录是为了让未来的你或另一个 AI 迅速接上当前状态。不要在这里写密码、token、私钥内容。

## Mac

- EZ4Connect SOCKS: `127.0.0.1:11080`
- 本机互联网代理: `127.0.0.1:7897`
- SSH key: `~/.ssh/nvidia_garlic_node05_vllm`
- 远端入口: `win-ssh`
- 远端 Codex 登录入口: `win-codex login/status/logout`
- 反向隧道: Mac `127.0.0.1:7897` -> Windows `127.0.0.1:17897`
- `win-codex logout` 默认只忘记远端 WSL auth，不会退出 Mac 本机 Codex。

EZ4Connect 配置建议：

```ini
AutoReconnect=true
KeepAlive=true
```

已见过的断联日志特征：

```text
panic: EOF
connection reset by peer
```

## Windows

- Host: `10.251.1.15`
- User: `administrator`
- WSL distro for old T1/IsaacGym work: `Ubuntu-20.04`
- WSL distro previously used only for Codex experiments: `IsaacLab-22.04`
- Codex wrapper: `C:\Users\Administrator\bin\codex.cmd`
- 兼容快捷入口: `C:\Users\Administrator\bin\cx.cmd`
- Windows portproxy: `<WSL gateway>:17898 -> 127.0.0.1:17897`
- 夜间断连曾定位到 Windows 蓝屏/异常重启，而不是 Windows Update：`2026-05-15 22:33` 启动前有 `Kernel-Power 41`、`EventLog 6008`、BugCheck `0x3B`；5 月 9/10/11 多次 BugCheck `0x113`，伴随大量 `nvlddmkm` 事件和 `C:\Windows\LiveKernelReports\WATCHDOG...dmp`，优先怀疑 NVIDIA/图形栈/GPU watchdog。

远端 Windows 使用方式：

```bat
cd C:\Users\Administrator\Documents\dev\2T1
codex
```

这会进入当前目录对应的 WSL 路径，默认 YOLO。长回复用 `Ctrl+T` 打开 transcript/pager 查看。

## WSL

当前机器上见过两个 WSL：

```text
Ubuntu-20.04      有 /opt/conda 和 /opt/isaacgym，能跑旧 T1/IsaacGym。
IsaacLab-22.04    名字像 Isaac Lab，但实测没有 isaaclab/isaacsim/isaacgym。
```

- Proxy wrapper: `/usr/local/bin/codex`
- Raw Codex CLI: `/opt/node-current/bin/codex`
- Check command: `/usr/local/bin/win-net-check`
- DNS 固定在 `/etc/resolv.conf`
- `/etc/wsl.conf` 禁止 WSL 自动重写 DNS

代理环境由 `/usr/local/bin/codex` 动态设置：

```text
HTTP_PROXY=http://<wsl_gateway>:17898
HTTPS_PROXY=http://<wsl_gateway>:17898
ALL_PROXY=socks5h://<wsl_gateway>:17898
```

## 登录状态

当前远端 Codex 使用网页登录方式，设备码登录在 Team 里被禁用。之后如果掉登录：

```bash
win-codex login
```

不要使用：

```bash
codex login --device-auth
```
