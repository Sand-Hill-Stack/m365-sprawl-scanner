# M365 Sprawl Scanner (`m365-sprawl-scanner`)

```text
  ███████╗ █████╗ ███╗   ██╗██████╗     ██╗  ██╗██╗██╗     ██╗          ██████╗████████╗ █████╗  ██████╗██╗  ██╗
  ██╔════╝██╔══██╗████╗  ██║██╔══██╗    ██║  ██║██║██║     ██║         ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║  ██║
  ███████╗███████║██╔██╗ ██║██║  ██║    ███████║██║██║     ██║         ╚█████╗     ██║   ███████║██║     ███████║
  ╚════██║██╔══██║██║╚██╗██║██║  ██║    ██╔══██║██║██║     ██║          ╚═══██╗    ██║   ██╔══██║██║     ██╔══██║
  ███████║██║  ██║██║ ╚████║██████╔╝    ██║  ██║██║███████╗███████╗    ██████╔╝    ██║   ██║  ██║╚██████╗██║  ██║
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝    ╚═════╝     ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
  
                                  ---  S A N D   H I L L   S T A C K  ---
```

Utility-first, zero-data-leak command-line scanner designed for enterprise IT administrators to map document version chaos, calculate un-transcribed audio/video search blindspots, and deploy isolated, private in-tenant knowledge workspaces.

---

## 1. Executive Summary & Objective

In modern enterprises, generic out-of-the-box Large Language Models (LLMs) and standard Copilots often fail or hallucinate due to the sheer noise in unstructured SharePoint repositories. Document libraries are frequently contaminated with multiple stale version drift instances (e.g. `_v1`, `_v2`, `_FINAL`, `_FINAL_v2_draft.docx`) and rich media assets (videos, meeting records) that standard textual indexes are entirely blind to.

The **`m365-sprawl-scanner`** is a native PowerShell utility that:
1. **Enumerates M365 directories** via official Microsoft APIs.
2. **Detects redundant file clusters** (Answer Contamination Vectors).
3. **Calculates media blindspots** (Trapped Knowledge Assets).
4. **Computes a hard data governance index**: the **Curation Efficiency Index (CEI)**.

This utility serves as the catalyst for demonstrating SharePoint version chaos, paving a secure onboarding route to transition cluttered data structures into **Sand Hill Certus** private, security-trimmed, vector-embedded knowledge perimeters.

---

## 2. Absolute Zero-Exfiltration Security Guarantee

Because this script is designed for enterprise global administrators handling highly sensitive in-tenant metadata:

* **100% Volatile Local Execution:** All parsing, path matching, string cleaning, runtime calculations, and analytical reports are processed entirely within the volatile memory space of your local machine.
* **No Telemetry / No Tracking:** Under no circumstances are file names, path listings, user details, or tenant identifiers transmitted to external servers. Your tenant data remains strictly inside your session boundaries.
* **Inspectable & Auditable:** Written in highly readable, non-obfuscated cross-platform PowerShell Core (`pwsh`). Enterprise security teams can review every single line of code prior to execution.

---

## 3. Installation & Quick Start

The scanner runs cross-platform on **Windows**, **macOS**, and **Linux** via **PowerShell Core**.

