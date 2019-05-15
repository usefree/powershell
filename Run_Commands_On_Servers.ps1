# Created by usefree 23.04.2016
# Script allow to run commands on specified list of windows servers
#------ It is possible to hardcode Commands using example below: 
#--- Ex1

#$Commands[0] = 'hostname'
#$Commands[1] = 'get-date'
#$Commands[2] = 'dir c:\users\'

# after that it is necessary to specify right amount of script arguments
# which are defined in hardcode  
# usage should be like: 
#./RunCommandsOnServers.ps1 -Commands 0,1,2 -Servers rdp, app11, app4

#--- Ex2

#6#List of VM-s on hosts
#6$$Commands[0] = 'get-vm'
#6$Output = " fl VmName"

# ----- More examples are at the end of listing

param (
[string[]]$Commands, #= "hostname",
[string]$Output = " fl *",
[string[]]$Servers
)
$Usage2 = "Usage for hardcoded command for host3, host4:"
$Usage3 = "./RunCommandsOnServers.ps1 -Commands 0 -Servers host3, host4"
$Usage1 = "Usage: ./RunCommandsOnServers.ps1 -Commands [Command1], [Command2] -Output [output format] -Servers [all], [rdp], [app], [hosts], [test], [hostname_of_server]"
$Date = get-date -uformat "-%d-%m-%Y"

# ----- Arrays of predefined servers & variables /

