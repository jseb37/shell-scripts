#!/bin/bash
set -euo pipefail

show_menu() {
    echo "============================"
    echo "   System Utility Menu"
    echo "============================"
    echo "1) Disk usage"
    echo "2) Memory usage"
    echo "3) Running processes"
    echo "4) Check service status"
    echo "5) Exit"
    echo "============================"
}

disk_usage() {
    df -h
}

memory_usage() {
    free -h
}

running_processes() {
    ps -ef | head -10
}

check_service() {
    read -p "Enter service name: " service
    systemctl status "$service" --no-pager  #By default, systemctl status pipes output into a pager (less),--no-pager disables paging,#Output is printed directly to stdout.

}

while true
do
    clear
    show_menu
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) disk_usage ;;
        2) memory_usage ;;
        3) running_processes ;;
        4) check_service ;;
        5) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option" ;;
    esac

    read -p "Press Enter to continue..."
done
