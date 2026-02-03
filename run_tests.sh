#!/bin/bash

# Exit on error
set -e

# Enable verbose output
#set -x

# Source configuration
source config.sh
source lib.sh

# Create log directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="${LOG_DIR}/${TIMESTAMP}"
mkdir -p "$LOG_DIR"

# Function to run TCP saturation test
run_tcp_saturation() {
    local client_hostname=$1
    local server_ip=$2
    local duration=$3
    local test_dir=$4
    local test_name=${5:-saturation}
    local output_file="$test_dir/tcp_${test_name}_$(date +%Y%m%d_%H%M%S).json"
    
    echo "Running TCP saturation test from $client_hostname to $server_ip..."
    
    # Start iperf3 server in background with nohup
    run_ssh_command "$server_ip" "nohup iperf3 -s -J > /tmp/iperf_server.json &"
    sleep 2
    
    # Run iperf3 client
    run_ssh_command "$client_hostname" "iperf3 -c $server_ip -P 16 -t $duration -J" > "$output_file"

    # Get server output
    run_ssh_command "$server_ip" "cat /tmp/iperf_server.json" > "$output_file.server"

    # Kill iperf3 server
    run_ssh_command "$server_ip" "pkill -f 'iperf3 -s' || true"
}

# Function to run UDP saturation test
run_udp_saturation() {
    local client_hostname=$1
    local server_ip=$2
    local duration=$3
    local test_dir=$4
    local port=${5:-5202}
    local rate=${6:-"0"}
    local test_name=${7:-saturation}
    local output_file="$test_dir/udp_${test_name}_$(date +%Y%m%d_%H%M%S).json"
    
    echo "Running UDP saturation test from $client_hostname to $server_ip..."
    
    # Start iperf3 server in background with nohup
    run_ssh_command "$server_ip" "nohup iperf3 -s -p $port -J > /tmp/iperf_server.json &"
    
    # Run iperf3 client with UDP
    run_ssh_command "$client_hostname" "iperf3 -c $server_ip -p $port -u -b $rate -t $duration -J" > "$output_file"

    # Get server output
    run_ssh_command "$server_ip" "cat /tmp/iperf_server.json" > "$output_file.server"

    # Kill iperf3 server
    run_ssh_command "$server_ip" "pkill -f 'iperf3 -s' || true"
}

# Function to run WiFi jamming test
run_wifi_jamming() {
    local jammer_hostname=$1
    local target_channel=$2
    local duration=$3
    local test_dir=$4
    local output_file="$test_dir/wifi_jamming_$(date +%Y%m%d_%H%M%S).log"
    
    echo "Running WiFi jamming test..."
    
    # Get the interface for the jammer node
    local jammer_interface=""
    for node_name in "${!NODES[@]}"; do
        IFS='|' read -r hostname ip role interface network <<< "${NODES[$node_name]}"
        if [ "$hostname" = "$jammer_hostname" ]; then
            jammer_interface=$interface
            break
        fi
    done
    
    if [ -z "$jammer_interface" ]; then
        echo "Error: Could not find interface for jammer node $jammer_hostname"
        return 1
    fi

    # Get network config for SSID
    local ssid=""
    for node_name in "${!NODES[@]}"; do
        IFS='|' read -r hostname ip role interface network <<< "${NODES[$node_name]}"
        if [ "$role" = "ap" ]; then
            IFS='|' read -r ssid password channel hw_mode auth_algs wpa wpa_key_mgmt wpa_pairwise rsn_pairwise <<< "${NETWORKS[$network]}"
            break
        fi
    done

    if [ -z "$ssid" ]; then
        echo "Error: Could not find SSID from AP configuration"
        return 1
    fi

    # Setup interface in managed mode and scan for AP
    echo "Setting up interface and scanning for AP..."
    run_ssh_command "$jammer_hostname" "ip link set $jammer_interface down && \
                                       iw dev $jammer_interface set type managed && \
                                       ip link set $jammer_interface up && \
                                       sleep 1" 30 || {
        echo "Error: Failed to setup interface in managed mode"
        return 1
    }

    # Get AP MAC address
    echo "Scanning for SSID: $ssid..."
    local ap_mac=$(run_ssh_command "$jammer_hostname" "iw dev $jammer_interface scan 2>/dev/null | awk -v ssid=\"$ssid\" '
        /^BSS / {mac=\$2}
        \$0 ~ \"SSID: \"ssid {print mac}
    '") || {
        echo "Error: Failed to scan for AP"
        return 1
    }

    if [ -z "$ap_mac" ]; then
        echo "Error: Could not find AP with SSID: $ssid"
        return 1
    fi

    echo "Found AP MAC: $ap_mac"

    # Switch to monitor mode
    echo "Switching to monitor mode..."
    run_ssh_command "$jammer_hostname" "ip link set $jammer_interface down && \
                                       iw dev $jammer_interface set type monitor && \
                                       ip link set $jammer_interface up && \
                                       sleep 1" 30 || {
        echo "Error: Failed to set monitor mode"
        return 1
    }

    # Calculate number of deauth packets based on duration (5 packets per second)
    local packet_count=$((duration * 5))
    
    # Start deauth attack
    echo "Starting deauth attack for $duration seconds..."
    local jammer_pid=$(start_background_process "$jammer_hostname" "aireplay-ng -0 $packet_count -a $ap_mac $jammer_interface" "/tmp/wifi_jammer_nohup.out")
    
    # Wait for duration
    sleep $duration
    
    # Stop jamming
    stop_background_process "$jammer_hostname" "$jammer_pid"

    # Restore interface to managed mode
    echo "Restoring interface to managed mode..."
    run_ssh_command "$jammer_hostname" "ip link set $jammer_interface down && \
                                       iw dev $jammer_interface set type managed && \
                                       ip link set $jammer_interface up" 30
    
    # Add summary information
    echo "WiFi Jamming Test Summary:" >> "$output_file"
    echo "Target SSID: $ssid" >> "$output_file"
    echo "Target AP MAC: $ap_mac" >> "$output_file"
    echo "Duration: $duration seconds" >> "$output_file"
    echo "Packets Sent: $packet_count" >> "$output_file"
    echo "Jammer Interface: $jammer_interface" >> "$output_file"
    echo "Attack Type: Deauthentication" >> "$output_file"
}

