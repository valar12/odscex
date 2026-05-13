function Invoke-odscGraphBatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateCount(1, 20)]
        [object[]] $Requests
    )

    $BatchRequests = for ($Index = 0; $Index -lt $Requests.Count; $Index++) {
        $Request = $Requests[$Index]
        [pscustomobject]@{
            id = if ($Request.id) { [string]$Request.id } else { [string]($Index + 1) }
            method = if ($Request.method) { [string]$Request.method } else { 'GET' }
            url = if ($Request.url -match '^/') { $Request.url } else { "/$($Request.url)" }
            body = $Request.body
            headers = $Request.headers
        }
    }

    $Body = @{ requests = $BatchRequests } | ConvertTo-Json -Depth 20
    Invoke-odscApiRequest -Resource '$batch' -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Post) -Body $Body -DoNotUsePrefer
}
