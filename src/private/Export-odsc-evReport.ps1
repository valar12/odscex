function Export-odsc-evReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]] $InputObject,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Csv', 'Json', 'Clixml')]
        [string] $Format = 'Csv'
    )

    switch ($Format) {
        'Csv' { $InputObject | Export-Csv -Path $Path -NoTypeInformation }
        'Json' { $InputObject | ConvertTo-Json -Depth 20 | Set-Content -Path $Path -Encoding UTF8 }
        'Clixml' { $InputObject | Export-Clixml -Path $Path }
    }
}
