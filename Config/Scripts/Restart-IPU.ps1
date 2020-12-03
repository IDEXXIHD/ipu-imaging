<#-
    .SYNOPSIS
    Name:Restart-IPU.ps1
    The purpose of this script is Rename and Restart the IPU after imaging.    
    
    .NOTES
    Version: 1.0
    Creation Date: 2020-08-04
    Author: Rich Hayes
#>

# Rename the PC "IPU" + SERIALNUMBER
$Computer = Get-WmiObject Win32_ComputerSystem
$IpuName = ('IPU' +  (Get-WmiObject win32_bios | Select-Object SerialNumber).SerialNumber)
$Computer.Rename($IpuName)

#Reboot and run Postinstall scripts
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'PostInstall' -Value 'C:\Scripts\PostInstall-IPU.bat'
Restart-Computer -Force