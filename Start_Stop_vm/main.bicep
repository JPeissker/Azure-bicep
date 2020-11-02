param location string = resourceGroup().location
param actionType string {
  allowed: [
    'StartVm'
    'StopVm'
  ]
  metadata: {
    description: 'Not Implemented yet! -- defines if workflow srts or stops a virtuel machine'
  }
}
param vmName string = 'myVirtualMachineName'
param clientId string {
  secure: true
}
param clientSecret string {
  secure: true
}
param runHours array = [
  '12'
]
param runMinutes array = [
  0
]
param runWeekDays array = [
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
]
param timeZone string = 'W. Europe Standard Time'

var ConnectionType = 'azurevm'

resource Connection 'Microsoft.Web/connections@2016-06-01' = {
  name: ConnectionType
  location: location
  kind: 'V1'
  properties: {
    displayName: '${vmName}-Connection'
    api: {
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/${ConnectionType}'
    }
    parameterValues: {
      'token:clientId': clientId
      'token:clientSecret': clientSecret
      'token:grantType': 'client_credentials'
      'token:TenantId': subscription().tenantId
	  }
  }
}

// Stop VM if actionType = 'StopVm'
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
            frequency: 'Week'
            interval: 1
            schedule: {
              hours: runHours
              minutes: runMinutes
              weekDays: runWeekDays
            }
            timeZone: timeZone
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
            connectionName: Connection.name
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/azurevm'
          }
        }
      }
    }
  }
}

// Start actionType = 'StartVm'
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
              hours: runHours
              minutes: runMinutes
              weekDays: runWeekDays
            }
            timeZone: timeZone
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
            connectionName: Connection.name
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/azurevm'
          }
        }
      }
    }
  }
}