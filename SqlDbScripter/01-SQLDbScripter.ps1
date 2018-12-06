<#
.SYNOPSIS
  SQL Database Scripter
.DESCRIPTION
  Easily script SQL Server Database(s) (objects and data) and recreate them with the correct dependencies and sequence of objects
.NOTES
  Version:        1.0
  Author:         UbhiTS
  Creation Date:  12/5/2018
#>

# load needed assemblies 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMOExtended")| Out-Null; 

# script parameters
$SourceServer = "<sqldbserver>"
$DBUsername = "<sqlusername>"
$DBPassword = "<sqlpassword>"
$TargetDBFiles = "C:\DBScripts\" + $SourceServer

# the sequence and the names of the databases to script on the source server
$dbnames = @(
"db1", 
"db2", 
"db3", 
"db4")

$SMOserver = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList "$SourceServer"
$SMOserver.ConnectionContext.LoginSecure = $false
$SMOserver.ConnectionContext.set_Login($DBUsername)
$SMOserver.ConnectionContext.set_Password($DBPassword)
$databases = $SMOserver.Databases

if (-not (Test-Path "$TargetDBFiles")) {
    new-item -type directory -path "$TargetDBFiles" | Out-Null
}

# script database-level objects.
foreach ($db in $databases)
{
    if ($db.Name -notin $dbnames) { continue }

    "$db"

    $DatabaseObjects = $db.ApplicationRoles
    $DatabaseObjects += $db.Assemblies
    $DatabaseObjects += $db.ExtendedStoredProcedures
    $DatabaseObjects += $db.ExtendedProperties
    $DatabaseObjects += $db.PartitionFunctions
    $DatabaseObjects += $db.PartitionSchemes
    $DatabaseObjects += $db.Roles
    $DatabaseObjects += $db.Rules
    $DatabaseObjects += $db.Schemas
    $DatabaseObjects += $db.StoredProcedures
    $DatabaseObjects += $db.Synonyms
    $DatabaseObjects += $db.Tables
    $DatabaseObjects += $db.Triggers
    $DatabaseObjects += $db.UserDefinedAggregates
    $DatabaseObjects += $db.UserDefinedDataTypes
    $DatabaseObjects += $db.UserDefinedFunctions
    $DatabaseObjects += $db.UserDefinedTableTypes
    $DatabaseObjects += $db.UserDefinedTypes
    $DatabaseObjects += $db.Users
    $DatabaseObjects += $db.Views

    # create root database folder
    $DatabaseSavePath = $TargetDBFiles + "\" + $db.Name
    $CSVFileName = $db.Name + ".csv"

    if (-not (Test-Path "$DatabaseSavePath\Data")) {
        new-item -type directory -name "Data"-path "$DatabaseSavePath" | Out-Null
    }

    # create sequence csv file
    & sqlcmd -S $SourceServer -U $DBUsername -P $DBPassword -d $db.Name -x -I -i "$PSScriptRoot\Sqls\SET_NOCOUNT_ON.sql,$PSScriptRoot\Sqls\OBJECT_SEQUENCE.sql" -o "$DatabaseSavePath\$CSVFileName" -s"," -W -h-1 # -I for QUOTED_IDENTIFIERS, -x for $ symbol in INSERTS

    # script all objects in database
    foreach ($DatabaseObject in $DatabaseObjects | where {!($_.IsSystemObject)}) 
    {
        # drop options
        $ScriptDrop = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
        $ScriptDrop.Options.AppendToFile = $False
        $ScriptDrop.Options.AllowSystemObjects = $False
        $ScriptDrop.Options.ClusteredIndexes = $False
        $ScriptDrop.Options.DriAll = $False
        $ScriptDrop.Options.SchemaQualify = $False
        $ScriptDrop.Options.ScriptDrops = $True
        $ScriptDrop.Options.ScriptData = $False
        $ScriptDrop.Options.ScriptSchema = $True
        $ScriptDrop.Options.IncludeDatabaseContext = $False
        $ScriptDrop.Options.IncludeHeaders = $False
        $ScriptDrop.Options.IncludeIfNotExists = $True
        $ScriptDrop.Options.Indexes = $False
        $ScriptDrop.Options.ClusteredIndexes = $False
        $ScriptDrop.Options.NonClusteredIndexes = $False
        $ScriptDrop.Options.NoCollation = $True
        $ScriptDrop.Options.ToFileOnly = $True
        $ScriptDrop.Options.Permissions = $False
        $ScriptDrop.Options.WithDependencies = $False

        # create options
        $ScriptCreate = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
        $ScriptCreate.Options.AppendToFile = $True
        $ScriptCreate.Options.AllowSystemObjects = $False
        $ScriptCreate.Options.ClusteredIndexes = $True
        $ScriptCreate.Options.DriAll = $True
        $ScriptCreate.Options.SchemaQualify = $False
        $ScriptCreate.Options.ScriptDrops = $False
        $ScriptCreate.Options.ScriptData = $False
        $ScriptCreate.Options.ScriptSchema = $True
        $ScriptCreate.Options.IncludeDatabaseContext = $False
        $ScriptCreate.Options.IncludeHeaders = $True
        $ScriptCreate.Options.IncludeIfNotExists = $False
        $ScriptCreate.Options.Indexes = $True
        $ScriptCreate.Options.ClusteredIndexes = $True
        $ScriptCreate.Options.NonClusteredIndexes = $True
        $ScriptCreate.Options.NoCollation = $True
        $ScriptCreate.Options.ToFileOnly = $True
        $ScriptCreate.Options.Permissions = $True
        $ScriptCreate.Options.WithDependencies = $False

        # data options
        $ScriptData = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
        $ScriptData.Options.ScriptDrops = $False
        $ScriptData.Options.ScriptData = $True
        $ScriptData.Options.ScriptSchema = $False
        $ScriptData.Options.ToFileOnly = $True
        $ScriptData.Options.SchemaQualify = $False

        # build folder structures
        $TypeFolder=$DatabaseObject.GetType().Name

        # for tables we need to qualify with dbo schema, this section can be removed or edited as needed
        if ($TypeFolder -eq "Table") {
            $ScriptDrop.Options.SchemaQualify = $True
            $ScriptCreate.Options.SchemaQualify = $True
            $ScriptData.Options.SchemaQualify = $True
        }

        if (-not (Test-Path "$DatabaseSavePath\$TypeFolder")) {
            new-item -type directory -name "$TypeFolder" -path "$DatabaseSavePath" | Out-Null
        }

        "`t $TypeFolder $DatabaseObject"

        # set filename
        $ScriptFile = $DatabaseObject -replace ":", "-" -replace "\\", "-" -replace "\[", "" -replace "\]", ""
        
        $ScriptDrop.Options.FileName = $DatabaseSavePath + "\" + $TypeFolder + "\" + $ScriptFile + ".sql"
        $ScriptCreate.Options.FileName = $DatabaseSavePath + "\" + $TypeFolder + "\" + $ScriptFile + ".sql"
        $ScriptData.Options.FileName = $DatabaseSavePath + "\Data\" + $ScriptFile + ".sql"

        # script the actual object
        $ScriptDrop.Script($DatabaseObject)
        $ScriptCreate.Script($DatabaseObject)
        
        # if table then script the data, this is the specific way to extract data only
        # https://gist.github.com/andrerocker/655819
        if ($TypeFolder -eq "Table") {
            $ScriptData.enumScript($DatabaseObject)
        }
    }
}

write-host
write-host "Script Generation Sequence Complete !"