#!/bin/bash
# 脚本：s-ui 流量自动重置与定时任务
DB_PATH="/usr/local/s-ui/db/s-ui.db"
SCRIPT_PATH="/root/s-ui-traffic-reset.sh"
LOG_PATH="/root/s-ui-reset.log"

echo "=========================================="
echo "开始配置 s-ui 流量一键自动重置..."
echo "=========================================="

# 生成被定时执行的清理脚本
cat << 'SCRIPT_EOF' > $SCRIPT_PATH
#!/bin/bash
DB_PATH="/usr/local/s-ui/db/s-ui.db"
LOG_PATH="/root/s-ui-reset.log"

echo "==========================================" >> "$LOG_PATH"
echo "执行 s-ui 流量重置任务 - \$(date +'%Y-%m-%d %H:%M:%S')" >> "$LOG_PATH"

if ! command -v sqlite3 &> /dev/null; then
    echo "[!] 尝试安装 sqlite3..." >> "$LOG_PATH"
    if [ -x "\$(command -v apt)" ]; then apt update && apt install sqlite3 -y; elif [ -x "\$(command -v yum)" ]; then yum install sqlite3 -y; elif [ -x "\$(command -v dnf)" ]; then dnf install sqlite3 -y; fi
fi

if [ ! -f "$DB_PATH" ]; then
    echo "[x] 未找到数据库: $DB_PATH，任务终止。" >> "$LOG_PATH"
    exit 1
fi

BACKUP_PATH="${DB_PATH}.bak_\$(date +%Y%m%d%H%M%S)"
cp "$DB_PATH" "$BACKUP_PATH"

sqlite3 "$DB_PATH" "UPDATE clients SET up = 0, down = 0;"
SQL_CLIENT_STATUS=$?
sqlite3 "$DB_PATH" "DELETE FROM stats;"
SQL_STATS_STATUS=$?

if [ $SQL_CLIENT_STATUS -eq 0 ] && [ $SQL_STATS_STATUS -eq 0 ]; then
    echo "[✓] 数据库流量清零成功" >> "$LOG_PATH"
else
    echo "[x] 数据库操作失败" >> "$LOG_PATH"
    exit 1
fi

systemctl restart s-ui
if [ $? -eq 0 ]; then
    echo "[✓] s-ui 面板重启成功" >> "$LOG_PATH"
else
    echo "[x] s-ui 面板重启失败" >> "$LOG_PATH"
fi
echo "任务结束" >> "$LOG_PATH"
SCRIPT_EOF

# 赋予执行权限并加入定时任务
chmod +x $SCRIPT_PATH
CRON_CMD="0 0 1 * * /bin/bash $SCRIPT_PATH"

if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
    echo "[!] 定时任务已存在，无需重复添加。"
else
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "[✓] 定时任务添加成功 (每月1号0点执行)。"
fi

# 立即执行一次测试
/bin/bash $SCRIPT_PATH
tail -n 10 $LOG_PATH
echo "配置彻底完成！"
