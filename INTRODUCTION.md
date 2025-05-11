# ORBITRON: An Integrated WiFi Testbed Framework
## Author Information

**Author:** Shahab Afshar  
**ORCID:** [0009-0000-3682-0471](https://orcid.org/0009-0000-3682-0471)  
**Affiliation:** Iowa State University  
**Department:** Electrical and Computer Engineering (ECPE)  
**Course:** Wireless Network Security  
**Advisor:** Dr. Mohamed Selim

[![ORCID](https://img.shields.io/badge/ORCID-0009--0000--3682--0471-A6CE39?style=flat-square&logo=ORCID&logoColor=white)](https://orcid.org/0009-0000-3682-0471)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Shahab_Afshar-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/shahabafshar)

## Abstract

ORBITRON is an integrated framework of a wireless network testbed and analysis described herein. The framework leverages the ORBIT testbed [1] to support reproducible and controlled test conditions for network security analysis, performance testing, and protocol analysis. This paper describes the framework's architecture, implementation, and application in wireless network testing and research.

## I. Introduction

Wireless network security and performance testing is increasingly necessary in the modern networked age. Most of the conventional testing approaches are unsuccessful in providing reproducible results and full performance metrics, particularly in real network conditions [2]. ORBITRON transcends such limitations by using an automated controlled testbed facilitating effective network analysis and security testing.

The creation of the framework was driven by the necessity for reproducible, standardized wireless network test methods. Through the utilization of the capabilities of the ORBIT testbed [1], ORBITRON offers researchers and network administrators a solid ground for executing thorough network analysis, security testing, and performance evaluation.

## II. System Architecture

### A. Testbed Integration
ORBITRON is installed on the ORBIT testbed [1], a wireless network emulator. The testbed provides an emulated wireless environment that provides reproducible test conditions without losing the realism of actual hardware designs. This integration gives precise control of network parameters with realistic test environments.

### B. Node Architecture

The architecture has a distributed layout featuring multiple nodes, each performing special roles when it comes to the testing. The Access Point node is the central wireless hub responsible for directing traffic and security parameters in terms of IEEE 802.11 standards [2]. Client nodes emulate end-users, providing accurate readings of connectivity and signal strengths. Saturator nodes induce test network loads and permit capacity and traffic pattern assessment. The Control node governs the test process, capturing performance information and managing test conditions.

## III. Technical Implementation

### A. Core Components

The deployment of the architecture is composed of three primary components: Configuration Management, Monitoring System, and Analysis Engine. Configuration Management deploys node setup and test parameterization, thereby enabling reproducible testing environments. The Monitoring System provides real-time metrics collection and performance logging, whereas the Analysis Engine inspects data to generate in-depth reports and graphs.

### B. Testing Methodology

ORBITRON employs a formal test lifecycle as three phases: Environment Setup, Test Execution, and Analysis. The Environment Setup phase configures nodes and network parameters based on standard wireless network security protocols [3]. Under the Test Execution, the system automatically tests a sequence and records performance metrics. The Analysis phase processes data collected to offer insights and visualization.

## IV. Testing Capabilities

### A. Performance Analysis

The platform provides full performance test capabilities, including TCP/UDP throughput analysis, signal strength measurement, and channel utilization monitoring according to the IEEE 802.11 standard [2]. These capabilities facilitate comprehensive testing of network performance under various conditions and loads.

### B. Security Assessment

ORBITRON embeds cutting-edge security test features, like WiFi jamming detection and interference testing of signals. Security test feature in the system enables thorough study of network threats and performance of security mechanisms based on formal security testing processes [4]. 

## V. Applications and Use Cases

### A. Network Security Research

The system enables advanced network security research by carrying out controlled security protocol testing and vulnerability testing [4]. Various attack models can be simulated, and networks' resilience to various conditions can be experimented with.

### B. Performance Optimization

ORBITRON facilitates network performance optimization by performing extensive analysis of throughput, latency, and resource consumption [3]. The extremely detailed metrics collection from the system enables performance bottlenecks and optimization points to be determined.

## VI. Future Development

Development roadmap is diverse range of future enhancements like strong security testing functionality, more supported protocols, and more visualization function. Future effort is the inclusion of machine learning features so that performance might be optimized and predicted automatically, based on current wireless network security research [4].

## VII. Conclusion

ORBITRON provides single-site solution for test and analysis of wireless network with reproducible testing environments and automatic analysis. The architecture assists researchers and network operators in performing thorough network assessments, analyzing performance data, and optimizing network settings, in compliance with industry-defined standards and best practices [2], [3].



## References

[1] ORBIT Testbed Documentation, [Online]. Available: https://www.orbit-lab.org/.

[2] IEEE 802.11 Working Group, "IEEE Standard for Information Technology--Telecommunications and Information Exchange between Systems Local and Metropolitan Area Networks--Specific Requirements Part 11: Wireless LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications," IEEE Std 802.11-2020, 2021.

[3] M. S. Gast, "802.11 Wireless Networks: The Definitive Guide," O'Reilly Media, Inc., 2005.

[4] D. L. Lough, "A Taxonomy of Computer Attacks with Applications to Wireless Networks," Ph.D. dissertation, Virginia Polytechnic Institute and State University, 2001.