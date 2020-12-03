'定数の宣言
' --- [ バーチャルハードディスクのパス定義 ]
Const VHD_FILE  = "C:\Program Files (x86)\SysmexWork\VirtualSysmex.vhd"   

' --- [ VHDファイルマウント実行定義 ]
Const DISKPART_CMD  = """C:\Program Files (x86)\SysmexWork\CmdEx.exe"" /c ""DiskPart /S C:\temp\mount.txt"" "

' --- [ DiskPartコマンドファイル定義 ]
Const DISKPART_FILE = "C:\temp\mount.txt"
Const DISKPART_DEL  = """C:\Program Files (x86)\SysmexWork\CmdEx.exe"" /c ""DEL C:\temp\mount.txt"""

' --- [ DiskPartコマンド定義 ]
Const DISKPART_AUTOMOUNT	= "automount noerr"
Const DISKPART_SELECT_VDISK	= "select vdisk file=""C:\Program Files (x86)\SysmexWork\VirtualSysmex.vhd"""
Const DISKPART_ATTACH_VDISK	= "attach vdisk noerr"
Const DISKPART_ONLINE_DISK	= "online disk noerr"
Const DISKPART_SELECT_PARTITION	= "select partition 1"
Const DISKPART_ASSIGN_MOUNT	= "assign mount=""C:\Program Files (x86)\Sysmex\"" noerr"
Const DISKPART_SELECT_VOLUME	= "select volume=""C:\Program Files (x86)\Sysmex\"""
Const DISKPART_ASSIGN_LETTER	= "assign letter=S noerr"
Const DISKPART_EXIT		= "exit"

' --- [ 実行ファイルの定義 ]
Const IPU_EXE       = "C:\Program Files (x86)\Sysmex\IPU\IPU.exe"
Const START_IPU     = "cmd.exe /c start """" ""C:\Program Files (x86)\Sysmex\IPU\IPU.exe"" "
Const START_COMM    = "cmd.exe /c start """" ""C:\Program Files (x86)\Sysmex\IPU\Communicator.exe"" "

Const ForReading   = 1 '読み込み
Const ForWriting   = 2 '書きこみ（上書きモード）
Const ForAppending = 8 '書きこみ（追記モード）

    Dim objFso
    Dim objFsoEx
    Dim objFsoIPU
    Dim objFileSys
    Dim intCnt
    Dim intCntS
    Dim intExecute
    Dim objDriveFile
    Dim objWshShell

    On Error Resume Next

    ' ---- イベントログ記録
    Set objWshShell = WScript.CreateObject("WScript.Shell")
    objWshShell.LogEvent 4, "StartIPU.vbs - Start IPU script."

    ' ---- IPU起動
    Set objFsoIPU = CreateObject("Scripting.FileSystemObject")
    If objFsoIPU.FileExists(IPU_EXE) Then
        ' ---- 既にマウント済みならそのまま起動
        CreateObject("WScript.Shell").Run START_COMM,0	' communicator startup
        CreateObject("WScript.Shell").Run START_IPU,0	' IPU startup
        objWshShell.LogEvent 0, "StartIPU.vbs - Startup direct exe."
    Else
        ' ---- VHDマウントし起動
        Set objFso = CreateObject("Scripting.FileSystemObject")
        If objFso.FileExists(VHD_FILE) Then
            For intCnt = 0 to 11
                ' ---- DiskPart用のスクリプトファイルを作成
                Set objFileSys = CreateObject("Scripting.FileSystemObject")
                Set objDriveFile = objFileSys.OpenTextFile(DISKPART_FILE, ForWriting, True)
                If objDriveFile Then
                    ' ---- スクリプトファイルを出力
                    objDriveFile.WriteLine DISKPART_AUTOMOUNT
                    objDriveFile.WriteLine DISKPART_SELECT_VDISK
                    objDriveFile.WriteLine DISKPART_ATTACH_VDISK
                    objDriveFile.WriteLine DISKPART_ONLINE_DISK
                    objDriveFile.WriteLine DISKPART_SELECT_PARTITION
                    objDriveFile.WriteLine DISKPART_ASSIGN_MOUNT
                    objDriveFile.WriteLine DISKPART_SELECT_VOLUME
                    objDriveFile.WriteLine DISKPART_ASSIGN_LETTER
                    objDriveFile.WriteLine DISKPART_EXIT
                    ' ---- スクリプトを実行
                    CreateObject("WScript.Shell").Run DISKPART_CMD,0,true
                    ' ---- スクリプトの実行を確認してIPU起動
                    intExecute = 0
                    For intCntS = 0 to 4
                        WScript.Sleep(1000)
                        Set objFsoEx = CreateObject("Scripting.FileSystemObject")
                        If objFsoEx.FileExists(IPU_EXE) Then
                            WScript.Sleep(5000)
                            CreateObject("WScript.Shell").Run START_COMM,0	' communicator startup
                            CreateObject("WScript.Shell").Run START_IPU,0	' IPU startup
                            Set objFsoEx = Nothing
                            intExecute = 1
                            Exit For
                        End If
                        Set objFsoEx = Nothing
                        objFsoEx = 0
                    Next
                    ' ---- スクリプトファイルを削除
                    objDriveFile.Close
                    Set objFileSys = Nothing
                    Set objDriveFile  = Nothing
                    objDriveFile = 0
                    CreateObject("WScript.Shell").Run DISKPART_DEL,0
                    ' ---- 実行確認
                    If intExecute = 1 Then
                        objWshShell.LogEvent 0, "StartIPU.vbs - Startup mount exe."
                        Exit For
                    Else
                        objWshShell.LogEvent 1, "StartIPU.vbs - DiskPart error."
                    End If
                Else
                    objWshShell.LogEvent 1, "StartIPU.vbs - DISKPART file create error."
                    Set objFileSys = Nothing
                    Set objDriveFile  = Nothing
                    objDriveFile = 0
                    WScript.Sleep(5000)
                End If
           Next
        Else
            objWshShell.LogEvent 1, "StartIPU.vbs - Not exist VHD file."
        End If
        Set objFso = Nothing
    End If
    Set objFsoIPU = Nothing
    objWshShell.LogEvent 4, "StartIPU.vbs - End IPU script."
    Set objWshShell = Nothing
