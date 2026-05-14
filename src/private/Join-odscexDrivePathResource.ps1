function Join-odscexDrivePathResource {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $User,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $RelativePath,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Name
    )

    $EncodedPath = ConvertTo-odscexGraphDrivePath -Path $RelativePath
    $EncodedName = if ([string]::IsNullOrWhiteSpace($Name)) { '' } else { [uri]::EscapeDataString($Name) }
    $PathParts = @($EncodedPath, $EncodedName) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    if ($PathParts.Count -eq 0) {
        return "users/${User}/drive/root"
    }

    return "users/${User}/drive/root:/$($PathParts -join '/')"
}
