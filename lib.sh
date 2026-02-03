#!/bin/bash

# Shared library for ORBITRON
# Sourced by init.sh, setup.sh, run_tests.sh, monitor.sh

# SSH options for reliable connections
SSH_OPTS="-o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Function to run SSH commands with proper options
# Usage: run_ssh_command <hostname> <command> [timeout_seconds]
run_ssh_command() {
    local hostname=$1
    local command=$2
    local timeout_secs=${3:-0}
    if [ "$timeout_secs" -gt 0 ] 2>/dev/null; then
        timeout "$timeout_secs" ssh $SSH_OPTS root@"$hostname" "$command"
    else
        ssh $SSH_OPTS root@"$hostname" "$command"
    fi
}

# Function to copy files via SCP with proper options
run_scp_command() {
    local source=$1
    local hostname=$2
    local destination=$3
    scp $SSH_OPTS "$source" "root@$hostname:$destination"
}

# Function to check if a node is reachable via ping
check_node() {
    local hostname=$1
    echo "Checking if $hostname is reachable..."
    if ! ping -c 1 "$hostname" > /dev/null 2>&1; then
        echo "Error: Cannot reach $hostname"
        return 1
    fi
    return 0
}

# Function to start a background process on a remote host via SSH
# Returns the remote PID
start_background_process() {
    local hostname=$1
    local command=$2
    local output_file=${3:-/dev/null}
    run_ssh_command "$hostname" "nohup $command > $output_file 2>&1 & echo \$!"
}

# Function to stop a background process on a remote host
stop_background_process() {
    local hostname=$1
    local pid=$2
    run_ssh_command "$hostname" "kill $pid 2>/dev/null || true"
}
