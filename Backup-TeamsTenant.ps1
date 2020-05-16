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

If ((Get-PSSession | Where-Object -FilterScript {
         $_.ComputerName -like '*.online.lync.com'
}).State -eq 'Opened') {
	Write-Host -Object 'Using existing session credentials'
} 
Else {
	Write-Host -Object 'Logging into Office 365...'
   
	If ($OverrideAdminDomain) {
		$O365Session = (New-CsOnlineSession -OverrideAdminDomain $OverrideAdminDomain)
	}
	Else {
		$O365Session = (New-CsOnlineSession)
	}
	$null = (Import-PSSession -Session $O365Session -AllowClobber)
}

Try {
    # Tenant Configuration
    $null = (Get-CsOnlineDialInConferencingBridge | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingBridge.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialInConferencingLanguagesSupported | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingLanguagesSupported.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialInConferencingServiceNumber | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingServiceNumber.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialinConferencingTenantConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialinConferencingTenantConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialInConferencingTenantSettings | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingTenantSettings.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDirectoryTenant | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDirectoryTenant.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDirectoryTenantNumberCities | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDirectoryTenantNumberCities.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineLisCivicAddress | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineLisCivicAddress.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineLisLocation | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineLisLocation.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsClientConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsClientConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsGuestCallingConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsGuestCallingConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsGuestMeetingConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsGuestMeetingConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsGuestMessagingConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsGuestMessagingConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsMeetingBroadcastConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMeetingBroadcastConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsMigrationConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMigrationConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsMeetingConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMeetingConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsUpgradeConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsUpgradeConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTenant | ConvertTo-Json | Out-File -FilePath "Get-CsTenant.txt" -Force -Encoding utf8)
    $null = (Get-CsTenantFederationConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTenantFederationConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTenantHybridConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTenantHybridConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTenantLicensingConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTenantLicensingConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTenantMigrationConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTenantMigrationConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTenantNetworkConfiguration | ConvertTo-Json | Out-File -FilePath "Get-CsTenantNetworkConfiguration.txt" -Force -Encoding utf8)
    $null = (Get-CsTenantPublicProvider | ConvertTo-Json | Out-File -FilePath "Get-CsTenantPublicProvider.txt" -Force -Encoding utf8)
    
    # Tenant Policies (except voice)
    $null = (Get-CsTeamsUpgradePolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsUpgradePolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsAppPermissionPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsAppPermissionPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsAppSetupPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsAppSetupPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsCallParkPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsCallParkPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsChannelsPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsChannelsPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsComplianceRecordingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsComplianceRecordingPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsEducationAssignmentsAppPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsEducationAssignmentsAppPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsFeedbackPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsFeedbackPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsInteropPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsInteropPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsMeetingBroadcastPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMeetingBroadcastPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsMeetingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMeetingPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsMessagingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsMessagingPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsNotificationAndFeedsPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsNotificationAndFeedsPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsTargetingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsTargetingPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsVerticalPackagePolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsVerticalPackagePolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsVideoInteropServicePolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsVideoInteropServicePolicy.txt" -Force -Encoding utf8)

    # Tenant Voice Configuration
	$null = (Get-CsTeamsTranslationRule | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsTranslationRule.txt" -Force -Encoding utf8)
    $null = (Get-CsTenantDialPlan | ConvertTo-Json | Out-File -FilePath "Get-CsTenantDialPlan.txt" -Force -Encoding utf8)

    $null = (Get-CsOnlinePSTNGateway | ConvertTo-Json | Out-File -FilePath "Get-CsOnlinePSTNGateway.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineVoiceRoute | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineVoiceRoute.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlinePstnUsage | ConvertTo-Json | Out-File -FilePath "Get-CsOnlinePstnUsage.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineVoiceRoutingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineVoiceRoutingPolicy.txt" -Force -Encoding utf8)

    # Tenant Voice related Configuration and Policies
    $null = (Get-CsTeamsIPPhonePolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsIPPhonePolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsEmergencyCallingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsEmergencyCallingPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsEmergencyCallRoutingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsEmergencyCallRoutingPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialinConferencingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialinConferencingPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialOutPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialOutPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineVoicemailPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineVoicemailPolicy.txt" -Force -Encoding utf8)
    $null = (Get-CsTeamsCallingPolicy | ConvertTo-Json | Out-File -FilePath "Get-CsTeamsCallingPolicy.txt" -Force -Encoding utf8)

    # Tenant Telephone Numbers
    $null = (Get-CsOnlineNumberPortInOrder | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineNumberPortInOrder.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineNumberPortOutOrderPin | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineNumberPortOutOrderPin.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineTelephoneNumber | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineTelephoneNumber.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineTelephoneNumberAvailableCount | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineTelephoneNumberAvailableCount.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineTelephoneNumberInventoryTypes | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineTelephoneNumberInventoryTypes.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineTelephoneNumberReservationsInformation | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineTelephoneNumberReservationsInformation.txt" -Force -Encoding utf8)

    # Resource Accounts, Call Queues and Auto Attendants
    $null = (Get-CsOnlineApplicationInstance | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineApplicationInstance.txt" -Force -Encoding utf8)
	$null = (Get-CsOnlineApplicationInstanceAssociation | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineApplicationInstanceAssociation.txt" -Force -Encoding utf8)
	$null = (Get-CsCallQueue | ConvertTo-Json | Out-File -FilePath "Get-CsCallQueue.txt" -Force -Encoding utf8)
	$null = (Get-CsAutoAttendant | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendant.txt" -Force -Encoding utf8)
	$null = (Get-CsAutoAttendantHolidays | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendantHolidays.txt" -Force -Encoding utf8)
	$null = (Get-CsAutoAttendantSupportedLanguage | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendantSupportedLanguage.txt" -Force -Encoding utf8)
	$null = (Get-CsAutoAttendantSupportedTimeZone | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendantSupportedTimeZone.txt" -Force -Encoding utf8)
	$null = (Get-CsAutoAttendantTenantInformation | ConvertTo-Json | Out-File -FilePath "Get-CsAutoAttendantTenantInformation.txt" -Force -Encoding utf8)
	$null = (Get-CsOrganizationalAutoAttendant | ConvertTo-Json | Out-File -FilePath "Get-CsOrganizationalAutoAttendant.txt" -Force -Encoding utf8)
	$null = (Get-CsOrganizationalAutoAttendantHolidays | ConvertTo-Json | Out-File -FilePath "Get-CsOrganizationalAutoAttendantHolidays.txt" -Force -Encoding utf8)
	$null = (Get-CsOrganizationalAutoAttendantSupportedLanguage | ConvertTo-Json | Out-File -FilePath "Get-CsOrganizationalAutoAttendantSupportedLanguage.txt" -Force -Encoding utf8)
	$null = (Get-CsOrganizationalAutoAttendantSupportedTimeZone | ConvertTo-Json | Out-File -FilePath "Get-CsOrganizationalAutoAttendantSupportedTimeZone.txt" -Force -Encoding utf8)
	$null = (Get-CsOrganizationalAutoAttendantTenantInformation | ConvertTo-Json | Out-File -FilePath "Get-CsOrganizationalAutoAttendantTenantInformation.txt" -Force -Encoding utf8)

    # User Configuration
    $null = (Get-CsOnlineUser | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineUser.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineVoiceUser | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineVoiceUser.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialInConferencingUser | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingUser.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialInConferencingUserInfo | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingUserInfo.txt" -Force -Encoding utf8)
    $null = (Get-CsOnlineDialInConferencingUserState | ConvertTo-Json | Out-File -FilePath "Get-CsOnlineDialInConferencingUserState.txt" -Force -Encoding utf8)
    

} 
Catch {
	Write-Error -Message 'There was an error backing up the MS Teams configuration.'
	Exit
}

$TenantName = (Get-CsTenant).Displayname
$BackupFile = ('TeamsBackup_' + (Get-Date -Format yyyy-MM-dd) + $TenantName + '.zip')
$null = (Compress-Archive -Path $Filenames -DestinationPath $BackupFile -Force)
$null = (Remove-Item -Path $Filenames -Force -Confirm:$false)

Write-Host -Object ('Microsoft Teams configuration backed up to {0}' -f $BackupFile)
