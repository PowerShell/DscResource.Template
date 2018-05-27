$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $script:modulesFolderPath -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_Folder'

<#
    .SYNOPSIS
        Returns the current state of the folder.

    .PARAMETER Path
        The path to the folder to retrieve.

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

    .NOTES
        The ReadOnly parameter was made mandatory in this example to show
        how to handle unused mandatory parameters.
        In a real scenarion this parameter would not need to have the type
        qualifier Required in the schema.mof.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $ReadOnly
    )

    $getTargetResourceResult = @{
        Ensure        = 'Absent'
        Path          = $Path
        ReadOnly      = $false
        Hidden        = $false
        EnableSharing = $false
        ShareName     = $null
    }

    Write-Verbose -Message (
        $script:localizedData.RetrieveFolder `
            -f $Path
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

        $folderShare = Get-SmbShare |
            Where-Object -FilterScript {
            $_.Path -eq 'C:\Temp'
        }

        # Cast the object to Boolean.
        $isShared = [System.Boolean] $folderShare
        if ($isShared)
        {
            $shareName = $folderShare.Name
        }

        $getTargetResourceResult['Ensure'] = 'Present'
        $getTargetResourceResult['ReadOnly'] = $isReadOnly
        $getTargetResourceResult['Hidden'] = $isHidden
        $getTargetResourceResult['EnableSharing'] = $isShared
        $getTargetResourceResult['ShareName'] = $shareName
    }
    else
    {
        Write-Verbose -Message $script:localizedData.FolderNotFound
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Creates or removes the folder.

    .PARAMETER Path
        The path to the folder to retrieve.

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

    .PARAMETER Hidden
        If the folder attribut should be hidden. Default value is $false.

    .PARAMETER EnableSharing
        If sharing should be enabled on the folder. Default value is $false

    .PARAMETER Ensure
        Specifies the desired state of the folder. When set to 'Present', the folder will be created. When set to 'Absent', the folder will be removed. Default value is 'Present'.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $ReadOnly,

        [Parameter()]
        [System.Boolean]
        $Hidden,

        [Parameter()]
        [System.Boolean]
        $EnableSharing,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $getTargetResourceParameters = @{
        Path     = $Path
        ReadOnly = $ReadOnly
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    if ($Ensure -eq 'Present')
    {
        if ($getTargetResourceResult -eq 'Absent')
        {
            Write-Verbose -Message (
                $script:localizedData.CreateFolder `
                    -f $Path
            )
        }
        else
        {
            Write-Verbose -Message $script:localizedData.SettingProperties
        }
    }
    else
    {
        if ($getTargetResourceResult -eq 'Present')
        {
            Write-Verbose -Message (
                $script:localizedData.RemoveFolder `
                    -f $Path
            )
        }
    }
}

<#
    .SYNOPSIS
        Creates or removes the folder.

    .PARAMETER Path
        The path to the folder to retrieve.

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

    .PARAMETER Hidden
        If the folder attribut should be hidden. Default value is $false.

    .PARAMETER EnableSharing
        If sharing should be enabled on the folder. Default value is $false

    .PARAMETER Ensure
        Specifies the desired state of the folder. When set to 'Present', the folder will be created. When set to 'Absent', the folder will be removed. Default value is 'Present'.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $ReadOnly,

        [Parameter()]
        [System.Boolean]
        $Hidden,

        [Parameter()]
        [System.Boolean]
        $EnableSharing,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $getTargetResourceParameters = @{
        Path     = $Path
        ReadOnly = $ReadOnly
    }

    $testTargetResourceResult = $false

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message $script:localizedData.EvaluateProperties

        $valuesToCheck = @(
            'Ensure'
            'ReadOnly'
            'Hidden'
            'EnableSharing'
        )

        $testTargetResourceResult = Test-DscParameterState `
            -CurrentValues $getTargetResourceResult `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck $valuesToCheck
    }
    else
    {
        if ($Ensure -eq $getTargetResourceResult.Ensure)
        {
            $testTargetResourceResult = $true
        }
    }

    return $testTargetResourceResult
}

<#
    .SYNOPSIS
        Test if an attribute on a folder is present.

    .PARAMETER Folder
        The folder that should be checked for the attribute.

    .PARAMETER Attribute
       The attribute to check for on the folder.
#>
function Test-FileAttribute
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]
        $Folder,

        [Parameter(Mandatory = $true)]
        [System.IO.FileAttributes]
        $Attribute
    )

    $attributeValue = $Folder.Attributes -band [System.IO.FileAttributes]::$Attribute

    switch ($attributeValue)
    {
        { $_ -gt 0 }
        {
            $isPresent = $true
        }

        default
        {
            $isPresent = $false
        }
    }

    return $isPresent
}
