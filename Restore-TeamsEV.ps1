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
	
      .NOTES
      Additional information about the file.
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


try
{
	$ZipPath = Resolve-Path -Path $File
	$null = (Add-Type -AssemblyName System.IO.Compression.FileSystem)
	$ZipStream = [io.compression.zipfile]::OpenRead($ZipPath)
}
catch
{
	Write-Error -Message 'Could not open zip archive.'
	exit
}

if ((Get-PSSession | Where-Object -FilterScript {
			$_.ComputerName -like '*.online.lync.com'
		}).State -eq 'Opened')
{
	Write-Host -Object 'Using existing session credentials'
}
else
{
	Write-Host -Object 'Logging into Office 365...'
	if ($OverrideAdminDomain)
	{
		$O365Session = New-CsOnlineSession -OverrideAdminDomain $OverrideAdminDomain
	}
	else
	{
		$O365Session = New-CsOnlineSession
	}
	Import-PSSession -Session $O365Session -AllowClobber
}

$EV_Entities = 'Dialplans', 'VoiceRoutes', 'VoiceRoutingPolicies', 'PSTNUsages', 'TranslationRules', 'PSTNGateways'

Write-Host -Object 'Validating backup files.'

foreach ($EV_Entity in $EV_Entities)
{
	try
	{
		$ZipItem = $ZipStream.GetEntry("$EV_Entity.txt")
		$ItemReader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($ZipItem.Open())
		
		Set-Variable -Name $EV_Entity -Value ($ItemReader.ReadToEnd() | ConvertFrom-Json)
		
		if ((Get-Variable -Name $EV_Entity).Value[0].Identity -eq $NULL)
		{
			throw ('Error')
		} # Throw error if there is no Identity field, which indicates this isn't a proper backup file
	}
	catch
	{
		Write-Error -Message "$EV_Entity.txt could not be found or could not be parsed. Exiting."
		exit
	}
}

Write-Host -ForegroundColor Green -Object 'Backup files are OK!'

if (!$KeepExisting)
{
	$Confirm = Read-Host -Prompt 'WARNING: This will ERASE all existing dialplans/voice routes/policies etc prior to restoring from backup. Continue (Y/N)?'
	if ($Confirm -notmatch '^[Yy]$')
	{
		Write-Host -Object 'Exiting without making changes.'
		exit
	}
	
	Write-Host -Object 'Erasing all existing dialplans/voice routes/policies etc.'
	
	Get-CsTenantDialPlan | Remove-CsTenantDialPlan
	Get-CsOnlineVoiceRoute | Remove-CsOnlineVoiceRoute
	Get-CsOnlineVoiceRoutingPolicy | Remove-CsOnlineVoiceRoutingPolicy
	Set-CsOnlinePstnUsage -ErrorAction Global -Usage $NULL
	Get-CsOnlinePSTNGateway | Set-CsOnlinePSTNGateway -OutbundTeamsNumberTranslationRules $NULL -OutboundPstnNumberTranslationRules $NULL
	Get-CsTeamsTranslationRule | Remove-CsTeamsTranslationRule
}

# Rebuild tenant dialplans from backup
Write-Host -Object 'Restoring tenant dialplans'
foreach ($Dialplan in $Dialplans)
{
	
	$DPExists = (Get-CsTenantDialPlan -OutVariable $Dialplan.Identity -ErrorAction:SilentlyContinue | Select-Object -ExpandProperty Identity)
	
	if ($DPExists)
	{
		# TODO: Splat
		Set-CsTenantDialPlan -Identity $Dialplan.Identity -OptimizeDeviceDialing $Dialplan.OptimizeDeviceDialing -Description $Dialplan.Description
		
		if ($Dialplan.ExternalAccessPrefix)
		{
			# Have to do this because MS won't allow $NULL or empty ExternalAccessPrefix, but is happy if you don't include it
			Set-CsTenantDialPlan -Identity $Dialplan.Identity -ExternalAccessPrefix $Dialplan.ExternalAccessPrefix
		}
	}
	else
	{
		# TODO: Splat
		New-CsTenantDialPlan -Identity $Dialplan.Identity -OptimizeDeviceDialing $Dialplan.OptimizeDeviceDialing -Description $Dialplan.Description
		
		if ($Dialplan.ExternalAccessPrefix)
		{
			# Have to do this because MS won't allow $NULL or empty ExternalAccessPrefix, but is happy if you don't include it
			Set-CsTenantDialPlan -Identity $Dialplan.Identity -ExternalAccessPrefix $Dialplan.ExternalAccessPrefix
		}
	}
	
	$NormRules = @()
	foreach ($NormRule in $Dialplan.NormalizationRules)
	{
		$Description = [regex]::Match($NormRule, '(?ms)^Description=(.*?);').Groups[1].Value
		$Pattern = [regex]::Match($NormRule, '(?ms)Pattern=(.*?);').Groups[1].Value
		$Translation = [regex]::Match($NormRule, '(?ms)Translation=(.*?);').Groups[1].Value
		$Name = [regex]::Match($NormRule, '(?ms)Name=(.*?);').Groups[1].Value
		$IsInternalExtension = [Convert]::ToBoolean([regex]::Match($NormRule, '(?ms)IsInternalExtension=(.*?)$').Groups[1].Value)
		
		$NormRules += New-CsVoiceNormalizationRule -Name $Name -Parent $Dialplan.Identity -Pattern $Pattern -Translation $Translation -Description $Description -InMemory -IsInternalExtension $IsInternalExtension
	}
	
	Set-CsTenantDialPlan -Identity $Dialplan.Identity -NormalizationRules $NormRules
}

