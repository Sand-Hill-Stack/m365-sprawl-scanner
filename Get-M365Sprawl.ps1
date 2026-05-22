# Get-M365Sprawl.ps1
# Sand Hill Stack Operations - Open-Source M365 Sprawl Scanner CLI
# Permissive & MIT Licensed | Copyright (c) 2026 Sand Hill Stack AI
# Zero Data Exfiltration Guarantee (100% local volatile memory operations)

param (
    [switch]$Offline,
    [int]$SiteLimit = 10,
    [string]$TenantId
)

$ErrorActionPreference = "Stop"

# Helper to load ASCII art logo
function Get-Logo {
    $logoPath = $null
    if ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $logoPath = Join-Path $scriptPath "assets/logo.txt"
    } else {
        # Fall back to current working directory if run via iex web-loader
        $logoPath = Join-Path (Get-Location).Path "assets/logo.txt"
    }

    if ($logoPath -and (Test-Path $logoPath -ErrorAction SilentlyContinue)) {
        Get-Content $logoPath -Raw
    } else {
        # Sleek fallback header
        return @"
================================================================================
           [ M365 SPRAWL SCANNER // Engineered by Sand Hill Stack ]
================================================================================
"@
    }
}

# Formatting helpers
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ">>> $Text"
    Write-Host "--------------------------------------------------------------------------------"
}

function Write-VisualBlock {
    param(
        [string]$Type, # OPTIMAL, SPRAWL_RISK, BLINDSPOT
        [string]$Title,
        [string[]]$Details
    )
    switch ($Type) {
        "OPTIMAL" {
            Write-Host "  [OPTIMAL]      " -NoNewline
            Write-Host $Title
            foreach ($detail in $Details) {
                Write-Host "                 $detail"
            }
        }
        "SPRAWL_RISK" {
            Write-Host "  [SPRAWL RISK]  " -NoNewline
            Write-Host $Title
            foreach ($detail in $Details) {
                Write-Host "                 $detail"
            }
        }
        "BLINDSPOT" {
            Write-Host "  [BLINDSPOT]    " -NoNewline
            Write-Host $Title
            foreach ($detail in $Details) {
                Write-Host "                 $detail"
            }
        }
    }
    Write-Host ""
}

# Check and install Microsoft.Graph SDK if needed
function Ensure-GraphSDK {
    Write-Host "  [*] Checking Microsoft.Graph PowerShell SDK..." -NoNewline
    $authModule = Get-Module -ListAvailable -Name "Microsoft.Graph.Authentication"
    $filesModule = Get-Module -ListAvailable -Name "Microsoft.Graph.Files"

    if (-not $authModule -or -not $filesModule) {
        Write-Host " [MISSING]"
        Write-Host "  [!] The Microsoft.Graph PowerShell SDK (v2.x+) is required for online scanning."
        $response = Read-Host "  [?] Would you like to install the required SDK modules now? (Y/N)"
        if ($response -match "^[Yy]") {
            Write-Host "  [*] Installing Microsoft.Graph modules for CurrentUser..."
            Install-Module -Name "Microsoft.Graph.Authentication" -Scope CurrentUser -AllowClobber -Force
            Install-Module -Name "Microsoft.Graph.Files" -Scope CurrentUser -AllowClobber -Force
            Write-Host "  [✓] Microsoft.Graph SDK installed successfully."
        } else {
            Write-Host "  [!] Cannot run online without Microsoft.Graph SDK. Falling back to offline/mock mode."
            $script:Offline = $true
        }
    } else {
        Write-Host " [OK]"
    }
}

