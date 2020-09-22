#Requires -RunAsAdministrator
#Requires -Version 5
Write-Host ":: " -ForegroundColor DarkBlue -NoNewline
Write-Host "Checking the environment" -ForegroundColor DarkCyan
if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Output "PowerShell 5 or later is required to run bootstrap."
    Write-Output "Upgrade PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell"
    break
}
# show notification to change execution policy:
$allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
if ((Get-ExecutionPolicy).ToString() -notin $allowedExecutionPolicy) {
    Write-Output "PowerShell requires an execution policy in [$($allowedExecutionPolicy -join ", ")] to run bootstrap."
    Write-Output "For example, to set the execution policy to 'RemoteSigned' please run :"
    Write-Output "'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"
    break
}
if ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -notcontains 'Tls12') {
    Write-Output "paxos` dotfiles requires at least .NET Framework 4.5"
    Write-Output "Please download and install it first:"
    Write-Output "https://www.microsoft.com/net/download"
    break
}
Write-Output "OS: $((Get-WmiObject Win32_OperatingSystem).osarchitecture)"
if (-not [environment]::Is64BitOperatingSystem) {
    Write-Host "ERROR: Not 64 bit Windows may issue some problems" -ForegroundColor Red
    # exit
}

Write-Host ":: " -ForegroundColor DarkBlue -NoNewline
Write-Host "Load bootstrap script" -ForegroundColor DarkCyan
$bootstrap_url = "https://raw.githubusercontent.com/Paxxs/dotfiles-win/master/bootstrap.ps1"
$bootstrap_dir = "$($env:HOMEDRIVE)$($env:HOMEPATH)"
Write-Output "Downloading..."
(New-Object System.Net.WebClient).DownloadFile($bootstrap_url,"$bootstrap_dir\pxbootstrap.ps1")
$level = Read-Host "Select level (Minimal/Basic/Full)"
if (Test-Path "$bootstrap_dir\pxbootstrap.ps1") {
    . "$bootstrap_dir\pxbootstrap.ps1" -Plevel $level
    Write-Output "Remove bootstrap..."
    Remove-Item "$bootstrap_dir\pxbootstrap.ps1" -Force -ErrorAction Continue
} else {
    Write-Host "ERROR: Unable to load script" -ForegroundColor Red
}