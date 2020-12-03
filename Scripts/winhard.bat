@echo off

REM
REM Version 5
REM
REM The script enables firewall blocking of the following ports
REM
REM tcp/80   - http
REM tcp/135  - rpc (remote procedure call)
REM tcp/139  - netbios (session services, file sharing)
REM tcp/445  - smb (server message block, direct file sharing)
REM tcp/515  - lpd (print server)
REM tcp/2869 - ssdp (event notification)
REM tcp/3389 - remote display protocol (rdp)
REM
REM udp/137  - netbios (name services)
REM udp/138  - netbios (datagram services)
REM udp/1900 - ssdp
REM
REM
REM The following are explicitly opened on Win7/Win10 where the install process
REM may not have configured them.
REM
REM tcp/49500-49599 - IRAP communication
REM udp/49400       - IRAP Hail
REM
REM Rules to allow the Sysmex programs IPU.exe and Communicator.exe are also
REM generated for Win7/Win10.
REM
REM   S:\IPU\IPU.exe
REM   S:\IPU\Communicator.exe
REM
REM The script explicitly opens the following port for IPU <-> Instrument communications
REM
REM tcp/4098
REM
REM The script also disables the remote desktop service (called Terminal Services)
REM by setting the following registry key to 1
REM
REM HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections
REM

setlocal ENABLEDELAYEDEXPANSION

ver | findstr "5\.1\." > NUL

if !ERRORLEVEL! equ 0 (

    REM winXP system

    REM make sure the firewall is running
    netsh firewall set opmode enable > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to turn on firewall"
        exit /B 1
    )
	
    REM okay if this command fails, we explicitly block the ports it uses further down
    netsh firewall set allowedprogram program="C:\WINDOWS\system32\sessmgr.exe" name="Remote Assistance" mode=disable > NUL

    netsh firewall add portopening protocol=tcp port=80 mode=disable name="block-tcp-80" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking tcp port 80"
        exit /B 1
    )
	
    netsh firewall add portopening protocol=tcp port=135 mode=disable name="block-tcp-135" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking tcp port 135"
        exit /B 1
    )
	
    netsh firewall add portopening protocol=tcp port=139 mode=disable name="block-tcp-139" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking tcp port 139"
        exit /B 1
    )
	
    netsh firewall add portopening protocol=tcp port=445 mode=disable name="block-tcp-445" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking tcp port 445"
        exit /B 1
    )

    netsh firewall add portopening protocol=tcp port=515 mode=disable name="block-tcp-515" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking tcp port 515"
        exit /B 1
    )
	
    netsh firewall add portopening protocol=tcp port=2869 mode=disable name="block-tcp-2869" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking tcp port 2869"
        exit /B 1
    )
	
    netsh firewall add portopening protocol=tcp port=3389 mode=disable name="block-tcp-3389" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking tcp port 3389"
        exit /B 1
    )

    netsh firewall add portopening protocol=udp port=137 mode=disable name="block-udp-137" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking udp port 137"
        exit /B 1
    )
	
    netsh firewall add portopening protocol=udp port=138 mode=disable name="block-udp-138" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking udp port 138"
        exit /B 1
    )	

    netsh firewall add portopening protocol=udp port=1900 mode=disable name="block-udp-1900" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to add rule blocking udp port 1900"
        exit /B 1
    )

) else (

    REM win7 or win10

    REM disable the firewall while we are manipulating rules
    REM if the firewall is already off this is okay

    netsh advfirewall set allprofiles state off > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to turn off firewall"
        exit /B 1
    )

    netsh advfirewall firewall delete rule name="block-unused-tcp" > NUL

    netsh advfirewall firewall add rule name="block-unused-tcp" action=block direction=in protocol=tcp localport=80,135,139,445,515,2869,3389 > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to create rule to block unused TCP ports"
        exit /B 1
    )

    netsh advfirewall firewall delete rule name="block-unused-udp" > NUL

    netsh advfirewall firewall add rule name="block-unused-udp" action=block direction=in protocol=udp localport=137,138,1900 > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to create rule to block unused UDP ports"
        exit /B 1
    )

    netsh advfirewall firewall delete rule name="allow-tcp-4098" > NUL

    netsh advfirewall firewall add rule name="allow-tcp-4098" action=allow direction=in protocol=tcp localport=4098 > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to create rule to allow TCP port 4098"
        exit /B 1
    )
	
    REM allow the IRAP dynamic ports
    netsh advfirewall firewall delete rule name="TCP 49500-49599" > NUL

    netsh advfirewall firewall add rule name="TCP 49500-49599" action=allow direction=in protocol=tcp localport=49500-49599 > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to create rule to allow TCP ports 49500-49599"
        exit /B 1
    )
	
    REM allow the IRAP hailing port
    netsh advfirewall firewall delete rule name="UDP 49400" > NUL

    netsh advfirewall firewall add rule name="UDP 49400" action=allow direction=in protocol=tcp localport=49400 > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to create rule to allow UDP port 49400"
        exit /B 1
    )

    REM allow SYSMEX applications, communicator.exe and ipu.exe

    netsh advfirewall firewall delete rule name="Communicator" > NUL

    netsh advfirewall firewall add rule name="Communicator" action=allow direction=in program="S:\ipu\communicator.exe" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to create rule to allow communicator.exe"
        exit /B 1
    )

    netsh advfirewall firewall delete rule name="IPU" > NUL

    netsh advfirewall firewall add rule name="IPU" action=allow direction=in program="S:\ipu\ipu.exe" > NUL

    if !ERRORLEVEL! neq 0 (
        echo "Failed to create rule to allow ipu.exe"
        exit /B 1
    )


    REM faster machines seem to require a delay before restart

    timeout 10 > NUL
	
    netsh advfirewall set allprofiles state on > NUL
	
    if !ERRORLEVEL! neq 0 (
        echo "Failed to turn off firewall"
        exit /B 1
    )
)


REM Turning off RDP via the Registry, same key for all platforms

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f > NUL

if !ERRORLEVEL! neq 0 (
    echo "Failed to disable remote desktop in the registry"
    exit /B 1
)
