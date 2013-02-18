Enable-Mock | iex

MockContext {
    # make this quiet
    $logMock = Mock Write-TestLog -OutputMock {}

    # run a test and look at the output
    $results =
        TestFixture "Fixture" -OutputResults {
            TestFixture "Group" {
                TestSetup {
                    "Setup"
                }

                TestCase "Passes" {
                }

                TestCase "Fails" {
                    throw "fail"
                }

                TestTearDown {
                    "TearDown"
                }
            }
        }

    # validate the results structure of the test
    $results.Count | Should Be 2
    $results.Name | Should Be Fixture
    $results.Cases | Should Count 1
    $results.Cases[0].Name | Should Be Group
    $results.Cases[0].Cases | Should Count 2
    $results.Cases[0].Cases[0].Name | Should Be Passes
    $results.Cases[0].Cases[1].Name | Should Be Fails

    # validate the counts of the results
    $results.Passed | Should Be 1
    $results.Failed | Should Be 1
    $results.Cases[0].Passed | Should Be 1
    $results.Cases[0].Failed | Should Be 1
    $results.Cases[0].Cases[0].Passed | Should Be 1
    $results.Cases[0].Cases[1].Failed | Should Be 1

    # make sure that setup and teardown were called
    $logMock.Calls |? { $_.Input -contains 'Setup' } | Should Count $results.Count
    $logMock.Calls |? { $_.Input -contains 'TearDown' } | Should Count $results.Count
}