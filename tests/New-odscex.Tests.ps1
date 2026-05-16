BeforeAll {
    . "$PSScriptRoot/../src/public/New-odscex.ps1"
}

Describe 'New-odscex' {
    It 'passes DocumentLibraryId through to Set-odscexShortcutState' {
        $script:SetParameters = $null

        function Set-odscexShortcutState {
            param(
                [string] $Uri,
                [string] $DocumentLibrary,
                [string] $DocumentLibraryId,
                [string] $FolderPath,
                [string] $RelativePath,
                [string] $ShortcutName,
                [string] $State,
                [string] $ConflictAction,
                [switch] $AllowAmbiguousLibraryMatch,
                [string] $UserPrincipalName,
                [string] $UserObjectId,
                [switch] $Confirm
            )

            $script:SetParameters = $PSBoundParameters
        }

        New-odscex -Uri 'https://contoso.sharepoint.com/sites/site' -DocumentLibraryId 'library-id' -UserPrincipalName 'user@contoso.com' -Confirm:$false

        $script:SetParameters.DocumentLibraryId | Should -Be 'library-id'
        $script:SetParameters.ContainsKey('DocumentLibrary') | Should -BeFalse
    }

    It 'requires either DocumentLibrary or DocumentLibraryId' {
        { New-odscex -Uri 'https://contoso.sharepoint.com/sites/site' -UserPrincipalName 'user@contoso.com' -Confirm:$false -ErrorAction Stop } |
            Should -Throw 'Specify -DocumentLibrary or -DocumentLibraryId.'
    }
}
