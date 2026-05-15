# 安全说明

不要提交：

- SSH 私钥
- Codex `auth.json`
- OpenAI token
- EZ4Connect 密码
- EZ4Connect `config.ini`，里面可能有 base64 形式保存的密码
- `zjuconnect.log` 原文

本项目只保留模板和脚本。真实配置建议放：

```text
~/.config/codex-bridge/env
```

远端 Windows 的 `codex` 默认是 YOLO，会跳过确认并关闭沙盒。只在你信任的项目目录里使用。
