Enable-Mock | iex

MockContext {
    # make this quiet
    $logMock = Mock Write-TestLog -OutputMock {}

    # run a test and look at the output
    $results = It "fails" -OutputResults {
        throw "exception"
    }

    # we should have an exception
    $results.Exception | Should Not Be Null
    $results.Exception | Should Be "exception"

    # the stack trace should be a little filtered
    $results.StackTrace | Should Match "exception"
    $results.StackTrace | Should Not Match "psate.psm1"
}