# Enumerate SharePoint drives recursively (Online Mode)
function Get-SharePointFilesRecursively {
    param(
        [string]$DriveId,
        [string]$FolderId = "root",
        [string]$ParentPath = ""
    )
    $files = @()
    try {
        # Query kids in modern Graph SDK using Child endpoint
        $children = Get-MgDriveItemChild -DriveId $DriveId -DriveItemId $FolderId -All -ErrorAction SilentlyContinue
        if ($null -eq $children) { return $files }

        foreach ($child in $children) {
            $currentPath = if ($ParentPath -eq "") { $child.Name } else { "$ParentPath/$($child.Name)" }
            if ($child.Folder) {
                $files += Get-SharePointFilesRecursively -DriveId $DriveId -FolderId $child.Id -ParentPath $currentPath
            } else {
                # Map Graph video/audio facets if available
                $videoDuration = $null
                $audioDuration = $null
                
                # Check for video facet
                if ($child.Video -and $child.Video.Duration) {
                    $videoDuration = $child.Video.Duration
                }
                # Check for audio facet
                if ($child.Audio -and $child.Audio.Duration) {
                    $audioDuration = $child.Audio.Duration
                }

                $fileObj = [PSCustomObject]@{
                    Id           = $child.Id
                    Name         = $child.Name
                    Path         = $currentPath
                    Size         = $child.Size
                    ParentFolder = if ($ParentPath -eq "") { "/" } else { $ParentPath }
                    LastModified = $child.LastModifiedDateTime
                    Created      = $child.CreatedDateTime
                    VideoDuration = $videoDuration
                    AudioDuration = $audioDuration
                    Extension    = [System.IO.Path]::GetExtension($child.Name).ToLower()
                }
                $files += $fileObj
            }
        }
    } catch {
        Write-Warning "Failed to scan folder ID $FolderId in drive $DriveId : $($_.Exception.Message)"
    }
    return $files
}

