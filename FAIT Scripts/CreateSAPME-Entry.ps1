<#
.SYNOPSIS

    Called during IVLS or IPU post imaging process;
    Uses a web request to write the service tag and batch string;
    (image + software version) of the IVLS PC to the SAP ME backend.

.INPUTs

    Takes 2 strings;
    ($NcCode) "NONE" or the error code to pass to SAP ME
    ($Product) for either "IPU" or "IVLS" 

.OUTPUTS

    Returns 0 on sucess
    1 on INVALID_PC or Web Request fail

.NOTES
    Version:        1.21
    Author:         R.Hayes
    Changed Date:   08/14/2020
    Creation Date:  11/04/2019
    Purpose/Change: 1.0 Initial script development
                    1.1 Added Window 7 Support
                    1.2 Changed from dev to production server
                    1.21 Cleaned up comments and console output
#>

[CmdletBinding()]
param (
    [string]$NcCode = $Args[0],
    [string]$Product = $Args[1]
)

function InvokeWebRequest ([string]$url)
{
    try
    {
        $webrequest = [System.Net.WebRequest]::Create($url)
        $response = $webrequest.GetResponse()
        $stream = $response.GetResponseStream()
        $sr = new-object System.IO.StreamReader($stream)
        $content = $sr.ReadToEnd();
        return $content
    }  
    catch { return "INVALID SN" }
    finally
    {
        if($null -ne $sr) { $sr.Close(); }
        if($null -ne $response) { $response.Close(); }
    }
}

$Model = (Get-WmiObject 'Win32_ComputerSystem').Model.ToUpper().Replace(' ',"")
#Changed to Cornish server for production 03-05-20 RHD
#$SapMePath = "http://denmark:8084/SAPME_WS/rest/PCImage/imagePC?sfc=" #Dev
$SapMePath = "http://cornish:8084/SAPME_WS/rest/PCImage/imagePC?sfc=" #Production
$ServiceTag = (Get-WmiObject Win32_BIOS).SerialNumber
#$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$ScriptPath = "c:\scripts"
$Software = &"$ScriptPath\GetSw-Version.ps1" -Product $Product
$Image = "$($Model)_$($Software)".ToUpper() 

if($NcCode.ToUpper()-eq "NONE"){
        
    $Request = InvokeWebRequest("$($SapMePath)$($ServiceTag)$("&image=")$($Image)")
    Write-Host "======================================================"
    Write-Host "Model: $Model"
    Write-Host "Service Tag: $ServiceTag"
    Write-Host "Image: $Image"
    Write-Host "Reponse: $Request"
    Write-Host "======================================================"

        if($Request -match '^\d+$') { #If this is a valid match the server will respond with a positive numeric
            
            Exit 0
        } 
        else{
        
            Exit 1
        }
    }

    #When NC code is not "NONE" - Ignore the return value from the request and just write the NC code
    else {

        $Request = InvokeWebRequest("$($SapMePath)$($ServiceTag)$("&image=")$($NcCode)")
    }

       