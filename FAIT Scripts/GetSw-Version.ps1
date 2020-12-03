<#
.SYNOPSIS

    Called during IVLS or IPU post imaging process;
    Creates a string to be used with CreateSAPME-Entry.ps1

.INPUTs

    Takes a string ($Product) for either "IPU" or "IVLS (not case sensitive)

.OUTPUTs

    Returns; 
    String for use in the "Image" field of the;
    SAP ME "PC Imaging Admin QA Database"

.NOTES
    Version:        1.21
    Author:         R.Hayes
    Last Updated:   06/02/2020
    Creation Date:  09/30/2019
    Purpose/Change: 1.0 Initial script development
                    1.01 Changed IPU sw ver. parsing method
                    1.2 Find the last installed verion for re-installed sw.
                    1.21 Removed redundant console output
#>

[CmdletBinding()]
param (
    [string]$Product = $Args[0] 
)


if($Product.ToUpper() -eq "IVLS")

{
    $OS = (Get-WmiObject -class Win32_OperatingSystem).caption
    if ($OS -like '*Windows 10*')
    {
        $SwPath = 'Software\WOW6432Node'
    }
    else
    {
        $SwPath = 'Software' 
    }
    $SwVersion = (Get-ItemProperty "hklm:\$SwPath\IDEXX Laboratories, Inc.\VetLab Station\").CurrentVersion
    $Oem = (Get-ItemProperty HKLM:\System\setup).OEMDuplicatorString.Replace('IVLS','').Replace(' ','')
    return "$($Oem)_$($SwVersion)" 
}

elseif ($Product.ToUpper() -eq "IPU") {
    $Oem = (Get-ItemProperty HKLM:\SYSTEM\Setup).OEMDuplicatorString[0]
    #Code revised below to find the latest install version - RDH 06 02 2020
    #Change the parsing method for IPU Image/Software versions - 3-05-20 RDH
    #$SwVersion = $Oem.Substring(4,8) -- Strings aren't consistant in all images. Refactor!
  
    # Use the Sysmex installer keys instead.
    # Each OS has different registry locations.
    $OS = (Get-WmiObject -class Win32_OperatingSystem).caption

    if ($OS -like '*Windows 10*')
    {
        #Same path for both properties - RDH 06 02 2020
        $RegPath ='HKLM:\SOFTWARE\WOW6432Node\Sysmex\ShxInstaller'
    }
    else
    {
        #Same path for both properties - RDH 06 02 2020
        $RegPath ='HKLM:\SOFTWARE\Sysmex\ShxInstaller'
    }
    
    #Get the property list from the sysmex path - RDH 06 02 2020
    $Properties = get-item -Path $RegPath | Select-Object -ExpandProperty Property
    #Sort Decending to put the latest install version at the top
    $VerProperty = ($Properties | Where-Object {$_ -like "*_Vers*"} | Sort-Object -Descending)
    $EvVerProperty = $Properties | Where-Object {$_ -like "*_EvVers*"} | Sort-Object -Descending
    #The top of the filtered list will contain the property path of the latest Sysmex software version
    $Version= $VerProperty[0]
    $EvVersion= $EvVerProperty[0]
    $V1 = (Get-ItemProperty -Path $RegPath -Name $Version).$Version
    $V2 = (Get-ItemProperty -Path $RegPath -Name $EvVersion).$EvVersion
    $SwVersion = "00-$V1$V2"
    #Parse out the image version info
    $VPos=$Oem.ToUpper().LastIndexOfAny('V')
    $ImgVer=$Oem.Remove(0,$VPos)
    #(e.g IPUV5_00-34_57)
    $VersionString = "IPU$($ImgVer)_$($SwVersion)".ToUpper()
    return $VersionString
    }
