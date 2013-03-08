Enable-Mock | iex

try
{
    # create a test folder
    $testFolder = New-Item -Name "psate.test" -Path $env:TEMP -ItemType Directory -Force

    # test the standard creation
    New-TestProject MyTests -Path $testFolder
    "$testFolder\MyTests.ps1" | Should Exist
    "$testFolder\MyTests.Tests.ps1" | Should Exist

    # create the tests only
    New-TestProject OtherTests -Path $testFolder -OnlyTestFile
    "$testFolder\OtherTests.ps1" | Should Not Exist
    "$testFolder\OtherTests.Tests.ps1" | Should Exist

    # check the force parameter
    { New-TestProject MyTests -Path $testFolder } | Should Throw
}
finally
{
    # clean up the test folder
    $testFolder | Remove-Item -Recurse
}
