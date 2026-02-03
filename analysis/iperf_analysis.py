# %% [markdown]
# # iperf Test Results Analysis
#
# This script analyzes the results from iperf tests comparing TCP and UDP
# performance under different conditions.
#
# Usage:
#   python iperf_analysis.py <log_directory> [output_directory]

# %%
import json
import sys
import os
import glob
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from datetime import datetime

# Set style for better visualizations
try:
    plt.style.use('seaborn-v0_8')
except OSError:
    plt.style.use('seaborn')
sns.set_palette('husl')

# %%
# Load the test results
def load_iperf_results(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)


def discover_test_files(log_dir):
    """Auto-discover iperf3 JSON files in the log directory."""
    results = {
        'tcp_baseline': [],
        'udp_baseline': [],
        'tcp_flood': [],
        'udp_flood': [],
    }
    for subdir in ['tcp_test', 'udp_test', 'wifi_test']:
        pattern = os.path.join(log_dir, subdir, '*.json')
        for f in sorted(glob.glob(pattern)):
            if f.endswith('.server'):
                continue
            basename = os.path.basename(f)
            if basename.startswith('tcp_baseline'):
                results['tcp_baseline'].append(f)
            elif basename.startswith('udp_baseline'):
                results['udp_baseline'].append(f)
            elif basename.startswith('udp_flood'):
                results['udp_flood'].append(f)
            elif basename.startswith('tcp_flood'):
                results['tcp_flood'].append(f)
    return results


def is_udp(data):
    """Check if iperf3 result is UDP based on protocol field."""
    return data.get('start', {}).get('test_start', {}).get('protocol') == 'UDP'


# %% [markdown]
# ## 1. Overall Performance Summary

# %%
def get_summary_stats(data):
    end = data['end']

    if is_udp(data):
        summary = end.get('sum', {})
        return {
            'Total Bytes': summary.get('bytes', 0),
            'Average Throughput (Mbps)': summary.get('bits_per_second', 0) / 1e6,
            'Jitter (ms)': summary.get('jitter_ms', 0),
            'Lost Packets': summary.get('lost_packets', 0),
            'Total Packets': summary.get('packets', 0),
            'Lost Percent': summary.get('lost_percent', 0),
            'CPU Utilization (%)': end.get('cpu_utilization_percent', {}).get('host_total', 0)
        }
    else:
        return {
            'Total Bytes Sent': end['sum_sent']['bytes'],
            'Total Bytes Received': end['sum_received']['bytes'],
            'Average Throughput (Mbps)': end['sum_sent']['bits_per_second'] / 1e6,
            'Total Retransmits': end['sum_sent'].get('retransmits', 0),
            'CPU Utilization (%)': end.get('cpu_utilization_percent', {}).get('host_total', 0)
        }


# %% [markdown]
# ## 2. Throughput Over Time Analysis

# %%
def extract_throughput_data(data):
    intervals = data['intervals']
    rows = []
    for interval in intervals:
        row = {
            'Time': interval['sum']['start'],
            'Throughput (Mbps)': interval['sum']['bits_per_second'] / 1e6,
        }
        if not is_udp(data):
            row['Retransmits'] = interval['sum'].get('retransmits', 0)
        else:
            row['Packets'] = interval['sum'].get('packets', 0)
        rows.append(row)
    return pd.DataFrame(rows)


# %% [markdown]
# ## 3. CPU Utilization Analysis

# %%
def get_cpu_utilization(data):
    cpu = data['end'].get('cpu_utilization_percent', {})
    return {
        'Host Total': cpu.get('host_total', 0),
        'Host User': cpu.get('host_user', 0),
        'Host System': cpu.get('host_system', 0),
        'Remote Total': cpu.get('remote_total', 0),
        'Remote User': cpu.get('remote_user', 0),
        'Remote System': cpu.get('remote_system', 0),
    }


# %% [markdown]
# ## 4. Packet / Data Loss Analysis

