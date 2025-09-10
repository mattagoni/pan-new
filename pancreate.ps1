##Deploy PaloFirewall into Hub vNET
New-AzureRmResourceGroup -Name magoni -Location AustraliaSouthEast
New-AzResourceGroupDeployment -ResourceGroupName "magoni" -TemplateFile "/home/matthew/pan/pandeploytemplate.json" -TemplateParameterFile "/home/matthew/pan/pandeploymentparameters.json"



##get Palto network ready after template deployment
$nic = Get-AzNetworkInterface -Name paloaltofw-pan-ip-eth0 -ResourceGroup magoni
$nic.IpConfigurations.publicipaddress.id = $null
Set-AzNetworkInterface -NetworkInterface $nic
Remove-AzureRmPublicIpAddress -Name pan-ip -ResourceGroupName magoni

New-AzPublicIpAddress -Name Pan-mgt-Ip -ResourceGroupName magoni -Location 'AustraliaSouthEast' -AllocationMethod static -sku standard
New-AzPublicIpAddress -Name Pan-untrust-Ip -ResourceGroupName magoni -Location 'AustraliaSouthEast' -AllocationMethod static -sku standard

$vnet = Get-AzVirtualNetwork -Name HubNetwork -ResourceGroupName HubNetwork-RG
$subnet = Get-AzVirtualNetworkSubnetConfig -Name Mgt -VirtualNetwork $vnet
$nic = Get-AzNetworkInterface -Name paloaltofw-pan-ip-eth0 -ResourceGroupName magoni
$pip = Get-AzPublicIpAddress -Name Pan-mgt-Ip -ResourceGroupName magoni
$nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig-mgmt -PublicIPAddress $pip -Subnet $subnet
$nic | Set-AzNetworkInterface

$vnet = Get-AzVirtualNetwork -Name HubNetwork -ResourceGroupName HubNetwork-RG
$subnet = Get-AzVirtualNetworkSubnetConfig -Name Untrust -VirtualNetwork $vnet
$nic = Get-AzNetworkInterface -Name paloaltofw-pan-ip-eth1 -ResourceGroupName magoni
$pip = Get-AzPublicIpAddress -Name Pan-untrust-Ip -ResourceGroupName magoni
$nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig-untrust -PublicIPAddress $pip -Subnet $subnet
$nic | Set-AzNetworkInterface

$rule1 = New-AzNetworkSecurityRuleConfig -Name ALLIN -Description "Allow ALL IN" -Access Allow -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *
$rule2 = New-AzNetworkSecurityRuleConfig -Name ALLOUT -Description "Allow ALL OUT" -Access Allow -Protocol * -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName magoni -Location australiasoutheast -Name "AllowALL" -SecurityRules $rule1,$rule2


$nic = Get-AzNetworkInterface -ResourceGroupName "magoni" -Name "paloaltofw-pan-ip-eth0"
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName "magoni" -Name "AllowAll"
$nic.NetworkSecurityGroup = $nsg
$nic | Set-AzNetworkInterface

$nic = Get-AzNetworkInterface -ResourceGroupName "magoni" -Name "paloaltofw-pan-ip-eth1"
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName "magoni" -Name "AllowAll"
$nic.NetworkSecurityGroup = $nsg
$nic | Set-AzNetworkInterface

$nic = Get-AzNetworkInterface -ResourceGroupName "magoni" -Name "paloaltofw-pan-ip-eth2"
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName "magoni" -Name "AllowAll"
$nic.NetworkSecurityGroup = $nsg
$nic | Set-AzNetworkInterface

##Create Default Routes for Networks back to PAN
az network route-table create --name NSWROUTETABLE --resource-group NswNetwork-rg --location Australiaeast
az network route-table route create -g NswNetwork-rg --route-table-name NSWROUTETABLE -n NSWROUTETABLE --next-hop-type VirtualAppliance --address-prefix 0.0.0.0/0 --next-hop-ip-address 10.100.1.4
az network vnet subnet update -g NswNetwork-rg -n network1 --vnet-name NswNetwork --route-table NSWROUTETABLE

az network route-table create --name VICROUTETABLE --resource-group VicNetwork-rg --location AustraliaSoutheast
az network route-table route create -g VICNetwork-rg --route-table-name VICROUTETABLE -n VICROUTETABLE --next-hop-type VirtualAppliance --address-prefix 0.0.0.0/0 --next-hop-ip-address 10.100.1.4
az network vnet subnet update -g VICNetwork-rg -n network1 --vnet-name VICNetwork --route-table VICROUTETABLE

az network route-table create --name USAROUTETABLE --resource-group USANetwork-rg --location WESTUS
az network route-table route create -g USANetwork-rg --route-table-name USAROUTETABLE -n USAROUTETABLE --next-hop-type VirtualAppliance --address-prefix 0.0.0.0/0 --next-hop-ip-address 10.100.1.4
az network vnet subnet update -g USANetwork-rg -n network1 --vnet-name USANetwork --route-table USAROUTETABLE
