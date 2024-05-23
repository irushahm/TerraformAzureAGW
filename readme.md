# Terraform Azure Infrastructure Provisioning

## Introduction

This repository contains Terraform code to provision Azure infrastructure for hosting a simple web application. The infrastructure setup includes configuring virtual networks, subnets, network security groups, virtual machines, public IP addresses, and an application gateway on Azure.

The web application will be hosted behind the Azure Application Gateway, providing load balancing and security features.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- Terraform installed locally.
- Azure subscription.

## Usage

1. Clone the repository:

    ```bash
    git clone <repository-url>
    ```

2. Initialize Terraform:

    ```bash
    terraform init
    ```

3. Review and adjust the variables in `variables.tf` as needed.

4. Apply the Terraform configuration:

    ```bash
    terraform apply
    ```

5. After successful provisioning, you can access the resources deployed in your Azure account.

## Configuration

The Terraform configuration in this repository includes the following resources:

- **Azure Provider Configuration**: Specifies the required provider and version.
- **Azure Resource Group**: Creates an Azure resource group for grouping resources.
- **Azure Virtual Networks (VNets)**: Creates two virtual networks with subnets.
- **Azure Network Security Group (NSG)**: Sets up a network security group for controlling traffic.
- **Azure Network Security Rule**: Defines a network security rule for inbound traffic.
- **Azure Subnet Network Security Group Association**: Associates NSG with subnets.
- **Azure Virtual Network Peering**: Sets up peering between VNets.
- **Azure Public IP Address**: Allocates public IP addresses for VMs and resources.
- **Azure Network Interface**: Creates network interfaces for VMs.
- **Azure Linux Virtual Machine**: Deploys Linux virtual machines.
- **Azure Application Gateway**: Configures an application gateway.

## Outputs

The Terraform configuration provides the following outputs:

- **Public IP Addresses**: Lists the public IP addresses associated with the deployed VMs.

## Cleanup

To tear down the infrastructure created by Terraform, run:

```bash
terraform destroy
