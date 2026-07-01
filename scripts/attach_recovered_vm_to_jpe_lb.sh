#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  attach_recovered_vm_to_jpe_lb.sh -g <resource-group> -v <vm-name> -l <lb-name> -p <backend-pool-name>

Example:
  ./scripts/attach_recovered_vm_to_jpe_lb.sh \
    -g rg-asr-test01-jpe \
    -v vm-asr-test01-web01-krc-test \
    -l lb-asr-test01-jpe \
    -p be-asr-test01-jpe

Purpose:
  ASR Test Failover or Failover creates a VM/NIC in Japan East.
  This script attaches the recovered VM NIC to the Japan East Public Load Balancer backend pool.
EOF
}

RG=""
VM_NAME=""
LB_NAME=""
POOL_NAME=""
IPCONFIG_NAME="ipconfig1"

while getopts ":g:v:l:p:i:h" opt; do
  case "$opt" in
    g) RG="$OPTARG" ;;
    v) VM_NAME="$OPTARG" ;;
    l) LB_NAME="$OPTARG" ;;
    p) POOL_NAME="$OPTARG" ;;
    i) IPCONFIG_NAME="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [[ -z "$RG" || -z "$VM_NAME" || -z "$LB_NAME" || -z "$POOL_NAME" ]]; then
  usage
  exit 1
fi

command -v az >/dev/null 2>&1 || { echo "az CLI is required" >&2; exit 1; }

NIC_ID=$(az vm show \
  --resource-group "$RG" \
  --name "$VM_NAME" \
  --query "networkProfile.networkInterfaces[0].id" \
  -o tsv)

NIC_NAME=$(basename "$NIC_ID")

echo "Recovered VM      : $VM_NAME"
echo "Recovered NIC     : $NIC_NAME"
echo "DR Load Balancer  : $LB_NAME"
echo "DR Backend Pool   : $POOL_NAME"

az network nic ip-config address-pool add \
  --resource-group "$RG" \
  --nic-name "$NIC_NAME" \
  --ip-config-name "$IPCONFIG_NAME" \
  --lb-name "$LB_NAME" \
  --address-pool "$POOL_NAME"

az vm run-command invoke \
  --resource-group "$RG" \
  --name "$VM_NAME" \
  --command-id RunShellScript \
  --scripts "sudo systemctl enable nginx; sudo systemctl restart nginx; sudo systemctl status nginx --no-pager" \
  -o table

echo "Done. Test the Japan East LB public IP with: curl http://<jpe_lb_public_ip>/health"
