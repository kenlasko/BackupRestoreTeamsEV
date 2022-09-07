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

	.PARAMETER File
		REQUIRED. Path to the zip file containing the backed up Teams EV config to restore

	.PARAMETER KeepExisting
		OPTIONAL. Will not erase existing Enterprise Voice configuration before restoring.

	.PARAMETER OverrideAdminDomain
		OPTIONAL: The FQDN your Office365 tenant. Use if your admin account is not in the same domain as your tenant (ie. doesn't use a @tenantname.onmicrosoft.com address)

	.NOTES
		Version 1.10
		Build: Feb 04, 2020

		Copyright © 2020  Ken Lasko
		klasko@ucdialplans.com
		https://www.ucdialplans.com
#>

[CmdletBinding(ConfirmImpact = 'Medium',
SupportsShouldProcess)]
param
(
	[Parameter(Mandatory, HelpMessage = 'Path to the zip file containing the backed up Teams EV config to restore',
	ValueFromPipelineByPropertyName)]
	[string]
	$File,
	[switch]
	$KeepExisting,
	[string]
	$OverrideAdminDomain
)

Try {
	$ZipPath = (Resolve-Path -Path $File)
	$null = (Add-Type -AssemblyName System.IO.Compression.FileSystem)
	$ZipStream = [io.compression.zipfile]::OpenRead($ZipPath)
}
Catch {
	Write-Error -Message 'Could not open zip archive.' -ErrorAction Stop
	Exit
}

Try {
	Connect-MicrosoftTeams
}
Catch {
	Write-Warning 'Microsoft Teams PowerShell module not installed. Please install via Install-Module MicrosoftTeams, then run the script again.'
	Break
}

$EV_Entities = 'Dialplans', 'VoiceRoutes', 'VoiceRoutingPolicies', 'PSTNUsages', 'TranslationRules', 'PSTNGateways'

Write-Host -Object 'Validating backup files.'

ForEach ($EV_Entity in $EV_Entities) {
	Try {
		$ZipItem = $ZipStream.GetEntry("$EV_Entity.txt")
		$ItemReader = (New-Object -TypeName System.IO.StreamReader -ArgumentList ($ZipItem.Open()))

		$null = (Set-Variable -Name $EV_Entity -Value ($ItemReader.ReadToEnd() | ConvertFrom-Json))

		# Throw error if there is no Identity field, which indicates this isn't a proper backup file
		If ($null -eq ((Get-Variable -Name $EV_Entity).Value[0].Identity)) {
			$null = (Set-Variable -Name $EV_Entity -Value $NULL)
			Throw ('Error')
		}
	}
	Catch {
		Write-Error -Message ($EV_Entity + '.txt could not be found, was empty or could not be parsed. ' + $EV_Entity + ' will not be restored.') -ErrorAction Continue
	}
	$ItemReader.Close()
}

If (!$KeepExisting) {
	$Confirm = Read-Host -Prompt 'WARNING: This will ERASE all existing dialplans/voice routes/policies etc prior to restoring from backup. Continue (Y/N)?'
	If ($Confirm -notmatch '^[Yy]$') {
		Write-Host -Object 'Exiting without making changes.'
		Exit
	}

	Write-Host -Object 'Erasing all existing dialplans/voice routes/policies etc.'

	Write-Verbose 'Erasing all tenant dialplans'
	$null = (Get-CsTenantDialPlan -ErrorAction SilentlyContinue | Remove-CsTenantDialPlan -ErrorAction SilentlyContinue)
	Write-Verbose 'Erasing all online voice routes'
	$null = (Get-CsOnlineVoiceRoute -ErrorAction SilentlyContinue | Remove-CsOnlineVoiceRoute -ErrorAction SilentlyContinue)
	Write-Verbose 'Erasing all online voice routing policies'
	$null = (Get-CsOnlineVoiceRoutingPolicy -ErrorAction SilentlyContinue | Remove-CsOnlineVoiceRoutingPolicy -ErrorAction SilentlyContinue)
	Write-Verbose 'Erasing all PSTN usages'
	$null = (Set-CsOnlinePstnUsage -Identity Global -Usage $NULL -ErrorAction SilentlyContinue)
	Write-Verbose 'Removing translation rules from PSTN gateways'
	$null = (Get-CsOnlinePSTNGateway -ErrorAction SilentlyContinue | Set-CsOnlinePSTNGateway -OutboundTeamsNumberTranslationRules $NULL -OutboundPstnNumberTranslationRules $NULL -ErrorAction SilentlyContinue)
	Write-Verbose 'Removing translation rules'
	$null = (Get-CsTeamsTranslationRule -ErrorAction SilentlyContinue | Remove-CsTeamsTranslationRule -ErrorAction SilentlyContinue)
}

# Rebuild tenant dialplans from backup
Write-Host -Object 'Restoring tenant dialplans'

ForEach ($Dialplan in $Dialplans) {
	Write-Verbose "Restoring $($Dialplan.Identity) dialplan"
	$DPExists = (Get-CsTenantDialPlan -Identity $Dialplan.Identity -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Identity)

	$DPDetails = @{
		Identity = $Dialplan.Identity
		OptimizeDeviceDialing = $Dialplan.OptimizeDeviceDialing
		Description = $Dialplan.Description
	}

	# Only include the external access prefix if one is defined. MS throws an error if you pass a null/empty ExternalAccessPrefix
	If ($Dialplan.ExternalAccessPrefix) {
		$DPDetails.Add("ExternalAccessPrefix", $Dialplan.ExternalAccessPrefix)
	}

	If ($DPExists) {
		$null = (Set-CsTenantDialPlan @DPDetails)
	}
	Else {
		$null = (New-CsTenantDialPlan @DPDetails)
	}

	# Create a new Object
	$NormRules = @()

	ForEach ($NormRule in $Dialplan.NormalizationRules) {
		$NRDetails = @{
			Parent = $Dialplan.Identity
			Name = [regex]::Match($NormRule, '(?ms)Name=(.*?);').Groups[1].Value
			Pattern = [regex]::Match($NormRule, '(?ms)Pattern=(.*?);').Groups[1].Value
			Translation = [regex]::Match($NormRule, '(?ms)Translation=(.*?);').Groups[1].Value
			Description = [regex]::Match($NormRule, '(?ms)^Description=(.*?);').Groups[1].Value
			IsInternalExtension = [Convert]::ToBoolean([regex]::Match($NormRule, '(?ms)IsInternalExtension=(.*?)$').Groups[1].Value)
		}
		$NormRules += New-CsVoiceNormalizationRule @NRDetails -InMemory
	}
	$null = (Set-CsTenantDialPlan -Identity $Dialplan.Identity -NormalizationRules $NormRules)
}

# Rebuild PSTN usages from backup
Write-Host -Object 'Restoring PSTN usages'

ForEach ($PSTNUsage in $PSTNUsages.Usage) {
	Write-Verbose "Restoring $PSTNUsage PSTN usage"
	$null = (Set-CsOnlinePstnUsage -Identity Global -Usage @{Add = $PSTNUsage} -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
}

# Rebuild voice routes from backup
Write-Host -Object 'Restoring voice routes'

ForEach ($VoiceRoute in $VoiceRoutes) {
	Write-Verbose "Restoring $($VoiceRoute.Identity) voice route"
	$VRExists = (Get-CsOnlineVoiceRoute -Identity $VoiceRoute.Identity -ErrorAction SilentlyContinue).Identity

	$VRDetails = @{
		Identity = $VoiceRoute.Identity
		NumberPattern = $VoiceRoute.NumberPattern
		Priority = $VoiceRoute.Priority
		OnlinePstnUsages = $VoiceRoute.OnlinePstnUsages
		OnlinePstnGatewayList = $VoiceRoute.OnlinePstnGatewayList
		Description = $VoiceRoute.Description
	}

	If ($VRExists) {
		$null = (Set-CsOnlineVoiceRoute @VRDetails)
	}
	Else {
		$null = (New-CsOnlineVoiceRoute @VRDetails)
	}
}

# Rebuild voice routing policies from backup
Write-Host -Object 'Restoring voice routing policies'

ForEach ($VoiceRoutingPolicy in $VoiceRoutingPolicies) {
	Write-Verbose "Restoring $($VoiceRoutingPolicy.Identity) voice routing policy"
	$VPExists = (Get-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy.Identity -ErrorAction SilentlyContinue).Identity

	$VPDetails = @{
		Identity = $VoiceRoutingPolicy.Identity
		OnlinePstnUsages = $VoiceRoutingPolicy.OnlinePstnUsages
		Description = $VoiceRoutingPolicy.Description
	}

	If ($VPExists) {
		$null = (Set-CsOnlineVoiceRoutingPolicy @VPDetails)
	}
	Else {
		$null = (New-CsOnlineVoiceRoutingPolicy @VPDetails)
	}
}

# Rebuild outbound translation rules from backup
Write-Host -Object 'Restoring outbound translation rules'

ForEach ($TranslationRule in $TranslationRules) {
	Write-Verbose "Restoring $($TranslationRule.Identity) translation rule"
	$TRExists = (Get-CsTeamsTranslationRule -Identity $TranslationRule.Identity -ErrorAction SilentlyContinue).Identity

	$TRDetails = @{
		Identity = $TranslationRule.Identity
		Pattern = $TranslationRule.Pattern
		Translation = $TranslationRule.Translation
		Description = $TranslationRule.Description
	}

	If ($TRExists) {
		$null = (Set-CsTeamsTranslationRule @TRDetails)
	}
	Else {
		$null = (New-CsTeamsTranslationRule @TRDetails)
	}
}

# Re-add translation rules to PSTN gateways
Write-Host -Object 'Re-adding translation rules to PSTN gateways'

ForEach ($PSTNGateway in $PSTNGateways) {
	Write-Verbose "Restoring translation rules to $($PSTNGateway.Identity)"
	$GWExists = (Get-CsOnlinePSTNGateway -Identity $PSTNGateway.Identity -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Identity)

	$GWDetails = @{
		Identity = $PSTNGateway.Identity
		OutbundTeamsNumberTranslationRules = $PSTNGateway.OutbundTeamsNumberTranslationRules #Sadly Outbund isn't a spelling mistake here. That's what the command uses.
		OutboundPstnNumberTranslationRules = $PSTNGateway.OutboundPstnNumberTranslationRules
		InboundTeamsNumberTranslationRules = $PSTNGateway.InboundTeamsNumberTranslationRules
		InboundPstnNumberTranslationRules = $PSTNGateway.InboundPstnNumberTranslationRules
	}
	If ($GWExists) {
		$null = (Set-CsOnlinePSTNGateway @GWDetails)
	}
}

Write-Host -Object 'Finished!'
