function RStartServiceW
{
    <#
    .SYNOPSIS

    The RStartServiceW method starts a specified service. (Opnum 19)

    Author: Roberto Rodriguez (@Cyb3rWard0g)

    .DESCRIPTION

    The RStartServiceW method starts a specified service. (Opnum 19)

    .PARAMETER RpcClient

    RPC client connected to the endpoint (Endpoint path example: \pipe\svcctl)

    .PARAMETER ServiceHandle

    Handle to the service record obtained after opening the service via the ROpenServiceW function

    .NOTES

    DWORD RStartServiceW(
        [in] SC_RPC_HANDLE hService,
        [in, range(0, SC_MAX_ARGUMENTS)] 
            DWORD argc,
        [in, unique, size_is(argc)] LPSTRING_PTRSW argv
    );

    .LINK

    https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-scmr/d9be95a2-cf01-4bdc-b30f-6fe4b37ada16

    .EXAMPLE

    $ScmClient = New-RpcClientConnection -FilePath C:\Windows\System32\services.exe -EndpointPath \pipe\svcctl -ProtocolSequence ncacn_np -NetworkAddress 192.168.2.5 -InterfaceId 367abb81-9844-35f1-ad32-98f038001003 -ImpersonationLevel Identification
    $ScmHandle = ROpenSCManagerW -RpcClient $scmClient -MachineName ADFS01.solorigatelabs.com -DatabaseName ServicesActive -DesiredAccess CreateService -Verbose
    
    $ServiceHandle = RCreateServiceW -RpcClient $ScmClient -ScmHandle $ScmHandle -ServiceName test5 -DisplayName test5 -BinaryPathName '%COMSPEC% /C dir C:\ > C:\programdata\test.txt'

    $ScmClient.RCloseServiceHandle -RpcClient $RpcClient -ScRpcHandle $ServiceHandle -Verbose
    $ServiceHandle = $null

    $ServiceHandle = ROpenServiceW -RpcClient $ScmClient -ScmHandle $ScmHandle -ServiceName test5

    RStartServiceW -RpcClient $ScmClient -ServiceHandle $ServiceHandle
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        $RpcClient,

        [Parameter(Position = 1, Mandatory = $True)]
        [NtApiDotNet.Ndr.Marshal.NdrContextHandle]$ServiceHandle
    )
    # Creating Service
    $Result = $RpcClient.RStartServiceW($ServiceHandle,$null,$null)

    # Handle results
    if ($Result -ne 0) {
        $ex = [System.ComponentModel.Win32Exception]::new($result)
        throw $ex
    }
    else{
        # Return Handle
        write-verbose "[+] Service $ServiceName started successfully!"
    }
}