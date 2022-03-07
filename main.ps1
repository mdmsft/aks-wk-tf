terraform init -upgrade -backend-config="resource_group_name=mdmsft" -backend-config="storage_account_name=mdmsft" -backend-config="container_name=tfstate"
terraform fmt -recursive
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan