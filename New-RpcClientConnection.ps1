function New-RpcClientConnection
{
    <#
    .DESCRIPTION

    The ROpenSCManagerW method establishes a connection to server and opens the SCM database on the specified server. (Opnum 15)

    .PARAMETER FilePath

    The full file path of the DLL or EXE hosting the RPC server code.

    .PARAMETER EndopointPath

    Example: \pipe\svcctl

    .PARAMETER ProtocolSequence

    Example: ncacn_np

    .PARAMETER NetworkAddress

    Example: 192.168.2.5

    .PARAMETER Endpoint

    RPC Endpoint

    .PARAMETER InterfaceId

    Rpc server interface id. For example: 367abb81-9844-35f1-ad32-98f038001003 -> SCM / svcctl

    .PARAMETER ImpersonationLevel

    .NOTES

    Author: Roberto Rodriguez (@Cyb3rWard0g)

    .LINK

    .EXAMPLE

    $ScmClient = New-RpcClientConnection -FilePath C:\Windows\System32\services.exe -EndpointPath \pipe\svcctl -ProtocolSequence ncacn_np -NetworkAddress 192.168.2.5 -InterfaceId 367abb81-9844-35f1-ad32-98f038001003 -ImpersonationLevel Identification

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory=$True)]
        [String]$FilePath,
        
        [Parameter(Position = 2, Mandatory=$False, ParameterSetname='EndpointPath')]
        [String]$EndpointPath,

        [Parameter(Mandatory=$False, ParameterSetname='EndpointPath')]
        [ValidateSet('ncalrpc','ncacn_np','ncacn_ip_tcp','ncacn_hvsocket')]
        [String]$ProtocolSequence='ncalrpc',

        [Parameter(Mandatory=$False, ParameterSetname='EndpointPath')]
        [String]$NetworkAddress,

        [Parameter(Position = 2, Mandatory=$True, ParameterSetname='Endpoint')]
        [String]$Endpoint,

        [Parameter(Mandatory=$False)]
        [String]$InterfaceId,

        [Parameter(Mandatory=$False)]
        [ValidateSet('Anonymous','Delegation','Identification','Impersonation')]
        [string]$ImpersonationLevel='Identification'
    )

    # Parse local RPC Servers
    write-verbose "[+] Parsing local RPC Servers"
    if ($FilePath)
    {
        $RpcServers = Get-RpcServer -FullName $FilePath
    }
    else
    {
        $RpcServers = Get-ChildItem C:\Windows\System32\* -Include '*.dll','*.exe' | Get-RpcServer
    }
    # Look for RPC Server by specific InterfaceId
    write-verbose "[+] Filtering RPC servers by InterfaceId"
    $RpcServer = $RpcServers | Where-Object { $_.InterfaceId -eq $InterfaceId }
    
    # This cmdlet creates a new RPC client from a parsed RPC server.
    # The client object contains methods to call RPC methods.
    # The client starts off disconnected. You need to pass the client to Connect-RpcClient to connect to the server.
    write-verbose "[+] Creating new RPC client from RPC server"
    $RpcClient = Get-RpcClient -Server $RpcServer

    # This cmdlet connects a RPC client to an endpoint
    write-verbose "[+] Connect RPC client to RPC endpoint"
    try {
        if ($EndpointPath -and $($EndpointPath -ne ""))
        {
            Connect-RpcClient -Client $RpcClient -EndpointPath $EndpointPath -ProtocolSequence $ProtocolSequence -NetworkAddress $NetworkAddress -SecurityQualityOfService $(New-NtSecurityQualityOfService -ImpersonationLevel $ImpersonationLevel) -errorAction Stop
        }
        else 
        {
            Connect-RpcClient -Client $RpcClient -Endpoint $Endpoint -SecurityQualityOfService $(New-NtSecurityQualityOfService -ImpersonationLevel $ImpersonationLevel) -errorAction Stop 
        }
        write-verbose "[+] Connected RPC client to RPC endpoint successfully!"
        $RpcClient
    }
    catch
    {
        $_.Exception.Message
    }
}