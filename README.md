# avd-tf – Azure Government AVD Terraform Deployments

Terraform Infrastructure-as-Code for deploying Azure Virtual Desktop (AVD)
in **Azure Government (AzureUSGovernment)**, designed for FedRAMP High and
DoD IL4/IL5 environments.  Executed via GitLab CI/CD pipelines.

---

## Repository Structure

```
├── deployment-1-subscription-vending/   # Platform: subscription vending
│   ├── .gitlab-ci.yml
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── variables.tf
│
├── deployment-2-avd-workload/           # Customer: AVD workload landing zone
│   ├── .gitlab-ci.yml
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── modules/
│       ├── avd/                         # AVD management plane (AVM modules)
│       ├── networking/                  # Spoke VNet, NSGs, route tables
│       ├── profile-storage/             # FSLogix / Azure Files
│       └── session-hosts/              # Windows session host VMs
│
└── .gitlab-ci.yml                       # Root orchestration pipeline
```

---

## Deployment 1 – Platform / Subscription Vending

**Owner:** Platform / Cloud Engineering Team  
**Azure scope:** EA/MCA billing account → ALZ Management Group hierarchy  
**Customer cost:** None (subscription container only)

### What it deploys

| Resource | Purpose |
|---|---|
| `azurerm_subscription` | New Azure Government subscription for AVD workload |
| `azurerm_management_group_subscription_association` | Places subscription under ALZ workload MG |
| `azurerm_role_assignment` (Owner) | Customer technical owners |
| `azurerm_role_assignment` (Cost Management Reader) | Customer finance/ops users |
| `azurerm_consumption_budget_subscription` | Monthly budget with 80% / 100% alerts |

### Outputs

| Output | Description |
|---|---|
| `subscription_id` | UUID of the vended subscription |
| `subscription_resource_id` | Full ARM resource ID |
| `tenant_id` | Azure AD tenant ID |
| `management_group_id` | ALZ management group name |
| `monthly_budget_id` | Consumption budget resource ID |

### Required GitLab CI/CD Variables

| Variable | Description |
|---|---|
| `ARM_CLIENT_ID` | Service principal client ID |
| `ARM_CLIENT_SECRET` | Service principal client secret |
| `ARM_TENANT_ID` | Azure AD tenant ID |
| `ARM_SUBSCRIPTION_ID` | Platform management subscription ID |
| `TF_BACKEND_RG` | State storage resource group |
| `TF_BACKEND_SA` | State storage account name |
| `TF_BACKEND_CONTAINER` | State storage container name |
| `TF_VAR_billing_scope_id` | EA/MCA billing scope resource ID |
| `TF_VAR_management_group_id` | ALZ management group ID |
| `TF_VAR_budget_start_date` | Budget start date (RFC3339) |

### Usage

```bash
cd deployment-1-subscription-vending

terraform init \
  -backend-config="resource_group_name=<rg>" \
  -backend-config="storage_account_name=<sa>" \
  -backend-config="container_name=<container>" \
  -backend-config="key=subscription-vending/terraform.tfstate" \
  -backend-config="environment=usgovernment"

terraform plan \
  -var="platform_subscription_id=<sub-id>" \
  -var="billing_scope_id=<ea-scope>" \
  -var="management_group_id=<mg-id>" \
  -var="budget_start_date=2025-01-01T00:00:00Z"

terraform apply
```

---

## Deployment 2 – Customer AVD Workload Landing Zone

**Owner:** Customer team (post-vending)  
**Azure scope:** Customer AVD workload subscription (output of Deployment 1)  
**Customer cost:** All resources are customer-billable

### What it deploys

| Resource Group | Resources | Customer Cost |
|---|---|---|
| `rg-avd-networking-*` | Spoke VNet, subnets, NSGs, route tables, private DNS zones | Minimal (DNS zones only) |
| `rg-avd-storage-*` | Premium Azure Files storage account, FSLogix share, private endpoint | **Ongoing: per-GB provisioned capacity** |
| `rg-avd-avd-*` | AVD host pool, desktop application group, workspace (via AVM) | None (management plane) |
| `rg-avd-compute-*` | Windows session host VMs, availability set, VM extensions | **Primary cost: per-second VM compute + OS disk** |

