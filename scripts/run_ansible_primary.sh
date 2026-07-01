#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible-playbook command not found. Install Ansible first."
  echo "Example: python3 -m pip install --user ansible"
  exit 1
fi

RG=$(terraform output -raw primary_resource_group_name)
VM=$(terraform output -raw primary_vm_name)

ansible-playbook ansible/playbooks/configure_nginx_azure_run_command.yml \
  -e "resource_group=${RG}" \
  -e "vm_name=${VM}" \
  -e "role_label=Korea Central PRIMARY"

echo "Ansible nginx configuration completed for ${VM}."
