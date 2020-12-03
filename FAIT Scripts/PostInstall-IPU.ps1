<#-
    .SYNOPSIS
    Name:Post-Install.ps1
    The purpose of this script is to configure an IPU after imaging and verify the configuration.    
    Includes installation of Smart Service.
    
    .DESCRIPTION
    Depends on: 
    AgentSmartServiceSetup_[VERSION].exe
    Check-Activated.ps1
    CreateSAPME-Entry.ps1
    GetSw-Version.ps1
    Debug.cfg (If running in test mode)

    .NOTES

    Author: Rich Hayes    
    Version: 1
    Updated:
            2020-09-01  Release
			Cleaned up console output
            2020-08-12  Added SS install log check
            2020-08-11  Script Clean-up
            2020-08-10  Add SAPME 
                        Time sync and un-register service   
            2020-08-04  Initial Development
#>
Function WriteLog{
    Param (
        $LogText,
        $Pass = $true
        )
        
        if($Pass){
            $Color = "White"
            }else{
            $Color = "Red"
            }

        $Timestamp = Get-Date -Format "yyyy.dd.MM HH:mm:ss"
        Add-Content -Path $LogFile -Value "[$Timestamp] $LogText"
        Write-Host $LogText -ForegroundColor $Color
}

#Get the contents of the debug.cfg file, if it exists.
#Skip the SAP ME check if in config
$DebugPath = "C:\Scripts\Debug.cfg"
if(Test-Path -Path $DebugPath){
    $Debug = (Get-Content -Path $DebugPath).Split('=')
    if($Debug[0] -eq 'skipsapmecheck'){
        $SkipSapMeCheck = $true
        }else{
        $SkipSapMeCheck = $false
        }
    }else{
    $SkipSapMeCheck = $false
}

Add-Type -AssemblyName PresentationFramework
$LogFile = 'c:\IPUImage.log'
Set-Content -Path $LogFile -Value "Starting IPU Post Imaging Production Log ***"
WriteLog "Production Mode: $(-not $SkipSapMeCheck)"

#Get PC Hardware properties
$OemSt = (Get-ItemProperty -Path "HKLM:\SYSTEM\Setup" -Name "OEMDuplicatorString").OEMDuplicatorString[0]
$Cpu = (Get-WmiObject -Class win32_processor).Name
$Bios = (Get-WmiObject -Class win32_bios).SMBIOSBIOSVersion
$Model = (Get-WmiObject -Class win32_ComputerSystem).Model
$Manuf = (Get-WmiObject -Class win32_ComputerSystem).Manufacturer
WriteLog "IPU Image Version: $OemSt"
WriteLog "Model: $Model"
WriteLog "Manufacturer: $Manuf"
WriteLog "PC BIOS Version: $Bios"
WriteLog "PC CPU: $CPU"

#Sync with time service 2020-08-10 
#Stop and un-register the service after time is synced  
$TimeService = Get-Service W32Time
$TimeService | Set-Service -StartupType Manual
$TimeService | Start-Service
WriteLog "Syncing time."
w32tm.exe /resync /force | Out-Null
$UnregTime = w32tm.exe /unregister
WriteLog $UnregTime

#Install Smart Service
$ScriptsDir = Get-ChildItem -Path 'C:\Scripts'
$SmartSvcExe = ($ScriptsDir | Where-Object {$_.Name -like 'AgentSmartService*'}).Name
$SmartSvcVer = $SmartSvcExe -replace 'AgentSmartServiceSetup_','' -replace '.exe',''
Copy-Item -Path "c:\Scripts\$SmartSvcExe" -Destination "c:\temp"
WriteLog "Unpacking $SmartSvcExe."
Start-Process -FilePath "c:\temp\$SmartSvcExe" -ArgumentList '-y' -Wait 
$SmartSvcBat = $SmartSvcExe -replace 'exe','bat'
Writelog "Running $SmartSvcBat."
cmd.exe /c "c:\temp\$SmartSvcBat -s -tIPU -ePROD"

