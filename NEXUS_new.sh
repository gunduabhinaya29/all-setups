#!/bin/bash

# Update system
yum update -y

# Install dependencies
yum install -y wget java-17-amazon-corretto

# Create app directory
mkdir -p /app
cd /app || exit 1

# Download Nexus
wget https://download.sonatype.com/nexus/3/nexus-3.79.1-04-linux-x86_64.tar.gz

# Extract Nexus
tar -xvf nexus-3.79.1-04-linux-x86_64.tar.gz

# Rename folder
mv nexus-3.79.1-04 nexus

# Create nexus user
id nexus &>/dev/null || useradd nexus

# Set ownership
chown -R nexus:nexus /app/nexus
chown -R nexus:nexus /app/sonatype-work

# Configure Nexus to run as nexus user
sed -i 's/^#run_as_user=""/run_as_user="nexus"/' /app/nexus/bin/nexus

# Create systemd service
cat <<EOF >/etc/systemd/system/nexus.service
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Enable and start Nexus
systemctl enable nexus
systemctl start nexus

# Show status
systemctl status nexus --no-pager
