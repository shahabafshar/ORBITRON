#!/bin/bash

# Exit on error
set -e

# Enable verbose output
# set -x

# Source configuration
source config.sh
source lib.sh

# Function to install required packages
install_packages() {
    local hostname=$1
    echo "Installing required packages on $hostname..."
    
    # Check if node is reachable
    check_node "$hostname" || return 1
    
    # Install packages with retries
    for i in {1..3}; do
        if run_ssh_command "$hostname" "DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get install -y iperf3 hostapd wpasupplicant tmux hping3"; then
            return 0
        fi
        echo "Attempt $i failed, retrying in 5 seconds..."
        sleep 5
    done
    echo "Error: Failed to install packages on $hostname after 3 attempts"
    return 1
}

# Function to cleanup node
cleanup_node() {
    local hostname=$1
    local interface=$2

    echo "Cleaning up $hostname..."
    echo "================================================"
    # Kill any existing processes
    run_ssh_command "$hostname" "pkill -f hostapd || true; \
                       pkill -f wpa_supplicant || true; \
                       pkill -f mdk3 || true; \
                       pkill -f aireplay-ng || true" || echo "Warning: Cleanup failed on $hostname"
    echo "================================================"
    # Reset interface and remove IP
    run_ssh_command "$hostname" "ip link set $interface down || true; \
                       ip addr flush dev $interface || true; \
                       pkill -f wpa_supplicant || true; \
                       pkill -f hostapd || true; \
                       pkill -f dhclient || true" || echo "Warning: Interface reset failed on $hostname"
}

# Function to setup AP node
setup_ap() {
    local hostname=$1
    local ip=$2
    local interface=$3
    local network=$4

    echo "Setting up AP on $hostname..."
    
    # Check if node is reachable
    check_node "$hostname" || return 1
    
    # Get network config
    IFS='|' read -r ssid password channel hw_mode auth_algs wpa wpa_key_mgmt wpa_pairwise rsn_pairwise <<< "${NETWORKS[$network]}"
    
    # Create hostapd config in a temp file
    local tmpconf
    tmpconf=$(mktemp)
    cat > "$tmpconf" << EOF
interface=$interface
driver=nl80211
ssid=$ssid
hw_mode=$hw_mode
channel=$channel
auth_algs=$auth_algs
wpa=$wpa
wpa_passphrase=$password
wpa_key_mgmt=$wpa_key_mgmt
wpa_pairwise=$wpa_pairwise
rsn_pairwise=$rsn_pairwise
EOF

    # Copy config and setup AP
    echo "Copying hostapd config to $hostname..."
    run_scp_command "$tmpconf" "$hostname" "/root/hostapd.conf" || { rm -f "$tmpconf"; echo "Error: Failed to copy config to $hostname"; return 1; }
    rm -f "$tmpconf"
    
    echo "Starting hostapd on $hostname..."
    run_ssh_command "$hostname" "ip link set $interface down && \
                    ip addr flush dev $interface && \
                    iw dev $interface set type managed && \
                    iw dev $interface set type monitor && \
                    iw dev $interface set type managed && \
                    ip link set $interface up && \
                    ip addr add $ip/24 dev $interface && \
                    tmux new-session -d -s hostapd 'hostapd -dd /root/hostapd.conf'" || { echo "Error: Failed to start hostapd on $hostname"; return 1; }
    
    # Wait for AP to start and verify
    sleep 5
    if ! run_ssh_command "$hostname" "pgrep hostapd > /dev/null"; then
        echo "Error: hostapd failed to start on $hostname"
        return 1
    fi
}

# Function to setup client node
setup_client() {
    local hostname=$1
    local ip=$2
    local interface=$3
    local network=$4

    echo "Setting up client on $hostname..."
    
    # Check if node is reachable
    check_node "$hostname" || return 1
    
    # Get network config
    IFS='|' read -r ssid password channel hw_mode auth_algs wpa wpa_key_mgmt wpa_pairwise rsn_pairwise <<< "${NETWORKS[$network]}"
    
    # Generate wpa_supplicant config using wpa_passphrase
    echo "Generating wpa_supplicant config on $hostname..."
    run_ssh_command "$hostname" "wpa_passphrase '$ssid' '$password' > /root/wpa.conf" || { echo "Error: Failed to generate wpa config on $hostname"; return 1; }

    # Setup client
    echo "Starting wpa_supplicant on $hostname..."
    run_ssh_command "$hostname" "ip link set $interface up && \
                       ip addr flush dev $interface && \
                       iw dev $interface set type managed && \
                       wpa_supplicant -i$interface -c/root/wpa.conf -B && \
                       sleep 10 && \
                       ip addr add $ip/24 dev $interface" || { echo "Error: Failed to setup client on $hostname"; return 1; }
    
    # Wait for client to connect
    sleep 5
}

# Function to setup saturator node
setup_saturator() {
    local hostname=$1
    local ip=$2
    local interface=$3
    local network=$4

    echo "Setting up saturator on $hostname..."
    setup_client "$hostname" "$ip" "$interface" "$network"
}

# Function to setup jammer node
setup_jammer() {
    local hostname=$1
    local interface=$2

    echo "Setting up jammer on $hostname..."
    
    # Check if node is reachable
    check_node "$hostname" || return 1
    
    # Set interface to monitor mode
    run_ssh_command "$hostname" "ip link set $interface down && \
                       ip addr flush dev $interface && \
                       airmon-ng start $interface" || { echo "Error: Failed to setup jammer on $hostname"; return 1; }
}

# Main setup process
main() {
    # Process each node
    for node_name in "${!NODES[@]}"; do
        IFS='|' read -r hostname ip role interface network <<< "${NODES[$node_name]}"
        
        echo "Processing node: $node_name ($hostname)"
        
        # First cleanup the node
        cleanup_node "$hostname" "$interface"
        
        # Install required packages
        install_packages "$hostname" || { echo "Error: Package installation failed"; exit 1; }
        
        # Then setup based on role
        case $role in
            "ap")
                setup_ap "$hostname" "$ip" "$interface" "$network" || { echo "Error: AP setup failed"; exit 1; }
                ;;
            "client")
                setup_client "$hostname" "$ip" "$interface" "$network" || { echo "Error: Client setup failed"; exit 1; }
                ;;
            "saturator")
                setup_saturator "$hostname" "$ip" "$interface" "$network" || { echo "Error: Saturator setup failed"; exit 1; }
                ;;
            "jammer")
                setup_jammer "$hostname" "$interface" || { echo "Error: Jammer setup failed"; exit 1; }
                ;;
            "control")
                echo "Control node $hostname requires no special setup"
                ;;
            *)
                echo "Unknown role: $role for node $hostname"
                exit 1
                ;;
        esac
    done

    echo "Setup completed successfully!"
}

# Record start time
setup_start_time=$(date +%s)

# Run the main function
main 

# Calculate and report total elapsed time
setup_end_time=$(date +%s)
total_elapsed=$((setup_end_time - setup_start_time))
minutes=$((total_elapsed / 60))
seconds=$((total_elapsed % 60))

echo "====================setup======================="
echo "Setup completed successfully"
echo "Total setup time: ${minutes}m ${seconds}s"
echo "Nodes configured: ${#NODES[@]}"
echo "Status: All nodes configured"
echo "================================================"
