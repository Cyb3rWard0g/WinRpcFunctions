function RDeleteService
{
    <#
    .SYNOPSIS

    The RDeleteService method marks the specified service for deletion from the SCM database. (Opnum 2)

    Author: Roberto Rodriguez (@Cyb3rWard0g)

    .DESCRIPTION

    The RDeleteService method marks the specified service for deletion from the SCM database. (Opnum 2)

    .PARAMETER RpcClient

    RPC client connected to the endpoint (Endpoint path example: \pipe\svcctl)

    .PARAMETER ServiceHandle

    Handle to the service record obtained after opening the service via the ROpenServiceW function

    .NOTES

    DWORD RDeleteService(
        [in] SC_RPC_HANDLE hService
    );

    .LINK

    https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-scmr/6744cdb8-f162-4be0-bb31-98996b6495be

    .EXAMPLE

    $ScmClient = New-RpcClientConnection -FilePath C:\Windows\System32\services.exe -EndpointPath \pipe\svcctl -ProtocolSequence ncacn_np -NetworkAddress 192.168.2.5 -InterfaceId 367abb81-9844-35f1-ad32-98f038001003 -ImpersonationLevel Identification
    $ScmHandle = ROpenSCManagerW -RpcClient $scmClient -MachineName ADFS01.solorigatelabs.com -DatabaseName ServicesActive -DesiredAccess CreateService

    $ServiceHandle = ROpenServiceW -RpcClient $ScmClient -ScmHandle $ScmHandle -ServiceName test5

    RDeleteService -RpcClient $ScmClient -ServiceHandle $ServiceHandle
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
    $Result
    if ($Result -ne 0) {
        $ex = [System.ComponentModel.Win32Exception]::new($result)
        throw $ex
    }
    else{
        # Return Handle
        write-verbose "[+] Service $ServiceName was mar successfully!"
    }
}