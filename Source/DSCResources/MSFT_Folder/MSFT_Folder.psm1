$script:ModuleBasePath = Split-Path -Parent -Path (Split-Path -Parent $PSScriptRoot)
$ModuleName = Split-path -Leaf $script:ModuleBasePath

if ($ModuleName -as [version] -or ($ModuleName -in @('source', 'src')))
{
    $ModuleName = Split-Path -Leaf (Split-path -Parent $script:ModuleBasePath)
}

$script:MasterModule = Import-Module -Name (Join-Path $ModuleBasePath "$ModuleName.psd1") -PassThru -force
# Calling the MasterModule's private function Get-LocalizedData to load data based on current UI culture
$script:localizedData = &$script:MasterModule { Get-LocalizedData }

<#
    .SYNOPSIS
        Returns the current state of the folder.

    .PARAMETER Path
        The path to the folder to retrieve.
        Not the best example as it could be Absolute or relative

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

    .NOTES
        The ReadOnly parameter was made mandatory in this example to show
        how to handle unused mandatory parameters.
        In a real scenario this parameter would not need to have the type
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

    $getFolderParams = @{}
    foreach ($key in (Get-Command Get-Folder).Parameters.keys)
    {
        # Add the parameter to Get-Folder called only if it's a valid parameter
        if ($PSBoundParameters.containsKey($key))
        {
            $getFolderParams.add($key, $PSBoundParameters[$key])
        }
    }

    try
    {
        # Ensuring we're returning a terminating error from Get-Folder
        $getFolderParams['ErrorAction'] = 'Stop'
        $targetFolder = Get-Folder @getFolderParams
    }
    catch
    {
        # Catching the error message and showing as Verbose in DSC
        Write-verbose $_.Exception.Message
    }


    if ($targetFolder)
    {
        $ensure = 'Present'
    }
    else
    {
        $ensure = 'Absent'
    }

    # ensure all keys are present, even if their value -eq $null
    return @{
        Ensure    = $ensure
        Path      = $Path
        ReadOnly  = $targetFolder.ReadOnly
        Hidden    = $targetFolder.Hidden
        Shared    = $targetFolder.Shared
        ShareName = $targetFolder.ShareName
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
        If the folder attribute should be hidden. Default value is $false.

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

    # Removing the Ensure parameter from PSBoundParameters so we can use the hashtable with Set-Folder
    $null = $PSBoundParameters.remove('Ensure')

    if ($Ensure -eq 'Present')
    {
        # Create and configure the folder
        $null = Set-Folder @PSBoundParameters
    }
    else
    {
        <#
        # Example to lazily pass relevant parameters to calling function
        $getFolderCmd = Get-Command -Name Get-Folder
        # Copy the Bound Parameters
        $getFoldersParameters = @{}

        # Add Get-folder's parameter if `"$($key)" is defined in current scope (careful when using ParameterSets)
        foreach ($key in $getFolderCmd.Parameters.Keys)
        {
            if ($value = Get-variable -Name $key -ValueOnly -Scope 0 -ErrorAction SilentlyContinue)
            {
                $null = $getFoldersParameters.Add($key, $value)
            }
        }

        $getFoldersParameters['ErrorAction'] = 'SilentlyContinue'
        $TargetFolder = Get-Folder @getFoldersParameters
        #>

        $TargetFolder = Get-Folder -Path $Path -ErrorAction SilentlyContinue

        if ($TargetFolder)
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
