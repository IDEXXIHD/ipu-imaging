<#-
    .SYNOPSIS
    Name:Import-IDEXXPower.ps1
    The purpose of this script is to import a custom Idexx power plan. 
    
    .NOTES
    Version: 1.1
    Creation Date: 2019-06-27
    Updated:       2019-08-29
    Author: Rich Hayes
    Change (1.0):   Inital release
    Change (1.1):   Add additional line to clean up console output.
#>

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path
$idexx = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName='Idexx'"

if($null -eq $idexx ){
powercfg -restoredefaultschemes
powercfg -import "$scriptRoot\Idexx-powerplan.pow" 
$plan = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName='Idexx'"
$guid= $plan.InstanceID.Split("{}")[1]
powercfg /SetActive $guid
}
else{
Write-Host 'Idexx Power plan has already been installed!'
}

Write-Host