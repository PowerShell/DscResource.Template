# Contributing

Thank you for considering contributing to this resource module. Every little
change helps make the DSC resources even better for everyone to use.

## Common contribution guidelines

THis resource module follow all of the common contribution guidelines for
DSC resource modules [outlined in DscResources repository](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md),
so please review these as a baseline for contributing.

## Specific guidelines for this resource module

### Automatic formatting with VS Code

There is a VS Code workspace settings file within this project with formatting
settings matching the style guideline. That will make it possible inside VS Code
to press SHIFT+ALT+F, or press F1 and choose 'Format document' in the list. The
PowerShell code will then be formatted according to the Style Guideline
(although maybe not complete, but would help a long way).

### Naming convention

#### mof-based resource

All mof-based resource (with Get/Set/Test-TargetResource) should be prefixed
with 'MSFT'. I.e. MSFT\_Folder.

>**Note:** If the resource module is not part of the DSC Resource Kit the
>prefix can be any abbreviation, for example your name or company name.
>For the example below, the 'MSFT' prefix is used.

##### Folder and file structure

```Text
DSCResources/MSFT_Folder/MSFT_Folder.psm1
DSCResources/MSFT_Folder/MSFT_Folder.schema.mof
DSCResources/MSFT_Folder/en-US/MSFT_Folder.strings.psd1

Tests/Unit/MSFT_Folder.Tests.ps1

Examples/Resources/Folder/1-AddConfigurationOption.ps1
Examples/Resources/Folder/2-RemoveConfigurationOption.ps1
```

>**Note:** For the examples folder we don't use the 'MSFT\_' prefix on the
>resource folders. This is to make those folders resemble the name the user
>would use in the configuration file.

##### Schema mof file

Please note that the `FriendlyName` in the schema mof file should not contain the
prefix `MSFT\_`.

```powershell
[ClassVersion("1.0.0.0"), FriendlyName("Folder")]
class MSFT_Folder : OMI_BaseResource
{
    # Properties removed for readability.
};
```

#### Composite or class-based resource

Any composite (with a Configuration) or class-based resources should be prefixed
with just 'Sql'

### Helper functions

Helper functions or wrapper functions that are used by the resource can preferably
be placed in the resource module file. If the functions are of a type that could
be used by more than one resource, then the functions should be placed in the
shared [DscResource.Template.ResourceHelper.psm1](/Modules/DscResource.Template.ResourceHelper.psm1)
module file.

### Localization

In each resource folder there should be, at least, a localization folder for
english language 'en-US'.
In the 'en-US' (and any other language folder) there should be a file named
'MSFT_ResourceName.strings.psd1', i.e.
'MSFT_SqlSetup.strings.psd1'.
At the top of each resource the localized strings should be loaded, see the helper
function `Get-LocalizedData` for more information on how this is done.

The localized string file should contain the following (beside the localization
strings)

```powershell
# Localized resources for SqlSetup

ConvertFrom-StringData @'
    InstallingUsingPathMessage = Installing using path '{0}'.
'@
```

This is an example of how to write localized verbose messages.

```powershell
Write-Verbose -Message ($script:localizedData.InstallingUsingPathMessage -f $path)
```

This is an example of how to write localized warning messages.

```powershell
Write-Warning -Message `
    ($script:localizedData.InstallationReportedProblemMessage -f $path)
```

This is an example of how to throw localized error messages. The helper functions
`New-InvalidArgumentException` and `New-InvalidOperationException` (see below) should
preferably be used whenever possible.

```powershell
throw ($script:localizedData.InstallationFailedMessage -f $Path, $processId)
```

#### Helper functions for localization

There are also five helper functions to simplify localization.

##### New-InvalidArgumentException

```powershell
<#
    .SYNOPSIS
        Creates and throws an invalid argument exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
```

This can be used in code like this.

```powershell
if ( -not $resultOfEvaluation )
{
    $errorMessage = `
        $script:localizedData.ActionCannotBeUsedInThisContextMessage `
            -f $Action, $Parameter

    New-InvalidArgumentException -ArgumentName 'Action' -Message $errorMessage
}
```

##### New-InvalidOperationException

```powershell
<#
    .SYNOPSIS
        Creates and throws an invalid operation exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating
        error
