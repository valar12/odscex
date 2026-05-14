---
external help file: odscex-help.xml
Module Name: odscex
online version: https://github.com/innovara/odscex/blob/main/docs/Connect-odscex.md
schema: 2.0.0
---

# Connect-odscex

## SYNOPSIS
Connects and creates a session to the Microsoft Graph API.

## SYNTAX

### ClientSecret (Default)
```
Connect-odscex -TenantId <String> -ClientId <String> -ClientSecret <SecureString> [-Cloud <String>] [-AzureCloudInstance <Integer>] [-GraphEndpoint <String>] [<CommonParameters>]
```

### ClientCertificate
```
Connect-odscex -TenantId <String> -ClientId <String> -ClientCertificate <X509Certificate2> [-Cloud <String>] [-AzureCloudInstance <Integer>] [-GraphEndpoint <String>] [<CommonParameters>]
```

## DESCRIPTION
The **Connect-odscex** function authenticates and creates a session to the Microsoft Graph API. Use `-Cloud` to select the Microsoft Graph and token authority endpoints for worldwide, GCC, GCC High, DoD, and China environments.

Supported cloud values:

* `Global` - Microsoft Graph global service, `https://graph.microsoft.com`.
* `GCC` - Microsoft 365 GCC, which uses worldwide Microsoft Graph endpoints, `https://graph.microsoft.com`.
* `GCCHigh` - Microsoft Graph for US Government L4, `https://graph.microsoft.us`.
* `DoD` - Microsoft Graph for US Government L5, `https://dod-graph.microsoft.us`.
* `China` - Microsoft Graph China operated by 21Vianet, `https://microsoftgraph.chinacloudapi.cn`.

## EXAMPLES

### Example 1: Connect using a client secret
```powershell
PS C:\> Connect-odscex -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret (ConvertTo-SecureString -String "000000000000000000000000000" -AsPlainText -Force)
```

This command connects to the Microsoft Graph global service using a client secret configured in the Azure AD application.

### Example 2: Connect using a client certificate
```powershell
PS C:\> Connect-odscex -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientCertificate (Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000')
```

This command connects to the Microsoft Graph API using a client certificate configured in the Azure AD application.

### Example 3: Connect to Microsoft 365 GCC
```powershell
PS C:\> Connect-odscex -Cloud GCC -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret (ConvertTo-SecureString -String "000000000000000000000000000" -AsPlainText -Force)
```

This command connects to a Microsoft 365 GCC tenant. GCC uses the worldwide Microsoft Graph endpoint.

### Example 4: Connect to Microsoft 365 GCC High
```powershell
PS C:\> Connect-odscex -Cloud GCCHigh -TenantId "00000000-0000-0000-0000-000000000000" -ClientId "00000000-0000-0000-0000-000000000000" -ClientCertificate (Get-Item -Path 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000')
```

This command connects to a GCC High tenant using the Azure US Government token authority, requests a `https://graph.microsoft.us/.default` token, and sends API requests to the `https://graph.microsoft.us` Microsoft Graph endpoint.

## PARAMETERS

### -AzureCloudInstance
Specifies an integer that corresponds to an Azure Cloud Instance type (None = 0, AzurePublic = 1, AzureChina = 2, AzureGermany = 3, AzureUsGovernment = 4). This parameter is retained for compatibility. Prefer `-Cloud` for national cloud selection because it also selects the Microsoft Graph endpoint. If both `-Cloud` and `-AzureCloudInstance` are supplied, the values must describe the same cloud.

```yaml
Type: Integer
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Cloud-dependent
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientCertificate
Specifies a certificate that has been configured in the Azure AD application for authentication.

```yaml
Type: X509Certificate2
Parameter Sets: ClientCertificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientId
Specifies a string that contains the client ID of the Azure AD application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientSecret
Specifies a secure string that contains the client secret that has been configured in the Azure AD application for authentication.

```yaml
Type: SecureString
Parameter Sets: ClientSecret
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Cloud
Specifies the Microsoft cloud environment. Valid values are `Global`, `GCC`, `GCCHigh`, `DoD`, and `China`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Global
Accept pipeline input: False
Accept wildcard characters: False
```

### -GraphEndpoint
Overrides the Microsoft Graph root endpoint. This is intended for advanced scenarios; most callers should use `-Cloud`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Cloud-dependent
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantId
Specifies a string that contains the tenant ID of the Azure/365 environment of the Azure AD application.

```yaml
Type: String
Parameter Sets: (All)
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
