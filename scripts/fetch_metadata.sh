#!/bin/sh
set -e

NETWORKS="enjin-matrixchain canary-matrixchain enjin-relaychain canary-relaychain"

get_network_config() {
  case "$1" in
  enjin-matrixchain) echo "wss://archive.matrix.blockchain.enjin.io,matrix,production" ;;
  enjin-relaychain) echo "wss://rpc.relay.blockchain.enjin.io,enjin,production" ;;
  canary-matrixchain) echo "wss://archive.matrix.canary.enjin.io,matrix,canary" ;;
  canary-relaychain) echo "wss://rpc.relay.canary.enjin.io,enjin,canary" ;;
  *) return 1 ;;
  esac
}

rpc_call() {
  url=$(echo "$1" | sed 's/wss:/https:/')
  curl -s --connect-timeout 30 \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$2\",\"params\":[]}" \
    "$url"
}

fetch_spec_version() {
  response=$(rpc_call "$1" "state_getRuntimeVersion")
  version=$(echo "$response" | jq -r '.result.specVersion // empty')

  [ -z "$version" ] || [ "$version" = "null" ] && return 1
  echo "$version"
}

fetch_metadata() {
  response=$(rpc_call "$1" "state_getMetadata")
  metadata=$(echo "$response" | jq -r '.result // empty')

  [ -z "$metadata" ] || [ "$metadata" = "null" ] && return 1
  echo "$metadata" | grep -q '^0x.\{8,\}' || return 1
  echo "$metadata"
}

write_metadata_file() {
  dir="$1/lib/consts/$2/$3"
  mkdir -p "$dir"
  cat >"$dir/v$4.dart" <<EOF
const v$4 =
    '$5';
EOF
}

update_exports() {
  export_file="$1/lib/consts/$2/$3/$3.dart"
  export_line="export 'v$4.dart';"

  touch "$export_file"
  grep -Fxq "$export_line" "$export_file" || echo "$export_line" >>"$export_file"

  grep '^export ' "$export_file" |
    awk -F"v|\\.dart" '{print $2, $0}' |
    sort -n |
    awk '{$1=""; print substr($0,2)}' >"$export_file.tmp"
  mv "$export_file.tmp" "$export_file"
}

process_network() {
  network="$1"
  config=$(get_network_config "$network") || return 1

  rpc=$(echo "$config" | cut -d, -f1)
  category=$(echo "$config" | cut -d, -f2)
  environment=$(echo "$config" | cut -d, -f3)
  base="$2"

  echo "Processing $network..."

  version=$(fetch_spec_version "$rpc") || return 1
  metadata=$(fetch_metadata "$rpc") || return 1

  write_metadata_file "$base" "$category" "$environment" "$version" "$metadata"
  update_exports "$base" "$category" "$environment" "$version"

  echo "$network: v$version -> lib/consts/$category/$environment/v$version.dart"
  echo "REMINDER: Update lib/consts/$category/$category.dart to include case $version in the ${environment}Spec function"
}

command -v jq >/dev/null || {
  echo "ERROR: jq required" >&2
  exit 1
}
command -v curl >/dev/null || {
  echo "ERROR: curl required" >&2
  exit 1
}

BASE=$(cd "$(dirname "$0")/.." && pwd)

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: $0 [network]"
  echo "Networks: $NETWORKS"
  exit 0
fi

if [ $# -eq 1 ]; then
  process_network "$1" "$BASE" || {
    echo "Unknown network: $NETWORKS" >&2
    exit 1
  }
else
  for network in $NETWORKS; do
    process_network "$network" "$BASE" || echo "$network failed" >&2
  done
fi
