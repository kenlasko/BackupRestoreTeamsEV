# BackupRestoreTeamsEV

PowerShell scripts that allow you to easily backup and restore your Microsoft Teams Enterprise Voice configuration

## Getting Started

Download the scripts onto your local Windows machine where you normally connect to your MS Teams tenant.

### Prerequisites

Requires that you have the Office 365 PowerShell module installed, and that you have a Microsoft Teams Enterprise Voice configuration that you are interested in backing up/restoring. You may have to set your execution policy to unrestricted to run this script: 

Set-ExecutionPolicy Unrestricted


## Running a backup

Simply run **.\Backup-TeamsEV.ps1** from a PowerShell prompt. If you are not already connected to your Teams tenant, the script will prompt for authentication. If your admin account is not a @tenantname.onmicrosoft.com account, then you should use the **-OverrideAdminDomain** switch.

## Restoring a backup

Run **.\Restore-TeamsEV.ps1** with the path to the backup file to restore. If you are not already connected to your Teams tenant, the script will prompt for authentication. If your admin account is not a @tenantname.onmicrosoft.com account, then you should use the **-OverrideAdminDomain** switch. 

By default, the script will clean out any existing config, including dialplans, voice routes, voice routing policies, PSTN usages and translation rules. You can override this behaviour by using the **-KeepExisting** switch.

## Authors

**Ken Lasko** 
* https://github.com/kenlasko
* https://ucdialplans.com
* https://ucken.blogspot.com
* https://twitter.com/kenlasko
* https://www.linkedin.com/in/kenlasko71/
