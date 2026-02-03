# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ORBITRON is a wireless network testing framework for the [ORBIT testbed](https://www.orbit-lab.org/). It automates WiFi performance testing (TCP/UDP saturation, WiFi jamming via deauthentication attacks) across distributed nodes and collects metrics like throughput, jitter, packet loss, and CPU utilization. Built primarily in Bash with Python for data analysis.

## Running the Framework

```bash
# Interactive menu (primary entry point)
./main.sh          # launches orbitron.sh

# Manual operation
./init.sh          # Initialize ORBIT testbed (power cycle nodes, load images)
./setup.sh         # Configure all nodes (AP, client, saturator, jammer, control)
./monitor.sh       # Start real-time monitoring on all nodes
./run_tests.sh tcp       # Run TCP saturation test only
./run_tests.sh udp       # Run UDP saturation test only
./run_tests.sh wifi      # Run WiFi jamming test only
./run_tests.sh all       # Run all tests

# Analysis (run locally, not on testbed)
pip install -r requirements.txt
python analysis/iperf_analysis.py <log_directory> [output_directory]
# Example: python analysis/iperf_analysis.py logs/20250507_032111
```

## Architecture

### Distributed Node Roles

The framework orchestrates multiple ORBIT testbed nodes, each with a specialized role defined in `config.sh`:

- **AP** — Runs `hostapd` as a wireless access point and hosts the `iperf3` server
- **Client** — Connects via `wpa_supplicant`, generates traffic, measures signal
- **Saturator** — Connects to the AP as a WiFi client (via `wpa_supplicant`), generates iperf3 load
- **Jammer** — Operates in monitor mode, runs `aireplay-ng` deauthentication attacks
- **Control** — Orchestrates tests, runs simultaneous UDP flood traffic

Node config format in `config.sh`: `[name]="hostname|ip|role|interface|network"`

### Script Responsibilities

| Script | Purpose |
|--------|---------|
| `lib.sh` | Shared functions (`run_ssh_command`, `check_node`, `start/stop_background_process`, `SSH_OPTS`) sourced by all scripts |
| `config.sh` | Node definitions, network configs (SSID/password/channel/WPA), test parameters (`TEST_DURATION`) |
| `init.sh` | ORBIT testbed initialization: powers off nodes, resets attenuation matrix, loads images, waits for nodes (10-min timeout) |
| `setup.sh` | Per-node setup: kills stale processes, resets interfaces, installs packages (3 retries), configures role-specific daemons |
| `run_tests.sh` | Test execution: TCP saturation with concurrent UDP floods, UDP saturation with concurrent floods, WiFi jamming during TCP baseline |
| `monitor.sh` | Parallel monitoring: WiFi metrics, interface stats, CPU/memory, channel utilization. Trap handler cleans up on Ctrl+C |
| `orbitron.sh` | Interactive menu interface wrapping all operations |
| `analysis/iperf_analysis.py` | Parses iperf3 JSON results, auto-discovers test files, generates plots and summaries. Accepts log dir as CLI argument |

### Execution Flow

```
init.sh (ORBIT testbed setup) → setup.sh (node configuration) → run_tests.sh (test execution) → analysis/iperf_analysis.py (local analysis)
```

All scripts source `lib.sh` for shared SSH and utility functions.

### Test Output Structure

Results go to `logs/YYYYMMDD_HHMMSS/{tcp,udp,wifi}_test/` as iperf3 JSON files. Analysis output (plots) goes to `analysis/output/` by default.

### Key Patterns

- All scripts source `lib.sh` which provides `run_ssh_command()`, `check_node()`, `start_background_process()`, `stop_background_process()`, and `SSH_OPTS`
- `run_ssh_command()` accepts an optional 3rd argument for timeout in seconds
- Node configs are parsed with `IFS='|' read -r` destructuring from the associative arrays in `config.sh`
- Shell scripts use `set -e` for fail-fast behavior
- Package installation has retry logic (3 attempts) with `apt-get update` before install
- Analysis must be performed locally — the ORBIT testbed does not support Jupyter/matplotlib
