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
$HelpParameters = @{
    Name = '<commandName>'
    Full = $true
}

Get-Help @HelpParameters
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
$ClientSecretParameters = @{
    String = '000000000000000000000000000'
    AsPlainText = $true
    Force = $true
}

$ConnectParameters = @{
    Cloud = 'GCC'
    TenantId = '00000000-0000-0000-0000-000000000000'
    ClientId = '00000000-0000-0000-0000-000000000000'
    ClientSecret = ConvertTo-SecureString @ClientSecretParameters
}

Connect-odscex @ConnectParameters
```

### Connecting to Microsoft 365 GCC High

```powershell
$CertificateParameters = @{
    Path = 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000'
}
$Certificate = Get-Item @CertificateParameters
$ConnectParameters = @{
    Cloud = 'GCCHigh'
    TenantId = '00000000-0000-0000-0000-000000000000'
    ClientId = '00000000-0000-0000-0000-000000000000'
    ClientCertificate = $Certificate
}

Connect-odscex @ConnectParameters
```

### Connecting to Microsoft 365 DoD

```powershell
$CertificateParameters = @{
    Path = 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000'
}
$Certificate = Get-Item @CertificateParameters
$ConnectParameters = @{
    Cloud = 'DoD'
    TenantId = '00000000-0000-0000-0000-000000000000'
    ClientId = '00000000-0000-0000-0000-000000000000'
    ClientCertificate = $Certificate
}

Connect-odscex @ConnectParameters
```

----------

## Single-user examples

### Connecting with a Client Secret

```powershell
$ClientSecretParameters = @{
    String = '000000000000000000000000000'
    AsPlainText = $true
    Force = $true
}

$ConnectParameters = @{
    TenantId = '00000000-0000-0000-0000-000000000000'
    ClientId = '00000000-0000-0000-0000-000000000000'
    ClientSecret = ConvertTo-SecureString @ClientSecretParameters
}

Connect-odscex @ConnectParameters
```

### Connecting with a Client Certificate

```powershell
$CertificateParameters = @{
    Path = 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000'
}
$Certificate = Get-Item @CertificateParameters
$ConnectParameters = @{
    TenantId = '00000000-0000-0000-0000-000000000000'
    ClientId = '00000000-0000-0000-0000-000000000000'
    ClientCertificate = $Certificate
}

Connect-odscex @ConnectParameters
```

### Disconnecting

```powershell
Disconnect-odscex
```

### Retrieving the properties of a Drive resource

```powershell
$DriveParameters = @{
    UserPrincipalName = 'user@contoso.com'
}

Get-odscexDrive @DriveParameters
```

### Creating or converging a shortcut to a desired state

```powershell
$ShortcutStateParameters = @{
    Uri = 'https://contoso.sharepoint.com/sites/WorkingSite'
    DocumentLibrary = 'Working Document Library'
    UserPrincipalName = 'user@contoso.com'
    ShortcutName = 'Working'
    State = 'Present'
    ConflictAction = 'Skip'
}

Set-odscexShortcutState @ShortcutStateParameters
```

### Creating a new Shortcut to a Document Library

```powershell
$ShortcutParameters = @{
    Uri = 'https://contoso.sharepoint.com/sites/WorkingSite'
    DocumentLibrary = 'Working Document Library'
    UserPrincipalName = 'user@contoso.com'
}

New-odscex @ShortcutParameters
```

### Creating a new Shortcut to a Subfolder in a Document Library

```powershell
$ShortcutParameters = @{
    Uri = 'https://contoso.sharepoint.com/sites/WorkingSite'
    DocumentLibrary = 'Working Document Library'
    FolderPath = 'Working Folder'
    UserPrincipalName = 'user@contoso.com'
}

New-odscex @ShortcutParameters
```

### Creating a shortcut in a subfolder of the user's OneDrive

```powershell
$ShortcutParameters = @{
    Uri = 'https://contoso.sharepoint.com/sites/WorkingSite'
    DocumentLibrary = 'Working Document Library'
    RelativePath = 'subfolder1/subfolder2'
    UserPrincipalName = 'user@contoso.com'
}

New-odscex @ShortcutParameters
```

### Getting an existing Shortcut by Name

```powershell
$ShortcutLookupParameters = @{
    ShortcutName = 'Working Folder'
    UserPrincipalName = 'user@contoso.com'
}

