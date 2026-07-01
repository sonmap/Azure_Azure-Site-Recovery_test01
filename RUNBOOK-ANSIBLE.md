# Ansible Runbook

This repository separates infrastructure provisioning and OS/application configuration.

- Terraform creates Azure infrastructure, VM, Load Balancer, Traffic Manager, and ASR resources.
- Ansible configures the VM operating system and nginx application.

## Flow

```text
1. terraform apply
2. run Ansible against the Korea Central primary VM
3. verify nginx through the primary Load Balancer and Traffic Manager
4. confirm ASR replication is healthy
5. run Test Failover
6. attach recovered VM NIC to Japan East Load Balancer
7. run Ansible again only if you want to reconfigure the recovered VM
8. verify Japan East Load Balancer and Traffic Manager failover
```

## Why Azure Run Command mode

The VM in this lab does not have a direct Public IP. Because of that, this runbook uses Ansible on localhost and calls Azure VM Run Command. This allows OS and application configuration without direct SSH access.

## Prerequisites

```bash
az login
az account show
python3 -m pip install --user ansible
export PATH="$HOME/.local/bin:$PATH"
ansible --version
```

## Apply infrastructure

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## Configure primary VM with Ansible

```bash
chmod +x scripts/*.sh
./scripts/run_ansible_primary.sh
```

This installs nginx, creates `/var/www/html/index.html`, creates `/var/www/html/health`, and restarts nginx.

## Verify primary service

```bash
curl -v "http://$(terraform output -raw primary_lb_public_ip)/health"
curl -v "http://$(terraform output -raw traffic_manager_fqdn)/"
```

## Run Ansible against a selected VM

Use this after ASR Test Failover if you want to reconfigure the recovered VM manually.

```bash
./scripts/run_ansible_vm.sh <resource-group> <vm-name> "Japan East DR"
```

## DR test flow

```bash
az vm list \
  --resource-group $(terraform output -raw dr_resource_group_name) \
  -o table
```

Attach the recovered VM to the Japan East Load Balancer backend pool:

```bash
./scripts/attach_recovered_vm_to_jpe_lb.sh \
  -g $(terraform output -raw dr_resource_group_name) \
  -v <RECOVERED_VM_NAME> \
  -l $(terraform output -raw dr_lb_name) \
  -p $(terraform output -raw dr_lb_backend_pool_name)
```

Verify Japan East service:

```bash
curl -v "http://$(terraform output -raw jpe_lb_public_ip)/health"
```

## Design note

Because ASR replicates the VM disk, the nginx configuration applied to the primary VM by Ansible should be replicated to the DR VM after replication becomes healthy. Running Ansible against the recovered VM is optional and mainly useful for validation or post-failover customization.