$ArrayOfAppServers = @("app1","app2","app3")
$ArrayOfHostsServers = @("host1", "host2", "host3")
$ArrayOfRdpServers = @("rdp11", "rdp2")
$ArrayOfDBServers = @("db1","db2")
$ArrayOfOtherServers2 =@("appd", "appc")
$ArrayOfAllServers2 = $ArrayOfDBServers + $ArrayOfOtherServers2 + $ArrayOfRdpServers + `
                      $ArrayOfAppServers + $ArrayOfHostsServers
$ArrayOfTestServers = @("appf","app4","host4","db3","rdp3")
$ArrayOfServers = @()

# ----- / Variables 

# ----- Check if Commands received /

if (-not $Commands ) {
	Write-host "Error. Please, specify Command"
	Write-host $Usage
    Write-host $Usage1
    Write-host $Usage2
	exit
}

# ----- Compose list of servers /

function ComposeListOfServers {
	Param (
	[string[]]$Servers
	)
	$TempArrayOfServers = @()
	if (-not $Servers) {
		Write-host "Error. Empty servers parameter"
		Write-host $Usage
        Write-host $Usage1
        Write-host $Usage2
		exit
	} else {
		foreach ($Variant in $Servers) {
			Switch ($Variant)
			{
				"all" { 
					$TempArrayOfServers += $ArrayOfAllServers2
					; break
					}
				"rdp" 	{ $TempArrayOfServers += $ArrayOfRdpServers}
				"app" 	{ $TempArrayOfServers += $ArrayOfAppServers}
				"hosts" { $TempArrayOfServers += $ArrayOfHostsServers}
				"test" 	{ $TempArrayOfServers += $ArrayOfTestServers}
				"test1" { $TempArrayOfServers += $ArrayOfTestServers1}
                "db" { $TempArrayOfServers += $ArrayOgDBServers}
				default { 	$TempArrayOfAllServers += $ArrayOfAllServers2
							if ( $TempArrayOfAllServers -contains $Variant ) {
								$TempArrayOfServers += $Variant
							} else {
								Write-host 'Error. Parameter "'$Variant'" is not recognized'; 
							}
						}
			}
		}
	}
	return $TempArrayOfServers
}

# ----- Check if list of servers composed right /

if ( $Servers ) {
	$ArrayOfServers = ComposeListOfServers($Servers)
} else {
	Write-Host "Array of servers is not specified"
	Write-host $Usage
    Write-host $Usage1
    Write-host $Usage2
	exit
}
if ( -not $ArrayOfServers) {
	Write-Host "Array of servers specified incorrectly"
	Write-host $Usage
    Write-host $Usage1
    Write-host $Usage2
	exit
}


$Substr1 = 'get-winevent -logname "system" | where-object {($_.id -eq 37) -and ($_.providername -eq "Ntfs")}|'
$Substr2 = '%{$objsid=new-object system.security.principal.securityidentifier($_.userid); '
$Substr3 = '$objuser=$objsid.translate([system.security.principal.ntaccount]); write-host $_.machinename " " $_.timecreated " " $objuser " " $_.Message}'

$Commands[0] = $Substr1 + $Substr2 + $Substr3
#$Output = "ft -autosize -property TimeCreated, Id, Message"

# ----- Function executing commands /

function RunCommands {
	Param (
	[string[]]$ArrayOfServers,
	[string[]]$Commands
	)
$ScriptResult = @()

# ----- Get current user privileges for session creation /

$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$Credentials = Get-Credential $User
#!!
# necessary to add checking if credentials are correct after first server connection
#!!
	
	foreach ($Server in $ArrayOfServers) {
	write-host "Processing $Server ..."
	Write-host "---------------------------------------------------------------"
        $connection = Test-Connection $Server -Count 1 -ErrorAction SilentlyContinue
		if ($connection -ne $null){
            write-host "$Server is reachable"
            $Session = New-PSSession -computerName $Server -credential $Credentials
		    $ScriptResult += Invoke-Command -Session $Session -Scriptblock {
				Param( 
				$Server,
				$Commands 
				)
                $TempScriptResult =@()
				foreach ($Command in $Commands) {
<# ----- Possible test block before executing command /
				Invoke-Expression $Command -whatif `
					-ErrorAction SilentlyContinue `
					-ErrorVariable ProcessError
					if ($ProcessError) {
						Write-host "Error. Command $Command executed with errors."
						Write-host $ProcessError
						Write-host $Usage
						exit
					} else {
----- #>	
					#$TempScriptResult += "On Server $Server executing command `r`n $Command `r`n"
                    $TempScriptResult += Invoke-Expression $Command
					#$TempScriptResult = $TempScriptResult.ToString() + "`r`n"
				}
				#$TempScriptResult += "`r`n ---------/ End of results for Server: $Server /----------`r`n"
				return $TempScriptResult
			} -ArgumentList $Server, $Commands
			Remove-PSSession $Session
        }
        else {
            write-host "$Server is Unreachable" -ForegroundColor Red
        }
	}
	return $ScriptResult
}

$ResultOfCommands = RunCommands -ArrayOfServers $ArrayOfServers -Commands $Commands 

# ----- It is possible to hardcode output for specific commands set
# for example for hardcoded command "get-vm" if it is necessary to receive
# only vm names $Output should be hardcoded to 
# $Output = "ft Names"

$Printresult = '$ResultOfCommands' + '|' + $Output
Invoke-Expression $Printresult

#------ List of usefull commands

# ----- Hardcode command and output /

# ----- 1 Search for custom Event in Logs for last specific period /

#$Substr1 = 'Get-WinEvent -logname "Microsoft-Windows-TerminalServices-SessionBroker-Client/Operational" |'
#$Substr2 = ' where-object {(((Get-Date) - $_.TimeCreated).TotalHours -le 48)'
#$substr3 = '-and (($_.id -eq 1301) -or ($_.id -eq 1307))'
#$substr4 = '-and (($_LevelDisplayName -eq "Error") -or ($_LevelDisplayName -eq "Ошибка"))}'
#$Commands[0] = $Substr1 + $Substr2 + $Substr3 + $Substr4
#$Output = "ft -autosize -property TimeCreated, Id, Message"

# ----- 2 Backup IIS WebConfiguration /

#$Commands[0] = 'Backup-WebConfiguration -name backup-(get-date)'

# ----- 3 Search in specified file if it contain given substring /

#$Commands[0] = 'Get-Content "C:\Program Files\NSClient++\nsclient.ini" | findstr alias_up '

# ------ 4 Restart nscp service /

#$Commands[0] = 'restart-service salt-minion' 

# ----- 5 List permissions for specified folder /

#$Commands[0] = ' get-acl C:\inetpub\wwwroot'
#$Output = " fl Accesstostring"
# --------------------------------------------------------------------

# 6 #List of VM-s on hosts
# 6 $Commands[0] = 'get-vm'
# 6 $Output = " fl VmName"

#7---add registry keys for TLS 1.1 TLS 1.2 ---
#7---after adding hardcode below to call script for each server:
#7---./RunCommandsOnServers.ps1 -Commands 0,1,2,3,4,5,6,7,8,9 -Servers app12

#7 $Commands[0] = 'New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1"'
#7 $Commands[1] = 'New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"'
#7 $Commands[2] = 'New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"'
#7 $Commands[3] = 'New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" -Name DisabledByDefault -Value 0 -Force'
#7 $Commands[4] = 'New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Name DisabledByDefault -Value 0 -Force'

#7 $Commands[5] = 'New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2"'
#7 $Commands[6] = 'New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"'
#7 $Commands[7] = 'New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"'
#7 $Commands[8] = 'New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -Name DisabledByDefault -Value 0 -Force'
#7 $Commands[9] = 'New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Name DisabledByDefault -Value 0 -Force'

#---8 count windows updates on servers
#8 $Commands[0] = '((new-object -com "Microsoft.Update.Session").CreateupdateSearcher().Search(("IsInstalled=0")).Updates | Measure-Object).Count.toString()'
  
#---9 Get swap file size
#9 $Commands[0] = '(Get-WmiObject Win32_PageFileusage |  Select-Object Name,AllocatedBaseSize,PeakUsage).AllocatedBaseSize'

#---10 Stop computer
#10 $Commands[0] = 'stop-computer -force'

#---11 list of files
#11 $Commands[0] = 'dir C:\inetpub\'
#11 ./RunCommandsOnServers.ps1 -Commands 0 -Output 'ft FullName' -Servers app1

#---12 Create new folder
#12 $Commands[0] = 'New-item -ItemType "directory" -Path "C:\inetpub"'

#---13 copy content of folder to another folder. Create folder where copying
#13 $Commands[0] = 'Copy-item "\\app1\c$\inetpub" "C:\inetpub" -Recurse'

#---14 remove files in folder 
#14 $Commands[0] = 'Remove-item "C:\inetpub\BG.1*"'
#14 $Commands[0] = 'Remove-item "C:\inetpub" -recurse'

#---15 get list of vms on hosts
#15 #$Commands[0] = 'Get-vm'
#15 $Output = " ft PSComputerName, VMName"
#15 RunCommandsOnServers.ps1 -Commands 0 -Servers hosts

#---16 Get list of System journal events with number 16945 for last 125 hours
#16$Commands[0] = 'Get-Winevent -LogName System | where-object {(((Get-Date) - $_.TimeCreated).TotalHours -le 125) -and (($_.id -eq 16945) -or ($_.id -eq 1129))} '

#---17 Get list of specific journal events containing text "test_usefree"
#17 $Substr1 = 'Get-WinEvent -logname "Microsoft-Windows-TerminalServices-SessionBroker-Client/Operational" |'
#17 $Substr2 = ' where-object {(((Get-Date) - $_.TimeCreated).TotalHours -le 2)'
#17 $substr3 = '-and (($_.id -eq 1301) -or ($_.id -eq 1307)) -and (($_.Message -replace "`r`n", " ") -like "*test_usefree*")}'
#17 $Commands[0] = $Substr1 + $Substr2 + $Substr3
#17 $Output = "fl Message, TimeCreated, MachineName"
#------------------#

#---18 Count updates installed
#18 $Commands[0] = '((new-object -com "Microsoft.Update.Session").CreateupdateSearcher().Search(("IsInstalled=0")).Updates | Measure-Object).Count.toString()'

#---19 find if specific hotfix installed
#19 $Commands[0] = 'get-hotfix | findstr 3080079'

#---20 Get content of specific file
#20$Commands[0] = ' get-content "C:\salt\conf\minion.d\grains.conf"'

#---21 Find service status start stop service 
#21 $Commands[0] = 'get-service | findstr salt-minion'
#21 $Commands[0] = 'stop-service nscp' 
#21 $Commands[1] = 'start-service nscp'

#--- 22 Working with appcmd
#22 $Commands[0] = 'C:\Windows\system32\inetsrv\appcmd.exe recycle apppool test'
#22 $Commands[0] = 'C:\Windows\system32\inetsrv\appcmd.exe add backup "22072018"'
#22 $Commands[0] = 'C:\Windows\system32\inetsrv\appcmd.exe restore backup "22072018"'

#---23 Get OS version
#23 $Commands[0] = 'Get-WmiObject win32_operatingsystem '
#23 $Output = " ft Name, CSName -Autosize"

#--- 24 CHECK IF HOST HAVE RAID
#24  $Commands[0] = 'get-wmiobject -class win32_systemdriver | where-object {$_.displayname -like "*mraid*"}'

#--- 25 get logged in users
#25 $Commands[0] = '$users=qwinsta;foreach ($user in $users){if(($user -match "rdp-tcp")-and(($user -match "Активно")-or($user -match "Active"))){write-host $($user.tostring() -split "\s+")[2]}}'

#--27 get all dynamic DNS A-records and their ip
#27 $Commands[0] = 'Get-DnsServerResourceRecord -ZoneName usefree.local -ComputerName dc1 -RRType A | where {$_.Timestamp -ne $null } | %{write-host $_.Hostname, $_.recordData.ipv4address.ipaddresstostring}'

#--- 28 Create symlink
# 28 $Commands[0] = 'cmd /c mklink "C:\Program Files\NSClient++\nsclient.ini" "C:\scripts\config\NSClient.ini"'

#--- 29 list files in dir
# 29 $Commands[0] = 'dir C:\inetpub'
# 29 $Output = " ft PSComputerName, BaseName, CreationTime, Length"

#-- 30 Create\remove scheduled task
# 30 $Commands[0] = '$Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "C:\scripts\LogRotatprWindows.ps1"'
# 30 $Commands[1] = '$Trigger =  New-ScheduledTaskTrigger -Daily -At 9pm'
# 30 $Commands[2] = 'Register-ScheduledTask -User "NT AUTHORITY\SYSTEM" -Action $Action -Trigger $Trigger -TaskName "IISLogRotation" -Description "Daily Rotation of IISlog"'
# 30 $Commands[0] = 'Unregister-ScheduledTask -TaskName IISLogRotation -Confirm:$false'
# $Output = " ft PSComputerName, TaskName, State"

#-- 31 Get fileversion
# 31 $Commands[0] = '[System.Diagnostics.FileversionInfo]::GetVersionInfo("c:\inetpub\test.dll").fileversion'

#-- 32 get process WorkingSet
# 32 $Commands[0] = 'get-process | where-object {$_.Name -eq "test.process"}'
# 32 $Output = '| ft Name, WorkingSet'

#-- 33 Get driver info
# 33 $Commands[0] = 'Get-WmiObject Win32_PnPSignedDriver | where-object {$_.DeviceName -match "etwork"}'
# 33 $Commands[0] = 'Get-WmiObject Win32_PnPSignedDriver | where {$_.devicename -like "*DELL*"}'
# 33 $Commands[0] = 'Get-WmiObject Win32_PnPSignedDriver | where {$_.devicename -like "*Qlogic*"}'
# 33 $Output = "ft PSComputerName, devicename, driverversion"
#

#-- 34 Check VM CPU Options (compatibility mode)
# 34 $Commands[0] = "get-vmprocessor *"
# 34 $Output = "ft computername, vmname, CompatibilityForMigrationEnabled"

#-- 35 Check Integraton Services 
# 35 $Commands[0] = "get-vm *"
# 35 $Output = "ft ComputerName, vmname, IntegrationServicesState, IntegrationServicesVersion"

#-- 36 Move all roles, disks from current server to best possible node, pause current node, resume current node
# 36 $Commands[0] = 'get-clustergroup | where {$_.OwnerNode -eq $Server} | Move-clustervirtualMachineRole'
# 36 $Commands[1] = 'Get-ClusterSharedVolume | where {$_.OwnerNode -eq $server} | Move-ClusterSharedVolume'
# 36 $Commands[1] = 'suspend-clusternode $Server -Drain'
# 36 $Commands[1] = 'Resume-ClusterNode $Server -Failback Immediate'

#-- 37 Move VMs to specified cluster node 
# 37 $Commands[0] = 'get-clustergroup "app1","app2","app3" | Move-clustervirtualMachineRole -Node $Server'

#-- 38 Uninstall windows feature
# 38 Get-WindowsFeature | Where-Object {$_.InstallState -Eq “Available”} | Uninstall-WindowsFeature -Remove 

#-- 39 install SSC Serv
# 39 $Commands[0] = 'C:\users\usefree\Documents\SSCSERV361.msi'
# 39 $Commands[1] = '$hostname=$(hostname).tolower()'
# 39 $Commands[2] = '[guid]::NewGuid() | %{$Guid=$_.guid}'
# 39 $Commands[3] = 'New-Item -Path "HKLM:\Software\octo\SSC Serv\Graphite\$Guid"'
# 39 $Commands[4] = 'New-ItemProperty -Path "HKLM:\Software\octo\SSC Serv\Graphite\$Guid"-Name "Node" -Value "192.168.48.63" -Force'
# 39 $Commands[5] = 'New-ItemProperty -Path "HKLM:\Software\octo\SSC Serv\Graphite\$Guid"-Name "Service" -Value "2003" -Force'
# 39 $Commands[6] = 'New-ItemProperty -Path "HKLM:\Software\octo\SSC Serv\Graphite\$Guid"-Name "SeparateInstances" -Value "true" -Force'
# 39 $Commands[7] = 'New-ItemProperty -Path "HKLM:\Software\octo\SSC Serv\Graphite\$Guid"-Name "AlwaysAppendDS" -Value "false" -Force'
# 39 $Commands[8] = 'New-ItemProperty -Path "HKLM:\Software\octo\SSC Serv\Graphite\$Guid"-Name "StoreRates" -Value "true" -Force'
# 39 $Commands[9] = 'New-ItemProperty -Path "HKLM:\Software\octo\SSC Serv\Graphite\$Guid"-Name "Postfix" -Value "" -Force'
# 39 $Commands[10] = 'New-ItemProperty -Path "HKLM:\Software\octo\SSC Serv\Graphite\$Guid"-Name "Prefix" -Value "pm." -Force'
# 39 $Commands[11] = 'Set-ItemProperty -Path "HKLM:\Software\octo\SSC Serv"-Name "Hostname" -Value "ams.$hostname" -Force'
# 39 $Commands[12] = 'Set-ItemProperty -Path "HKLM:\Software\octo\SSC Serv\Graphite"-Name "Enabled" -Value "true" -Force'
# 39 $Commands[13] = 'start-service "SSC Service"'

#-- 40 register filebeat service
# 40 #$Commands[0] = 'New-Service -name "filebeat" -displayName "filebeat" -binaryPathName "`"C:\\Program Files\\Filebeat\\filebeat.exe`" -c `"C:\\Program Files\\Filebeat\\filebeat.yml`" -path.home `"C:\\Program Files\\Filebeat\\`" -path.data `"C:\\ProgramData\\filebeat`""'

