# s-ui 自动化运维脚本 (Traffic Reset & Auto Reboot)

这是一个专为 `s-ui` 面板（支持多用户新版架构）编写的轻量级自动化运维工具库。包含两个核心功能：**每月自动清零 s-ui 流量** 和 **每天定时校准中国时区并重启服务器**。

## 🌟 功能特性

* **完全适配新版 s-ui 数据库**：完美兼容将流量数据记录在 `clients` 表和 `stats` 表的新版架构，不仅清空用户配额，还会一并清空仪表盘统计图表历史。
* **自动依赖检测与安装**：脚本运行前会自动检查并安装 `sqlite3`、`cron` 等必要组件，即便是极简版 Ubuntu 系统也能顺利运行，无需手动干预。
* **精准的中国时区校准**：自动将服务器系统时间同步为 `Asia/Shanghai` (UTC+8)，确保所有定时任务严格按照北京时间执行，告别时差烦恼。
* **纯净一键执行**：代码通过网络直接拉取到内存中执行，无多余残留文件，安全、干净、高效。

## 🚀 一键部署教程

请确保使用 **`root` 用户** 登录您的 Linux 服务器（VPS），直接复制以下对应功能的命令，在终端回车运行即可自动完成所有配置。

### 1. s-ui 流量每月自动清零脚本
**功能**：立即清零当前流量，并设置每月 1 号的凌晨 00:00 自动将所有面板用户的上传/下载流量归零，随后自动重启面板生效。

```bash
bash <(curl -Ls [https://raw.githubusercontent.com/zqh2333/s-ui-traffic-reset/main/sui-reset.sh](https://raw.githubusercontent.com/zqh2333/s-ui-traffic-reset/main/sui-reset.sh))
