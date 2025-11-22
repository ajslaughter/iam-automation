# AP Field Operations Console

> **Enterprise Grade Field Automation for Adolfson & Peterson Construction**
>
> *Built for the Systems Analyst Role*

![Platform](https://img.shields.io/badge/Platform-Windows%20PowerShell-blue) ![Focus](https://img.shields.io/badge/Focus-Field%20Operations-green) ![Safety](https://img.shields.io/badge/Compliance-IIF%20Safety-orange)

## 🏗️ Executive Summary
The **Field Operations Console** is a unified automation platform designed to standardize IT support across regional job sites. It addresses the specific challenges of the Systems Analyst role: **Safety Compliance**, **Remote Connectivity**, and **Asset Management**.

## 🌟 Key Features (Console Menu 1-6)

### [1] 🦺 Daily Safety Briefing
**Enforces the IIF (Incident and Injury Free) Culture.**
- **Function:** Locks all admin tools until the user acknowledges specific hazard checks (e.g., trip hazards, ladder safety).
- **Why:** Ensures IT is compliant with safety protocols before technical work begins.

### [2] 📡 Site Connectivity Test
**Rapid "Inside-Out" Network Diagnostics.**
- **Function:** Tests the full path: Local Adapter -> Gateway -> Internet (8.8.8.8) -> Corporate VPN -> Meraki Dashboard.
- **Why:** Instantly isolates if an issue is Local (cable) or Upstream (ISP).

### [3] 🕸️ Packet Capture (Netsh)
**Native Traffic Analysis.**
- **Function:** Uses Windows `netsh trace` to record 60 seconds of packet data to an `.etl` log file.
- **Why:** Allows for deep analysis on field laptops without requiring Wireshark installation.

### [4] 🖨️ Repair Print System
**One-Click Spooler Remediation.**
- **Function:** Forcibly stops the Print Spooler, deletes corrupt `.SPL` files, and restarts the service.
- **Why:** Automates the fix for the most common field office support ticket.

### [5] 💻 Workstation Prep
**SCCM / Imaging Simulation.**
- **Function:** Configures a new laptop based on role ("Field" vs. "Office"). Installs specific software (Bluebeam, Citrix) and sets "High Performance" power plans.
- **Why:** Standardizes endpoint deployment across regional sites.

### [6] 📝 Device Asset Inventory
**Automated Asset Tagging.**
- **Function:** Scans WMI/CIM to generate a "Birth Certificate" CSV with Serial Number, Model, and OS Version.
- **Why:** Maintains accurate hardware inventory data for the region.

## 🚀 Usage

Double-click `src/Start-FieldOpsConsole.ps1` to launch the interactive menu.

```text
 [1] 🦺  DAILY SAFETY BRIEFING (IIF Compliance)
 [2] 📡  Site Connectivity Test (Meraki/VPN)
 [3] 🕸️   Packet Capture (Netsh Trace)
 ...
```