# %%
def calculate_loss(data):
    """Calculate packet loss (UDP) or data loss (TCP) percentage."""
    if is_udp(data):
        summary = data['end'].get('sum', {})
        lost = summary.get('lost_packets', 0)
        total = summary.get('packets', 0)
        return (lost / total * 100) if total > 0 else 0
    else:
        bytes_sent = data['end']['sum_sent']['bytes']
        bytes_received = data['end']['sum_received']['bytes']
        return ((bytes_sent - bytes_received) / bytes_sent * 100) if bytes_sent > 0 else 0


# %% [markdown]
# ## 5. Generate Analysis

# %%
def run_analysis(log_dir, output_dir):
    """Run the full analysis pipeline."""
    os.makedirs(output_dir, exist_ok=True)

    files = discover_test_files(log_dir)

    # Collect all available data
    datasets = {}
    for category, paths in files.items():
        for path in paths:
            label = os.path.splitext(os.path.basename(path))[0]
            try:
                datasets[label] = load_iperf_results(path)
            except (json.JSONDecodeError, FileNotFoundError) as e:
                print(f"Warning: Could not load {path}: {e}")

    if not datasets:
        print(f"No valid iperf3 JSON files found in {log_dir}")
        return

    # Print summary stats
    print("=" * 60)
    print("PERFORMANCE SUMMARY")
    print("=" * 60)
    for label, data in datasets.items():
        print(f"\n--- {label} ---")
        stats = get_summary_stats(data)
        for key, value in stats.items():
            if isinstance(value, float):
                print(f"  {key}: {value:.2f}")
            else:
                print(f"  {key}: {value}")

    # Plot throughput over time for each dataset
    plt.figure(figsize=(12, 6))
    for label, data in datasets.items():
        throughput = extract_throughput_data(data)
        plt.plot(throughput['Time'], throughput['Throughput (Mbps)'], label=label)
    plt.xlabel('Time (seconds)')
    plt.ylabel('Throughput (Mbps)')
    plt.title('Throughput Over Time')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'throughput_over_time.png'), dpi=150)
    plt.close()

    # Plot retransmissions for TCP datasets
    tcp_datasets = {k: v for k, v in datasets.items() if not is_udp(v)}
    if tcp_datasets:
        plt.figure(figsize=(12, 6))
        for label, data in tcp_datasets.items():
            throughput = extract_throughput_data(data)
            if 'Retransmits' in throughput.columns:
                plt.plot(throughput['Time'], throughput['Retransmits'], label=label)
        plt.xlabel('Time (seconds)')
        plt.ylabel('Number of Retransmissions')
        plt.title('Retransmissions Over Time')
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'retransmissions.png'), dpi=150)
        plt.close()

    # CPU utilization comparison
    cpu_data = {}
    for label, data in datasets.items():
        cpu_data[label] = get_cpu_utilization(data)
    cpu_df = pd.DataFrame(cpu_data)
    plt.figure(figsize=(12, 6))
    cpu_df.plot(kind='bar')
    plt.title('CPU Utilization Comparison')
    plt.xlabel('CPU Metrics')
    plt.ylabel('Utilization (%)')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'cpu_utilization.png'), dpi=150)
    plt.close()

    # Loss comparison
    loss_data = {label: calculate_loss(data) for label, data in datasets.items()}
    plt.figure(figsize=(8, 6))
    plt.bar(loss_data.keys(), loss_data.values())
    plt.title('Packet / Data Loss Percentage')
    plt.xlabel('Test')
    plt.ylabel('Loss (%)')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'loss.png'), dpi=150)
    plt.close()

    # Print loss summary
    print("\n" + "=" * 60)
    print("LOSS SUMMARY")
    print("=" * 60)
    for label, loss in loss_data.items():
        loss_type = "Packet loss" if is_udp(datasets[label]) else "Data loss"
        print(f"  {label}: {loss_type} = {loss:.2f}%")

    print(f"\nPlots saved to {output_dir}/")


# %%
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python iperf_analysis.py <log_directory> [output_directory]")
        print("Example: python iperf_analysis.py logs/20250507_032111 analysis/output")
        sys.exit(1)

    log_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.join('analysis', 'output')
    run_analysis(log_dir, output_dir)
