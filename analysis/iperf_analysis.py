# %% [markdown]
# # iperf Test Results Analysis
# 
# This notebook analyzes the results from iperf tests comparing TCP and UDP performance under different conditions.

# %%
import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from datetime import datetime

# Set style for better visualizations
plt.style.use('seaborn')
sns.set_palette('husl')

# %%
# Load the test results
def load_iperf_results(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

# Load baseline TCP results
baseline_tcp = load_iperf_results('../logs/20250504_063310/baseline_tcp.json')

# Load baseline UDP results
baseline_udp = load_iperf_results('../logs/20250504_063310/baseline_udp.json')

# %% [markdown]
# ## 1. Overall Performance Summary

# %%
def get_summary_stats(data):
    return {
        'Total Bytes Sent': data['end']['sum_sent']['bytes'],
        'Total Bytes Received': data['end']['sum_received']['bytes'],
        'Average Throughput (Mbps)': data['end']['sum_sent']['bits_per_second'] / 1e6,
        'Total Retransmits': data['end']['sum_sent']['retransmits'],
        'CPU Utilization (%)': data['end']['cpu_utilization_percent']['host_total'] * 100
    }

# Create summary DataFrame
summary_data = {
    'Baseline TCP': get_summary_stats(baseline_tcp),
    'Baseline UDP': get_summary_stats(baseline_udp)
}

summary_df = pd.DataFrame(summary_data)
summary_df

# %% [markdown]
# ## 2. Throughput Over Time Analysis

# %%
def extract_throughput_data(data):
    intervals = data['intervals']
    return pd.DataFrame([{
        'Time': interval['sum']['start'],
        'Throughput (Mbps)': interval['sum']['bits_per_second'] / 1e6,
        'Retransmits': interval['sum']['retransmits']
    } for interval in intervals])

# Extract throughput data
tcp_throughput = extract_throughput_data(baseline_tcp)
udp_throughput = extract_throughput_data(baseline_udp)

# Plot throughput over time
plt.figure(figsize=(12, 6))
plt.plot(tcp_throughput['Time'], tcp_throughput['Throughput (Mbps)'], label='TCP')
plt.plot(udp_throughput['Time'], udp_throughput['Throughput (Mbps)'], label='UDP')
plt.xlabel('Time (seconds)')
plt.ylabel('Throughput (Mbps)')
plt.title('Throughput Over Time Comparison')
plt.legend()
plt.grid(True)
plt.show()

# %% [markdown]
# ## 3. Statistical Analysis of Throughput

# %%
# Calculate throughput statistics
throughput_stats = pd.DataFrame({
    'TCP': tcp_throughput['Throughput (Mbps)'],
    'UDP': udp_throughput['Throughput (Mbps)']
}).describe()

throughput_stats

# %% [markdown]
# ## 4. Retransmission Analysis

# %%
# Plot retransmissions over time
plt.figure(figsize=(12, 6))
plt.plot(tcp_throughput['Time'], tcp_throughput['Retransmits'], label='TCP')
plt.plot(udp_throughput['Time'], udp_throughput['Retransmits'], label='UDP')
plt.xlabel('Time (seconds)')
plt.ylabel('Number of Retransmissions')
plt.title('Retransmissions Over Time')
plt.legend()
plt.grid(True)
plt.show()

# %% [markdown]
# ## 5. CPU Utilization Analysis

# %%
def get_cpu_utilization(data):
    return {
        'Host Total': data['end']['cpu_utilization_percent']['host_total'] * 100,
        'Host User': data['end']['cpu_utilization_percent']['host_user'] * 100,
        'Host System': data['end']['cpu_utilization_percent']['host_system'] * 100,
        'Remote Total': data['end']['cpu_utilization_percent']['remote_total'] * 100,
        'Remote User': data['end']['cpu_utilization_percent']['remote_user'] * 100,
        'Remote System': data['end']['cpu_utilization_percent']['remote_system'] * 100
    }

# Create CPU utilization DataFrame
cpu_data = {
    'TCP': get_cpu_utilization(baseline_tcp),
    'UDP': get_cpu_utilization(baseline_udp)
}

cpu_df = pd.DataFrame(cpu_data)

# Plot CPU utilization
plt.figure(figsize=(12, 6))
cpu_df.plot(kind='bar')
plt.title('CPU Utilization Comparison')
plt.xlabel('CPU Metrics')
plt.ylabel('Utilization (%)')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# %% [markdown]
# ## 6. Packet Loss Analysis

# %%
def calculate_packet_loss(data):
    bytes_sent = data['end']['sum_sent']['bytes']
    bytes_received = data['end']['sum_received']['bytes']
    return ((bytes_sent - bytes_received) / bytes_sent) * 100

# Calculate packet loss percentages
packet_loss = {
    'TCP': calculate_packet_loss(baseline_tcp),
    'UDP': calculate_packet_loss(baseline_udp)
}

# Plot packet loss
plt.figure(figsize=(8, 6))
plt.bar(packet_loss.keys(), packet_loss.values())
plt.title('Packet Loss Percentage')
plt.xlabel('Protocol')
plt.ylabel('Packet Loss (%)')
plt.show()

# %% [markdown]
# ## 7. Summary of Findings
# 
# Based on the analysis above, here are the key findings:
# 
# 1. **Throughput Performance**:
#    - TCP average throughput: {:.2f} Mbps
#    - UDP average throughput: {:.2f} Mbps
# 
# 2. **Reliability**:
#    - TCP retransmissions: {} packets
#    - UDP retransmissions: {} packets
# 
# 3. **CPU Utilization**:
#    - TCP host CPU usage: {:.2f}%
#    - UDP host CPU usage: {:.2f}%
# 
# 4. **Packet Loss**:
#    - TCP packet loss: {:.2f}%
#    - UDP packet loss: {:.2f}%
# 
# These results provide insights into the performance characteristics of both protocols under the test conditions. 