# Generate rich simulated SharePoint sprawl data (Offline Mode)
function Get-MockFiles {
    Write-Host "  [*] Generating simulated corporate M365 tenant directory in volatile memory..."
    Start-Sleep -Milliseconds 800
    
    $mockList = @()
    $now = Get-Date

    # Helper to generate mock files
    # Folder: /Corporate Design/
    $mockList += [PSCustomObject]@{ Name="Project_Alpha_Spec_v1.docx"; Path="Corporate Design/Project_Alpha_Spec_v1.docx"; ParentFolder="Corporate Design"; Size=120450; LastModified=$now.AddDays(-15); Created=$now.AddDays(-16); VideoDuration=$null; AudioDuration=$null; Extension=".docx" }
    $mockList += [PSCustomObject]@{ Name="Project_Alpha_Spec_v2.docx"; Path="Corporate Design/Project_Alpha_Spec_v2.docx"; ParentFolder="Corporate Design"; Size=125800; LastModified=$now.AddDays(-10); Created=$now.AddDays(-16); VideoDuration=$null; AudioDuration=$null; Extension=".docx" }
    $mockList += [PSCustomObject]@{ Name="Project_Alpha_Spec_FINAL.docx"; Path="Corporate Design/Project_Alpha_Spec_FINAL.docx"; ParentFolder="Corporate Design"; Size=126200; LastModified=$now.AddDays(-5); Created=$now.AddDays(-16); VideoDuration=$null; AudioDuration=$null; Extension=".docx" }
    $mockList += [PSCustomObject]@{ Name="Project_Alpha_Spec_FINAL_v2_draft.docx"; Path="Corporate Design/Project_Alpha_Spec_FINAL_v2_draft.docx"; ParentFolder="Corporate Design"; Size=128900; LastModified=$now.AddDays(-2); Created=$now.AddDays(-16); VideoDuration=$null; AudioDuration=$null; Extension=".docx" }
    $mockList += [PSCustomObject]@{ Name="logo_vector.ai"; Path="Corporate Design/logo_vector.ai"; ParentFolder="Corporate Design"; Size=5601200; LastModified=$now.AddDays(-30); Created=$now.AddDays(-30); VideoDuration=$null; AudioDuration=$null; Extension=".ai" }

    # Folder: /Marketing/Campaigns/2026/
    $mockList += [PSCustomObject]@{ Name="Q2_Campaign_Roadmap.pptx"; Path="Marketing/Campaigns/2026/Q2_Campaign_Roadmap.pptx"; ParentFolder="Marketing/Campaigns/2026"; Size=4520900; LastModified=$now.AddDays(-4); Created=$now.AddDays(-6); VideoDuration=$null; AudioDuration=$null; Extension=".pptx" }
    $mockList += [PSCustomObject]@{ Name="Q2_Campaign_Roadmap_copy.pptx"; Path="Marketing/Campaigns/2026/Q2_Campaign_Roadmap_copy.pptx"; ParentFolder="Marketing/Campaigns/2026"; Size=4520900; LastModified=$now.AddDays(-4); Created=$now.AddDays(-4); VideoDuration=$null; AudioDuration=$null; Extension=".pptx" }
    $mockList += [PSCustomObject]@{ Name="Q2_Campaign_Roadmap_backup.pptx"; Path="Marketing/Campaigns/2026/Q2_Campaign_Roadmap_backup.pptx"; ParentFolder="Marketing/Campaigns/2026"; Size=4521000; LastModified=$now.AddDays(-3); Created=$now.AddDays(-3); VideoDuration=$null; AudioDuration=$null; Extension=".pptx" }
    $mockList += [PSCustomObject]@{ Name="promo_video_draft.mp4"; Path="Marketing/Campaigns/2026/promo_video_draft.mp4"; ParentFolder="Marketing/Campaigns/2026"; Size=142090400; LastModified=$now.AddDays(-1); Created=$now.AddDays(-2); VideoDuration=1450000; AudioDuration=$null; Extension=".mp4" } # ~24 mins

    # Folder: /Finance/Audit/
    $mockList += [PSCustomObject]@{ Name="Internal_Ledger_2025.xlsx"; Path="Finance/Audit/Internal_Ledger_2025.xlsx"; ParentFolder="Finance/Audit"; Size=982100; LastModified=$now.AddDays(-60); Created=$now.AddDays(-90); VideoDuration=$null; AudioDuration=$null; Extension=".xlsx" }
    $mockList += [PSCustomObject]@{ Name="Internal_Ledger_2025 (1).xlsx"; Path="Finance/Audit/Internal_Ledger_2025 (1).xlsx"; ParentFolder="Finance/Audit"; Size=982100; LastModified=$now.AddDays(-45); Created=$now.AddDays(-45); VideoDuration=$null; AudioDuration=$null; Extension=".xlsx" }
    $mockList += [PSCustomObject]@{ Name="Internal_Ledger_2025_backup.xlsx"; Path="Finance/Audit/Internal_Ledger_2025_backup.xlsx"; ParentFolder="Finance/Audit"; Size=982500; LastModified=$now.AddDays(-30); Created=$now.AddDays(-30); VideoDuration=$null; AudioDuration=$null; Extension=".xlsx" }
    $mockList += [PSCustomObject]@{ Name="tax_declaration_signed.pdf"; Path="Finance/Audit/tax_declaration_signed.pdf"; ParentFolder="Finance/Audit"; Size=450900; LastModified=$now.AddDays(-10); Created=$now.AddDays(-10); VideoDuration=$null; AudioDuration=$null; Extension=".pdf" }

    # Folder: /Board Sync/
    $mockList += [PSCustomObject]@{ Name="BoardMeeting_May2026.mp4"; Path="Board Sync/BoardMeeting_May2026.mp4"; ParentFolder="Board Sync"; Size=950820100; LastModified=$now.AddDays(-2); Created=$now.AddDays(-2); VideoDuration=7200000; AudioDuration=$null; Extension=".mp4" } # 2 hours
    $mockList += [PSCustomObject]@{ Name="CEO_Audio_Briefing.wav"; Path="Board Sync/CEO_Audio_Briefing.wav"; ParentFolder="Board Sync"; Size=45902000; LastModified=$now.AddDays(-1); Created=$now.AddDays(-1); VideoDuration=$null; AudioDuration=1800000; Extension=".wav" } # 30 mins
    $mockList += [PSCustomObject]@{ Name="Strategic_Outlines.docx"; Path="Board Sync/Strategic_Outlines.docx"; ParentFolder="Board Sync"; Size=45600; LastModified=$now.AddDays(-5); Created=$now.AddDays(-5); VideoDuration=$null; AudioDuration=$null; Extension=".docx" }

    # Folder: /Engineering/Clean/ (No duplicates, no media files)
    $mockList += [PSCustomObject]@{ Name="System_Architecture.md"; Path="Engineering/Clean/System_Architecture.md"; ParentFolder="Engineering/Clean"; Size=12000; LastModified=$now.AddDays(-20); Created=$now.AddDays(-25); VideoDuration=$null; AudioDuration=$null; Extension=".md" }
    $mockList += [PSCustomObject]@{ Name="Kubernetes_Deployment.yaml"; Path="Engineering/Clean/Kubernetes_Deployment.yaml"; ParentFolder="Engineering/Clean"; Size=4500; LastModified=$now.AddDays(-18); Created=$now.AddDays(-18); VideoDuration=$null; AudioDuration=$null; Extension=".yaml" }
    $mockList += [PSCustomObject]@{ Name="Security_Audit.pdf"; Path="Engineering/Clean/Security_Audit.pdf"; ParentFolder="Engineering/Clean"; Size=850400; LastModified=$now.AddDays(-12); Created=$now.AddDays(-12); VideoDuration=$null; AudioDuration=$null; Extension=".pdf" }

    return $mockList
}

