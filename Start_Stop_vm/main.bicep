param location string = resourceGroup().location
param vmName string = 'myVirtualMachine'
param clientId string {
  secure: true
}
param clientSecret string {
  secure: true
}

var ConnectionName = 'azurevm'

resource Connection 'Microsoft.Web/connections@2016-06-01' = {
  name: ConnectionName
  location: location
  kind: 'V1'
  properties: {
    displayName: '${vmName}-Connection'
    api: {
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/${ConnectionName}'
    }
    parameterValues: {
      'token:clientId': clientId
      'token:clientSecret': clientSecret
      'token:grantType': 'client_credentials'
      'token:TenantId': subscription().tenantId
	  }
  }
}

// Stop VM
resource StopVm 'Microsoft.Logic/workflows@2017-07-01' = {
  name: '${vmName}-stop'
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Day'
            interval: 1
            schedule: {
              hours: [
                '19'
              ]
              minutes: [
                0
              ]
            }
            timeZone: 'W. Europe Standard Time'
          }
          type: 'Recurrence'
        }
      }
      actions: {
        Power_off_virtual_machine: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azurevm\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: concat('/subscriptions/@{encodeURIComponent(\'', subscription().subscriptionId, '\')}/resourcegroups/@{encodeURIComponent(\'', resourceGroup().name, '\')}/providers/Microsoft.Compute/virtualMachines/@{encodeURIComponent(\'', vmName, '\')}/powerOff')
            queries: {
              'api-version': '2019-12-01'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azurevm: {
            connectionId: Connection.id
            connectionName: ConnectionName
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/azurevm'
          }
        }
      }
    }
  }
}

// Start Vm
resource StartVm 'Microsoft.Logic/workflows@2017-07-01' = {
  name: '${vmName}-start'
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Week'
            interval: 1
            schedule: {
              hours: [
                '18'
              ]
              minutes: [
                0
              ]
              weekDays: [
                'Monday'
                'Tuesday'
                'Wednesday'
                'Thursday'
                'Friday'
              ]
            }
            timeZone: 'W. Europe Standard Time'
          }
          type: 'Recurrence'
        }
      }
      actions: {
        Start_virtual_machine: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azurevm\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: concat('/subscriptions/@{encodeURIComponent(\'', subscription().subscriptionId, '\')}/resourcegroups/@{encodeURIComponent(\'', resourceGroup().name, '\')}/providers/Microsoft.Compute/virtualMachines/@{encodeURIComponent(\'', vmName, '\')}/start')
            queries: {
              'api-version': '2019-12-01'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azurevm: {
            connectionId: Connection.id
            connectionName: ConnectionName
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/azurevm'
          }
        }
      }
    }
  }
}