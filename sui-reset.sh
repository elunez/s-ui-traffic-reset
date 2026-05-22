#!/bin/bash
# 脚本：s-ui 流量自动重置与定时任务
DB_PATH="/usr/local/s-ui/db/s-ui.db"
SCRIPT_PATH="/root/s-ui-traffic-reset.sh"
LOG_PATH="/root/s-ui-reset.log"

install_package() {
    PACKAGE_NAME="$1"

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y && apt-get install -y "$PACKAGE_NAME"
    elif command -v apt >/dev/null 2>&1; then
        apt update -y && apt install -y "$PACKAGE_NAME"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$PACKAGE_NAME"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$PACKAGE_NAME"
    elif command -v microdnf >/dev/null 2>&1; then
        microdnf install -y "$PACKAGE_NAME"
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache "$PACKAGE_NAME"
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install "$PACKAGE_NAME"
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm "$PACKAGE_NAME"
    else
        return 1
    fi
}

ensure_crontab() {
    if command -v crontab >/dev/null 2>&1; then
        return 0
    fi

    echo "[!] 未检测到 crontab，尝试自动安装 cron..."
    if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
        install_package cron
    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1 || command -v microdnf >/dev/null 2>&1; then
        install_package cronie
    elif command -v apk >/dev/null 2>&1; then
        install_package dcron
    elif command -v zypper >/dev/null 2>&1; then
        install_package cron
    elif command -v pacman >/dev/null 2>&1; then
        install_package cronie
    else
        echo "[x] 未找到支持的包管理器，请手动安装 cron/crontab 后重试。"
        exit 1
    fi

    if ! command -v crontab >/dev/null 2>&1; then
        echo "[x] crontab 自动安装后仍不可用，请手动安装 cron/crontab 后重试。"
        exit 1
    fi
}

start_cron_service() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable --now cron >/dev/null 2>&1 || systemctl enable --now crond >/dev/null 2>&1 || true
    elif command -v service >/dev/null 2>&1; then
        service cron start >/dev/null 2>&1 || service crond start >/dev/null 2>&1 || true
    elif command -v rc-service >/dev/null 2>&1; then
        rc-service dcron start >/dev/null 2>&1 || rc-service crond start >/dev/null 2>&1 || true
    fi
}

if [ "$(id -u)" -ne 0 ]; then
    echo "[x] 请使用 root 用户运行此脚本。"
    exit 1
fi

echo "=========================================="
echo "开始配置 s-ui 流量一键自动重置..."
echo "=========================================="

# 生成被定时执行的清理脚本
cat << 'SCRIPT_EOF' > "$SCRIPT_PATH"
#!/bin/bash
DB_PATH="/usr/local/s-ui/db/s-ui.db"
LOG_PATH="/root/s-ui-reset.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_PATH"
}

run_with_log() {
    "$@" >> "$LOG_PATH" 2>&1
}

install_sqlite3() {
    if command -v sqlite3 >/dev/null 2>&1; then
        return 0
    fi

    log "[!] 未检测到 sqlite3，尝试自动安装..."

    if command -v apt-get >/dev/null 2>&1; then
        run_with_log apt-get update -y && run_with_log apt-get install -y sqlite3
    elif command -v apt >/dev/null 2>&1; then
        run_with_log apt update -y && run_with_log apt install -y sqlite3
    elif command -v dnf >/dev/null 2>&1; then
        run_with_log dnf install -y sqlite
    elif command -v yum >/dev/null 2>&1; then
        run_with_log yum install -y sqlite
    elif command -v microdnf >/dev/null 2>&1; then
        run_with_log microdnf install -y sqlite
    elif command -v apk >/dev/null 2>&1; then
        run_with_log apk add --no-cache sqlite
    elif command -v zypper >/dev/null 2>&1; then
        run_with_log zypper --non-interactive install sqlite3
    elif command -v pacman >/dev/null 2>&1; then
        run_with_log pacman -Sy --noconfirm sqlite
    else
        log "[x] 未找到支持的包管理器，请手动安装 sqlite3 后重试。"
        return 1
    fi

    if command -v sqlite3 >/dev/null 2>&1; then
        log "[✓] sqlite3 安装成功"
        return 0
    fi

    log "[x] sqlite3 自动安装后仍不可用，请手动安装后重试。"
    return 1
}

restart_s_ui() {
    if command -v systemctl >/dev/null 2>&1; then
        run_with_log systemctl restart s-ui
    elif command -v service >/dev/null 2>&1; then
        run_with_log service s-ui restart
    elif command -v rc-service >/dev/null 2>&1; then
        run_with_log rc-service s-ui restart
    else
        log "[x] 未找到 systemctl/service/rc-service，无法自动重启 s-ui。"
        return 1
    fi
}

log "=========================================="
log "开始执行流量重置任务"

if [ ! -f "$DB_PATH" ]; then
    log "[x] 未找到数据库: $DB_PATH，任务终止。"
    exit 1
fi

if ! install_sqlite3; then
    exit 1
fi

SQL_OUTPUT=$(sqlite3 "$DB_PATH" <<'SQL_EOF' 2>&1
BEGIN TRANSACTION;
UPDATE clients SET up = 0, down = 0;
DELETE FROM stats;
COMMIT;
SQL_EOF
)
SQL_STATUS=$?

if [ $SQL_STATUS -eq 0 ]; then
    log "[✓] 数据库流量清零成功"
else
    log "[x] 数据库操作失败，sqlite3 退出码: $SQL_STATUS"
    if [ -n "$SQL_OUTPUT" ]; then
        log "$SQL_OUTPUT"
    fi
    exit 1
fi

if restart_s_ui; then
    log "[✓] s-ui 面板重启成功"
else
    log "[x] s-ui 面板重启失败"
fi
log "任务结束"
SCRIPT_EOF

# 赋予执行权限并加入定时任务
chmod +x "$SCRIPT_PATH"
CRON_CMD="0 0 1 * * /bin/bash $SCRIPT_PATH"

ensure_crontab
start_cron_service

if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
    echo "[!] 定时任务已存在，无需重复添加。"
else
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "[✓] 定时任务添加成功 (每月1号0点执行)。"
fi

echo "[✓] 配置完成！定时任务将在每月1号0点执行重置。"
