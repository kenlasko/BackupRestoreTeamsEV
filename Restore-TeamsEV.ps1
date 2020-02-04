<#
.SYNOPSIS
A script to automatically restore a backed-up Teams Enterprise Voice configuration.

.DESCRIPTION
A script to automatically restore a backed-up Teams Enterprise Voice configuration. Requires a backup run using Backup-TeamsEV.ps1 in the same directory as the script. Will restore the following items:
- Dialplans and associated normalization rules
- Voice routes
- Voice routing policies
- PSTN usages
- Outbound translation rules

The script must be run from a Skype for Business server.

User running the script must have the following roles at minimum:
- member of the local Administrators group on all SfB and associated servers
- ability to add user accounts and groups to the domain (depending on selected options)
- at least CSViewOnlyAdministrator rights in SfB. CSAdministrator role required for some selected options
- read rights to any SQL server associated with SfB

.PARAMETER File
REQUIRED. Path to the zip file containing the backed up Teams EV config to restore 

.PARAMETER KeepExisting
OPTIONAL. Will not erase existing Enterprise Voice configuration before restoring. 

.PARAMETER OverrideAdminDomain
OPTIONAL: The FQDN your Office365 tenant. Use if your admin account is not in the same domain as your tenant (ie. doesn't use a @tenantname.onmicrosoft.com address)

Version 1.00
Build: Feb 04, 2020

Copyright © 2020  Ken Lasko  
klasko@ucdialplans.com
https://www.ucdialplans.com
#>

[cmdletbinding()]
Param(
	[parameter(ValueFromPipelineByPropertyName, Mandatory=$True)]
	[string]$File,
	[Parameter(Mandatory=$False)]
	[switch]$KeepExisting,
	[Parameter(Mandatory=$False, ValidateNotNullOrEmpty())]
	[string] $OverrideAdminDomain
)

Try {
	$ZipPath = Resolve-Path $File
	$ZipStream = [io.compression.zipfile]::OpenRead($ZipPath)
}
Catch {
	Write-Error "Could not open zip archive."
	Exit
}

If ((Get-PSSession).State -eq 'Opened') {
	Write-Host 'Using existing session credentials'}
Else {
	Write-Host "Logging into Office 365..."
	If ($OverrideAdminDomain) {
		$O365Session = New-CsOnlineSession -OverrideAdminDomain $OverrideAdminDomain
	}
	Else {
		$O365Session = New-CsOnlineSession
	}
	Import-PSSession $O365Session -AllowClobber
}

$EV_Entities = "Dialplans", "VoiceRoutes", "VoiceRoutingPolicies", "PSTNUsages", "TranslationRules", "PSTNGateways"

Write-Host "Validating backup files." 

ForEach ($EV_Entity in $EV_Entities) {
	Try {
		$ZipItem = $ZipStream.GetEntry("$EV_Entity.txt")
		$ItemReader = New-Object System.IO.StreamReader($ZipItem.Open())

		Set-Variable -Name $EV_Entity -Value ($ItemReader.ReadToEnd() | ConvertFrom-Json)
		If ((Get-Variable $EV_Entity).Value[0].Identity -eq $NULL) {Throw("Error")} # Throw error if there is no Identity field, which indicates this isn't a proper backup file
	}
	Catch {
		Write-Error "$EV_Entity.txt could not be found or could not be parsed. Exiting."
		Exit
	}
}

Write-Host -ForegroundColor Green "Backup files are OK!"

If (!$KeepExisting) {
	$Confirm = Read-Host "WARNING: This will ERASE all existing dialplans/voice routes/policies etc prior to restoring from backup. Continue (Y/N)?"
	If ($Confirm -notmatch "^[Yy]$") {
		Write-Host "Exiting without making changes."
		Exit
	}
	
	Write-Host "Erasing all existing dialplans/voice routes/policies etc."
	Get-CsTenantDialPlan | Remove-CsTenantDialPlan
	Get-CsOnlineVoiceRoute | Remove-CsOnlineVoiceRoute
	Get-CsOnlineVoiceRoutingPolicy | Remove-CsOnlineVoiceRoutingPolicy
	Set-CsOnlinePstnUsage Global -Usage $NULL
	Get-CsOnlinePSTNGateway | Set-CsOnlinePSTNGateway -OutbundTeamsNumberTranslationRules $NULL -OutboundPstnNumberTranslationRules $NULL
	Get-CsTeamsTranslationRule | Remove-CsTeamsTranslationRule 
}

# Rebuild tenant dialplans from backup
Write-Host "Restoring tenant dialplans"
ForEach ($Dialplan in $Dialplans) {
	$DPExists = (Get-CsTenantDialplan $Dialplan.Identity -ErrorAction:SilentlyContinue).Identity 

	If ($DPExists) {
		Set-CsTenantDialplan -Identity $Dialplan.Identity -OptimizeDeviceDialing $Dialplan.OptimizeDeviceDialing -Description $Dialplan.Description
		If ($Dialplan.ExternalAccessPrefix) { # Have to do this because MS won't allow $NULL or empty ExternalAccessPrefix, but is happy if you don't include it
			Set-CsTenantDialplan -Identity $Dialplan.Identity -ExternalAccessPrefix $Dialplan.ExternalAccessPrefix
		}
	}
	Else {
		New-CsTenantDialplan -Identity $Dialplan.Identity -OptimizeDeviceDialing $Dialplan.OptimizeDeviceDialing -Description $Dialplan.Description
		If ($Dialplan.ExternalAccessPrefix) { # Have to do this because MS won't allow $NULL or empty ExternalAccessPrefix, but is happy if you don't include it
			Set-CsTenantDialplan -Identity $Dialplan.Identity -ExternalAccessPrefix $Dialplan.ExternalAccessPrefix
		}
	}
	
	$NormRules = @()
	ForEach ($NormRule in $Dialplan.NormalizationRules) {
		$Description = [regex]::Match($NormRule,"(?ms)^Description=(.*?);").Groups[1].Value
		$Pattern = [regex]::Match($NormRule,"(?ms)Pattern=(.*?);").Groups[1].Value
		$Translation = [regex]::Match($NormRule,"(?ms)Translation=(.*?);").Groups[1].Value
		$Name = [regex]::Match($NormRule,"(?ms)Name=(.*?);").Groups[1].Value
		$IsInternalExtension = [System.Convert]::ToBoolean([regex]::Match($NormRule,"(?ms)IsInternalExtension=(.*?)$").Groups[1].Value)
		
		$NormRules += New-CsVoiceNormalizationRule -Name $Name -Parent $Dialplan.Identity -Pattern $Pattern -Translation $Translation -Description $Description -InMemory -IsInternalExtension $IsInternalExtension
	}
	
	Set-CsTenantDialPlan -Identity $Dialplan.Identity -NormalizationRules $NormRules
}

# Rebuild PSTN usages from backup
Write-Host "Restoring PSTN usages"
ForEach ($PSTNUsage in $PSTNUsages.Usage) {
	Set-CsOnlinePSTNUsage -Identity Global -Usage @{Add=$PSTNUsage} -WarningAction:SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
}

# Rebuild voice routes from backup
Write-Host "Restoring voice routes"
ForEach ($VoiceRoute in $VoiceRoutes) {
	$VRExists = (Get-CsOnlineVoiceRoute $VoiceRoute.Identity -ErrorAction:SilentlyContinue).Identity 
	If ($VRExists) {
		Set-CsOnlineVoiceRoute -Identity $VoiceRoute.Identity -NumberPattern $VoiceRoute.NumberPattern -Priority $VoiceRoute.Priority -OnlinePstnUsages $VoiceRoute.OnlinePstnUsages -OnlinePstnGatewayList $VoiceRoute.OnlinePstnGatewayList -Description $VoiceRoute.Description
	}
	Else {
		New-CsOnlineVoiceRoute -Identity $VoiceRoute.Identity -NumberPattern $VoiceRoute.NumberPattern -Priority $VoiceRoute.Priority -OnlinePstnUsages $VoiceRoute.OnlinePstnUsages -OnlinePstnGatewayList $VoiceRoute.OnlinePstnGatewayList -Description $VoiceRoute.Description
	}
}

# Rebuild voice routing policies from backup
Write-Host "Restoring voice routing policies"
ForEach ($VoiceRoutingPolicy in $VoiceRoutingPolicies) {
	$VPExists = (Get-CsOnlineVoiceRoutingPolicy $VoiceRoutingPolicy.Identity -ErrorAction:SilentlyContinue).Identity 
	If ($VPExists) {
		Set-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy.Identity -OnlinePstnUsages $VoiceRoutingPolicy.OnlinePstnUsages -Description $VoiceRoutingPolicy.Description
	}
	Else {
		New-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy.Identity -OnlinePstnUsages $VoiceRoutingPolicy.OnlinePstnUsages -Description $VoiceRoutingPolicy.Description
	}
}

# Rebuild outbound translation rules from backup
Write-Host "Restoring outbound translation rules"
ForEach ($TranslationRule in $TranslationRules) {
	$TRExists = (Get-CsTeamsTranslationRule $TranslationRule.Identity -ErrorAction:SilentlyContinue).Identity 
	If ($TRExists) {
		Set-CsTeamsTranslationRule -Identity $TranslationRule.Identity -Pattern $TranslationRule.Pattern -Translation $TranslationRule.Translation -Description $TranslationRule.Description
	}
	Else {
		New-CsTeamsTranslationRule -Identity $TranslationRule.Identity -Pattern $TranslationRule.Pattern -Translation $TranslationRule.Translation -Description $TranslationRule.Description
	}
}

# Re-add translation rules to PSTN gateways
Write-Host "Re-adding translation rules to PSTN gateways"
ForEach ($PSTNGateway in $PSTNGateways) {
	$GWExists = (Get-CsOnlinePSTNGateway $PSTNGateway.Identity -ErrorAction:SilentlyContinue).Identity 
	If ($GWExists) {
		Set-CsOnlinePSTNGateway -Identity $PSTNGateway.Identity -OutbundTeamsNumberTranslationRules $PSTNGateway.OutbundTeamsNumberTranslationRules -OutboundPstnNumberTranslationRules $PSTNGateway.OutboundPstnNumberTranslationRules -InboundTeamsNumberTranslationRules $PSTNGateway.InboundTeamsNumberTranslationRules -InboundPstnNumberTranslationRules $PSTNGateway.InboundPstnNumberTranslationRules
	}
}

Write-Host "Finished!"
