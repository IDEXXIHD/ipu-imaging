<#-
    .SYNOPSIS
    Name: Confif-IPU.ps1
    The purpose of this script is to configure Windows 10
    for use in creating a ProcyteDx IPU image.  
    
    .DESCRIPTION
    Based off of image requirments found at:
    https://wiki.idexx.com/pages/viewpage.action?pageId=280860598

    Requires: 
    Import-IdexxPowerPlan.ps1 
    IdexxPowerPlan.pow

    
    .NOTES
    Author: Rich Hayes
    Version: 1
    Updated: 2020-08-12 Initial Release
    Updated: 2020-07-07 Development
    
#>

Clear-Host 
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

if ((Get-MpComputerStatus -ErrorAction SilentlyContinue).IsTamperProtected){
    Write-Host "You must disable tamper protection before starting."
    Pause
    exit
    } 

#Stop Windows Update 
Start-Process -FilePath "$scriptPath\Software\wub\Wub.exe" -WorkingDirectory "$scriptPath\Software\wub" -ArgumentList '/d','/p' -Wait -Verb RunAs

#Get configuration and prompt user to start
$Feature = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
$WinVersion = (Get-WmiObject -Class Win32_OperatingSystem).Caption + " " + ((WMIC os get osarchitecture)[2]).Trim()
$SysmexVersion = Get-ChildItem -Path "$scriptPath\Software\Sysmex\" -Name

#Installation and Setup ===========================
# 1 . Windows 10 Professional x64  shall be installed with the current feature release.
if($WinVersion -ne "Microsoft Windows 10 Pro 64-bit"){
    Write-Error "Windows Version must be Microsoft Windows 10 Pro 64-bit"
}

$ImgVersion = Read-Host 'Please enter the image number' 
if (-not($ImgVersion -match "^\d+$")){
    Write-Error "IPU image version must be numeric."
}
$OemStr = "IPU$($Feature)v$($ImgVersion)"

Write-Host
Write-Host "OS Version      : $WinVersion"
Write-Host "Feature Release : $Feature"
Write-Host "Sysmex Version  : $SysmexVersion"
Write-Host "Image Version   : $OemStr"
Write-Host

$Continue = Read-Host 'Is the above configuration correct [y,n]?' 
if($Continue.ToUpper() -eq "N" ){
    Exit
}

#Group Policy -- Need to be done first to add the built-in administrator
Write-Host "Importing group policy..."
Copy-Item -Path "$scriptPath\Config\layout.xml" -Destination 'C:\' -Confirm:$false
powershell.exe -file "$scriptPath\Scripts\GroupPolicy-IPU.ps1" $scriptPath

if(-Not(Test-Path -Path 'HKLM:\SOFTWARE\IPU')){
    New-Item 'HKLM:\SOFTWARE\' -Name 'IPU'
    Set-ItemProperty -Path "HKLM:\SOFTWARE\IPU" -Name 'Version' -Value $SysmexVersion
}

#2. Windows shall be registered to the organization "IDEXX"
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'RegisteredOrganization' -Value 'IDEXX'
#3. Windows shall be registered to the owner "Procyte Dx"
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'RegisteredOwner' -Value 'ProCyte Dx'
#4. The image version shall be maintained in the registry key: HKLM:\System\Setup\OEMDuplicatorString 
New-ItemProperty 'HKLM:\System\Setup' -Name 'OEMDuplicatorString' -Value $OemStr -PropertyType MultiString -Force | Out-Null

#User Accounts ==================================== 
#1.	Windows shall have the administrator account, Sysmex
#2.	The Sysmex user account shall be part of the Administrators security group *by default via OOBE 
#3.	The Sysmex account password shall be: "c9.0" and be set to never expire
$password = ConvertTo-SecureString -String "c9.0" -AsPlainText -Force
Set-LocalUser -Name 'Sysmex' -Password $password
#4.	The Sysmex account shall be set to automatically log in.
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultUserName' -Value 'Sysmex'
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultPassword' -Value 'c9.0'
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name  'AutoAdminLogon' -Value '1'
#5 The built-in Adminstrator account shall be enabled * via GPO
#6 The built-in Adminstrator account shall have the password "c9.0" and be set to never expire/
Set-LocalUser -Name 'Administrator' -AccountNeverExpires:$true -Password $password

