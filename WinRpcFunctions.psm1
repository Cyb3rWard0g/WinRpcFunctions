# Installing and Import NtObjectManager
if (Get-Module -ListAvailable -Name NtObjectManager) {
    if (!(Get-Module "NtObjectManager"))
    {
        Import-Module NtObjectManager
    } 
} 
else 
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    Register-PSRepository -Default
    
    Install-Module NtObjectManager -Force
    Import-Module NtObjectManager
}

# Loading New-RpcClientConnection script
. "$($PSScriptRoot)\New-RpcClientConnection.ps1"

# Importing Functions
Get-ChildItem $PSScriptRoot | Where-Object { $_.PSIsContainer -and $_.Name -ne 'resources' } | Foreach-Object { Get-ChildItem "$($_.FullName)\*" -Include '*.ps1' } | Foreach-Object { . $_.FullName }