Get-odscex @ShortcutLookupParameters
```

### Removing an existing Shortcut by Name

```powershell
$RemoveParameters = @{
    ShortcutName = 'Working Folder'
    UserPrincipalName = 'user@contoso.com'
    PassThru = $true
}

Remove-odscex @RemoveParameters
```

----------

## Organization-scale examples

Group targeting reads groups/{id}/transitiveMembers/microsoft.graph.user in Microsoft Graph. Grant admin consent for GroupMember.Read.All at minimum, or a broader equivalent such as Group.Read.All or Directory.Read.All. Hidden membership groups also require Member.Read.Hidden.

### Target a group

```powershell
$TargetUserParameters = @{
    GroupId = '00000000-0000-0000-0000-000000000000'
}
$Users = Get-odscexTargetUser @TargetUserParameters

$AssignmentParameters = @{
    User = $Users
    Uri = 'https://contoso.sharepoint.com/sites/WorkingSite'
    DocumentLibrary = 'Documents'
    ShortcutName = 'Working'
    State = 'Present'
    ConflictAction = 'Skip'
    ReportPath = '.\odscex-results.csv'
}

Invoke-odscexShortcutAssignment @AssignmentParameters
```

### Target users from CSV

```powershell
$TargetUserParameters = @{
    CsvPath = '.\users.csv'
}
$Users = Get-odscexTargetUser @TargetUserParameters

$AssignmentParameters = @{
    User = $Users
    Uri = 'https://contoso.sharepoint.com/sites/WorkingSite'
    DocumentLibrary = 'Documents'
    ShortcutName = 'Working'
    State = 'Present'
    ReportPath = '.\odscex-results.json'
    OutputFormat = 'Json'
}

Invoke-odscexShortcutAssignment @AssignmentParameters
```

The CSV should contain either `UserPrincipalName`, `UserObjectId`, or `Id` columns.

### Target filtered users

```powershell
$TargetUserParameters = @{
    Filter = 'accountEnabled eq true'
}
$Users = Get-odscexTargetUser @TargetUserParameters

$AssignmentParameters = @{
    User = $Users
    Uri = 'https://contoso.sharepoint.com/sites/WorkingSite'
    DocumentLibrary = 'Documents'
    ShortcutName = 'Working'
}

Invoke-odscexShortcutAssignment @AssignmentParameters
```

### Remove a shortcut from a group

```powershell
$TargetUserParameters = @{
    GroupId = '00000000-0000-0000-0000-000000000000'
}
$Users = Get-odscexTargetUser @TargetUserParameters

$AssignmentParameters = @{
    User = $Users
    Uri = 'https://contoso.sharepoint.com/sites/WorkingSite'
    DocumentLibrary = 'Documents'
    ShortcutName = 'Working'
    State = 'Absent'
    ReportPath = '.\odscex-remove.csv'
}

Invoke-odscexShortcutAssignment @AssignmentParameters
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
$ApplyParameters = @{
    Path = '.\shortcuts.json'
    ReportPath = '.\shortcut-apply.csv'
}

Invoke-odscexApply @ApplyParameters
```

Preview the plan without applying it:

```powershell
$PlanParameters = @{
    Path = '.\shortcuts.json'
}
Invoke-odscexPlan @PlanParameters

$ApplyParameters = @{
    Path = '.\shortcuts.json'
    WhatIf = $true
}
Invoke-odscexApply @ApplyParameters
```

----------

## Operational guidance

* Use `Set-odscexShortcutState` or `Invoke-odscexShortcutAssignment` for repeatable runs. They report `Compliant` when the shortcut already points to the requested target.
* Use `-ConflictAction Skip`, `Replace`, `Rename`, or `Error` to decide what happens when a same-named item points elsewhere.
* Use `-ReportPath` and `-OutputFormat Csv|Json|Clixml` for audit evidence.
* Use `-ResumeFrom` to restart a failed assignment from a specific user index.
* The Microsoft Graph helper follows `@odata.nextLink` when callers request all pages and retries transient `429`, `500`, `502`, `503`, and `504` responses.
* Advanced callers can use `Invoke-odscexGraphBatch` to submit up to 20 Graph subrequests in a single JSON batch.
