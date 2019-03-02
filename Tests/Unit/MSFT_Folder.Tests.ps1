#region HEADER
$script:dscModuleName = 'DscResource.Template'
$script:dscResourceName = 'MSFT_Folder'

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
        $mockFolderObject = $null

        Describe 'MSFT_Folder\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $defaultParameters = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
                    ReadOnly = $false
                }

                $script:mockFolderObject = New-Item -Path $defaultParameters.Path -ItemType 'Directory' -Force
            }

            BeforeEach {
                $getTargetResourceParameters = $defaultParameters.Clone()
            }

            Context 'When the configuration is absent' {
                BeforeAll {
                    Mock -CommandName Get-Item -MockWith {
                        return $null
                    } -Verifiable
                }

                It 'Should return the state as absent' {
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                    $getTargetResourceResult.Ensure | Should -Be 'Absent'

                    Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                    $getTargetResourceResult.Path | Should -Be $getTargetResourceParameters.Path
                    $getTargetResourceResult.ReadOnly | Should -Be $getTargetResourceParameters.ReadOnly
                }

                It 'Should return $false or $null respectively for the rest of the properties' {
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                    $getTargetResourceResult.Hidden | Should -Be $false
                    $getTargetResourceResult.Shared | Should -Be $false
                    $getTargetResourceResult.ShareName | Should -BeNullOrEmpty
                }
            }

            Context 'When the configuration is present' {
                BeforeAll {
                    Mock -CommandName Get-Item -MockWith {
                        return $script:mockFolderObject
                    }

                    $testCase = @(
                        @{
                            Shared = $false
                        },
                        @{
                            Shared = $true
                        }
                    )
                }

                BeforeEach {
                    Mock -CommandName Get-SmbShare -MockWith {
                        return @{
                            Path = $Shared
                        }
                    }
                }

                It 'Should return the state as present' {
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                    $getTargetResourceResult.Ensure | Should -Be 'Present'

                    Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                    $getTargetResourceResult.Path | Should -Be $getTargetResourceParameters.Path
                }

                It 'Should return the correct values when Shared is <Shared>' -TestCases $testCase {
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [System.Boolean]
                        $Shared
                    )

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                    $getTargetResourceResult.Shared | Should -Be $Shared

                    Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'MSFT_Folder\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $defaultParameters = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
                    ReadOnly = $false
                }

                $script:mockFolderObject = New-Item -Path $defaultParameters.Path -ItemType 'Directory' -Force
            }

            BeforeEach {
                $testTargetResourceParameters = $defaultParameters.Clone()
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration are absent' {
                    BeforeAll {
                        Mock -CommandName Get-Item -MockWith {
                            return $null
                        } -Verifiable
                    }

                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration are present' {
                    BeforeAll {
                        $mockGetTargetResource = @{
                            Ensure    = 'Present'
                            ReadOnly  = $true
                            Hidden    = $true
                            Shared    = $true
                            ShareName = 'TestShare'
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return $mockGetTargetResource
                        } -Verifiable
                    }

                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Present'
                        $testTargetResourceParameters['ReadOnly'] = $true
                        $testTargetResourceParameters['Hidden'] = $true
                    }

                    It 'Should return the $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Assert-VerifiableMock
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the $true' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                            }
                        } -Verifiable

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false
                    }
                }

                Context 'When the configuration should be present' {
                    BeforeAll {
                        $testCase = @(
                            @{
                                Path      = (Join-Path -Path $TestDrive -ChildPath 'FolderTestReadOnly')
                                ReadOnly  = $true
                                Hidden    = $false
                                Shared    = $false
                                ShareName = $null
                            },
                            @{
                                Path      = (Join-Path -Path $TestDrive -ChildPath 'FolderTestHidden')
                                ReadOnly  = $false
                                Hidden    = $true
                                Shared    = $false
                                ShareName = $null
                            }
                        )
                    }

                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Present'
                    }

                    It 'Should return the $true' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure   = 'Absent'
                                ReadOnly = $false
                            }
                        } -Verifiable

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false
                    }

                    It 'Should return $false when ReadOnly is <ReadOnly>, and Hidden is <Hidden>' -TestCases $testCase {
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
                            $Shared,

                            [Parameter()]
                            [System.String]
                            $ShareName
                        )

                        $mockGetTargetResource = @{
                            Ensure    = 'Present'
                            Path      = $Path
                            ReadOnly  = $ReadOnly
                            Hidden    = $Hidden
                            Shared    = $Shared
                            ShareName = $ShareName
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return $mockGetTargetResource
                        } -Verifiable

                        $testTargetResourceParameters['ReadOnly'] = $false
                        $testTargetResourceParameters['Hidden'] = $false

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false
                    }
                }

                Assert-VerifiableMock
            }
        }

        Describe 'MSFT_Folder\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $defaultParameters = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
                    ReadOnly = $false
                }
            }

            BeforeEach {
                $setTargetResourceParameters = $defaultParameters.Clone()
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Set-FileAttribute
                }

                AfterEach {
                    <#
                        Make sure to remove the test folder so that it does
                        not exist for other tests.
                    #>
                    if ($script:mockFolderObject -and (Test-Path -Path $script:mockFolderObject))
                    {
                        Remove-Item -Path $script:mockFolderObject -Force
                    }
                }

                Context 'When the configuration should be absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                            }
                        } -Verifiable

                        Mock -CommandName Remove-Item -ParameterFilter {
                            $Path -eq $setTargetResourceParameters.Path
                        } -Verifiable
                    }

                    BeforeEach {
                        $setTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the configuration should be present' {
                    BeforeAll {
                        $script:mockFolderObject = New-Item -Path $defaultParameters.Path -ItemType 'Directory' -Force

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Absent'
                            }
                        } -Verifiable

                        Mock -CommandName Get-Item
                        Mock -CommandName New-Item -ParameterFilter {
                            $Path -eq $setTargetResourceParameters.Path
                        } -MockWith {
                            return $script:mockFolderObject
                        } -Verifiable
                    }

                    BeforeEach {
                        $setTargetResourceParameters['Ensure'] = 'Present'
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Get-Item -Exactly -Times 0 -Scope 'It'
                        Assert-MockCalled -CommandName New-Item -ParameterFilter {
                            $Path -eq $defaultParameters.Path
                        } -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Set-FileAttribute -ParameterFilter {
                            $Attribute -eq 'ReadOnly'
                        } -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Set-FileAttribute -ParameterFilter {
                            $Attribute -eq 'Hidden'
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the configuration is present but has the wrong properties' {
                    BeforeAll {
                        $script:mockFolderObject = New-Item -Path $defaultParameters.Path -ItemType 'Directory' -Force

                        $testCase = @(
                            @{
                                ReadOnly  = $true
                                Hidden    = $false
                                Shared    = $false
                                ShareName = $null
                            },
                            @{
                                ReadOnly  = $false
                                Hidden    = $true
                                Shared    = $false
                                ShareName = $null
                            },
                            @{
                                ReadOnly  = $false
                                Hidden    = $false
                                Shared    = $true
                                ShareName = 'TestShare'
                            }
                        )

                        Mock -CommandName New-Item
                        Mock -CommandName Get-Item -ParameterFilter {
                            $Path -eq $setTargetResourceParameters.Path
                        } -MockWith {
                            return $script:mockFolderObject
                        } -Verifiable
                    }

                    BeforeEach {
                        $setTargetResourceParameters['Ensure'] = 'Present'
                    }

                    It 'Should call the correct mocks when ReadOnly is <ReadOnly>, and Hidden is <Hidden>' -TestCases $testCase {
                        param
                        (
                            [Parameter(Mandatory = $true)]
                            [System.Boolean]
                            $ReadOnly,

                            [Parameter()]
                            [System.Boolean]
                            $Hidden,

                            [Parameter()]
                            [System.Boolean]
                            $Shared,

                            [Parameter()]
                            [System.String]
                            $ShareName
                        )

                        $mockGetTargetResource = @{
                            Ensure    = 'Present'
                            Path      = $script:mockFolderObject.FullName
                            ReadOnly  = $ReadOnly
                            Hidden    = $Hidden
                            Shared    = $Shared
                            ShareName = $ShareName
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return $mockGetTargetResource
                        }

                        $setTargetResourceParameters['ReadOnly'] = $false
                        $setTargetResourceParameters['Hidden'] = $false

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-Item -Exactly -Times 0 -Scope 'It'
                        Assert-MockCalled -CommandName Get-Item -Exactly -Times 1 -Scope 'It'

                        if ($ReadOnly)
                        {
                            Assert-MockCalled -CommandName Set-FileAttribute -ParameterFilter {
                                $Attribute -eq 'ReadOnly'
                            } -Exactly -Times 1 -Scope 'It'
                        }

                        if ($Hidden)
                        {
                            Assert-MockCalled -CommandName Set-FileAttribute -ParameterFilter {
                                $Attribute -eq 'Hidden'
                            } -Exactly -Times 1 -Scope 'It'
                        }
                    }
                }

                Assert-VerifiableMock
            }
        }

        Describe 'MSFT_Folder\Test-FileAttribute' -Tag 'Helper' {
            BeforeAll {
                $mockAttribute = 'ReadOnly'
                $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
                $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force
                $script:mockFolderObject.Attributes = [System.IO.FileAttributes]::$mockAttribute
            }

            Context 'When a folder has a specific attribute' {
                It 'Should return $true' {
                    $testFileAttributeResult = Test-FileAttribute -Folder $script:mockFolderObject -Attribute $mockAttribute
                    $testFileAttributeResult | Should -Be $true
                }
            }

            Context 'When a folder does not have a specific attribute' {
                It 'Should return $false' {
                    $testFileAttributeResult = Test-FileAttribute -Folder $script:mockFolderObject -Attribute 'Hidden'
                    $testFileAttributeResult | Should -Be $false
                }
            }
        }

        Describe 'MSFT_Folder\Set-FileAttribute' -Tag 'Helper' {
            BeforeAll {
                $mockAttribute = 'ReadOnly'
                $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
                $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force

                $defaultAttributeParameter = @{
                    Folder = $script:mockFolderObject
                    Attribute = $mockAttribute
                }
        }

            Context 'When a folder should have a specific attribute' {
                It 'Should set the folder to the specific attribute' {
                    $setFileAttributeParameter = $defaultAttributeParameter.Clone()
                    $setFileAttributeParameter['Enabled'] = $true

                    { Set-FileAttribute @setFileAttributeParameter } | Should -Not -Throw

                    # Using the helper function that was test above to test the result
                    $testFileAttributeResult = Test-FileAttribute @defaultAttributeParameter
                    $testFileAttributeResult | Should -Be $true
                }
            }

            Context 'When a folder should not have a specific attribute' {
                It 'Should set the folder to the specific attribute' {
                    $setFileAttributeParameter = $defaultAttributeParameter.Clone()
                    $setFileAttributeParameter['Enabled'] = $false

                    { Set-FileAttribute @setFileAttributeParameter } | Should -Not -Throw

                    # Using the helper function that was test above to test the result
                    $testFileAttributeResult = Test-FileAttribute @defaultAttributeParameter
                    $testFileAttributeResult | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

