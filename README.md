# Autre dépôt TF
Avec identités managées & Container App : https://github.com/fouquetm/pub-sub-tf/tree/pub-sub

# Terraform documentations
**backend** : https://developer.hashicorp.com/terraform/language/backend
- **azurerm** : https://developer.hashicorp.com/terraform/language/backend/azurerm

**modules** : https://developer.hashicorp.com/terraform/language/modules

# Terraform command lines
**terraform init** : met à jour le workdir terraform en important les mises à jour backend & modules

params :
-backend-config="./env/dev-backend.tfvars"

example :
```
terraform init -backend-config="./env/dev-backend.tfvars"
```

**terraform plan** : analyse et affiche les modifications à appliquer

params:
-var-file="./env/dev.tfvars"
-out="myplan.plan"

example :
```
terraform plan -var-file="./env/dev.tfvars" -out="myplan.plan"
```

**terraform apply** : applique les modifications

params:
-var-file="./env/dev.tfvars"
-auto-approve : supprime la validation manuelle de la commande

example :
```
terraform apply -var-file="./env/dev.tfvars" -auto-approve

ou

terraform apply myplan.tf -var-file="./env/dev.tfvars" -auto-approve
```

**terraform destroy** : supprime les ressources gérées par terraform

params:
-var-file="./env/dev.tfvars"
-auto-approve : supprime la validation manuelle de la commande

example :
```
terraform destroy -var-file="./env/dev.tfvars" -auto-approve
```

**terraform import** : importe une ressource existante dans le tfstate

params:
-var-file="./env/dev.tfvars"

example :
```
terraform import terraform import -var-file="./dev.tfvars" module.mssql_database.azurerm_key_vault_secret.database-sql-connection-string "https://kv-maalsi-24-dev-xwky7g.vault.azure.net/secrets/rabbitmqdemo-sql-connection-string/55914a91c5b843f0a9cd918ae0b7b138"
```

**terraform state** : agit sur le fichier tfstate

params:
rm : supprime une référence dans le tfstate

examples :
```
terraform state rm module.mssql_database.azurerm_key_vault_secret.database-sql-connection-string
```