Enable-Mock | iex

MockContext {
    # do this quietly
    $logMock = Mock Write-TestLog -OutputMock {}

    # let us clean it up
    $newMock = Mock New-Item -OutputMock { "file" }
    $removeMock = Mock Remove-Item -OutputMock {}

        # run a test and look at the output
        Given "a setup" {
            TestSetup {
                $file | New-TestFile
            }

            It "does something" {
            }
        }

    # make sure we added and removed the file
    $newMock.Calls.Count | Should Be 1
    $newMock.Calls |% { $_.BoundParameters['ItemType'] } | Should Be File
    @($removeMock.Calls |? { $_.Input -contains "file" }).Count | Should Be 1
}

# now that we know the file is removed properly, let's test the parameters
MockContext {
    # do this quietly
    $logMock = Mock Write-TestLog -OutputMock {}

    It "creates a file in the temp folder" {
        $file = New-TestFile
        $file | Should Exist
        $file.Directory | Should Be $env:TEMP
    }

    It "creates a file with a given name" {
        $file = New-TestFile -Name "Fred"
        $file | Should Exist
        $file.Name | Should Be "Fred"
    }

    It "creates a file with a given name" {
        $folder = New-Item -Name "psate.temp" -Path $env:TEMP -ItemType Folder

        $file = New-TestFile -Path $folder
        $file | Should Exist
        $file.Directory | Should Be $folder
    }
}