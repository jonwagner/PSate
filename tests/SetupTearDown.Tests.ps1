Enable-Mock | iex

MockContext {
    # do this quietly
    $logMock = Mock Write-TestLog -OutputMock {}

    # make sure the exceptions throw
    { TestSetup {} } | Should Throw "within a test context"
    { TestTearDown {} } | Should Throw "within a test context"

    Given "given" {
        TestSetup { "setup" }
        It "it1" { "it1" }
        It "it2" { "it2" }
        TestTearDown { "teardown" }
    }

    # make sure that setup/teardown were called in the right order
    $logMock.Calls |? Input |% Input | Should Be @('setup', 'it1', 'teardown', 'setup', 'it2', 'teardown')

    # make sure teardown happens even with an exception
    Given "given" {
        It "it1" { throw "exception" }
        TestTearDown { "teardown after exception" }
    }
    $logMock.Calls.Input | Should Contain "teardown after exception"
}
