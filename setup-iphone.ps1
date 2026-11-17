# TU Student - iPhone setup for Windows
# Installs iTunes (iPhone USB drivers) and iloader, then opens iloader so you can
# install SideStore on your iPhone. Run in PowerShell:
#   irm https://raw.githubusercontent.com/1aristarh/TU-Student-releases/main/setup-iphone.ps1 | iex

$ErrorActionPreference = 'Stop'
$Source = 'https://raw.githubusercontent.com/1aristarh/TU-Student-releases/main/sidestore.json'

function Step($n, $text) { Write-Host "`n[$n/4] $text" -ForegroundColor Cyan }
function Fail($text) { Write-Host "`n$text" -ForegroundColor Red; Read-Host 'Press Enter to close'; exit 1 }

Write-Host 'TU Student - iPhone setup' -ForegroundColor Green

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Fail 'winget is missing. Install "App Installer" from the Microsoft Store, then run this again.'
}

Step 1 'Checking iTunes...'
if (Get-AppxPackage -Name 'AppleInc.iTunes' -ErrorAction SilentlyContinue) {
    Write-Host 'You have the Microsoft Store version of iTunes. It does not work for this.' -ForegroundColor Yellow
    if ((Read-Host 'Remove it and install the Apple version? (y/n)') -ne 'y') { Fail 'Stopped. Uninstall Store iTunes yourself and run again.' }
    Get-AppxPackage -Name 'AppleInc.iTunes' | Remove-AppxPackage
}
$itunes = winget list -e --id Apple.iTunes --accept-source-agreements 2>$null | Select-String 'Apple.iTunes'
if ($itunes) { Write-Host 'iTunes already installed.' }
else {
    Write-Host 'Installing iTunes (needed for the iPhone USB driver). Accept the admin prompt.'
    winget install -e --id Apple.iTunes --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { Fail 'iTunes install failed. Install it from https://www.apple.com/itunes/download/win64/ and run again.' }
}

Step 2 'Installing iloader...'
winget install -e --id nabdev.iloader --silent --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0 -and -not (winget list -e --id nabdev.iloader 2>$null | Select-String 'iloader')) {
    Fail 'iloader install failed. Download it from https://github.com/nab138/iloader/releases/latest and run again.'
}

Step 3 'Opening iloader...'
$exe = Get-ChildItem "$env:LOCALAPPDATA\Programs", $env:ProgramFiles, "$env:LOCALAPPDATA\iloader" -Filter 'iloader*.exe' -Recurse -Depth 2 -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch 'unins' } | Select-Object -First 1
if ($exe) { Start-Process $exe.FullName } else { Write-Host 'Open "iloader" from the Start menu.' -ForegroundColor Yellow }

Step 4 'Now do this:'
Write-Host @"

  ON THE PC (iloader):
    1. Plug in the iPhone with a cable, unlock it, tap "Trust".
    2. In iloader, sign in with your Apple ID.
    3. Click "Install SideStore" and wait until it says done.

  ON THE iPHONE:
    4. Settings > Privacy & Security > Developer Mode > On  (phone restarts)
    5. Settings > General > VPN & Device Management > trust your Apple ID
    6. Install "LocalDevVPN" from the App Store, open it once and allow the VPN.
    7. Open SideStore > Sources > + and paste (already copied to your clipboard):
         $Source
    8. Open the TU Student source > Get.
    9. Set up the nightly auto-refresh (Shortcuts) - see the video.

"@
Set-Clipboard -Value $Source
Write-Host 'The source link is on your clipboard - send it to your phone.' -ForegroundColor Green
Read-Host 'Press Enter to close'
