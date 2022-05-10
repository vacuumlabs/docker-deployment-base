#!/bin/bash
set -euo pipefail

echo "****************************"
echo "*** executability checks ***"
echo "****************************"
ansible --version
aws --version
aws-vault --version
docker --version
pre-commit --version
terraform --version
terraform-docs --version
tflint --version
echo "[OK]"

echo
echo "*************************"
echo "*** aws and aws-vault ***"
echo "*************************"
export AWS_CONFIG_FILE=aws-config
cat > aws-config << EOF
[default]
region = eu-central-1
EOF
aws configure list
export AWS_VAULT_BACKEND=file
aws-vault list
rm -rf aws-config ~/.awsvault
echo "[OK]"

echo
echo "******************************************"
echo "*** pre-commit, tflint, terraform-docs ***"
echo "***           and terraform            ***"
echo "******************************************"
cat > main.tf << EOF
resource "null_resource" "test" {
}
EOF
cat > .pre-commit-config.yaml << EOF
repos:
- repo: https://github.com/antonbabenko/pre-commit-terraform.git
  rev: v1.71.0
  hooks:
    - id: terraform_fmt
    - id: terraform_docs
EOF

# pre-commit requires valid git repo. Recreate it in case it does not exist
[[ -d .git ]] || git init
pre-commit run
tflint main.tf
terraform-docs markdown . > /dev/null
terraform init
terraform apply -auto-approve
rm -rf \
    .cache .pre-commit-config.yaml \
    .terraform .terraform.d terraform.tfstate main.tf
echo "[OK]"

echo
echo "***********************************"
echo "*** All tests were successful! ****"
echo "***********************************"
