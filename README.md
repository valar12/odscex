# odsc PowerShell Module

[![GitHub Release](https://badge.fury.io/gh/innovara%2Fodsc.svg)](https://github.com/innovara/odsc/releases)
[![PowerShell Gallery Release](https://img.shields.io/powershellgallery/v/odsc)](https://www.powershellgallery.com/packages/odsc)
[![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/innovara/odsc/blob/main/LICENSE.md)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/innovara/odsc)](https://github.com/innovara/odsc/commits/main)

#### Table of Contents

* [Overview](#overview)
* [What's New](#whats-new)
* [Installation](#installation)
* [Usage](#usage)
* [Organization-scale management](#organization-scale-management)
* [Licensing](#licensing)

----------

## Overview

odsc is a [PowerShell](https://microsoft.com/powershell) [module](https://technet.microsoft.com/en-us/library/dd901839.aspx)
that provides CLI access to managing SharePoint shortcuts in OneDrive. It supports both single-user shortcut operations and organization-scale desired-state assignments for groups, CSV targets, filtered users, or all users.

## What's New

Check out [CHANGELOG.md](CHANGELOG.md) to review the details of all releases.

## Installation

You can get latest release of the odsc module on the [PowerShell Gallery](https://www.powershellgallery.com/packages/odsc)

```PowerShell
Install-Module -Name odsc
```

## Usage

Example command:

```powershell
$Shortcut = Get-odsc -ShortcutName "Working Folder" -UserPrincipalName "user@contoso.com"
```

For more example commands, please refer to [USAGE.md](USAGE.md).

## Organization-scale management

Use `Get-odscTargetUser` to resolve users, then apply a desired shortcut state with `Invoke-odscShortcutAssignment` or `Invoke-odscApply`.

```powershell
$Users = Get-odscTargetUser -GroupId "00000000-0000-0000-0000-000000000000"
Invoke-odscShortcutAssignment -User $Users -Uri "https://contoso.sharepoint.com/sites/WorkingSite" -DocumentLibrary "Documents" -ShortcutName "Working" -State Present -ConflictAction Skip -ReportPath ".\odsc-results.csv"
```

Desired-state runs are idempotent by default: an existing shortcut that already points to the requested SharePoint target is reported as `Compliant` instead of being recreated.

## Licensing

odsc is licensed under the [MIT license](LICENSE.md).
