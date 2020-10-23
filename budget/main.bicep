param budgetName string = 'budget'
param budgetAmount string = '130'
param startDate string = '2020-11-01'
param requestEmail string = 'julian.peissker@direkt-gruppe.de'

resource budget 'Microsoft.Consumption/budgets@2019-10-01' = {
  name: budgetName
  properties: {
    timePeriod: {
      startDate: startDate
      endDate: dateTimeAdd(startDate, 'P1Y')
    }
    timeGrain: 'Annually'
    amount: budgetAmount
    category: 'Cost'
    notifications: {
      NotificationForExceededBudget1: {
        enabled: true
        operator: 'GreaterThan'
        threshold: '90'
        contactEmails: [
          requestEmail
        ]
        contactRoles: [
          'Owner'
        ]
        contactGroups: []
      }
    }
    filter: {
      and: [
        {
          dimensions: {
            name: 'ResourceGroupName'
            operator: 'In'
            values: resourceGroup().name
          }
        }
      ]
    }
  }
}