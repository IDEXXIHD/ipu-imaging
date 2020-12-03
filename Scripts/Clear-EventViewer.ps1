<#
    .SYNOPSIS
    Name:Config-VSSImage.ps1
    The purpose of this script is to clear all event logs.
    
    .NOTES
    Release Date: 2019-06-27
    Author: Rich Hayes
#>

Clear-EventLog -LogName Application
Clear-EventLog -LogName Security
Clear-EventLog -LogName System