#!/bin/bash
REPORT_DIR="$HOME/linux-server-health-monitor/reports"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$REPORT_DIR/health-report-$TIMESTAMP.txt"

mkdir -p "$REPORT_DIR"
exec > >(tee "$REPORT_FILE") 2>&1
MEMORY_USAGE=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
DISK_USAGE=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')
CPU_USAGE=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | xargs)
SSH_STATUS=$(systemctl is-active sshd)
FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    INTERNET_STATUS="CONNECTED"
else
    INTERNET_STATUS="NOT CONNECTED"
fi
get_status() {
    VALUE=$1

    if [ "$VALUE" -ge 85 ]; then
        echo "CRITICAL"
    elif [ "$VALUE" -ge 70 ]; then
        echo "WARNING"
    else
        echo "HEALTHY"
    fi
}

MEMORY_STATUS=$(get_status "$MEMORY_USAGE")
DISK_STATUS=$(get_status "$DISK_USAGE")
CPU_STATUS=$(get_status "$CPU_USAGE")

echo "========================================"
echo "       LINUX SERVER HEALTH REPORT"
echo "========================================"
echo
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
echo
echo "SYSTEM HEALTH"
echo "CPU Usage:    ${CPU_USAGE}% [$CPU_STATUS]"
echo "Memory Usage: ${MEMORY_USAGE}% [$MEMORY_STATUS]"
echo "Disk Usage:   ${DISK_USAGE}% [$DISK_STATUS]"
echo "Load Average: $LOAD_AVERAGE"
echo
echo "SERVICE STATUS"

if [ "$SSH_STATUS" = "active" ]; then
    echo "SSH Service: RUNNING"
else
    echo "SSH Service: NOT RUNNING"
fi
if [ "$FAILED_SERVICES" -eq 0 ]; then
    echo "Failed Services: None"
else
    echo "Failed Services: $FAILED_SERVICES detected"
fi

echo "Internet: $INTERNET_STATUS"

echo
echo "========================================"
echo "Report completed"
echo "========================================"
echo
