---
external help file: odscex-help.xml
Module Name: odscex
online version: https://github.com/innovara/odscex/blob/main/docs/Invoke-odscexGraphBatch.md
schema: 2.0.0
---

# Invoke-odscexGraphBatch

## SYNOPSIS
Submits up to 20 Microsoft Graph requests in a single JSON batch.

## DESCRIPTION
The **Invoke-odscexGraphBatch** command accepts request objects with `method`, `url`, optional `body`, and optional `headers` properties, then submits them to Microsoft Graph's `$batch` endpoint. It is intended for advanced automation and read-heavy orchestration scenarios.

## EXAMPLES

### Example 1

```powershell
Invoke-odscexGraphBatch -Requests @(
    @{ id = '1'; method = 'GET'; url = '/users/user@contoso.com/drive' }
)
```
