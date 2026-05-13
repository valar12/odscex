function Resolve-odscUserIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('UserPrincipalName', 'Mail')]
        [string] $InputUserPrincipalName,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('UserObjectId', 'UserId', 'Id')]
        [string] $InputUserObjectId
    )

    if ($InputUserObjectId) {
        return $InputUserObjectId
    }

    if ($InputUserPrincipalName) {
        return $InputUserPrincipalName
    }

    Write-Error 'A user principal name or object ID is required.' -ErrorAction Stop
}
