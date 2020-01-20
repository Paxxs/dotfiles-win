function IsAdmin {
    $currentPrincipal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Edit-Hosts {
    Invoke-Expression "$(if (-not $(IsAdmin)) {'sudo '})$(if ($env:EDITOR -ne $null) {
        $env:EDITOR
    } else {
        'notepad'
    }) $env:windir\system32\drivers\etc\hosts"
}

function Edit-Profile {
    Invoke-Expression "$(if ($env:EDITOR -ne $null) {
        $env:EDITOR
    } else {
        'notepad'
    }) $profile"
}
function Update-System {
    #require administrator
    Invoke-Expression "$(if (-not $(IsAdmin)) {'sudo '})Install-WindowsUpdate -IgnoreUserInput -IgnoreReboot -AcceptAll"
    Invoke-Expression "scoop update"
    Update-Module
    Update-Help
}