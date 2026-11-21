<#

.SYNOPSIS
PSAppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION
- The script is provided as a template to perform an install, uninstall, or repair of an application(s).
- The script either performs an "Install", "Uninstall", or "Repair" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script imports the PSAppDeployToolkit module which contains the logic and functions required to install or uninstall an application.

.PARAMETER DeploymentType
The type of deployment to perform.

.PARAMETER DeployMode
Specifies whether the installation should be run in Interactive (shows dialogs), Silent (no dialogs), NonInteractive (dialogs without prompts) mode, or Auto (shows dialogs if a user is logged on, device is not in the OOBE, and there's no running apps to close).

Silent mode is automatically set if it is detected that the process is not user interactive, no users are logged on, the device is in Autopilot mode, or there's specified processes to close that are currently running.

.PARAMETER SuppressRebootPassThru
Suppresses the 3010 return code (requires restart) from being passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode
Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging
Disables logging to file for the script.

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeployMode Silent

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall

.EXAMPLE
Invoke-AppDeployToolkit.exe -DeploymentType Install -DeployMode Silent

.INPUTS
None. You cannot pipe objects to this script.

.OUTPUTS
None. This script does not generate any output.

.NOTES
Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Invoke-AppDeployToolkit.ps1, and Invoke-AppDeployToolkit.exe
- 69000 - 69999: Recommended for user customized exit codes in Invoke-AppDeployToolkit.ps1
- 70000 - 79999: Recommended for user customized exit codes in PSAppDeployToolkit.Extensions module.

.LINK
https://psappdeploytoolkit.com

#>

[CmdletBinding()]
param
(
    # Default is 'Install'.
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [System.String]$DeploymentType,

    # Default is 'Auto'. Don't hard-code this unless required.
    [Parameter(Mandatory = $false)]
    [ValidateSet('Auto', 'Interactive', 'NonInteractive', 'Silent')]
    [System.String]$DeployMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$SuppressRebootPassThru,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$TerminalServerMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$DisableLogging
)


##================================================
## MARK: Variables
##================================================

# Zero-Config MSI support is provided when "AppName" is null or empty.
# By setting the "AppName" property, Zero-Config MSI will be disabled.
$adtSession = @{
    # App variables.
    AppVendor                   = 'Microsoft'
    AppName                     = 'WindowsRegionalSettingsFRCH'
    AppVersion                  = '1.0.0'
    AppArch                     = 'x64'
    AppLang                     = 'EN'
    AppRevision                 = '01'
    AppSuccessExitCodes         = @(0)
    AppRebootExitCodes          = @(1641, 3010)
    AppProcessesToClose         = @()  # Example: @('excel', @{ Name = 'winword'; Description = 'Microsoft Word' })
    AppScriptVersion            = '1.0.0'
    AppScriptDate               = '2026-11-17'
    AppScriptAuthor             = 'Stefan Beckmann, beckmann.ch'
    RequireAdmin                = $true

    # Install Titles (Only set here to override defaults set by the toolkit).
    InstallName                 = ''
    InstallTitle                = ''

    # Script variables.
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptParameters   = $PSBoundParameters
    DeployAppScriptVersion      = '4.1.8'
}

function Install-ADTDeployment {
    [CmdletBinding()]
    param
    (
    )

    ##================================================
    ## MARK: Pre-Install
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close processes if specified, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt.
    $saiwParams = @{
        AllowDefer     = $true
        DeferTimes     = 3
        CheckDiskSpace = $true
        PersistPrompt  = $true
    }
    if ($adtSession.AppProcessesToClose.Count -gt 0) {
        $saiwParams.Add('CloseProcesses', $adtSession.AppProcessesToClose)
    }
    Show-ADTInstallationWelcome @saiwParams

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress

    ##================================================
    ## MARK: Install
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI installations.
    if ($adtSession.UseDefaultMsi) {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile) {
            $ExecuteDefaultMSISplat.Add('Transforms', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
        if ($adtSession.DefaultMspFiles) {
            $adtSession.DefaultMspFiles | Start-ADTMsiProcess -Action Patch
        }
    }

    Write-ADTLogEntry -Message ("Script started") -Source 'Installation'

    # Get current System Locale
    $currentSystemLocale = (Get-WinSystemLocale).Name
    Write-ADTLogEntry -Message ("Current System Locale: " + $currentSystemLocale) -Source 'Installation'

    # Set the location
    Write-ADTLogEntry -Message ("Set Home Location to GeoId: " + $defaultGeoId) -Source 'Installation'
    Set-WinHomeLocation -GeoId $defaultGeoId

    # Set the culture
    Write-ADTLogEntry -Message ("Set Culture to: " + $defaultTargetLanguage) -Source 'Installation'
    Set-Culture -CultureInfo $defaultTargetLanguage

    Write-ADTLogEntry -Message ("Target System Locale: " + $defaultTargetLanguage) -Source 'Installation'
    Set-WinSystemLocale -SystemLocale $defaultTargetLanguage

    # Document settings
    Write-ADTLogEntry -Message ("Document settings") -Source 'Installation'
    Write-ADTLogEntry -Message ("WinUserLanguageList: " + (Get-WinUserLanguageList | Out-String)) -Source 'Installation'
    Write-ADTLogEntry -Message ("WinHomeLocation: " + (Get-WinHomeLocation | Out-String)) -Source 'Installation'
    Write-ADTLogEntry -Message ("WinSystemLocale: " + (Get-WinSystemLocale | Out-String)) -Source 'Installation'
    Write-ADTLogEntry -Message ("WinUILanguageOverride: " + (Get-WinUILanguageOverride | Out-String)) -Source 'Installation'

    # Copy user international settings to system with WelcomeScreen and NewUser set to True
    Write-ADTLogEntry -Message ("Copy User International Settings to System with WelcomeScreen and NewUser set to True") -Source 'Installation'
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True

    Write-ADTLogEntry -Message ("Script finished") -Source 'Installation'

    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    # Update the registry with uninstall information
    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'DisplayName' `
        -Value $applicationName `
        -Type String

    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'Version' `
        -Value $adtSession.AppVersion `
        -Type String

    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'Revision' `
        -Value $adtSession.AppRevision `
        -Type String

    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'InstallDate' `
        -Value (Get-Date -Format 'yyyy-MM-dd') `
        -Type String

    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'AppScriptVersion' `
        -Value $adtSession.AppScriptVersion `
        -Type String

    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'AppScriptDate' `
        -Value $adtSession.AppScriptDate `
        -Type String

    ## Display a message at the end of the install.
    if (!$adtSession.UseDefaultMsi) {
        Show-ADTInstallationPrompt -Message 'Installation completed successfully.' -ButtonRightText 'OK' -NoWait
    }
}

function Uninstall-ADTDeployment {
    [CmdletBinding()]
    param
    (
    )

    ##================================================
    ## MARK: Pre-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## If there are processes to close, show Welcome Message with a 60 second countdown before automatically closing.
    if ($adtSession.AppProcessesToClose.Count -gt 0) {
        Show-ADTInstallationWelcome -CloseProcesses $adtSession.AppProcessesToClose -CloseProcessesCountdown 60
    }

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress

    ##================================================
    ## MARK: Uninstall
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI uninstallations.
    if ($adtSession.UseDefaultMsi) {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile) {
            $ExecuteDefaultMSISplat.Add('Transforms', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
    }

    # Add log entry for uninstallation tasks
    Write-ADTLogEntry -Message ("No uninstallation tasks defined") -Source 'Uninstallation'

    ##================================================
    ## MARK: Post-Uninstallation
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    # Remove the uninstall registry key for the application
    Remove-ADTRegistryKey `
        -LiteralPath $regPackageDetections

}

function Repair-ADTDeployment {
    [CmdletBinding()]
    param
    (
    )

    ##================================================
    ## MARK: Pre-Repair
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## If there are processes to close, show Welcome Message with a 60 second countdown before automatically closing.
    if ($adtSession.AppProcessesToClose.Count -gt 0) {
        Show-ADTInstallationWelcome -CloseProcesses $adtSession.AppProcessesToClose -CloseProcessesCountdown 60
    }

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress

    ##================================================
    ## MARK: Repair
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI repairs.
    if ($adtSession.UseDefaultMsi) {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile) {
            $ExecuteDefaultMSISplat.Add('Transforms', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
    }

    Write-ADTLogEntry -Message ("Script started") -Source 'Repair'

    # Get current System Locale
    $currentSystemLocale = (Get-WinSystemLocale).Name
    Write-ADTLogEntry -Message ("Current System Locale: " + $currentSystemLocale) -Source 'Repair'

    # Set the location
    Write-ADTLogEntry -Message ("Set Home Location to GeoId: " + $defaultGeoId) -Source 'Repair'
    Set-WinHomeLocation -GeoId $defaultGeoId

    # Set the culture
    Write-ADTLogEntry -Message ("Set Culture to: " + $defaultTargetLanguage) -Source 'Repair'
    Set-Culture -CultureInfo $defaultTargetLanguage

    Write-ADTLogEntry -Message ("Target System Locale: " + $defaultTargetLanguage) -Source 'Repair'
    Set-WinSystemLocale -SystemLocale $defaultTargetLanguage

    # Document settings
    Write-ADTLogEntry -Message ("Document settings") -Source 'Repair'
    Write-ADTLogEntry -Message ("WinUserLanguageList: " + (Get-WinUserLanguageList | Out-String)) -Source 'Repair'
    Write-ADTLogEntry -Message ("WinHomeLocation: " + (Get-WinHomeLocation | Out-String)) -Source 'Repair'
    Write-ADTLogEntry -Message ("WinSystemLocale: " + (Get-WinSystemLocale | Out-String)) -Source 'Repair'
    Write-ADTLogEntry -Message ("WinUILanguageOverride: " + (Get-WinUILanguageOverride | Out-String)) -Source 'Repair'

    # Copy user international settings to system with WelcomeScreen and NewUser set to True
    Write-ADTLogEntry -Message ("Copy User International Settings to System with WelcomeScreen and NewUser set to True") -Source 'Repair'
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True

    Write-ADTLogEntry -Message ("Script finished") -Source 'Repair'

    ##================================================
    ## MARK: Post-Repair
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    # Update the registry with uninstall information
    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'Revision' `
        -Value $adtSession.AppRevision `
        -Type String

    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'InstallDate' `
        -Value (Get-Date -Format 'yyyy-MM-dd') `
        -Type String

    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'AppScriptVersion' `
        -Value $adtSession.AppScriptVersion `
        -Type String

    Set-ADTRegistryKey `
        -LiteralPath $regPackageDetections `
        -Name 'AppScriptDate' `
        -Value $adtSession.AppScriptDate `
        -Type String

}


##================================================
## MARK: Initialization
##================================================

# Set strict error handling across entire operation.
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
Set-StrictMode -Version 1

# Import the module and instantiate a new session.
try {
    # Import the module locally if available, otherwise try to find it from PSModulePath.
    if (Test-Path -LiteralPath "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1" -PathType Leaf) {
        Get-ChildItem -LiteralPath "$PSScriptRoot\PSAppDeployToolkit" -Recurse -File | Unblock-File -ErrorAction Ignore
        Import-Module -FullyQualifiedName @{ ModuleName = "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.1.8' } -Force
    } else {
        Import-Module -FullyQualifiedName @{ ModuleName = 'PSAppDeployToolkit'; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.1.8' } -Force
    }

    # Open a new deployment session, replacing $adtSession with a DeploymentSession.
    $iadtParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation
    $adtSession = Remove-ADTHashtableNullOrEmptyValues -Hashtable $adtSession
    $adtSession = Open-ADTSession @adtSession @iadtParams -PassThru
} catch {
    $Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([System.Int32]::MaxValue)))
    exit 60008
}

##================================================
## CONFIG: Regional settings and ADT configuration
##================================================

# Define default GeoId and CultureInfo for regional settings
$defaultGeoId = 223
$defaultTargetLanguage = 'fr-CH'

# Initialize ADT configuration
$adtConfig = Get-ADTConfig

# Get the application name for registry entries
$applicationName = $adtSession.AppVendor + '_' + $adtSession.AppName + '_' + $adtSession.AppVersion

# Determine the registry path for uninstall information based on admin requirements
if ($adtSession.RequireAdmin) {
    $regPackageDetections = $adtConfig.Toolkit.RegPath + "\_PackageDetections\Packages\" + $applicationName
} else {
    $regPackageDetections = $adtConfig.Toolkit.RegPathNoAdminRights + "\_PackageDetections\Packages\" + $applicationName
}

##================================================
## MARK: Invocation
##================================================

# Commence the actual deployment operation.
try {
    # Import any found extensions before proceeding with the deployment.
    Get-ChildItem -LiteralPath $PSScriptRoot -Directory | & {
        process {
            if ($_.Name -match 'PSAppDeployToolkit\..+$') {
                Get-ChildItem -LiteralPath $_.FullName -Recurse -File | Unblock-File -ErrorAction Ignore
                Import-Module -Name $_.FullName -Force
            }
        }
    }

    # Invoke the deployment and close out the session.
    & "$($adtSession.DeploymentType)-ADTDeployment"

    Close-ADTSession

} catch {
    # An unhandled error has been caught.
    $mainErrorMessage = "An unhandled error within [$($MyInvocation.MyCommand.Name)] has occurred.`n$(Resolve-ADTErrorRecord -ErrorRecord $_)"
    Write-ADTLogEntry -Message $mainErrorMessage -Severity 3

    ## Error details hidden from the user by default. Show a simple dialog with full stack trace:
    # Show-ADTDialogBox -Text $mainErrorMessage -Icon Stop -NoWait

    ## Or, a themed dialog with basic error message:
    # Show-ADTInstallationPrompt -Message "$($adtSession.DeploymentType) failed at line $($_.InvocationInfo.ScriptLineNumber), char $($_.InvocationInfo.OffsetInLine):`n$($_.InvocationInfo.Line.Trim())`n`nMessage:`n$($_.Exception.Message)" -ButtonRightText OK -Icon Error -NoWait

    Close-ADTSession -ExitCode 60001
}
