# s-ui 自动化运维工具箱 (Traffic Reset & Auto Reboot)

专为 `s-ui` 面板（新版多用户架构）打造的轻量级自动化脚本库。包含 **每月流量自动清零** 与 **每日定时重启** 两个独立模块。

## ✨ 核心功能

### 🔄 1. 流量自动清零 (sui-reset.sh)
- **深度清理**：不仅重置 `clients` 表中的用户上传/下载配额，同时清空 `stats` 表中的仪表盘历史统计图表。
- **自动备份**：每次清零前自动将数据库安全备份至 `/usr/local/s-ui/db/` 目录。
- **定时触发**：默认每月 1 号凌晨 00:00 自动执行并重启面板加载新数据。

### ⚡ 2. 每日定时重启 (reboot.sh)
- **时区校准**：自动强制锁定服务器系统时间为 `Asia/Shanghai` (中国标准时间 UTC+8)。
- **准时释放**：每天凌晨 03:00 准时重启服务器，清理内存碎片，保障代理节点持续稳定。
- **依赖补全**：自动检测并补齐精简版 Ubuntu/Debian 系统的 `cron` 定时组件。

---

## 🚀 一键部署命令

请务必使用 **`root` 用户** 登录终端。直接点击代码块右上角的复制按钮，粘贴到终端回车即可运行：

### 模块 A：仅配置【流量每月清零】
```bash
bash <(curl -Ls [https://raw.githubusercontent.com/zqh2333/s-ui-traffic-reset/main/sui-reset.sh](https://raw.githubusercontent.com/zqh2333/s-ui-traffic-reset/main/sui-reset.sh))

---
### 模块 B：仅配置【服务器每日重启】
```bash
bash <(curl -Ls [https://raw.githubusercontent.com/zqh2333/s-ui-traffic-reset/main/reboot.sh](https://raw.githubusercontent.com/zqh2333/s-ui-traffic-reset/main/reboot.sh))
