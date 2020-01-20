#region Navigation Shortcuts
${function:~} = { Set-Location ~ }
# PoSh won't allow ${function:..} because of an invalid path error, so...
${function:Set-ParentLocation} = { Set-Location .. }; Set-Alias ".." Set-ParentLocation
${function:...} = { Set-Location ..\.. }

# https://docs.microsoft.com/en-us/dotnet/api/system.environment.getfolderpath?view=netframework-4.8#System_Environment_GetFolderPath_System_Environment_SpecialFolder_
${function:dt} = { Set-Location $([Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)) }
${function:docs} = { Set-Location $([Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)) }
#FOLDERID_Downloads: https://docs.microsoft.com/en-us/windows/win32/shell/knownfolderid
${function:dl} = { Set-Location $(Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}') }
#endregion

#region Git Shortcuts
${function:ggs } = { git status }
function gga($file) { git add $file }
${function:ggai} = { git add --interactive }
${function:ggaa} = { git add --all }
function ggc($msg) { if($msg) { git commit -m $msg } else { git commit } }
${function:ggca} = { git commit --amend }
${function:ggcaa} = { git commit --amend --no-edit }
${function:ggp} = { git push }
${function:ggpf} = { git push --force-with-lease }
# 只进行 fast-forward 合并
${function:ggu} = { git pull --ff-only }
${function:ggd} = { git diff }
${function:ggds} = { git diff --staged }
${function:ggl} = { git log --graph --color --all --decorate --format="%C(auto)%d %s" }
${function:ggll} = { git log --graph --color --all --decorate --format="%C(auto)%h %d %s %Cblue %ar %an" }
# 最后一次
${function:ggx} = { git show -s --format='%Cgreen%h %Cblue%an %Cred%cr%Creset%n%s' }
# 根目录
${function:ggroot} = { Push-Location (git rev-parse --show-toplevel) }
#endregion

#region scoop alias
Set-Alias apt scoop
${function:scoops} = {scoop update; scoop status}
#endregion

#region function
Set-Alias mkd CreateAndSetDir -Description "Create a new directory and enter it"
Set-Alias update Update-System -Description "Update system, scoop, ruby Gems, ...(other packages)"
Set-Alias myip Get-Myip -Description "Get the public IP address through ipinfo.io"

Set-Alias open Invoke-Item -Description "The Invoke-Item cmdlet performs the default action on the specified item"
#endregion

#region Correct PowerShell Aliases if tools are available (aliases win if set)
# curl: Use `curl.exe` if available
if (Get-Command curl.exe -ErrorAction SilentlyContinue | Test-Path) {
    Remove-Item alias:curl -ErrorAction SilentlyContinue
    ${function:curl} = { curl.exe @args }
    # Gzip-enabled `curl`
    ${function:gurl} = { curl --compressed @args }
} else {
    # Gzip-enabled `curl`
    ${function:gurl} = { Invoke-WebRequest -TransferEncoding GZip }
}

# WGet: Use `wget.exe` if available
if (Get-Command wget.exe -ErrorAction SilentlyContinue | Test-Path) {
    Remove-Item alias:wget -ErrorAction SilentlyContinue
}

# Get-ChildItemColor
if (Get-Module "Get-ChildItemColor") {
    Set-Alias l Get-ChildItem -option AllScope
    Set-Alias ls Get-ChildItemColorFormatWide -option AllScope
}
#endregion