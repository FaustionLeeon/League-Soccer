# Run Windows game tests, optionally saving diagnostic frames for visual review.
param(
  [string]$BuildDirectory = (Join-Path $PSScriptRoot '..\build-win'),
  [ValidateSet('Release', 'Debug', 'RelWithDebInfo')][string]$Configuration = 'Release',
  [switch]$SkipBuild,
  [switch]$CaptureFrames
)
$ErrorActionPreference = 'Stop'
$projectDirectory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$BuildDirectory = (Resolve-Path $BuildDirectory).Path
$executable = Join-Path $BuildDirectory "$Configuration\gameplayfootball.exe"
if (Get-Process gameplayfootball -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $executable }) {
  throw 'Close the running game before testing to avoid competing game sessions.'
}
if (-not $SkipBuild) {
  & cmake --build $BuildDirectory --config $Configuration --parallel 4
  if ($LASTEXITCODE -ne 0) { throw 'Game build failed.' }
}
& ctest --test-dir $BuildDirectory -C $Configuration --output-on-failure --parallel 4
if ($LASTEXITCODE -ne 0) { throw 'Automated tests failed.' }
if (-not (Test-Path -LiteralPath $executable)) { throw "Game executable missing: $executable" }
$outputDirectory = Join-Path $BuildDirectory ('visual-smoke-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $outputDirectory | Out-Null
$cases = @(
  @{Name='quick-720p'; Config='menu_smoke_quick_match.config'; Width=1280; Height=720; Markers=@('Quick Match verification succeeded')},
  @{Name='quick-ultrawide'; Config='menu_smoke_quick_match.config'; Width=1920; Height=810; Markers=@('Quick Match verification succeeded')},
  @{Name='graphics-settings'; Config='menu_smoke_settings_graphics.config'; Width=1280; Height=720; Markers=@('Settings Graphics page reached successfully')},
  @{Name='audio-settings'; Config='menu_smoke_settings_audio.config'; Width=1280; Height=720; Markers=@('Settings Audio page reached successfully')},
  @{Name='player-control-match'; Config='menu_smoke_gamepad_match.config'; Width=1280; Height=720; Markers=@('scripted gamepad: input sampled, driving a human player in a live match','Full-match verification succeeded')}
)
$previousCaptureDirectory = $env:GF_CAPTURE_DIRECTORY
try {
  foreach ($case in $cases) {
    $caseDirectory = Join-Path $outputDirectory $case.Name
    New-Item -ItemType Directory -Path $caseDirectory | Out-Null
    $configPath = Join-Path $caseDirectory 'test.config'
    $logPath = Join-Path $caseDirectory 'stdout.log'
    $errorPath = Join-Path $caseDirectory 'stderr.log'
    $settings = Get-Content (Join-Path $projectDirectory ('data\' + $case.Config)) -Raw
    $settings += "`n`"audio_volume`" `"0`"`n`"context_x`" `"$($case.Width)`"`n`"context_y`" `"$($case.Height)`"`n`"context_fullscreen`" `"false`"`n"
    [IO.File]::WriteAllText($configPath, $settings)
    $env:GF_CAPTURE_DIRECTORY = if ($CaptureFrames) { Join-Path $caseDirectory 'frames' } else { $null }
    Write-Host "Testing $($case.Name)..."
    $gameProcess = Start-Process -FilePath $executable -ArgumentList ('"' + $configPath + '"') -WorkingDirectory (Split-Path $executable) -WindowStyle Hidden -RedirectStandardOutput $logPath -RedirectStandardError $errorPath -PassThru
    try {
      # Retain the native handle so Windows PowerShell can read ExitCode after exit.
      $null = $gameProcess.Handle
      if (-not $gameProcess.WaitForExit(240000)) { throw "$($case.Name) timed out. See $logPath" }
      if ($gameProcess.ExitCode -ne 0) { throw "$($case.Name) exited with $($gameProcess.ExitCode). See $logPath" }
      foreach ($marker in $case.Markers) {
        if (-not (Select-String -LiteralPath $logPath -Pattern $marker -SimpleMatch -Quiet)) { throw "$($case.Name) missing success marker: $marker" }
      }
      if (Select-String -LiteralPath $logPath,$errorPath -Pattern '\[(FatalError|FATAL ERROR[^\]]*|Error|Warning)\]' -Quiet) { throw "$($case.Name) reported a warning or error. See $caseDirectory" }
      if ($CaptureFrames -and @(Get-ChildItem -LiteralPath $env:GF_CAPTURE_DIRECTORY -Filter '*.png').Count -eq 0) { throw "$($case.Name) produced no render captures." }
      Write-Host "PASS: $($case.Name)"
    } finally {
      if (-not $gameProcess.HasExited) { Stop-Process -Id $gameProcess.Id }
      $gameProcess.Dispose()
    }
  }
} finally {
  $env:GF_CAPTURE_DIRECTORY = $previousCaptureDirectory
}
Write-Host "All checks passed. Results: $outputDirectory"
