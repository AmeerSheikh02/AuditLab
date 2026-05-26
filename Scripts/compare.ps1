# compare.ps1
# Windows system audit report generator used by the Electron app
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path $scriptRoot -Parent

function Get-PolicyValue {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Text,
		[Parameter(Mandatory = $true)]
		[string]$Label,
		[switch]$AllowTextValue
	)

	$pattern = [regex]::Escape($Label) + '\s*:\s*(.+)$'
	$match = [regex]::Match($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
	if (-not $match.Success) {
		throw "Could not find '$Label' in net accounts output."
	}

	$valueText = $match.Groups[1].Value.Trim()
	if ($AllowTextValue) {
		return $valueText
	}

	if ($valueText -match '^(\d+)$') {
		return [int]$Matches[1]
	}

	throw "Expected numeric value for '$Label' but found '$valueText'."
}

function Get-AuditResult {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Name,
		[Parameter(Mandatory = $true)]
		[object]$Current,
		[Parameter(Mandatory = $true)]
		[object]$Required,
		[switch]$FailedIfUnavailable
	)

	$currentText = if ($null -eq $Current -or $Current -eq '') { 'Unavailable' } else { [string]$Current }
	$requiredText = [string]$Required
	$compliant = $false

	if ($null -ne $Current -and $Current -ne '') {
		$compliant = $Current -eq $Required
	}

	[pscustomobject]@{
		Name = $Name
		Current = $currentText
		Required = $requiredText
		Compliant = $compliant
		FailedIfUnavailable = [bool]$FailedIfUnavailable
	}
}

function Get-BuiltinGuestDisabled {
	try {
		$guestAccount = Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True" |
			Where-Object { $_.SID -like '*-501' } |
			Select-Object -First 1

		if ($null -eq $guestAccount) {
			return $null
		}

		return [bool]$guestAccount.Disabled
	} catch {
		return $null
	}
}

function Get-RealTimeProtectionEnabled {
	try {
		if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
			$status = Get-MpComputerStatus
			return [bool]$status.RealTimeProtectionEnabled
		}
	} catch {
		return $null
	}

	return $null
}

function Get-FirewallProfilesEnabled {
	try {
		if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
			$profiles = Get-NetFirewallProfile
			if ($null -eq $profiles) {
				return $null
			}

			return (@($profiles | Where-Object { $_.Enabled -eq $false }).Count -eq 0)
		}
	} catch {
		return $null
	}

	return $null
}

function Get-UacEnabled {
	try {
		$uacValue = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -ErrorAction Stop
		return [int]$uacValue -eq 1
	} catch {
		return $null
	}
}

$policyOutput = & net accounts 2>&1
if ($LASTEXITCODE -ne 0) {
	throw "Failed to read Windows account policy: $policyOutput"
}

$policyText = [string]::Join("`n", $policyOutput)

$maximumPasswordAge = Get-PolicyValue -Text $policyText -Label 'Maximum password age (days)'
$lockoutDuration = Get-PolicyValue -Text $policyText -Label 'Lockout duration (minutes)'
$lockoutObservationWindow = Get-PolicyValue -Text $policyText -Label 'Lockout observation window (minutes)'

$realTimeProtectionEnabled = Get-RealTimeProtectionEnabled
$firewallProfilesEnabled = Get-FirewallProfilesEnabled
$uacEnabled = Get-UacEnabled
$guestAccountDisabled = Get-BuiltinGuestDisabled

$requiredMaximumPasswordAge = 50
$requiredLockoutDuration = 25
$requiredLockoutObservationWindow = 15
$requiredRealTimeProtectionEnabled = $true
$requiredFirewallProfilesEnabled = $true
$requiredUacEnabled = $true
$requiredGuestAccountDisabled = $true

$auditResults = @(
	Get-AuditResult -Name 'Maximum password age (days)' -Current $maximumPasswordAge -Required $requiredMaximumPasswordAge
	Get-AuditResult -Name 'Lockout duration (minutes)' -Current $lockoutDuration -Required $requiredLockoutDuration
	Get-AuditResult -Name 'Lockout observation window (minutes)' -Current $lockoutObservationWindow -Required $requiredLockoutObservationWindow
	Get-AuditResult -Name 'Defender real-time protection enabled' -Current $realTimeProtectionEnabled -Required $requiredRealTimeProtectionEnabled
	Get-AuditResult -Name 'Firewall profiles enabled' -Current $firewallProfilesEnabled -Required $requiredFirewallProfilesEnabled
	Get-AuditResult -Name 'UAC enabled' -Current $uacEnabled -Required $requiredUacEnabled
	Get-AuditResult -Name 'Built-in guest account disabled' -Current $guestAccountDisabled -Required $requiredGuestAccountDisabled
)

$mismatchCount = @($auditResults | Where-Object { -not $_.Compliant }).Count

$generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$currentLines = foreach ($item in $auditResults) {
	'{0,-46} {1}' -f ($item.Name + ':'), $item.Current
}

$requiredLines = foreach ($item in $auditResults) {
	'{0,-46} {1}' -f ($item.Name + ':'), $item.Required
}

$report = @"
Audit report generated: $generatedAt

$mismatchCount unmatched configurations in your system found

$($currentLines -join "`n")

Required configurations:
$($requiredLines -join "`n")
"@

# Also output to stdout for immediate feedback
Write-Output $report
