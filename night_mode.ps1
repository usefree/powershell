# night_mode
# computer will be powered off in 1 hour 
# if current  time >= 23; time <= [0,1,2,3,4,5,6]
# usefree 09 02 2019

$TimerActive = 0
$file = "c:\temp\timeractive.txt"
$logfile = "c:\scripts\timer_log.txt"
$date=Get-Date
write-output "Computer started at $date" >> $logfile
while ($TimerActive -le 12) {
$hour=[convert]::ToInt32(((get-date -uformat "%H").ToString()), 10)
	if ( 0,1,2,3,4,5,6,23 -contains $hour) {
		if ( Test-Path $file ) {
			$TimerActive = [convert]::ToInt32((Get-Content $file), 10)
			if ($TimerActive -ge 12) {
				shutdown -s -t 180
                $date=Get-Date
                write-output "Computer will be powered off at $date" >> $logfile
                write-output "-------------------------------------" >> $logfile
				get-childitem $file | Remove-Item
			} else {
				$TimerActive = $TimerActive +1
				write-output $TimerActive > $file
			} 
		} else {
			New-Item $file -Force
			$TimerActive = $TimerActive+1
			write-output $TimerActive > $file
		}
	} else {
		write-host "Hour $hour is free to use PC"
	}
	Start-Sleep -seconds 300 
}
