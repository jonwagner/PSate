Enable-Mock | iex

MockContext {
    # make this quiet
    $logMock = Mock Write-TestLog -OutputMock {}

    # run a test and look at the output
    $results =
        Describing "Describing" -OutputResults {
            Given "Given" {
                TestSetup {
                    "Setup"
                }

                It "Passes" {
                }

                It "Fails" {
                    throw "fail"
                }

                TestTearDown {
                    "TearDown"
                }
            }
        }

    # validate the results structure of the test
    $results.Count | Should Be 2
    $results.Name | Should Be Describing
    $results.Cases | Should Count 2
    $results.Cases[0].Name | Should Be Given
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

MockContext {
    # make this quiet
    $logMock = Mock Write-TestLog -OutputMock {}

    # run a test and look at the output
    $results =
        Describing "Describing" -OutputResults {
            GivenEach "Given" {
                TestSetup {
                    "Setup"
                }

                1..3 | % {
                It "Fails if even" {
                    if (($_ % 2) -eq 0) {
                      throw "fail"
                    }
                }

                It "Passes if less than 3" {
                    if ($_ -ge 3) {
                      throw "fail"
                    }
                }

                TestTearDown {
                    "TearDown"
                }
            }
        }
    }

    # validate the results structure of the test
    $results.Count | Should Be 6
    $results.Name | Should Be Describing
    $results.Cases.Count | Should Be 1 # Why can't I use $results.Cases | Should Count 1? And why isn't it 2 like in the previous test?
    $results.Cases[0].Name | Should Be Given
    $results.Cases[0].Cases | Should Count 6
    $results.Cases[0].Cases[0] | Should Count 1
    $results.Cases[0].Cases[1] | Should Count 1
    $results.Cases[0].Cases[2] | Should Count 1
    $results.Cases[0].Cases[3] | Should Count 1
    $results.Cases[0].Cases[4] | Should Count 1
    $results.Cases[0].Cases[5] | Should Count 1
    $results.Cases[0].Cases[0].Name | Should Be "Fails if even"
    $results.Cases[0].Cases[1].Name | Should Be "Passes if less than 3"

    # validate the counts of the results
    $results.Passed | Should Be 4
    $results.Failed | Should Be 2
    $results.Cases[0].Passed | Should Be 4
    $results.Cases[0].Failed | Should Be 2
    $results.Cases[0].Cases[0].Passed | Should Be 1
    $results.Cases[0].Cases[1].Passed | Should Be 1
    $results.Cases[0].Cases[2].Failed | Should Be 1
    $results.Cases[0].Cases[3].Passed | Should Be 1
    $results.Cases[0].Cases[4].Passed | Should Be 1
    $results.Cases[0].Cases[5].Failed | Should Be 1

    # make sure that setup and teardown were called
    ($logMock.Calls |? { $_.Input -contains 'Setup' }).Count | Should Be 4 # Why isn't this 1? And why can't I use Should Count like in the previous test?
    ($logMock.Calls |? { $_.Input -contains 'TearDown' }).Count | Should Be 4 # Why isn't this 1? And why can't I use Should Count like in the previous test?
}
