# Installs an APK on an Android emulator, starts the app the way the
# launcher does, draws a few strokes, and saves screenshots and the app's
# log. Fails if the app crashed or logged a Dart error.
#
#   powershell -ExecutionPolicy Bypass -File tool\android_smoke.ps1
#   powershell -ExecutionPolicy Bypass -File tool\android_smoke.ps1 -Avd medium_phone -Apk dist\JoyPainting-v4.1.0-x86_64.apk
#
# Without -Apk it uses the newest x86_64 APK in dist\ (build one with
# tool\build_apk.ps1). The emulator is started (cold boot) if none is
# running. Installing over an existing install keeps the paintings.
param(
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [string]$Apk,
    [string]$Avd = 'medium_tablet',
    [string]$Out = 'build\android_screens',
    [int]$Strokes = 3
)

$package = 'com.personal.jingyaopaint'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
Set-Location $Root
New-Item -ItemType Directory -Force $Out | Out-Null

if (-not $Apk) {
    $found = Get-ChildItem dist -Filter '*-x86_64.apk' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $found) { Write-Output 'SMOKE: FAIL (no x86_64 APK in dist\; run tool\build_apk.ps1)'; exit 1 }
    $Apk = $found.FullName
}
Write-Output "APK: $Apk"

function Invoke-Adb([string[]]$adbArgs) {
    # adb writes progress to stderr; keep only its output.
    $output = & $adb @adbArgs 2>$null
    return $output
}

# --- An emulator -------------------------------------------------------------
$running = (Invoke-Adb @('devices')) -match '^emulator-\d+\s+device'
if (-not $running) {
    Write-Output "Starting emulator $Avd (cold boot)..."
    Start-Process -FilePath $emulator -ArgumentList @('-avd', $Avd, '-no-snapshot-load') -WindowStyle Minimized
    Invoke-Adb @('wait-for-device') | Out-Null
    $deadline = (Get-Date).AddMinutes(4)
    while ((Invoke-Adb @('shell', 'getprop', 'sys.boot_completed')) -ne '1') {
        if ((Get-Date) -gt $deadline) { Write-Output 'SMOKE: FAIL (emulator did not finish booting)'; exit 1 }
        Start-Sleep -Seconds 3
    }
    # The launcher needs a moment after boot.
    Start-Sleep -Seconds 10
}
$model = Invoke-Adb @('shell', 'getprop', 'ro.product.model')
$release = Invoke-Adb @('shell', 'getprop', 'ro.build.version.release')
$size = ((Invoke-Adb @('shell', 'wm', 'size')) -split ':')[-1].Trim()
Write-Output "Device: $model, Android $release, $size"

# --- Install and start -------------------------------------------------------
# Release APKs are split per CPU type, which adds 4000 to an x86_64 APK's
# version code; an unsplit APK has a lower code and counts as a downgrade.
$install = (& $adb install -r $Apk 2>&1 | ForEach-Object { "$_" }) -join ' '
if ($install -notmatch 'Success') { Write-Output "SMOKE: FAIL (install: $install)"; exit 1 }
Invoke-Adb @('shell', 'am', 'force-stop', $package) | Out-Null
Invoke-Adb @('logcat', '-c') | Out-Null
# Through the launcher intent, as a tap on the icon does.
Invoke-Adb @('shell', 'monkey', '-p', $package, '-c', 'android.intent.category.LAUNCHER', '1') | Out-Null
Start-Sleep -Seconds 12

function Save-Screen([string]$name) {
    Invoke-Adb @('shell', 'screencap', '-p', "/sdcard/$name.png") | Out-Null
    Invoke-Adb @('pull', "/sdcard/$name.png", (Join-Path $Out "$name.png")) | Out-Null
    Invoke-Adb @('shell', 'rm', "/sdcard/$name.png") | Out-Null
    Write-Output ("Screenshot: " + (Join-Path $Out "$name.png"))
}
Save-Screen 'start'

# --- Draw a few strokes across the middle of the screen ------------------------
if ($Strokes -gt 0 -and $size -match '(\d+)x(\d+)') {
    $w = [int]$Matches[1]; $h = [int]$Matches[2]
    for ($i = 0; $i -lt $Strokes; $i++) {
        $y1 = [int]($h * (0.35 + 0.08 * $i)); $y2 = [int]($h * (0.45 + 0.08 * $i))
        Invoke-Adb @('shell', 'input', 'swipe', [int]($w * 0.3), $y1, [int]($w * 0.6), $y2, '400') | Out-Null
    }
    Start-Sleep -Seconds 2
    Save-Screen 'drawn'
}

# --- Still running? Any errors? ----------------------------------------------
$appPid = Invoke-Adb @('shell', 'pidof', $package)
$logFile = Join-Path $Out 'app.log'
Invoke-Adb @('logcat', '-d') | Out-File -Encoding utf8 $logFile
$errors = Select-String -Path $logFile -Pattern 'FATAL EXCEPTION|E/flutter|Unhandled Exception' |
    Where-Object { $_.Line -match $package -or $_.Line -match 'flutter' }
if (-not $appPid) { Write-Output "SMOKE: FAIL (the app is not running; see $logFile)"; exit 1 }
if ($errors) {
    $errors | Select-Object -First 10 | ForEach-Object { Write-Output $_.Line }
    Write-Output "SMOKE: FAIL (errors in the log; see $logFile)"
    exit 1
}
Write-Output "SMOKE: PASS (running as pid $appPid, no errors in the log)"
