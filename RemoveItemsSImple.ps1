# remove files script
param( 
[string]$DirToRemove 
)

function RemoveItems {
param( 
[string]$DirToRemove )

$Items = Get-Childitem "$DirToRemove" -Recurse 
    foreach ($Item in $Items) {
        try {
            $Item | Remove-Item -Force -Recurse -ErrorAction Stop 
        } catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-host "ErrorMessage: $ErrorMessage"
            Write-host "FailedItem: $FailedItem"
        }
    }
}

RemoveItems $DirToRemove


