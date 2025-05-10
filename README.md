# Orbit Testbed WiFi Testing Framework

```
    ██████╗ ██████╗ ██████╗ ██╗████████╗██████╗  ██████╗ ███╗   ██╗
   ██╔═══██╗██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║
   ██║   ██║██████╔╝██████╔╝██║   ██║   ██████╔╝██║   ██║██╔██╗ ██║
   ██║   ██║██╔══██╗██╔══██╗██║   ██║   ██╔══██╗██║   ██║██║╚██╗██║
   ╚██████╔╝██║  ██║██████╔╝██║   ██║   ██║  ██║╚██████╔╝██║ ╚████║
    ╚═════╝ ╚═╝  ╚═╝╚════╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
```

## About

This project is developed and maintained by Shahab Afshar.

[![ORCID](https://img.shields.io/badge/ORCID-0009--0000--3682--0471-A6CE39?style=flat-square&logo=ORCID&logoColor=white)](https://orcid.org/0009-0000-3682-0471)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Shahab_Afshar-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/shahabafshar)

**Professor:** [Dr. Mohamed Selim](https://scholar.google.com/citations?user=jL7iUGMAAAAJ&hl=en) [![Google Scholar](https://img.shields.io/badge/Google_Scholar-4285F4?style=flat-square&logo=google-scholar&logoColor=white)](https://scholar.google.com/citations?user=jL7iUGMAAAAJ&hl=en) 

**Course:** Wireless Network Security  
**Department:** Electrical and Computer Engineering (ECPE)  
**University:** Iowa State University  

**Testbed:** [ORBIT (Open-Access Research Testbed for Next-Generation Wireless Networks)](https://www.orbit-lab.org/)  
ORBIT is a two-tier wireless network emulator/field trial designed to achieve reproducible experimentation, while also supporting realistic evaluation of protocols and applications.

ORBITRON is a comprehensive network testing suite designed for wireless network security analysis and performance evaluation.

This framework provides tools for testing WiFi performance and saturation on the ORBIT testbed.

## Features

- Automated setup of Access Point (AP), Client, and Saturator nodes
- Real-time monitoring of WiFi metrics:
  - Signal strength and quality
  - CPU utilization
  - Interface statistics
  - Channel utilization
- Performance testing with iperf3:
  - TCP and UDP throughput
  - Retransmission analysis
  - Jitter measurements
- Comprehensive data analysis and visualization
- Detailed performance reports
- User-friendly menu interface for easy operation

## Prerequisites

1. ORBIT testbed access
2. Python 3.6 or higher
3. Required Python packages (install using `pip install -r requirements.txt`):
   - pandas
   - matplotlib
   - seaborn
   - numpy
4. Required system packages:
   - iperf3
   - aireplay-ng
   - iwconfig
   - ssh

## Node Setup

The framework supports multiple node roles:
- AP (Access Point)
- Client
- Saturator (for generating traffic)
- Jammer (optional)
- Control (for monitoring and coordination)

Configuration is managed through `config.sh`:
```bash
# Example node configuration
NODES=(
    ["ap"]="node1-3.outdoor.orbit-lab.org|10.1.0.17|ap|wlan0|main_network"
    ["client"]="node1-1.outdoor.orbit-lab.org|10.1.0.15|client|wlan0|main_network"
    ["saturator"]="node1-2.outdoor.orbit.lab.org|10.1.0.16|saturator|wlan0|saturation_network"
)
```

## Usage

### Menu Interface (Recommended)

The easiest way to use the framework is through the menu interface:

```bash
./orbitron.sh
```

The menu provides the following options:
1. Initialize Test Environment
2. Run TCP Saturation Test
3. Run UDP Saturation Test
4. Run WiFi Jamming Test
5. Run All Tests
6. View Test Results
7. Configure Test Parameters
8. About ORBITRON
9. Exit

### Manual Operation

For advanced users, the framework can be operated manually:

1. Setup nodes:
   ```bash
   ./setup.sh
   ```

2. Start monitoring:
   ```bash
   ./monitor.sh
   ```

3. Run specific tests:
   ```bash
   ./run_tests.sh [test_type]
   # where test_type can be: tcp, udp, wifi, or all
   ```

4. Analyze results:
   ```bash
   python analysis.py logs/[test_timestamp] analysis/
   ```

## Output

The analysis generates:
1. Time-series plots for:
   - Signal strength
   - Connection quality
   - CPU usage
   - Bandwidth
   - Retransmissions
   - Jitter

2. A comprehensive Markdown report with:
   - Per-node WiFi metrics
   - Performance statistics
   - Test summary

## Troubleshooting

1. SSH Connection Issues:
   - The framework now includes robust SSH connection handling
   - Automatic retry for package installation
   - SSH key verification skipping for testing

2. Package Installation:
   - Automatic cleanup of problematic repositories
   - Lock file handling
   - Multiple installation attempts

3. Node Connectivity:
   - Node reachability checks before operations
   - Interface reset and cleanup procedures
   - Proper process termination

4. Analysis Issues:
   - Note that analysis must be performed on a local system
   - Copy log files from the ORBIT testbed to your local machine
   - Run analysis.py locally with the copied log files

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
