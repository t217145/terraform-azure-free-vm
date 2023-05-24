terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
$ip_address = terraform output --raw public_ip_address
$admin = terraform output --raw admin_name

# Login to the VM
ssh $admin@$ip_address

# execute this in the VM
sudo su
apt-get update -y && apt-get upgrade -y
apt-get install docker.io -y
@REM !!Beware the port number
docker run -itd --cap-add=NET_ADMIN -p 13305:1194/udp -p 80:8080/tcp -e HOST_ADDR=$(curl -s https://api.ipify.org) --name dockovpn alekslitvinenk/openvpn

# Clean up resource
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan
