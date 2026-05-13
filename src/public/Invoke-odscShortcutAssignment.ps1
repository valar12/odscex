function Invoke-odscShortcutAssignment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]] $User,

        [Parameter(Mandatory = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $false)]
        [string] $DocumentLibrary,

        [Parameter(Mandatory = $false)]
        [string] $DocumentLibraryId,

        [Parameter(Mandatory = $false)]
        [string] $FolderPath,

        [Parameter(Mandatory = $false)]
        [string] $RelativePath,

        [Parameter(Mandatory = $false)]
        [string] $ShortcutName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [string] $State = 'Present',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Skip', 'Replace', 'Rename', 'Error')]
        [string] $ConflictAction = 'Skip',

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 64)]
        [int] $ThrottleLimit = 4,

        [Parameter(Mandatory = $false)]
        [int] $ResumeFrom = 0,

        [Parameter(Mandatory = $false)]
        [string] $ReportPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Csv', 'Json', 'Clixml')]
        [string] $OutputFormat = 'Csv'
    )

    begin {
        $Results = New-Object System.Collections.Generic.List[object]
        if ($ThrottleLimit -gt 1) {
            Write-Verbose 'ThrottleLimit is accepted for orchestration compatibility; this implementation processes users sequentially to honor Microsoft Graph throttling and retry guidance.'
        }
    }

    process {
        for ($Index = $ResumeFrom; $Index -lt $User.Count; $Index++) {
            $TargetUser = $User[$Index]
            $UserPrincipalName = $TargetUser.UserPrincipalName
            $UserObjectId = if ($TargetUser.UserObjectId) { $TargetUser.UserObjectId } else { $TargetUser.Id }

            try {
                $Parameters = @{
                    Uri = $Uri
                    FolderPath = $FolderPath
                    RelativePath = $RelativePath
                    ShortcutName = $ShortcutName
                    State = $State
                    ConflictAction = $ConflictAction
                    WhatIf = $WhatIfPreference
                }

                if ($DocumentLibraryId) { $Parameters.DocumentLibraryId = $DocumentLibraryId } else { $Parameters.DocumentLibrary = $DocumentLibrary }
                if ($UserObjectId) {
                    $Parameters.UserObjectId = $UserObjectId
                    $UserIdentifier = $UserObjectId
                } else {
                    $Parameters.UserPrincipalName = $UserPrincipalName
                    $UserIdentifier = $UserPrincipalName
                }
                $Parameters.Confirm = $false

                if ($PSCmdlet.ShouldProcess("${UserIdentifier}'s OneDrive", "Set shortcut '$ShortcutName' to state '$State'")) {
                    $Result = Set-odscShortcutState @Parameters
                    $Results.Add($Result) | Out-Null
                    $Result
                }
            } catch {
                $Failure = [pscustomobject]@{
                    PSTypeName = 'odsc.ShortcutResult'
                    User = if ($UserObjectId) { $UserObjectId } else { $UserPrincipalName }
                    ShortcutName = $ShortcutName
                    Action = $State
                    Status = 'Failed'
                    TargetSite = $Uri
                    TargetLibrary = $DocumentLibrary
                    TargetFolderPath = $FolderPath
                    DriveItemId = $null
                    WebUrl = $null
                    Message = $_.Exception.Message
                    Response = $null
                    Timestamp = (Get-Date).ToUniversalTime()
                }
                $Results.Add($Failure) | Out-Null
                $Failure
            }
        }
    }

    end {
        if ($ReportPath) {
            Export-odscReport -InputObject $Results.ToArray() -Path $ReportPath -Format $OutputFormat
        }
    }
}
