#!/bin/bash

set -e

OUTPUT_DIR=".config/portainer/templates"
ENV_FILE=".env"

mkdir -p "$OUTPUT_DIR"

# List of stacks with their corresponding Docker Compose files
declare -A stacks=(
  [mediaserver]="mediaserver/mediaserver.yml"
  [cloudserver]="cloudserver/cloudserver.yml"
  [homeserver]="homeserver/homeserver.yml"
  [monitoring]="monitoring/monitoring.yml"
  [infrastructure]="infrastructure/infrastructure.yml"
  [services]="services/services.yml"
  [webapps]="webapps/webapps.yml"
)

echo && echo "📦 Generating final Docker Compose files for Portainer..."

for stack in "${!stacks[@]}"; do
  compose_file="${stacks[$stack]}"
  output_file="$OUTPUT_DIR/compose.${stack}.yml"

  echo "🔧 Converting $compose_file → $output_file"
  docker compose --env-file="$ENV_FILE" -f "$compose_file" config > "$output_file"
done

echo && echo "✅ All custom templates for Portainer updated and saved to $OUTPUT_DIR." && echo
