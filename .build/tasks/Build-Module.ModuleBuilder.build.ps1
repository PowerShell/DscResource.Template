Param (

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf $BuildRoot) ),

    $SourcePath = (property SourcePath (Join-path $BuildRoot "Source/[Bb]uild.psd1")),

    [string]
    $SourceFolder = $ProjectName,

    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [string]
    $ModuleVersion = (property ModuleVersion $(
            if (Get-Command gitversion) {
                Write-Verbose "Using  ModuleVersion as resolved by gitversion"
                (gitversion | ConvertFrom-Json).InformationalVersion
            }
            else {
                Write-Verbose "Command gitversion not found, defaulting to 0.0.1"
                '0.0.1'
            }
        ))
)

# Synopsis: Build the Module based on its Build.psd1 definition
Task Build_Module_ModuleBuilder {
    Import-Module ModuleBuilder

    # $BuildModuleParams = @{
    #     SourcePath
    #     OutputDirectory
    #     SemVer
    #     Version
    #     Prerelease
    #     BuildMetaData
    # }
    "Module version is $ModuleVersion"
    "Git Version says: $((gitversion | ConvertFrom-Json).InformationalVersion)"

    Build-Module -SourcePath $SourcePath -SemVer $ModuleVersion

}
