#------------Variables/------------------------------------------------------

$FolderToBackup = "C:\filesToBackup"
$TempFolder = "C:\TemporaryFiles"
$TempFolder2 = "C:\TemporaryFiles2"
$BackupServer = "server2"
$FolderWithBackup = "\\$BackupServer\c$\backup"
$Date = date -format d
$7zFolder = "C:\Program Files (x86)\7-Zip\"
$Date = $Date.toString().Replace('.','-')
$BackupSatus = 0
$ArchiveBeforeTransferSize = 0
$ArchiveAfterTransferSize = 0
$Message = ""

#------------/Variables-------------------------------------------------------

if (-not (Test-Path $TempFolder)) {
	New-Item $TempFolder -type directory 
	}

if (-not (Test-Path $TempFolder2)) {
	New-Item $TempFolder2 -type directory 
	} else {
		$BackupSatus = 1
	}

robocopy $FolderToBackup $TempFolder *.* /E /V /R:1 /W:5 /PURGE /LOG:$TempFolder\$Date.log
	
set-alias sz "$7zFolder\7z.exe"
sz a -mx=9 $TempFolder2\$Date.zip $TempFolder\

$connection = Test-Connection $BackupServer -Count 1 -ErrorAction SilentlyContinue
	if ($connection -ne $null){
		robocopy $TempFolder2 $FolderWithBackup\
		$ArchiveBeforeTransferSize = get-childitem $TempFolder2 -recurse `
		| where-object { ((get-date)-$_.creationTime).days -le 0 } | %{echo $_.Length}
		$ArchiveAfterTransferSize = get-childitem $FolderWithBackup -recurse `
		| where-object { ((get-date)-$_.creationTime).days -le 0 } | %{echo $_.Length}
		if ($ArchiveBeforeTransferSize -eq $ArchiveAfterTransferSize){
			Remove-Item $TempFolder2 -Force -recurse
		} else {
			$BackupSatus = 3
		}
	} else {
		$BackupSatus = 2
	}

#------Rotation/-----------------------------------------------------

get-childitem $FolderWithBackup -recurse | `
where-object { ((get-date)-$_.creationTime).days -ge 30 } | `
%{$ItemtoRemove=$FolderWithBackup+$_; echo $ItemtoRemove} | Remove-Item		

#------/Rotation-----------------------------------------------------

Switch ($BackupSatus)
	{
		0 { $Message = "Everything OK." }
		1 { $Message = "One or more file transfer before current was unsuccessful. Current - successful."}
		2 { $Message = "Backup server is unavailable." }
		3 { $Message = "Archives sizes mismatch after file transfer." }
	}
Remove-Item $TempFolder -Force -recurse	
# Send email here 	
if ("2,3" -match $Message){
	send-mailmessage -to "User01 <pm.services@gmail.com>"`
	-from "BackUp script <pm1.services@gmail.com>" -subject $Message -smtpServer 192.168.49.110
}
If ($BackupSatus -eq 3){
	$BackupSatus = 2
}

Write-Host "$BackupSatus $Message | $BackupSatus $Message"
