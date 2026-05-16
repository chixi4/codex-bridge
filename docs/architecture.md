# 架构

## 组件

Mac：

- EZ4Connect: `127.0.0.1:11080`，连校园/内网 Windows。
- Clash/Mixed proxy: `127.0.0.1:7897`，访问 OpenAI/Google/npm。
- `win-ssh`: 带 keepalive 的远端 SSH。
- `win-wsl-ssh`: 通过 Windows SSH 的 `nc` 管道直连 WSL sshd，绕过 Windows 控制台层。
- `wsl-mac-proxy-tunnel.sh`: 建立 Windows 反向端口 `17897`。
- `win-codex login`: 用本机浏览器完成远端 WSL Codex 登录。

Windows：

- OpenSSH Server。
- `netsh interface portproxy`: 把 WSL 可见地址转到 Windows localhost。
- `C:\Users\Administrator\bin\codex.cmd`: 当前目录启动 WSL Codex，默认 YOLO。

WSL：

- `/usr/local/bin/codex`: 设置 HTTP/HTTPS/ALL_PROXY 后调用真实 Codex CLI。
- `/usr/local/bin/codex-raw`: 指向真实 CLI。
- `/usr/local/bin/win-net-check`: 检查 DNS 和代理。
- `sshd` on `127.0.0.1:2222`: 只在 WSL 内部监听，由 `win-wsl-ssh` 按需启动。

## 数据流

```text
WSL codex
  -> HTTP_PROXY=http://<wsl_gateway>:17898
  -> Windows portproxy
  -> Windows 127.0.0.1:17897
  -> SSH -R 17897:127.0.0.1:7897
  -> Mac Clash 127.0.0.1:7897
  -> Internet
```

## 控制流

```text
Mac win-ssh
  -> EZ4Connect SOCKS 127.0.0.1:11080
  -> Windows SSH
  -> Windows cmd
  -> codex.cmd
  -> wsl.exe -d <WSL_DISTRO>
  -> /usr/local/bin/codex
```

Codex TUI 直连路径：

```text
Mac win-wsl-ssh
  -> EZ4Connect SOCKS 127.0.0.1:11080
  -> Windows SSH ProxyCommand
  -> wsl.exe -d <WSL_DISTRO> -- nc 127.0.0.1 2222
  -> WSL sshd
  -> Linux pty
  -> /usr/local/bin/codex
```
