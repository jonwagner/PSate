Enable-Mock | iex

TestScope "Add-Numbers.ps1" {
    . $TestScriptPath\Mock-Numbers.ps1

    Describing "Add-Numbers" {

        TestSetup {
            Mock Get-Number { 2 }
        }

        It "mocks at a higher scope" {
            Add-Numbers | Should Be 4
        }

        It "mocks in the current scope" {
            Mock Get-Number { 3 }
            Add-Numbers | Should Be 6
        }
    }
}