---
external help file: odscex-help.xml
Module Name: odscex
online version: https://github.com/innovara/odscex/blob/main/docs/Get-odscexTargetUser.md
schema: 2.0.0
---

# Get-odscexTargetUser

## SYNOPSIS
Provides organization-scale OneDrive shortcut management capabilities.

## DESCRIPTION
The **Get-odscexTargetUser** command is part of the enterprise management surface for odscex. Use these commands to resolve target users, apply desired shortcut state, run assignment plans, validate permissions, and produce operational reports.

When using -GroupId, odscex reads groups/{id}/transitiveMembers/microsoft.graph.user in Microsoft Graph. Grant admin consent for GroupMember.Read.All at minimum, or a broader equivalent such as Group.Read.All or Directory.Read.All. Hidden membership groups also require Member.Read.Hidden.

## EXAMPLES

### Example 1

See [USAGE.md](../USAGE.md) for complete examples covering group, CSV, filtered-user, and desired-state plan deployments.

## NOTES

These commands are designed for repeatable automation and return structured objects suitable for reporting.
