terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
$ip_address = terraform output --raw public_ip_address
echo $ip_address