#Desktop ===========================================
#The Windows control panel appearance shall be configured to view by large Icons.
If (-Not (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel')) {
    New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ControlPanel' -Force  | Out-Null
}
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel' -Type DWord -Name 'StartupPage' -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel' -Type DWord -Name 'AllItemsIconView' -Value 2
#The Windows folder options shall be configured to show file extensions.
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value '0'
#The desktop background and logon screen shall be set to solid blue color (RGB 58,110,165).
Set-ItemProperty 'HKCU:\Control Panel\Colors' -Name 'Background' -Value '58 110 165'
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name 'Wallpaper' -Value ''
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name 'DisableLogonBackgroundImage' -Type DWord  -Value 1
#Automatically pick accent color shall be set to de-selected.
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name 'AutoColorization' -Value 0
#Transparency effects shall be set to off.
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0
#The taskbar shall be set to Autohide
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarSizeMove' -Value 0
#The taskbar shall be set to Locked
$settings = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3').Settings
$settings[8] = 3
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3' -Name 'Settings' -Value $settings
#The taskbar shalll show an icon for search
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 1
#The task view button shall be set to hidden.
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0
#Windows Screen Saver shall be disabled.
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name "ScreenSaveActive" -Value 0
#Lock screens shall be set as 'disabled'
If (-Not (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -Name 'Personalization' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name 'NoLockScreen' -Type DWord -Value 1
#File Explorer shall open to 'This PC'
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Type DWord -Name 'LaunchTo' -Value '1'
#Windows Performance Options shall be set to "Adjust for Best Performance"
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -name 'VisualFXSetting' -value 2
#Desktop shall contain (only) the icons; This PC, Recycle Bin, <IPU Software Folder> , IDChanger.exe
taskkill.exe /f /im OneDrive.exe
C:\Windows\SysWOW64\OneDriveSetup.exe /uninstall
&"$scriptPath\Scripts\ShowDesktopIcons.ps1"

#The File Explorer icon shall be the only pinned app on the taskbar.
$appname = "Microsoft Edge"
((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() `
     | Where-Object{$_.Name -eq $appname}).Verbs() `
     | Where-Object{$_.Name.replace('&','') -match 'Unpin from taskbar'} `
     | Where-Object{$_.DoIt()}

#Show me the Windows Welcome Experience after updates and occassionaly when I sign in - disabled
Set-ItemProperty "hkcu:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Type Dword -Name 'SubscribedContent-310093Enabled' -Value 0

#Network Settings and Adapters ==========================
& "$scriptPath\Scripts\Set-IpuAdapters.ps1"
#3. All new Networks Profiles shall be automatically configured as “Public.” * GPO
#4. The Network location wizard shall be disabled.
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Network\NetworkLocationWizard' -Name 'HideWizard' -Value '1'

#Printers
#1.	Windows pre-installed printers shall be removed.
Get-Printer | Remove-Printer

#Power Plan
&"$scriptPath\PowerPlan\Import-IdexxPowerPlan.ps1"

#Security
Set-Service LanmanServer -StartupType Disabled

Write-Host "Configuring Windows Firewall....."
& cmd.exe /c "$scriptPath\Scripts\winhard.bat"
if($LASTEXITCODE -ne 0){
    Write-Error "winhard.bat failed."
}

#System
#1.	The option to automatically restart in the event of a system failure shall be enabled.
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name 'AutoReboot' -Value 1
#2.	Scheduled HDD defrag task shall be removed.
If ((Get-ScheduledTask -TaskName 'ScheduledDefrag').State -eq 'Ready'){
    Disable-ScheduledTask -TaskName 'ScheduledDefrag' -TaskPath '\Microsoft\Windows\Defrag'
}
#3.	The Time Zone shall be: Eastern Standard Time (GMT -5) with DST off.
tzutil /s "Eastern Standard Time_dstoff"
#5.	The Windows Time Service shall be removed.
Stop-Service -name W32Time
Set-Service w32time -StartupType Disabled

#6.	The Input standard (keyboard) shall be: English (U.S.) -- Default.

# Windows Applications ========================================
Write-Host "Removing built-in Windows Apps..."
&"$scriptPath\Scripts\Remove-IPUApps.ps1"

#Reset Explorer.exe
$explorer = Get-Process Explorer
$explorer.Kill()
$explorer.WaitForExit()

#Create folders and copy the install for IPU
Write-Host "Copying Sysmex files to the desktop..."
$Source = "$scriptPath\Software\Sysmex"
$Desktop = "C:\users\Sysmex\Desktop"
& "$scriptPath\Scripts\Copy-ItemWithProgress" $Source $Desktop '/V /E'
$source = "$scriptPath\Software\ID Changer.exe"
$null = Copy-Item $Source $Desktop -Confirm:$false
$CfgScripts = 'C:\Scripts'
if (Test-Path -Path $CfgScripts){
    Remove-Item -Path $CfgScripts -Recurse
}
New-Item -Path 'c:\Scripts' -ItemType Directory -Confirm:$false
Copy-Item -Path "$scriptPath\Config\Scripts\*" -Destination 'C:\Scripts' -Confirm:$false -Recurse

#Store this PC name in the registry
Set-ItemProperty "HKLM:\SOFTWARE\IPU" -Name "TECHPC" -Value $env:COMPUTERNAME

#Next boot run post configuration tasks
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "PostConfig" -Value "$scriptPath\Scripts\PostConfig.bat"

$Continue = Read-Host 'Configuration Complete. Are you ready to reboot [y,n]?' 
if($Continue.ToUpper() -eq "N" ){
    Exit
}

Restart-Computer