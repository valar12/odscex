function Disconnect-odsc-ev {
    [CmdletBinding()]
    param()

    process {
        $script:ODSToken = $null
        $script:ODSCloudEnvironment = 'Global'
        $script:ODSGraphEndpoint = 'https://graph.microsoft.com'
    }

    end {
        Write-Information 'Disconnected.' -InformationAction Continue
    }
}