#-- 41 find if software creates abnormal temp files with name FOX*
# 41 $Substr1 = 'get-childitem C:\Users\|%{if(test-path "c:\users\$_\AppData\Local\Temp"){$user=$_;$dir="c:\users\$_\AppData\Local\Temp\";get-childitem "$dir"}}|'
# 41 $Substr2 = '%{if (($_ -match "^[0-9][0-9]$")-or($_ -match "^[0-9]$")) {$subdir=$_;get-childitem "$dir$subdir"}} | '
# 41 $substr3 = '%{ $file=$_; if ($_ -match "FOX*"){get-childitem "$dir$subdir\$file" | %{$size=$_.Length}; '
# 41 $substr4 = ' if ($size -gt 1900000000) {write-host "$dir$subdir\$file" $size $user}}}'
# 41 $Commands[0] = $Substr1 + $Substr2 + $Substr3 + $substr4

#-- 42 check if update (hotfix) installed
# 42 $Commands[0] = 'New-Object -ComObject Microsoft.Update.Session | %{$_.createupdatesearcher()} | %{$_.queryhistory(0,$_.gettotalhistorycount())} | %{if($_.Title.ToString().Contains("3019215")){echo $_}}'

#--43 find events in system journal for users, that exceeded disk quota

# 43 $Substr1 = 'get-winevent -logname "system" | where-object {($_.id -eq 37) -and ($_.providername -eq "Ntfs")}|'
# 43 $Substr2 = '%{$objsid=new-object system.security.principal.securityidentifier($_.userid); '
# 43 $Substr3 = '$objuser=$objsid.translate([system.security.principal.ntaccount]); write-host $_.machinename " " $_.timecreated " " $objuser " " $_.Message}'
# 43 $Commands[0] = $Substr1 + $Substr2 + $Substr3

# 44 $Commands[0] = 'Get-NetAdapter'
# 44 $Output = " ft PSComputerName, ifAlias, InterfaceDescription"

# 45 $Commands[0] = 'Invoke-GPUpdate -force'
# 45 $Commands[1] = 'gpupdate /force'

# 46 get cpu frequency
# 46 $Commands[0] = '(get-wmiobject Win32_Processor | select-object -first 1).MaxClockSpeed'

# 47 find name by sid draft
# $Commands[0] = '$objSID = New-Object System.Security.Principal.SecurityIdentifier ("S-1-5-21-3979673632-2343654964-3717600413-7770")'
# $Commands[1] = '$objUser = $objSID.Translate( [System.Security.Principal.NTAccount]); $objUser.Value'





