function Invoke-odscApply {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [string] $ReportPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Csv', 'Json', 'Clixml')]
        [string] $OutputFormat = 'Csv'
    )

    $Plans = Invoke-odscPlan -Path $Path
    $Results = New-Object System.Collections.Generic.List[object]

    foreach ($Plan in $Plans) {
        if (-not $PSCmdlet.ShouldProcess("plan '$($Plan.Name)'", "Apply shortcut state '$($Plan.State)'")) {
            continue
        }

        $Target = $Plan.Target
        if ($Target.groupId) {
            $Users = @(Get-odscTargetUser -GroupId $Target.groupId)
        } elseif ($Target.csvPath) {
            $Users = @(Get-odscTargetUser -CsvPath $Target.csvPath)
        } elseif ($Target.filter) {
            $Users = @(Get-odscTargetUser -Filter $Target.filter)
        } elseif ($Target.allUsers) {
            $Users = @(Get-odscTargetUser -AllUsers)
        } else {
            Write-Error "Plan '$($Plan.Name)' does not define a supported target." -ErrorAction Stop
        }

        $Assignment = Invoke-odscShortcutAssignment -User $Users -Uri $Plan.Uri -DocumentLibrary $Plan.DocumentLibrary -DocumentLibraryId $Plan.DocumentLibraryId -FolderPath $Plan.FolderPath -RelativePath $Plan.RelativePath -ShortcutName $Plan.Name -State $Plan.State -Confirm:$false
        foreach ($Result in $Assignment) {
            $Results.Add($Result) | Out-Null
            $Result
        }
    }

    if ($ReportPath) {
        Export-odscReport -InputObject $Results.ToArray() -Path $ReportPath -Format $OutputFormat
    }
}
