TestScope "Calculator.ps1" {

    # enable PSMock (comment this out if not using mocks)
    Enable-Mock | iex

    # import the script
    . $TestScriptPath\Calculator.ps1

    Describing "Calculator" {

        Given "two numbers" {
            TestSetup {
                Mock Add-Numbers { 90 } -When {$x -eq 0}
                Mock Add-Numbers { 91 } -When {$y -eq 0}
            }

            It "Add-Numbers Normal" {
                Add-Numbers 1 2 | should be 3
            }

            It "Add-Numbers With X=0" {
                Add-Numbers 0 2 | should be 90
            }

            It "Add-Numbers With Y=0" {
                Add-Numbers 1 0 | should be 91
            }
        }
    }
}

