# Action Rules `[Microsoft.AlertsManagement/actionRules]`

This module deploys an Alert Processing Rule.

Configure your input values within a .bicepparam file and use that as your parameter file input at deployment time.

## Deployment

> For the examples below we assume you have downloaded or cloned the Git repo as-is and are in the root of the repository as your selected directory in your terminal of choice. Also ensure you have set your target subscription scope to prevent resource group not found exceptions.

### Azure CLI

```bash
# For Azure global regions

dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
NAME="amba-AlertProcess-${dateYMD}"
RGID="UKS-MGMT-RSG-AMBA-001"
TEMPLATEFILE="custom/modules/alert-processing-rule/alert-processing-rule.bicep"
PARAMETERS="custom/modules/alert-processing-rule/parameters/alert-processing-rule-example.bicepparam"

az deployment group create --name ${NAME:0:63} --resource-group $RGID --template-file $TEMPLATEFILE --parameters $PARAMETERS
```

### PowerShell

```powershell
# For Azure global regions

$inputObject = @{
  DeploymentName        = -join ('amba-AlertProcess-{0}' -f (Get-Date -Format 'yyyyMMddTHHMMssffffZ'))[0..63]
  ResourceGroupName     = "UKS-MGMT-RSG-AMBA-001"
  TemplateFile          = "custom/modules/alert-processing-rule/alert-processing-rule.bicep"
  TemplateParameterFile = "custom/modules/alert-processing-rule/parameters/alert-processing-rule-example.bicepparam"
}

New-AzResourceGroupDeployment @inputObject
```

## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the Alert Processing Rule. |
| `resourceId` | string | The resource ID of the Alert Processing Rule. |