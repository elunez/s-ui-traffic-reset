# s-ui 流量自动重置脚本

专为 `s-ui` 面板（新版多用户架构）打造的轻量级自动化脚本。用于 **每月自动清零流量**，并在清零后 **重启 s-ui 面板服务** 以加载新数据。

## ✨ 核心功能

### 🔄 流量自动清零 (sui-reset.sh)
- **深度清理**：不仅重置 `clients` 表中的用户上传/下载配额，同时清空 `stats` 表中的仪表盘历史统计图表。
- **自动备份**：每次清零前自动将数据库安全备份至 `/usr/local/s-ui/db/` 目录。
- **定时触发**：默认每月 1 号凌晨 00:00 自动执行。
- **服务重启**：流量清零成功后仅重启 `s-ui` 面板服务，不重启服务器。
- **依赖补全**：自动检测并补齐 `sqlite3` 与 `cron/crontab`，兼容常见 Linux 发行版。

---

## 🚀 一键部署命令

请务必使用 **root 用户** 登录终端。直接点击下方代码块右上角的复制按钮，粘贴到终端回车即可运行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/elunez/s-ui-traffic-reset/main/sui-reset.sh)
```

---

## 🛠️ 常用检查命令

部署完成后，可使用以下命令核验状态：

- **查看当前已生效的定时任务：**
  ```bash
  crontab -l
  ```

- **查看流量清零执行日志：**
  ```bash
  cat /root/s-ui-reset.log
  ```

---

## ⚠️ 注意事项

1. **复制报错处理**：如果在终端粘贴后提示 `-bash: syntax error near unexpected token '('`，说明你复制时误选了网页的超链接格式。请务必**只复制纯文本代码**（推荐直接点击代码框的 Copy 按钮）。
2. **默认路径说明**：本脚本默认你的 s-ui 面板数据库路径为 `/usr/local/s-ui/db/s-ui.db`。如果你的安装路径非默认，请先 Fork 本仓库，修改 `sui-reset.sh` 首行的 `DB_PATH` 变量后再运行。
