# This is optional. It is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 1)]
param()

$script:DSCModuleName = 'DscResource.Template'
$script:DSCResourceFriendlyName = 'Folder'
$script:DSCResourceName = "MSFT_$($script:DSCResourceFriendlyName)"

if (-not $env:APPVEYOR -eq $true)
{
    Write-Warning -Message ('Integration test for {0} will be skipped unless $env:APPVEYOR equals $true' -f $script:DSCResourceName)
    return
}

#region HEADER
# Integration Test Template Version: 1.2.1
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    Describe "$($script:DSCResourceName)_Integration" {
        $configurationName = "$($script:DSCResourceName)_Create_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq "[$($script:DSCResourceFriendlyName)]Integration_Test"
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.Path
                $resourceCurrentState.ReadOnly | Should -Be $ConfigurationData.AllNodes.ReadOnly
                $resourceCurrentState.Hidden | Should -Be $false
                $resourceCurrentState.EnableSharing | Should -Be $false
                $resourceCurrentState.ShareName | Should -BeNullOrEmpty
            }
        }

        $configurationName = "$($script:DSCResourceName)_Remove_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData    = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq "[$($script:DSCResourceFriendlyName)]Integration_Test"
                }

                $resourceCurrentState.Ensure | Should -Be 'Absent'
                $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.Path
                $resourceCurrentState.ReadOnly | Should -Be $false
                $resourceCurrentState.Hidden | Should -Be $false
                $resourceCurrentState.EnableSharing | Should -Be $false
                $resourceCurrentState.ShareName | Should -BeNullOrEmpty
            }
        }
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
