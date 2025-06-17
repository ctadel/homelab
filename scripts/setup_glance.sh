#!/bin/bash
set -e

VERSION="v0.8.4"
BASE_URL="https://github.com/glanceapp/glance/releases/download/${VERSION}"
INSTALL_DIR="/opt/glance"
SERVICE_FILE="/etc/systemd/system/glance.service"

# ---- Step 1: Get Config Directory ----
if [[ "$1" == "--config" && -n "$2" ]]; then
  CONFIG_DIR="$2"
else
  read -rp "📁 Enter the path to your Glance config directory: " CONFIG_DIR
fi
CONFIG_DIR="${CONFIG_DIR%/}"

if [ ! -d "$CONFIG_DIR" ]; then
  echo "❌ Directory not found: $CONFIG_DIR"
  exit 1
fi

CONFIG_FILE="$CONFIG_DIR/glance.yml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ glance.yml not found in: $CONFIG_DIR"
  exit 1
fi

# ---- Step 2: Detect Architecture ----
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)   FILENAME="glance-linux-amd64.tar.gz" ;;
  aarch64)  FILENAME="glance-linux-arm64.tar.gz" ;;
  armv7l)   FILENAME="glance-linux-armv7.tar.gz" ;;
  i386|i686)FILENAME="glance-linux-386.tar.gz" ;;
  *)        echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ---- Step 3: Install Glance Binary ----
echo "📁 Creating install directory at $INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

echo "📥 Downloading Glance binary: $FILENAME"
curl -L "${BASE_URL}/${FILENAME}" -o /tmp/glance.tar.gz

echo "📦 Extracting Glance"
tar -xzf /tmp/glance.tar.gz -C /tmp
sudo mv /tmp/glance "$INSTALL_DIR/glance"
sudo chmod +x "$INSTALL_DIR/glance"
rm /tmp/glance.tar.gz

# ---- Step 4: Handle existing systemd service ----
if [ -f "$SERVICE_FILE" ]; then
  echo "⚠️  systemd service $SERVICE_FILE already exists."
  read -rp "Do you want to overwrite it? (y/n): " yn
  case $yn in
    [Yy]* )
      echo "Removing old service file..."
      sudo systemctl stop glance || true
      sudo systemctl disable glance || true
      sudo rm -f "$SERVICE_FILE"
      ;;
    * )
      echo "Aborting installation."
      exit 0
      ;;
  esac
fi

# ---- Step 5: Create systemd service ----
echo "🛠️ Setting up systemd service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Glance Dashboard
After=network.target

[Service]
ExecStart=$INSTALL_DIR/glance --config $CONFIG_FILE
Restart=always
User=root
WorkingDirectory=$CONFIG_DIR

[Install]
WantedBy=multi-user.target
EOF

# ---- Step 6: Start Service ----
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable glance
sudo systemctl restart glance

echo "✅ Glance installed and running as a service!"
echo "📂 Config directory: $CONFIG_DIR"
echo "🌐 Access it at http://localhost:8080"
