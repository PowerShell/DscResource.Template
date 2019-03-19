function Get-Folder
{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [String]
        $Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Boolean]
        $ReadOnly

        # TODO: Decide on this form (overhead for each function), or the suffix model (current implementation)
        # ,[Parameter(DontShow)]
        # [hashtable]
        # $localizedData = $(
        #     if ($script:LocalizedData)
        #     {
        #         $script:LocalizedData = Get-LocalizedData
        #     }
        #     $script:LocalizedData
        # )
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
        @{
            Ensure    = 'Present'
            ReadOnly  = $isReadOnly
            Hidden    = $isHidden
            Shared    = $isShared
            ShareName = $shareName
        }
    }
    else
    {
        Write-Verbose -Message $script:localizedData.FolderNotFound
    }
}
