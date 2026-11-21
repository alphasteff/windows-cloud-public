#name: Install Language Packs Windows 11 25H2
#description: Install Language Packs Windows 11 Enterprise 25H2 and Windows 11 Multi Session 25H2
#execution mode: Individual with restart
#tags: beckmann.ch
#author: Stefan Beckmann, beckmann.ch

<# Notes:

Installs the configured language packs and language capabilities on Windows 11 Enterprise 25H2 and Windows 11 Multi Session 25H2.
Package sources are read from the relative folders ClientLanguagePack, LipLanguagePack (optional), FeatureOnDemand, and Capability.
The script disables scheduled tasks and a policy setting that remove unused preinstalled language packs.
It does not set the Windows display language or regional settings.
After installation, it creates a registry detection key containing the solution version and returns exit code 1641 (restart required).

#>

$ErrorActionPreference = 'Stop'

$AppVendor = 'Microsoft'
$AppName = 'WindowsLanguagePacks25h2'
$AppVersion = '1.0.0'

# Define supported languages
$languages = @(
    @{ sourceLanguage = 'en-US'; targetLanguage = 'en-US' },
    @{ sourceLanguage = 'de-DE'; targetLanguage = 'de-CH' },
    @{ sourceLanguage = 'fr-FR'; targetLanguage = 'fr-CH' },
    @{ sourceLanguage = 'it-IT'; targetLanguage = 'it-CH' }
)

# Define language packs and display languages
$languagePacks = $languages.sourceLanguage | Select-Object -Unique
$displayLanguages = $languages.targetLanguage | Select-Object -Unique
$allLanguages = $languagePacks + $displayLanguages | Select-Object -Unique

# Define directories for language packs and features
$clientLanguagePackDir = ".\ClientLanguagePack"
$lipLanguagePackDir = ".\LipLanguagePack"
$fdoDir = ".\FeatureOnDemand"
$capabilityDir = ".\Capability"

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

$logPath = "$InstallLogDir\MicrosoftLanguagePacks.log"
$logger = [Logger]::new($logPath)

if (-not (Test-Path -Path $InstallLogDir)) {
    New-Item -ItemType Directory -Path $InstallLogDir -Force
}

$fileDir = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logger.Log("Var fileDir: " + ($fileDir | Out-String))

if (Test-Path -Path $clientLanguagePackDir) {
    $logger.Log('Get Language Pack Files')
    $muiFiles = Get-ChildItem -Path $clientLanguagePackDir -Filter *.cab -ErrorAction SilentlyContinue -Force | Where-Object {
        $found = $FALSE
        foreach ($language in $languagePacks) {
            if ($_.Name.ToLower().Contains($language.ToLower())) {
                $found = $TRUE
                break
            }
        }
        $found
    }
    $logger.Log("Var muiFiles: " + ($muiFiles | Out-String))
} else {
    $logger.Log("No Language Pack files found.", [LogLevel]::ERROR)
}

if (Test-Path -Path $lipLanguagePackDir) {
    $logger.Log("Get Lip Language Pack Files")
    $lipFiles = Get-ChildItem -Path $lipLanguagePackDir -Filter *.cab -ErrorAction SilentlyContinue -Force | Where-Object {
        $found = $FALSE
        foreach ($language in $languagePacks) {
            if ($_.Name.ToLower().Contains($language.ToLower())) {
                $found = $TRUE
                break
            }
        }
        $found
    }
    $logger.Log("Var lipFiles: " + ($lipFiles | Out-String))
}

$capFiles = Get-ChildItem -Path $capabilityDir -Filter *.cab -ErrorAction SilentlyContinue -Force | Where-Object {
    $found = $FALSE
    foreach ($language in $languagePacks) {
        if ($_.Name.ToLower().Contains($language.ToLower()) -or $_.Name.ToLower().Contains($language.Split('-')[0] + '-ch')) {
            $found = $TRUE
            break
        }
    }
    $found
}

