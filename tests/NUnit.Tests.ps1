Enable-Mock | iex

MockContext {
    # make this quiet
    $logMock = Mock Write-TestLog -OutputMock {}

    # run a test and look at the output
    $results = Describing "Describing" -OutputResults {
        Given "Given" {
            It "succeeds" {}
            It "fails" { throw "exception" }
        }
    }

    # load it into xml
    [xml]$nunit = Format-AsNUnit $results

    $testResults = $nunit['test-results']
    $testResults.name | Should Be Psate
    $testResults.total | Should Be 2
    $testResults.errors | Should Be 0
    $testResults.failures | Should Be 1

    $describing = $testResults['test-suite']
    $describing.name | Should Be Describing
    $describing.executed | Should Be True
    $describing.result | Should Be Failure
    $describing.success | Should Be False
    $describing.asserts | Should Be 1

    $given = $describing.results['test-suite']
    $given.name | Should Be Given
    $given.executed | Should Be True
    $given.result | Should Be Failure
    $given.success | Should Be False
    $given.asserts | Should Be 1

    $pass = $given.results.'test-case'[0]
    $pass.name | Should Be succeeds
    $pass.executed | Should Be True
    $pass.result | Should Be Success
    $pass.success | Should Be True
    $pass.asserts | Should Be 0

    $fail = $given.results.'test-case'[1]
    $fail.name | Should Be fails
    $fail.executed | Should Be True
    $fail.result | Should Be Failure
    $fail.success | Should Be False
    $fail.asserts | Should Be 1
}