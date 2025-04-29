# DATE: 29-04-2023
# SOURCE: https://learn.microsoft.com/en-us/azure/automation/learn/powershell-runbook-managed-identity

# Install Powershell on Mac
- https://learn.microsoft.com/en-gb/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.5

brew install powershell/tap/powershell
pwsh

# Instal AZ PS
## Get Currently Installed modules
Get-Module -ListAvailable | Where-Object Name -like "AZ*"

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber


# Start with Webhook
 - SOURCE: https://learn.microsoft.com/en-us/azure/automation/automation-webhooks?tabs=portal