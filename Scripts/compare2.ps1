# compare2.ps1
# Windows protection audit report generator used by the Electron app

function Get-AuditResult {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Name,
		[object]$Current,
		[Parameter(Mandatory = $true)]
		[object]$Required
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
	}
}

function Test-FirewallEnabled {
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

function Test-Smb1Disabled {
	try {
		if (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
			$feature = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop
			if ($null -eq $feature) {
				return $null
			}

			return $feature.State -ne 'Enabled'
		}
	} catch {
		return $null
	}

	return $null
}

function Test-RdpDisabled {
	try {
		$rdpValue = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -ErrorAction Stop
		return [int]$rdpValue -eq 1
	} catch {
		return $null
	}
}

function Test-SecureBootEnabled {
	try {
		if (Get-Command Confirm-SecureBootUEFI -ErrorAction SilentlyContinue) {
			return [bool](Confirm-SecureBootUEFI)
		}
	} catch {
		return $null
	}

	return $null
}

function Test-BitLockerEnabled {
	try {
		if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
			$systemDrive = $env:SystemDrive
			$volume = Get-BitLockerVolume -MountPoint $systemDrive -ErrorAction Stop
			if ($null -eq $volume) {
				return $null
			}

			return $volume.ProtectionStatus -eq 'On'
		}
	} catch {
		return $null
	}

	return $null
}

function Test-GuestAccountDisabled {
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

$results = @(
	Get-AuditResult -Name 'Firewall profiles enabled' -Current (Test-FirewallEnabled) -Required $true
	Get-AuditResult -Name 'SMBv1 disabled' -Current (Test-Smb1Disabled) -Required $true
	Get-AuditResult -Name 'Remote Desktop disabled' -Current (Test-RdpDisabled) -Required $true
	Get-AuditResult -Name 'Secure Boot enabled' -Current (Test-SecureBootEnabled) -Required $true
	Get-AuditResult -Name 'BitLocker enabled on system drive' -Current (Test-BitLockerEnabled) -Required $true
	Get-AuditResult -Name 'Built-in guest account disabled' -Current (Test-GuestAccountDisabled) -Required $true
)

$mismatchCount = @($results | Where-Object { -not $_.Compliant }).Count
$generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$currentLines = foreach ($item in $results) {
	'{0,-46} {1}' -f ($item.Name + ':'), $item.Current
}
$requiredLines = foreach ($item in $results) {
	'{0,-46} {1}' -f ($item.Name + ':'), $item.Required
}

$report = @"
Audit report generated: $generatedAt

$mismatchCount unmatched configurations in your system found

$($currentLines -join "`n")

Required configurations:
$($requiredLines -join "`n")
"@

Write-Output $report
