# AP Field Operations Console

> **Enterprise Grade Field Automation for Adolfson & Peterson Construction**
>
> *Built for the Systems Analyst Role*

![Platform](https://img.shields.io/badge/Platform-Windows%20PowerShell-blue) ![Focus](https://img.shields.io/badge/Focus-Field%20Operations-green) ![Safety](https://img.shields.io/badge/Compliance-IIF%20Safety-orange)

## 🏗️ Executive Summary
The **Field Operations Console** is a unified automation platform designed to standardize IT support across regional job sites. It addresses the specific challenges of the Systems Analyst role: **Safety Compliance**, **Remote Connectivity**, and **Asset Management**.

## 🌟 Key Features

### 1. 🔒 Safety-First Architecture (IIF Culture)
The console enforces the **Incident and Injury Free (IIF)** culture programmatically.
- **Feature:** The "Technical Menu" (Network, Printing, Admin) is **locked** by default.
- **Mechanism:** The engineer *must* complete the **Daily Safety Briefing** and acknowledge hazard checks before tools are enabled.
- **Result:** Safety is not an afterthought; it is a prerequisite for IT operations.

### 2. 📡 Rapid Site Diagnostics
- **One-Click Connectivity:** Tests Local Adapter -> Gateway -> Internet -> VPN -> Meraki Cloud in 5 seconds.
- **Packet Capture:** Native Windows packet capture (ETL) for deep analysis without requiring 3rd party software installs in the field.

### 3. 🛠️ Client & Peripheral Support
- **Print Spooler Repair:** Automated remediation for the most common field office ticket (stuck print jobs).
- **Workstation Prep:** Standardized "Field" vs "Office" software deployment profiles (Bluebeam, Citrix, Office 365).
- **Asset Tagging:** Generates "Birth Certificate" CSVs for hardware inventory tracking.

## 🚀 Usage

Double-click `src/Start-FieldOpsConsole.ps1` to launch the interactive menu.

```text
 [1] 🦺  DAILY SAFETY BRIEFING (IIF Compliance)
 [2] 📡  Site Connectivity Test (Meraki/VPN)
 [3] 🕸️   Packet Capture (Netsh Trace)
 ...
```
