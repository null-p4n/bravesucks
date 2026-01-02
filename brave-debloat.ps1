<#
Brave Browser Debloat & Privacy Enhancement Script (Windows PowerShell)

This script mirrors the Linux bash workflow and:
- Detects Brave on Windows and builds a privacy-focused launcher with hardened flags.
- Prompts to disable Brave AI/Leo features (default: disable).
- Backs up Preferences/Local State before editing.
- Cleans common Brave settings (Rewards, Ads, Wallet, Telemetry, IPFS, AI if selected).
- Removes selected lab flags from Local State.
- Blocks Brave telemetry domains in the hosts file when running as Administrator (otherwise prints manual entries).
- Optionally applies Brave policy registry keys aligned with the included example/brave.reg.
#>

Write-Host "=== Brave Browser Privacy & Debloating (Windows) ===`n"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Detect Brave executable
$candidatePaths = @(
    "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
    "$env:ProgramFiles(x86)\BraveSoftware\Brave-Browser\Application\brave.exe",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"
)

$braveExe = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $braveExe) {
    Write-Warning "Could not find Brave Browser executable. Continuing, but launcher creation may fail."
    $braveExe = "brave.exe"
} else {
    Write-Host "Found Brave executable at: $braveExe"
}

# Prompt for Brave AI disablement
$disableBraveAI = $true
$aiResponse = Read-Host "Disable Brave AI/Leo features (recommended)? [Y/n]"
if ($aiResponse) {
    switch ($aiResponse.ToLower()) {
        "n" { $disableBraveAI = $false }
        "no" { $disableBraveAI = $false }
    }
}

# User data paths
$userDataDir = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data"
$profileDir = Join-Path $userDataDir "Default"
if (-not (Test-Path $profileDir)) {
    $profileDir = Get-ChildItem -Path $userDataDir -Filter "Profile *" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($profileDir) {
        $profileDir = $profileDir.FullName
    }
}

if (-not $profileDir) {
    Write-Warning "No Brave profile found under $userDataDir. Preferences edits will be skipped."
}

# Backup preferences
$backupDir = Join-Path $env:USERPROFILE ("brave-backup-" + (Get-Date -Format "yyyyMMddHHmmss"))
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

if ($profileDir) {
    $prefPath = Join-Path $profileDir "Preferences"
    $localStatePath = Join-Path $userDataDir "Local State"

    if (Test-Path $prefPath) {
        Copy-Item $prefPath (Join-Path $backupDir "Preferences.bak")
        Write-Host "✓ Backed up Preferences to $backupDir"
    }
    if (Test-Path $localStatePath) {
        Copy-Item $localStatePath (Join-Path $backupDir "Local_State.bak")
        Write-Host "✓ Backed up Local State to $backupDir"
    }
}

function Ensure-HashtablePath {
    param (
        [hashtable] $Root,
        [string[]] $PathSegments
    )
    $current = $Root
    for ($i = 0; $i -lt $PathSegments.Count - 1; $i++) {
        $segment = $PathSegments[$i]
        if (-not $current.ContainsKey($segment) -or $current[$segment] -eq $null -or $current[$segment].GetType().Name -ne "Hashtable") {
            $current[$segment] = @{}
        }
        $current = $current[$segment]
    }
    return $current
}

function Set-NestedValue {
    param (
        [hashtable] $Root,
        [string] $Path,
        $Value
    )
    $segments = $Path -split '\.'
    $container = Ensure-HashtablePath -Root $Root -PathSegments $segments
    $container[$segments[-1]] = $Value
}

# Modify Preferences
function Convert-PSObjectToHashtable {
    param ($InputObject)
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $InputObject.Keys) {
            $result[$key] = Convert-PSObjectToHashtable $InputObject[$key]
        }
        return $result
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { Convert-PSObjectToHashtable $_ })
    }
    return $InputObject
}

function ConvertFrom-JsonToHashtable {
    param ([string] $Json)
    $convertCmd = Get-Command ConvertFrom-Json
    if ($convertCmd.Parameters.ContainsKey("AsHashtable")) {
        return $Json | ConvertFrom-Json -AsHashtable
    }
    return Convert-PSObjectToHashtable ($Json | ConvertFrom-Json)
}