#Check Windows activation status 
$WinActivationPath = 'C:\Scripts\Check-Activated.ps1'
if(Test-Path -Path $WinActivationPath){
&'C:\Scripts\Check-Activated.ps1'
Writelog "Got Activation status."
$IsActivated = ($LASTEXITCODE -eq 0)
}else{
$IsActivated = $false
Writelog "Check-Activated.ps1 was not found!" -Pass $false
} 
Writelog "Activation status: $IsActivated" -Pass $IsActivated

#Verify completion of smart service install
Writelog "Checking Smart Service."
$SsvcInstalled = $false
$XmlPath = 'C:\Program Files\Agent SmartService\config'
$SmartLog = 'C:\Program Files\Agent SmartService\logs\AgentSmartServiceInstall.log'

Do
{ 
    #Check for the install log, if present, check that the xml was downloaded
    Start-Sleep -Seconds 1
    $Timeout +=1
    if($Timeout -ge 10){break}
    if(Test-Path -Path $SmartLog){
        $XmlQuery = Get-ChildItem -Path $XmlPath | Where-Object {$_.Name -eq 'AgentServiceConfigurator.xml'}
        $SsvcInstalled = ($null -ne $XmlQuery.Name)
        }else{
        $SsvcInstalled = $false
        }
} Until ($SsvcInstalled -eq $true)

WriteLog "Smart Service Install Status:$SsvcInstalled" -Pass $SsvcInstalled

#Execute SQL Script to remove old server name and add new server name based on new computer name.
$SqlCmd = 'sqlcmd -S "(local)\SQLEXPRESS" -i c:\scripts\addserver.sql -o c:\scripts\addserver.log -v renameComputer=' + $env:COMPUTERNAME
cmd.exe /c $SqlCmd
WriteLog "Updated SQL Server Name"

#Set BCD parameters
cmd.exe /c 'C:\Scripts\setBCD.bat' | Out-Null
WriteLog "Updated BCD Parameters"

#Copy startup scripts
cmd.exe /c 'C:\Scripts\AfterLogin.bat' |Out-Null
WriteLog "Copied Startup Scripts"

#Check if SAP ME database has matching data for this PC 
if(-not $SkipSapMeCheck){
    Writelog "Checking SAP ME Database."
    $SapMeScriptPath = "C:\Scripts\CreateSAPME-Entry.ps1"
    if(Test-Path -Path $SapMeScriptPath){
    &"C:\Scripts\CreateSAPME-Entry.ps1" -NcCode "NONE" -Product "IPU"
    $SapMeValid = ($LASTEXITCODE -eq 0)
    }else{
    $SapMeValid = $false
    Writelog "CreateSAPME-Entry.ps1 was not found!" -Pass $false
    } 
    Writelog "PC Matches SAPME data: $SapMeValid" -Pass $SapMeValid
}else{
    Writelog "Test Mode: Skipping SAPME verification. "
    $SapMeValid = $true
}


if($SsvcInstalled -and $IsActivated -and $SapMeValid){

    if($SkipSapMeCheck){
            $Title = "*** Test Image: Do not ship this PC! ***"
        }Else{
            $Title = "Imaging Complete!"
        }

    WriteLog ("IPU Post Imaging tasks completed successfully.")
    $Msg = "Process Completed Successfuly!`r`n`r`n"
    $Msg += "IPU Image:`t$OemSt`r`nManufacturer:`t$Manuf`r`nPC Model:`t$Model`r`nSmart Service:`t$SmartSvcVer`r`n`r`n"
    $Msg += "Click OK to shut down."
    [System.Windows.MessageBox]::Show($Msg, $Title)
    Stop-Computer
    }else{
    #Write Error codes to SAPME if in production
    if(-not $SkipSapMeCheck){
        if(-not $SsvcInstalled){
            &"C:\Scripts\CreateSAPME-Entry.ps1" -NcCode "SmartService:Fail" -Product "IPU"
        }
        if(-not $IsActivated){
            &"C:\Scripts\CreateSAPME-Entry.ps1" -NcCode "Activation:Fail" -Product "IPU"
        }
    }
    WriteLog ("****************************************") -Pass $false
    WriteLog ("*     IPU Post Imaging FAILED!         *") -Pass $false
    WriteLog ("*       DO NOT SHIP THIS PC            *") -Pass $false
    WriteLog ("****************************************") -Pass $false

    }