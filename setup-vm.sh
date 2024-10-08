#!/bin/bash

export RANDOM_ID="$(openssl rand -hex 3)"
export MY_RESOURCE_GROUP_NAME="myVMResourceGroup$RANDOM_ID"
export REGION=westeurope
export MY_VM_NAME="myVM$RANDOM_ID"
export MY_USERNAME=azureuser
export MY_VM_IMAGE="Canonical:0001-com-ubuntu-minimal-jammy:minimal-22_04-lts-gen2:latest"

# create resource group
az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION

# get cloud-init.txt
curl -o cloud-init.txt https://raw.githubusercontent.com/mkol5222/appsec-chart/main/cloud-init.yml

# create VM
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli

az vm create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --name $MY_VM_NAME \
  --image $MY_VM_IMAGE \
  --admin-username $MY_USERNAME \
  --generate-ssh-keys \
  --custom-data cloud-init.txt \
  --assign-identity \
  --size Standard_DS2_v2  \
  --public-ip-sku Standard

az vm open-port -g $MY_RESOURCE_GROUP_NAME -n $MY_VM_NAME --port 22,80,443

az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --vm-name $MY_VM_NAME

export IP_ADDRESS=$(az vm show --show-details --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --query publicIps --output tsv)

alias sshvm="ssh -o StrictHostKeyChecking=no $MY_USERNAME@$IP_ADDRESS"

echo '#!/bin/bash' > "destroyvm-$RANDOM_ID"
echo "az vm delete --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --yes" >> "destroyvm-$RANDOM_ID"
echo "az group delete --name $MY_RESOURCE_GROUP_NAME --yes" >> "destroyvm-$RANDOM_ID"
chmod +x "destroyvm-$RANDOM_ID"

echo '#!/bin/bash' > "sshvm-$RANDOM_ID"
echo "az ssh vm -n $MY_VM_NAME -g $MY_RESOURCE_GROUP_NAME --local-user azureuser" >> "sshvm-$RANDOM_ID"
chmod +x "sshvm-$RANDOM_ID"

echo
echo "VM created. You can now connect to it using 'sshvm' command"
echo "To destroy the VM, run 'destroyvm-$RANDOM_ID'"
echo
