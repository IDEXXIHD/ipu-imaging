Read-Host 'Plug in the adapters to be configured. [Enter]'
pnputil.exe /add-driver "$scriptPath\Drivers\AX88772\NETAX88772.inf" /install 

#Configure the newer TrendNet adapters - HW Versions 4,5,6
Do
{
    Read-Host 'Plug network cable into the (White/Black) adapter [Enter]'
    $Asix = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like '*AX88772C USB*'} | Where-Object {$_.Status -eq 'Up'}
    $Asix | Get-NetIPAddress |Remove-NetIPAddress -Confirm:$false 
    $Asix | New-NetIPAddress -IPAddress 192.168.28.100 -PrefixLength 24 | Out-Null
    $Asix | Disable-NetAdapterBinding -ComponentID ms_tcpip6 
    $Asix | Get-NetIPAddress
} Until ($null -ne $Asix)

#Configure the newer TrendNet adapters - HW Version 3
Do
{
    Read-Host 'Plug network cable into the (Blue) adapter [Enter]'
    $Asix = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like '*AX88772 USB*'} | Where-Object {$_.Status -eq 'Up'}
    $Asix | Get-NetIPAddress |Remove-NetIPAddress -Confirm:$false 
    $Asix | New-NetIPAddress -IPAddress 192.168.28.101 -PrefixLength 24 | Out-Null
    $Asix | Disable-NetAdapterBinding -ComponentID ms_tcpip6  
    $Asix | Get-NetIPAddress
} Until ($null -ne $Asix) 