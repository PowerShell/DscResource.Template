<#
    .SYNOPSIS
        Template for creating DSC Resource Unit Tests
    .DESCRIPTION
        To Use:
        1. Copy to \Tests\Unit\ folder and rename <ResourceName>.tests.ps1 (e.g. MSFT_xFirewall.tests.ps1)
        2. Customize TODO sections.
        3. Delete all template comments (TODOs, etc.)
    .NOTES
        There are multiple methods for writing unit tests. This template provides a few examples
        which you are welcome to follow but depending on your resource, you may want to
        design it differently. Read through our TestsGuidelines.md file for an intro on how to
        write unit tests for DSC resources: https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md
#>

#region HEADER
# TODO: Update to correct module name and resource name.
$script:DSCModuleName = 'DscResource.Template'
$script:DSCResourceName = 'MSFT_Folder'

# Unit Test Template Version: 1.3.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{s
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

# TODO: Insert the correct <ModuleName> and <ResourceName> for your resource
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
     # TODO: Optional init code goes here...
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    # TODO: Other Optional Cleanup Code Goes Here...
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        <#
            TODO: Optionally create any variables here for use by your tests

            TODO: Optionally create any script blocks that will be used by mocks
            in BeforeAll/BeforeEach to dynamically set variables.

            TODO: Complete the Describe blocks below and add more as needed.
            The most common method for unit testing is to test by function. For more information
            check out this introduction to writing unit tests in Pester:
            https://www.simple-talk.com/sysadmin/powershell/practical-powershell-unit-testing-getting-started/#eleventh
            You may also follow one of the patterns provided in the TestsGuidelines.md file:
            https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md
        #>

        $mockFolderObject = $null

        Describe "MSFT_Folder\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $defaultParameters = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
                    ReadOnly = $false
                }

                # Per describe-block initialization
                $script:mockFolderObject = New-Item -Path $defaultParameters.Path -ItemType 'Directory' -Force
            }

            AfterAll {
                # Per describe-block cleanup
                #Remove-Item -Path $defaultParameters.Path -Force
            }

            BeforeEach {
                # per test initialization within the describe-block

                $getTargetResourceParameters = $defaultParameters.Clone()
            }

            AfterEach {
                # per test cleanup within the describe-block
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    # Per context-block initialization
                }

                AfterAll {
                    # Per context-block cleanup
                }

                BeforeEach {
                    # per test initialization
                }

                AfterEach {
                    # per test cleanup
                }

                Context 'When the configuration is absent' {
                    BeforeAll {
                        # Per context-block initialization
                        Mock -CommandName Get-Item -MockWith {
                            return $null
                        } -Verifiable
                    }

                    AfterAll {
                        # Per context-block cleanup
                    }

                    BeforeEach {
                        # per test initialization
                    }

                    AfterEach {
                        # per test cleanup
                    }

                    It 'Should return the state as absent' {
                        # test-code
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Ensure | Should -Be 'Absent'

                        Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the same values as passed as parameters' {
                        # test-code
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Path | Should -Be $getTargetResourceParameters.Path
                        $getTargetResourceResult.ReadOnly | Should -Be $getTargetResourceParameters.ReadOnly
                  }

                    It 'Should return $false or $null respectively for the rest of the properties' {
                        # test-code
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Hidden | Should -Be $false
                        $getTargetResourceResult.EnableSharing | Should -Be $false
                        $getTargetResourceResult.ShareName | Should -BeNullOrEmpty
                    }
                }

                Context 'When the configuration is present' {
                    BeforeAll {
                        # Per context-block initialization
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

                    AfterAll {
                        # Per context-block cleanup
                    }

                    BeforeEach {
                        # per test initialization
                        Mock -CommandName Get-SmbShare -MockWith {
                            return @{
                                # This is using the parameter from the test case.
                                Path = $EnableSharing
                            }
                        }
                    }

                    AfterEach {
                        # per test cleanup
                    }

                    It 'Should return the state as present' {
                        # test-code
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Ensure | Should -Be 'Present'

                        Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Path | Should -Be $getTargetResourceParameters.Path
                    }

                    It 'Should return the correct values when EnableSharing is ''<EnableSharing>''' -TestCases $testCase {
                        param
                        (
                            # EnableSharing
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

            # Context 'When the system is not in the desired state' {
            #     BeforeAll {
            #         # Per context-block initialization
            #     }

            #     BeforeAll {
            #         # Per context-block cleanup
            #     }

            #     Context 'When the configuration is absent' {
            #         BeforeEach {
            #             # per-test-initialization
            #         }

            #         AfterEach {
            #             # per-test-cleanup
            #         }

            #         It 'Should return the state as absent' {
            #             # test-code
            #             $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
            #             $getTargetResourceResult.Ensure | Should -Be 'Absent'

            #             Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
            #         }

            #         It 'Should return the same values as passed as parameters' {
            #             # test-code
            #             $result = Get-TargetResource @getTargetResourceParameters
            #             $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
            #             $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName

            #             Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
            #         }

            #         It 'Should return $null for the rest of the properties' {
            #             # test-code
            #             $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
            #             $getTargetResourceResult.AccountName | Should -BeNullOrEmpty
            #             $getTargetResourceResult.EmailAddress | Should -BeNullOrEmpty
            #             $getTargetResourceResult.MailServerName | Should -BeNullOrEmpty
            #             $getTargetResourceResult.LoggingLevel | Should -BeNullOrEmpty
            #             $getTargetResourceResult.ProfileName | Should -BeNullOrEmpty
            #             $getTargetResourceResult.DisplayName | Should -BeNullOrEmpty
            #             $getTargetResourceResult.ReplyToAddress | Should -BeNullOrEmpty
            #             $getTargetResourceResult.Description | Should -BeNullOrEmpty
            #             $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty

            #             Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
            #         }
            #     }

            #     Context 'When the configuration is present' {
            #         It 'Should return the state as present' {
            #             $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
            #             $getTargetResourceResult.Ensure | Should -Be 'Present'

            #             Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
            #         }

            #         It 'Should return the same values as passed as parameters' {
            #             $result = Get-TargetResource @getTargetResourceParameters
            #             $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
            #             $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName

            #             Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
            #         }

            #         It 'Should return the correct values for the rest of the properties' {
            #             $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
            #             $getTargetResourceResult.AccountName | Should -Be $mockAccountName
            #             $getTargetResourceResult.EmailAddress | Should -Be $mockEmailAddress
            #             $getTargetResourceResult.MailServerName | Should -Be $mockMailServerName
            #             $getTargetResourceResult.LoggingLevel | Should -Be $mockLoggingLevelExtended
            #             $getTargetResourceResult.ProfileName | Should -Be $mockProfileName
            #             $getTargetResourceResult.DisplayName | Should -Be $mockDisplayName
            #             $getTargetResourceResult.ReplyToAddress | Should -Be $mockReplyToAddress
            #             $getTargetResourceResult.Description | Should -Be $mockDescription
            #             $getTargetResourceResult.TcpPort | Should -Be $mockTcpPort

            #             Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
            #         }
            #     }
            # }

            # (optional) Verifies that all mocks in the context was called.
            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerDatabaseMail\Test-TargetResource" -Tag 'Test' {
            BeforeAll {
                $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
                $mockDynamicLoggingLevelValue = $mockLoggingLevelExtendedValue
                $mockDynamicDescription = $mockDescription
                $mockDynamicAgentMailType = $mockAgentMailTypeDatabaseMail
                $mockDynamicDatabaseMailProfile = $mockProfileName
            }

            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $testTargetResourceParameters = $defaultParameters.Clone()
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                        $testTargetResourceParameters['AccountName'] = $mockMissingAccountName
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is present' {
                    BeforeEach {
                        $testTargetResourceParameters['DisplayName'] = $mockDisplayName
                        $testTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
                        $testTargetResourceParameters['Description'] = $mockDescription
                        $testTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
                        $testTargetResourceParameters['TcpPort'] = $mockTcpPort
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration should be present' {
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

                    $testCaseAccountNameIsMissing = $defaultTestCase.Clone()
                    $testCaseAccountNameIsMissing['TestName'] = 'AccountName is missing'
                    $testCaseAccountNameIsMissing['AccountName'] = 'MissingAccountName'

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

                    $testCaseLoggingLevelIsWrong = $defaultTestCase.Clone()
                    $testCaseLoggingLevelIsWrong['TestName'] = 'LoggingLevel is wrong'
                    $testCaseLoggingLevelIsWrong['LoggingLevel'] = $mockLoggingLevelNormal

                    $testCaseTcpPortIsWrong = $defaultTestCase.Clone()
                    $testCaseTcpPortIsWrong['TestName'] = 'TcpPort is wrong'
                    $testCaseTcpPortIsWrong['TcpPort'] = 2525

                    $testCases = @(
                        $testCaseAccountNameIsMissing
                        $testCaseEmailAddressIsWrong
                        $testCaseMailServerNameIsWrong
                        $testCaseProfileNameIsWrong
                        $testCaseDisplayNameIsWrong
                        $testCaseReplyToAddressIsWrong
                        $testCaseDescriptionIsWrong
                        $testCaseLoggingLevelIsWrong
                        $testCaseTcpPortIsWrong
                    )

                    It 'Should return the state as $false when <TestName>' -TestCases $testCases {
                        param
                        (
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

                        $testTargetResourceParameters['AccountName'] = $AccountName
                        $testTargetResourceParameters['EmailAddress'] = $EmailAddress
                        $testTargetResourceParameters['MailServerName'] = $MailServerName
                        $testTargetResourceParameters['ProfileName'] = $ProfileName
                        $testTargetResourceParameters['DisplayName'] = $DisplayName
                        $testTargetResourceParameters['ReplyToAddress'] = $ReplyToAddress
                        $testTargetResourceParameters['Description'] = $Description
                        $testTargetResourceParameters['LoggingLevel'] = $LoggingLevel
                        $testTargetResourceParameters['TcpPort'] = $TcpPort

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerDatabaseMail\Set-TargetResource" -Tag 'Set' {
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

