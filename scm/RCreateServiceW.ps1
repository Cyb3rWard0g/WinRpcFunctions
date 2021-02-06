function RCreateServiceW
{
    <#
    .SYNOPSIS

    The RCreateServiceW method creates the service record in the SCM database. (Opnum 12)

    Author: Roberto Rodriguez (@Cyb3rWard0g)

    .DESCRIPTION

    The RCreateServiceW method creates the service record in the SCM database. (Opnum 12)

    .PARAMETER RpcClient

    RPC client connected to the endpoint (Endpoint path example: \pipe\svcctl)

    .PARAMETER ScmHandle

    Handle to the SCM database obtained with the ROpenSCManagerW function

    .PARAMETER ServiceName

    The name of the service to install

    .PARAMETER DisplayName
    
    The display name by which user interface programs identify the service

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
    
    Default 'SERVICE_ALL_ACCESS'.

    .PARAMETER ServiceType

    A value that specifies the type of service

    SERVICE_KERNEL_DRIVER (0x00000001): A driver service. These are services that manage devices on the system.
    SERVICE_FILE_SYSTEM_DRIVER (0x00000002): A file system driver service. These are services that manage file systems on the system.
    SERVICE_WIN32_OWN_PROCESS (0x00000010): Service that runs in its own process.
    SERVICE_WIN32_SHARE_PROCESS (0x00000020): Service that shares a process with other services.
    SERVICE_INTERACTIVE_PROCESS (0x00000100): The service can interact with the desktop.

    .PARAMETER StartType

    A value that specifies when to start the service

    SERVICE_BOOT_START (0x00000000): Starts the driver service when the system boots up. This value is valid only for driver services.
    SERVICE_SYSTEM_START (0x00000001): Starts the driver service when the system boots up. This value is valid only for driver services. The services marked SERVICE_SYSTEM_START are started after all SERVICE_BOOT_START services have been started.
    SERVICE_AUTO_START (0x00000002): Starts the service automatically during system startup.
    SERVICE_DEMAND_START (0x00000003): Starts the service when a client requests the SCM to start the service.
    SERVICE_DISABLED (0x00000004): Service cannot be started.

    .PARAMETER ErrorControl
    
    A value that specifies the severity of the error if the service fails to start and determines the action that the SCM takes

    SERVICE_ERROR_IGNORE (0x00000000): The SCM ignores the error and continues the startup operation.
    SERVICE_ERROR_NORMAL (0x00000001): The SCM logs the error, but continues the startup operation.
    SERVICE_ERROR_SEVERE (0x00000002): The SCM logs the error. If the last-known good configuration is being started, the startup operation continues. Otherwise, the system is restarted with the last-known good configuration.
    SERVICE_ERROR_CRITICAL (0x00000003): The SCM SHOULD log the error if possible. If the last-known good configuration is being started, the startup operation fails. Otherwise, the system is restarted with the last-known good configuration.

    .PARAMETER BinaryPathName
    
    The fully qualified path to the service binary file. The path MAY include arguments. If the path contains a space, it MUST be quoted so that it is correctly interpreted. For example, "d:\\my share\\myservice.exe" is specified as "\"d:\\my share\\myservice.exe\"".

    .NOTES

    DWORD RCreateServiceW(
        [in] SC_RPC_HANDLE hSCManager,
        [in, string, range(0, SC_MAX_NAME_LENGTH)] 
            wchar_t* lpServiceName,
        [in, string, unique, range(0, SC_MAX_NAME_LENGTH)] 
            wchar_t* lpDisplayName,
        [in] DWORD dwDesiredAccess,
        [in] DWORD dwServiceType,
        [in] DWORD dwStartType,
        [in] DWORD dwErrorControl,
        [in, string, range(0, SC_MAX_PATH_LENGTH)] 
            wchar_t* lpBinaryPathName,
        [in, string, unique, range(0, SC_MAX_NAME_LENGTH)] 
            wchar_t* lpLoadOrderGroup,
        [in, out, unique] LPDWORD lpdwTagId,
        [in, unique, size_is(dwDependSize)] 
            LPBYTE lpDependencies,
        [in, range(0, SC_MAX_DEPEND_SIZE)] 
            DWORD dwDependSize,
        [in, string, unique, range(0, SC_MAX_ACCOUNT_NAME_LENGTH)] 
            wchar_t* lpServiceStartName,
        [in, unique, size_is(dwPwSize)] 
            LPBYTE lpPassword,
        [in, range(0, SC_MAX_PWD_SIZE)] 
            DWORD dwPwSize,
        [out] LPSC_RPC_HANDLE lpServiceHandle
    );

    .LINK

    https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-scmr/6a8ca926-9477-4dd4-b766-692fab07227e

    .EXAMPLE

    $ScmClient = New-RpcClientConnection -FilePath C:\Windows\System32\services.exe -EndpointPath \pipe\svcctl -ProtocolSequence ncacn_np -NetworkAddress 192.168.2.5 -InterfaceId 367abb81-9844-35f1-ad32-98f038001003 -ImpersonationLevel Identification
    $ScmHandle = ROpenSCManagerW -RpcClient $scmClient -MachineName ADFS01.solorigatelabs.com -DatabaseName ServicesActive -DesiredAccess CreateService -Verbose
    
    $ServiceHandle = RCreateServiceW -RpcClient $ScmClient -ScmHandle $ScmHandle -ServiceName test5 -DisplayName test5 -BinaryPathName '%COMSPEC% /C dir C:\ > C:\programdata\test.txt'

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
        [string]$DisplayName = "WardogService",
        
        [Parameter(Position = 4, Mandatory=$False)]
        [ArgumentCompleter( {
            param ($CommandName,$ParameterName,$WordToComplete,$CommandAst,$FakeBoundParameters)
            ([NtApiDotNet.Win32.ServiceAccessRights]).DeclaredMembers | Where-Object { $_.IsStatic } | Select-Object -ExpandProperty name | Where-object {$_ -like "$wordToComplete*"}
        })]
        [String]$DesiredAccess  = 'All',

        [Parameter(Position = 5, Mandatory=$False)]
        [ArgumentCompleter( {
            param ($CommandName,$ParameterName,$WordToComplete,$CommandAst,$FakeBoundParameters)
            ([NtApiDotNet.Win32.ServiceType]).DeclaredMembers | Where-Object { $_.IsStatic } | Select-Object -ExpandProperty name | Where-object {$_ -like "$wordToComplete*"}
        })]
        [String]$ServiceType  = 'Win32OwnProcess',

        [Parameter(Position = 6, Mandatory=$False)]
        [ArgumentCompleter( {
            param ($CommandName,$ParameterName,$WordToComplete,$CommandAst,$FakeBoundParameters)
            ([NtApiDotNet.Win32.ServiceStartType]).DeclaredMembers | Where-Object { $_.IsStatic } | Select-Object -ExpandProperty name | Where-object {$_ -like "$wordToComplete*"}
        })]
        [String]$StartType  = 'Demand',

        [Parameter(Position = 7, Mandatory=$False)]
        [ArgumentCompleter( {
            param ($CommandName,$ParameterName,$WordToComplete,$CommandAst,$FakeBoundParameters)
            ([NtApiDotNet.Win32.ServiceErrorControl]).DeclaredMembers | Where-Object { $_.IsStatic } | Select-Object -ExpandProperty name | Where-object {$_ -like "$wordToComplete*"}
        })]
        [String]$ErrorControl  = 'Normal',

        [Parameter(Position = 8, Mandatory=$False)]
        [String]$BinaryPathName
    )
    # Creating Service
    $Result = $RpcClient.RCreateServiceW($ScmHandle,$ServiceName,$DisplayName,[NtApiDotNet.Win32.ServiceAccessRights]::$DesiredAccess,[NtApiDotNet.Win32.ServiceType]::$ServiceType,[NtApiDotNet.Win32.ServiceStartType]::$StartType,[NtApiDotNet.Win32.ServiceErrorControl]::$ErrorControl,$BinaryPathName, $null, $null, $null, 0, 'LocalSystem',$null,0)
    
    # Handle results
    if ($Result.retval -ne 0) {
        $ex = [System.ComponentModel.Win32Exception]::new($result.retval)
        throw $ex
    }
    else{
        # Return Handle
        write-verbose "[+] Service $ServiceName was installed successfully!"
        $Result.p15
    }
}