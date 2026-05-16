function Join-odscexDrivePathChildrenResource {
    [CmdletBinding(DefaultParameterSetName = 'ByUser')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByUser')]
        [string] $User,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByDrive')]
        [string] $DriveId,

        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $EncodedPath = ConvertTo-odscexGraphDrivePath -Path $RelativePath
    if ([string]::IsNullOrWhiteSpace($EncodedPath)) {
        if ($PSCmdlet.ParameterSetName -eq 'ByDrive') {
            return "drives/${DriveId}/root/children"
        }

        return "users/${User}/drive/root/children"
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByDrive') {
        return "drives/${DriveId}/root:/${EncodedPath}:/children"
    }

    return "users/${User}/drive/root:/${EncodedPath}:/children"
}
