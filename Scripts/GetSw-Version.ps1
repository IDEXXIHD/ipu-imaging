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
    Version:        1.1
    Author:         R.Hayes
    Last Updated:   03/05/2020
    Creation Date:  09/30/2019
    Purpose/Change: 1.0 Initial script development
                    1.01 Changed IPU sw ver. parsing method
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
    #Change the parsing method for IPU Image/Software versions - 3-05-20 RDH
    #$SwVersion = $Oem.Substring(4,8) -- Strings aren't consistant in all images. Refactor!
    # Use the Sysmex installer keys instead.
    # Each OS has different registry locations.
    $OS = (Get-WmiObject -class Win32_OperatingSystem).caption

    if ($OS -like '*Windows 10*')
    {
        $V1Path ='HKLM:\SOFTWARE\WOW6432Node\Sysmex\ShxInstaller'
        $V2Path ='HKLM:\SOFTWARE\WOW6432Node\Sysmex\ShxInstaller'
    }
    else
    {
        $V1Path ='HKLM:\SOFTWARE\Sysmex\ShxInstaller'
        $V2Path ='HKLM:\SOFTWARE\Sysmex\ShxInstaller'
    }
    #Parse out the Sysmex version info
    $V1 = (Get-ItemProperty -Path $V1Path -Name 'Install_1_Version').Install_1_Version
    $V2 = (Get-ItemProperty -Path $V2Path -Name 'Install_1_EvVersion').Install_1_EvVersion
    $SwVersion = "00-$V1$V2"
    #Parse out the image version info
    $VPos=$Oem.ToUpper().LastIndexOfAny('V')
    $ImgVer=$Oem.Remove(0,$VPos)
    #(e.g IPUV5_00-34_57)
    return  "IPU$($ImgVer)_$($SwVersion)".ToUpper()
    }
