Enable-Mock | iex

# verify that variable scopes behave as expected
$script:value = "script"
$script:value | Should Be "script"

# root level test cases should have their own scope
TestCase "TestCase" {
    $value = "TestCase"
    $value | Should Be "TestCase"
}
$script:value | Should Be "script"

# at the BEGINNING of any block, the variable should be as expeected
Describing "Describing" {
    $script:value | Should Be "script"
    $value = "Describing"
    $value | Should Be "Describing"

    Given "Given" {
        $value | Should Be "Describing"
        $value = "Given"
        $value | Should Be "Given"

        It "It" {
            $value | Should Be "Given"
            $value = "It"
            $value | Should Be "It"
        }
        $value | Should Be "Given"

        It "It2" {
            $value | Should Be "Given"
            $value = "It2"
            $value | Should Be "It2"
        }
        $value | Should Be "Given"
    }
    $value | Should Be "Describing"
}
$script:value | Should Be "script"