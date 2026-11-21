#name: Config Language Packs Windows 11 25H2
#description: Config Language Packs Windows 11 Enterprise 25H2 and Windows 11 Multi Session 25H2
#execution mode: Individual with restart
#tags: beckmann.ch
#author: Stefan Beckmann, beckmann.ch

<# Notes:

Use this script on Windows 11 Enterprise 25H2 and Windows 11 Multi Session 25H2 after installing the configured language packs.
The script sets the current user's language list to the configured languages and sets the home location to GeoId 223 (Switzerland).
It copies the user's international settings to the Welcome screen and new user profiles.
The script does not explicitly set the system locale or Windows UI language override.
After configuration, it creates a registry detection key containing the solution version and returns exit code 1641 (restart required).

#>

$ErrorActionPreference = 'Stop'

$AppVendor = 'Microsoft'
$AppName = 'WindowsLanguagePacksConfig25h2'
$AppVersion = '1.0.0'

# Define supported languages
$languages = @(
    @{ sourceLanguage = 'en-US'; targetLanguage = 'en-US' },
    @{ sourceLanguage = 'de-DE'; targetLanguage = 'de-CH' },
    @{ sourceLanguage = 'fr-FR'; targetLanguage = 'fr-CH' },
    @{ sourceLanguage = 'it-IT'; targetLanguage = 'it-CH' }
)

# Define default GeoId and CultureInfo for regional settings
$defaultGeoId = 223

# Define language packs and display languages
$displayLanguages = $languages.targetLanguage | Select-Object -Unique

# Log directory
$InstallLogDir = "$env:SystemRoot\Logs\Install"

# Function to log messages to a file and console
enum LogLevel {
    INFO
    WARNING
    ERROR
}

class Logger {
    [string]$LogFilePath

    Logger([string]$path) {
        $this.LogFilePath = $path

        if (-not (Test-Path $this.LogFilePath)) {
            New-Item -Path $this.LogFilePath -ItemType File -Force | Out-Null
        }
    }

    # Overload 1 -> nur Message (default INFO)
    [void]Log([string]$message) {
        $this.Log($message, [LogLevel]::INFO)
    }

    # Overload 2 -> Message + Level
    [void]Log([string]$message, [LogLevel]$level) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $entry = "$timestamp [$level] $message"

        Add-Content -Path $this.LogFilePath -Value $entry

        switch ($level) {
            ([LogLevel]::ERROR) {
                Write-Error $entry
            }
            ([LogLevel]::WARNING) {
                Write-Warning $entry
            }
            default {
                Write-Host $entry
            }
        }
    }
}

$logPath = "$InstallLogDir\MicrosoftLanguagePacksConfig.log"
$logger = [Logger]::new($logPath)

if (-not (Test-Path -Path $InstallLogDir)) {
    New-Item -ItemType Directory -Path $InstallLogDir -Force
}


##Add installed language to language list##
$oldLanguageList = Get-WinUserLanguageList
$logger.Log("Old Language List: " + ($oldLanguageList | Out-String))

$logger.Log("Creat new Language List")
# Define supported languages
$newLanguageList = $null
foreach ($displayLanguage in $displayLanguages) {
    if ($newLanguageList) {
        $logger.Log("Add additional Language: " + $displayLanguage)
        $newLanguageList.Add("$($displayLanguage)")
    } else {
        $logger.Log("Add first Language: " + $displayLanguage)
        $newLanguageList = New-WinUserLanguageList -Language $displayLanguage
    }
}

$logger.Log("Updated Language List: " + ($newLanguageList | Out-String))
Set-WinUserLanguageList $newLanguageList -Force

# Set the location
$logger.Log("Set Home Location to GeoId: " + $defaultGeoId)
Set-WinHomeLocation -GeoId $defaultGeoId

# Document settings
$logger.Log("Document settings")
$logger.Log("WinUserLanguageList: " + (Get-WinUserLanguageList | Out-String))
$logger.Log("WinHomeLocation: " + (Get-WinHomeLocation | Out-String))
$logger.Log("WinSystemLocale: " + (Get-WinSystemLocale | Out-String))
$logger.Log("WinUILanguageOverride: " + (Get-WinUILanguageOverride | Out-String))

# Copy user international settings to system with WelcomeScreen and NewUser set to True
$logger.Log("Copy User International Settings to System with WelcomeScreen and NewUser set to True")
Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True

# Create the registry key and set the version
$basePath = "HKLM:\SOFTWARE\_PackageDetections\Packages"
$applicationName = $AppVendor + '_' + $AppName + '_' + $AppVersion
$programRegistryPath = Join-Path $basePath $applicationName

New-Item -Path $programRegistryPath -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path $programRegistryPath -Name 'Version' -Value $AppVersion -PropertyType String -Force

exit 1641