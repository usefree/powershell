# remove files script

function remove-catalogs {
param( [string]$workdir )

$items = Get-Childitem "$workdir" -Recurse 
$stoppedProcesses = ""
foreach ($item in $items) {
    Write-Host "remove $item with force"
    if ( ($item.GetType()).name -eq "DirectoryInfo" ) {
        write-host "removing directory $item"
        $item | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable ProcessError1
    } else {
        write-host "removing file $item"
        $item | Remove-Item -Force -ErrorAction SilentlyContinue -ErrorVariable ProcessError2
    }
    if (($ProcessError1) -or ($ProcessError2)) {
        Write-Host "remove $item with force failed"
        Write-Host "remove $item without force"
        if (($item.GetType()).name -eq "DirectoryInfo" ) {
            write-host "removing directory $item"
            $item | Remove-Item -Recurse -ErrorAction SilentlyContinue -errorvariable ProcessError3
        } else {
            write-host "removing file $item"
            $item | Remove-Item -ErrorAction SilentlyContinue -errorvariable ProcessError4
        }
        if (($ProcessError3) -or ($ProcessError4)) {
            Write-Host "remove $item without force failed"
            if ( ($item.GetType()).name -eq "FileInfo" ) {
                Write-Host "searching blocking process"
                $ProcessID = (Get-WmiObject -Class Win32_Process | Where-Object -FilterScript { (($_.path -match $item) -and ($_.path -match $workdir) )}).ProcessId
                Write-Host "process $ProcessID going to kill"
                Stop-Process $ProcessID -Force -ErrorAction SilentlyContinue -ErrorVariable ProcessError3
                if (-not $ProcessError3) {
                   $stoppedProcesses = $stoppedProcesses + "$processname, "
                }
            } 
        }
    }    
}
return $stoppedProcesses
}
$stoppedProcesses = remove-catalogs "c:\\temp\\temp\\"
if ( $stoppedProcesses -ne "" ) {
    write-host "second attempt"
    remove-catalogs "c:\\temp\\temp\\"
}