### Module Descriptions

#### `modules/networking`
- Spoke VNet with configurable address space
- Session host subnet with AVD-specific NSG rules (deny inbound internet, allow AVD gateway outbound)
- Private endpoint subnet (policies disabled)
- Route table for session hosts
- Azure Files private DNS zone (`privatelink.file.core.usgovcloudapi.net`)
- Optional VNet peering to hub

#### `modules/profile-storage`
- Premium Azure Files storage account (FSLogix-optimised)
- FSLogix profiles share with configurable quota
- Private endpoint for storage (prevents public internet traversal)

#### `modules/avd`
- AVD host pool (Pooled or Personal) via [AVM](https://aka.ms/avm)
- Desktop application group with user role assignments
- Workspace with application group association
- Registration token lifecycle management

#### `modules/session-hosts`
- Windows session host VMs (AAD or ADDS join)
- Availability set across fault/update domains
- AVD DSC agent extension (registers VMs with host pool)
- FSLogix configuration via Custom Script Extension
- AAD Login / Domain Join extensions (conditional)

### Outputs

| Output | Description |
|---|---|
| `spoke_vnet_id` | Spoke VNet resource ID |
| `host_pool_id` | AVD host pool resource ID |
| `workspace_id` | AVD workspace resource ID |
| `application_group_id` | Desktop application group resource ID |
| `storage_account_name` | FSLogix storage account name |
| `session_host_vm_ids` | List of session host VM IDs |

### Required GitLab CI/CD Variables

| Variable | Description |
|---|---|
| `ARM_CLIENT_ID` | Service principal client ID |
| `ARM_CLIENT_SECRET` | Service principal client secret |
| `ARM_TENANT_ID` | Azure AD tenant ID |
| `ARM_SUBSCRIPTION_ID` | Customer AVD workload subscription ID |
| `TF_BACKEND_RG` | State storage resource group |
| `TF_BACKEND_SA` | State storage account name |
| `TF_BACKEND_CONTAINER` | State storage container name |
| `TF_VAR_avd_subscription_id` | Same as `ARM_SUBSCRIPTION_ID` |
| `TF_VAR_local_admin_password` | Session host local admin password (secret) |

### Usage

```bash
cd deployment-2-avd-workload

terraform init \
  -backend-config="resource_group_name=<rg>" \
  -backend-config="storage_account_name=<sa>" \
  -backend-config="container_name=<container>" \
  -backend-config="key=avd-workload/<subscription-id>/terraform.tfstate" \
  -backend-config="environment=usgovernment"

terraform plan \
  -var="avd_subscription_id=<sub-id>" \
  -var="local_admin_password=<password>"

terraform apply
```

---

## Global Constraints

- **Azure Environment:** AzureUSGovernment only
- **Provider:** `hashicorp/azurerm ~> 4.0` with `environment = "usgovernment"` and `resource_provider_registrations = "none"`
- **Regions:** Only Azure Government regions (`usgovvirginia`, `usgovtexas`, `usgovarizona`)
- **Authentication:** Service principal / workload identity (non-interactive)
- **State:** One Terraform state file per deployment; stored in Azure Government Blob Storage
- **CI/CD:** GitLab CI/CD (`init → plan → apply`); no GitHub Actions or Azure DevOps
- **No preview features** used

## Platform vs. Customer Responsibility

| Layer | Responsibility | Deployment |
|---|---|---|
| EA/MCA Billing Scope | Platform | D1 |
| ALZ Management Group Hierarchy | Platform | D1 |
| Subscription vending + RBAC | Platform | D1 |
| Subscription budget | Platform | D1 |
| Azure Policy (inherited) | Platform | (inherited via MG) |
| Hub networking (if applicable) | Platform | (pre-existing) |
| Shared identity / ADDS (if applicable) | Platform | (pre-existing) |
| Spoke VNet + NSGs | Customer | D2 |
| Profile storage (FSLogix) | Customer | D2 |
| Session host VMs | Customer | D2 |
| AVD management plane | Customer | D2 |
| RBAC (VM management, AVD users) | Customer | D2 |

---

## AVM Module Registry Note

The AVD management plane module uses [Azure Verified Modules (AVM)](https://aka.ms/avm).
In environments with limited outbound internet access, ensure the Terraform
registry (`registry.terraform.io`) is reachable during `terraform init`, or
pre-mirror the modules using:

```bash
terraform providers mirror /path/to/mirror
```

## What is Spec Kit?

Spec Kit is a toolkit that helps teams practice Spec-Driven Development — a methodology where clear specifications guide implementation, especially when working with AI coding assistants like GitHub Copilot.

## What's Included

This template provides the full Spec Kit setup for GitHub Copilot (v0.2.0):

- **`.github/agents/`** — GitHub Copilot agent command files for the full SDD workflow
- **`.github/prompts/`** — Prompt shortcuts for triggering Spec Kit commands in Copilot Chat
- **`.specify/templates/`** — Document templates (spec, plan, tasks, constitution, checklist)
- **`.specify/scripts/bash/`** — Helper scripts for managing features and branches
- **`.specify/memory/constitution.md`** — Project constitution (customize with your principles)
- **`specs/`** — Directory where feature specifications are stored

## Getting Started

### 1. Customize the Constitution

Edit `.specify/memory/constitution.md` to define your project's core principles, constraints, and governance rules. You can also use the `/speckit.constitution` command in GitHub Copilot Chat to generate it interactively.

### 2. Create a Feature Specification

In GitHub Copilot Chat, use:

```
@workspace /speckit.specify Add user authentication with email and password
```

This will create a feature branch and populate a specification in `specs/`.

### 3. Generate an Implementation Plan

```
@workspace /speckit.plan
```

### 4. Break Into Tasks

```
@workspace /speckit.tasks
```

### 5. Implement

```
@workspace /speckit.implement
```

## Available Commands

| Command | Description |
|---------|-------------|
| `/speckit.specify` | Create a feature specification |
| `/speckit.clarify` | Clarify specification requirements |
| `/speckit.plan` | Generate an implementation plan |
| `/speckit.tasks` | Break the plan into actionable tasks |
| `/speckit.implement` | Execute the implementation plan |
| `/speckit.checklist` | Generate a checklist for a domain |
| `/speckit.analyze` | Analyze the project for consistency |
| `/speckit.constitution` | Create or update the project constitution |
| `/speckit.taskstoissues` | Convert tasks to GitHub Issues |

## Interacting with GitHub Agents via GitHub Issues

You can trigger Spec Kit workflows directly from GitHub Issues by assigning the issue to **@copilot** or by mentioning `@copilot` in an issue comment with a Spec Kit command.

### Assigning an Issue to @copilot

When you assign a GitHub Issue to `@copilot`, Copilot will automatically pick it up and begin working on it based on the issue description.

### Mentioning @copilot in a Comment

You can also trigger a specific Spec Kit agent by mentioning `@copilot` in an issue comment followed by the agent name and any relevant instructions:

```
@copilot /speckit.specify Add user authentication with email and password
```

```
@copilot /speckit.plan
```

```
@copilot /speckit.tasks
```

```
@copilot /speckit.implement
```

### Example Workflow via Issues

1. **Create a GitHub Issue** describing the feature or task you want to implement.
2. **Assign the issue to @copilot**, or comment with `@copilot /speckit.specify <description>` to generate a feature spec.
3. **Follow up** in the issue comments with `@copilot /speckit.plan`, then `@copilot /speckit.tasks`, and finally `@copilot /speckit.implement` to progress through the full SDD workflow.
4. Copilot will open a pull request with the implementation and link it back to your issue.

> **Tip:** You can use any of the commands from the [Available Commands](#available-commands) table above in an issue comment by prefixing them with `@copilot`.

## Learn More

- [Spec Kit on GitHub](https://github.com/github/spec-kit)
- [Spec-Driven Development Guide](https://github.com/github/spec-kit/blob/main/spec-driven.md)