#>
```

This can be used in code like this.

```powershell
try
{
    Start-Process @startProcessArguments
}
catch
{
    $errorMessage = $script:localizedData.InstallationFailedMessage -f $Path, $processId
    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
}

```

##### New-ObjectNotFoundException

```powershell
<#
    .SYNOPSIS
        Creates and throws an object not found exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating
        error
#>
```

This can be used in code like this.

```powershell
try
{
    Get-ChildItem -Path $path
}
catch
{
    $errorMessage = $script:localizedData.PathNotFoundMessage -f $path
    New-ObjectNotFoundException -Message $errorMessage -ErrorRecord $_
}

```

##### New-InvalidResultException

```powershell
<#
    .SYNOPSIS
        Creates and throws an invalid result exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating
        error
#>
```

This can be used in code like this.

```powershell
try
{
    $numberOfObjects = Get-ChildItem -Path $path
    if ($numberOfObjects -eq 0)
    {
        throw 'To few files.'
    }
}
catch
{
    $errorMessage = $script:localizedData.TooFewFilesMessage -f $path
    New-InvalidResultException -Message $errorMessage -ErrorRecord $_
}

```

##### Get-LocalizedData

```powershell
<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the
        localized string file.
#>
```

This should be used at the top of each resource like this.

```powershell
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlSetup'
```

### Unit tests

For a review of a Pull Request (PR) to start, all tests must pass without error.
If you need help to figure why some test don't pass, just write a comment in the
Pull Request (PR), or submit an issue, and somebody will come along and assist.

To run all tests manually run the following.

```powershell
Install-Module Pester
cd '<path to cloned repository>\Tests\Unit'
Invoke-Pester
```

#### Unit tests for style check of Markdown files

When sending in a Pull Request (PR) a style check will be performed on all Markdown
files, and if the tests find any error the build will fail.
See the section [Documentation with Markdown](#documentation-with-markdown) how
these errors can be found before sending in the PR.

The Markdown tests can be run locally if the packet manager 'npm' is available.
To have npm available you need to install [node.js](https://nodejs.org/en/download/).
If 'npm' is not available, a warning text will print and the rest of the tests
will continue run.

>**Note:* To run the common tests, at least one unit tests must have be run for
>the common test framework to have been cloned locally.

```powershell
cd '<path to cloned repository>'
Invoke-Pester .\DSCResource.Tests\Meta.Tests.ps1
```

#### Unit tests for examples files

When sending in a Pull Request (PR) all example files will be tested so they can
be compiled to a .mof file. If the tests find any errors the build will fail.
Before the test runs in AppVeyor the module will be copied to a path of
`$env:PSModulePath`.
To run this test locally, make sure you have the resource module
deployed to a path where it can be used.
See `$env:PSModulePath` to view the existing paths.

>**Note:* To run the common tests, at least one unit tests must have be run for
>the common test framework to have been cloned locally.

```powershell
cd '<path to cloned repository>'
Invoke-Pester .\DSCResource.Tests\Meta.Tests.ps1
```

### Integration tests

Integration tests should be written for resources so they can be validated by
the automated test framework which is run in AppVeyor when commits are pushed
to a Pull Request (PR).
Please see the [Testing Guidelines](https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md)
for common DSC Resource Kit testing guidelines.
There are also configurations made by existing integration tests that can be reused
to write integration tests for other resources. This is documented in the
[Integration tests README](/Tests/Integration/README.md).

#### AppVeyor

AppVeyor is the platform where the tests is run when sending in a Pull Request (PR).
All tests are run on a clean AppVeyor build worker for each push to the Pull
Request (PR).
The tests that are run on the build worker are common tests, unit tests and
integration tests (with some limitations).

### Documentation with Markdown

If using Visual Studio Code to edit Markdown files it can be a good idea to install
the markdownlint extension. It will help to find lint errors and style checking.
The file [.markdownlint.json](/.markdownlint.json) is prepared with a default set
of rules which will automatically be used by the extension.
