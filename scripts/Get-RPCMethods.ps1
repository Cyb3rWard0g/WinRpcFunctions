# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]$DbgHelpDllPath,

    [parameter(Mandatory=$true)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [switch]$CurrentProcesses = $false
)

# Validate Paths
$DbgHelpDllPath = Resolve-Path $DbgHelpDllPath -ErrorAction Stop
$OutputPath = Resolve-Path $OutputPath -ErrorAction Stop

# Importing NTObjectManager Module
Import-Module NtObjectManager -Scope Local

# *****************
# Collect Modules *
# *****************

# Extract Modules either from current Processes or directly from every .dll or .exe in SYSTEM32 
if ($CurrentProcesses){
    write-host "[+] Collecting modules loaded by currently running processes"
    $allModules = Get-Process | Where-Object {$_.ProcessName -ne 'Code'} | ForEach-Object {$_.Modules} | Select-Object -ExpandProperty FileName | sort -Unique
}
else{
    Write-Host "[+] Collecting modules from SYSTEM32"
    $allModules = Get-ChildItem "$env:windir\system32\*" -Include "*.dll","*.exe"
}

# *********************
# Extract RPC Servers *
# *********************

$allRpcFunctions = @()

write-host "[+] Parsing RPC Servers from modules"
$modRpcServers = $allModules | Get-RpcServer -DbgHelpPath $dbghelpDllPath
# Loop through every RPCServers results
foreach ($server in $modRpcServers) {
    write-host "  [>] Processing" $server.Name "results"
    # Creating folders for RPC interfaces
    write-host "    [>>] Creating" $server.Name "folder"
    if (!(Test-Path $OutputPath\$($server.Name))){
        New-Item -ItemType Directory -Force -Path $OutputPath\$($server.Name) | out-null
    }
    # Output RPC Server interfaces to JSON Files
    write-host "    [>>] Exporting all RPC functions to JSON file"
    $server.Procedures | ConvertTo-Json | Out-File $OutputPath\$($server.Name)\$($server.InterfaceId).json
    # Iterate over each RPC Function mapped to the RPC Interface
    foreach ($procedure in $server.Procedures) {
        write-host "    [>>] Processing "$procedure.Name "RPC function"
        # Creating a Procedure object to append to an array
        $rpcFuncObject = [pscustomobject] @{
            Module   = $server.Name
            ModulePath = $server.FilePath
            InterfaceId = $server.InterfaceId
            InterfaceStructOffset = $server.Offset
            ProceduresCount = $server.ProcedureCount
            Procedure = $procedure.Name
            ProcNum = $procedure.ProcNum
            ProcStackSize = $procedure.StackSize
            DispatchFunction = $procedure.DispatchFunction
            Service = $server.ServiceName
            IsServiceRunning = $server.IsServiceRunning
        }
        $allRpcFunctions += $rpcFuncObject
    }
}

# ****************
# Export Results *
# ****************

write-host "[+] Exporting all results"
# Export all RPC Servers with functions and virtual addresses
$allRpcFunctions | ConvertTo-Json -Compress | Out-File "$OutputPath\allRPCFunctions.json"

# Export all unique modules to text file. useful to integrate with Ghidra imports and headless analyzer
$allRpcFunctions | Select-Object -ExpandProperty ModulePath | sort -Unique | Out-File -append "$OutputPath\allModules.txt"