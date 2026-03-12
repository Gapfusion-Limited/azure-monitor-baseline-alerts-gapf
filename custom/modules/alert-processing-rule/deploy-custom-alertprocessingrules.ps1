<#
.SYNOPSIS
    Iterates all .bicepparam files in a folder, extracts subscriptionId from each,
    sets Az context, and runs New-AzResourceGroupDeployment with a supplied Bicep template.

.PARAMETER ParameterFolder
    Folder containing .bicepparam files (can be relative).

.PARAMETER TemplateFile
    Path to the bicep template to deploy (e.g. custom/modules/alert-processing-rule/alert-processing-rule.bicep).

.PARAMETER ResourceGroupName
    Target resource group for the deployment(s).

.PARAMETER Preview
    If set, runs deployments with -WhatIf. Omit to perform actual deployments.

.PARAMETER Recurse
    If set, searches subfolders for .bicepparam files.

.PARAMETER IncludePattern
    Optional wildcard pattern to include subset of files (e.g. "*Shared_NonProd*.bicepparam").

.PARAMETER ExcludePattern
    Optional wildcard pattern to exclude files (e.g. "*PROD*.bicepparam").

.PARAMETER ConfirmEach
    If set, confirms before each deployment.

.EXAMPLE
    .\Invoke-BicepParamDeployments.ps1 `
      -ParameterFolder "custom/modules/alert-processing-rule/parameters" `
      -TemplateFile "custom/modules/alert-processing-rule/alert-processing-rule.bicep" `
      -ResourceGroupName "UKS-MGMT-RSG-AMBA-001" `
      -Preview `
      -Recurse

#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [string] $ParameterFolder,

    [Parameter(Mandatory)]
    [string] $TemplateFile,

    [Parameter(Mandatory)]
    [string] $ResourceGroupName,

    [switch] $Preview,
    [switch] $Recurse,

    [string] $IncludePattern,
    [string] $ExcludePattern,

    [switch] $ConfirmEach
)

begin {
    # Fail fast for missing Az
    if (-not (Get-Module -ListAvailable -Name Az.Accounts, Az.Resources)) {
        throw "Required modules Az.Accounts and Az.Resources are not available. Install Az: Install-Module Az -Scope CurrentUser"
    }

    # Resolve paths for clarity
    $resolvedParamFolder = Resolve-Path -Path $ParameterFolder -ErrorAction Stop
    $resolvedTemplate    = Resolve-Path -Path $TemplateFile -ErrorAction Stop

    Write-Host "Parameter folder: $resolvedParamFolder"
    Write-Host "Template file    : $resolvedTemplate"
    Write-Host "Resource group   : $ResourceGroupName"
    Write-Host "Mode             : " -NoNewline
    if ($Preview) { Write-Host "WHAT-IF (no changes)" -ForegroundColor Yellow } else { Write-Host "APPLY (changes will be made)" -ForegroundColor Green }

    function Get-SubscriptionIdFromBicepParam {
        param(
            [Parameter(Mandatory)][string] $FilePath
        )
        # Read as raw text once; tolerate CRLF/LF and whitespace
        $content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction Stop

        # Regex to find typical bicepparam declaration:
        #   param parSubscriptionId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
        # Support single or double quotes and arbitrary whitespace.
        $regex = [regex]"(?im)^\s*param\s+\w*subscriptionid\w*\s*=\s*['""](?<id>[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})['""]"

        $m = $regex.Match($content)
        if ($m.Success) {
            return $m.Groups['id'].Value.ToLower()
        }

        # Fallback: search any GUID in the file (less strict)
        $guidRegex = [regex]"(?i)\b(?<id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\b"
        $m2 = $guidRegex.Match($content)
        if ($m2.Success) {
            return $m2.Groups['id'].Value.ToLower()
        }

        return $null
    }

    function New-SafeDeploymentName {
        param(
            [Parameter(Mandatory)][string] $Prefix # e.g., "amba-AlertProcess"
        )
        # DeploymentName max length: 64. We'll suffix with a timestamp token and trim.
        $timestamp = (Get-Date -Format "yyyyMMddTHHmmssffffZ") # monotonically increasing-ish
        $name      = "$Prefix-$timestamp"

        if ($name.Length -gt 64) {
            $name = $name.Substring(0,64)
        }

        # Allowed characters: letters, numbers, '.', '_', and '-' (safe subset)
        $name = ($name -replace '[^a-zA-Z0-9\.\-_]', '-')
        return $name
    }

    function Invoke-Deployment {
        param(
            [Parameter(Mandatory)][string] $ParamFile,
            [Parameter(Mandatory)][string] $TemplateFile,
            [Parameter(Mandatory)][string] $ResourceGroupName,
            [Parameter(Mandatory)][string] $SubscriptionId,
            [switch] $Preview,
            [switch] $ConfirmEach
        )

        # Set Az context for the subscription in the file
        try {
            Write-Host "Setting context to subscription $SubscriptionId ..." -ForegroundColor Cyan
            Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "Failed to set context for subscription $SubscriptionId for file '$ParamFile'. Skipping."
            return
        }

        # Compose the input object for this run
        $deploymentName = New-SafeDeploymentName -Prefix "amba-AlertProcess"
        $inputObject = @{
            DeploymentName        = $deploymentName
            ResourceGroupName     = $ResourceGroupName
            TemplateFile          = $TemplateFile
            TemplateParameterFile = $ParamFile
        }

        Write-Host "Prepared deployment:" -ForegroundColor DarkGray
        Write-Host "  Name: $deploymentName"
        Write-Host "  Target Resource Group  : $ResourceGroupName"
        Write-Host "  Template File : $TemplateFile"
        Write-Host "  Parameter File : $ParamFile"
        Write-Host ""

        $cmd = { New-AzResourceGroupDeployment @using:inputObject }

        if ($ConfirmEach) {
            $title = "Proceed with deployment $deploymentName against subscription $SubscriptionId?"
            $choice = Read-Host "$title (y/N)"
            if ($choice -notin @('y','Y')) {
                Write-Host "Skipped by user." -ForegroundColor Yellow
                return
            }
        }

        try {
            if ($Preview) {
                Write-Host "Executing What-If ..." -ForegroundColor Yellow
                New-AzResourceGroupDeployment -WhatIf @inputObject
            }
            else {
                Write-Host "Executing deployment ..." -ForegroundColor Green
                New-AzResourceGroupDeployment @inputObject
            }
        }
        catch {
            Write-Warning "Deployment failed for '$ParamFile' in subscription $SubscriptionId. Error: $($_.Exception.Message)"
        }
    }
}

process {
    # Build file query
    $gciParams = @{
        Path   = $resolvedParamFolder.Path
        Filter = "*.bicepparam"
    }
    if ($Recurse) { $gciParams['Recurse'] = $true }

    $files = Get-ChildItem @gciParams | Where-Object { -not $_.PSIsContainer }

    if ($IncludePattern) {
        $files = $files | Where-Object { $_.Name -like $IncludePattern }
    }
    if ($ExcludePattern) {
        $files = $files | Where-Object { $_.Name -notlike $ExcludePattern }
    }

    if (-not $files) {
        Write-Warning "No .bicepparam files found in '$resolvedParamFolder' with the given criteria."
        return
    }

    Write-Host "Found $($files.Count) .bicepparam file(s)." -ForegroundColor Cyan
    Write-Host ""

    foreach ($file in $files) {
        $paramPath = $file.FullName
        Write-Host "Processing: $($file.Name)" -ForegroundColor White

        $subId = Get-SubscriptionIdFromBicepParam -FilePath $paramPath
        if (-not $subId) {
            Write-Warning "No subscriptionId found in '$($file.Name)'. Skipping."
            continue
        }

        Invoke-Deployment `
            -ParamFile $paramPath `
            -TemplateFile $resolvedTemplate.Path `
            -ResourceGroupName $ResourceGroupName `
            -SubscriptionId $subId `
            -Preview:$Preview `
            -ConfirmEach:$ConfirmEach

        Write-Host ("-" * 60) -ForegroundColor DarkGray
    }
}

end {
    Write-Host "Completed processing." -ForegroundColor Cyan
}