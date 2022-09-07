# To Do
# Integrate into Teams Functions

<#
	.SYNOPSIS
		A script to automatically backup a Microsoft Teams Tenant configuration.

	.DESCRIPTION
		Automates the backup of Microsoft Teams.

	.PARAMETER OverrideAdminDomain
		OPTIONAL: The FQDN your Office365 tenant. Use if your admin account is not in the same domain as your tenant (ie. doesn't use a @tenantname.onmicrosoft.com address)

	.NOTES
		Based on Version 1.10 of Backup-TeamsEV
		Build: Feb 04, 2020

		Copyright © 2020  Ken Lasko
		klasko@ucdialplans.com
        https://www.ucdialplans.com

        Expanded to cover more elements
        David Eberhardt
        https://github.com/DEberhardt/
        https://davideberhardt.wordpress.com/


        14-MAY 2020

        The list of command is not dynamic, meaning addded commandlets post publishing date are not captured
#>

[CmdletBinding(ConfirmImpact = 'None')]
param
(
	[Parameter(ValueFromPipelineByPropertyName)]
	[string]
	$OverrideAdminDomain
)

$Filenames = '*.txt'

Try {
	Connect-MicrosoftTeams
}
Catch {
	Write-Warning 'Microsoft Teams PowerShell module not installed. Please install via Install-Module MicrosoftTeams, then run the script again.'
	Break
}

  # Tenant Configuration
  $null = (Get-CsOnlineDialInConferencingBridge -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingBridge.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineDialInConferencingLanguagesSupported -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingLanguagesSupported.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineDialInConferencingServiceNumber -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingServiceNumber.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineDialinConferencingTenantConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialinConferencingTenantConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineDialInConferencingTenantSettings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingTenantSettings.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineLisCivicAddress -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineLisCivicAddress.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineLisLocation -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineLisLocation.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsClientConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsClientConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsGuestCallingConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsGuestCallingConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsGuestMeetingConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsGuestMeetingConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsGuestMessagingConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsGuestMessagingConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsMeetingBroadcastConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMeetingBroadcastConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsMeetingConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMeetingConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsUpgradeConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsUpgradeConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTenant -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTenant.txt" -Force -Encoding utf8)
  $null = (Get-CsTenantFederationConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTenantFederationConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTenantNetworkConfiguration -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTenantNetworkConfiguration.txt" -Force -Encoding utf8)
  $null = (Get-CsTenantPublicProvider -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTenantPublicProvider.txt" -Force -Encoding utf8)

  # Tenant Policies (except voice)
  $null = (Get-CsTeamsUpgradePolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsUpgradePolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsAppPermissionPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsAppPermissionPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsAppSetupPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsAppSetupPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsCallParkPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsCallParkPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsChannelsPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsChannelsPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsEducationAssignmentsAppPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsEducationAssignmentsAppPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsFeedbackPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsFeedbackPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsMeetingBroadcastPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMeetingBroadcastPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsMeetingPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMeetingPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsMessagingPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMessagingPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsNotificationAndFeedsPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsNotificationAndFeedsPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsTargetingPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsTargetingPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsVerticalPackagePolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsVerticalPackagePolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsVideoInteropServicePolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsVideoInteropServicePolicy.txt" -Force -Encoding utf8)

  # Tenant Voice Configuration
  $null = (Get-CsTeamsTranslationRule -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsTranslationRule.txt" -Force -Encoding utf8)
  $null = (Get-CsTenantDialPlan -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTenantDialPlan.txt" -Force -Encoding utf8)

  $null = (Get-CsOnlinePSTNGateway -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlinePSTNGateway.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineVoiceRoute -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineVoiceRoute.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlinePstnUsage -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlinePstnUsage.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineVoiceRoutingPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineVoiceRoutingPolicy.txt" -Force -Encoding utf8)

  # Tenant Voice related Configuration and Policies
  $null = (Get-CsTeamsIPPhonePolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsIPPhonePolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsEmergencyCallingPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsEmergencyCallingPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsEmergencyCallRoutingPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsEmergencyCallRoutingPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineDialinConferencingPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialinConferencingPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineVoicemailPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineVoicemailPolicy.txt" -Force -Encoding utf8)
  $null = (Get-CsTeamsCallingPolicy -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsCallingPolicy.txt" -Force -Encoding utf8)

  # Tenant Telephone Numbers
  $null = (Get-CsOnlineTelephoneNumber -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineTelephoneNumber.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineTelephoneNumberAvailableCount -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineTelephoneNumberAvailableCount.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineTelephoneNumberInventoryTypes -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineTelephoneNumberInventoryTypes.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineTelephoneNumberReservationsInformation -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineTelephoneNumberReservationsInformation.txt" -Force -Encoding utf8)

  # Resource Accounts, Call Queues and Auto Attendants
  $null = (Get-CsOnlineApplicationInstance -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineApplicationInstance.txt" -Force -Encoding utf8)
  $null = (Get-CsCallQueue -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsCallQueue.txt" -Force -Encoding utf8)
  $null = (Get-CsAutoAttendant -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendant.txt" -Force -Encoding utf8)
  $null = (Get-CsAutoAttendantSupportedLanguage -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendantSupportedLanguage.txt" -Force -Encoding utf8)
  $null = (Get-CsAutoAttendantSupportedTimeZone -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendantSupportedTimeZone.txt" -Force -Encoding utf8)
  $null = (Get-CsAutoAttendantTenantInformation -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendantTenantInformation.txt" -Force -Encoding utf8)

  # User Configuration
  $null = (Get-CsOnlineUser -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineUser.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineVoiceUser -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineVoiceUser.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineDialInConferencingUser -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingUser.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineDialInConferencingUserInfo -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingUserInfo.txt" -Force -Encoding utf8)
  $null = (Get-CsOnlineDialInConferencingUserState -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingUserState.txt" -Force -Encoding utf8)



$TenantName = (Get-CsTenant).Displayname
$BackupFile = ('TeamsBackup_' + (Get-Date -Format yyyy-MM-dd) + $TenantName + '.zip')
$null = (Compress-Archive -Path $Filenames -DestinationPath $BackupFile -Force)
$null = (Remove-Item -Path $Filenames -Force -Confirm:$false)

Write-Host -Object ('Microsoft Teams configuration backed up to {0}' -f $BackupFile)
