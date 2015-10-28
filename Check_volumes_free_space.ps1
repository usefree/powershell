# Plugin for Nagios
# Check on Windows host if there on local disks 
# or Cluster Shared Volumes (CSV) attached to host is enought free space
# if there are one or more discs or CSV with less than 10% free space 
# Warning message Generated
# if there are one or more discs or CSV with less than 5% free space 
# Critical message Generated

param([int]$w=10, [int]$c=5)
$Status = 0
$DefaultMessage = "Ok, Free space on all volumes more than 10%"
$Message = $DefaultMessage
$VolumesNeedCriticalAttention = ""
$VolumesNeedWarningAttention = ""
$ListCSV = ""

# --- Disks free space check -----

$Hostname = hostname
$Wmiq = 'SELECT * FROM Win32_LogicalDisk WHERE Size != Null AND DriveType >= 2'
$Disks = Get-WmiObject -Query $Wmiq -ErrorAction SilentlyContinue -ErrorVariable ProcessError;
if ($ProcessError) {
	$Status = 3
	$Message = "Unknown disk check error!"
} else {
	foreach ($Disk in $Disks) {
		$CustomDiskPercentFreeSpace = [int](($Disk.FreeSpace)/($Disk.Size) * 100)
		if (($CustomDiskPercentFreeSpace -le $c) -and ($Disk.FreeSpace -le 1073741824)) {
			if (($Message -eq $DefaultMessage) -or ($Message -eq "Warning")) {
				$Message = "Critical"
				$Status = 2
			}
			$VolumesNeedCriticalAttention += "Disk: $($Disk.DeviceID)\ Free Space: $CustomDiskPercentFreeSpace%; "
		} elseif (($CustomDiskPercentFreeSpace -le $w) -and ($Disk.FreeSpace -le 2147483648)) {
			if ($Message -eq $DefaultMessage) {
				$Message = "Warning"
				$Status = 1
			}
			$VolumesNeedWarningAttention += "Disk: $($Disk.DeviceID)\ Free Space: $CustomDiskPercentFreeSpace%; "
		}
	}
}

# ----- Cluster shared volume free space check ----

Import-Module FailoverClusters
$ClasterVolumes = Get-ClusterSharedVolume -ErrorAction SilentlyContinue -ErrorVariable ProcessError;
if ($ProcessError) {
	$ListCSV = "Host have no Fail Over Cluster Role."
} else {
	foreach ($Volume in $ClasterVolumes) {
		if ($Hostname -eq $Volume.OwnerNode) {
			$OwnerNode = $Volume.OwnerNode
			$FriendlyVolumeName = $Volume.SharedVolumeInfo.FriendlyVolumeName
			$CustomVolumePercentFree = [int]($Volume.SharedVolumeInfo.Partition.PercentFree)
			if (($CustomVolumePercentFree -le $c) -and ($Volume.SharedVolumeInfo.Partition.FreeSpace -le 1073741824)) {
				if (($Message -eq $DefaultMessage) -or ($Message -eq "Warning")) {
					$Message = "Critical"
					$Status = 2
				}
				$VolumesNeedCriticalAttention += "CSV: $FriendlyVolumeName\$Volume Free Space: $CustomVolumePercentFree%; "
			} elseif (($CustomVolumePercentFree -le $w) -and ($Volume.SharedVolumeInfo.Partition.FreeSpace -le 2147483648)) {
				if ($Message -eq $DefaultMessage) {
					$Message = "Warning"
					$Status = 1
				}
				$VolumesNeedWarningAttention += "CSV: $FriendlyVolumeName\$Volume Free Space: $CustomVolumePercentFree%; "
			}
		} 
	}
}	
if ($Status -eq 1) {
	Write-Host "$Message; $VolumesNeedWarningAttention $ListCSV"
} else {
	Write-Host "$Message; $VolumesNeedCriticalAttention $ListCSV"
}
exit $Status
