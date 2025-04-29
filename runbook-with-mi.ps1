# Sign in to your Azure subscription
Connect-AzAccount
[Select 126, plx-ccoe-sbx-glb]

# If you have multiple subscriptions, set the one to use
$context = Get-AzSubscription -SubscriptionId 66517894-4511-4118-a3a4-6c07e925ec64
Set-AzContext $context



# These values are used in this tutorial
$resourceGroup = "plx-rg-ccoe-pnr-aut"
$automationAccount = "plx-aut-ccoe-pnr-auto"
$userAssignedManagedIdentity = "plx-mi-ccoe-pnr-mui"

# Use PowerShell cmdlet New-AzRoleAssignment to assign a role to the system-assigned managed identity.
$role1 = "DevTest Labs User"

$SAMI = (Get-AzAutomationAccount -ResourceGroupName $resourceGroup -Name $automationAccount).Identity.PrincipalId
New-AzRoleAssignment `
    -ObjectId $SAMI `
    -ResourceGroupName $resourceGroup `
    -RoleDefinitionName $role1

# The same role assignment is needed for the user-assigned managed identity
$UAMI = (Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroup -Name $userAssignedManagedIdentity).PrincipalId
New-AzRoleAssignment `
    -ObjectId $UAMI `
    -ResourceGroupName $resourceGroup `
    -RoleDefinitionName $role1

# Additional permissions for the system-assigned managed identity are needed to execute cmdlets Get-AzUserAssignedIdentity and Get-AzAutomationAccount as used in this tutorial.
$role2 = "Reader"
New-AzRoleAssignment `
    -ObjectId $SAMI `
    -ResourceGroupName $resourceGroup `
    -RoleDefinitionName $role2

# Runbook code
Param(
    [string]$ResourceGroup,
    [string]$VMName,
    [string]$Method,
    [string]$UAMI 
)

$automationAccount = "plx-aut-ccoe-pnr-auto"

# Ensures you do not inherit an AzContext in your runbook
$null = Disable-AzContextAutosave -Scope Process

# Connect using a Managed Service Identity
try {
    $AzureConnection = (Connect-AzAccount -Identity).context
}
catch {
    Write-Output "There is no system-assigned user identity. Aborting." 
    exit
}

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureConnection.Subscription -DefaultProfile $AzureConnection

if ($Method -eq "SA") {
    Write-Output "Using system-assigned managed identity"
}
elseif ($Method -eq "UA") {
    Write-Output "Using user-assigned managed identity"

# Connects using the Managed Service Identity of the named user-assigned managed identity
    $identity = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroup -Name $UAMI -DefaultProfile $AzureContext

# validates assignment only, not perms
    $AzAutomationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroup -Name $automationAccount -DefaultProfile $AzureContext
    if ($AzAutomationAccount.Identity.UserAssignedIdentities.Values.PrincipalId.Contains($identity.PrincipalId)) {
        $AzureConnection = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context

# set and store context
        $AzureContext = Set-AzContext -SubscriptionName $AzureConnection.Subscription -DefaultProfile $AzureConnection
    }
    else {
        Write-Output "Invalid or unassigned user-assigned managed identity"
        exit
    }
}
else {
    Write-Output "Invalid method. Choose UA or SA."
    exit
}

# Get current state of VM
$status = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Status -DefaultProfile $AzureContext).Statuses[1].Code

Write-Output "`r`n Beginning VM status: $status `r`n"

# Start or stop VM based on current state
if ($status -eq "Powerstate/deallocated") {
    Start-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -DefaultProfile $AzureContext
}
elseif ($status -eq "Powerstate/running") {
    Stop-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -DefaultProfile $AzureContext -Force
}

# Get new state of VM
$status = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Status -DefaultProfile $AzureContext).Statuses[1].Code

Write-Output "`r`n Ending VM status: $status `r`n `r`n"

Write-Output "Account ID of current context: " $AzureContext.Account.Id


# Start with Webhook
$Names  = @(
    @{ Name="Hawaii"},
    @{ Name="Seattle"},
    @{ Name="Florida"}
)

$body = ConvertTo-Json -InputObject $Names
# URL needs commas around it
$webhookURI = "https://8cd62a72-fbf8-4b16-a436-d769de327912.webhook.ne.azure-automation.net/webhooks?token=MOe7MbcDjUoEOGZ4SKANaUGaacPfqW%2btbPzDdmS1VW4%3d"

$response = Invoke-WebRequest -Method Post -Uri $webhookURI -Body $body -UseBasicParsing
$response

$responseFile = Invoke-WebRequest -Method Post -Uri $webhookURI -Body $bodyFile -UseBasicParsing
$responseFile

#isolate job ID
$jobid = (ConvertFrom-Json ($response.Content)).jobids[0]
$jobid
# Get output
Get-AzAutomationJobOutput `
    -AutomationAccountName $automationAccount `
    -Id $jobid `
    -ResourceGroupName $resourceGroup `
    -Stream Output
