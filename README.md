# odsc PowerShell Module

[![GitHub Release](https://badge.fury.io/gh/innovara%2Fodsc.svg)](https://github.com/innovara/odsc/releases)
[![PowerShell Gallery Release](https://img.shields.io/powershellgallery/v/odsc)](https://www.powershellgallery.com/packages/odsc)
[![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/innovara/odsc/blob/main/LICENSE.md)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/innovara/odsc)](https://github.com/innovara/odsc/commits/main)

#### Table of Contents

* [Overview](#overview)
* [What's New](#whats-new)
* [Installation](#installation)
* [Prerequisites](#prerequisites)
* [National cloud support](#national-cloud-support)
* [Usage](#usage)
* [Single-user shortcut management](#single-user-shortcut-management)
* [Organization-scale management](#organization-scale-management)
* [Desired-state plan files](#desired-state-plan-files)
* [Reporting and audit output](#reporting-and-audit-output)
* [Advanced Graph operations](#advanced-graph-operations)
* [Licensing](#licensing)

----------

## Overview

odsc is a [PowerShell](https://microsoft.com/powershell) [module](https://technet.microsoft.com/en-us/library/dd901839.aspx)
that provides CLI access to managing SharePoint shortcuts in OneDrive. It supports both single-user shortcut operations and organization-scale desired-state assignments for groups, CSV targets, filtered users, or all users.

The expanded organization management surface is intended for repeatable administrative runs. You can resolve users, validate access, apply shortcuts idempotently, remove shortcuts, export reports, and define shortcuts in a plan file for scheduled or CI/CD-driven deployments.

## What's New

Check out [CHANGELOG.md](CHANGELOG.md) to review the details of all releases.

## Installation

You can get latest release of the odsc module on the [PowerShell Gallery](https://www.powershellgallery.com/packages/odsc)

```PowerShell
Install-Module -Name odsc
```

## Prerequisites

To use this module you need a Microsoft Entra application registration that can authenticate to Microsoft Graph. At a minimum, collect or configure:

* Tenant ID
* Client ID / Application ID
* Client secret or certificate
* Microsoft Graph application permissions for the operations you will run
* Admin consent for those permissions

Broad organization-scale deployments commonly require permissions such as `Files.ReadWrite.All`, `Sites.ReadWrite.All`, and `User.Read.All`. Targeting users by group also requires permission to read group membership. Use the least-privilege model your tenant supports, and validate access before a broad rollout.

## National cloud support

odsc can authenticate and send Microsoft Graph requests to multiple Microsoft cloud environments. Use `Connect-odsc -Cloud` instead of manually setting endpoints.

| Cloud | Microsoft Graph endpoint | Notes |
| --- | --- | --- |
| `Global` | `https://graph.microsoft.com` | Default worldwide Microsoft Graph service. |
| `GCC` | `https://graph.microsoft.com` | Microsoft 365 GCC uses worldwide Microsoft Graph endpoints. |
| `GCCHigh` | `https://graph.microsoft.us` | Microsoft Graph for US Government L4 / GCC High. |
| `DoD` | `https://dod-graph.microsoft.us` | Microsoft Graph for US Government L5 / DoD. |
| `China` | `https://microsoftgraph.chinacloudapi.cn` | Microsoft Graph China operated by 21Vianet. |

Example GCC connection:

```powershell
Connect-odsc `
    -Cloud GCC `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientSecret (ConvertTo-SecureString -String "client-secret" -AsPlainText -Force)
```

Example GCC High connection:

```powershell
$Certificate = Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000'
Connect-odsc `
    -Cloud GCCHigh `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientCertificate $Certificate
```

After connection, every module command uses a token scoped to the selected cloud's Graph resource and sends requests to that cloud's Graph endpoint until `Disconnect-odsc` is called or another `Connect-odsc` call selects a different cloud. Advanced callers can use `-GraphEndpoint` to override the Graph root endpoint when required.

## Usage

Connect with a client secret:

```powershell
Connect-odsc `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientSecret (ConvertTo-SecureString -String "client-secret" -AsPlainText -Force)
```

Connect with a certificate:

```powershell
$Certificate = Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000'
Connect-odsc `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientCertificate $Certificate
```

Disconnect when finished:

```powershell
Disconnect-odsc
```

For full command-level help, run:

```powershell
Get-Help -Full <commandName>
```

For additional examples, see [USAGE.md](USAGE.md).

## Single-user shortcut management

### Get a user's OneDrive drive metadata

```powershell
Get-odscDrive -UserPrincipalName "user@contoso.com"
```

### Create a shortcut to a document library

```powershell
New-odsc `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com"
```

### Create a shortcut to a document library folder

```powershell
New-odsc `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -FolderPath "Department/Policies" `
    -ShortcutName "Department Policies" `
    -UserPrincipalName "user@contoso.com"
```

### Place the shortcut in a OneDrive subfolder

```powershell
New-odsc `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -RelativePath "Company/Shortcuts" `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com"
```

### Converge a shortcut with desired-state behavior

`Set-odscShortcutState` is the recommended command for repeatable automation. If the shortcut already points to the requested SharePoint target, the command reports `Compliant` instead of creating a duplicate.

```powershell
Set-odscShortcutState `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com" `
    -State Present `
    -ConflictAction Skip
```

### Replace a conflicting shortcut

```powershell
Set-odscShortcutState `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com" `
    -State Present `
    -ConflictAction Replace
```

### Remove a shortcut

```powershell
Remove-odsc `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com" `
    -PassThru
```

## Organization-scale management

Use `Get-odscTargetUser` to resolve users, then apply a desired shortcut state with `Invoke-odscShortcutAssignment` or `Invoke-odscApply`.

### Validate permissions before rollout

```powershell
Test-odscPermission `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -UserPrincipalName "pilot.user@contoso.com"
```

### Assign a shortcut to all members of a group

```powershell
$Users = Get-odscTargetUser -GroupId "00000000-0000-0000-0000-000000000000"

Invoke-odscShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Present `
    -ConflictAction Skip `
    -ReportPath ".\odsc-group-results.csv"
```

### Assign a shortcut to users from a CSV file

The CSV should contain `UserPrincipalName`, `UserObjectId`, or `Id` columns.

```powershell
$Users = Get-odscTargetUser -CsvPath ".\users.csv"

Invoke-odscShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -ReportPath ".\odsc-csv-results.json" `
    -OutputFormat Json
```

### Assign a shortcut to filtered users

```powershell
$Users = Get-odscTargetUser -Filter "accountEnabled eq true"

Invoke-odscShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Present
```

### Assign a shortcut to all users

```powershell
$Users = Get-odscTargetUser -AllUsers

Invoke-odscShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/Company" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Company Documents" `
    -State Present `
    -ReportPath ".\odsc-all-users.csv"
```

### Remove a shortcut for a target population

```powershell
$Users = Get-odscTargetUser -GroupId "00000000-0000-0000-0000-000000000000"

Invoke-odscShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Absent `
    -ReportPath ".\odsc-remove-results.csv"
```

### Preview changes with WhatIf

```powershell
$Users = Get-odscTargetUser -CsvPath ".\pilot-users.csv"

Invoke-odscShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Present `
    -WhatIf
```

### Resume a large run

If a large run stops after processing some users, use `-ResumeFrom` to continue at a zero-based user index.

```powershell
Invoke-odscShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Present `
    -ResumeFrom 250 `
    -ReportPath ".\odsc-resumed-results.csv"
```

## Desired-state plan files

Plan files let you describe expected shortcuts once and reapply them on a schedule. `Invoke-odscPlan` and `Invoke-odscApply` support JSON and PowerShell data files.

### Example JSON plan

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
    },
    {
      "name": "Company Handbook",
      "siteUrl": "https://contoso.sharepoint.com/sites/Company",
      "library": "Documents",
      "state": "Present",
      "target": {
        "allUsers": true
      }
    }
  ]
}
```

Review the plan:

```powershell
Invoke-odscPlan -Path ".\shortcuts.json"
```

Apply the plan and export a report:

```powershell
Invoke-odscApply `
    -Path ".\shortcuts.json" `
    -ReportPath ".\shortcut-apply.csv"
```

Preview the plan without applying changes:

```powershell
Invoke-odscApply -Path ".\shortcuts.json" -WhatIf
```

## Reporting and audit output

Organization-scale commands return structured result objects and can also write reports. The report format can be `Csv`, `Json`, or `Clixml`.

```powershell
Invoke-odscShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -ReportPath ".\shortcut-audit.clixml" `
    -OutputFormat Clixml
```

Common statuses include:

* `Created` - shortcut was created.
* `Compliant` - shortcut already pointed to the requested target.
* `AlreadyAbsent` - shortcut removal was requested and no matching shortcut existed.
* `Removed` - shortcut was removed.
* `SkippedConflict` - a same-named item existed and `-ConflictAction Skip` was used.
* `Failed` - the user assignment failed and the error was captured in the result object.

## Advanced Graph operations

`Invoke-odscApiRequest` follows `@odata.nextLink` when callers request all pages and retries transient Microsoft Graph responses such as `429`, `500`, `502`, `503`, and `504`. Advanced callers can also submit JSON batches of up to 20 Microsoft Graph subrequests.

```powershell
Invoke-odscGraphBatch -Requests @(
    @{ id = 'drive'; method = 'GET'; url = '/users/user@contoso.com/drive' },
    @{ id = 'site'; method = 'GET'; url = '/sites/contoso.sharepoint.com:/sites/WorkingSite' }
)
```

## Licensing

odsc is licensed under the [MIT license](LICENSE.md).
