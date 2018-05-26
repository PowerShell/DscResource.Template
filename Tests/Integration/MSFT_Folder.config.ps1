<#
    .SYNOPSIS
        Integration test for MSFT_Folder.

    .NOTES
        This integration test has two test.

        Test 1: Create a folder.
        Test 2: Remove a folder.
s
#>
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            Path     = 'C:\DscTemp'
            ReadOnly = $false
        }
    )
}

Configuration MSFT_Folder_Create_Config
{
    Import-DscResource -ModuleName 'DscResource.Template'

    node localhost
    {
        Folder 'Integration_Test'
        {

            Path     = $Node.Path
            ReadOnly = $Node.ReadOnly
        }
    }
}

Configuration MSFT_Folder_Remove_Config
{
    Import-DscResource -ModuleName 'DscResource.Template'

    node localhost
    {
        Folder 'Integration_Test'
        {
            Ensure   = 'Absent'
            Path     = $Node.Path
            ReadOnly = $Node.ReadOnly
        }
    }
}
