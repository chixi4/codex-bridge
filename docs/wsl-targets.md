# WSL 目标选择

不要只根据 WSL distro 的名字判断它能不能跑项目。先检查真实依赖。

## 检查命令

Windows：

```powershell
wsl -l -v
```

检查某个 distro 里是否有 Codex：

```powershell
wsl -d Ubuntu-20.04 -- bash -lc "command -v codex; codex --version"
```

检查旧 Isaac Gym：

```powershell
wsl -d Ubuntu-20.04 -- bash -lc "/opt/conda/bin/python - <<'PY'
import importlib.util as u
print('isaacgym', u.find_spec('isaacgym'))
print('isaaclab', u.find_spec('isaaclab'))
print('isaacsim', u.find_spec('isaacsim'))
PY"
```

## 当前机器结论

当前 T1 旧训练栈应该指向：

```text
WSL_DISTRO=Ubuntu-20.04
```

原因：

```text
Ubuntu-20.04:
  /opt/conda/bin/python 能 import isaacgym
  /opt/isaacgym 存在

IsaacLab-22.04:
  import isaaclab -> None
  import isaacsim -> None
  import isaacgym -> None
```

如果以后真的迁移到 NVIDIA Isaac Lab，需要单独在目标 distro 安装 Isaac Sim / Isaac Lab，并迁移旧 `booster_gym` 代码；不要把 distro 名字当成迁移完成。
