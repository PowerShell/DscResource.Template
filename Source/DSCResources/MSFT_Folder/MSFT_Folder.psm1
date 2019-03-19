$script:ModuleBasePath = Split-Path -Parent -Path (Split-Path -Parent $PSScriptRoot)
$ModuleName = Split-path -Leaf $script:ModuleBasePath

if ($ModuleName -as [version] -or ($ModuleName -in @('source', 'src')))
{
    $ModuleName = Split-Path -Leaf (Split-path -Parent $script:ModuleBasePath)
}

$script:MasterModule = Import-Module -Name (Join-Path $ModuleBasePath "$ModuleName.psd1") -PassThru -force
# Calling the MasterModule's private function Get-LocalizedData to load data based on current UI culture
$script:localizedData = &$script:MasterModule { Get-LocalizedData -verbose }

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

    Write-Verbose -Message (
        $script:localizedData.RetrieveFolder `
            -f $Path
    )

    # Technically, the Ensure = 'Present' should probably be brought back here (not in the Get-Folder)
    return (Get-Folder @PSBoundParameters)
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
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $getFolderCmd = Get-Command Get-Folder
    # Copy the Bound Paramters to an Hashtable
    $getFoldersParameters = @{} + $PSBoundParameters

    # Remove the DSC Set-TargetResource Params that do not exist in the Get-folder
    foreach ($key in $PSBoundParameters.Keys)
    {
        if ($key -notin $getFolderCmd.Parameters.Keys)
        {
            $null = $getFoldersParameters.Remove($key)
        }
    }


    $getTargetResourceResult = Get-Folder $getFoldersParameters

    if ($Ensure -eq 'Present')
    {
        if ($getTargetResourceResult.Ensure -eq 'Absent')
        {
            Write-Verbose -Message (
                $script:localizedData.CreateFolder `
                    -f $Path
            )

            $folder = New-Item -Path $Path -ItemType 'Directory' -Force
        }
        else
        {
            $folder = Get-Item -Path $Path -Force
        }

        Write-Verbose -Message (
            $script:localizedData.SettingProperties `
                -f $Path
        )

        Set-FileAttribute -Folder $folder -Attribute 'ReadOnly' -Enabled $ReadOnly
        Set-FileAttribute -Folder $folder -Attribute 'Hidden' -Enabled $Hidden
    }
    else
    {
        if ($getTargetResourceResult.Ensure -eq 'Present')
        {
            Write-Verbose -Message (
                $script:localizedData.RemoveFolder `
                    -f $Path
            )

            Remove-Item -Path $Path -Force -ErrorAction Stop
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
