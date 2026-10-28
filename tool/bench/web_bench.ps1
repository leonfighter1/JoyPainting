# Measures how smooth drawing on a big painting is in Chrome: builds the
# benchmark page (tool/bench/web_bench.dart) in profile mode, serves it on
# this computer, opens it in a separate Chrome window with its own empty
# profile, and waits for the frame timings. Nothing in the app or your
# Chrome profile is touched.
#
#   powershell -ExecutionPolicy Bypass -File tool\bench\web_bench.ps1
#   powershell -ExecutionPolicy Bypass -File tool\bench\web_bench.ps1 -Sample intermediate
param(
    [string]$Root = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [string]$Sample = 'advanced',
    [int]$Port = 8123,
    [int]$TimeoutMinutes = 15
)

Set-Location $Root
$site = 'build\bench_web'
$out = "build\bench\web_$Sample.json"
Remove-Item $out -ErrorAction SilentlyContinue

flutter build web --profile -t tool/bench/web_bench.dart --dart-define=SAMPLE=$Sample --no-web-resources-cdn -o $site
if ($LASTEXITCODE -ne 0) { Write-Output 'BENCH: FAIL (build)'; exit 1 }

$server = Start-Process dart -ArgumentList @('run', 'tool/bench/serve.dart', $site, $out, $Port) -PassThru -NoNewWindow
Start-Sleep -Seconds 3

# Its own profile, so the run is clean and your browser is left alone.
# The window has to stay visible: hidden tabs get no frames.
$profileDir = Join-Path $env:TEMP 'joypainting-bench-chrome'
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
Start-Process $chrome -ArgumentList @(
    "--user-data-dir=$profileDir", '--no-first-run', '--no-default-browser-check',
    '--disable-background-timer-throttling', '--disable-renderer-backgrounding',
    '--disable-backgrounding-occluded-windows', '--window-size=1280,900',
    '--new-window', "http://127.0.0.1:$Port/") | Out-Null

$finished = $server.WaitForExit($TimeoutMinutes * 60 * 1000)
Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe'" |
    Where-Object { $_.CommandLine -like "*joypainting-bench-chrome*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
if (-not $finished) {
    Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    Write-Output 'BENCH: FAIL (no result in time)'
    exit 1
}
Write-Output "BENCH: done, results in $out"
