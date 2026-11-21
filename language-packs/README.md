# Windows 11 25H2 Language and Regional Settings

This repository contains scripts and Intune source folders for installing, configuring, and packaging Windows 11 25H2 language and regional settings.

The supported target languages are German (Switzerland), French (Switzerland), and Italian (Switzerland). English (United States) is retained as a source and display language option.

## Contents

| Path | Purpose |
| --- | --- |
| `Extract-LanguagePacks/` | Extracts selected language packs and Features on Demand from a mounted Windows 11 Language and Optional Features ISO. |
| `Microsoft_WindowsLanguagePacks25h2_1.0.0/` | Installs client language packs, LIP language packs, Features on Demand, and language capabilities. |
| `Microsoft_WindowsLanguagePacksConfig25h2_1.0.0/` | Configures the Windows user language list and copies international settings to new and Welcome screen users. |
| `Microsoft_WindowsRegionalSettingsDECH_1.0.0/` | Configures German (Switzerland) culture and regional settings. |
| `Microsoft_WindowsRegionalSettingsFRCH_1.0.0/` | Configures French (Switzerland) culture and regional settings. |
| `Microsoft_WindowsRegionalSettingsITCH_1.0.0/` | Configures Italian (Switzerland) culture and regional settings. |
| `Microsoft_WindowsLanguageConfigDECH_1.0.0/` | Configures the German (Switzerland) user language list. |
| `Microsoft_WindowsLanguageConfigFRCH_1.0.0/` | Configures the French (Switzerland) user language list. |
| `Microsoft_WindowsLanguageConfigITCH_1.0.0/` | Configures the Italian (Switzerland) user language list. |
| `Create packages.ps1` | Creates `.intunewin` packages with `IntuneWinAppUtil.exe`. |

## Workflow

1. Mount the Windows 11 25H2 Language and Optional Features ISO.
2. Run `Extract-LanguagePacks/Create-LanguagePackFile.ps1` to extract the required CAB files.
3. Place the generated source folders under `C:\Temp\Windows 11 Enterprise 25H2`.
4. Run `Create packages.ps1` to create the Intune `.intunewin` packages.
5. Create the corresponding Intune applications and assign them to the target devices or users.

## Intune Package Configuration

### Language pack installation

- **Name:** Windows Language Packs 25h2 1.0.0
- **Install command:** `%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ".\Install.ps1"`
- **Uninstall command:** `%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ".\Uninstall.ps1"`
- **Timeout:** 60 minutes
- **Detection:** Registry value `Version` under `HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguagePacks25h2_1.0.0`

### Language pack configuration

- **Name:** Windows Language Packs Config 25h2 1.0.0
- **Install command:** `%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ".\Install.ps1"`
- **Uninstall command:** `%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ".\Uninstall.ps1"`
- **Timeout:** 60 minutes
- **Detection:** Registry value `Version` under `HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguagePacksConfig25h2_1.0.0`

### Regional settings

| Package | Target locale | GeoId | Detection |
| --- | --- | --- | --- |
| German (Swiss) | `de-CH` | 223 | `HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsRegionalSettingsDECH_1.0.0` |
| French (Swiss) | `fr-CH` | 223 | `HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsRegionalSettingsFRCH_1.0.0` |
| Italian (Swiss) | `it-CH` | 223 | `HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsRegionalSettingsITCH_1.0.0` |

For each regional settings package:

- **Install command:** `Invoke-AppDeployToolkit.exe -DeploymentType Install -DeployMode Silent`
- **Uninstall command:** `Invoke-AppDeployToolkit.exe -DeploymentType Uninstall -DeployMode Silent`
- **Timeout:** 2 minutes
- **Detection value:** `Version`

### Language configuration

| Package | Target locale | Detection |
| --- | --- | --- |
| German (Swiss) | `de-CH` | `HKEY_CURRENT_USER\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguageConfigDECH_1.0.0` |
| French (Swiss) | `fr-CH` | `HKEY_CURRENT_USER\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguageConfigFRCH_1.0.0` |
| Italian (Swiss) | `it-CH` | `HKEY_CURRENT_USER\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguageConfigITCH_1.0.0` |

For each language configuration package:

- **Install command:** `Invoke-AppDeployToolkit.exe -DeploymentType Install -DeployMode NonInteractive`
- **Uninstall command:** `Invoke-AppDeployToolkit.exe -DeploymentType Uninstall -DeployMode NonInteractive`
- **Timeout:** 7 minutes
- **Detection value:** `Version`

## Restart Behavior

The language pack installation scripts return exit code `1641` after creating their detection registry key. Intune may therefore require or request a device restart. The regional settings and language configuration packages use PSAppDeployToolkit and may also indicate a restart according to the deployment result.

## Prerequisites

- Windows 11 Enterprise or Windows 11 Multi Session 25H2 oder 26H2
- Local administrator privileges for device-level installation
- `IntuneWinAppUtil.exe` for package creation
- PSAppDeployToolkit files and dependencies for the regional settings and language configuration packages
- Sufficient disk space for language pack CAB files
