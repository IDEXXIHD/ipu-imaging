 <#-
    .SYNOPSIS
    Name:GroupPolicy-IPU.ps1
    The purpose of this script is import group policy
    Requires: LPGO folder containing LPGO.exe and gpo backup

    .NOTES
    Version: 1.0
    Creation Date: 2020-04-24
    Author: Rich Hayes
    Change (1.0):   Inital release
   
#>

param (
    [string]$scriptPath
)

 # Group Policy & Policy Definition Import.  
 #Give rights and copy templates
 #takeown /F C:\Windows\PolicyDefinitions\* /R /A
 #icacls C:\Windows\PolicyDefinitions\* /T /grant administrators:F
 Copy-Item -Path "$scriptPath\LGPO\PolicyDefinitions\*" -Destination "C:\Windows\PolicyDefinitions\" -Force 
 Copy-Item -Path "$scriptPath\LGPO\PolicyDefinitions\en-US\*" -Destination "C:\Windows\PolicyDefinitions\en-US" -Force 
 #Reset Ownership
 #icacls "C:\Windows\PolicyDefinitions\*" /setowner "NT Service\TrustedInstaller"
#Apply local GPO
&"$scriptPath\LGPO\LGPO.exe" /g "$scriptPath\LGPO\GPO" 
 gpupdate /Force 