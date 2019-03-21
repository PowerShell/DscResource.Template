@{
    Path                     = "./DscResource.template.psd1"
    VersionedOutputDirectory = $true
    OutputDirectory          = "../output/DscResource.template"
    Suffix                   = "./suffix.ps1"
    CopyDirectories          = @('Examples','DSCResources','en')
}