if (Test-Path -Path $capabilityDir) {
    $logger.Log("Var capFiles: " + ($capFiles | Out-String))
    $capabilityDir = Get-Item -Path $capabilityDir
    $logger.Log("capFiles Full Path: " + ($capabilityDir | Out-String))
}

$fodFiles = Get-ChildItem -Path $fdoDir -Filter *.cab -ErrorAction SilentlyContinue -Force | Where-Object {
    $found = $FALSE
    foreach ($language in $languagePacks) {
        if ($_.Name.ToLower().Contains($language.ToLower()) -or $_.Name.ToLower().Contains($language.Split('-')[0] + '-ch')) {
            $found = $TRUE
            break
        }
    }
    $found
}

if (Test-Path -Path $fdoDir) {
    $logger.Log("Var fodFiles: " + ($fodFiles | Out-String))
}

##Disable Language Pack Cleanup##
$logger.Log('Disable Language Pack Cleanup')
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\MUI\" -TaskName "LPRemove"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller" -TaskName "Uninstallation"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Control Panel\International" /v "BlockCleanupOfUnusedPreinstalledLangPacks" /t REG_DWORD /d 1 /f


foreach ($muiFile in $muiFiles) {
    $logger.Log("Install MuiFile: " + $muiFile.FullName)
    $ErrorActionPreference = 'SilentlyContinue'
    $null = Add-WindowsPackage -Online -PackagePath $muiFile.FullName -LogPath ($InstallLogDir + '\' + $muiFile.BaseName + '.log') -NoRestart -IgnoreCheck -ErrorAction SilentlyContinue -Verbose:$false | Out-Null
    $ErrorActionPreference = 'Continue'
}

foreach ($LIPFile in $LIPFiles) {
    $logger.Log("Install LipFile: " + $LIPFile.FullName)
    $ErrorActionPreference = 'SilentlyContinue'
    $null = Add-WindowsPackage -Online -PackagePath $LIPFile.FullName -LogPath ($InstallLogDir + '\' + $LIPFile.BaseName + '.log') -NoRestart -IgnoreCheck -ErrorAction SilentlyContinue -Verbose:$false | Out-Null
    $ErrorActionPreference = 'Continue'
}

foreach ($language in $allLanguages) {
    # Define additional Capability files
    $additionalCapabilityList = @(
        "Language.Basic~~~$language~0.0.1.0",
        "Language.Handwriting~~~$language~0.0.1.0",
        "Language.OCR~~~$language~0.0.1.0",
        "Language.Speech~~~$language~0.0.1.0",
        "Language.TextToSpeech~~~$language~0.0.1.0"
    )

    foreach ($capFile in $additionalCapabilityList) {
        #$capFile = $ExecutionContext.InvokeCommand.ExpandString($additionalCapability)
        $logger.Log("Install CapFile: " + $capFile)
        $ErrorActionPreference = 'SilentlyContinue'
        $null = Add-WindowsCapability -Online -Name $capFile -Source $capabilityDir -LimitAccess -LogPath ($InstallLogDir + '\' + $capFile + '.log') -ErrorAction SilentlyContinue -Verbose:$false | Out-Null
        $ErrorActionPreference = 'Continue'
    }
}

foreach ($FODFile in $FODFiles) {
    $logger.Log("Install FodFile: " + $FODFile.FullName)
    $ErrorActionPreference = 'SilentlyContinue'
    $null = Add-WindowsPackage -Online -PackagePath $FODFile.FullName -LogPath ($InstallLogDir + '\' + $FODFile.BaseName + '.log') -NoRestart -IgnoreCheck -ErrorAction SilentlyContinue -Verbose:$false | Out-Null
    $ErrorActionPreference = 'Continue'
}

# Create the registry key and set the version
$basePath = "HKLM:\SOFTWARE\_PackageDetections\Packages"
$applicationName = $AppVendor + '_' + $AppName + '_' + $AppVersion
$programRegistryPath = Join-Path $basePath $applicationName

New-Item -Path $programRegistryPath -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path $programRegistryPath -Name 'Version' -Value $AppVersion -PropertyType String -Force

$logger.Log("Script beendet")
exit 1641