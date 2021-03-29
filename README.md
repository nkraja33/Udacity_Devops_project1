# Microsoft Azure: Deploy a IaaS web server

## Introduction

This project contains code to host a web application Infrastructure on Microsoft Azure.

To manage resources it uses terraform and to build image it uses Packer.

This template prompts the number of instances to be created within the Availability set. The virtual machine instance count is spread across the Availability set and load is distributed with the use of a Load Balancer.

The template includes the creation of a Virtual network, subnet and public IP address. It blocks external internet internet traffic with the use of Network Security Groups by default.

Follow the instructions below is setup the environment.

All commands are run through Azure CLI (see Dependencies section)

## Getting Started

1. Clone this repository
2. Create an [Azure Account](https://portal.azure.com)
3. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
4. Install [Packer](https://www.packer.io/downloads)
5. Install [Terraform](https://www.terraform.io/downloads.html)
6. Follow the below instruction to create resources in Azure

### Instructions

#### 1. Create service principal for Terraform and Packer [Create service Principal](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html)

#### 2. Set ARM environment variables:(For Windows)

Run the below commands to set the environment values by providing the appropriate values in PowerShell

    ```
    $env:ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
    $env:ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
    $env:ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
    $env:ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
    ```

#### 3. Create resource group to store Packer Image:

    ```
    az group create -l <location> -n packer-image_ubuntu
    ```

If you want to change the image name, please change in server_image.json file as well.


#### 4. Build packer image

Before ```cd``` to the directory where the ```.json``` files are located.

    ```packer build server_image.json
    ```

#### 5. Terraform variables

The following variables were needed to create the webserver.

- Prefix (The prefix which should be used for all resources)
- Location (The Azure Region in which all resources in this example should be created)
- Username (Admin Username for the VM)
- Password (Password for Admin User)
- Number of VMs (Number of virtual Machines to be created in Availability Set)
- Tag (Tag for all the resources)

These values were repeatedly needs in the process by to ease things terraform will get the values once using the ```vars.tf``` and it will apply them
whenever required. If you want to add or edit the variables please update it in ```vars.tf``` file.

#### 6. Run Terraform

    ```
    terraform plan -out <filename>
    terraform apply
    ```

  Note: -out will create a file with details of the resources that will created in Axure, It will be helpful to review them before deployment.

## Output

Following the Terraform service principal authentication guidelines creates the following resources:

- Azure Service Principal

Running the Packer commands creates the following resources:

- Image resource group
- Managed virtual machine image

The following resources are created with the Terraform template:

- Resource Group
- Virtual Network
- Subnet
- Network Security Group
- Security group rules
- Public IP
- Load Balancer
- Backend Address pools
- Availability Set
- Network Interface Card(s)
- Virtual Machine(s)
- Azure Managed Disk(s)
