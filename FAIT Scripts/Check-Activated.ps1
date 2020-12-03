# Check-Activated.ps1
# By: Rhayes 04/17/2019
# This powershell script will return 0 if Windows is activated.
# else, it will return 1.

$status = 1
$activated = 1

Write-Host "Getting Windows activation status."
Write-Host "This may take several seconds..."

# The license object property "licenses status" will return 1 if 
# Win10 is activated. Else, another val like (e.i. 5) 
$license = Get-CimInstance -ClassName SoftwareLicensingProduct |
     Where-Object {$_.PartialProductKey} |
     Select-Object LicenseStatus -Last 1

if ($license.LicenseStatus -eq $activated) {
        $status = 0
    }
    else{
        $status=1
    }

Exit $status
