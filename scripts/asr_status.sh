#!/usr/bin/env bash
set -euo pipefail

RG="${1:-}"
VAULT="${2:-}"

if [[ -z "$RG" || -z "$VAULT" ]]; then
  cat <<'EOF'
Usage:
  ./scripts/asr_status.sh <recovery-vault-resource-group> <recovery-vault-name>

Example:
  ./scripts/asr_status.sh rg-asr-test01-jpe rsv-asr-test01-jpe-abcde
EOF
  exit 1
fi

command -v az >/dev/null 2>&1 || { echo "az CLI is required" >&2; exit 1; }

az extension add --name site-recovery --upgrade >/dev/null

echo "Recovery Services Vault: $VAULT"
echo "Resource Group         : $RG"
echo

echo "== ASR Fabrics =="
az site-recovery fabric list \
  --resource-group "$RG" \
  --vault-name "$VAULT" \
  -o table

echo
echo "== Replication Policies =="
az site-recovery policy list \
  --resource-group "$RG" \
  --vault-name "$VAULT" \
  -o table

echo
echo "== Replicated Items =="
echo "Azure CLI site-recovery commands require fabric/container names for detailed item query."
echo "Use Azure Portal: Recovery Services vault -> Replicated items -> check Protected/Healthy status."
