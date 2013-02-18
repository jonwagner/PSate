Enable-Mock | iex

MockContext {
    # do this quietly
    $logMock = Mock Write-TestLog -OutputMock {}

    $results = TestCase "ScriptPath" -OutputResults {
        $TestScriptPath | Should Match '\\PSate\\tests$'
    }

    $results.Failed | Should Be 0
}
