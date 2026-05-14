---
external help file: odsc-ev-help.xml
Module Name: odsc-ev
online version: https://github.com/innovara/odsc-ev/blob/main/docs/Invoke-odsc-evGraphBatch.md
schema: 2.0.0
---

# Invoke-odsc-evGraphBatch

## SYNOPSIS
Submits up to 20 Microsoft Graph requests in a single JSON batch.

## DESCRIPTION
The **Invoke-odsc-evGraphBatch** command accepts request objects with `method`, `url`, optional `body`, and optional `headers` properties, then submits them to Microsoft Graph's `$batch` endpoint. It is intended for advanced automation and read-heavy orchestration scenarios.

## EXAMPLES

### Example 1

```powershell
Invoke-odsc-evGraphBatch -Requests @(
    @{ id = '1'; method = 'GET'; url = '/users/user@contoso.com/drive' }
)
```
