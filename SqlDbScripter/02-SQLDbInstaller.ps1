<#
.SYNOPSIS
  SQL Database Script Executer
.DESCRIPTION
  Execute database scripts generated with the SQL Database Scripter utility
.NOTES
  Version:        1.0
  Author:         UbhiTS
  Creation Date:  12/5/2018
#>

# script parameters
$TargetServer = "<sqldbserver>"
$DBUsername = "<sqlusername>"
$DBPassword = "<sqlpassword>"
$SourceDBFiles = "C:\DBScripts\<SourceServerSavePath>"

# the sequence and the names of the database to execute on the target server
# you can even merge all databases into one by specifying 1 target for all source databases
# source db -> target db
$DBDict = [ordered]@{
"db1"="db1"; # source database name and target database names are same
"db2"="new_db2"; # source database name is recreated with different name
"db3"="merged_db"; # multiple source databases are merged into target database
"db4"="merged_db"; # multiple source databases are merged into target database
}

foreach ($key in $DbDict.Keys) {

    $SourceDBName = $key
    $TargetDBName = $DBDict[$key]

    $TargetUsername = $DBUsername
    $TargetPassword = $DBPassword  

    $SourceDBFilesPath = $SourceDBFiles + "\" + $SourceDBName

    if (-not (Test-Path $SourceDBFilesPath)) {
        continue
    }

    write-host $SourceDBName -> $TargetDBName" ("$TargetUsername")"

    $ftype = @("*.sql")
    $filesToExecute = Get-ChildItem -Path $SourceDBFilesPath\* -Include $ftype -Recurse | Sort-Object -Descending # sorting to execute the table files before the data
    $ObjectSequencePath = $SourceDBFilesPath + "\" + $SourceDBName + ".csv"

    $filesSequence = Import-Csv -Header id,entity $ObjectSequencePath
    $filesSequence | % { $_.id = [int]$_.id }
    $filesSequence | Sort-Object id | Out-Null

    foreach ($file in $filesSequence) {
        foreach ($sqlfile in $filesToExecute) {
            if ($sqlfile.FullName.ToLower().Contains(-join(".",$file.entity.ToLower(),"."))) {
                if ((Get-Item $sqlfile).length -gt 2) { # this is to not run empty files (specifically for data)
                    write-host $file.id - $sqlfile
                    & sqlcmd -S $TargetServer -U $TargetUsername -P $TargetPassword -d $TargetDBName -x -I -i "$PSScriptRoot\Sqls\SET_NOCOUNT_ON.sql,$sqlfile" # -I for QUOTED_IDENTIFIERS, -x for $ symbol in INSERTS
                }
                continue
            }
        }
    }
}

write-host
write-host "Deployment Sequence Complete !"