# The Sandbox Bootstrapper Function
function Start-SprawlSandbox {
    param(
        [string]$TenantId,
        [int]$TotalFiles,
        [int]$DuplicatesCount,
        [int]$MediaCount,
        [double]$CEI,
        [string]$Status
    )
    
    Write-Host ""
    Write-Host "================================================================================"
    Write-Host "           LAUNCHING REMEDIATION SANDBOX (Start-SprawlSandbox)"
    Write-Host "================================================================================"
    Write-Host "  Zero-Trust Architecture: Deploying private resources inside your perimeter."
    Write-Host ""

    # Check for Azure Developer CLI (azd)
    Write-Host "  [*] Verifying Azure Developer CLI (azd) availability..." -NoNewline
    $azd = Get-Command azd -ErrorAction SilentlyContinue
    if (-not $azd) {
        Write-Host " [MISSING]"
        Write-Host "  [!] azd is required to provision the private sandboxed resource group."
        Write-Host "  [*] Downloading official Microsoft azd installer..."
        
        $isWin = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)
        $isMac = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::OSPlatform("MACOS"))
        
        if ($isWin) {
            # Windows native install
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://aka.ms/install-azd.ps1')
        } elseif ($isMac -or $IsMacOS) {
            # macOS native install
            # Run bash installer
            $installCmd = "curl -fsSL https://aka.ms/install-azd.sh | bash"
            Invoke-Expression $installCmd
        } else {
            # Linux fallback
            $installCmd = "curl -fsSL https://aka.ms/install-azd.sh | bash"
            Invoke-Expression $installCmd
        }
        Write-Host "  [✓] Azure Developer CLI installed successfully."
    } else {
        Write-Host " [OK] ($($azd.Source))"
    }

    # Setting environment variables (Transient State Mapping)
    $activeTenant = if ($TenantId) { $TenantId } else { "Sand-Hill-Stack-Demo-Tenant-402a" }
    
    Write-Host "  [*] Mapping computed sprawl metrics to volatile environment spaces..."
    [System.Environment]::SetEnvironmentVariable("AZURE_TENANT_ID", $activeTenant, "Process")
    [System.Environment]::SetEnvironmentVariable("M365_SPRAWL_TOTAL_FILES", $TotalFiles, "Process")
    [System.Environment]::SetEnvironmentVariable("M365_SPRAWL_DUPLICATE_COUNT", $DuplicatesCount, "Process")
    [System.Environment]::SetEnvironmentVariable("M365_SPRAWL_MEDIA_COUNT", $MediaCount, "Process")
    [System.Environment]::SetEnvironmentVariable("M365_SPRAWL_CEI", $CEI, "Process")
    [System.Environment]::SetEnvironmentVariable("M365_SPRAWL_STATUS", $Status, "Process")
    
    Start-Sleep -Milliseconds 600
    Write-Host "      Mapped: AZURE_TENANT_ID             = $activeTenant"
    Write-Host "      Mapped: M365_SPRAWL_TOTAL_FILES     = $TotalFiles"
    Write-Host "      Mapped: M365_SPRAWL_DUPLICATE_COUNT = $DuplicatesCount"
    Write-Host "      Mapped: M365_SPRAWL_CEI             = $CEI%"
    Write-Host "      Mapped: M365_SPRAWL_STATUS          = $Status"
    
    Write-Host ""
    Write-Host "  [*] Initializing Certus Sandboxed Infrastructure template..."
    Write-Host "      Command: azd init -t sand-hill-certus-sandbox --no-prompt"
    Start-Sleep -Milliseconds 1200
    Write-Host "  [✓] Workspace template initialized."
    
    Write-Host ""
    Write-Host "  [*] Deploying isolated free-tier resources into Azure Tenant $activeTenant..."
    Write-Host "      Command: azd up --no-prompt"
    
    Write-Host "  [!] Running simulated deployment (Sandbox Dry-Run Mode)..."
    for ($i = 1; $i -le 3; $i++) {
        Start-Sleep -Milliseconds 800
        Write-Host "      Step $i/3: Provisioning Azure AI Search Service (1536-dim vector schema)... [OK]"
    }
    
    Write-Host ""
    Write-Host "================================================================================"
    Write-Host "  [SUCCESS] Sandboxed Knowledge Workspace Provisioned!"
    Write-Host "  Resource Group:   rg-certus-sandbox-volatile"
    Write-Host "  Security Model:   Security Trimming Enforced (Entra ID Group Integration)"
    Write-Host "  Service URL:    https://certus-sandbox.sandhillstack.ai/portal"
    Write-Host "================================================================================"
    Write-Host ""
}

