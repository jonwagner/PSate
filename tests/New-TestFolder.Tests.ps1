Enable-Mock | iex

MockContext {
    # do this quietly
    $logMock = Mock Write-TestLog -OutputMock {}

    # let us clean it up
    $newMock = Mock New-Item -OutputMock { "folder" }
    $removeMock = Mock Remove-Item -OutputMock {}

        # run a test and look at the output
        Given "a setup" {
            TestSetup {
                $folder | New-TestFolder
            }

            It "does something" {
            }
        }

    # make sure we added and removed the folder
    $newMock.Calls | Should Count 1
    $newMock.Calls |% { $_.BoundParameters['ItemType'] } | Should Be Container
    $removeMock.Calls |? Input -contains "folder" | Should Count 1
}
