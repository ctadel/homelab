#!/bin/bash

set -euo pipefail

# List of required networks
DOCKER_NETWORKS=(
  cloudnet
  homenet
  infranet
  medianet
  watchnet
  servicenet
  webappnet
)

# Function to check and create a network
create_network() {
  local network_name="$1"

  if docker network inspect "$network_name" >/dev/null 2>&1; then
    echo "✅ Network '$network_name' already exists. Skipping."
  else
    echo "➕ Creating network: $network_name"
    docker network create --driver bridge "$network_name"
    echo "✅ Created network '$network_name'"
  fi
}

# Main
echo "🚀 Starting Docker network creation..."
for net in "${DOCKER_NETWORKS[@]}"; do
  create_network "$net"
done

echo "🏁 All networks checked/created successfully."
