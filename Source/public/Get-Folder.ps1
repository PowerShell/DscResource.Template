<#
.SYNOPSIS
Retrieve a Folder and its properties

.DESCRIPTION
Get the Folder and whether it is Hidden, ReadOnly and shared.
If the Folder is shared, it also returns its Share Name.

.PARAMETER Path
Path of the folder to get

.EXAMPLE
Get-Folder -Path C:\

.NOTES
It will throw an exception if the path does not point to a folder.

#>
function Get-Folder
{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Path
    )

    # Using -Force to find hidden folders.
    $folder = Get-Item -Path $Path -Force -ErrorAction 'SilentlyContinue' |
        Where-Object -FilterScript {
        $_.PSIsContainer -eq $true
    }

    if ($folder)
    {
        Write-Verbose -Message $script:localizedData.FolderFound

        $isReadOnly = Test-FileAttribute -Folder $folder -Attribute 'ReadOnly'
        $isHidden = Test-FileAttribute -Folder $folder -Attribute 'Hidden'

        # Find if this Folder is Shared
        $folderShare = Get-SmbShare |
            Where-Object -FilterScript {
            $_.Path -eq $Path
        }

        # Cast the object to Boolean.
        $isShared = [System.Boolean] $folderShare
        if ($isShared)
        {
            $shareName = $folderShare.Name
        }

        # Return the Folder object
        [PSCustomObject]@{
            PSTypeName = 'DscResource.Template.Folder'
            Path       = $Path
            ReadOnly   = $isReadOnly
            Hidden     = $isHidden
            Shared     = $isShared
            ShareName  = $shareName
        }
    }
    else
    {
        Throw ($script:localizedData.FolderNotFound -f $Path)
    }
}
