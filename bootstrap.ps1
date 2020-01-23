#Requires -Version 5
#Requires -RunAsAdministrator
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet("Minimal", "Basic", "Full")]
    $Plevel
)
Write-Output "Level: $Plevel"
function Write-Error([string]$message) {
    [System.Console]::ForegroundColor = 'red'
    [System.Console]::Error.WriteLine("Error:" + $message)
    [System.Console]::ResetColor()
}
function Write-Warn([string]$message) {
    [Console]::ForegroundColor = 'Yellow'
    [Console]::Error.WriteLine("WARN: " + $message)
    [Console]::ResetColor()
}
function Write-Verbose([string]$message) {
    [Console]::ForegroundColor = 'DarkGreen'
    [Console]::Error.WriteLine("Verbose: " + $message)
    [Console]::ResetColor()
}
function Write-Title ($msg) {
    Write-Host ":: " -ForegroundColor DarkGreen -NoNewline
    Write-Host $msg -ForegroundColor Yellow
}
function TimeoutPrompt {
    param (
        $prompt,
        $seconds2Wait
    )
    Write-Host $prompt -NoNewline
    # $secondsCounter = 0
    # $subCounter = 0
    $timeout = New-TimeSpan -Seconds $seconds2Wait
    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $Host.UI.RawUI.FlushInputBuffer()
    while ($stopWatch.Elapsed -lt $timeout) {
        # Start-Sleep -Milliseconds 10
        # $subCounter += 10
        # if ($subCounter -eq 1000) {
        #     $secondsCounter++
        #     $subCounter = 0
        #     Write-Host "." -NoNewline
        # }
        Start-Sleep -Seconds 1
        Write-Host "." -NoNewline
        if ($host.UI.RawUI.KeyAvailable) {
            $keyPressed = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyUp, IncludeKeyDown")
            if ($keyPressed.KeyDown -eq $True) {
                $Host.UI.RawUI.FlushInputBuffer()
                Write-Host "`r`n"
                return $true
            }
        }
    }
    Write-Host "`r`n"
    return $false
}
function StowFile {
    param (
        [string]$link,
        [string]$target
    )
    $file = Get-Item $link -ErrorAction SilentlyContinue
    $target = (Get-Item $target -ErrorAction SilentlyContinue).FullName 
    if ($file) {
        if ($file.LinkType -ne "SymbolicLink") {
            Write-Error "$($file.FullName) already exists and is not a symbolic link"
            return
        }
        elseif ($file.Target -ne $target) {
            Write-Error "$($file.FullName) already exists and points to '$($file.Target)', it should point to '$target'"
            return
        }
        else {
            Write-Verbose "$($file.FullName) already linked"
            return
        }
    }
    else {
        $folder = Split-Path $link
        if (-not (Test-Path $folder)) {
            Write-Verbose "Creating folder $folder"
            New-Item -Type Directory -Path $folder
        }

        Write-Verbose "Creating link $link to $target"
        (New-Item -Path $link -ItemType SymbolicLink -Value $target -ErrorAction Continue).Target
    }
}
function DownloadFile {
    param (
        [string]$url,
        $target,
        [string]$hash = $null
    )
    
    if (Test-Path $target) {
        Write-Verbose "$target already downloaded."
        $IsDownload = $true
    }
    else {
        # download
        $IsDownload = $false
        try {
            $wc = New-Object System.Net.WebClient
            $wc.headers.add('Referer', (strip_filename $url))
            $wc.Headers.Add('User-Agent', (Get-UserAgent))
            $wc.DownloadFile($url, $target)
        }
        catch {
            Write-Error $_
            exit
        }
    }
    if ($hash) {
        $targethash = Get-FileHash $target -Algorithm "SHA256"
        $diff = 0
        Compare-Object -ReferenceObject $hash -DifferenceObject $targethash.Hash | ForEach-Object {
            if ($_.SilentlyContinue -ne "==") {
                $diff += 1
            }
        }
        if ($diff -ne 0) {
            if ($IsDownload) {
                Write-Error "'$target' does not match expected hash!`nExpected: $hash`nActual: $($targethash.Hash)"
                return
            }
            else {
                Write-Error "Downloaded File '$target' from url '$url' does not match expected hash!`nExpected: $hash`nActual: $($targethash.Hash)"
                return
            }
        }
    }
    if (!$IsDownload) {
        Write-Verbose "$target download successful !"
    }
}
function SetEnvVariable {
    param (
        [ValidateSet("Machine ", "Process ", "User")]
        [string]$target,
        [string]$name,
        [string]$value
    )
    $existing = [System.Environment]::GetEnvironmentVariable($name, $target)
    if ($existing) {
        Write-Verbose "Environment variable $name already set to '$existing'"
    }
    else {
        Write-Verbose "Adding the $name environment variable to '$value'"
        [System.Environment]::SetEnvironmentVariable($name,$value,$target)
    }
}
function EnsureDir ($dir) {
    if (!(Test-Path $dir)) {
        # Write-Output "Create folder: $dir"
        mkdir $dir | Out-Null
    }
    Resolve-Path $dir
}
# scoop
function AddScoopLog {
    param (
        $message,
        [bool]$isAppend = $false,
        [string]$file = "$($env:HOMEDRIVE)$($env:HOMEPATH)\scoop.log"
    )
    if ($isAppend) {
        $message >> $file
    }
    else {
        "`n" >> $file
        Get-Date -Format 'yyyy/M/d hh:mm:s' >> $file
        $message >> $file
    }
}
function CheckScoopBucket {
    param (
        [string]$bucket,
        [string]$bucket_url,
        [int]$count
    )
    begin {
        if (-not [string]::IsNullOrWhiteSpace($bucket_url)) {
            Write-Output "==> $bucket_url"
        }
        $ins_suc = $true
        $log = @()
    }

    process {
        if ($_ -cmatch 'failed|Error|bucket not found|like a valid git|missing|fatal: |try again') {
            $log += "ERROR: $_"
            $ins_suc = $false
            Write-Error $_
        }
        else {
            $log += $_
            # Write-Output "...$_"
        }
    }

    end {
        if ($ins_suc) {
            # Write-Host "成功：" -ForegroundColor Cyan -NoNewline
            # Write-Host "数据库 $bucket 克隆成功" -BackgroundColor DarkGreen
            Write-Verbose "Bucket $bucket added successfully!"
        }
        else {
            # Write-Host "失败：" -ForegroundColor Red -NoNewline
            # Write-Host "数据库 $bucket 克隆失败"
            Write-Error "Bucket $bucket add failure."

            Write-Verbose "Preparing to readd the bucket: $bucket [ $count ]"

            Write-Verbose "==> scoop bucket rm $bucket"
            scoop bucket rm $bucket

            AddScoopBucket -bu_name $bucket -bu_url $bucket_url -count $count

            AddScoopLog -message "Failed bucket：$bucket [ $count ]"
            AddScoopLog -message $log -isAppend $true
        }
    }
}
function CheckScoopInstall {
    param (
        [string]$appName,
        [int]$count,
        [bool]$isCore = $false

    )
    begin {
        Write-Output "`nInstall $appName"
        $ins_suc = $true
        $log = @()
    }

    process {
        if ($_ -cmatch 'aborted|failed|Error|doesn''t exist|Couldn''t find') {
            $log += "ERROR: $_"
            $ins_suc = $false
            Write-Error $_
        }
        else {
            $log += $_
            # Write-Host "...."$_
            Write-Output "...$_"
        }
    }

    end {
        if ($ins_suc) {
            # Write-Host "成功：" -ForegroundColor Green -NoNewline
            # Write-Host "$appName 安装成功" -BackgroundColor DarkGreen
            Write-Verbose "App $appName installed successful!"
        }
        else {
            # Write-Host "失败：" -ForegroundColor Red -NoNewline
            # Write-Host "$appName 安装失败"
            Write-Error "App $appName install failure."
            if (-not $isCore) {
                if ($count -le 3) {
                    Write-Verbose "Preparing for reinstallation $appName [ $count ]"
                    Write-Output "==> scoop uninstall $appName"
                    scoop uninstall $appName
                    InsScoop -appsName $appName -count $count
                }
                else {
                    # Write-Host "失败：" -ForegroundColor Red -NoNewline
                    # Write-Host "安装 $appName 失败超过三次，不再尝试" -ForegroundColor DarkRed -BackgroundColor Yellow
                    Write-Error "App $appName install failure.(Fail more than three times)"
                    AddScoopLog -message "Failed Installation: $appName"
                    AddScoopLog -message $log -isAppend $true
                }
            }
            else {
                Write-Verbose "App $appName is core app and it being reinstalled [ $count ]"
                scoop uninstall $appName

                Write-Output "==> scoop uninstall $appName"
                InsScoop -appsName $appName -count $count -isCore $true
            }
        }
    }
}
function AddScoopBucket {
    param (
        [string]$bu_name,
        [string]$bu_url,
        [int]$count = 0
    )
    $count ++
    if ([string]::IsNullOrWhiteSpace($bu_url)) {
        (cmd /c "scoop bucket add $bu_name") | CheckScoopBucket -bucket $bu_name -count $count
    }
    else {
        (cmd /c "scoop bucket add $bu_name `'$bu_url`'") | CheckScoopBucket -bucket $bu_name -count $count -bucket_url $bu_url
    }
}
function InsScoop {
    param (
        [string]$appsName,
        [int]$count = 0,
        [bool]$isCore = $false
    )
    $count ++
    (powershell.exe scoop install $appsName) | CheckScoopInstall -appName $appsName -count $count -isCore $isCore
}

