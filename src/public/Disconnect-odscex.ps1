function Disconnect-odscex {
    [CmdletBinding()]
    param()

    process {
        $script:ODSCEXToken = $null
        $script:ODSCEXCloudEnvironment = 'Global'
        $script:ODSCEXGraphEndpoint = 'https://graph.microsoft.com'
    }

    end {
        Write-Information 'Disconnected.' -InformationAction Continue
    }
}
