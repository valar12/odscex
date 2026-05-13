---
external help file: odsc-help.xml
Module Name: odsc
online version: https://github.com/innovara/odsc/blob/main/docs/Invoke-odscGraphBatch.md
schema: 2.0.0
---

# Invoke-odscGraphBatch

## SYNOPSIS
Submits up to 20 Microsoft Graph requests in a single JSON batch.

## DESCRIPTION
The **Invoke-odscGraphBatch** command accepts request objects with `method`, `url`, optional `body`, and optional `headers` properties, then submits them to Microsoft Graph's `$batch` endpoint. It is intended for advanced automation and read-heavy orchestration scenarios.

## EXAMPLES

### Example 1

```powershell
Invoke-odscGraphBatch -Requests @(
    @{ id = '1'; method = 'GET'; url = '/users/user@contoso.com/drive' }
)
```