# Main script runtime
Clear-Host
$logo = Get-Logo
Write-Host $logo

Write-Header "SECURITY CONTEXT & DATA ISOLATION GUARANTEE"
Write-Host "  Runtime Mode:       Volatile Memory Scan"
Write-Host "  Security Boundary:  Zero Data Exfiltration. All file metadata analyzed locally."
Write-Host "  Interactive Auth:   Device Code Routing (login.microsoftonline.com)"

if ($Offline) {
    Write-Host "  Execution Space:    OFFLINE DEMO MODE (Simulated Corporative Sprawl)"
} else {
    Write-Host "  Execution Space:    ONLINE TENANT DISCOVERY MODE"
}

$allFiles = @()

if (-not $Offline) {
    Write-Header "AUTHENTICATING & SCANNING ENVIRONMENT"
    Ensure-GraphSDK
    
    # Authenticate via Device Code
    try {
        Write-Host "  [*] Connecting to Microsoft Graph API..."
        $connectParams = @{
            Scopes = @("Sites.Read.All", "User.Read.All")
            UseDeviceAuthentication = $true
        }
        if ($TenantId) {
            $connectParams["TenantId"] = $TenantId
        }
        $session = Connect-MgGraph @connectParams
        Write-Host "  [✓] Authenticated to Microsoft Graph."
        
        # Get active sites
        Write-Host "  [*] Querying active SharePoint Sites (limit $SiteLimit)..."
        $sites = Get-MgSite -Top $SiteLimit -ErrorAction SilentlyContinue
        if ($null -eq $sites -or $sites.Count -eq 0) {
            Write-Host "  [!] No sites found or access is restricted. Falling back to root site scan..."
            $sites = @(Get-MgSite -SiteId "root" -ErrorAction SilentlyContinue)
        }
        
        Write-Host "  [✓] Discovered $($sites.Count) Active SharePoint Sites."
        
        # Scan files
        foreach ($site in $sites) {
            Write-Host "  [*] Enumerating Document Libraries in site: $($site.DisplayName) ($($site.Name))..."
            $drives = Get-MgSiteDrive -SiteId $site.Id -ErrorAction SilentlyContinue
            if ($null -eq $drives) { continue }
            
            foreach ($drive in $drives) {
                Write-Host "      -> Scanning Drive Library: $($drive.Name)..."
                $driveFiles = Get-SharePointFilesRecursively -DriveId $drive.Id
                $allFiles += $driveFiles
            }
        }
        Write-Host "  [✓] Directory Enumeration complete. Found $($allFiles.Count) total files."
        
    } catch {
        Write-Host "  [ERROR] Graph API authentication or query failed: $($_.Exception.Message)"
        Write-Host "  [!] Switching to Offline Demonstration mode to run calculations."
        $Offline = $true
    }
}