if ($profileDir) {
    if (Test-Path $prefPath) {
        try {
            $pref = ConvertFrom-JsonToHashtable (Get-Content -Raw -Path $prefPath)
            Set-NestedValue -Root $pref -Path "brave.rewards.enabled" -Value $false
            Set-NestedValue -Root $pref -Path "brave.rewards.hide_button" -Value $true
            Set-NestedValue -Root $pref -Path "brave.brave_ads.enabled" -Value $false
            Set-NestedValue -Root $pref -Path "brave.brave_ads.opted_in" -Value $false
            Set-NestedValue -Root $pref -Path "brave.wallet.rpc_allowed_origins" -Value @()
            Set-NestedValue -Root $pref -Path "brave.wallet.keyring_lock_timeout_mins" -Value 0
            Set-NestedValue -Root $pref -Path "brave.p3a_enabled" -Value $false
            Set-NestedValue -Root $pref -Path "brave.stats.usage_ping_enabled" -Value $false
            Set-NestedValue -Root $pref -Path "brave.today.opted_in" -Value $false
            Set-NestedValue -Root $pref -Path "brave.ipfs.enabled" -Value $false
            if ($disableBraveAI) {
                Set-NestedValue -Root $pref -Path "brave.leo.enabled" -Value $false
                Set-NestedValue -Root $pref -Path "brave.leo.onboarding_seen" -Value $true
                Set-NestedValue -Root $pref -Path "brave.ai_chat.enabled" -Value $false
                Set-NestedValue -Root $pref -Path "brave.ai.autocomplete_enabled" -Value $false
            }
            $pref | ConvertTo-Json -Depth 100 | Set-Content -Path $prefPath -Encoding UTF8
            Write-Host "✓ Updated Brave Preferences"
        } catch {
            Write-Warning "Failed to update Preferences: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Preferences file not found at $prefPath"
    }

    # Modify Local State lab flags
    if (Test-Path $localStatePath) {
        try {
            $state = ConvertFrom-JsonToHashtable (Get-Content -Raw -Path $localStatePath)
            $flags = @(
                "brave-news",
                "brave-speedreader",
                "brave-wallet",
                "brave-ads-custom-push-notifications",
                "brave-vpn",
                "ipfs"
            )
            if ($disableBraveAI) {
                $flags += @(
                    "brave-leo",
                    "brave-leo-inline",
                    "brave-leo-lite",
                    "brave-ai-chat",
                    "brave-ai-prompts",
                    "brave-ai-autocomplete"
                )
            }
            if ($state.ContainsKey("browser")) {
                $experiments = $state["browser"]["enabled_labs_experiments"]
                if ($experiments) {
                    $state["browser"]["enabled_labs_experiments"] = @($experiments | Where-Object { $_ -and ($flags -notcontains $_) })
                }
            }
            $state | ConvertTo-Json -Depth 100 | Set-Content -Path $localStatePath -Encoding UTF8
            Write-Host "✓ Updated Brave Local State flags"
        } catch {
            Write-Warning "Failed to update Local State: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Local State file not found at $localStatePath"
    }
}

# Build disable-features list
$baseDisabledFeatures = @(
    "BraveRewards",
    "BraveAds",
    "BraveWallet",
    "BraveNews",
    "Speedreader",
    "BraveAdblock",
    "BraveSpeedreader",
    "BraveVPN",
    "Crypto",
    "CryptoWallets",
    "InterestCohortAPI",
    "Fledge",
    "Topics",
    "InterestFeedV2",
    "UseChromeOSDirectVideoDecoder"
)

$aiDisabledFeatures = @(
    "BraveLeo",
    "BraveLeoInline",
    "BraveAIChat",
    "BraveAIPrompts",
    "BravePromptAutocomplete"
)

$features = @($baseDisabledFeatures)
if ($disableBraveAI) {
    $features += $aiDisabledFeatures
}
$featuresArg = [string]::Join(",", $features)

# Create private launcher
$launcherDir = Join-Path $env:USERPROFILE "bin"
New-Item -ItemType Directory -Force -Path $launcherDir | Out-Null
$launcherPath = Join-Path $launcherDir "brave-private.cmd"

$launcherContent = @"
@echo off
"$braveExe" ^
  --disable-brave-sync ^
  --disable-features=$featuresArg ^
  --disable-background-networking ^
  --disable-component-extensions-with-background-pages ^
  --disable-domain-reliability ^
  --disable-sync-preferences ^
  --disable-site-isolation-trials ^
  --disable-prediction-service ^
  --disable-remote-fonts ^
  --disable-extensions-http-throttling ^
  --disable-breakpad ^
  --disable-speech-api ^
  --disable-translate ^
  --disable-sync ^
  --disable-first-run-ui ^
  --disable-client-side-phishing-detection ^
  --disable-component-updater ^
  --disable-suggestions-service ^
  --disable-webgl ^
  --no-pings ^
  --no-report-upload ^
  --no-service-autorun ^
  --no-first-run ^
  --aggressive-cache-discard ^
  --metrics-recording-only ^
  --clear-token-service ^
  --reset-variation-state ^
  --block-new-web-contents ^
  --start-maximized ^
  --incognito ^
  %*
"@

Set-Content -Path $launcherPath -Value $launcherContent -Encoding ASCII
Write-Host "✓ Created private Brave launcher at $launcherPath"

# Hosts file updates
$hostsEntries = @(
    "0.0.0.0 variations.brave.com",
    "0.0.0.0 go-updater.brave.com",
    "0.0.0.0 componentupdater.brave.com",
    "0.0.0.0 crlsets.brave.com",
    "0.0.0.0 laptop-updates.brave.com",
    "0.0.0.0 brave-core-ext.s3.brave.com",
    "0.0.0.0 grant.rewards.brave.com",
    "0.0.0.0 stats.brave.com",
    "0.0.0.0 p3a.brave.com",
    "0.0.0.0 analytics.brave.com",
    "0.0.0.0 rewards.brave.com",
    "0.0.0.0 pcdn.brave.com",
    "0.0.0.0 static1.brave.com",
    "0.0.0.0 updates.bravesoftware.com"
)

$hostsPath = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
if ($isAdmin) {
    $currentHosts = Get-Content -Path $hostsPath -ErrorAction SilentlyContinue
    $added = $false
    foreach ($entry in $hostsEntries) {
        if (-not ($currentHosts -match [regex]::Escape($entry))) {
            Add-Content -Path $hostsPath -Value $entry
            $added = $true
        }
    }
    if ($added) {
        Write-Host "✓ Added Brave telemetry domains to $hostsPath"
    } else {
        Write-Host "✓ Brave telemetry domains already blocked in $hostsPath"
    }
} else {
    Write-Warning "Not running as Administrator; cannot modify $hostsPath."
    Write-Host "Add these lines manually to block Brave telemetry:"
    $hostsEntries | ForEach-Object { Write-Host "  $_" }
}

# Optional registry policies
$applyPoliciesResponse = Read-Host "Apply Brave policy registry keys (requires Administrator)? [Y/n]"
$applyPolicies = $true
if ($applyPoliciesResponse) {
    switch ($applyPoliciesResponse.ToLower()) {
        "n" { $applyPolicies = $false }
        "no" { $applyPolicies = $false }
    }
}

if ($applyPolicies) {
    if (-not $isAdmin) {
        Write-Warning "Administrator privileges are required to write HKLM policies. Re-run PowerShell as Administrator."
    } else {
        $policyBase = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"
        New-Item -Path $policyBase -Force | Out-Null
        New-ItemProperty -Path $policyBase -Name "TorDisabled" -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $policyBase -Name "IPFSEnabled" -PropertyType DWord -Value 0 -Force | Out-Null
        New-ItemProperty -Path $policyBase -Name "BraveRewardsDisabled" -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $policyBase -Name "BraveWalletDisabled" -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $policyBase -Name "BraveVPNDisabled" -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $policyBase -Name "BraveAIChatEnabled" -PropertyType DWord -Value 0 -Force | Out-Null

        $enabledUrls = "BraveShieldsEnabledForUrls"
        $disabledUrls = "BraveShieldsDisabledForUrls"
        New-Item -Path (Join-Path $policyBase $enabledUrls) -Force | Out-Null
        New-Item -Path (Join-Path $policyBase $disabledUrls) -Force | Out-Null

        New-ItemProperty -Path (Join-Path $policyBase $enabledUrls) -Name "1" -PropertyType String -Value "[*.]twitter.com" -Force | Out-Null
        New-ItemProperty -Path (Join-Path $policyBase $enabledUrls) -Name "2" -PropertyType String -Value "https://www.example.com" -Force | Out-Null

        New-ItemProperty -Path (Join-Path $policyBase $disabledUrls) -Name "1" -PropertyType String -Value "https://www.example.com" -Force | Out-Null
        New-ItemProperty -Path (Join-Path $policyBase $disabledUrls) -Name "2" -PropertyType String -Value "[*.]brave.com" -Force | Out-Null

        Write-Host "✓ Applied Brave policy registry keys"
    }
} else {
    Write-Host "Skipped registry policy application."
}

Write-Host "`n=== Setup Complete ==="
Write-Host "1. Use the private launcher: $launcherPath"
if ($prefPath) { Write-Host "2. Preferences updated (backup in $backupDir)" }
Write-Host "3. Policy keys: $([string]::Format('{0}', $(if ($applyPolicies -and $isAdmin) { 'applied' } elseif ($applyPolicies) { 'pending (rerun as Admin)' } else { 'skipped' } )))"
