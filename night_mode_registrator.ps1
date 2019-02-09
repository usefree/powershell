$Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "C:\scripts\night_mode.ps1"
$Trigger =  New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -User "NT AUTHORITY\SYSTEM" -Action $Action -Trigger $Trigger -TaskName "nightmode" -Description "nightmode"
#Unregister-ScheduledTask -TaskName nightmode -Confirm:$false