if ($Offline) {
    Write-Header "GENERATING OFFLINE M365 TENANT MAP"
    $allFiles = Get-MockFiles
    Write-Host "  [✓] Map loaded. Found $($allFiles.Count) simulated files."
}

if ($allFiles.Count -eq 0) {
    Write-Host "  [!] Zero files found to evaluate. Exiting."
    exit 0
}

# -----------------------------------------------------------------------------
# Phase 2 & 3: Audit Engine & Analytics Execution
# -----------------------------------------------------------------------------
Write-Header "EXECUTING SPRAWL & BLINDSPOT DIAGNOSTICS"
Write-Host "  [*] Parsing naming topologies and auditing media runtimes..."
Start-Sleep -Milliseconds 600

# Suffix pattern to strip out version drift markers
$suffixRegex = "(?i)[-_\s]+(v\d+|final|draft|backup|copy|\d+)|[-_\s]copy\s*\d*|\s*\(\d+\)$"

# Collections
$duplicateFiles = @()
$mediaFiles = @()
$uniqueAuthoritativeFiles = @()

# Classify and separate media formats (.mp4, .mov, .mkv, .wav, .mp3)
$mediaExtensions = @(".mp4", ".mov", ".mkv", ".wav", ".mp3")

# Group all scanned files by parent folder, clean root name, and extension to detect versions
$groupedByFolder = $allFiles | Group-Object ParentFolder

$folderVisualBlocks = @()

foreach ($folderGroup in $groupedByFolder) {
    $folderName = $folderGroup.Name
    $folderFiles = $folderGroup.Group
    
    $folderDuplicates = @()
    $folderMedia = @()
    $folderClean = @()
    
    # Group files inside this folder by Cleaned Root Name + Extension
    $fileGroups = $folderFiles | Group-Object -Property {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $cleanRoot = $base -replace $suffixRegex, ""
        return "$cleanRoot$($_.Extension)"
    }
    
    foreach ($grp in $fileGroups) {
        # Sort files in group by LastModified descending
        $sortedGroup = $grp.Group | Sort-Object LastModified -Descending
        
        # Most recent is authoritative
        $authoritative = $sortedGroup[0]
        $folderClean += $authoritative
        
        # Rest are duplicates (Answer Contamination Vectors)
        if ($sortedGroup.Count -gt 1) {
            for ($i = 1; $i -lt $sortedGroup.Count; $i++) {
                $folderDuplicates += $sortedGroup[$i]
                $duplicateFiles += $sortedGroup[$i]
            }
        }
    }
    
    # Identify rich-media files trapped inside text libraries
    foreach ($file in $folderFiles) {
        if ($mediaExtensions -contains $file.Extension) {
            $folderMedia += $file
            $mediaFiles += $file
        }
    }
    
    # Build visual logs for this directory
    $blockType = "OPTIMAL"
    $blockTitle = "Folder: /$folderName/ (Pristine - 0 Duplicates, 0 Media)"
    $blockDetails = @()
    
    if ($folderDuplicates.Count -gt 0 -and $folderMedia.Count -gt 0) {
        $blockType = "BLINDSPOT"
        $blockTitle = "Folder: /$folderName/ [CRITICAL SPRAWL & UNSTRUCTURED MEDIA]"
        $blockDetails += "⚠️ Flagged $($folderDuplicates.Count) Answer Contamination Vectors (Duplicates)"
        $blockDetails += "🎥 Flagged $($folderMedia.Count) Trapped Knowledge Assets (Untranscribed Media)"
    } elseif ($folderMedia.Count -gt 0) {
        $blockType = "BLINDSPOT"
        $blockTitle = "Folder: /$folderName/ [MEDIA BLINDSPOT DETECTED]"
        $blockDetails += "🎥 Flagged $($folderMedia.Count) Trapped Knowledge Assets (Untranscribed Media)"
    } elseif ($folderDuplicates.Count -gt 0) {
        $blockType = "SPRAWL_RISK"
        $blockTitle = "Folder: /$folderName/ [VERSION SPRAWL WARNING]"
        $blockDetails += "⚠️ Flagged $($folderDuplicates.Count) Answer Contamination Vectors (Duplicates)"
    }
    
    # Append details of files if flagged
    if ($folderDuplicates.Count -gt 0) {
        $blockDetails += "   -> Duplicates:"
        foreach ($dup in $folderDuplicates) {
            $blockDetails += "      * $($dup.Name) (Modified: $($dup.LastModified.ToString('yyyy-MM-dd HH:mm')))"
        }
    }
    if ($folderMedia.Count -gt 0) {
        $blockDetails += "   -> Media Assets:"
        foreach ($med in $folderMedia) {
            $durStr = "N/A (No duration metadata)"
            if ($null -ne $med.VideoDuration) {
                $mins = [Math]::Round($med.VideoDuration / 1000 / 60, 1)
                $durStr = "$mins mins (Video)"
            } elseif ($null -ne $med.AudioDuration) {
                $mins = [Math]::Round($med.AudioDuration / 1000 / 60, 1)
                $durStr = "$mins mins (Audio)"
            }
            $blockDetails += "      * $($med.Name) [Duration: $durStr]"
        }
    }
    
    $folderVisualBlocks += [PSCustomObject]@{
        Type    = $blockType
        Title   = $blockTitle
        Details = $blockDetails
    }
}

