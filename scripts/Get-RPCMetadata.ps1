# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: MIT

function Get-RPCMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$DbgHelpDllPath,

        [parameter(Mandatory=$true)]
        [string]$OutputPath,

        [Parameter(Mandatory=$false)]
        [switch]$CurrentProcesses = $false,

        [Parameter(Mandatory=$false)]
        [ValidateSet("json","yaml")]
        [string]$Format = 'json'
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
        $allModules = Get-Process | Where-Object {$_.ProcessName -ne 'Code'} | ForEach-Object {$_.Modules} | Select-Object -ExpandProperty FileName | Sort-Object -Unique
    }
    else {
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
        write-host "    [>>] Creating $($server.InterfaceId) folders"
        if (!(Test-Path $OutputPath\$($server.Name)\$($server.InterfaceId))){
            New-Item -ItemType Directory -Force -Path $OutputPath\$($server.Name)\$($server.InterfaceId) | out-null
        }

        # RPC Endpoint folder
        if ($server.EndpointCount -ge 1) {
            write-host "      [>>] Creating endpoint folder"
            New-Item -ItemType Directory -Force -Path "$OutputPath\$($server.Name)\$($server.InterfaceId)\endpoints" | out-null
        }
        # RPC Procedure folder
        if ($server.ProcedureCount -ge 1) {
            write-host "      [>>] Creating procedures folder"
            New-Item -ItemType Directory -Force -Path "$OutputPath\$($server.Name)\$($server.InterfaceId)\procedures" | out-null
        }

        # Creating RPC Server file
        $rpcServer = [ordered]@{
            id = $server.InterfaceId
            label = "$($server.InterfaceId) RPC Server"
            typeOf = "RPCServer"
            attributes = [ordered] @{
                interface_id = $server.InterfaceId
                module = $server.Name
                module_path = $server.FilePath
                procedure_count = $server.ProcedureCount
                endpoint_count = $server.EndpointCount
            }
        }

        # Output JSON or YAML
        write-host "    [>>] Creating RPC Server file in $Format format.."
        if ($Format -eq 'json') {
            $rpcServer | ConvertTo-Json | Out-File "$OutputPath\$($server.Name)\$($server.InterfaceId)\$($server.InterfaceId).json"
        }
        else {
            $rpcServer | ConvertTo-Yaml | Out-File "$OutputPath\$($server.Name)\$($server.InterfaceId)\$($server.InterfaceId).yaml"
        }

        write-host "    [>>] Exporting all RPC procedures as $Format format"
        # Iterate over each RPC procedure mapped to the RPC Interface
        foreach ($procedure in $server.Procedures) {
            write-host "    [>>] Processing $($procedure.Name) RPC procedure"
            # Creating a Procedure object to append to an array
            $rpcProcedureObject = [ordered] @{
                id = $procedure.Name
                label = "$($procedure.Name) RPC Call"
                typeOf = "RPCProcedure"
                attributes = [ordered] @{
                    name = $procedure.Name
                    procnum = $procedure.ProcNum
                    module_name = $server.Name
                    module_path = $server.FilePath
                    interface_id = $server.InterfaceId
                }
            }
            $allRpcFunctions += $rpcProcedureObject

            # Creating RPC procedures files
            $procedureFileName = $procedure.Name
            if ($Format -eq 'json') {
                $rpcProcedureObject | ConvertTo-Json | Out-File "$OutputPath\$($server.Name)\$($server.InterfaceId)\procedures\$($procedureFileName).json"
            }
            else {
                $rpcProcedureObject | ConvertTo-Yaml | Out-File "$OutputPath\$($server.Name)\$($server.InterfaceId)\procedures\$($procedureFileName).yaml"
            }
        }

        write-host "    [>>] Exporting all RPC endpoints as $Format format"
        foreach ($endpoint in $server.Endpoints) {
            write-host "    [>>] Processing $($procedure.Name) RPC endpoint"
            # Creating a Procedure object to append to an array
            $rpcEndpointObject = [ordered] @{
                id = "$($server.InterfaceId)_$($endpoint.Endpoint.Replace('\s+', '_').Replace('\','_'))"
                label = "$($endpoint.BindingString) RPC Endpoint"
                typeOf = "RPCEndpoint"
                attributes = [ordered] @{
                    binding_string = $endpoint.BindingString
                    name = $endpoint.Endpoint
                    path = $endpoint.EndpointPath
                    protocol_sequence = $endpoint.Protocol
                    annotation = $endpoint.Annotation
                    interface_id = $server.InterfaceId
                }
            }

            # Creating RPC endpoint files
            $endpointFileName = $endpoint.Endpoint.Replace('\s+', '_').Replace('\','_')
            if ($Format -eq 'json') {
                $rpcEndpointObject | ConvertTo-Json | Out-File "$OutputPath\$($server.Name)\$($server.InterfaceId)\endpoints\$($endpointFileName).json"
            }
            else {
                $rpcEndpointObject| ConvertTo-Yaml | Out-File "$OutputPath\$($server.Name)\$($server.InterfaceId)\endpoints\$($endpointFileName).yaml"
            }
        }
    }

    # ****************
    # Export Results *
    # ****************

    write-host "[+] Exporting all results"
    # Export all RPC Servers with functions and virtual addresses
    $allRpcFunctions | ConvertTo-Json -Compress | Out-File "$OutputPath\allRPCFunctions.json"

    # Export all unique modules to text file. useful to integrate with Ghidra imports and headless analyzer
    $allRpcFunctions | ForEach-Object {$_.attributes.module_path} | Sort-Object -Unique | Out-File -append "$OutputPath\allModules.txt"
}