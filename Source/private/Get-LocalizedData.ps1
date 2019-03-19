<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture, and calling module.
        Falls back to en-US strings if the current culture does not have available translation.

    .NOTES
        This function will load the Localized Data from the Culture folder at the base of the module
        and will search the file to load based on the name of the PSM1 file calling it, so that
        each DscResource odule can load its specific Language file, along with one for the parent module.
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Globalization.CultureInfo]
        # Specify the Culture to load the Localized Data. Defaults to current UICulture and falls back to en-US
        $UICulture = (Get-UICulture),

        [Parameter()]
        [System.String]
        # Specify the path to lookup for language data file, by appending the culture name to its path.
        # Defaults to the module's base, or to the $PSScriptRoot's parent (when developping functions)
        $BaseDirectory = $PSCmdlet.SessionState.Module.ModuleBase,

        [Parameter()]
        [System.String]
        # FileName of the Localized Strings to load. Defaults to ModuleName.strings.psd1 where
        # the Module Name is either the Module or DSC Resource calling Get-LocalizedData
        $FileName
    )

    if (-Not $BaseDirectory)
    {
        # If it's not in a module, look in the Parent folder. Useful for Development.
        $BaseDirectory = Split-Path -Parent -Path $PSScriptRoot
    }



    if (-Not $FileName)
    {
        $CallingScript = Get-Item $MyInvocation.PSCommandPath -ErrorAction SilentlyContinue

        # Find if calling from .psm1 file, in which case find matching BaseName +.strings.psd1 (could be module or DSC Resource)
        if ($CallingScript.Extension -eq '.psm1')
        {
            $FileName = $CallingScript.BaseName + '.strings.psd1'
        }
        elseif ($PSCmdlet.SessionState.Module.Name)
        {
            # The invocation comes from a ps1, but within a module (dot sourcing?). Use the Module's Name to load the strings
            $FileName = '{0}.strings.psd1' -f $PSCmdlet.SessionState.Module
        }
        else
        {
            # For Development purposes
            if (($ModuleName = Split-Path -leaf $BaseDirectory) -and $ModuleName -in @('Source', 'src'))
            {
                $ModuleName = Split-Path -Leaf (Split-Path -Parent $BaseDirectory)
            }
            # The invocation comes from outside a module, and either from a ps1 or the CLI. Use a Common.strings.psd1
            $FileName = '{0}.strings.psd1' -f $ModuleName
        }
    }

    $ImportLocalizedDataParams = @{
        UICulture     = $UICulture
        BaseDirectory = $BaseDirectory
        FileName      = $FileName
    }

    Write-Verbose "Looking to load $FileName from $BaseDirectory for $UICulture"
    try
    {
        # Try localized Data for current UICulture
        $localizedData = Import-LocalizedData @ImportLocalizedDataParams
    }
    catch
    {
        # Default to en-US UI Culture
        $ImportLocalizedDataParams['UICulture'] = 'en-US'
        $localizedData = Import-LocalizedData @ImportLocalizedDataParams
    }

    return $localizedData
}
