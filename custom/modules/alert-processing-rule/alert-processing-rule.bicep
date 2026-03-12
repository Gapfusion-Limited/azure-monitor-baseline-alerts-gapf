// =============================================================================
// This module deploys an Alert Processing Rule via the Azure Verified Bicep Resource Module
// Module: br/public:avm/res/alerts-management/action-rule
// Source: https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/alerts-management/action-rule
// =============================================================================

targetScope = 'resourceGroup'

@sys.description('Subscription ID where the alert processing rule will be created.')
param parSubscriptionId string

@sys.description('Name of the alert processing rule.')
param parAprName string

@sys.description('Description for the alert processing rule.')
param parAprDescription string

@sys.description('Location of the alert processing rule - only Global is supported.')
@allowed([
  'Global'
])
param parAprLocation string = 'Global'

@sys.description('Scopes to which the alert processing rule will be applied. Example: /subscriptions/{subscriptionId} or /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName} or /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}')
param parAprScopes array

@sys.description('Alert Processing Rule Actions')
param parAprActions array = []

@sys.description('Alert Processing Rule Conditions')
param parAprConditions array = []

@sys.description('Indicates whether the alert processing rule is enabled or not.')
@allowed([
  true
  false
])
param parAprEnabled bool

@sys.description('Schedule for the alert processing rule. Example: "0 0 * * *" for daily at midnight. - empty object of {} for always')
param parAprSchedule object = {}

@sys.description('Tags to be applied to the alert processing rule.')
param parAprTags object = {}

module actionRule 'br/public:avm/res/alerts-management/action-rule:0.2.4' = {
  params: {
    name: parAprName
    aprDescription: parAprDescription
    location: parAprLocation
    scopes: parAprScopes
    actions: parAprActions
    conditions: parAprConditions
    enabled: parAprEnabled
    schedule: parAprSchedule
    tags: parAprTags
  }
}

output actionRuleId string = actionRule.outputs.resourceId
output actionRuleName string = actionRule.outputs.name
