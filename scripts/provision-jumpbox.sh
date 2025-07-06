#!/bin/bash

# Variables - update these
RESOURCE_GROUP="rg-jumpbox"
LOCATION="eastus"
VM_NAME="aks-jumpbox"
ADMIN_USER="azureuser"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
IMAGE="Ubuntu2204"
VNET_NAME="vnet-jumpbox"
SUBNET_NAME="subnet-jumpbox"
NSG_NAME="nsg-jumpbox"
PUBLIC_IP_NAME="ip-jumpbox"
NIC_NAME="nic-jumpbox"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create virtual network and subnet
az network vnet create   --name $VNET_NAME   --resource-group $RESOURCE_GROUP   --subnet-name $SUBNET_NAME

# Create network security group with SSH rule
az network nsg create   --resource-group $RESOURCE_GROUP   --name $NSG_NAME

az network nsg rule create   --resource-group $RESOURCE_GROUP   --nsg-name $NSG_NAME   --name Allow-SSH   --protocol tcp   --priority 1000   --destination-port-range 22   --access allow

# Create public IP and NIC
az network public-ip create   --name $PUBLIC_IP_NAME   --resource-group $RESOURCE_GROUP   --allocation-method Static

az network nic create   --resource-group $RESOURCE_GROUP   --name $NIC_NAME   --vnet-name $VNET_NAME   --subnet $SUBNET_NAME   --network-security-group $NSG_NAME   --public-ip-address $PUBLIC_IP_NAME

# Create the VM
az vm create   --name $VM_NAME   --resource-group $RESOURCE_GROUP   --location $LOCATION   --nics $NIC_NAME   --image $IMAGE   --admin-username $ADMIN_USER   --ssh-key-values $SSH_KEY_PATH   --public-ip-sku Standard   --output json

# Open port 22 if not already open
az vm open-port --port 22 --resource-group $RESOURCE_GROUP --name $VM_NAME

# Install Azure CLI and kubectl
az vm run-command invoke   --command-id RunShellScript   --name $VM_NAME   --resource-group $RESOURCE_GROUP   --scripts '
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash;
    az aks install-cli;
  '

echo "Jumpbox $VM_NAME provisioned and ready for AKS connection."