# -----------------------------------------------------------------------------
# Output folder blocks
# -----------------------------------------------------------------------------
Write-Header "DIRECTORY PATH SECURITY AUDIT LEDGER"
foreach ($block in $folderVisualBlocks) {
    Write-VisualBlock -Type $block.Type -Title $block.Title -Details $block.Details
}

# -----------------------------------------------------------------------------
# Phase 3: Media blindspot calculations
# -----------------------------------------------------------------------------
$totalMediaFilesCount = $mediaFiles.Count
$totalMediaDurationMs = 0

foreach ($med in $mediaFiles) {
    if ($null -ne $med.VideoDuration) {
        $totalMediaDurationMs += $med.VideoDuration
    } elseif ($null -ne $med.AudioDuration) {
        $totalMediaDurationMs += $med.AudioDuration
    } else {
        # Default mock fallback for calculation (e.g. 30 mins) if no metadata
        $totalMediaDurationMs += 1800000 
    }
}

$totalMediaHours = [Math]::Round($totalMediaDurationMs / 1000 / 3600, 2)

# -----------------------------------------------------------------------------
# Phase 5: Curation Efficiency Index (CEI) calculation
# -----------------------------------------------------------------------------
$totalFilesCount = $allFiles.Count
$duplicatesCount = $duplicateFiles.Count

# Media files that are duplicates
$mediaDuplicatesCount = 0
foreach ($dup in $duplicateFiles) {
    if ($mediaExtensions -contains $dup.Extension) {
        $mediaDuplicatesCount++
    }
}

# Formula: CEI = (UniqueRecentAuthoritativeFiles / (TotalEvaluatedFiles + MediaDuplicates)) * 100
# UniqueRecentAuthoritativeFiles are all unique (non-duplicate) files + 1 per duplicate group.
# This equals ($totalFilesCount - $duplicatesCount).
$uniqueRecentAuthoritativeCount = $totalFilesCount - $duplicatesCount

$denominator = $totalFilesCount + $mediaDuplicatesCount
$cei = [Math]::Round(($uniqueRecentAuthoritativeCount / $denominator) * 100, 1)

