# M365 Sprawl Scanner (`m365-sprawl-scanner`)

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

## 2. Zero-Trust Security & Data Isolation Architecture

Because this utility is targeted at enterprise administrators who handle sensitive data corporate-wide, adherence to strict security boundaries is architecturally enforced:

> [!IMPORTANT]
> **THE VOLATILE-ONLY SECURITY GUARANTEE**
> * **Absolute Zero Exfiltration:** All metadata processing, file loops, and path evaluation algorithms occur *entirely* within the local terminal's volatile memory space (RAM). 
> * **No Cloud Backchannels:** No file names, path routes, tenant IDs, email addresses, or analytical summaries are transmitted to external servers, APIs, or third parties.
> * **Zero Local Footprint:** The tool runs as a completely transient, on-demand memory task. It does not modify local system paths, install hidden system daemons, write temporary cache files, or leave behind metadata databases.

### Key Security & Trust Pillars:

* **Official Identity Gateway Integration:** All authentication is routed directly through Microsoft's secure native Entra ID (formerly Azure AD) endpoints (`login.microsoftonline.com`) using standard secure OAuth interactive flows. Your credentials are never handled or seen by the script.
* **Minimum Privilege Delegation:** The script explicitly requests read-only directory scopes (`Sites.Read.All` and `User.Read.All`). It cannot modify or delete files, delete directories, or access user emails/calendars.
* **Fully Auditable Source Code:** The script is completely open-source, written in standard cross-platform PowerShell Core (`pwsh`). It is entirely un-obfuscated and self-contained, allowing corporate cybersecurity teams to inspect every line prior to execution.
* **Encrypted API Channels:** All communications between your local terminal and Microsoft 365 are conducted over standard TLS 1.2/1.3 encrypted HTTPS channels managed natively by the Microsoft.Graph SDK.


---

## 3. Prerequisites & Dependency Setup

The scanner runs cross-platform on **Windows**, **macOS**, and **Linux** via **PowerShell Core (`pwsh`)**.

### Step 1: Install PowerShell Core (`pwsh`)
If you do not have PowerShell Core installed, set it up using the command below matching your OS:

* **macOS (via Homebrew):**
  ```bash
  brew install powershell
  ```
  *(Alternatively, download the official `.pkg` installer from the [PowerShell Releases page](https://github.com/PowerShell/PowerShell/releases)).*

* **Windows (via winget):**
  ```powershell
  winget install --id Microsoft.Powershell --source winget
  ```

* **Linux (Ubuntu/Debian):**
  ```bash
  sudo apt-get update
  sudo apt-get install -y powershell
  ```

### Step 2: Install Microsoft Graph SDK (Optional / Self-Healing)
The scanner depends on the official `Microsoft.Graph` PowerShell SDK modules. 
> [!TIP]
> **No manual setup required:** The script will automatically check for these dependencies upon execution. If they are missing, it will securely prompt you and offer to install them to your local user scope (`-Scope CurrentUser`) dynamically!

If you prefer to pre-install them manually, run this inside your `pwsh` shell:
```powershell
Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -AllowClobber -Force
Install-Module -Name Microsoft.Graph.Files -Scope CurrentUser -AllowClobber -Force
Install-Module -Name Microsoft.Graph.Sites -Scope CurrentUser -AllowClobber -Force
```

---

## 4. Run the Scanner

Once PowerShell (`pwsh`) is running, you can execute the tool using a single-line command or a manual download.

> [!TIP]
> **RECOMMENDED FOR DEMOS (PREVENT TIMEOUTS):**
> Standard Microsoft Graph authentication prompts can time out if you are distracted. To guarantee a smooth, stress-free demo, **pre-authenticate your session beforehand**. The scanner will dynamically detect the active authenticated session and execute immediately without prompting!
>
> Run this first inside your `pwsh` shell to pre-authenticate:
> ```powershell
> Connect-MgGraph -Scopes "Sites.Read.All", "User.Read.All", "Files.Read.All"
> ```

### Option A: Direct Web-Load execution (Zero Download)
Start the shell by typing `pwsh` in your terminal, pre-authenticate (as recommended above), and paste the following to execute directly in volatile memory:

```powershell
iex (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Sand-Hill-Stack/m365-sprawl-scanner/main/Get-M365Sprawl.ps1')
```

### Option B: Local Repository execution
1. Clone the public repository:
   ```bash
   git clone https://github.com/Sand-Hill-Stack/m365-sprawl-scanner.git
   cd m365-sprawl-scanner
   ```
2. Enter the PowerShell Core terminal:
   ```bash
   pwsh
   ```
3. Pre-authenticate your session (recommended):
   ```powershell
   Connect-MgGraph -Scopes "Sites.Read.All", "User.Read.All", "Files.Read.All"
   ```
4. Run the scanner:
   ```powershell
   ./Get-M365Sprawl.ps1
   ```


---

## 5. Technical Specs & Permissions

* **Environment:** PowerShell Core (`pwsh` v7.x or later recommended).
* **Dependencies:** `Microsoft.Graph` PowerShell SDK (automatically checked and optionally installed for CurrentUser).
* **Authentication Flow:** Secure interactive OAuth browser loopback flow routed strictly through Microsoft's official identity endpoint (`login.microsoftonline.com`).
* **Required Minimum Permissions:** 
  * `Sites.Read.All` - Required to enumerate SharePoint communication/team sites and document libraries.
  * `User.Read.All` - Required to map current admin user metadata.
  * `Files.Read.All` - Required to read metadata and traverse documents inside personal OneDrive drive collections.

---

## 6. Diagnostic & Calculation Pipeline

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

## 7. The Diagnostic Ledger (Console UI)

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

## 8. Remediation via `Start-SprawlSandbox`

If your CEI score indicates version chaos, the CLI publishes a quick remediation bootstrap routine:

```powershell
Start-SprawlSandbox
```

### Automation Architecture:
1. **Checks for the Azure Developer CLI (`azd`)**: If missing, it invisibly downloads and installs the official Microsoft installer cross-platform.
2. **Maps Transient Variables**: Mapped parameters (`AZURE_TENANT_ID`, `M365_SPRAWL_CEI`, `M365_SPRAWL_TOTAL_FILES`) are securely mapped to local volatile environment spaces.
3. **Provisions Private Infrastructure**: Executes `azd up` targeting the isolated **Sand Hill Certus** free-tier template. This spins up a secure Azure AI Search service and Phi-4 ingestion perimeter inside your *own* private subscription boundaries.

---

## 9. License & Governance

Licensed under the permissive **MIT License**. Created and maintained by **Sand Hill Stack Operations**.

For corporate audits or contribution inquiries, visit [sandhillstack.ai](https://www.sandhillstack.ai/).
