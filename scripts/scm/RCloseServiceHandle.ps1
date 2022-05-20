function RCloseServiceHandle
{
    <#
    .SYNOPSIS

    The RCloseServiceHandle method is called by the client. In response, the server releases the handle to the specified service or the SCM database. (Opnum 0)

    Author: Roberto Rodriguez (@Cyb3rWard0g)

    .DESCRIPTION

    The RCloseServiceHandle method is called by the client. In response, the server releases the handle to the specified service or the SCM database. (Opnum 0)

    .PARAMETER RpcClient

    RPC client connected to the endpoint (Endpoint path example: \pipe\svcctl)

    .PARAMETER ScRpcHandle

    The handle to a service record or to the SCM database that MUST have been created previously

    .NOTES

    DWORD RCloseServiceHandle(
        [in, out] LPSC_RPC_HANDLE hSCObject
    );

    .LINK

    https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-scmr/a2a4e174-09fb-4e55-bad3-f77c4b13245c

    .EXAMPLE

    $ScmClient = New-RpcClientConnection -FilePath C:\Windows\System32\services.exe -EndpointPath \pipe\svcctl -ProtocolSequence ncacn_np -NetworkAddress 192.168.2.5 -InterfaceId 367abb81-9844-35f1-ad32-98f038001003 -ImpersonationLevel Identification
    $ScmHandle = ROpenSCManagerW -RpcClient $scmClient -MachineName ADFS01.solorigatelabs.com -DatabaseName ServicesActive -DesiredAccess CreateService -Verbose
    $ServiceHandle = RCreateServiceW -RpcClient $ScmClient -ScmHandle $ScmHandle -ServiceName test -DisplayName test -BinaryPathName '%COMSPEC% /C dir C:\ > C:\programdata\test.txt'
    
    RCloseServiceHandle -RpcClient $ScmClient -ScRpcHandle $ServiceHandle
    RCloseServiceHandle -RpcClient $ScmClient -ScRpcHandle $Scmhandle

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        $RpcClient,

        [Parameter(Position = 1, Mandatory = $True)]
        [NtApiDotNet.Ndr.Marshal.NdrContextHandle]$ScRpcHandle
    )

    write-verbose "[+] Closing SC RPC Handle: $($ScRpcHandle.Uuid)"
    $Result = $RpcClient.RCloseServiceHandle($ScRpcHandle)
    # Handle results
    if ($Result.retval -ne 0) {
        $ex = [System.ComponentModel.Win32Exception]::new($result.retval)
        throw $ex
    }
    else{
        # Return Handle
        write-verbose "[+] SC RPC Handle: $($ScRpcHandle.Uuid) was closed successfully!"
    }
}