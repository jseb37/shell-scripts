#!/bin/bash

# === CONFIGURATION ===
LOG_FILE="resource_usage.log"             # Log file for resource usage
MAX_LOG_SIZE=102400                       # Rotate log file if it exceeds 100KB
ALERT_CPU=80.0                            # CPU usage alert threshold in percentage
ALERT_MEM=80.0                            # Memory usage alert threshold in percentage
ALERT_DISK=80.0                           # Disk usage alert threshold in percentage
ALERT_LOG="alerts.log"                    # Log file for alerts
ALERT_EMAIL="admin@example.com"           # Recipient email for alert

# === HEADER INITIALIZATION ===
# If the log file doesn't exist, initialize it with headers
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Timestamp           | CPU (%) | Mem (%) | Disk (%)" > "$LOG_FILE"
    echo "--------------------------------------------------------" >> "$LOG_FILE"
fi

echo "Monitoring resource usage of VM... Press Ctrl+C to stop."

# === FUNCTION: Get disk usage of root (/) in percent ===
get_disk_usage() {
    df --output=pcent / | tail -1 | tr -dc '0-9'
}

# === FUNCTION: Rotate the main log file if it exceeds MAX_LOG_SIZE ===
rotate_log() {
    if [[ -f "$LOG_FILE" && $(stat -c%s "$LOG_FILE") -ge $MAX_LOG_SIZE ]]; then
        mv "$LOG_FILE" "${LOG_FILE%.log}_$(date +"%Y%m%d_%H%M%S").log"
        echo "Timestamp           | CPU (%) | Mem (%) | Disk (%)" > "$LOG_FILE"
        echo "--------------------------------------------------------" >> "$LOG_FILE"
    fi
}

# === FUNCTION: Log alert messages and send email ===
log_alert() {
    local MESSAGE="$1"
    echo "$MESSAGE" >> "$ALERT_LOG"
    echo "[ALERT] $MESSAGE"

    # Send email
    echo "$MESSAGE" | mail -s "🚨 VM Resource Alert" "$ALERT_EMAIL"
}

# === MONITORING LOOP ===
while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    MEM=$(free | awk '/Mem/ {printf "%.2f", $3/$2 * 100}')
    DISK=$(get_disk_usage)

    # Write stats into the log file
    printf "%s | %7.2f | %7.2f | %8s\n" "$TIMESTAMP" "$CPU" "$MEM" "$DISK" >> "$LOG_FILE"

    # Alert if CPU, Memory, or Disk usage exceeds the threshold
    (( $(echo "$CPU > $ALERT_CPU" | bc -l) )) && log_alert "$TIMESTAMP High CPU: $CPU%"
    (( $(echo "$MEM > $ALERT_MEM" | bc -l) )) && log_alert "$TIMESTAMP High Memory: $MEM%"
    (( $(echo "$DISK > $ALERT_DISK" | bc -l) )) && log_alert "$TIMESTAMP High Disk Usage: $DISK%"

    rotate_log
    sleep 5
done
