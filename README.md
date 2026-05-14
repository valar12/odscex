# odsc-ev PowerShell Module

[![GitHub Release](https://badge.fury.io/gh/valar12%2Fodsc-ev.svg)](https://github.com/valar12/odsc-ev/releases)
[![PowerShell Gallery Release](https://img.shields.io/powershellgallery/v/odsc-ev)](https://www.powershellgallery.com/packages/odsc-ev)
[![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/valar12/odsc-ev/blob/main/LICENSE.md)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/valar12/odsc-ev)](https://github.com/valar12/odsc-ev/commits/main)

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

odsc-ev is a [PowerShell](https://microsoft.com/powershell) [module](https://technet.microsoft.com/en-us/library/dd901839.aspx)
that provides CLI access to managing SharePoint shortcuts in OneDrive. It supports both single-user shortcut operations and organization-scale desired-state assignments for groups, CSV targets, filtered users, or all users.

The expanded organization management surface is intended for repeatable administrative runs. You can resolve users, validate access, apply shortcuts idempotently, remove shortcuts, export reports, and define shortcuts in a plan file for scheduled or CI/CD-driven deployments.

## What's New

Check out [CHANGELOG.md](CHANGELOG.md) to review the details of all releases.

## Installation

You can get latest release of the odsc-ev module on the [PowerShell Gallery](https://www.powershellgallery.com/packages/odsc-ev)

```PowerShell
Install-Module -Name odsc-ev
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

odsc-ev can authenticate and send Microsoft Graph requests to multiple Microsoft cloud environments. Use `Connect-odsc-ev -Cloud` instead of manually setting endpoints.

| Cloud | Microsoft Graph endpoint | Notes |
| --- | --- | --- |
| `Global` | `https://graph.microsoft.com` | Default worldwide Microsoft Graph service. |
| `GCC` | `https://graph.microsoft.com` | Microsoft 365 GCC uses worldwide Microsoft Graph endpoints. |
| `GCCHigh` | `https://graph.microsoft.us` | Microsoft Graph for US Government L4 / GCC High. |
| `DoD` | `https://dod-graph.microsoft.us` | Microsoft Graph for US Government L5 / DoD. |
| `China` | `https://microsoftgraph.chinacloudapi.cn` | Microsoft Graph China operated by 21Vianet. |

Example GCC connection:

```powershell
Connect-odsc-ev `
    -Cloud GCC `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientSecret (ConvertTo-SecureString -String "client-secret" -AsPlainText -Force)
```

Example GCC High connection:

```powershell
$Certificate = Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000'
Connect-odsc-ev `
    -Cloud GCCHigh `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientCertificate $Certificate
```

After connection, every module command uses a token scoped to the selected cloud's Graph resource and sends requests to that cloud's Graph endpoint until `Disconnect-odsc-ev` is called or another `Connect-odsc-ev` call selects a different cloud. Advanced callers can use `-GraphEndpoint` to override the Graph root endpoint when required.

## Usage

Connect with a client secret:

```powershell
Connect-odsc-ev `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientSecret (ConvertTo-SecureString -String "client-secret" -AsPlainText -Force)
```

Connect with a certificate:

```powershell
$Certificate = Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000'
Connect-odsc-ev `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientCertificate $Certificate
```

Disconnect when finished:

```powershell
Disconnect-odsc-ev
```

For full command-level help, run:

```powershell
Get-Help -Full <commandName>
```

For additional examples, see [USAGE.md](USAGE.md).

## Single-user shortcut management

### Get a user's OneDrive drive metadata

```powershell
Get-odsc-evDrive -UserPrincipalName "user@contoso.com"
```

### Create a shortcut to a document library

```powershell
New-odsc-ev `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com"
```

### Create a shortcut to a document library folder

```powershell
New-odsc-ev `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -FolderPath "Department/Policies" `
    -ShortcutName "Department Policies" `
    -UserPrincipalName "user@contoso.com"
```

### Place the shortcut in a OneDrive subfolder

```powershell
New-odsc-ev `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -RelativePath "Company/Shortcuts" `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com"
```

### Converge a shortcut with desired-state behavior

`Set-odsc-evShortcutState` is the recommended command for repeatable automation. If the shortcut already points to the requested SharePoint target, the command reports `Compliant` instead of creating a duplicate.

```powershell
Set-odsc-evShortcutState `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com" `
    -State Present `
    -ConflictAction Skip
```

### Replace a conflicting shortcut

```powershell
Set-odsc-evShortcutState `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com" `
    -State Present `
    -ConflictAction Replace
```

### Remove a shortcut

```powershell
Remove-odsc-ev `
    -ShortcutName "Working Documents" `
    -UserPrincipalName "user@contoso.com" `
    -PassThru
```

## Organization-scale management

Use `Get-odsc-evTargetUser` to resolve users, then apply a desired shortcut state with `Invoke-odsc-evShortcutAssignment` or `Invoke-odsc-evApply`.

### Validate permissions before rollout

```powershell
Test-odsc-evPermission `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -UserPrincipalName "pilot.user@contoso.com"
```

### Assign a shortcut to all members of a group

```powershell
$Users = Get-odsc-evTargetUser -GroupId "00000000-0000-0000-0000-000000000000"

Invoke-odsc-evShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Present `
    -ConflictAction Skip `
    -ReportPath ".\odsc-ev-group-results.csv"
```

### Assign a shortcut to users from a CSV file

The CSV should contain `UserPrincipalName`, `UserObjectId`, or `Id` columns.

```powershell
$Users = Get-odsc-evTargetUser -CsvPath ".\users.csv"

Invoke-odsc-evShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -ReportPath ".\odsc-ev-csv-results.json" `
    -OutputFormat Json
```

### Assign a shortcut to filtered users

```powershell
$Users = Get-odsc-evTargetUser -Filter "accountEnabled eq true"

Invoke-odsc-evShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Present
```

### Assign a shortcut to all users

```powershell
$Users = Get-odsc-evTargetUser -AllUsers

Invoke-odsc-evShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/Company" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Company Documents" `
    -State Present `
    -ReportPath ".\odsc-ev-all-users.csv"
```

### Remove a shortcut for a target population

```powershell
$Users = Get-odsc-evTargetUser -GroupId "00000000-0000-0000-0000-000000000000"

Invoke-odsc-evShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Absent `
    -ReportPath ".\odsc-ev-remove-results.csv"
```

### Preview changes with WhatIf

```powershell
$Users = Get-odsc-evTargetUser -CsvPath ".\pilot-users.csv"

Invoke-odsc-evShortcutAssignment `
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
Invoke-odsc-evShortcutAssignment `
    -User $Users `
    -Uri "https://contoso.sharepoint.com/sites/WorkingSite" `
    -DocumentLibrary "Documents" `
    -ShortcutName "Working Documents" `
    -State Present `
    -ResumeFrom 250 `
    -ReportPath ".\odsc-ev-resumed-results.csv"
```

## Desired-state plan files

Plan files let you describe expected shortcuts once and reapply them on a schedule. `Invoke-odsc-evPlan` and `Invoke-odsc-evApply` support JSON and PowerShell data files.

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
Invoke-odsc-evPlan -Path ".\shortcuts.json"
```

Apply the plan and export a report:

```powershell
Invoke-odsc-evApply `
    -Path ".\shortcuts.json" `
    -ReportPath ".\shortcut-apply.csv"
```

Preview the plan without applying changes:

```powershell
Invoke-odsc-evApply -Path ".\shortcuts.json" -WhatIf
```

## Reporting and audit output

Organization-scale commands return structured result objects and can also write reports. The report format can be `Csv`, `Json`, or `Clixml`.

```powershell
Invoke-odsc-evShortcutAssignment `
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

`Invoke-odsc-evApiRequest` follows `@odata.nextLink` when callers request all pages and retries transient Microsoft Graph responses such as `429`, `500`, `502`, `503`, and `504`. Advanced callers can also submit JSON batches of up to 20 Microsoft Graph subrequests.

```powershell
Invoke-odsc-evGraphBatch -Requests @(
    @{ id = 'drive'; method = 'GET'; url = '/users/user@contoso.com/drive' },
    @{ id = 'site'; method = 'GET'; url = '/sites/contoso.sharepoint.com:/sites/WorkingSite' }
)
```

## Licensing

odsc-ev is licensed under the [MIT license](LICENSE.md).
