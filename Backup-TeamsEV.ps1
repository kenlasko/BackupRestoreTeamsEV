<#
.SYNOPSIS
A script to automatically backup a Microsoft Teams Enterprise Voice configuration.

.DESCRIPTION
Automates the backup of Microsoft Teams Enterprise Voice normalization rules, dialplans, voice policies, voice routes, PSTN usages and PSTN GW translation rules for various countries.

.PARAMETER OverrideAdminDomain
OPTIONAL: The FQDN your Office365 tenant. Use if your admin account is not in the same domain as your tenant (ie. doesn't use a @tenantname.onmicrosoft.com address)

Version 1.00
Build: Feb 04, 2020

Copyright © 2020  Ken Lasko  
klasko@ucdialplans.com
https://www.ucdialplans.com
#>

# The below settings are for applying command line options for unattended script application
param (
	# Input the OverrideAdminDomain. Use if you normally have to enter your onmicrosoft.com domain name when signing onto O365
	[Parameter(ValueFromPipeline = $False, ValueFromPipelineByPropertyName = $True)]
	[ValidateNotNullOrEmpty()]
	[string] $OverrideAdminDomain
)

$Filenames = "Dialplans.txt", "VoiceRoutes.txt", "VoiceRoutingPolicies.txt", "PSTNUsages.txt", "TranslationRules.txt", "PSTNGateways.txt"

If ((Get-PSSession).State -eq 'Opened') {
	Write-Host 'Using existing session credentials'}
Else {
	Write-Host "Logging into Office 365..."
	$O365Session = New-CsOnlineSession -OverrideAdminDomain $OverrideAdminDomain
	Import-PSSession $O365Session -AllowClobber
}

Try {
	Get-CsTenantDialPlan | ConvertTo-Json | Out-File Dialplans.txt
	Get-CsOnlineVoiceRoute | ConvertTo-Json | Out-File VoiceRoutes.txt
	Get-CsOnlineVoiceRoutingPolicy | ConvertTo-Json | Out-File VoiceRoutingPolicies.txt
	Get-CsOnlinePstnUsage | ConvertTo-Json | Out-File PSTNUsages.txt
	Get-CsTeamsTranslationRule | ConvertTo-Json | Out-File TranslationRules.txt
	Get-CsOnlinePSTNGateway | ConvertTo-Json | Out-File PSTNGateways.txt
}
Catch {
	Write-Error "There was an error backing up the MS Teams Enterprise Voice configuration."
	Exit
}

Compress-Archive -Path $FileNames -DestinationPath "TeamsEVBackup_$(get-date -f yyyy-MM-dd).zip" -Force
Remove-Item $Filenames

Write-Host "Microsoft Teams Enterprise Voice configuration backed up to TeamsEVBackup_$(get-date -f yyyy-MM-dd).zip"