# Main test execution
main() {
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Get AP and client nodes
    local ap_hostname=""
    local ap_ip=""
    local client_hostname=""
    local saturator_hostname=""
    local jammer_hostname=""
    local control_hostname=""

    for node_name in "${!NODES[@]}"; do
        IFS='|' read -r hostname ip role interface network <<< "${NODES[$node_name]}"
        case $role in
            "ap") ap_hostname=$hostname; ap_ip=$ip ;;
            "client") client_hostname=$hostname ;;
            "saturator") saturator_hostname=$hostname ;;
            "jammer") jammer_hostname=$hostname ;;
            "control") control_hostname=$hostname ;;
        esac
    done

    # Run tests
    echo "Starting network tests..."
    
    local tests_to_run=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            "tcp") tests_to_run+=("tcp") ;;
            "udp") tests_to_run+=("udp") ;;
            "wifi") tests_to_run+=("wifi") ;;
            "all") tests_to_run=("tcp" "udp" "wifi") ;;
            *) echo "Unknown test: $1" ;;
        esac
        shift
    done
    
    # If no tests specified, run all tests
    if [ ${#tests_to_run[@]} -eq 0 ]; then
        tests_to_run=("tcp" "udp" "wifi")
    fi
    
    # Run selected tests
    for test in "${tests_to_run[@]}"; do
        # Create test-specific directory
        local test_dir="$LOG_DIR/${test}_test"
        mkdir -p "$test_dir"
        
        case $test in
            "tcp")
                echo "Running TCP Saturation Test..."
                run_tcp_saturation "$saturator_hostname" "$ap_ip" "$TEST_DURATION" "$test_dir" "baseline" &
                local baseline_pid=$!
                sleep 10
                echo "Running simultaneous UDP flood using UDP saturation..."
                for rate in {100..900..100}; do
                    run_udp_saturation "$control_hostname" "$ap_ip" 10 "$test_dir" 5205 "${rate}M" "flood_${rate}M"
                done
                wait $baseline_pid || { echo "ERROR: TCP baseline test failed"; exit 1; }
                ;;
            "udp")
                echo "Running UDP Saturation Test..."
                run_udp_saturation "$saturator_hostname" "$ap_ip" "30" "$test_dir" 5202 "900M" "baseline" &
                local baseline_pid=$!
                sleep 10
                echo "Running simultaneous UDP flood using UDP saturation..."
                for rate in {100..900..100}; do
                    run_udp_saturation "$control_hostname" "$ap_ip" 10 "$test_dir" 5205 "${rate}M" "flood_${rate}M"
                done
                wait $baseline_pid || { echo "ERROR: UDP baseline test failed"; exit 1; }
                ;;
            "wifi")
                echo "Running WiFi Jamming Test..."
                run_tcp_saturation "$saturator_hostname" "$ap_ip" "$TEST_DURATION" "$test_dir" "baseline" &
                local baseline_pid=$!
                sleep 30
                jam_duration=$((TEST_DURATION - 30))
                run_wifi_jamming "$jammer_hostname" "1" "$jam_duration" "$test_dir"
                wait $baseline_pid || { echo "ERROR: WiFi baseline test failed"; exit 1; }
                ;;
        esac
    done
    
    echo "Selected tests completed. Results are in $LOG_DIR"
}

# Record start time
test_start_time=$(date +%s)

# Run main function
main "$@"

# Calculate and report total elapsed time
test_end_time=$(date +%s)
total_elapsed=$((test_end_time - test_start_time))
minutes=$((total_elapsed / 60))
seconds=$((total_elapsed % 60))

echo "====================tests======================="
echo "Tests completed successfully"
echo "Total test time: ${minutes}m ${seconds}s"
echo "Status: All tests completed"
echo "================================================"