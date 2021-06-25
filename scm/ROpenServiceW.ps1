function ROpenServiceW
{
    <#
    .SYNOPSIS

    The ROpenServiceW method creates an RPC context handle to an existing service record. (Opnum 16)

    Author: Roberto Rodriguez (@Cyb3rWard0g)

    .DESCRIPTION

    The ROpenServiceW method starts a specified service. (Opnum 19)

    .PARAMETER RpcClient

    RPC client connected to the endpoint (Endpoint path example: \pipe\svcctl)

    .PARAMETER ScmHandle

    Handle to the SCM database obtained with the ROpenSCManagerW function

    .PARAMETER ServiceName

    The ServiceName of the service record

    .PARAMETER DesiredAccess

    A value that specifies the access to the service
    
    Access Rights for a Service

    References:
    - https://docs.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights?redirectedfrom=MSDN
    - https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-scmr/0d7a7011-9f41-470d-ad52-8535b47ac282

    SERVICE_ALL_ACCESS (0xF01FF) 	Includes STANDARD_RIGHTS_REQUIRED in addition to all access rights in this table.
    SERVICE_CHANGE_CONFIG (0x0002) 	Required to call the ChangeServiceConfig or ChangeServiceConfig2 function to change the service configuration. Because this grants the caller the right to change the executable file that the system runs, it should be granted only to administrators.
    SERVICE_ENUMERATE_DEPENDENTS (0x0008) 	Required to call the EnumDependentServices function to enumerate all the services dependent on the service.
    SERVICE_INTERROGATE (0x0080) 	Required to call the ControlService function to ask the service to report its status immediately.
    SERVICE_PAUSE_CONTINUE (0x0040) 	Required to call the ControlService function to pause or continue the service.
    SERVICE_QUERY_CONFIG (0x0001) 	Required to call the QueryServiceConfig and QueryServiceConfig2 functions to query the service configuration.
    SERVICE_QUERY_STATUS (0x0004) 	Required to call the QueryServiceStatus or QueryServiceStatusEx function to ask the service control manager about the status of the service. Required to call the NotifyServiceStatusChange function to receive notification when a service changes status.
    SERVICE_START (0x0010) 	Required to call the StartService function to start the service.
    SERVICE_STOP (0x0020) 	Required to call the ControlService function to stop the service.
    SERVICE_USER_DEFINED_CONTROL(0x0100) 	Required to call the ControlService function to specify a user-defined control code.
    
    Default 'SERVICE_START'

    .NOTES

    DWORD ROpenServiceW(
        [in] SC_RPC_HANDLE hSCManager,
        [in, string, range(0, SC_MAX_NAME_LENGTH)] 
            wchar_t* lpServiceName,
        [in] DWORD dwDesiredAccess,
        [out] LPSC_RPC_HANDLE lpServiceHandle
    );

    .LINK

    https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-scmr/6a8ca926-9477-4dd4-b766-692fab07227e

    .EXAMPLE

    $ScmClient = New-RpcClientConnection -FilePath C:\Windows\System32\services.exe -EndpointPath \pipe\svcctl -ProtocolSequence ncacn_np -NetworkAddress 192.168.2.5 -InterfaceId 367abb81-9844-35f1-ad32-98f038001003 -ImpersonationLevel Identification
    $ScmHandle = ROpenSCManagerW -RpcClient $scmClient -MachineName ADFS01.solorigatelabs.com -DatabaseName ServicesActive -DesiredAccess CreateService -Verbose
    $ServiceHandle = RCreateServiceW -RpcClient $ScmClient -ScmHandle $ScmHandle -ServiceName test5 -DisplayName test5 -BinaryPathName '%COMSPEC% /C dir C:\ > C:\programdata\test.txt'
    
    $ScmClient.RCloseServiceHandle -RpcClient $RpcClient -ScRpcHandle $Result.p15 -Verbose
    $ServiceHandle = $null

    $ServiceHandle = ROpenServiceW -RpcClient $ScmClient -ScmHandle $ScmHandle -ServiceName test5

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        $RpcClient,

        [Parameter(Position = 1, Mandatory = $True)]
        [NtApiDotNet.Ndr.Marshal.NdrContextHandle] $ScmHandle,

        [Parameter(Position = 2, Mandatory=$True)]
        [String]$ServiceName,
        
        [Parameter(Position = 3, Mandatory=$False)]
        [ArgumentCompleter( {
            param ($CommandName,$ParameterName,$WordToComplete,$CommandAst,$FakeBoundParameters)
            ([NtApiDotNet.Win32.ServiceAccessRights]).DeclaredMembers | Where-Object { $_.IsStatic } | Select-Object -ExpandProperty name | Where-object {$_ -like "$wordToComplete*"}
        })]
        [String]$DesiredAccess  = 'All'
    )
    # Creating Service
    $Result = $RpcClient.ROpenServiceW($ScmHandle,$ServiceName,[NtApiDotNet.Win32.ServiceAccessRights]::$DesiredAccess)
    
    # Handle results
    if ($Result.retval -ne 0) {
        $ex = [System.ComponentModel.Win32Exception]::new($result.retval)
        throw $ex
    }
    else{
        # Return Handle
        write-verbose "[+] SC RPC Handle to service $ServiceName was obtained successfully!"
        $Result.p3
    }
}
