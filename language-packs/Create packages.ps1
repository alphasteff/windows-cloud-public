#name: Create Windows Language and Regional Settings Intune Packages
#description: Create .intunewin packages for Windows 11 25H2 language, regional, and language configuration applications
#execution mode: Manual
#tags: beckmann.ch
#author: Stefan Beckmann, beckmann.ch

<# Notes:

Run this helper on a machine with IntuneWinAppUtil.exe and the application source folders under C:\Temp.
It packages the Windows Language Packs and Windows Language Packs Config applications with Install.ps1, and the regional settings and per-language configuration applications with Invoke-AppDeployToolkit.exe.
Only packages whose source folders exist are processed; existing .intunewin output files for those packages are removed before new packages are created.
Package install commands, detection registry paths, timeouts, and detection values are documented below.

#>

$packagePath = 'C:\Temp'

Set-Location -Path $packagePath

$applications = @(
    "Microsoft_WindowsLanguagePacks25h2_1.0.0"
    "Microsoft_WindowsLanguagePacksConfig25h2_1.0.0"
)

foreach ($app in $applications) {
    if (Test-Path "$packagePath\$app" -ErrorAction SilentlyContinue) {
        if (Test-Path "$packagePath\$app.intunewin" -ErrorAction SilentlyContinue) { Remove-Item "$packagePath\$app.intunewin" -Force }
        . "$packagePath\IntuneWinAppUtil.exe" -c "$packagePath\$app" -s Install.ps1 -o $packagePath -q
        Rename-Item Install.intunewin "$packagePath\$app.intunewin"
    }
}

$applications = @(
    "Microsoft_WindowsRegionalSettingsDECH_1.0.0"
    "Microsoft_WindowsRegionalSettingsFRCH_1.0.0"
    "Microsoft_WindowsRegionalSettingsITCH_1.0.0"
    "Microsoft_WindowsLanguageConfigDECH_1.0.0"
    "Microsoft_WindowsLanguageConfigFRCH_1.0.0"
    "Microsoft_WindowsLanguageConfigITCH_1.0.0"
)

foreach ($app in $applications) {
    if (Test-Path "$packagePath\$app" -ErrorAction SilentlyContinue) {
        if (Test-Path "$packagePath\$app.intunewin" -ErrorAction SilentlyContinue) { Remove-Item "$packagePath\$app.intunewin" -Force }
        . "$packagePath\IntuneWinAppUtil.exe" -c "$packagePath\$app" -s 'Invoke-AppDeployToolkit.exe' -o $packagePath -q
        Rename-Item 'Invoke-AppDeployToolkit.intunewin' "$packagePath\$app.intunewin"
    }
}

##### Language Packs
# Name: Windows Language Packs 25h2 1.0.0
# Description: Install Windows 11 25h2 Language Packs (DE, FR, IT)
# Detection: HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguagePacks25h2_1.0.0
# Intune will force a mandatory device restart

# %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ".\Install.ps1" ; exit $LASTEXITCODE
# %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ".\Uninstall.ps1" ; exit $LASTEXITCODE
# 60 Min
# Detection Value: Version

# Name: Windows Language Packs Config 25h2 1.0.0
# Description: Configure Windows 11 25h2 Language Packs (DE, FR, IT)
# Detection: HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguagePacksConfig25h2_1.0.0
# App install may force a device restart

# %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ".\Install.ps1" ; exit $LASTEXITCODE
# %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ".\Uninstall.ps1" ; exit $LASTEXITCODE
# 60 Min
# Detection Value: Version




##### Regional Settings
# Name: Windows Regional Settings German(Swiss) 1.0.0
# Description: Configure Windows Regional Settings for User to: German (Swiss)
# Detection: HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsRegionalSettingsDECH_1.0.0

# Name: Windows Regional Settings French(Swiss) 1.0.0
# Description: Configure Windows Regional Settings for User to: French (Swiss)
# Detection: HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsRegionalSettingsFRCH_1.0.0

# Name: Windows Regional Settings Italian(Swiss) 1.0.0
# Description: Configure Windows Regional Settings for User to: Italian (Swiss)
# Detection: HKEY_LOCAL_MACHINE\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsRegionalSettingsITCH_1.0.0

# Invoke-AppDeployToolkit.exe -DeploymentType Install -DeployMode Silent
# Invoke-AppDeployToolkit.exe -DeploymentType Uninstall -DeployMode Silent
# 2 Min
# Detection Value: Version



##### Language Config
# Name: Windows Language Config German(Swiss) 1.0.0
# Description: Configure Windows Language for User to: German (Swiss)
# Detection:  HKEY_CURRENT_USER\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguageConfigDECH_1.0.0

# Name: Windows Language Config French(Swiss) 1.0.0
# Description: Configure Windows Language for User to: French (Swiss)
# Detection:  HKEY_CURRENT_USER\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguageConfigFRCH_1.0.0

# Name: Windows Language Config Italian(Swiss) 1.0.0
# Description: Configure Windows Language for User to: Italian (Swiss)
# Detection:  HKEY_CURRENT_USER\SOFTWARE\_PackageDetections\Packages\Microsoft_WindowsLanguageConfigITCH_1.0.0

# Invoke-AppDeployToolkit.exe -DeploymentType Install -DeployMode NonInteractive
# Invoke-AppDeployToolkit.exe -DeploymentType Uninstall -DeployMode NonInteractive
# 7 Min
# Detection Value: Version