Enable-Mock | iex

MockContext {
    # do this quietly
    Mock Write-TestLog { }

    # make sure the exceptions throw
    { TestSetup {} } | Should Throw "within a test context"
    { TestTearDown {} } | Should Throw "within a test context"

    # make sure teardown happens in nested groups
    $script:calls = @()
    Describing "Describing" {
        Given "given" {
            It "ita1" { $script:calls += "ita1"; }
            It "ita2" { $script:calls += "ita2"; }
        }
        Given "given2" {
            It "itb1" { $script:calls += "itb1"; }
            It "itb2" { $script:calls += "itb2"; }
        }
    }
    $calls | Should Be @('ita1', 'ita2', 'itb1', 'itb2')

    $script:calls = @()
    Given "given" {
        TestSetup { $script:calls += "setup" }
        It "it1" { $script:calls += "it1" }
        It "it2" { $script:calls += "it2" }
        TestTearDown { $script:calls += "teardown" }
    }

    # make sure that setup/teardown were called in the right order
    $calls | Should Be @('setup', 'it1', 'teardown', 'setup', 'it2', 'teardown')

    # make sure teardown happens even with an exception
    $script:calls = @()
    Given "given" {
        TestSetup { $script:calls += "setup" }
        It "it1" { $script:calls += "it1"; throw "exception" }
        It "it2" { $script:calls += "it2"; throw "exception" }
        TestTearDown { $script:calls += "teardown" }
    }
    $calls | Should Be @('setup', 'it1', 'teardown', 'setup', 'it2', 'teardown')

    # make sure teardown happens in nested groups
    $script:calls = @()
    Describing "Describing" {
        TestSetup { $script:calls += "describing setup" }
        Given "given" {
            TestSetup { $script:calls += "setup" }
            It "it1" { $script:calls += "it1"; }
            It "it2" { $script:calls += "it2"; }
            TestTearDown { $script:calls += "teardown" }
        }
        Given "given2" {
            TestSetup { $script:calls += "given2 setup" }
            It "it1" { $script:calls += "given2 it1"; }
            It "it2" { $script:calls += "given2 it2"; }
            TestTearDown { $script:calls += "given2 teardown" }
        }
        TestTearDown { $script:calls += "describing teardown" }
    }
    $calls | Should Be @(
        'describing setup', 
            'setup', 'it1', 'teardown', 
            'setup', 'it2', 'teardown',
        'describing teardown',
        'describing setup', 
            'given2 setup', 'given2 it1', 'given2 teardown', 
            'given2 setup', 'given2 it2', 'given2 teardown',
        'describing teardown')
}
