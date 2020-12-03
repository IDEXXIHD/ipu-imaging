'�萔�̐錾
' --- [ �o�[�`�����n�[�h�f�B�X�N�̃p�X��` ]
Const VHD_FILE  = "C:\Program Files (x86)\SysmexWork\VirtualSysmex.vhd"   

' --- [ VHD�t�@�C���}�E���g���s��` ]
Const DISKPART_CMD  = """C:\Program Files (x86)\SysmexWork\CmdEx.exe"" /c ""DiskPart /S C:\temp\mount.txt"" "

' --- [ DiskPart�R�}���h�t�@�C����` ]
Const DISKPART_FILE = "C:\temp\mount.txt"
Const DISKPART_DEL  = """C:\Program Files (x86)\SysmexWork\CmdEx.exe"" /c ""DEL C:\temp\mount.txt"""

' --- [ DiskPart�R�}���h��` ]
Const DISKPART_AUTOMOUNT	= "automount noerr"
Const DISKPART_SELECT_VDISK	= "select vdisk file=""C:\Program Files (x86)\SysmexWork\VirtualSysmex.vhd"""
Const DISKPART_ATTACH_VDISK	= "attach vdisk noerr"
Const DISKPART_ONLINE_DISK	= "online disk noerr"
Const DISKPART_SELECT_PARTITION	= "select partition 1"
Const DISKPART_ASSIGN_MOUNT	= "assign mount=""C:\Program Files (x86)\Sysmex\"" noerr"
Const DISKPART_SELECT_VOLUME	= "select volume=""C:\Program Files (x86)\Sysmex\"""
Const DISKPART_ASSIGN_LETTER	= "assign letter=S noerr"
Const DISKPART_EXIT		= "exit"

' --- [ ���s�t�@�C���̒�` ]
Const IPU_EXE       = "C:\Program Files (x86)\Sysmex\IPU\IPU.exe"
Const START_IPU     = "cmd.exe /c start """" ""C:\Program Files (x86)\Sysmex\IPU\IPU.exe"" "
Const START_COMM    = "cmd.exe /c start """" ""C:\Program Files (x86)\Sysmex\IPU\Communicator.exe"" "

Const ForReading   = 1 '�ǂݍ���
Const ForWriting   = 2 '�������݁i�㏑�����[�h�j
Const ForAppending = 8 '�������݁i�ǋL���[�h�j

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

    ' ---- �C�x���g���O�L�^
    Set objWshShell = WScript.CreateObject("WScript.Shell")
    objWshShell.LogEvent 4, "StartIPU.vbs - Start IPU script."

    ' ---- IPU�N��
    Set objFsoIPU = CreateObject("Scripting.FileSystemObject")
    If objFsoIPU.FileExists(IPU_EXE) Then
        ' ---- ���Ƀ}�E���g�ς݂Ȃ炻�̂܂܋N��
        CreateObject("WScript.Shell").Run START_COMM,0	' communicator startup
        CreateObject("WScript.Shell").Run START_IPU,0	' IPU startup
        objWshShell.LogEvent 0, "StartIPU.vbs - Startup direct exe."
    Else
        ' ---- VHD�}�E���g���N��
        Set objFso = CreateObject("Scripting.FileSystemObject")
        If objFso.FileExists(VHD_FILE) Then
            For intCnt = 0 to 11
                ' ---- DiskPart�p�̃X�N���v�g�t�@�C�����쐬
                Set objFileSys = CreateObject("Scripting.FileSystemObject")
                Set objDriveFile = objFileSys.OpenTextFile(DISKPART_FILE, ForWriting, True)
                If objDriveFile Then
                    ' ---- �X�N���v�g�t�@�C�����o��
                    objDriveFile.WriteLine DISKPART_AUTOMOUNT
                    objDriveFile.WriteLine DISKPART_SELECT_VDISK
                    objDriveFile.WriteLine DISKPART_ATTACH_VDISK
                    objDriveFile.WriteLine DISKPART_ONLINE_DISK
                    objDriveFile.WriteLine DISKPART_SELECT_PARTITION
                    objDriveFile.WriteLine DISKPART_ASSIGN_MOUNT
                    objDriveFile.WriteLine DISKPART_SELECT_VOLUME
                    objDriveFile.WriteLine DISKPART_ASSIGN_LETTER
                    objDriveFile.WriteLine DISKPART_EXIT
                    ' ---- �X�N���v�g�����s
                    CreateObject("WScript.Shell").Run DISKPART_CMD,0,true
                    ' ---- �X�N���v�g�̎��s���m�F����IPU�N��
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
                    ' ---- �X�N���v�g�t�@�C�����폜
                    objDriveFile.Close
                    Set objFileSys = Nothing
                    Set objDriveFile  = Nothing
                    objDriveFile = 0
                    CreateObject("WScript.Shell").Run DISKPART_DEL,0
                    ' ---- ���s�m�F
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
