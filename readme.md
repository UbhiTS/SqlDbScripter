# Sql Database Scripter
Easily script a SQL Server Database (objects and data) and recreate them with the correct sequence and dependencies of objects on the same or different server

This utility extends the functionality of the SQL Generate Scripts task. You will notice that if you generate the scripts and output to a single file, you can execute on the target server and everything will execute well and without warnings or errors. However, if you output to multiple files, you have to make sure that you execute the files in the correct sequence or you may get errors and warnings.

With this utility, you can create scripts of all objects in seperate files and with the output a CSV file is generated which defines the sequence of the objects to be executed on the target server.

## There can be multiple benefits of this approach :-

- ### SQL Server Source Control
  - If on every release you snapshot the golden/vanilla database with the Sql Database Scripter utility and check-in the generated output files into any source control like SVN, TFS etc, you can achieve SQL Database Source Code easily.

- ### Move Databases to a new DB Server
  - You can script the databases on the source server and then execute the scripts on a new target server. You can also change the database names during this process

- ### Merge Multiple Databases
  - You can script out the databases into source files and then on the target server give the same target database name for all source databases

## Usage
1. Edit the 01-SQLDbScripter.ps1 script parameters and run in powershell
the dbnames parameter defines the sequence and the names of the databases to script on the source server
```
$SourceServer = "<sqldbserver>"
$DBUsername = "<sqlusername>"
$DBPassword = "<sqlpassword>"
$TargetDBFiles = "C:\DBScripts\" + $SourceServer
$dbnames = @(
"db1", 
"db2", 
"db3", 
"db4")
```

2. When the above script run completes, you can edit the 02-SQLDbInstaller.ps1 script and execute
the DBDict parameter defines the sequence and the names of the database to execute on the target server
you can merge all databases into one by specifying 1 target for all source databases
```
$TargetServer = "<sqldbserver>"
$DBUsername = "<sqlusername>"
$DBPassword = "<sqlpassword>"
$SourceDBFiles = "C:\DBScripts\<SourceFilesPath>"
$DBDict = [ordered]@{
"db1"="db1"; # source database name and target database names are same
"db2"="new_db2"; # source database name is recreated with different name
"db3"="merged_db"; # multiple source databases are merged into target database
"db4"="merged_db"; # multiple source databases are merged into target database
}
```

I hope this script helps you, you comments are welcome and appreciated if you find this script useful
