<#
Author:  Shawn Childs
Created: 3/20/2013
Purpose:  This powershell script shall find the Trendnet Adapter used for the ProCyte Dx IPU and set
		  its critical networking properties.  This script was intended to run at startup for every boot.  
#>

#Set all erroractions to STOP
$ErrorActionPreference = "Stop"

#This is the IP Address that must be set
$IP = "192.168.28.150"
#This is the subnet mask
$Mask = "255.255.255.0"

#Find the adapters by description.  The description contains the word ASIX.
#There may be multiple adapters configured and will likely return in an array.
Try{
	$Adapters = Get-WMIObject Win32_NetworkAdapterConfiguration | Where-Object {$_.Description -like "ASIX AX88772*"} 
	ForEach($Adapter in $Adapters){
		$Adapter.EnableStatic($IP, $Mask) 
	}
}
Catch [system.exception] {
	"Caught a system exception"
	$FailedItem = $_.Exception.ItemName
	$ErrorMessage = $_.Exception.Message
	$Time = Get-Date
	"$Time    Failed Item: $FailedItem with message: $ErrorMessage" | out-file C:\scripts\errlog.log -append
}