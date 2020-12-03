<#-
    .SYNOPSIS
    Name: Confif-IPU.ps1
    The purpose of this script is to configure a ProCyte Dx IPU  
    
    .DESCRIPTION
    Based off of image requirments found at: TDB
    Requires: 
    Import-IdexxPowerPlan.ps1 
    IdexxPowerPlan.pow

    .NOTES
    Version: 1.0
    Creation Date: 2020-05-05
    Author: Rich Hayes
    Change (1.0):   Inital release
   
#>

#Validate we have successfully installed the version on the desktop
$SysmexVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\IPU" -Name 'Version'
Write-Host "Starting the Sysmex installer for version $SysmexVersion..."
$Desktop = "C:\Users\Sysmex\Desktop"
Start-Process -FilePath "$Desktop\$SysmexVersion\Setup.exe" -WorkingDirectory "$Desktop\$SysmexVersion" -Wait -Verb RunAs 
$VPath ='HKLM:\SOFTWARE\WOW6432Node\Sysmex\ShxInstaller'
$V1 = (Get-ItemProperty -Path $VPath -Name 'Install_1_Version').Install_1_Version
$V2 = (Get-ItemProperty -Path $VPath -Name 'Install_1_EvVersion').Install_1_EvVersion
$InstalledVersion = "00-$V1$V2"
if($InstalledVersion -ne $SysmexVersion){
    Write-Error 'Sysmex appears to have failed installing or is wrong verion.'
}else{
    Write-Host "Sysmex software version $InstalledVersion installed successfully."
}

#Set the 'XS' account created by the installer to password never expire
Set-LocalUser -Name 'XS' -PasswordNeverExpires:$true

#Create the addserver.sql used for post-installion
Write-Host "Creating addserver.sql..."
$AddSvrPath = 'C:\Scripts\addserver.sql'
if (Test-Path -Path $AddSvrPath){
    Remove-Item -Path $AddSvrPath -Confirm:$false
}
$AddSvrDate = Get-Date -Format "MM/dd/yyyy HH:mm"
Set-Content -Path $AddSvrPath -Value "-- Created by Postconfig.ps1 on $AddSvrDate"
Add-Content -Path $AddSvrPath -Value 'SELECT @@servername'
Add-Content -Path $AddSvrPath -Value 'GO'
Add-Content -Path $AddSvrPath -Value '-- Drop old server name.'
Add-Content -Path $AddSvrPath -Value "sp_dropserver '$env:COMPUTERNAME\SQLEXPRESS'"
Add-Content -Path $AddSvrPath -Value 'GO'
Add-Content -Path $AddSvrPath -Value '-- Add new server name.'
Add-Content -Path $AddSvrPath -Value "sp_addserver `'`$(renameComputer)\SQLEXPRESS`',local"
Add-Content -Path $AddSvrPath -Value 'GO'

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
& "$scriptPath\Finalize-IPU.ps1"
Pause