param(
  [switch]$SkipPublishDryRun
)

$ErrorActionPreference = "Stop"

function Run-Step {
  param(
    [string]$Name,
    [string]$Command
  )
  Write-Host "==> $Name"
  powershell -NoProfile -ExecutionPolicy Bypass -Command $Command
}

function Run-PublishDryRun {
  Write-Host "==> Mooncakes publish dry run"
  $output = & moon publish --dry-run 2>&1
  $exitCode = $LASTEXITCODE
  $output | ForEach-Object { Write-Host $_ }
  $joined = $output -join "`n"
  if ($exitCode -ne 0) {
    if ($joined.Contains("Server status: 202 Accepted") -and
        $joined.Contains("Dry run completed successfully")) {
      Write-Warning "moon publish --dry-run returned exit code $exitCode after a server-accepted dry run. Treating this as a Moon CLI exit-code quirk, not a published release."
    } else {
      throw "moon publish --dry-run failed with exit code $exitCode"
    }
  }
}

Run-Step "MoonBit version" "moon version --all"
Run-Step "Format check" "moon fmt --check"
Run-Step "Check all targets" "moon check --target all"
Run-Step "Strict check" "moon check --deny-warn"
Run-Step "Build" "moon build"
Run-Step "Test all targets" "moon test --target all"
Run-Step "Strict test" "moon test --deny-warn"
Run-Step "Generated interfaces" "moon info; git diff --exit-code"
Run-Step "CLI help" "moon run src/main -- --help"
Run-Step "Example package" "moon run examples/basic"
Run-Step "Showcase example" "moon run examples/showcase"
Run-Step "Matrix example" "moon run examples/matrix"
Run-Step "Benchmark smoke" "moon run benchmarks/main"

if (-not $SkipPublishDryRun) {
  Run-PublishDryRun
}

Write-Host "==> Effective MoonBit source lines"
Get-ChildItem -Recurse -Filter *.mbt |
  Where-Object { $_.Name -notlike "pkg.generated*" } |
  ForEach-Object {
    Get-Content $_.FullName |
      Where-Object {
        $t = $_.Trim()
        $t -ne "" -and -not $t.StartsWith("//") -and -not $t.StartsWith("///")
      }
  } |
  Measure-Object |
  ForEach-Object { Write-Host ("code-like .mbt lines: " + $_.Count) }
