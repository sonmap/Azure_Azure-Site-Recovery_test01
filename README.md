# Azure Site Recovery Test01 - Korea Central to Japan East

이 저장소는 Azure VM 1대를 Korea Central(서울)에 만들고, nginx 웹 페이지를 올린 뒤 Azure Site Recovery(ASR)로 Japan East(일본) DR 테스트를 수행하기 위한 Terraform 샘플입니다.

## 목표 구성

```text
Normal
Client URL
  -> Azure Traffic Manager DNS
  -> Korea Central Public Load Balancer
  -> Korea Central VM / nginx

DR / Test Failover
Client URL 동일
  -> Azure Traffic Manager DNS
  -> Japan East Public Load Balancer
  -> ASR Test Failover 또는 Failover VM / nginx
```

> 여기서 ALB는 Azure Standard Public Load Balancer 기준입니다. Application Gateway를 쓰는 구조로 바꾸려면 `azurerm_lb` 부분을 `azurerm_application_gateway`로 대체하면 됩니다.

## 리전

| 역할 | Azure region |
|---|---|
| Primary | `koreacentral` |
| DR | `japaneast` |

## 포함 리소스

- Korea Central Resource Group / VNet / Subnet
- Japan East Resource Group / VNet / Subnet
- Korea Central nginx VM
- Korea Central Public Load Balancer
- Japan East Public Load Balancer
- Azure Traffic Manager Priority routing
- Recovery Services Vault
- ASR Fabric / Protection Container / Replication Policy / Mapping
- ASR replicated VM 기본 리소스
- 장애테스트 후 Japan East LB Backend Pool 연결 스크립트

## 실행 순서

### 1. 변수 파일 준비

```bash
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

최소 수정 항목:

```hcl
admin_username     = "azureuser"
admin_source_cidr  = "x.x.x.x/32"
ssh_public_key     = "ssh-rsa AAAA..."
traffic_manager_relative_name = "sonmap-asr-test01"
```

### 2. Terraform 배포

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

### 3. 정상 서비스 확인

```bash
terraform output service_url
terraform output traffic_manager_fqdn
curl -v "http://$(terraform output -raw traffic_manager_fqdn)/health"
curl -v "http://$(terraform output -raw traffic_manager_fqdn)/"
```

정상 상태에서는 Traffic Manager가 Korea Central Public LB로 응답합니다.

### 4. ASR 복제 상태 확인

Azure Portal 기준:

```text
Recovery Services vault
  -> Replicated items
  -> VM 상태 Protected 확인
```

CLI 확인 예시는 `scripts/asr_status.sh`를 사용합니다.

```bash
chmod +x scripts/*.sh
./scripts/asr_status.sh \
  $(terraform output -raw dr_resource_group_name) \
  $(terraform output -raw recovery_services_vault_name)
```

### 5. 장애 테스트

테스트 목적이면 먼저 ASR `Test failover`를 수행합니다.

```text
Recovery Services vault
  -> Replicated items
  -> Source VM 선택
  -> Test failover
  -> Target: Japan East test VNet/Subnet 선택
```

Test failover VM이 Japan East에 생성된 뒤 아래 스크립트로 Japan East Public LB Backend Pool에 NIC를 연결합니다.

```bash
chmod +x scripts/*.sh
./scripts/attach_recovered_vm_to_jpe_lb.sh \
  -g $(terraform output -raw dr_resource_group_name) \
  -v <RECOVERED_VM_NAME> \
  -l $(terraform output -raw dr_lb_name) \
  -p $(terraform output -raw dr_lb_backend_pool_name)
```

그 후 Japan East LB 직접 확인:

```bash
curl -v "http://$(terraform output -raw jpe_lb_public_ip)/health"
```

Primary 장애 또는 Traffic Manager endpoint 상태 변경 후 동일 URL 확인:

```bash
curl -v "http://$(terraform output -raw traffic_manager_fqdn)/"
```

또는 검증 스크립트:

```bash
./scripts/test_dr_flow.sh \
  $(terraform output -raw traffic_manager_fqdn) \
  $(terraform output -raw jpe_lb_public_ip)
```

## 같은 URL 유지 방식

이 샘플은 외부 URL을 VM이나 LB Public IP에 직접 붙이지 않고 Traffic Manager FQDN에 붙입니다.

운영 도메인이 있으면 CNAME을 아래로 연결합니다.

```text
www.example.com CNAME <traffic_manager_fqdn>
```

Traffic Manager는 Priority routing을 사용합니다.

- Priority 1: Korea Central Public Load Balancer
- Priority 2: Japan East Public Load Balancer

Korea Central이 비정상이 되고 Japan East가 정상 응답하면 같은 URL로 Japan East 서비스가 응답합니다.

## 주의 사항

1. ASR는 복제 설정 후 즉시 failover가 되는 것이 아니라 초기 복제 완료가 필요합니다.
2. Test failover VM은 ASR가 생성하므로, 생성 후 Japan East LB Backend Pool에 NIC를 연결해야 합니다.
3. 실제 운영에서는 DNS TTL, 헬스체크 경로, 인증서, WAF/Application Gateway 여부를 별도 설계해야 합니다.
4. VM boot 시 nginx가 자동 기동되도록 cloud-init과 systemd를 구성했습니다.
5. 이 샘플은 학습/테스트 목적입니다. 운영에서는 Key Vault, Bastion, Private Access, Azure Policy, Monitor Alert, Backup 정책을 추가하세요.
