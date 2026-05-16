---
external help file: odscex-help.xml
Module Name: odscex
online version: https://github.com/innovara/odscex/blob/main/docs/Test-odscexPermission.md
schema: 2.0.0
---

# Test-odscexPermission

## SYNOPSIS
Validates Microsoft Graph connectivity and OneDrive/SharePoint shortcut prerequisites.

## DESCRIPTION
The **Test-odscexPermission** command validates the Microsoft Graph token and optional
OneDrive and SharePoint shortcut inputs before you create or assign shortcuts. When a
user is supplied, it verifies that the user's OneDrive root can be read. When a site
and document library are supplied, it verifies that the shortcut target can be resolved,
including an optional folder path.

## EXAMPLES

### Example 1: Validate a user's OneDrive and a shortcut target

```powershell
Test-odscexPermission -Uri 'https://contoso.sharepoint.com/sites/WorkingSite' -DocumentLibrary 'Documents' -UserPrincipalName 'user@contoso.com'
```

Validates Graph connectivity, the user's OneDrive, the SharePoint site, and the
`Documents` library target.

### Example 2: Validate a folder target by library id

```powershell
Test-odscexPermission -Uri 'https://contoso.sharepoint.com/sites/WorkingSite' -DocumentLibraryId '00000000-0000-0000-0000-000000000000' -FolderPath 'Department/Policies' -UserObjectId '11111111-1111-1111-1111-111111111111'
```

Validates the destination OneDrive and confirms that the folder path resolves relative
to the selected document library root.

## PARAMETERS

### -Uri
The SharePoint site URL that contains the shortcut target document library.

### -UserPrincipalName
The user principal name for the OneDrive destination to validate.

### -UserObjectId
The Microsoft Entra object id for the OneDrive destination to validate.

### -DocumentLibrary
The display name of the SharePoint document library to validate.

### -DocumentLibraryId
The SharePoint list id of the document library to validate. Use this when display names
are ambiguous.

### -FolderPath
An optional folder path inside the document library. The path must be relative to the
library root and should not include the document library name.

### -AllowAmbiguousLibraryMatch
Allows the command to use the first matching document library when a display name or
prefix search returns multiple libraries.

## NOTES

The command returns structured check objects with `Check`, `Status`, and `Message`
properties so validation results can be logged or exported.
