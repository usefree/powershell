# remove files script
param( 
[string]$DirToRemove 
)

# Recursively rename all catalogs
# in order to avoid errors while
# Removing files with long names

function RenameItems {
param( 
[string]$DirToProcess )
$i=1
$Items = Get-Childitem "$DirToProcess"
    foreach ($Item in $Items) {
        if (($item.GetType()).name -eq "DirectoryInfo") {
            if ($(Get-ChildItem $Item.FullName | Measure-Object).Count -gt 0) {
                RenameItems $Item.FullName
            }
            try {
                $i++
                $Item | Rename-Item -NewName "$i" 
            } catch {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-host "ErrorMessage: $ErrorMessage"
                Write-host "FailedItem: $FailedItem"
            }
        } 
    }
}

RenameItems $DirToRemove

$Items = Get-Childitem "$DirToRemove"
foreach ($Item in $Items) {
    try {
        $Item | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue 
    } catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-host "ErrorMessage: $ErrorMessage"
        Write-host "FailedItem: $FailedItem"
    }
}
$DirToRemove | Remove-Item -Force -Recurse 



