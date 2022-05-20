# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: MIT

function Import-ModulesToGhidra {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$GhidraFolder,

        [parameter(Mandatory=$true)]
        [string]$ProjectPath,

        [parameter(Mandatory=$true)]
        [string]$ProjectName,

        [parameter(Mandatory=$true)]
        [string]$FilesPath
    )

    # Validate Paths
    $GhidraFolder = Resolve-Path $GhidraFolder -ErrorAction Stop
    $ProjectPath = Resolve-Path $ProjectPath -ErrorAction Stop
    $FilesPath = Resolve-Path $FilesPath -ErrorAction Stop

    $GhidraHeadless = "$GhidraFolder\support\\analyzeHeadless.bat"

    foreach ($module in (Get-Content $FilesPath)){
        if ($module.ToLower() -eq 'combase.dll'){
            continue
        }
        write-host "[+] Processing " $module
        try {
        
            & $GhidraHeadless $ProjectPath $ProjectName -import $module -overwrite
        }
        catch{
            Write-Gost "[!] Something went WRONG with " $module
            Write-Output $module | Out-File -append "$(Get-Location)\ERRORMODS.txt"
        }
    }
}