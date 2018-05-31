# DscResource.Template

The **DscResource.Template** module contains a template with example code and
best practices for DSC resource modules in
[DSC Resource Kit](https://github.com/PowerShell/DscResources).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional
questions or comments.

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/csmbpuwy8krymv05/branch/master?svg=true)](https://ci.appveyor.com/project/johlju/DscResource-Template/branch/master)
[![codecov](https://codecov.io/gh/johlju/DscResource.Template/branch/master/graph/badge.svg)](https://codecov.io/gh/johlju/DscResource.Template/branch/master)

This is the branch containing the latest release -
no contributions should be made directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/csmbpuwy8krymv05/branch/dev?svg=true)](https://ci.appveyor.com/project/johlju/DscResource-Template/branch/dev)
[![codecov](https://codecov.io/gh/johlju/DscResource.Template/branch/dev/graph/badge.svg)](https://codecov.io/gh/johlju/DscResource.Template/branch/dev)

This is the development branch
to which contributions should be proposed by contributors as pull requests.
This development branch will periodically be merged to the master branch,
and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please see our [contributing guidelines](/CONTRIBUTING.md).

## Installation

### GitHub

To manually install the module,
download the source code and unzip the contents to the directory
'$env:ProgramFiles\WindowsPowerShell\Modules' folder.

### PowerShell Gallery

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

```powershell
Find-Module -Name DscResource.Template -Repository PSGallery | Install-Module
```

To confirm installation, run the below command and ensure you see the
DSC resources available:

```powershell
Get-DscResource -Module DscResource.Template
```

## Requirements

The minimum Windows Management Framework (PowerShell) version required is 4.0
or higher.

## Examples

You can review the [Examples](/Examples) directory for some general use
scenarios for all of the resources that are in the module.

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

* [**Folder**](#folder) example resource
  to manage a folder on Windows.

### Folder

Example resource to manage a folder on Windows.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **`[String]` Path** _(Key)_: The path to the folder to create.
* **`[Boolean]` ReadOnly** _(Required)_: If the files in the folder should be
  read only.
* **`[Boolean]` Hidden** _(Write)_: If the folder should be hidden.
  Default value is `$false`.
* **`[Boolean]` EnableSharing** _(Write)_: If sharing should be enabled on the
  folder. Default value is `$false`.
* **`[String]` Ensure** _(Write)_: Specifies the desired state of the folder.
     When set to `'Present'`, the folder will be created. When set to `'Absent'`,
    the folder will be removed. Default value is `'Present'`.

#### Read-Only Properties from Get-TargetResource

* **`[String]` ShareName** _(Read)_: The name of the shared resource.

#### Examples

* [Create folder](/Examples/Resources/Folder/1-CreateFolder.ps1)
* [Remove folder](/Examples/Resources/Folder/2-RemoveFolder.ps1)

#### Known issues

All issues are not listed here, see [here for all open issues](https://github.com/johlju/DscResource.Template/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+Folder).
