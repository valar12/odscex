function New-odsc {
    [CmdletBinding(DefaultParameterSetName = 'UserPrincipalName', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UserObjectId')]
        [string] $Uri,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UserObjectId')]
        [string] $DocumentLibrary,

        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $FolderPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $RelativePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $ShortcutName,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserPrincipalName', ValueFromPipelineByPropertyName = $true)]
        [Alias('Mail')]
        [string] $UserPrincipalName,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserObjectId', ValueFromPipelineByPropertyName = $true)]
        [Alias('Id', 'UserId')]
        [string] $UserObjectId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Skip', 'Replace', 'Rename', 'Error')]
        [string] $ConflictAction = 'Rename',

        [Parameter(Mandatory = $false)]
        [switch] $AllowAmbiguousLibraryMatch
    )

    process {
        $Parameters = @{
            Uri = $Uri
            DocumentLibrary = $DocumentLibrary
            FolderPath = $FolderPath
            RelativePath = $RelativePath
            ShortcutName = $ShortcutName
            State = 'Present'
            ConflictAction = $ConflictAction
            AllowAmbiguousLibraryMatch = $AllowAmbiguousLibraryMatch
        }

        if ($WhatIfPreference) {
            $Parameters.WhatIf = $true
        }

        if ($PsCmdlet.ParameterSetName -eq 'UserObjectId') {
            $Parameters.UserObjectId = $UserObjectId
        } else {
            $Parameters.UserPrincipalName = $UserPrincipalName
        }

        Set-odscShortcutState @Parameters
    }
}
