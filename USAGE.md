# USAGE

#### Table of Contents
* [Module Documentation](#module-documentation)
* [Prerequisites](#prerequisites)
* [Single-user examples](#single-user-examples)
* [Organization-scale examples](#organization-scale-examples)
* [Desired-state plan files](#desired-state-plan-files)
* [Operational guidance](#operational-guidance)

----------

## Module Documentation

Documentation for all public commands for the module can be viewed:

```powershell
Get-Help -Full <commandName>
```

----------

## Prerequisites

To use this module you need to create an Azure AD / Microsoft Entra application. Once you have created the application you will need to perform the following tasks:

* Get the Client ID (Application ID) of the application.
* Get the Tenant ID of the Azure AD environment.
* Create a Client Secret or Client Certificate for the application.
* Add Microsoft Graph application permissions required by the commands you plan to run. Broad deployments commonly require `Files.ReadWrite.All`, `Sites.ReadWrite.All`, and `User.Read.All`; prefer least-privilege and selected-permission models where feasible.
* If you target groups, grant permissions that allow reading group membership.
* If you are using a Client Certificate you must have it stored on your workstation or loaded in your workstation's certificate store.

Use `Test-odscexPermission` before a large deployment to verify Graph connectivity, site access, and user drive access.

----------

## National cloud connections

Use `Connect-odscex -Cloud` to select the Microsoft cloud environment before running shortcut commands. Supported values are `Global`, `GCC`, `GCCHigh`, `DoD`, and `China`. The module requests tokens for the selected Microsoft Graph resource and stores the selected endpoint for all subsequent Graph API requests.

### Connecting to Microsoft 365 GCC

```powershell
Connect-odscex -Cloud GCC -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret (ConvertTo-SecureString -String "000000000000000000000000000" -AsPlainText -Force)
```

### Connecting to Microsoft 365 GCC High

```powershell
Connect-odscex -Cloud GCCHigh -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientCertificate (Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000')
```

### Connecting to Microsoft 365 DoD

```powershell
Connect-odscex -Cloud DoD -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientCertificate (Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000')
```

----------

## Single-user examples

### Connecting with a Client Secret

```powershell
Connect-odscex -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret (ConvertTo-SecureString -String "000000000000000000000000000" -AsPlainText -Force)
```

### Connecting with a Client Certificate

```powershell
Connect-odscex -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientCertificate (Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000')
```

### Disconnecting

```powershell
Disconnect-odscex
```

### Retrieving the properties of a Drive resource

```powershell
Get-odscexDrive -UserPrincipalName "user@contoso.com"
```

### Creating or converging a shortcut to a desired state

```powershell
Set-odscexShortcutState -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Working Document Library" -UserPrincipalName "user@contoso.com" -ShortcutName "Working" -State Present -ConflictAction Skip
```

### Creating a new Shortcut to a Document Library

```powershell
New-odscex -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Working Document Library" -UserPrincipalName "user@contoso.com"
```

### Creating a new Shortcut to a Subfolder in a Document Library

```powershell
New-odscex -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Working Document Library" -FolderPath "Working Folder" -UserPrincipalName "user@contoso.com"
```

### Creating a shortcut in a subfolder of the user's OneDrive

```powershell
New-odscex -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Working Document Library" -RelativePath "subfolder1/subfolder2" -UserPrincipalName "user@contoso.com"
```

### Getting an existing Shortcut by Name

```powershell
Get-odscex -ShortcutName "Working Folder" -UserPrincipalName "user@contoso.com"
```

### Removing an existing Shortcut by Name

```powershell
Remove-odscex -ShortcutName "Working Folder" -UserPrincipalName "user@contoso.com" -PassThru
```

----------

## Organization-scale examples

### Target a group

```powershell
$Users = Get-odscexTargetUser -GroupId "00000000-0000-0000-0000-000000000000"
Invoke-odscexShortcutAssignment -User $Users -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Documents" -ShortcutName "Working" -State Present -ConflictAction Skip -ReportPath ".\odscex-results.csv"
```

### Target users from CSV

```powershell
$Users = Get-odscexTargetUser -CsvPath ".\users.csv"
Invoke-odscexShortcutAssignment -User $Users -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Documents" -ShortcutName "Working" -State Present -ReportPath ".\odscex-results.json" -OutputFormat Json
```

The CSV should contain either `UserPrincipalName`, `UserObjectId`, or `Id` columns.

### Target filtered users

```powershell
$Users = Get-odscexTargetUser -Filter "accountEnabled eq true"
Invoke-odscexShortcutAssignment -User $Users -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Documents" -ShortcutName "Working"
```

### Remove a shortcut from a group

```powershell
$Users = Get-odscexTargetUser -GroupId "00000000-0000-0000-0000-000000000000"
Invoke-odscexShortcutAssignment -User $Users -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Documents" -ShortcutName "Working" -State Absent -ReportPath ".\odscex-remove.csv"
```

----------

## Desired-state plan files

`Invoke-odscexPlan` and `Invoke-odscexApply` support JSON and PowerShell data files.

### JSON example

```json
{
  "shortcuts": [
    {
      "name": "HR Policies",
      "siteUrl": "https://contoso.sharepoint.com/sites/HR",
      "library": "Documents",
      "folderPath": "Policies",
      "oneDrivePath": "Company",
      "state": "Present",
      "target": {
        "groupId": "00000000-0000-0000-0000-000000000000"
      }
    }
  ]
}
```

Apply the plan:

```powershell
Invoke-odscexApply -Path ".\shortcuts.json" -ReportPath ".\shortcut-apply.csv"
```

Preview the plan without applying it:

```powershell
Invoke-odscexPlan -Path ".\shortcuts.json"
Invoke-odscexApply -Path ".\shortcuts.json" -WhatIf
```

----------

## Operational guidance

* Use `Set-odscexShortcutState` or `Invoke-odscexShortcutAssignment` for repeatable runs. They report `Compliant` when the shortcut already points to the requested target.
* Use `-ConflictAction Skip`, `Replace`, `Rename`, or `Error` to decide what happens when a same-named item points elsewhere.
* Use `-ReportPath` and `-OutputFormat Csv|Json|Clixml` for audit evidence.
* Use `-ResumeFrom` to restart a failed assignment from a specific user index.
* The Microsoft Graph helper follows `@odata.nextLink` when callers request all pages and retries transient `429`, `500`, `502`, `503`, and `504` responses.
* Advanced callers can use `Invoke-odscexGraphBatch` to submit up to 20 Graph subrequests in a single JSON batch.
