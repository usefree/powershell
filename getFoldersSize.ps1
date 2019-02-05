param(
$folderToLook="C:\users";
)
if (test-path $folderToLook){
	foreach ($folder in get-childitem  c:\CI\) {write-host "Folder $folder "; "{0:N2} MB" -f ((Get-ChildItem $folder -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)}
}
