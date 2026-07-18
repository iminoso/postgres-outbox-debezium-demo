#!/usr/bin/env bash
set -euo pipefail

connector_name="worker-outbox-cdc"
connect_url="${CONNECT_URL:-http://localhost:8083}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_file="$script_dir/../infrastructure/connect/worker-outbox-connector.json"

# PUT makes this safe to run again after changing the connector configuration.
curl --fail --silent --show-error \
  --retry 10 \
  --retry-connrefused \
  --request PUT \
  --header "Content-Type: application/json" \
  --data "@$config_file" \
  "$connect_url/connectors/$connector_name/config"

echo
printf 'Connector %s applied.\n' "$connector_name"
