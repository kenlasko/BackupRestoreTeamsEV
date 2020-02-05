<#
	.SYNOPSIS
		A script to automatically backup a Microsoft Teams Enterprise Voice configuration.
	
	.DESCRIPTION
		Automates the backup of Microsoft Teams Enterprise Voice normalization rules, dialplans, voice policies, voice routes, PSTN usages and PSTN GW translation rules for various countries.
	
	.PARAMETER OverrideAdminDomain
		OPTIONAL: The FQDN your Office365 tenant. Use if your admin account is not in the same domain as your tenant (ie. doesn't use a @tenantname.onmicrosoft.com address)

	.NOTES
		Version 1.00
		Build: Feb 04, 2020
		
		Copyright © 2020  Ken Lasko
		klasko@ucdialplans.com
		https://www.ucdialplans.com
#>
[CmdletBinding(ConfirmImpact = 'None')]
param
(
	[Parameter(ValueFromPipelineByPropertyName)]
	[ValidateNotNullOrEmpty()]
	[string]
	$OverrideAdminDomain
)

$Filenames = 'Dialplans.txt', 'VoiceRoutes.txt', 'VoiceRoutingPolicies.txt', 'PSTNUsages.txt', 'TranslationRules.txt', 'PSTNGateways.txt'

if ((Get-PSSession | Where-Object -FilterScript {
         $_.ComputerName -like '*.online.lync.com'
}).State -eq 'Opened')
{
   Write-Host -Object 'Using existing session credentials'
}
else
{
   Write-Host -Object 'Logging into Office 365...'
   
   $O365Session = (New-CsOnlineSession -OverrideAdminDomain $OverrideAdminDomain)
   $null = (Import-PSSession -Session $O365Session -AllowClobber)
}

try
{
	$null = (Get-CsTenantDialPlan | ConvertTo-Json | Out-File -FilePath Dialplans.txt -Force -Encoding utf8)
	$null = (Get-CsOnlineVoiceRoute | ConvertTo-Json | Out-File -FilePath VoiceRoutes.txt -Force -Encoding utf8)
	$null = (Get-CsOnlineVoiceRoutingPolicy | ConvertTo-Json | Out-File -FilePath VoiceRoutingPolicies.txt -Force -Encoding utf8)
	$null = (Get-CsOnlinePstnUsage | ConvertTo-Json | Out-File -FilePath PSTNUsages.txt -Force -Encoding utf8)
	$null = (Get-CsTeamsTranslationRule | ConvertTo-Json | Out-File -FilePath TranslationRules.txt -Force -Encoding utf8)
	$null = (Get-CsOnlinePSTNGateway | ConvertTo-Json | Out-File -FilePath PSTNGateways.txt -Force -Encoding utf8)
}
catch
{
	Write-Error -Message 'There was an error backing up the MS Teams Enterprise Voice configuration.'
	exit
}

$BackupFile = ('TeamsEVBackup_' + (Get-Date -Format yyyy-MM-dd) + '.zip')
$null = (Compress-Archive -Path $Filenames -DestinationPath $BackupFile -Force)
$null = (Remove-Item -Path $Filenames -Force -Confirm:$false)

Write-Host -Object ('Microsoft Teams Enterprise Voice configuration backed up to {0}' -f $BackupFile)
