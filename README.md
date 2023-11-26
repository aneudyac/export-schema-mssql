# export-schema-mssql
This repository hosts a PowerShell script designed to streamline the process of generating SQL Server database scripts. The script organizes the resulting SQL scripts into a structured hierarchy based on the database schema, object type, and object name.

## Features
- Structured Scripting: The PowerShell script generates SQL scripts and organizes them into a folder structure following the pattern {Schema}\{ObjectType}\{ObjectName}.sql.
- Versatility: The script covers various database object types, including tables, views, stored procedures, functions, and triggers.

## Usage
1. Clone this repository to your local machine.
2. Execute the PowerShell script, providing the necessary parameters such as server name, database name, and output path.

```powershell

# Example usage:
# powershell export-schema.ps1 "SERVERNAME" "DATABASE" "C:\<YourOutputPath>"
```


## Requirements
- Microsoft SQL Server Management Objects (SMO) library.

  
## Contributions
Feel free to contribute to the development of this script by opening issues, providing suggestions, or submitting pull requests. Your input is valuable in making this tool even more robust and efficient.