# 参数转数值判断大小
$LevelMinimal = 1
$LevelBasic = 10
$levelFull = 100
$level = 0

switch ($Plevel) {
    "Minimal" { $level = $LevelMinimal }
    "Basic" { $level = $LevelBasic }
    "Full" { $level = $levelFull }
}

#region environment configuration
# - fw
# - $env:home

# 某些设备没有这个环境变量
if (-not $env:HOME) {
    $env:HOME = "$($env:HOMEDRIVE)$($env:HOMEPATH)"
}
#endregion

#region create dir and download dotfiles from github
# - create  & tmp
# - unzip master.zip to tmp
# - copy powershell folder to dotfiles
# - remove tmp

Write-Title "Download Paxos` dotfiles"
Write-Output "Creating dotfiles folder..."
$dir = EnsureDir "$env:home\dotfiles"

# download dotfiles zip
$zip_url = "https://github.com/Paxxs/dotfiles-win/archive/master.zip"
$zip_file = "$dir\dotfiles.zip"
Write-Output "Downloading dotfiles in $zip_file"
DownloadFile -url $zip_url -target $zip_file

# Extract zip
Write-Output 'Extracting...'
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[IO.Compression.ZipFile]::ExtractToDirectory($zip_file, "$dir\_tmp")
Copy-Item "$dir\_tmp\*master\powershell" $dir -Recurse -Force
Remove-Item "$dir\_tmp", $zip_file -Recurse -Force
#endregion

