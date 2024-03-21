### Setup the VPN server
1. Go to Azure Console or local terminal with Azure CLI / PowerShell installed
2. Clone this repo
```console
git clone https://github.com/t217145/terraform-azure-free-vm.git
cd terraform-azure-free-vm

```
3. Change the value in variables.tf and save it
4. Type following command in sequence
```console
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
$ip_address = terraform output --raw public_ip_address
echo $ip_address

```
5. Open a browser and visit the http://{$ip_address}
e.g. if the ip address it show is 10.1.2.3 then enter http://10.1.2.3 in your browser
Beware that you can down the openvpn file just once!!
6. Open the file you downloaded, change the port number to that of you defined in variables.tf

### Setup in your mobile / desktop
1. Install / Download the openvpn apps
2. Download the above openvpn file to your mobile
3. Open the openvpn apps and import the profile by selecting openvpn file you downloaded
