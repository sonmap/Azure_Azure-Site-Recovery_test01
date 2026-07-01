#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <resource-group> <vm-name> [role-label]"
  exit 1
fi

cd "$(dirname "$0")/.."

RG="$1"
VM="$2"
ROLE_LABEL="${3:-Ansible Managed VM}"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible-playbook command not found. Install Ansible first."
  exit 1
fi

ansible-playbook ansible/playbooks/configure_nginx_azure_run_command.yml \
  -e "resource_group=${RG}" \
  -e "vm_name=${VM}" \
  -e "role_label=${ROLE_LABEL}"

echo "Ansible nginx configuration completed."