#region powershell & install scoop
# - powershell profile
# - powershell module
# - install scoop and update first

if ($level -ge $LevelMinimal) {
    Write-Title "Stow powershell legacy profile"
    StowFile $Global:profile "$dir\powershell\Microsoft.PowerShell_profile.ps1"

    Write-Title "Install scoop"
    $customScoop = TimeoutPrompt "Press key to intervene in scoop installer" 5
    if ($customScoop) {
        $scoopDir = Read-Host "Where do u want to install (Enter: default)"
        if ($scoopDir) {
            [System.Environment]::setEnvironmentVariable('SCOOP', $scoopDir, 'User')
            $env:SCOOP = $scoopDir # with this we don't need to close and reopen the console
        }
        $scoopGlobalDir = Read-Host "Set global installation to custom directory (Enter: default)"
        if ($scoopGlobalDir) {
            [System.Environment]::setEnvironmentVariable('SCOOP_GLOBAL', $scoopGlobalDir, 'Machine')
            $env:SCOOP_GLOBAL = $scoopGlobalDir
        }
    }
    Invoke-Expression (new-object net.webclient).downloadstring('https://get.scoop.sh')

    Write-Output "configure scoop alias..."
    scoop alias add S 'scoop install $args[0]' 'Install apps'
    scoop alias add Su 'sudo scoop install $args[0]' 'Install apps (with sudo)'
    scoop alias add Ss 'scoop search $args[0]' 'Search available apps'
    scoop alias add Si 'scoop info $args[0]' 'Display information about an app'
    scoop alias add Sy 'scoop update $args[0]' 'Update apps, or Scoop itself'
    scoop alias add Syu 'sudo scoop update *' 'Updates all apps (with sudo)'
    scoop alias add R 'scoop uninstall $args[0]' 'Uninstall an app'
    scoop alias add Ru 'sudo scoop uninstall $args[0]' 'Uninstall an app (with sudo)'
    scoop alias add Fs 'scoop prefix $args[0]' 'Returns the path to the specified app'

    Write-Title "Install basic app..."
    $app_list = @(
        "git",
        "7zip",
        "aria2",
        "fzf",
        "sudo"
        "curl",
        "sed",
        "less",
        "gpg",
        "busybox",
        "openssh"
    ) | ForEach-Object {
        # InsScoop -appsName $_
        InsScoop -appsName $_ -isCore $true
    }
}

