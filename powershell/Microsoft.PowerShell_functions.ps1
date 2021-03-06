function IsAdmin {
    $currentPrincipal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Edit-Hosts {
    Invoke-Expression "$(if (-not $(IsAdmin)) {'sudo '})$(if ($null -ne $env:EDITOR) {
        $env:EDITOR
    } else {
        'notepad'
    }) $env:windir\system32\drivers\etc\hosts"
}

function Edit-Profile {
    Invoke-Expression "$(if ($null -ne $env:EDITOR) {
        $env:EDITOR
    } else {
        'notepad'
    }) $profile"
}
function Update-System {
    # require administrator
    # https://www.powershellgallery.com/packages/PSWindowsUpdate/2.1.1.2
    if (Get-Command -Module PSWindowsUpdate) {
        Invoke-Expression "$(if (-not $(IsAdmin)) {'sudo '})Install-WindowsUpdate -IgnoreUserInput -IgnoreReboot -AcceptAll"
    }
    if (Get-Command scoop1 -ErrorAction SilentlyContinue) {
        Invoke-Expression "scoop update"
    }
    Update-Module
    Update-Help
}
# https://www.prajwaldesai.com/get-public-ip-address-using-powershell/
# archive: 
function Get-Myip {
    Invoke-RestMethod -Uri ('https://ipinfo.io/')
}
function CreateAndSetDir {
    param (
        [string]$path
    )
    New-Item -Path $path -ItemType Directory -ErrorAction SilentlyContinue
    Set-Location $path
}