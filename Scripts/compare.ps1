# compare.ps1
# Simple generator for audit report used by the Electron app during testing
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path $scriptRoot -Parent
$reportPath = Join-Path $projectRoot 'tests\results\result.txt'

$report = @'
3 unmatched configurations in your system found

Maximum password age (days):                          42
Lockout duration (minutes):                           10
Lockout observation window (minutes):                 10

Required configurations:
Maximum password age (days):                          50
Lockout duration (minutes):                           25
Lockout observation window (minutes):                 15
'@

# Ensure directory exists
$reportDir = Split-Path $reportPath -Parent
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }

# Write report
$report | Out-File -FilePath $reportPath -Encoding utf8 -Force

# Also output to stdout for immediate feedback
Write-Output $report
