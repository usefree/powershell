param (
[string[]]$Servers
)
$Usage = "Usage: ./GetInstalledSoftwareList.ps1 [server_name1], [rdp], [app], [hosts], [test], [all]"

$CurrentDate = Get-date -UFormat "%Y_%m_%d_%H-%M"
$ResultFile = "C:\Users\usefree\Documents\scripts\SoftwareReport$CurrentDate.csv"

#------ Define arrays of server groups

$ArrayOfAppServers = @("app1","app2","app3")
$ArrayOfHostsServers = @("host1", "host2", "host3")
$ArrayOfRdpServers = @("rdp11", "rdp2")
$ArrayOfDBServers = @("db1","db2")
$ArrayOfOtherServers2 =@("appd", "appc", "BL-BO-MGMT")
$ArrayOfAllServers2 = $ArrayOfDBServers + $ArrayOfOtherServers2 + $ArrayOfRdpServers + `
                      $ArrayOfAppServers + $ArrayOfHostsServers
$ArrayOfTestServers = @("appf","app4","host4","db3","rdp3")
$ArrayOfServers = @()
$UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
$UninstallKey32 = "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
$array = @()

#------ / Variables 

#------ Compose list of servers

function ComposeListOfServers {
    Param (
    [string[]]$Servers
    )
    $TempArrayOfServers = @()
    if (-not $Servers) {
        Write-host "Error. Empty servers parameter"
        Write-host $Usage
        exit
    } else {
        foreach ($Variant in $Servers) {
            Switch ($Variant)
            {
                "all" { 
                    $TempArrayOfServers += $ArrayOfAllServers2
                    ; break
                    }
                "rdp"   { $TempArrayOfServers += $ArrayOfRdpServers}
                "app"   { $TempArrayOfServers += $ArrayOfAppServers}
                "hosts" { $TempArrayOfServers += $ArrayOfHostsServers}
                "test"  { $TempArrayOfServers += $ArrayOfTestServers}
                default {   $TempArrayOfAllServers += ($ArrayOfDBServers + `
                            $ArrayOfOtherServers2 + $ArrayOfRdpServers + `
                            $ArrayOfAppServers + $ArrayOfHostsServers)
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

#------ Check if list of servers composed right

if ( $Servers ) {
    $ArrayOfServers = ComposeListOfServers($Servers)
} else {
    Write-Host "Array of servers is not specified"
    Write-host $Usage
    exit
}
if ( -not $ArrayOfServers) {
    Write-Host "Array of servers specified incorrectly"
    Write-host $Usage
    exit
}

function GetSoftwareList {
    param (
        [string]$LocalUninstallKey,
        $CurrentArray
    )
    $equal = 0
#------ Create an instance of the Registry Object and open the HKLM base key

    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computername)

#------ Drill down into the Uninstall key using the OpenSubKey Method

    $regkey=$reg.OpenSubKey($LocalUninstallKey)

#------ Retrieve an array of string that contain all the subkey names
    $subkeys=$regkey.GetSubKeyNames()
    
#------ Open each Subkey and use GetValue Method to return the required values for each

    foreach($key in $subkeys){
        $thisKey=$LocalUninstallKey+"\\"+$key 
        $thisSubKey=$reg.OpenSubKey($thisKey) 
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $computername
        $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))
        $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))
        $obj | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value $($thisSubKey.GetValue("InstallLocation"))

#------ Prevent doubling of records

        foreach ($object in $CurrentArray){
            if (($object.DisplayName -eq $obj.DisplayName + ";") -and ($object.ComputerName -eq $obj.ComputerName + ";")) 
            {$equal = 1}
        }
        if (($equal -eq 0) -and ($obj.DisplayName)) {
            $obj.DisplayName = $obj.DisplayName +";"
            $obj.ComputerName = $obj.ComputerName +";"
            $obj.DisplayVersion = $obj.DisplayVersion +";"
            $obj.InstallLocation = $obj.InstallLocation +";"
            $CurrentArray += $obj
        } else {
            $equal = 0
        }
    } 
#------ Add blanc line between records of two servers   
    if ($LocalUninstallKey -eq "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall") {
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value " "
        $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value " "
        $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value " "
        $obj | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value " "
        $CurrentArray += $obj
    }
    return $CurrentArray
}

#---- Calling GetSoftwareList procedure only for reachable hosts

foreach($computername in $ArrayOfServers){
$connection = Test-Connection $computername -Count 1 -ErrorAction SilentlyContinue
        if ($connection -ne $null){
            write-host "$computername is reachable"
            $array = GetSoftwareList -LocalUninstallKey $UninstallKey -CurrentArray $array
            $array = GetSoftwareList -LocalUninstallKey $UninstallKey32 -CurrentArray $array
        }
        else {
            write-host "$computername is ANreachable" -ForegroundColor Red
        }    
}

#--- Writing to file 

$stream = [System.IO.StreamWriter] $ResultFile

foreach ($line in $array) {
    $subline = $line.ComputerName + $line.DisplayName + $line.DisplayVersion + $line.InstallLocation
    $stream.Writeline($subline)
}
$stream.close()