### Dynamic One-Liner Execution:
Execute the scanner instantly in your terminal session:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "iex (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Sand-Hill-Stack/m365-sprawl-scanner/main/Get-M365Sprawl.ps1')"
```

### Manual Installation:
1. Clone the public repository:
   ```bash
   git clone https://github.com/Sand-Hill-Stack/m365-sprawl-scanner.git
   cd m365-sprawl-scanner
   ```
2. Run the scanner:
   * **Demo / Offline Mode (Simulated data, no login required):**
     ```powershell
     ./Get-M365Sprawl.ps1 -Offline
     ```
   * **Interactive M365 Scan (Authenticates securely to your tenant):**
     ```powershell
     ./Get-M365Sprawl.ps1
     ```

---

## 4. Technical Specs & Permissions

* **Environment:** PowerShell Core (`pwsh` v7.x or later recommended).
* **Dependencies:** `Microsoft.Graph` PowerShell SDK (automatically checked and optionally installed for CurrentUser).
* **Authentication Flow:** Interactive OAuth Device Code flow routed strictly through Microsoft's official identity endpoint (`login.microsoftonline.com`).
* **Required Minimum Permissions:** 
  * `Sites.Read.All` - Required to enumerate SharePoint communication/team sites and document libraries.
  * `User.Read.All` - Required to map current admin user metadata.

---

## 5. Diagnostic & Calculation Pipeline

### Phase 1: Directory Enumeration
Connects to M365 using secure Graph tokens, lists active SharePoint libraries, and crawls folders recursively. It maps metadata (names, sizes, modification dates) while isolating media containers: `.mp4`, `.mov`, `.mkv`, `.wav`, and `.mp3`.

### Phase 2: Version Sprawl Detection
Strips common versioning/status suffix patterns using an advanced regular expression:
```regex
(?i)[-_\s]+(v\d+|final|draft|backup|copy|\d+)|[-_\s]copy\s*\d*|\s*\(\d+\)$
```
Files with matching roots and extensions within the same directory are flagged as **Answer Contamination Vectors (Duplicates)**, identifying duplicates that confuse generic LLM retrievers.

### Phase 3: Media Blindspots
Identifies untranscribed rich-media files trapped in text libraries. It reads the Graph API's native `video` and `audio` duration facets to calculate the aggregated runtimes in hours, mapping these as **Trapped Knowledge Assets** (invisible to standard keyword search engines).

### Phase 5: Curation Efficiency Index (CEI)
Runs a validation math equation to output the health score:

$$Curation\ Efficiency\ Index = \left( \frac{\text{Unique, Recent Authoritative Files}}{\text{Total Scanned Files + Media Duplicates}} \right) \times 100$$

* **Green `[OPTIMAL]`**: $\ge 75\%$
* **Yellow `[NEEDS CURATION]`**: $35\% - 75\%$
* **Red `[KNOWLEDGE CHAOS]`**: $<35\%$ (Automatically triggers high-severity alerts).

---

## 6. The Diagnostic Ledger (Console UI)

The script renders high-fidelity colored blocks for audited folders:
* `[OPTIMAL]` (Green): Pristine folders with clean files.
* `[SPRAWL RISK]` (Yellow): Directories hosting multiple file duplicate variants.
* `[BLINDSPOT]` (Red): Folders harboring un-transcribed media files.

Concludes with the **Diagnostic Ledger** summary balance sheet:

```text
================================================================================
                            M365 ENVIRONMENT BALANCE SHEET
================================================================================
  Total Tenant Files Scanned          : 18                 [OK]
  Unique Recent Authoritative Files   : 11                 [OK]
  Answer Contamination Vectors (Dups) : 7 (38.9%)          [SPRAWL RISK]
  Trapped Knowledge Assets (Media)    : 3 files            [BLINDSPOT]
  Aggregated Untranscribed Runtime    : 3.21 hours         [BLINDSPOT]
--------------------------------------------------------------------------------
  Curation Efficiency Index (CEI)     : 61.1%              [NEEDS CURATION]
================================================================================
```

---

## 7. Remediation via `Start-SprawlSandbox`

If your CEI score indicates version chaos, the CLI publishes a quick remediation bootstrap routine:

```powershell
Start-SprawlSandbox
```

### Automation Architecture:
1. **Checks for the Azure Developer CLI (`azd`)**: If missing, it invisibly downloads and installs the official Microsoft installer cross-platform.
2. **Maps Transient Variables**: Mapped parameters (`AZURE_TENANT_ID`, `M365_SPRAWL_CEI`, `M365_SPRAWL_TOTAL_FILES`) are securely mapped to local volatile environment spaces.
3. **Provisions Private Infrastructure**: Executes `azd up` targeting the isolated **Sand Hill Certus** free-tier template. This spins up a secure Azure AI Search service and Phi-4 ingestion perimeter inside your *own* private subscription boundaries.

---

## 8. License & Governance

Licensed under the permissive **MIT License**. Created and maintained by **Sand Hill Stack Operations**.

For corporate audits or contribution inquiries, visit [sandhillstack.ai](https://www.sandhillstack.ai/).
