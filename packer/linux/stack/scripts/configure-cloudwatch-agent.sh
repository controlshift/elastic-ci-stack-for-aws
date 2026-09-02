#!/usr/bin/env bash
set -euo pipefail

# Unlike upstream, we only ship host metrics (memory, CPU, swap, root disk) to
# CloudWatch. Log forwarding never earned its cost, so the rsyslog configs and
# the logs section of the agent config are deliberately absent.

echo "Configuring cloudwatch agent..."

echo "Adding amazon-cloudwatch-agent config..."
sudo cp /tmp/conf/cloudwatch-agent/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo "Configuring amazon-cloudwatch-agent to start at boot"
sudo systemctl enable amazon-cloudwatch-agent
