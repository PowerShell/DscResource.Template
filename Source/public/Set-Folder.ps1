<#
.SYNOPSIS
Creates a folder and Sets its Hidden and ReadOnly attributes.

.DESCRIPTION
Upon running this command, if the folder specified by its Path does not exist
it will be created, and the Attributes Hidden and ReadOnly will be set.

.PARAMETER Path
Path of the Folder to configure and/or create.

.PARAMETER ReadOnly
Set the ReadOnly attribute on the Folder

.PARAMETER Hidden
Set the Hidden attribute on the Folder

.EXAMPLE
Set-Folder -Path C:\Test -ReadOnly
# Creates a Test folder at the root of C: and sets the ReadOnly attribute.

#>
function Set-Folder
{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Path,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]
        $ReadOnly,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]
        $Hidden
    )

    if ( -not ($folder = Get-Item -Force $Path -ErrorAction SilentlyContinue) )
    {
        Write-Verbose -Message (
            $script:localizedData.CreateFolder `
                -f $Path
        )

        # TODO: implement Should Process
        # Create the folder as it doesn't exist yet
        $folder = New-Item -Path $Path -ItemType 'Directory' -Force
    }

    Write-Verbose -Message (
        $script:localizedData.SettingProperties `
            -f $Path
    )

    # Set the Folder's ReadOnly and Hidden attribute from the parameters
    Set-FileAttribute -Folder $folder -Attribute 'ReadOnly' -Enabled $ReadOnly
    Set-FileAttribute -Folder $folder -Attribute 'Hidden' -Enabled $Hidden

    return $folder
}
