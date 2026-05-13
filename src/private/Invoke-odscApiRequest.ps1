function Invoke-odscApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Resource,

        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method,

        [Parameter(Mandatory = $false)]
        [string] $Body,

        [Parameter(Mandatory = $false)]
        [switch] $DoNotUsePrefer,

        [Parameter(Mandatory = $false)]
        [switch] $AllPages,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int] $MaxRetryCount = 5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 300)]
        [int] $RetryDelaySeconds = 2
    )

    begin {
        $Token = $script:ODSToken

        if ((!$Token.ExpiresOn) -or
            (!$Token.AccessToken) -or
            ($Token.ExpiresOn -le (Get-Date))) {
            Write-Verbose 'No usable Microsoft Graph token is available.'
            Write-Error 'Please run Connect-odsc first.' -ErrorAction Stop
        }
    }

    process {
        $Headers = @{
            Authorization = "Bearer $($Token.AccessToken)"
        }

        if (!($DoNotUsePrefer.IsPresent)) {
            $Headers.Prefer = 'apiversion=2.1'
        }

        $GraphEndpoint = if ($script:ODSGraphEndpoint) { $script:ODSGraphEndpoint.TrimEnd('/') } else { 'https://graph.microsoft.com' }
        $Uri = if ($Resource -match '^https://') { $Resource } else { "$GraphEndpoint/v1.0/$($Resource)" }
        $Results = New-Object System.Collections.Generic.List[object]
        $NextUri = $Uri

        do {
            $Attempt = 0
            $Response = $null
            $Succeeded = $false

            while (-not $Succeeded) {
                $Request = @{
                    Uri = $NextUri
                    ContentType = 'application/json'
                    Headers = $Headers
                    Method = $Method
                    UseBasicParsing = $true
                }

                if ($Body -and $NextUri -eq $Uri) {
                    $Request.Body = $Body
                }

                try {
                    $RawResponse = Invoke-WebRequest @Request
                    $Response = if ([string]::IsNullOrWhiteSpace($RawResponse.Content)) {
                        $null
                    } else {
                        ConvertFrom-Json -InputObject $RawResponse.Content
                    }
                    $Succeeded = $true
                } catch {
                    $Attempt++
                    $StatusCode = $null
                    $RetryAfter = $null
                    $GraphRequestId = $null

                    if ($_.Exception.Response) {
                        $StatusCode = [int]$_.Exception.Response.StatusCode
                        try { $RetryAfter = $_.Exception.Response.Headers['Retry-After'] } catch { $RetryAfter = $null }
                        try { $GraphRequestId = $_.Exception.Response.Headers['request-id'] } catch { $GraphRequestId = $null }
                        if (-not $RetryAfter) { try { $RetryAfter = $_.Exception.Response.GetResponseHeader('Retry-After') } catch { $RetryAfter = $null } }
                        if (-not $GraphRequestId) { try { $GraphRequestId = $_.Exception.Response.GetResponseHeader('request-id') } catch { $GraphRequestId = $null } }
                    }

                    $IsTransient = $StatusCode -in @(429, 500, 502, 503, 504)
                    if (($Attempt -le $MaxRetryCount) -and $IsTransient) {
                        $Delay = if ($RetryAfter) { [int]$RetryAfter } else { [Math]::Min(300, ($RetryDelaySeconds * [Math]::Pow(2, ($Attempt - 1)))) }
                        Write-Verbose "Microsoft Graph request was throttled or transiently failed with HTTP $StatusCode. Retrying in $Delay seconds. RequestId: $GraphRequestId"
                        Start-Sleep -Seconds $Delay
                    } else {
                        $Message = "Microsoft Graph request failed. Method: $Method. Resource: $Resource. StatusCode: $StatusCode. RequestId: $GraphRequestId. Error: $($_.Exception.Message)"
                        Write-Error $Message -ErrorAction Stop
                    }
                }
            }

            if ($AllPages -and $Response -and ($null -ne $Response.value)) {
                foreach ($Item in $Response.value) {
                    $Results.Add($Item) | Out-Null
                }
                $NextUri = $Response.'@odata.nextLink'
                $Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get
                $Body = $null
            } else {
                return $Response
            }
        } while ($AllPages -and $NextUri)

        return $Results.ToArray()
    }
}
