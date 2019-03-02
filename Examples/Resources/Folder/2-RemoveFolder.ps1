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
