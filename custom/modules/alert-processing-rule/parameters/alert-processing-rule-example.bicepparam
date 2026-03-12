using '../alert-processing-rule.bicep'

param parSubscriptionId = ''

param parAprName = 'apr-AMBA-SUBNAME-001' //Suffix S where the rule relates to suppression e.g. S001

param parAprDescription = 'AMBA Notification Assets - Suppression Alert Processing Rule for maintenance period for Subscription'

param parAprScopes = [
  '/subscriptions/${parSubscriptionId}'
]

param parAprActions = [
  // {
  //   actionType: 'RemoveAllActionGroups'
  // }
]

param parAprConditions = [
  // {
  //   field: 'TargetResourceGroup'
  //   operator: 'Equals'
  //   values: [
  //     '/subscriptions/${parSubscriptionId}/resourceGroups/ExampleRG'
  //   ]
  // }
  // {
  //   field: 'TargetResourceType'
  //   operator: 'Equals'
  //   values: [
  //     'microsoft.compute/virtualmachines'
  //   ]
  // }
]

param parAprEnabled = false

param parAprSchedule = {
  // timezone: 'GMT Standard Time'
  // recurrences: [
  //   {
  //     recurrenceType: 'Daily'
  //     startTime: '17:00:00'
  //     endTime: '08:00:00'
  //   }
  // ]
}

param parAprTags = {
  _deployed_by_amba: 'true'
}
