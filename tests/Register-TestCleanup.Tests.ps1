Enable-Mock | iex

try {
    # create a file that we can delete
    $file = New-Item -Name "psate.test" -Path $env:TEMP -ItemType File -Force

    MockContext {
        # do this quietly
        $logMock = Mock Write-TestLog -OutputMock {}

        # let us clean it up
        $removeMock = Mock Remove-Item -OutputMock {}

            # run a test and look at the output
            Given "a setup" {
                TestSetup {
                    $foo = $file | Register-TestCleanup -PassThru
                    $foo | Should Be $file
                }

                It "does something" {
                }
            }

        # make sure remove-item was called on our file
        @($removeMock.Calls |? { $_.Input -contains $file }).Count | Should Be 1
    }
}
finally {
    # clean it up ourselves
    Remove-Item $file
}