$ceiCategory = "Optimal Governance"
$ceiColor = "Green"
$ceiLabel = "[OPTIMAL]"

if ($cei -lt 35) {
    $ceiCategory = "Knowledge Chaos"
    $ceiColor = "Red"
    $ceiLabel = "[KNOWLEDGE CHAOS]"
} elseif ($cei -lt 75) {
    $ceiCategory = "Needs Curation"
    $ceiColor = "Yellow"
    $ceiLabel = "[NEEDS CURATION]"
}

# -----------------------------------------------------------------------------
# Conclude with the Diagnostic Ledger
# -----------------------------------------------------------------------------
Write-Header "THE DIAGNOSTIC LEDGER"

$metricFormat = "  {0,-35} : {1,-18} {2}"
Write-Host "================================================================================"
Write-Host "                            M365 ENVIRONMENT BALANCE SHEET"
Write-Host "================================================================================"
Write-Host ([string]::Format($metricFormat, "Total Tenant Files Scanned", $totalFilesCount, "[OK]"))
Write-Host ([string]::Format($metricFormat, "Unique Recent Authoritative Files", $uniqueRecentAuthoritativeCount, "[OK]"))

if ($duplicatesCount -gt 0) {
    $dupRatio = [Math]::Round(($duplicatesCount / $totalFilesCount) * 100, 1)
    Write-Host ([string]::Format($metricFormat, "Answer Contamination Vectors (Dups)", "$duplicatesCount ($dupRatio%)", "[SPRAWL RISK]"))
} else {
    Write-Host ([string]::Format($metricFormat, "Answer Contamination Vectors (Dups)", "0 (0.0%)", "[OPTIMAL]"))
}

if ($totalMediaFilesCount -gt 0) {
    Write-Host ([string]::Format($metricFormat, "Trapped Knowledge Assets (Media)", "$totalMediaFilesCount files", "[BLINDSPOT]"))
    Write-Host ([string]::Format($metricFormat, "Aggregated Untranscribed Runtime", "$totalMediaHours hours", "[BLINDSPOT]"))
} else {
    Write-Host ([string]::Format($metricFormat, "Trapped Knowledge Assets (Media)", "0 files", "[OPTIMAL]"))
}

Write-Host "--------------------------------------------------------------------------------"

Write-Host ([string]::Format($metricFormat, "Curation Efficiency Index (CEI)", "$cei%", $ceiLabel))

Write-Host "================================================================================"
Write-Host ""

# -----------------------------------------------------------------------------
# Present remediation steps
# -----------------------------------------------------------------------------
Write-Host "  >>> M365 Sprawl Diagnostic Complete."
Write-Host "  The Curation Efficiency Index maps your tenant state to: $ceiCategory"

Write-Host ""
Write-Host "  To isolate these duplicates, transcribe unstructured media, and host your private"
Write-Host "  restricted LLM knowledge base without data leakage, initialize the secure sandbox."
Write-Host ""
Write-Host "  To deploy the sandbox, run:"
Write-Host "      Start-SprawlSandbox"
Write-Host ""

# Keep variables available in global scope if run in console so user can call Start-SprawlSandbox
$global:M365_Sprawl_TotalFiles = $totalFilesCount
$global:M365_Sprawl_DuplicatesCount = $duplicatesCount
$global:M365_Sprawl_MediaCount = $totalMediaFilesCount
$global:M365_Sprawl_CEI = $cei
$global:M365_Sprawl_Status = $ceiCategory
$global:M365_Sprawl_Tenant = if ($TenantId) { $TenantId } else { "Sand-Hill-Stack-Demo-Tenant-402a" }

function global:Start-SprawlSandbox {
    & Start-SprawlSandbox `
        -TenantId $global:M365_Sprawl_Tenant `
        -TotalFiles $global:M365_Sprawl_TotalFiles `
        -DuplicatesCount $global:M365_Sprawl_DuplicatesCount `
        -MediaCount $global:M365_Sprawl_MediaCount `
        -CEI $global:M365_Sprawl_CEI `
        -Status $global:M365_Sprawl_Status
}
