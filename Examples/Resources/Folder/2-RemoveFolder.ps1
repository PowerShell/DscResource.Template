<#
    .EXAMPLE
        This example will remove two folders. First resource will remove the
        first folder using the account passad in the parameter InstallCredential,
        and the second resource will run as SYSTEM to remove the second folder.

#>
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            Path1                       = 'C:\DscTemp1'
            Path2                       = 'C:\DscTemp2'
            ReadOnly                    = $false

            <#
                NOTE! THIS IS NOT RECOMMENDED IN PRODUCTION.
                This is added so that AppVeyor automatic tests can pass, otherwise
                the tests will fail on passwords being in plain text and not being
                encrypted. Because it is not possible to have a certificate in
                AppVeyor to encrypt the passwords we need to add the parameter
                'PSDscAllowPlainTextPassword'.
                NOTE! THIS IS NOT RECOMMENDED IN PRODUCTION.
            #>
            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $InstallCredential
    )

    Import-DscResource -ModuleName 'DscResource.Template'

    node localhost
    {
        Folder 'CreateDscTemp1'
        {
            Ensure               = 'Absent'
            Path                 = $Node.Path1
            ReadOnly             = $Node.ReadOnly

            PsDscRunAsCredential = $InstallCredential
        }

        Folder 'CreateDscTemp2'
        {
            Ensure   = 'Absent'
            Path     = $Node.Path2
            ReadOnly = $Node.ReadOnly
        }
    }
}