Write-Title "Clone scoop Bucket"
if ($level -ge $LevelMinimal) {
    $bucket_list = @(
        ("Extras bucket for Scoop", "extras"),
        ("nonportable applications", "nonportable"),
        ("Cluttered bucket", "MorFans", "https://github.com/Paxxs/Cluttered-bucket.git")
    ) | ForEach-Object {
        Write-Output "Cloning bucket: "$_[0]
        if ([string]::IsNullOrWhiteSpace($_[2])) {
            # official
            AddScoopBucket -bu_name $_[1]
        }
        else {
            AddScoopBucket -bu_name $_[1] -bu_url $_[2]
        }
    }
}
if ($level -ge $LevelBasic) {
    $bucket_list = @(
        ("JAVA Bucket", "java"),
        ("PHP Bucket", "php"),
        ("Installing nerd fonts", "nerd-fonts"),
        ("h404bi`s bucket", "dorado", "https://github.com/h404bi/dorado.git"),
        ("Ash258 Personal bucket", "Ash258", "https://github.com/Ash258/scoop-Ash258.git"),
        ("Reverse engineering tools", "retools", "https://github.com/TheCjw/scoop-retools.git"),
        ("All Sysinternals tools separately", "Sysinternals", "https://github.com/Ash258/Scoop-Sysinternals.git")
    ) | ForEach-Object {
        Write-Output "Cloning bucket: $($_[0])"
        if ([string]::IsNullOrWhiteSpace($_[2])) {
            # official
            AddScoopBucket -bu_name $_[1]
        }
        else {
            AddScoopBucket -bu_name $_[1] -bu_url $_[2]
        }
    }
    if ($level -ge $levelFull) {
        Write-Output "Cloning bucket: portableapps.com"
        AddScoopBucket -bu_name "portableapps" -bu_url "https://github.com/nickbudi/scoop-bucket.git"
    }
}



Write-Title "Install PowerShell Module"
if ($level -ge $LevelMinimal) {
    Write-Verbose "Install Module: posh-git"
    Install-Module posh-git -Scope CurrentUser -Force
}
if ($level -ge $LevelBasic) {
    Write-Verbose "Install Module: oh-my-posh"
    Install-Module oh-my-posh -Scope CurrentUser -Force
    
    #  Administrator rights are required
    Write-Verbose "Install Module: Get-ChildItemColor"
    Install-Module -AllowClobber Get-ChildItemColor -Force
    
    if(!(Get-Command z -ErrorAction SilentlyContinue)) {
        Write-Verbose "Install Module: z"
        Install-Module z -AllowClobber -Scope CurrentUser -Force
    }
    
    if(!(Get-Module PSFzf)) {
        Write-Verbose "Install Module: PSFzf"
        Install-Module -Name PSFzf -Force
    }
}
#endregion

#region Install Software
if ($level -ge $LevelBasic) {
    Write-Title "Install application..."
    $app_list = @(
        "extras/aria-ng-gui",
        "extras/dismplusplus",
        "extras/dnspy",
        "extras/everything",
        "nerd-fonts/FantasqueSansMono-NF",
        "MorFans/FastCopy-M",
        "MorFans/filezilla",
        "nerd-fonts/FiraCode",
        "nerd-fonts/FiraMono-NF",
        "main/frp",
        "extras/gifcam",
        "extras/joplin",
        "extras/keeweb",
        "extras/locale-emulator",
        "extras/mkcert",
        "main/nodejs",
        "ojdkbuild8-full",
        "extras/postman",
        "extras/processhacker",
        "extras/putty",
        "extras/resource-hacker",
        "tcping",
        "MorFans/UAC.HashTab",
        "extras/v2rayN",
        "winPython"
    ) | ForEach-Object {
        InsScoop -appsName $_ -isCore $true
    }
}
if ($level -ge $levelFull) {
    # Cspell:disable
    $app_list = @(
        # "MorFans/AliWangWang",
        "portableapps/authy-desktop",
        "MorFans/bingdian",
        "dorado/chfs",
        "ffmpeg",
        "MorFans/FFRenamePro",
        "fiddler",
        "extras/format-factory",
        "extras/googlechrome-dev",
        "dorado/hmcl",
        "MorFans/IDA-Pro.64",
        "MorFans/JJDown",
        "MorFans/LDPlayer.clear",
        # "dorado/magicavoxel",
        "MorFans/mofang-PCMaster-full",
        "nmap",
        "extras/obs-studio",
        "dorado/pandownload",
        "MorFans/potplayer-mini.64",
        "powertoys",
        "extras/rufus",
        "nerd-fonts/SarasaGothic-ttc",
        "extras/screentogif",
        "syncthing",
        "MorFans/tb-Toolbox",
        "extras/tor-browser",
        "dorado/trafficmonitor",
        "extras/typora",
        "MorFans/UAC.Listary5.Third",
        # "MorFans/UAC.QQ_Portable",
        # "MorFans/UAC.ThunderX",
        # "MorFans/UAC.Xmind-8",
        "MorFans/UAC.xshell6",
        # "MorFans/UAC.YoudaoDict.Pure",
        # "MorFans/WeChat-Portable",
        "MorFans/Windows.Auto.Night.Mode",
        "extras/wireshark"
    ) | ForEach-Object {
        InsScoop -appsName $_
    }
    # Cspell:enable
}
#endregion