# Rebuild PSTN usages from backup
Write-Host -Object 'Restoring PSTN usages'

# $PSTNUsages is not defined
foreach ($PSTNUsage in $PSTNUsages.Usage)
{
	$NULL = (Set-CsOnlinePstnUsage -Identity Global -Usage @{
			Add = $PSTNUsage
		} -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
}

# Rebuild voice routes from backup
Write-Host -Object 'Restoring voice routes'

# $VoiceRoutes is not defined
foreach ($VoiceRoute in $VoiceRoutes)
{
	$VRExists = (Get-CsOnlineVoiceRoute -OutVariable $VoiceRoute.Identity -ErrorAction:SilentlyContinue).Identity
	
	if ($VRExists)
	{
		# TODO: Splat
		Set-CsOnlineVoiceRoute -Identity $VoiceRoute.Identity -NumberPattern $VoiceRoute.NumberPattern -Priority $VoiceRoute.Priority -OnlinePstnUsages $VoiceRoute.OnlinePstnUsages -OnlinePstnGatewayList $VoiceRoute.OnlinePstnGatewayList -Description $VoiceRoute.Description
	}
	else
	{
		# TODO: Splat
		New-CsOnlineVoiceRoute -Identity $VoiceRoute.Identity -NumberPattern $VoiceRoute.NumberPattern -Priority $VoiceRoute.Priority -OnlinePstnUsages $VoiceRoute.OnlinePstnUsages -OnlinePstnGatewayList $VoiceRoute.OnlinePstnGatewayList -Description $VoiceRoute.Description
	}
}

# Rebuild voice routing policies from backup
Write-Host -Object 'Restoring voice routing policies'

# $VoiceRoutingPolicies is not defined
foreach ($VoiceRoutingPolicy in $VoiceRoutingPolicies)
{
	$VPExists = (Get-CsOnlineVoiceRoutingPolicy -OutVariable $VoiceRoutingPolicy.Identity -ErrorAction:SilentlyContinue).Identity
	if ($VPExists)
	{
		# TODO: Splat
		Set-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy.Identity -OnlinePstnUsages $VoiceRoutingPolicy.OnlinePstnUsages -Description $VoiceRoutingPolicy.Description
	}
	else
	{
		# TODO: Splat
		New-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy.Identity -OnlinePstnUsages $VoiceRoutingPolicy.OnlinePstnUsages -Description $VoiceRoutingPolicy.Description
	}
}

# Rebuild outbound translation rules from backup
Write-Host -Object 'Restoring outbound translation rules'

# $TranslationRules is not defined
foreach ($TranslationRule in $TranslationRules)
{
	$TRExists = (Get-CsTeamsTranslationRule -OutVariable $TranslationRule.Identity -ErrorAction:SilentlyContinue).Identity
	if ($TRExists)
	{
		# TODO: Splat
		Set-CsTeamsTranslationRule -Identity $TranslationRule.Identity -Pattern $TranslationRule.Pattern -Translation $TranslationRule.Translation -Description $TranslationRule.Description
	}
	else
	{
		# TODO: Splat
		New-CsTeamsTranslationRule -Identity $TranslationRule.Identity -Pattern $TranslationRule.Pattern -Translation $TranslationRule.Translation -Description $TranslationRule.Description
	}
}

# Re-add translation rules to PSTN gateways
Write-Host -Object 'Re-adding translation rules to PSTN gateways'

# $PSTNGateways is not defined
foreach ($PSTNGateway in $PSTNGateways)
{
	$GWExists = (Get-CsOnlinePSTNGateway -OutVariable $PSTNGateway.Identity -ErrorAction:SilentlyContinue | Select-Object -ExpandProperty Identity)
	
	if ($GWExists)
	{
		# TODO: Splat
		Set-CsOnlinePSTNGateway -Identity $PSTNGateway.Identity -OutbundTeamsNumberTranslationRules $PSTNGateway.OutbundTeamsNumberTranslationRules -OutboundPstnNumberTranslationRules $PSTNGateway.OutboundPstnNumberTranslationRules -InboundTeamsNumberTranslationRules $PSTNGateway.InboundTeamsNumberTranslationRules -InboundPstnNumberTranslationRules $PSTNGateway.InboundPstnNumberTranslationRules
	}
}

Write-Host -Object 'Finished!'
