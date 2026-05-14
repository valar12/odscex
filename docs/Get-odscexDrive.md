---
external help file: odscex-help.xml
Module Name: odscex
online version: https://github.com/innovara/odscex/blob/main/docs/Get-odscexDrive.md
schema: 2.0.0
---

# Get-odscexDrive

## SYNOPSIS
Retrieve the properties and relationships of a Drive resource.

## SYNTAX

### UserPrincipalName (Default)
```
Get-odscexDrive -UserPrincipalName <String> [<CommonParameters>]
```

### UserObjectId
```
Get-odscexDrive -UserObjectId <String> [<CommonParameters>]
```

## DESCRIPTION
The **Get-odscexDrive** function gets the metadata for a a user's OneDrive drive.

## EXAMPLES

### Example 1: Get a OneDrive drive
```powershell
PS C:\> Get-odscexDrive -UserPrincipalName "user@contoso.com"
```

This command gets the OneDrive drive for the user "user@contoso.com".

## PARAMETERS

### -UserObjectId
Specifies a string that contains the ID of a OneDrive user.

```yaml
Type: String
Parameter Sets: UserObjectId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserPrincipalName
Specifies a string that contains the user principal name of a OneDrive user.

```yaml
Type: String
Parameter Sets: UserPrincipalName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
