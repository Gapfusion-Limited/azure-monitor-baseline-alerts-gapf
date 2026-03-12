using '../alert-processing-rule.bicep'

param parSubscriptionId = '5c761373-726f-4bb5-b4d7-1b7adf91b71d'

param parAprName = 'apr-AMBA-sub-Sandbox-01-S001'

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
      '/subscriptions/${parSubscriptionId}/resourceGroups/uks-cinp-rsg'
      '/subscriptions/${parSubscriptionId}/resourceGroups/uks-webtransform1np-rsg'
      '/subscriptions/${parSubscriptionId}/resourceGroups/uks-webtransform3np-rsg'
      '/subscriptions/${parSubscriptionId}/resourceGroups/mc_uks-int-microservices-rsg_uks-int-ms-aks_uksouth'
      '/subscriptions/${parSubscriptionId}/resourceGroups/mc_uks-testbox-microservices-rsg_uks-testbox-ms-aks_uksouth'
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
