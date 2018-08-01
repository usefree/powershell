$wmi = Get-WMIObject -Class Win32_OperatingSystem

$LastBootTime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)

$SysUpTime = (Get-Date) - $LastBootTime

$Uptime = "UPTIME: $($sysuptime.days) Days, $($sysuptime.hours) Hours, $($sysuptime.minutes) Minutes, $($sysuptime.seconds) Seconds"

write-host $Uptime 

start-sleep 5
