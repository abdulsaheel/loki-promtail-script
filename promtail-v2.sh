#!/bin/bash

# Promtail Installation Script for Amazon Linux 2

# Variables
PROMTAIL_VERSION="2.8.0"  # Change this to the desired Promtail version
PROMTAIL_CONFIG_DIR="/etc/promtail"
PROMTAIL_BINARY="/usr/local/bin/promtail"
LOKI_URL="http://app-loki.abdulsahil.me:3100/loki/api/v1/push"
JOB_NAME="BTC Mainnet Node"  # Change this to your desired job name
TECH_LABEL="backend"  # Change this to your desired tech label

# Step 1: Update the System
echo "Updating the system..."
sudo yum update -y

# Step 2: Install Required Packages
echo "Installing required packages..."
sudo yum install -y unzip wget

# Step 3: Download Promtail
echo "Downloading Promtail..."
wget -q "https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip" -O /tmp/promtail-linux-amd64.zip

# Step 4: Extract Promtail Binary
echo "Extracting Promtail..."
unzip -q /tmp/promtail-linux-amd64.zip -d /tmp

# Step 5: Move Promtail Binary to /usr/local/bin
echo "Moving Promtail binary to /usr/local/bin..."
sudo mv /tmp/promtail-linux-amd64 "${PROMTAIL_BINARY}"
sudo chmod a+x "${PROMTAIL_BINARY}"

# Step 6: Create Promtail Configuration Directory
echo "Creating Promtail configuration directory..."
sudo mkdir -p "${PROMTAIL_CONFIG_DIR}"

# Step 7: Create Promtail Configuration File
echo "Creating Promtail configuration file..."
sudo tee "${PROMTAIL_CONFIG_DIR}/promtail-local-config.yaml" <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: ${LOKI_URL}

scrape_configs:
  - job_name: ${JOB_NAME}
    static_configs:
      - targets:
          - localhost
        labels:
          job: ${JOB_NAME}
          tech: ${TECH_LABEL}
          __path__: /var/log/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) - (?P<level>\w+) - (?P<message>.*)$'
      - labels:
          level: level
EOF

# Step 8: Create Systemd Service for Promtail
echo "Creating Promtail systemd service..."
sudo tee /etc/systemd/system/promtail.service <<EOF
[Unit]
Description=Promtail
After=network.target

[Service]
Type=simple
ExecStart=${PROMTAIL_BINARY} -config.file=${PROMTAIL_CONFIG_DIR}/promtail-local-config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Step 9: Reload Systemd and Start Promtail
echo "Reloading systemd and starting Promtail..."
sudo systemctl daemon-reload
sudo systemctl start promtail
sudo systemctl enable promtail

# Step 10: Verify Promtail Status
echo "Checking Promtail status..."
sudo systemctl status promtail --no-pager

# Step 11: Clean Up
echo "Cleaning up temporary files..."
rm -f /tmp/promtail-linux-amd64.zip /tmp/promtail-linux-amd64

echo "Promtail installation completed successfully!"
