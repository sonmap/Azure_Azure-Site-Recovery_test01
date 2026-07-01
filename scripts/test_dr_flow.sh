#!/usr/bin/env bash
set -euo pipefail

TM_FQDN="${1:-}"
JPE_IP="${2:-}"

if [[ -z "$TM_FQDN" || -z "$JPE_IP" ]]; then
  echo "Usage: ./scripts/test_dr_flow.sh <traffic-manager-fqdn> <japan-east-lb-public-ip>"
  exit 1
fi

echo "== Same URL through Traffic Manager =="
curl -v "http://${TM_FQDN}/health"
curl -v "http://${TM_FQDN}/"

echo "== Japan East LB direct health =="
curl -v "http://${JPE_IP}/health"

echo "If Japan East direct health is OK but the same URL still points to Korea, wait for DNS TTL and Traffic Manager monitoring, or disable the primary endpoint for a controlled DR test."
