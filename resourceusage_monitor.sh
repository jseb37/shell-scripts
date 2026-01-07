#!/bin/bash
set -euo pipefail
# === CONFIGURATION ===
LOG_FILE="resource_usage.log"             # Log file for resource usage
MAX_LOG_SIZE=50                       # Rotate log file if it exceeds 100KB
ALERT_CPU=0.0                           # CPU usage alert threshold in percentage
ALERT_MEM=30.0                            # Memory usage alert threshold in percentage
ALERT_DISK=30.0                           # Disk usage alert threshold in percentage
ALERT_LOG="alerts.log"                    # Log file for alerts

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

# Gets disk usage percentage of the root (/) filesystem
# Removes the header line
# Strips % and whitespace

# tr → translate / delete characters
# -d → delete
# -c → complement (everything except)
# '0-9' → digits

# Outputs a pure number (e.g., 42)



# === FUNCTION: Rotate the main log file if it exceeds MAX_LOG_SIZE ===
rotate_log() {
    if [[ -f "$LOG_FILE" && $(stat -c%s "$LOG_FILE") -ge $MAX_LOG_SIZE ]]; then
        mv "$LOG_FILE" "${LOG_FILE%.log}_$(date +"%Y%m%d_%H%M%S").log"
        echo "Timestamp           | CPU (%) | Mem (%) | Disk (%)" > "$LOG_FILE"
        echo "--------------------------------------------------------" >> "$LOG_FILE"
    fi
}
#LOG_FILE%.log means - > Remove .log from the end of $LOG_FILE if it exists to avoid .log to come multiple times
# stat → shows file metadata
# -c → custom output format
# %s → file size in bytes


log_alert() {
    local MSG="$1"
    local TS
    TS=$(date +"%Y-%m-%d %H:%M:%S")

    # Write alert to alert log
    echo "$TS | ALERT | $MSG" >> "$ALERT_LOG"

    # Print to STDERR (visible in terminal / cron)
    echo "$TS | ALERT | $MSG" >&2

    # Optional: signal failure to cron / systemd
    # exit 1
}

#A file descriptor (FD) is just a number the OS uses to represent an open file or stream for a process.
#A handle / ID that points to where input or output should go
# FD	Name	Meaning
# 0	STDIN	Input (keyboard, pipe)
# 1	STDOUT	Normal output
# 2	STDERR	Errors / alerts


# === MONITORING LOOP ===

while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    CPU=$(mpstat 1 1 | awk '$2=="all" {printf "%.2f", 100-$12; exit}')
 
    MEM=$(free | awk '/Mem/ {printf "%.2f\n", $3/$2 * 100}') 

    #total = used + free + buff/cache
    #available ≈ free + reclaimable cache − safety buffer

    # total → Total physical RAM installed on the system.
    # used → Memory currently in use by applications and the kernel (excluding reclaimable cache).
    # free → Completely unused RAM doing nothing right now.
    # shared → Memory shared between processes (mainly tmpfs / shared memory).
    # buff/cache → RAM used for filesystem buffers and page cache that can be reclaimed.
    # available → Memory the kernel estimates can be allocated by apps without swapping
    
    DISK=$(get_disk_usage)
     # Handle CPU = 0%
    if (( $(echo "$CPU == 0" | bc -l) )); then
       CPU="0.01"
    fi
    # Write stats into the log file
    printf "%s | %7.2f | %7.2f | %8s\n" "$TIMESTAMP" "$CPU" "$MEM" "$DISK" >> "$LOG_FILE"
   
    # Alert if CPU, Memory, or Disk usage exceeds the threshold
    (( $(echo "$CPU > $ALERT_CPU" | bc -l) )) && log_alert "$TIMESTAMP High CPU: $CPU%"
    (( $(echo "$MEM > $ALERT_MEM" | bc -l) )) && log_alert "$TIMESTAMP High Memory: $MEM%"
    (( $(echo "$DISK > $ALERT_DISK" | bc -l) )) && log_alert "$TIMESTAMP High Disk Usage: $DISK%"

    #(( )) does NOT return 1 or 0 as output
    #It sets the exit status, which && checks
    #&& runs the next command only if the previous command exits successfully

    rotate_log
    sleep 5
done

