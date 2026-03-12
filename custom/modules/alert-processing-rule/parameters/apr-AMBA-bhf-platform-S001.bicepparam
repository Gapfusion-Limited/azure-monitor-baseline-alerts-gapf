using '../alert-processing-rule.bicep'

param parSubscriptionId = 'dd209999-e199-4397-a14c-3b3062d32321'

param parAprName = 'apr-AMBA-bhf-platform-S001'

param parAprDescription = 'AMBA Notification Assets - Suppression Alert Processing Rule for Shared Non-Prod Subscription - multiple resource suppression during maintenance hours'

param parAprScopes = [
  '/subscriptions/${parSubscriptionId}'
]

param parAprActions = [
  {
    actionType: 'RemoveAllActionGroups'
  }
]

param parAprConditions = [
  {
    field: 'TargetResourceGroup'
    operator: 'Equals'
    values: [
      //Maximum of 5 values per condition - https://learn.microsoft.com/en-gb/azure/azure-monitor/alerts/alerts-processing-rules?tabs=portal#alert-processing-rule-filters
      '/subscriptions/${parSubscriptionId}/resourceGroups/uks-integrationnp-rsg'
      '/subscriptions/${parSubscriptionId}/resourceGroups/uks-contentnp-rsg'
      '/subscriptions/${parSubscriptionId}/resourceGroups/uks-testboxnp-rsg'
      '/subscriptions/${parSubscriptionId}/resourceGroups/uks-pr-alphanp-rsg'
      '/subscriptions/${parSubscriptionId}/resourceGroups/uks-sandboxnp-rsg'
    ]
  }
  {
    field: 'TargetResourceType'
    operator: 'Equals'
    values: [
      'microsoft.compute/virtualmachines'
      'microsoft.compute/virtualmachinescalesets'
    ]
  }
]

param parAprEnabled = true

// Scheduled suppression: 17:00-07:00 GMT (14 hours daily)
param parAprSchedule = {
  timezone: 'GMT Standard Time'
  recurrences: [
    {
      recurrenceType: 'Daily'
      startTime: '17:00:00'
      endTime: '07:00:00'
    }
  ]
}

param parAprTags = {
  _deployed_by_amba: 'true'
}
