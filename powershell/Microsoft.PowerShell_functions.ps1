function Edit-Hosts {
    Invoke-Expression "sudo $(if ($env:EDITOR -ne $null) {
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