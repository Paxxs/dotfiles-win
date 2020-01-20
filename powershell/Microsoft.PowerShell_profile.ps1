if (Get-Module "posh-git") {
    Import-Module posh-git -ErrorAction SilentlyContinue
    Set-Theme Paradox -ErrorAction SilentlyContinue
}
if (Get-Module "oh-my-posh") {
    Import-Module oh-my-posh -ErrorAction SilentlyContinue
}
if (Get-Module "Get-ChildItemColor") {
    Import-Module Get-ChildItemColor -ErrorAction SilentlyContinue
}
if (Get-Module "z") {
    Import-Module z -ErrorAction SilentlyContinue
}

# PSReadLine https://docs.microsoft.com/zh-cn/powershell/module/psreadline/?view=powershell-5.1
Set-PsReadlineOption -EditMode Vi -ViModeIndicator Cursor -HistoryNoDuplicate
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Shift+Tab' -Function Complete

#region stow function and alias
# 不兼容 integrated console
$profileInfo = Get-Item $profile
if (($profileInfo).LinkType -eq "SymbolicLink") {
    $profileInfo = Split-Path $profileInfo.Target
} else {
    $profileInfo = Split-Path $profileInfo.FullName
}

if (Test-Path("$profileInfo\Microsoft.PowerShell_functions.ps1")) {
    . "$profileInfo\Microsoft.PowerShell_functions.ps1"
}
if (Test-Path("$profileInfo\Microsoft.PowerShell_aliases.ps1")) {
    . "$profileInfo\Microsoft.PowerShell_aliases.ps1"
}
#endregion

# git log 乱码
$env:LC_ALL='C.UTF-8'