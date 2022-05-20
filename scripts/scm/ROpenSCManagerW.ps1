function ROpenSCManagerW
{
    <#
    .SYNOPSIS

    The ROpenSCManagerW method establishes a connection to server and opens the SCM database on the specified server. (Opnum 15)

    Author: Roberto Rodriguez (@Cyb3rWard0g)

    .DESCRIPTION

    The ROpenSCManagerW method establishes a connection to server and opens the SCM database on the specified server. (Opnum 15)

    .PARAMETER MachineName

    Server's machine name

    .PARAMETER NetworkAddress

    Server's IP Address

    .PARAMETER DatabaseName
    
    The parameter MUST be set to NULL, "ServicesActive", or "ServicesFailed"

    .PARAMETER DesiredAccess

    A value that specifies the access to the SCM database.
    
    Access Rights for the Service Control Manager

    References:
    - https://docs.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights?redirectedfrom=MSDN
    - https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-scmr/0d7a7011-9f41-470d-ad52-8535b47ac282

    SC_MANAGER_ALL_ACCESS (0xF003F): Includes STANDARD_RIGHTS_REQUIRED, in addition to all access rights in this table.
    SC_MANAGER_CREATE_SERVICE (0x0002): Required to call the CreateService function to create a service object and add it to the database.
    SC_MANAGER_CONNECT (0x0001): Required to connect to the service control manager.
    SC_MANAGER_ENUMERATE_SERVICE (0x0004): Required to call the EnumServicesStatus or EnumServicesStatusEx function to list the services that are in the database.
    Required to call the NotifyServiceStatusChange function to receive notification when any service is created or deleted.
    SC_MANAGER_LOCK (0x0008): Required to call the LockServiceDatabase function to acquire a lock on the database.
    SC_MANAGER_MODIFY_BOOT_CONFIG (0x0020): Required to call the NotifyBootConfigStatus function.
    SC_MANAGER_QUERY_LOCK_STATUS (0x0010): Required to call the QueryServiceLockStatus function to retrieve the lock status information for the database.
    
    Default 'SC_MANAGER_ALL_ACCESS'.

    .PARAMETER ImpersonationLevel

    .NOTES

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

    $ScmClient = New-RpcClientConnection -FilePath C:\Windows\System32\services.exe -EndpointPath \pipe\svcctl -ProtocolSequence ncacn_np -NetworkAddress 192.168.2.5 -InterfaceId 367abb81-9844-35f1-ad32-98f038001003 -ImpersonationLevel Identification 
    $ScmHandle = ROpenSCManagerW -RpcClient $ScmClient -MachineName ADFS01.solorigatelabs.com -DatabaseName ServicesActive -DesiredAccess CreateService -Verbose

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        $RpcClient,

        [Parameter(Position = 1)]
        [String]$MachineName,
        
        [Parameter(Position = 2, Mandatory=$False)]
        [ValidateSet('ServicesActive','ServicesFailed')]
        [string] $DatabaseName = 'ServicesActive',
        
        [Parameter(Position = 3, Mandatory=$False)]
        [ArgumentCompleter( {
            param (
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $FakeBoundParameters
            )
            ([NtApiDotNet.Win32.ServiceControlManagerAccessRights]).DeclaredMembers | Where-Object { $_.IsStatic } | Select-Object -ExpandProperty name | Where-object {$_ -like "$wordToComplete*"}
        })]
        [String]$DesiredAccess
    )

    write-verbose "[+] Invoking ROpenSCManagerW"
    $Result = $RpcClient.ROpenSCManagerW($MachineName,$DatabaseName,[NtApiDotNet.Win32.ServiceControlManagerAccessRights]::$DesiredAccess)

    # Handle results
    if ($Result.retval -ne 0) {
        $ex = [System.ComponentModel.Win32Exception]::new($result.retval)
        throw $ex
    }
    else{
        # Return Handle
        write-verbose "[+] A handle to the SCM database was obtained!"
        $Result.p3
    }
}