[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"
$ipaddress=$(Get-NetIPAddress | Where-Object {$_.IPAddress -Like "192.168.16.7*"}).IPAddress
$slackMessage = "MSSQL $ipaddress backup to S3 Stage s3/backup OK"
$Check_if_primary_Answer = 0
$BackupsFolder="F:\Backups"
$body = ConvertTo-Json @{
pretext = "Backup OK"
text = $slackMessage
color = "#0FF522"}
$uriSlack = "https://hooks.slack.com/services/"

function TryRun-Sql
{
[CmdletBinding()]
param(
[parameter(Mandatory=$false)][string]$file,
[parameter(Mandatory=$false)][string]$sql,
[parameter(Mandatory=$true, Position=1)][string]$instance,
[parameter(Mandatory=$true, Position=2)][string]$database,
[parameter(Mandatory=$false, Position=3)][ref]$message)
    $error.clear()
    try
    {
        if($file -ne $null -and $file -ne "")
        {
            $tempFile = Join-Path $env:TEMP 'temp.sql'
            Copy-Item $file $tempFile
            $query = get-content $tempFile
            $query= $query -join "`n"
            $query | Out-File -FilePath $tempFile -Encoding UTF8 -force            
            return invoke-sqlcmd -serverinstance $instance -InputFile $tempFile -Database $database -ErrorAction Stop
        }
        else
        {
            return invoke-sqlcmd $sql -serverinstance $instance -Database $database -ErrorAction Stop -QueryTimeout 3000
        }
    }
    catch
    {
        if($message -ne $null)
        {
            $message.Value = $error
        }
        return $null
    }
}

function Check_if_primary
{
[CmdletBinding()]
param(
[parameter(Mandatory=$true)][string]$dbInstance,
[parameter(Mandatory=$true)][string]$DataBase)

    $sql = @"
    SELECT sys.fn_hadr_is_primary_replica ('$DataBase') as Issmaster;  
    GO 
"@

    Write-Debug $sql
    $errorMessage = ""
    $Answer = TryRun-Sql -sql $sql -instance $dbInstance -database "master" -message ([ref]$errorMessage)
    if($errorMessage -ne "")
    {
        $tErr = "Check error: $errorMessage"
        Write-Error $tErr
        throw $tErr
    }
    $isMaster=$Answer.Issmaster
    return $isMaster
}

$Check_if_primary_Answer=Check_if_primary -dbInstance $ipaddress -DataBase "Test"
if ($Check_if_primary_Answer -eq 1) {
    Write-Debug "ismaster"
    if ( (get-childitem $BackupsFolder -recurse | where-object { ((get-date)-$_.creationTime).days -le 0 }).Length -eq 0) {
      $slackMessage = "MSSQL $ipaddress backup was not created on primary node!"
	    $body = ConvertTo-Json @{
	    pretext = "Backup failed"
	    text = $slackMessage
	    color = "#0FF522"}
      Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json'  | Out-Null
    } else {
        try {
	        aws s3 sync $BackupsFolder s3://backup/
        } 
        catch {
	        $slackMessage = "MSSQL $ipaddress backup to S3 Stage s3/backup failed"
	        $body = ConvertTo-Json @{
	        pretext = "Backup failed"
	        text = $slackMessage
	        color = "#0FF522"}
          Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json'  | Out-Null
        }
    }
} else {Write-Debug "notmaster"} 
