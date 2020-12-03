<#
    .SYNOPSIS
    Name:IVLS-Win10Cleanup.ps1
        
    .NOTES
    Release Date: 2020-05-07
    Author: Rich Hayes
#>

$Continue = Read-Host 'Are you ready to finalize the PC [y,n]?' 
if($Continue.ToUpper() -eq "N" ){
    Exit
}

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$ParentPath = (Get-Item $scriptPath).Parent.FullName
Write-Host "Finalizing before shut down..."
#Remove the startup files and copy in the PostImage batch file
$StartUpPath = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp'
remove-item -Path "$StartUpPath\*" -Confirm:$false
#Copy-Item -Path "$ParentPath\Config\Startup\PostImage.bat" -Destination $StartUpPath -Confirm:$false
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'PostInstall' -Value 'C:\Scripts\Restart-IPU.bat'

#Stop services that may have resources tied up
Stop-Service wuauserv
Stop-Service BITS
Stop-Service msiserver
Stop-Service CryptSvc
Stop-Service UsoSvc

#clean up temp files
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\ProgramData\Microsoft\Windows Defender\Scans\History\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Downloaded Program Files\*" -Recurse -Force -ErrorAction SilentlyContinue

#Clear IE Favorites, Feeds and History
RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 255
[Environment]::GetFolderPath('Favorites','None') | Remove-Item -Recurse -Force

#Empty Recycle Bin
Clear-RecycleBin -Force

# Windows Backup and Restore Disabled.
Disable-ComputerRestore -Drive "c:\"
vssadmin.exe delete shadows /all /quiet

#Clean-up the event logs
&"$scriptPath/Clear-EventViewer.ps1"

$Continue = Read-Host 'Shutdown the PC [y,n]?' 
if($Continue.ToUpper() -eq "N" ){
    Exit
}
Stop-Computer