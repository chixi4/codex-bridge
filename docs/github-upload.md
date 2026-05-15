# GitHub 上传

上传前在项目根目录检查：

```bash
bash scripts/check.sh
```

第一次上传：

```bash
cd codex-bridge
git init
git add .
git commit -m "Add Codex Bridge"
git branch -M main
git remote add origin https://github.com/<you>/<repo>.git
git push -u origin main
```

如果要放进已有仓库，直接把整个 `codex-bridge` 文件夹作为一个子目录提交即可。

建议传：

```text
README.md
docs/
scripts/
config/
config.example.env
.gitignore
```

不要传：

```text
~/.ssh/
~/.codex/
auth.json
EZ4Connect 原始日志
任何真实密码或 token
```
