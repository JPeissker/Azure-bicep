// this file can only be deployed at a subscription scope

param resourceGroupName string = 'myNewResourcegroup'

resource newResourceGroup 'Microsoft.Resources/resourceGroups@2020-01-01' = {
  name: resourceGroupName
  location: 'westeurope'
}

// module budget './budget/main.bicep' = {
//   name: 'budget'
//   params: {
//     budgetName: ''
//     budgetAmount: ''
//     startDate: ''
//     requestEmail: ''
//   }
// }