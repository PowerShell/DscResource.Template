@{
    # Pending PR on ModuleBuilder
    Path                 = "./Source/DscResource.Template.psd1"
    OutputDirectory      = "./output/DscResource.Template"
    Suffix               = "./suffix.ps1"

    BuildWorkflow        = @{
        # Default workflow (when no tasks specified)
        '.'     = @(
            'Clean',
            'Set_Build_Environment_Variables',
            'Build_Module_ModuleBuilder',
            'Pester_Tests_Stop_On_Fail',
            'Pester_if_Code_Coverage_Under_Threshold'
        )

        'build' = @(
            'Clean',
            'Set_Build_Environment_Variables',
            'Build_Module_ModuleBuilder'
        )

        'test'  = @(
            'Pester_Tests_Stop_On_Fail',
            'Pester_if_Code_Coverage_Under_Threshold'
        )
    }

    'Resolve-Dependency' = @{
        #PSDependTarget              = './output/modules'
        #Proxy = ''
        #ProxyCredential
        Gallery         = 'PSGallery'
        # AllowOldPowerShellGetModule = $true
        #MinimumPSDependVersion = '0.3.0'
        AllowPrerelease = $false
        Verbose         = $false
    }

    TaskHeader           = '
        param($Path)
        ""
        "=" * 79
        Write-Build Cyan "`t`t`t$($Task.Name.replace("_"," ").ToUpper())"
        Write-Build DarkGray  "$(Get-BuildSynopsis $Task)"
        "-" * 79
        Write-Build DarkGray "  $Path"
        Write-Build DarkGray "  $($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
        ""
    '
}
