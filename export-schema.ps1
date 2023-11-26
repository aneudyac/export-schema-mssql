# Usage: powershell ExportSchema.ps1 "SERVERNAME" "DATABASE" "C:\<YourOutputPath>"

# Start Script
Set-ExecutionPolicy RemoteSigned

function GenerateDBScript([string]$serverName, [string]$dbname, [string]$scriptpath)
{
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("System.Data") | Out-Null
    $srv = new-object "Microsoft.SqlServer.Management.SMO.Server" $serverName
    $srv.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject")
    # $db = $srv.Databases[$dbname]
    $scr = New-Object "Microsoft.SqlServer.Management.Smo.Scripter"
    $deptype = New-Object "Microsoft.SqlServer.Management.Smo.DependencyType"
    $scr.Server = $srv
    $options = New-Object "Microsoft.SqlServer.Management.SMO.ScriptingOptions"
    $options.AllowSystemObjects = $false
    $options.IncludeDatabaseContext = $true
    $options.IncludeIfNotExists = $false
    $options.ClusteredIndexes = $true
    $options.Default = $true
    $options.DriAll = $true
    $options.Indexes = $true
    $options.NonClusteredIndexes = $true
    $options.IncludeHeaders = $false
    $options.ToFileOnly = $true
    $options.AppendToFile = $true
    $options.ScriptDrops = $false

    # Set options for SMO.Scripter
    $scr.Options = $options

    $pc =  Get-CIMInstance CIM_ComputerSystem

    $serverPath = Join-Path -Path $scriptpath -ChildPath $pc.Name
    New-Item -Path $serverPath -ItemType Directory -Force | Out-Null

    foreach($db in $srv.Databases | Where-Object{ $_.IsAccessible -and !$_.IsSystemObject -and ($_.Name -eq $dbname -or [string]::IsNullOrEmpty($dbname))}) {
        Write-Output "Database: $($db)"

        $databasePath = Join-Path -Path $serverPath -ChildPath $db.Name
        New-Item -Path $databasePath -ItemType Directory -Force | Out-Null

        # Create a subfolder for each schema
        $schemas = $db.Schemas | Where-Object { $_.IsSystemObject -eq $false }
        foreach ($schema in $schemas) {
            Write-Output "Schema: $($schema)"

            $schemaPath = Join-Path -Path $databasePath -ChildPath $schema.Name
            New-Item -Path $schemaPath -ItemType Directory -Force | Out-Null

            $tablesPath = Join-Path -Path $schemaPath -ChildPath "Tables"
            New-Item -Path $tablesPath -ItemType Directory -Force | Out-Null
        
            # Tables
            foreach ($tb in $db.Tables) {
                if ($tb.IsSystemObject -eq $FALSE -and "[$($tb.Schema)]" -eq $schema) {
                    Write-Output "$($schema)--$($tablesPath)\$($tb.Schema).$($tb.Name)"
                    $options.FileName = Join-Path -Path $tablesPath -ChildPath "$($tb.Name).sql"
                    New-Item $options.FileName -type file -force | Out-Null
                    $smoObjects = New-Object Microsoft.SqlServer.Management.Smo.UrnCollection
                    $smoObjects.Add($tb.Urn)
                    $scr.Script($smoObjects)
                }
            }

            $viewsPath = Join-Path -Path $schemaPath -ChildPath "Views"
            New-Item -Path $viewsPath -ItemType Directory -Force | Out-Null

            # Views
            foreach ($view in $db.Views) {
                if ($view.IsSystemObject -eq $FALSE -and "[$($view.Schema)]" -eq $schema) {
                    Write-Output "$($schema)--$($viewsPath)\$($view.Schema).$($view.Name)"
                    $options.FileName = Join-Path -Path $viewsPath -ChildPath "$($view.Name).sql"
                    New-Item $options.FileName -type file -force | Out-Null
                    $scr.Script($view)
                }
            }

            $storedProceduresPath = Join-Path -Path $schemaPath -ChildPath "StoredProcedures"
            New-Item -Path $storedProceduresPath -ItemType Directory -Force | Out-Null

            # StoredProcedures
            foreach ($StoredProcedure in $db.StoredProcedures) {
                if ($StoredProcedure.IsSystemObject -eq $FALSE -and "[$($StoredProcedure.Schema)]" -eq $schema) {
                    Write-Output "$($schema)--$($storedProceduresPath)\$($StoredProcedure.Schema).$($StoredProcedure.Name)"
                    $options.FileName = Join-Path -Path $storedProceduresPath -ChildPath "$($StoredProcedure.Name).sql"
                    New-Item $options.FileName -type file -force | Out-Null
                    $scr.Script($StoredProcedure)
                }
            }

            $functionsPath = Join-Path -Path $schemaPath -ChildPath "Functions"
            New-Item -Path $functionsPath -ItemType Directory -Force | Out-Null

            # Functions
            foreach ($function in $db.UserDefinedFunctions) {
                if ($function.IsSystemObject -eq $FALSE -and "[$($function.Schema)]" -eq $schema) {
                    Write-Output "$($schema)--$($functionsPath)\$($StoredProcedure.Schema).$($StoredProcedure.Name)"
                    $options.FileName = Join-Path -Path $functionsPath -ChildPath "$($function.Name).sql"
                    New-Item $options.FileName -type file -force | Out-Null
                    $scr.Script($function)
                }
            
            }

            $triggersPath = Join-Path -Path $schemaPath -ChildPath "Triggers"
            New-Item -Path $tablesPath -ItemType Directory -Force | Out-Null

            # DBTriggers
            foreach ($trigger in $db.Triggers) {
                Write-Output "$($schema)--$($triggersPath)\$($trigger.Schema).$($trigger.Name)"
                $options.FileName = Join-Path -Path $triggersPath -ChildPath "$($trigger.Name).sql"
                New-Item $options.FileName -type file -force | Out-Null
                $scr.Script($trigger)
            }

            # Table Triggers
            foreach ($tb in $db.Tables) {
                foreach ($trigger in $tb.triggers) {
                    $options.FileName = Join-Path -Path "$($tb.Name)_$($trigger.Name)" -ChildPath "$($trigger.Name).sql"
                    New-Item $options.FileName -type file -force | Out-Null
                    $scr.Script($trigger)
                }
            }
        }
    }
}

# Execute
$instance = "localhost"
$database = ""
# $sqluser = ""
# $sqlpass = ""
# $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $instance, $sqluser, $sqlpass
# $server = New-Object Microsoft.SqlServer.Management.SMO.Server -ArgumentList $conn


# If $database is null or empty, then retrieve all database from the server
GenerateDBScript $instance "$database" "C:\Temp"
