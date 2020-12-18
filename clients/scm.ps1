function ROpenSCManagerW
{
    <#
    .SYNOPSIS

    PROOF OF CONCEPT - WORK IN PROGRESS
    
    .DESCRIPTION

    The ROpenSCManagerW method establishes a connection to server and opens the SCM database on the specified server.

    .PARAMETER MachineName

    Server's machine name

    .PARAMETER NetworkAddress

    Server's IP Address

    .PARAMETER DatabaseName
    
    The parameter MUST be set to NULL, "ServicesActive", or "ServicesFailed"

    .PARAMETER DesiredAccess

    A value that specifies the access to the database.
    
    SERVICE_ALL_ACCESS - 0x000F01FF: In addition to all access rights in this table, SERVICE_ALL_ACCESS includes Delete (DE), Read Control (RC), Write DACL (WD), and Write Owner (WO) access, as specified in ACCESS_MASK (section 2.4.3) of [MS-DTYP].
    SERVICE_CHANGE_CONFIG - 0x00000002: Required to change the configuration of a service.
    SERVICE_ENUMERATE_DEPENDENTS - 0x00000008: Required to enumerate the services installed on the server.
    SERVICE_INTERROGATE - 0x00000080: Required to request immediate status from the service.
    SERVICE_PAUSE_CONTINUE - 0x00000040: Required to pause or continue the service.
    SERVICE_QUERY_CONFIG - 0x00000001: Required to query the service configuration.
    SERVICE_QUERY_STATUS - 0x00000004: Required to request the service status.
    SERVICE_START - 0x00000010: Required to start the service.
    SERVICE_STOP - 0x00000020: Required to stop the service.
    SERVICE_USER_DEFINED_CONTROL - 0x00000100: Required to specify a user-defined control code.
    SERVICE_SET_STATUS - 0x00008000: Required for a service to set its status.
    
    Default 'SERVICE_ALL_ACCESS'.

    .NOTES

    Author: Roeberto Rodriguez (@Cyb3rWard0g)

    DWORD ROpenSCManagerW(
        [in, string, unique, range(0, SC_MAX_COMPUTER_NAME_LENGTH)] 
        SVCCTL_HANDLEW lpMachineName,
        [in, string, unique, range(0, SC_MAX_NAME_LENGTH)] 
        wchar_t* lpDatabaseName,
        [in] DWORD dwDesiredAccess,
        [out] LPSC_RPC_HANDLE lpScHandle
    );

    .LINK

    https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-scmr/dc84adb3-d51d-48eb-820d-ba1c6ca5faf2

    .EXAMPLE

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('HostName')]
        [String] $MachineName,

        [String] $NetworkAddress,
        
        [ValidateSet('ServicesActive','ServicesFailed')]
        [string] $DatabaseName = 'ServiceActive',
        
        [ValidateSet('SERVICE_ALL_ACCESS', 'SERVICE_QUERY_STATUS', 'SERVICE_START', 'SERVICE_STOP', 'SERVICE_QUERY_CONFIG', 'SERVICE_CHANGE_CONFIG')]
        [String]$DesiredAccess  = 'SERVICE_ALL_ACCESS'
    )

    $Access = Switch ($DesiredAccess) {
        'SERVICE_ALL_ACCESS' { 0x000F01FF }
        'SERVICE_QUERY_STATUS' { 0x00000004 }
        'SERVICE_START' { 0x00000010 }
        'SERVICE_STOP' { 0x00000020 }
        'SERVICE_QUERY_CONFIG' { 0x00000001 }
        'SERVICE_CHANGE_CONFIG' { 0x00000002 }
    }

    Import-Module NtObjectManager
    $scmServer = Get-RpcServer C:\Windows\System32\services.exe -DbgHelpPath 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\dbghelp.dll'
    $scmClient = Get-RpcClient $scmServer[0]

    Connect-RpcClient -Client $scmClient -EndpointPath "\pipe\svcctl" -ProtocolSequence ncacn_np -NetworkAddress $NetworkAddress -SecurityQualityOfService $(New-NtSecurityQualityOfService -ImpersonationLevel Identification)
    $result = $scmClient.ROpenSCManagerW($MachineName,$DatabaseName,$Access)

    # Handle results
    if ($result.retval -ne 0) {
        $ex = [System.ComponentModel.Win32Exception]::new($result.retval)
        throw $ex
    }
    else{
        $result.p3
    }
}