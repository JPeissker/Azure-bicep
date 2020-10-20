param VMName string
param vmSize string = 'Standard_A1'
param osVersion string = '2016-Datacenter'
param subnetID string
param applicationName string
param managementResourceGroup string   // Second IP segment for template VNET (VNet will be at least /20)
param orderCycleID string        // VM Size of the domain controller
param parentOrderCycleID string            // name of management resource group
param costCenter string
param customerNameShort string = ''
param _artifactsLocation string = ''
param _artifactsLocationSasToken string = ''
param vmDefaultNsgId string = ''
param vmDefaultAsgId string = ''
param availabilityZone string {
    allowed: [
        '1'
        '2'
        '3'
    ]
    default: '1'
}

var location = resourceGroup().location
var adminUsername = 'cspAdmin'
var adminPassword = concat(uniqueString(concat(orderCycleID)),'iq3!')
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var vmNicName = concat(VMName,'-NIC')
var osDiskName = concat(VMName,'-OSDisk')
var keyVaultName = take(toLower(concat(customerNameShort,'-secrets-',subscription().subscriptionId)),23)
var omsWorkspaceName = toLower(concat(customerNameShort,'-monitor-',subscription().subscriptionId))
var logstorageaccountname = take(toLower(concat(customerNameShort,'log',replace(subscription().subscriptionId,'-',''))), 24)
var nicProperties = if(empty(vmDefaultNsgId), nicPropertiesChoise.withoutNsg, nicPropertiesChoise.withNsg)
var nicPropertiesChoise = {
    withNsg: {
        ipConfigurations: [
            {
                name: concat(VMName,'-ipconfig')
                properties: {
                    privateIPAllocationMethod: 'Dynamic'
                    subnet: {
                        id: subnetID
                    }
                    applicationSecurityGroups: [
                        {
                            id: vmDefaultAsgId
                        }
                    ]
                }
            }
        ]
        networkSecurityGroup: {
            id: vmDefaultNsgId
        }
    }
    withoutNsg: {
        ipConfigurations: [
            {
                name: concat(VMName,'-ipconfig')
                properties: {
                    privateIPAllocationMethod: 'Dynamic'
                    subnet: {
                        id: subnetID
                    }
                }
            }
        ]
    }
}
var tagValues = {
    oci: orderCycleID
    poci: parentOrderCycleID
    costcenter: costCenter
    customershort: customerNameShort
    Customer_Application: applicationName
}

resource nic 'Microsoft.Network/networkInterfaces@2018-07-01' = {
    name: vmNicName
    location: location
    tags: tagValues
    properties: nicProperties
}

resource vm 'Microsoft.Compute/virtualMachines@2019-03-01' = {
    name: VMName
    location: location
    tags: tagValues
    dependsOn: [
        nic
    ]
    zones: [
        availabilityZone
    ]
    properties: {
        hardwareProfile: {
            vmSize: vmSize
        }
        osProfile: {
            computerName: VMName
            adminUsername: adminUsername
            adminPassword: adminPassword
        }
        storageProfile: {
            imageReference: {
                publisher: imagePublisher
                offer: imageOffer
                sku: osVersion
                version: 'latest'
            }
            osDisk: {
                osType: 'Windows'
                caching: 'ReadWrite'
                createOption: 'FromImage'
                name: osDiskName
                managedDisk: {
                    storageAccountType: 'Standard_LRS'
                }
            }
        }
        networkProfile: {
            networkInterfaces: [
                {
                    id: nic.id
                }
            ]
        }
    }
}

resource IaaSDiagnostics 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
    name: '${VMName}/IaaSDiagnostics'
    location: location
    dependsOn: [
        vm
    ]
    properties: {
        publisher: 'Microsoft.Azure.Diagnostics'
        type: 'IaaSDiagnostics'
        typeHandlerVersion: '1.9'
        autoUpgradeMinorVersion: true
        protectedSettings: {
            storageAccountName: logstorageaccountname
            storageAccountKey: listKeys(resourceId(managementResourceGroup, 'Microsoft.Storage/storageAccounts', logstorageaccountname),'2015-06-15').key1
            storageAccountEndPoint: 'https://core.windows.net'
        }
        settings: {
            StorageAccount: logstorageaccountname
        }
    }
}


resource vmDiskEncryption 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${VMName}/AzureDiskEncryption'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: uniqueString(resourceGroup().id, deployment().name)
    settings: {
      EncryptionOperation: 'DisableEncryption'
      VolumeType: 'All'
    }
  }
}



resource KeyVault 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
    name: concat(keyVaultName,'/',orderCycleID,'-',VMName)
    dependsOn: [
        vm
    ]
    properties: {
        contentType: concat('vm/',VMName)
        value: '{"username" : "${adminUsername}", "password" : "${adminPassword}"}'
    }
}
