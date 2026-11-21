#name: Extract Windows 11 25H2 Language Packages
#description: Extract selected language packs and Features on Demand from a Windows 11 25H2 Language and Optional Features ISO
#execution mode: Manual
#tags: beckmann.ch
#author: Stefan Beckmann, beckmann.ch

<# Notes:

Download the Windows 11 25H2 Language and Optional Features ISO and mount it locally. (https://my.visualstudio.com/ or https://learn.microsoft.com/en-us/azure/virtual-desktop/windows-11-language-packs from Microsoft)
The script reads the packages from D:\LanguagesAndOptionalFeatures and writes the selected files to C:\Temp\Windows 11 Enterprise 25H2.
It extracts client language packs, LIP language packs, Features on Demand, and language capabilities for en-US and the configured German, French, and Italian variants.
The target directory is split into ClientLanguagePack, LipLanguagePack, FeatureOnDemand, and Capability folders.
The final Compress-Archive command is currently disabled.

#>

# Define directories
$versionName = 'Windows 11 Enterprise 25H2'
$targetDrive = 'C:\Temp'
$languagePackISODrive = 'D:\'
$targetDirectory = Join-Path -Path $targetDrive -ChildPath $versionName

# Define supported languages
$languages = @(
    'en-US',
    'de-DE',
    'de-CH',
    'fr-FR',
    'fr-CH',
    'it-IT'
)

# Define directories for language packs and features
$clientLanguagePackDir = "$targetDirectory\ClientLanguagePack"
$lipLanguagePackDir = "$targetDirectory\LipLanguagePack"
$fdoDir = "$targetDirectory\FeatureOnDemand"
$capabilityDir = "$targetDirectory\Capability"

# Get all files from the mounted ISO
$allFiles = Get-ChildItem -Path "$languagePackISODrive\LanguagesAndOptionalFeatures"  | Select-Object -ExpandProperty FullName

# Filter files based on naming patterns
$clientLanguageFiles = $allFiles | Where-Object { $_ -like "*\Microsoft-Windows-Client-Language-Pack_x64_*.cab" }
$lipLanguageFiles = $allFiles | Where-Object { $_ -like "*\Microsoft-Windows-Lip-Language-Pack_x64_*.cab" }

# Select files for the specified languages
$selectedClientLanguageFiles = $clientLanguageFiles | Where-Object { $languages -contains $_.Substring($_.LastIndexOf('_') + 1, 5) }
$selectedLipLanguageFiles = $lipLanguageFiles | Where-Object { $languages -contains $_.Substring($_.LastIndexOf('_') + 1, 5) }

# Define additional FOD files
$additionalFodList = @(
    '*\Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-MSPaint-FoD-Package~31bf3856ad364e35~amd64~$language~.cab',
    '*\Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-SnippingTool-FoD-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-TPM-Diagnostics-FOD-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-VolumeActivation-Tools-FoD-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-WinOcr-FOD-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-WirelessDisplay-FOD-Package~31bf3856ad364e35~amd64~$language~.cab'
    '*\Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~amd64~$language~.cab'
)

# Define additional Capability files
$additionalCapabilityList = @(
    '*Microsoft-Windows-LanguageFeatures-Basic-$language-*.cab',
    '*Microsoft-Windows-LanguageFeatures-Handwriting-$language-*.cab',
    '*Microsoft-Windows-LanguageFeatures-OCR-$language-*.cab',
    '*Microsoft-Windows-LanguageFeatures-Speech-$language-*.cab',
    '*Microsoft-Windows-LanguageFeatures-TextToSpeech-$language-*.cab'
)

# Create arrays for selected FOD and Capability files
$selectedFdoFiles = @($allFiles | Where-Object { $_ -like "*\Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~~.cab" })
$selectedCapabilityFiles = @()

# Select FOD and Capability files for each language
foreach ($language in $languages) {
    $selectedFdoFiles += foreach ($fod in $additionalFodList) {
        $allFiles | Where-Object { $_ -like $ExecutionContext.InvokeCommand.ExpandString($fod) }
    }

    $selectedCapabilityFiles += foreach ($cap in $additionalCapabilityList) {
        $allFiles | Where-Object { $_ -like $ExecutionContext.InvokeCommand.ExpandString($cap) }
    }
}
$null = Remove-Variable language

# Check if target directory exists
if (-not (Test-Path -Path $targetDirectory)) {
    # Create target directory
    New-Item -ItemType Directory -Path $targetDirectory -Force
}

# Check if Client Language Pack directory exists
if (-not (Test-Path -Path $clientLanguagePackDir)) {
    # Create Client Language Pack directory
    New-Item -ItemType Directory -Path $clientLanguagePackDir -Force
}

# Check if LIP Language Pack directory exists
if (-not (Test-Path -Path $lipLanguagePackDir)) {
    # Create LIP Language Pack directory
    New-Item -ItemType Directory -Path $lipLanguagePackDir -Force
}

# Check if FDO directory exists
if (-not (Test-Path -Path $fdoDir)) {
    # Create FDO directory
    New-Item -ItemType Directory -Path $fdoDir -Force
}

# Check if Capability directory exists
if (-not (Test-Path -Path $capabilityDir)) {
    # Create Capability directory
    New-Item -ItemType Directory -Path $capabilityDir -Force
}

# Copy selected Client Language Pack files to target directory
foreach ($file in $selectedClientLanguageFiles) {
    Copy-Item -Path $file -Destination $clientLanguagePackDir -Force
}

# Copy selected LIP Language Pack files to target directory
foreach ($file in $selectedLipLanguageFiles) {
    Copy-Item -Path $file -Destination $lipLanguagePackDir -Force
}

# Copy selected FDO files to target directory
foreach ($file in $selectedFdoFiles) {
    Copy-Item -Path $file -Destination $fdoDir -Force
}

# Copy selected Capability files to target directory
foreach ($file in $selectedCapabilityFiles) {
    Copy-Item -Path $file -Destination $capabilityDir -Force
}

# Zip Target Directory
$zipFilePath = Join-Path -Path $targetDrive -ChildPath "$versionName.zip"
if (Test-Path -Path $zipFilePath) {
    Remove-Item -Path $zipFilePath -Force
}
#Compress-Archive -Path $targetDirectory\* -DestinationPath $zipFilePath -Force