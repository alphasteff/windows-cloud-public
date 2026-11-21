# Scripts Documentation

## Create-LanguagePackFile.ps1

[`Create-LanguagePackFile.ps1`](./Create-LanguagePackFile.ps1) creates a curated Windows 11 language pack source from a mounted **Languages and Optional Features** ISO. It selects the configured client language packs, Local Experience Packs (LIPs), Features on Demand (FoD), and language capabilities, then copies the matching CAB files into a structured target directory.

### Prerequisites

- Download the Windows 11 Languages and Optional Features ISO from Microsoft.
- Mount the ISO and note its drive letter.
- Run the script in a PowerShell session that can read the mounted ISO and write to the target directory.
- Ensure sufficient disk space is available for the selected CAB files.

### Configuration

Update the variables at the beginning of the script before running it:

| Variable | Default | Description |
| --- | --- | --- |
| `$versionName` | `Windows 11 Enterprise 25H2` | Name of the output folder and ZIP file. |
| `$targetDrive` | `C:\Temp` | Parent directory for the generated language pack source. |
| `$languagePackISODrive` | `D:\` | Drive where the ISO is mounted. |
| `$languages` | `en-US`, `de-DE`, `de-CH`, `fr-FR`, `fr-CH`, `it-IT` | Language codes whose packages are copied. |

The `$additionalFodList` and `$additionalCapabilityList` arrays control which optional feature and language capability packages are included.

### Usage

```powershell
.\Create-LanguagePackFile.ps1
```

The script scans the `LanguagesAndOptionalFeatures` directory on the mounted ISO and creates the following structure:

```text
C:\Temp\Windows 11 Enterprise 25H2\
|-- ClientLanguagePack\
|-- LipLanguagePack\
|-- FeatureOnDemand\
`-- Capability\
```

Existing files with the same names are overwritten. The script also prepares the path `C:\Temp\Windows 11 Enterprise 25H2.zip` and removes an existing archive at that location. Archive creation is currently disabled because the `Compress-Archive` command at the end of the script is commented out. Uncomment that command to generate the ZIP file.
