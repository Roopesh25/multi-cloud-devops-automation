#!/bin/bash

set -e  # exit on error
set -o pipefail

# Define default paths
TF_DIR=${1:-"."}
TF_VARS_FILE=${2:-"terraform.tfvars"}

echo "Starting Terraform deployment from $TF_DIR with $TF_VARS_FILE"
cd "$TF_DIR"

# Initialize
echo "🔧 Running terraform init..."
terraform init

# Validate
echo " Validating configuration..."
terraform validate

# Plan
echo " Creating plan..."
terraform plan -var-file="$TF_VARS_FILE" -out=tfplan

# Apply
read -p " Do you want to apply this plan? (y/n): " confirm
if [[ $confirm == "y" || $confirm == "Y" ]]; then
  echo " Applying plan..."
  terraform apply tfplan
else
  echo "Apply cancelled."
fi

# chmod +x deploy.sh
# ./deploy.sh ./terraform/aws terraform.tfvars
