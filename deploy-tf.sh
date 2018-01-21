#!/bin/bash

# Sample usage
# ./deploy-tf.sh aws aws_instance.ubuntu14 ubuntu ~/datalab-provisioner.pem

### PROVISION JUPYTERHUB SERVER VIA TERRAFORM
provider=$1
resource=$2
provisioner_user=$3
provisioner_key_file=$4
skip_terraform=${5:-0}

echo "Provider: $provider"
echo "Resource: $resource"
echo "User: $provisioner_user"
echo "Key: $provisioner_key_file"

### BUILD INFRASTRUCTURE

if [ $skip_terraform -eq 0 ]
then

pushd ./terraform/$provider
# terraform init
terraform plan \
    -out=./.terraform/terraform.tfplan \
    -target=$resource \
    -var "server_port=8000" \
    -var "provisioner_key_file=$provisioner_key_file"
terraform apply .terraform/terraform.tfplan 
popd

fi

### PROVISION JUPYTERHUB
# Prerequisites
# 1) install terraform-inventory from https://github.com/adammck/terraform-inventory#more-usage
# 2) install go into Windows 10 bash from https://stefanprodan.com/2016/golang-bash-on-windows-installer/
# 3) run: go get github.com/adammck/terraform-inventory
TF_STATE=./terraform/$provider ansible-playbook \
    --inventory=$(which terraform-inventory) \
    --inventory=./environments/env1 \
    --user=$provisioner_user \
    --private-key=$provisioner_key_file \
    --skip-tags=optional \
    -v \
    playbooks/datalab.yml

