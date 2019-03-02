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
                    $getTargetResourceResult.EnableSharing | Should -Be $false
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
                            EnableSharing = $false
                        },
                        @{
                            EnableSharing = $true
                        }
                    )
                }

                BeforeEach {
                    Mock -CommandName Get-SmbShare -MockWith {
                        return @{
                            Path = $EnableSharing
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

                It 'Should return the correct values when EnableSharing is <EnableSharing>' -TestCases $testCase {
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [System.Boolean]
                        $EnableSharing
                    )

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                    $getTargetResourceResult.EnableSharing | Should -Be $EnableSharing

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
                            Ensure = 'Present'
                            ReadOnly = $true
                            Hidden = $true
                            EnableSharing = $true
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
                        $testTargetResourceParameters['EnableSharing'] = $true
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
                                Path          = (Join-Path -Path $TestDrive -ChildPath 'FolderTestReadOnly')
                                ReadOnly      = $true
                                Hidden        = $false
                                EnableSharing = $false
                                ShareName     = $null
                            },
                            @{
                                Path          = (Join-Path -Path $TestDrive -ChildPath 'FolderTestHidden')
                                ReadOnly      = $false
                                Hidden        = $true
                                EnableSharing = $false
                                ShareName     = $null
                            },
                            @{
                                Path          = (Join-Path -Path $TestDrive -ChildPath 'FolderTestShare')
                                ReadOnly      = $false
                                Hidden        = $false
                                EnableSharing = $true
                                ShareName     = 'TestShare'
                            }
                        )
                    }

                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Present'
                    }

                    It 'Should return the $true' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Absent'
                                ReadOnly = $false
                            }
                        } -Verifiable

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false
                    }

                    It 'Should return $false when ReadOnly is <ReadOnly>, Hidden is <Hidden>, and EnableSharing is <EnableSharing>' -TestCases $testCase {
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
                            $EnableSharing,

                            [Parameter()]
                            [System.String]
                            $ShareName
                        )

                        $mockGetTargetResource = @{
                            Ensure = 'Present'
                            Path = $Path
                            ReadOnly = $ReadOnly
                            Hidden = $Hidden
                            EnableSharing = $EnableSharing
                            ShareName = $ShareName
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return $mockGetTargetResource
                        } -Verifiable

                        $testTargetResourceParameters['ReadOnly'] = $false
                        $testTargetResourceParameters['Hidden'] = $false
                        $testTargetResourceParameters['EnableSharing'] = $false

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false
                    }
                }

                Assert-VerifiableMock
            }
        }

        Describe 'MSFT_Folder\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
                $mockDynamicLoggingLevelValue = $mockLoggingLevelExtendedValue
                $mockDynamicDescription = $mockDescription
                $mockDynamicAgentMailType = $mockAgentMailTypeDatabaseMail
                $mockDynamicDatabaseMailProfile = $mockProfileName
            }

            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObject_MailAccount -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.SMO.Mail.MailAccount'
                } -Verifiable

                Mock -CommandName New-Object -MockWith $mockNewObject_MailProfile -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.SMO.Mail.MailProfile'
                } -Verifiable

                $setTargetResourceParameters = $defaultParameters.Clone()

                $script:MailAccountCreateMethodCallCount = 0
                $script:MailServerRenameMethodCallCount = 0
                $script:MailServerAlterMethodCallCount = 0
                $script:MailAccountAlterMethodCallCount = 0
                $script:MailProfileCreateMethodCallCount = 0
                $script:MailProfileAlterMethodCallCount = 0
                $script:MailProfileAddPrincipalMethodCallCount = 0
                $script:MailProfileAddAccountMethodCallCount = 0
                $script:JobServerAlterMethodCallCount = 0
                $script:LoggingLevelAlterMethodCallCount = 0
                $script:MailProfileDropMethodCallCount = 0
                $script:MailAccountDropMethodCallCount = 0

                $mockDynamicExpectedAccountName = $mockMissingAccountName
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    BeforeEach {
                        $setTargetResourceParameters['Ensure'] = 'Absent'
                        $setTargetResourceParameters['AccountName'] = $mockMissingAccountName
                        $setTargetResourceParameters['ProfileName'] = 'MissingProfile'

                        $mockDynamicAgentMailType = $mockAgentMailTypeSqlAgentMail
                        $mockDynamicDatabaseMailProfile = $null
                    }

                    It 'Should call the correct methods without throwing' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $script:MailAccountCreateMethodCallCount | Should -Be 0
                        $script:MailServerRenameMethodCallCount | Should -Be 0
                        $script:MailServerAlterMethodCallCount | Should -Be 0
                        $script:MailAccountAlterMethodCallCount | Should -Be 0
                        $script:MailProfileCreateMethodCallCount | Should -Be 0
                        $script:MailProfileAlterMethodCallCount | Should -Be 0
                        $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                        $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                        $script:JobServerAlterMethodCallCount | Should -Be 0
                        $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                        $script:MailProfileDropMethodCallCount | Should -Be 0
                        $script:MailAccountDropMethodCallCount | Should -Be 0

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is present' {
                    BeforeEach {
                        $setTargetResourceParameters['DisplayName'] = $mockDisplayName
                        $setTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
                        $setTargetResourceParameters['Description'] = $mockDescription
                        $setTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
                        $setTargetResourceParameters['TcpPort'] = $mockTcpPort
                    }

                    It 'Should call the correct methods without throwing' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $script:MailAccountCreateMethodCallCount | Should -Be 0
                        $script:MailServerRenameMethodCallCount | Should -Be 0
                        $script:MailServerAlterMethodCallCount | Should -Be 0
                        $script:MailAccountAlterMethodCallCount | Should -Be 0
                        $script:MailProfileCreateMethodCallCount | Should -Be 0
                        $script:MailProfileAlterMethodCallCount | Should -Be 0
                        $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                        $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                        $script:JobServerAlterMethodCallCount | Should -Be 0
                        $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                        $script:MailProfileDropMethodCallCount | Should -Be 0
                        $script:MailAccountDropMethodCallCount | Should -Be 0

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    BeforeEach {
                        $setTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the state as $false' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $script:JobServerAlterMethodCallCount | Should -Be 1
                        $script:MailProfileDropMethodCallCount | Should -Be 1
                        $script:MailAccountDropMethodCallCount | Should -Be 1
                    }
                }

                Context 'When the configuration should be present' {
                    Context 'When Database Mail XPs is enabled but fails evaluation' {
                        $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailDisabledConfigValue

                        It 'Should throw the correct error message' {
                            {
                                Set-TargetResource @setTargetResourceParameters
                            } | Should -Throw $script:localizedData.DatabaseMailDisabled

                            Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When account name is missing' {
                        It 'Should call the correct methods without throwing' {
                            $setTargetResourceParameters['AccountName'] = $mockMissingAccountName
                            $setTargetResourceParameters['DisplayName'] = $mockDisplayName
                            $setTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
                            $setTargetResourceParameters['Description'] = $mockDescription
                            $setTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
                            $setTargetResourceParameters['TcpPort'] = $mockTcpPort

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                            $script:MailAccountCreateMethodCallCount | Should -Be 1
                            $script:MailServerRenameMethodCallCount | Should -Be 1
                            $script:MailServerAlterMethodCallCount | Should -Be 1
                            $script:MailAccountAlterMethodCallCount | Should -Be 0

                            Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When properties are not in desired state' {
                        $defaultTestCase = @{
                            AccountName    = $mockAccountName
                            EmailAddress   = $mockEmailAddress
                            MailServerName = $mockMailServerName
                            ProfileName    = $mockProfileName
                            DisplayName    = $mockDisplayName
                            ReplyToAddress = $mockReplyToAddress
                            Description    = $mockDescription
                            LoggingLevel   = $mockLoggingLevelExtended
                            TcpPort        = $mockTcpPort
                        }

                        $testCaseEmailAddressIsWrong = $defaultTestCase.Clone()
                        $testCaseEmailAddressIsWrong['TestName'] = 'EmailAddress is wrong'
                        $testCaseEmailAddressIsWrong['EmailAddress'] = 'wrong@email.address'

                        $testCaseMailServerNameIsWrong = $defaultTestCase.Clone()
                        $testCaseMailServerNameIsWrong['TestName'] = 'MailServerName is wrong'
                        $testCaseMailServerNameIsWrong['MailServerName'] = 'smtp.contoso.com'

                        $testCaseProfileNameIsWrong = $defaultTestCase.Clone()
                        $testCaseProfileNameIsWrong['TestName'] = 'ProfileName is wrong'
                        $testCaseProfileNameIsWrong['ProfileName'] = 'NewProfile'

                        $testCaseDisplayNameIsWrong = $defaultTestCase.Clone()
                        $testCaseDisplayNameIsWrong['TestName'] = 'DisplayName is wrong'
                        $testCaseDisplayNameIsWrong['DisplayName'] = 'New display name'

                        $testCaseReplyToAddressIsWrong = $defaultTestCase.Clone()
                        $testCaseReplyToAddressIsWrong['TestName'] = 'ReplyToAddress is wrong'
                        $testCaseReplyToAddressIsWrong['ReplyToAddress'] = 'new-reply@email.address'

                        $testCaseDescriptionIsWrong = $defaultTestCase.Clone()
                        $testCaseDescriptionIsWrong['TestName'] = 'Description is wrong'
                        $testCaseDescriptionIsWrong['Description'] = 'New description'

                        $testCaseLoggingLevelIsWrong_Normal = $defaultTestCase.Clone()
                        $testCaseLoggingLevelIsWrong_Normal['TestName'] = 'LoggingLevel is wrong, should be ''Normal'''
                        $testCaseLoggingLevelIsWrong_Normal['LoggingLevel'] = $mockLoggingLevelNormal

                        $testCaseLoggingLevelIsWrong_Verbose = $defaultTestCase.Clone()
                        $testCaseLoggingLevelIsWrong_Verbose['TestName'] = 'LoggingLevel is wrong, should be ''Verbose'''
                        $testCaseLoggingLevelIsWrong_Verbose['LoggingLevel'] = $mockLoggingLevelVerbose

                        $testCaseTcpPortIsWrong = $defaultTestCase.Clone()
                        $testCaseTcpPortIsWrong['TestName'] = 'TcpPort is wrong'
                        $testCaseTcpPortIsWrong['TcpPort'] = 2525

                        $testCases = @(
                            $testCaseEmailAddressIsWrong
                            $testCaseMailServerNameIsWrong
                            $testCaseProfileNameIsWrong
                            $testCaseDisplayNameIsWrong
                            $testCaseReplyToAddressIsWrong
                            $testCaseDescriptionIsWrong
                            $testCaseLoggingLevelIsWrong_Normal
                            $testCaseLoggingLevelIsWrong_Verbose
                            $testCaseTcpPortIsWrong
                        )

                        It 'Should return the state as $false when <TestName>' -TestCases $testCases {
                            param
                            (
                                $TestName,
                                $AccountName,
                                $EmailAddress,
                                $MailServerName,
                                $ProfileName,
                                $DisplayName,
                                $ReplyToAddress,
                                $Description,
                                $LoggingLevel,
                                $TcpPort
                            )

                            $setTargetResourceParameters['AccountName'] = $AccountName
                            $setTargetResourceParameters['EmailAddress'] = $EmailAddress
                            $setTargetResourceParameters['MailServerName'] = $MailServerName
                            $setTargetResourceParameters['ProfileName'] = $ProfileName
                            $setTargetResourceParameters['DisplayName'] = $DisplayName
                            $setTargetResourceParameters['ReplyToAddress'] = $ReplyToAddress
                            $setTargetResourceParameters['Description'] = $Description
                            $setTargetResourceParameters['LoggingLevel'] = $LoggingLevel
                            $setTargetResourceParameters['TcpPort'] = $TcpPort

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:MailAccountCreateMethodCallCount | Should -Be 0

                            if ($TestName -like '*MailServerName*')
                            {
                                $script:MailServerRenameMethodCallCount | Should -Be 1
                                $script:MailServerAlterMethodCallCount | Should -Be 1
                                $script:MailAccountAlterMethodCallCount | Should -Be 0
                                $script:MailProfileCreateMethodCallCount | Should -Be 0
                                $script:MailProfileAlterMethodCallCount | Should -Be 0
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                                $script:JobServerAlterMethodCallCount | Should -Be 0
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                            }
                            elseif ($TestName -like '*TcpPort*')
                            {
                                $script:MailServerRenameMethodCallCount | Should -Be 0
                                $script:MailServerAlterMethodCallCount | Should -Be 1
                                $script:MailAccountAlterMethodCallCount | Should -Be 0
                                $script:MailProfileCreateMethodCallCount | Should -Be 0
                                $script:MailProfileAlterMethodCallCount | Should -Be 0
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                                $script:JobServerAlterMethodCallCount | Should -Be 0
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                            }
                            elseif ($TestName -like '*ProfileName*')
                            {
                                $script:MailServerRenameMethodCallCount | Should -Be 0
                                $script:MailServerAlterMethodCallCount | Should -Be 0
                                $script:MailAccountAlterMethodCallCount | Should -Be 0
                                $script:MailProfileCreateMethodCallCount | Should -Be 1
                                $script:MailProfileAlterMethodCallCount | Should -Be 1
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 1
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 1
                                $script:JobServerAlterMethodCallCount | Should -Be 1
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                            }
                            elseif ($TestName -like '*LoggingLevel*')
                            {
                                $script:MailServerRenameMethodCallCount | Should -Be 0
                                $script:MailServerAlterMethodCallCount | Should -Be 0
                                $script:MailAccountAlterMethodCallCount | Should -Be 0
                                $script:MailProfileCreateMethodCallCount | Should -Be 0
                                $script:MailProfileAlterMethodCallCount | Should -Be 0
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                                $script:JobServerAlterMethodCallCount | Should -Be 0
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 1
                            }
                            else
                            {
                                $script:MailServerRenameMethodCallCount | Should -Be 0
                                $script:MailServerAlterMethodCallCount | Should -Be 0
                                $script:MailAccountAlterMethodCallCount | Should -Be 1
                                $script:MailProfileCreateMethodCallCount | Should -Be 0
                                $script:MailProfileAlterMethodCallCount | Should -Be 0
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                                $script:JobServerAlterMethodCallCount | Should -Be 0
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                            }

                            Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                        }
                    }
                }
            }

            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}

