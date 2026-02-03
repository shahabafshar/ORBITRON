#!/bin/bash

# Source configuration
source config.sh
source lib.sh

# Add timestamp to LOG_DIR to match run_tests.sh convention
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="${LOG_DIR}/${TIMESTAMP}"

# Track child PIDs for cleanup
CHILD_PIDS=()

cleanup() {
    echo ""
    echo "Stopping all monitors..."
    for pid in "${CHILD_PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null
    echo "Monitoring stopped."
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Function to monitor WiFi metrics
monitor_wifi() {
    local hostname=$1
    local interface=$2
    local output_file="$LOG_DIR/wifi_metrics_${hostname}_$(date +%Y%m%d_%H%M%S).log"

    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Start monitoring in background
    while true; do
        echo "=== $(date) ===" >> "$output_file"

        # Get signal strength and quality
        run_ssh_command "$hostname" "iwconfig $interface" | grep -E "Signal|Quality" >> "$output_file"

        # Get interface statistics
        run_ssh_command "$hostname" "cat /proc/net/wireless" >> "$output_file"

        # Get CPU usage
        run_ssh_command "$hostname" "top -bn1 | grep 'Cpu(s)'" >> "$output_file"

        # Get memory usage
        run_ssh_command "$hostname" "free -m" >> "$output_file"

        # Get interface TX/RX statistics
        run_ssh_command "$hostname" "cat /sys/class/net/$interface/statistics/tx_bytes" >> "$output_file"
        run_ssh_command "$hostname" "cat /sys/class/net/$interface/statistics/rx_bytes" >> "$output_file"

        # Get current channel utilization (if iw supports it)
        run_ssh_command "$hostname" "iw dev $interface survey dump" >> "$output_file" 2>/dev/null || true

        echo "" >> "$output_file"
        sleep 1
    done
}

# Function to monitor all nodes
monitor_all_nodes() {
    # Start monitoring each node
    for node_name in "${!NODES[@]}"; do
        IFS='|' read -r hostname ip role interface network <<< "${NODES[$node_name]}"

        case $role in
            "ap")
                monitor_wifi "$hostname" "$interface" &
                CHILD_PIDS+=($!)
                ;;
            "client"|"saturator")
                monitor_wifi "$hostname" "$interface" &
                CHILD_PIDS+=($!)
                ;;
        esac
    done

    # Wait for Ctrl+C
    echo "Monitoring started. Press Ctrl+C to stop..."
    wait
}

# Main function
main() {
    # Create log directory
    mkdir -p "$LOG_DIR"

    # Start monitoring
    monitor_all_nodes
}

# Run main function
main
