#!/bin/bash
# 脚本：自动校准中国时区并设置每天凌晨3点重启

echo "=========================================="
echo "正在使用兼容模式配置定时重启任务..."
echo "=========================================="

if ! command -v cron &> /dev/null && ! command -v crontab &> /dev/null; then
    echo "[!] 检测到系统未安装 cron，正在自动安装..."
    apt-get update -y && apt-get install cron -y
    systemctl enable cron
fi
systemctl start cron &> /dev/null

echo "[!] 正在校准服务器时区为中国标准时间..."
if command -v timedatectl &> /dev/null; then
    timedatectl set-timezone Asia/Shanghai
else
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
fi

echo "[!] 正在写入中国时间凌晨 03:00 重启任务..."
CRON_CMD="0 3 * * * /sbin/reboot"
TMP_CRON="/tmp/current_cron_backup.txt"

crontab -l 2>/dev/null | grep -v "/sbin/reboot" > "$TMP_CRON"
echo "$CRON_CMD" >> "$TMP_CRON"
crontab "$TMP_CRON"
rm -f "$TMP_CRON"

if crontab -l 2>/dev/null | grep -q "/sbin/reboot"; then
    CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    echo "=========================================="
    echo "[✓] 配置彻底成功！"
    echo "1. 服务器当前时间: $CURRENT_TIME"
    echo "2. 自动重启任务已生效，将于每天 03:00 准时执行。"
    echo "=========================================="
else
    echo "[x] 任务写入仍然失败，请手动运行 apt install cron 检查环境。"
    exit 1
fi
