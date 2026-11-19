# Modular Terraform IaC — Django ToDo App on Microsoft Azure

Modular **Terraform (HCL)** infrastructure for deploying a Django web application on **Microsoft Azure**, featuring remote state management in Azure Blob Storage, automated Linux VM bootstrapping via Azure `CustomScript` extension, and CI validation with GitHub Actions.

## Architecture Overview

The configuration follows a root/child module pattern to separate network, storage, and compute layers for better maintainability and reuse:

- **Network Module (`modules/network`):** Provisions a Virtual Network (`10.0.0.0/16`), Subnet (`10.0.0.0/24`), Network Security Group (`defaultnsg`), and a dynamic Public IP (`linuxboxpip`) with a unique DNS label.
- **Storage Module (`modules/storage`):** Provisions an Azure Storage Account and Blob Container (`task-artifacts`) for storing deployment artifacts.
- **Compute Module (`modules/compute`):** Provisions a Network Interface, an **Ubuntu 22.04** Linux VM (`Standard_B1s`) with SSH key-based authentication, and an Azure `CustomScript` VM Extension running `install-app.sh` to configure the `systemd` service (`todoapp.service`).
- **Remote State (`backend.tf`):** Configured `azurerm` backend storing `terraform.tfstate` in an Azure Blob Storage container (`tfstate`) with state locking and deterministic provider versions via `.terraform.lock.hcl`.
- **CI Pipeline (`.github/workflows/terraform-validate.yml`):** Automated formatting, validation, and OIDC-ready (`id-token: write`) GitHub Actions workflow.

## Tech Stack

- **Infrastructure as Code:** Terraform (HCL)
- **Cloud Provider:** Microsoft Azure (`azurerm` provider), Azure CLI
- **CI/CD:** GitHub Actions (OIDC authentication)
- **OS & Services:** Ubuntu 22.04 LTS, Bash, `systemd`
- **Application:** Python, Django

## Project Structure

```text
├── .github/workflows/
│   └── terraform-validate.yml   # Automated CI workflow for Terraform validation
├── app/                         # Django ToDo web application & systemd unit (todoapp.service)
├── modules/
│   ├── network/                 # VNet, Subnet, NSG firewall rules, Public IP
│   ├── storage/                 # Storage Account & Blob Container
│   └── compute/                 # NIC, Ubuntu 22.04 VM, CustomScript Extension
├── .terraform.lock.hcl          # Provider dependency lock file
├── backend.tf                   # Azure Blob Storage remote backend configuration
├── main.tf                      # Root module orchestrating child modules
├── variables.tf                 # Parameterized input variables
├── outputs.tf                   # Exposed endpoints & resource identifiers
└── install-app.sh               # Automated server bootstrap & systemd setup script
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.5`
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) authenticated to an active Azure subscription
- An SSH key pair for VM access (`~/.ssh/id_rsa.pub`)

## Deployment & Verification

### 1. Authenticate & Configure Sensitive Variables

Never commit real credentials, SSH private keys, or `*.tfvars` files to version control. Authenticate via Azure CLI and pass sensitive parameters through environment variables (`TF_VAR_`) or Azure Key Vault:

```bash
az login
export TF_VAR_ssh_key_public="$(cat ~/.ssh/id_rsa.pub)"
export TF_VAR_location="westus2"
```

### 2. Initialize, Format & Validate

Initialize the Terraform working directory (connecting to the remote backend), verify canonical formatting, and validate configuration syntax:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
```

### 3. Plan & Apply Infrastructure Changes

Generate and review an execution plan before provisioning cloud resources:

```bash
terraform plan -out=tfplan
terraform apply "tfplan"
```

### 4. Verify Provisioned Resources & Application Health

Inspect Terraform outputs, confirm running resources in Azure, and verify the `systemd` service status on the target VM:

```bash
terraform output
az resource list --resource-group rg-todolist-prod --output table

# Check application service health on the VM via SSH:
sudo systemctl status todoapp.service
journalctl -u todoapp.service -n 50 --no-pager
```

### 5. Teardown

Destroy all provisioned cloud resources when finished to prevent unnecessary billing:

```bash
terraform destroy
```