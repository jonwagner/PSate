<#
    PSate - copyright(c) 2013 - Jon Wagner
    See https://github.com/jonwagner/PSate for licensing and other information.
    Version: $version$
    Changeset: $changeset$
#>

# maintain a current test context so that setup works properly
$testContext = $null
$testFilter = $null
$testOutput = 'Log'

# automatically enable mocking
if (Get-Command Enable-Mock -ErrorAction SilentlyContinue) {
    Enable-Mock | iex
}

# see if mocking is enabled, if not, then mock mocking (oh my)
if (!(Get-Command MockContext -ErrorAction SilentlyContinue)) {
    function MockContext {
        param ([scriptblock] $MockBlock)

        # NOTE: if you name this $ScriptBlock, then you modify the module variable ScriptBlock
        # and end up with a stack overflow.
        & $MockBlock
    }
}

<#
.Synopsis
    Invokes all of the .Tests.ps1 test scripts in a given path.

.Description
    Invokes all of the .Tests.ps1 test scripts in a given path. The tests are run as one test run,
    and the results are output.

.Parameter Path
    The path to use to look for the test scripts. The default is the current working directory.

.Parameter Recurse
    Tells Invoke-Tests to look in child directories.

.Parameter Filter
    Tells Invoke-Tests to only invoke the tests matching the description filters.
    The filter is an array of match strings that are applied as the test cases are run.
    The first string matches the top-level test descriptions, the second string matches second-level
    descriptions, etc.

    For example, if you have the following test hierarchy:

    Describing "FileWatcher" { 
        Given "one file" { It "watches it" {...}
        Given "two files" { It "watches them" { ... } 
    }
    Describing "FileScrubber" { Given "a file" { It "scrubs them" { ... } }

    -Filter "Watcher"
    Matches all of the FileWatcher tests.

    -Filter "Watcher","one"
    -Filter *,"one"
    Both of these matches only the "one file" tests.

    -Filter *,*,"them"
    Matches both the "watches them" and "scrubs them" tests.

.Parameter Output
    Tells Invoke-Tests how to output the results. The default is Log.

    * Quiet - no output is given
    * Log - a text representation of the test results is output
    * Results - the test results object is output
    * NUnit - an NUnit-compatible test result XML structure is output

.Parameter NUnit
    Outputs an NUnit-compatible test result XML structure to the given file, 
    in addition to the data that is output to the stream.

.Parameter ExitCode
    Instructs Invoke-Tests to exit the process with the number of failed tests.
    This is a good way to indicate failure to an automated build process.

.Parameter ResultsVariable
    If specified, the name of a variable to assign the results of the operation.

.Example
    Invoke-Tests

    Invokes all of the tests in the current path.

.Example
    Invoke-Tests .\Tests -Recurse

    Invokes all of the tests in the Tests folder and below.

.Example
    Invoke-Tests -Recurse -NUnit TestResults.xml -ExitCode

    Invokes all of the tests in the current directory and below, and 
    outputs TestResults.xml to a file, then exits with the number of failed tests.
    This is a good example of integrating with a automated build process.

.Example
    Invoke-Tests -Output Log -ResultsVariable Results

    Invokes the test cases, outputting the log to the stream and assigning the results
    to the global variable $Results.

.Link
    Test-Case
#>
# Invoke all of the tests in a given path
function Invoke-Tests {
    param (
        [Alias('p')]
        [string] $Path = '.',
        [Alias('f')]
        [string[]] $Filter,
        [ValidateSet('Quiet', 'Log', 'Results', 'NUnit')]
        [Alias('o')]
        [string] $Output = 'Log',
        [Alias('n')]
        [string] $NUnit,
        [Alias('x')]
        [switch] $ExitCode,
        [Alias('r')]
        [switch] $Recurse,
        [string] $ResultsVariable
    )

    try {
        # initialize the global variables
        $testFilter = $Filter
        $testOutput = $Output

        # invoke the tests
        $results = Test-Case "Invoking" (Resolve-Path $Path) -Group -OutputResults {
            # find all of the child-items that match
            Get-ChildItem $Path -Filter "*.Tests.ps1" -Recurse:$Recurse |% {
                Test-Case "Invoking" $_.FullName -Group { 
                    $scriptName = $_.FullName
                    try {
                        . $_.FullName 
                    }
                    catch {
                        Write-Error "Exception while running $scriptName"
                        throw $_
                    }
                }
            }
        }

        # write the final results
        if ($results.Failed -gt 0) {
            $color = 'Red'
        }
        else {
            $color = 'Green'
        }
        Write-TestLog "$($results.Count) tests. $($results.Passed) passed, $($results.Failed) failed." $color

        # output the results if requested
        if ($Output -eq 'Results') { $Results }
        elseif ($Output -eq 'NUnit') { $Results | Format-AsNUnit }

        # if they want to write nunit to a file, we can do that too
        if ($NUnit) {
            $Results | Format-AsNUnit | Set-Content $NUnit
        }

        # if they want the results in a variable, do that
        if ($ResultsVariable) {
            "`$global:$ResultsVariable = `$Results" | iex
        }

        # set the exit code if requested
        if ($ExitCode) {
            $host.SetShouldExit($results.Failed)
        }
    }
    finally {
        $testFilter = $null
        $testOutput = 'Log'
    }
}

<#
.Synopsis
    Runs a set of test cases.

.Description
    Runs a set of test cases. In general, you will not call this directly, but you would use one of the following:
    TestFixture, TestCase, TestScope, Describing, Given, It.

.Parameter Call
    The name of the method used to call the case. This is used for display purposes only.

.Parameter Name
    The name of the test group or case. This is used for display, and for filtering when used with Invoke-Tests.

.Parameter ScriptBlock
    The test script block to execute. This can contain and Setup, TearDown blocks, as well as test code to execute.

.Parameter Group
    This switch controls whether the ScriptBlock is executed to setup the case or to run the test case.
    For grouping constructs like TestScope, TestFixture, Describing, Given, the Group switch should be set, 
    and the ScriptBlock is executed immediately.
    For test constructs like TestCase and It, the Group switch should not be set, and the ScriptBlock
    is deferred until the outer group Setup blocks are executed.
    This is all handled for you if you use one of the other functions.

.Example
    Test-Case "Math" -Group {
        Test-Case "Add" {
            1 + 1 | Should Be 2
        }

        Test-Case "Subtract" {
            1 - 1 | Should Be 0
        }
    }

    Defines a group of Math test cases, with an Add and a Subtract case.

.Link
    TestFixture
.Link
    TestCase
.Link
    TestScope
.Link
    Describing
.Link
    Given
.Link
    It
#>
function Test-Case {
    param (
        [Parameter(Mandatory=$true)] [string] $Call,
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock,
        [switch] $Group,
        [switch] $OutputResults
    )

    # manage the script path for the current context
    $local:oldScriptPath = $global:TestScriptPath
    if (!$local:oldScriptPath) {

        # find the closest point in the stack not in our modules
        $invocation = (Get-PSCallStack | Where { $_.Location -notmatch '^((PSate)|(PSMock)).psm1:' } | Select -First 1)

        if ($invocation -and $invocation.ScriptName) {
            $global:TestScriptPath = Split-Path -Parent $invocation.ScriptName
        }
    }

    # save the test context to restore later
    $local:oldTestContext = $global:testContext

    try {
        if ($Group) {
            # if we don't have a current test context, then create one
            if (!$testContext) {
                $testContext = New-TestContext $Call $Name $testContext -Group
                Setup-Group $testContext $ScriptBlock
                Run-Group $testContext $ScriptBlock
            }
            elseif (!$testContext.IsSetUp) {
                # the parent isn't set up yet, so create a new context and register with the parent
                $testContext = New-TestContext $Call $Name $testContext -Group
                $testContext.Parent.Cases += $testContext

                Setup-Group $testContext $ScriptBlock
            }
            else {
                Run-Group $testContext $ScriptBlock

                # on to the next test
                $testContext.Parent.CurrentIndex++
            }
        }
        else {
            if (!$testContext) {
                # root level test case
                $testContext = New-TestContext $Call $Name $testContext
                Execute-Test $testContext $ScriptBlock
            }
            elseif (!$testContext.IsSetUp) {
                # the parent isn't set up yet, so create a new context and register with the parent
                $testContext = New-TestContext $Call $Name $testContext
                $testContext.Index = $testContext.Parent.Cases.Length
                $testContext.Parent.Cases += $testContext
                $testContext.IsSetUp = $true
            }
            else {
                # phase 2 - we are running the parent block once for each test case
                # if the CurrentIndex = TestIndex, then it's time to run this test
                if ($testContext.Parent.CurrentIndex -eq $testContext.Parent.TestIndex) {
                    Execute-Test $testContext $ScriptBlock
                }

                # on to the next test
                $testContext.Parent.CurrentIndex++
            }
        }

        # output the results if they asked for it
        if ($OutputResults) {
            return $testContext
        }
    }
    finally {
        $global:testContext = $local:oldTestContext
        $global:TestScriptPath = $local:oldScriptPath
    }
}

# Setup a group of tests
function Setup-Group {
    param (
        $Context,
        [scriptblock] $ScriptBlock
    )

    # run the script once to set it up
    Execute-ScriptBlock $Context $ScriptBlock

    # we are set up now, so initialize the variables
    $Context.IsSetUp = $true
}

# Run a group of tests
function Run-Group {
    param (
        $Context,
        [scriptblock] $ScriptBlock
    )

    try {
        if ($Context.Parent.CurrentIndex -eq $Context.Parent.TestIndex) {

            # this is a container, so run the sub-tests
            Write-TestLog "$($Context.Call) $($Context.Name)" White

            # now it is set up, run it once per case
            $Context.TestIndex = 0
            foreach ($case in $Context.Cases) {
                $Context.CurrentIndex = 0

                Execute-ScriptBlock $case $ScriptBlock

                $Context.TestIndex++
            }
        }
    }
    finally {
        # accumulate the results
        $Context.Time = $Context.Cases |% { $_.Time } | Measure-Object -Sum |% { $_.Sum }
        $Context.Count = $Context.Cases |% { $_.Count } | Measure-Object -Sum |% { $_.Sum }
        $Context.Passed = $Context.Cases |% { $_.Passed } | Measure-Object -Sum |% { $_.Sum }
        $Context.Failed = $Context.Cases |% { $_.Failed } | Measure-Object -Sum |% { $_.Sum }
        $Context.Success = ($Context.Failed -eq 0)
        if ($Context.Success) {
            $Context.Result = 'Success'
        }
        else {
            $Context.Result = 'Failure'
        }
    }
}

# Execute a single test.
function Execute-Test {
    param (
        $Context,
        [scriptblock] $ScriptBlock
    )

    # execute the case with measurement and capture the error
    $time = Measure-Command {
        try {
            Execute-ScriptBlock $Context $ScriptBlock

            # hooray
            $Context.Success = $true
            $Context.Result = 'Success'
            $Context.Passed = $Context.Passed + 1
        }
        catch {
            # boo
            $Context.Exception = $_
            $Context.StackTrace = (Get-FilteredStackTrace $_)
            $Context.Result = 'Failure'
            $Context.Success = $false
            $Context.Failed = $Context.Failed + 1
        }
        finally {
            # auto-teardown - clean up any folders and files
            [Array]::Reverse($Context.Items)
            $Context.Items | Remove-Item -Force -Recurse -ErrorAction Continue
            $Context.Items = @()
        }
    }
    $Context.Time = $time.TotalSeconds

    # output the results
    $Context.Count = $Context.Count + 1
    if ($Context.Success) {
        Write-TestLog "[+] $($Context.Call) $($Context.Name) [$(Format-Time $Context.Time)]" Green
    }
    else {
        Write-TestLog "[-] $($Context.Call) $($Context.Name) [$(Format-Time $Context.Time)]" Red
        Write-TestLog "    $($Context.Exception)" Red
        $Context.StackTrace |% { Write-TestLog  "    $_" Red }
    }
}

function Execute-ScriptBlock {
    param (
        $Context,
        [scriptblock] $ScriptBlock
    )

    # create a mock context, test context, and variable scope
    MockContext {
        try {
            $testContext = $Context

            & $ScriptBlock | Write-TestLog
        }
        finally {
            $testContext = $Context.Parent
        }
    }
}

################################################
# Setup and TearDown
################################################
<#
.Synopsis
     Defines a Setup block that is executed before each inner test.

.Description
    Defines a Setup block that is executed before each inner test. 
    A Setup block can be added at any level, and is executed once for each inner test block.

.Parameter ScriptBlock
    The setup block that is used to initialize each test case.

.Example
    Describing "Math" {
        Given "1 and 1" {
            TestSetup {
                $x = 1
                $y = 1
            }

            It "adds them" {
                $x + $y | Should Be 2
            }

            It "subtracts them" {
                $x - $y | Should Be 0
            }
        }
    }

    Creates a test case with a TestSetup block. The TestSetup block is run once for each It block.

.Link
    TestFixture
.Link
    TestCase
.Link
    TestScope
.Link
    Describing
.Link
    Given
.Link
    It
.Link
    TestTearDown
#>
function TestSetup {
    param (
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock
    )

    if (!$testContext) {
        throw "Test Setup can only be called from within a test context"
    }
    if ($testContext.IsSetUp) {
        . $ScriptBlock
        return
    }
    if (!$testContext.Group) {
        throw "Test Setup can only be called from within a grouping test context"
    }
    if ($testContext.Setup) {
        throw "There is already a Setup script for $($testContext.Call) $($testContext.Name)"
    }
}

<#
.Synopsis
    Defines a TearDown block that is executed after each inner test.

.Description
    Defines a TearDown block that is executed after each inner test. 
    A TearDown block can be added at any level, and is executed once for each inner test block.
    The TearDown block is guaranteed to execute regardless of the outcome of the test.

.Parameter ScriptBlock
    The teardown block that is used to initialize each test case.

.Example
    Describing "FileStuff" {
        Given "a temp file" {
            TestSetup {
                $file = New-Item -Name "temp.file" -Path $env:temp -Type File -Force
            }

            It "does something with the file" {
                # something
            }

            TestTearDown {
                $file | Remove-Item -Force
            }
        }
    }

    Creates a test case with a TestTearDown block. The TestTearDown block is run once after each It block.

.Link
    TestFixture
.Link
    TestCase
.Link
    TestScope
.Link
    Describing
.Link
    Given
.Link
    It
.Link
    TestSetup
#>
function TestTearDown {
    param (
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock
    )

    if (!$testContext) {
        throw "Test TearDown can only be called from within a test context"
    }
    if ($testContext.IsSetUp) {
        . $ScriptBlock
        return
    }
    if (!$testContext.Group) {
        throw "Test TearDown can only be called from within a grouping test context"
    }
    if ($testContext.TearDown) {
        throw "There is already a TearDown script for $($testContext.Call) $($testContext.Name)"
    }
}

################################################
# Resource helper functions
################################################

<#
.Synopsis
    Creates and returns a temp folder that is automatically deleted at the end of the test.

.Description
    Creates and returns a temp folder that is automatically deleted at the end of the test.
    Any files created in the folder are also deleted at the end of the test.

.Example
    Describing "FileStuff" {
        Given "nothing" {

            It "can create a test folder" {
                # create a folder
                $folder = New-TestFolder

                # do something with it
            }
        }
    }

    Creates a test case where a temporary folder is created. The folder and its contents are 
    automatically deleted in the TearDown phase of the test case.

.Link
    New-TestFile
.Link
    Register-TestCleanup
#>
function New-TestFolder {

    if (!$testContext) { throw "Cannot create a TestFolder outside of a test context." }

    # create a new folder name
    $guid = [Guid]::NewGuid().ToString()

    # create the folder and register it for cleanup
    New-Item -Name $guid -Path $env:Temp -Type Container -Force | Register-TestCleanup -PassThru
}

<#
.Synopsis
    Creates and returns a temp file that is automatically deleted at the end of the test.

.Description
    Creates and returns a temp file that is automatically deleted at the end of the test.

.Parameter Name
    The name of the file to create. If not specified, a guid is used as the filename.

.Parameter Path
    The name of the directory to create the file in. If not specified, the current temp folder is used.

.Example
    Describing "FileStuff" {
        Given "nothing" {

            It "can create a test file" {
                # create a file
                $file = New-TestFile

                # do something with it
            }
        }
    }

    Creates a test case where a temporary file is created. The file and its contents are 
    automatically deleted in the TearDown phase of the test case.

.Link
    New-TestFolder
.Link
    Register-TestCleanup
#>
function New-TestFile {
    param (
        [string] $Name,
        [string] $Path
    )

    if (!$testContext) { throw "Cannot create a TestFile outside of a test context." }

    # if no name, then use a guid
    if (!$Name) {
        $Name = [Guid]::NewGuid().ToString()
    }

    # if no path, then use the temp folder
    if (!$Path) {
        $Path = $env:Temp
    }

    # create a file with the given name and register it for cleanup
    New-Item -Name $Name -Path $Path -Type File -Force | Register-TestCleanup -PassThru
}

<#
.Synopsis
    Registers the given object to automatically get deleted at the end of the test.

.Description
    Registers the given object to automatically get deleted at the end of the test.
    The object and all of its contents are automatically deleted.

.Parameter Object
    The object to register for cleanup.

.Parameter PassThru
    If this switch is set, the object is automatically output to the stream.

.Example
    Describing "RegistryStuff" {
        Given "nothing" {

            It "can create a test registry key" {
                # create a file
                $reg = new-item -path hkcu:\Environment\TestNew | Register-TestCleanup -PassThru

                # do something with it
            }
        }
    }

    Creates a test case where a temporary registry key is created. The key and its contents are 
    automatically deleted in the TearDown phase of the test case.

.Link
    New-TestFolder
.Link
    New-TestFile
#>
function Register-TestCleanup {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [object[]] $Object,
        [switch] $PassThru
    )

    process {
        
        if (!$testContext) { throw "Cannot register for test cleanup outside of a test context." }

        $testContext.Items += $Object

        # if working in passthru mode, output the object
        if ($PassThru) {
            $Object
        }
    }
}

################################################
# Test Context functions
################################################

# Creates a new testcontext and initializes its members properly
function New-TestContext {
    param (
        [string] $Call,
        [string] $Name,
        $Parent,
        [switch] $Group
    )

    $context = @{
        "IsSetUp" = $false

        "Call" = $Call
        "Name" = $Name
        "Parent" = $Parent
        "Group" = $Group
        "Cases" = @()

        # cleanup items
        "Items" = @()

        # results
        "Success" = $null
        "Time" = $null
        "Exception" = $null
        "Count" = 0
        "Passed" = 0
        "Failed" = 0
    }

    if ($Parent) {
        $context.Depth = $Parent.Depth + 1
    }
    else {
        $context.Depth = 0
    }

    return $context
}

################################################
# Logging and output functions
################################################

# properly formats a string for output into the test log
function Write-TestLog {
    param (
        [Parameter(ValueFromPipeline=$true)][string[]] $Object,
        [consolecolor] $Color = 'Yellow'
    )

    process {
        if ($testOutput -eq 'Log') {
            "$(" " * $testContext.Depth * 2)$Object" | Write-Host -ForegroundColor $Color
        }
    }
}

################################################
# NUnit Output functions
################################################

# invokes a string template with replacements
function Invoke-Template {
    param (
        $Data,
        [string] $template
    )

    $Data |% { $template -replace '"','`"' -replace '^`"','"' -replace '`"$','"' | iex }
}

# formats a result object as an NUnit output
function Format-AsNUnit {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)] $TestResults
    )

    Invoke-Template $TestResults $testResultsTemplate
}

$testResultsTemplate = @'
"
<test-results name="PSate" total="$($_.Count)" errors="0" failures="$($_.Failed)" not-run="0" inconclusive="0" ignored="0" skipped="0" invalid="0" date="$(Get-Date -format "yyyy-MM-dd")" time="$(Get-Date -format "HH:mm:ss")">
    $(Invoke-Template (Get-WmiObject Win32_OperatingSystem) $environmentTemplate)

    <culture-info 
        current-culture="$(([System.Threading.Thread]::CurrentThread.CurrentCulture).Name)" 
        current-uiculture="$(([System.Threading.Thread]::CurrentThread.CurrentCulture).Name)" 
    />

	$(Invoke-Template $_ $testSuiteTemplate)
</test-results>
"
'@

$environmentTemplate = @'
"
    <environment 
        nunit-version="2.5.8.0" 
        clr-version="$([System.Environment]::Version)" 
        os-version="$($_.Version)"
        platform="$($_.Name)"
        cwd="$((Get-Location).Path)"
        machine-name="$($env:ComputerName)"
        user="$($env:UserName)"
        user-domain="$($env:UserDomain)"
    />
"
'@

$testSuiteTemplate = @'
"
    <test-suite type="Powershell" name="$($_.Name)" executed="True" result="$($_.Result)" success="$($_.Success)" time="$($_.Time)" asserts="$($_.Failed)">
    <results>
        $($_.Cases |? { $_.Cases.Length -gt 0 } |% { Invoke-Template $_ $testSuiteTemplate })
        $($_.Cases |? { $_.Cases.Length -eq 0 } |% { Invoke-Template $_ $testCaseTemplate })
    </results>
    </test-suite>
"
'@

$testCaseTemplate = @'
"
    <test-case name="$($_.Name)" executed="True" result="$($_.Result)" success="$($_.Success)" time="$($_.Time)" asserts="$($_.Failed)">
        $($_ |? { $_.Failed -gt 0 } |% { Invoke-Template $_ $testCaseFailureTemplate })
        $($_.Cases |% { Invoke-Template $_ $testCaseTemplate })
    </test-case>
"
'@

$testCaseFailureTemplate = @'
"
	    <failure>
		    <message><![CDATA[$($_.Exception.ToString())]]></message>
		    <stack-trace><![CDATA[$_.StackTrace]]></stack-trace>
	    </failure>
"
'@

################################################
# Internal Utility functions
################################################

# Make the number of milliseconds readable
function Format-Time {
    param (
        $Seconds
    )

    if ($Seconds -gt 0.99) {
        $time = [math]::Round($Seconds, 2)
        $unit = "s"
    }
    else {
        $time = [math]::Floor($Seconds * 1000)
        $unit = "ms"
    }
    return "$time $unit"
}

# Filter a stacktrace and rip out the PSST lines to make it more readable
function Get-FilteredStackTrace {
    param (
        $Exception
    )

    if ($PSVersionTable.PSVersion.Major -lt 3) {
        $Exception
    }
    else {
        $Exception.ScriptStackTrace.Split("`n") |
            ? { $_ -notmatch 'PSate.psm1:' } |
            ? { $_ -notmatch 'PShould.psm1:' } |
            ? { $_ -notmatch 'PSMock.psm1:' } |
            ? { $_ -notmatch 'psake.psm1:' }
    }
}

################################################
# TDD-style functions
################################################

<#
.Synopsis
    Groups a set of Test Cases

.Description
    Groups a set of TestCases under a given name.

.Example
    TestFixture "TheScriptToTest" {
        TestCase "The Test" {
            Do-Something | Should Be "Work"
        }
    }

    Defines a test fixture and a case in the fixture.

.Example
    TestFixture "TheScriptToTest" {
        TestFixture "SubGroup" {
            TestCase "The Test" {
                Do-Something | Should Be "Work"
            }
        }
    }

    Defines a test fixture, a sub-group and a case in the fixture.
#>
function TestFixture {
    param (
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock,
        [switch] $OutputResults
    )

    Test-Case "Fixture" @args @PSBoundParameters -Group
}

<#
.Synopsis
    Defines a Test Case to execute.

.Description
    Defines a Test Case to execute.

.Example
    TestFixture "TheScriptToTest" {
        TestCase "The Test" {
            Do-Something | Should Be "Work"
        }
    }

    Defines a test fixture and a case in the fixture.
#>
function TestCase {
    param (
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock,
        [switch] $OutputResults
    )

    Test-Case "Case" @args @PSBoundParameters
}

################################################
# BDD-style functions
################################################
<#
.Synopsis
    Groups a set of Test Cases

.Description
    Groups a set of TestCases under a given name.

.Example
    TestScope "TheScriptToTest" {
        Describing "TheFunctionToTest" {
            Given "SomeSetup" {
                It "does something" {
                    Do-Something | Should Be "Work"
                }
            }
        }
    }

    Defines a BDD-style test fixture and a case in the fixture.
#>
function TestScope {
    param (
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock,
        [switch] $OutputResults
    )

    Test-Case "Scope" @args @PSBoundParameters -Group
}

<#
.Synopsis
    Groups a set of Test Cases

.Description
    Groups a set of TestCases under a given name.

.Example
    TestScope "TheScriptToTest" {
        Describing "TheFunctionToTest" {
            Given "SomeSetup" {
                It "does something" {
                    Do-Something | Should Be "Work"
                }
            }
        }
    }

    Defines a BDD-style test fixture and a case in the fixture.
#>
function Describing {
    param (
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock,
        [switch] $OutputResults
    )

    Test-Case "Describing" @args @PSBoundParameters -Group
}

<#
.Synopsis
    Groups a set of Test Cases

.Description
    Groups a set of TestCases under a given name.

.Example
    TestScope "TheScriptToTest" {
        Describing "TheFunctionToTest" {
            Given "SomeSetup" {
                It "does something" {
                    Do-Something | Should Be "Work"
                }
            }
        }
    }

    Defines a BDD-style test fixture and a case in the fixture.
#>
function Given {
    param (
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock,
        [switch] $OutputResults
    )

    Test-Case "Given" @args @PSBoundParameters -Group
}

<#
.Synopsis
    Defines a Test Case to execute.

.Description
    Defines a Test Case to execute.

.Example
    TestScope "TheScriptToTest" {
        Describing "TheFunctionToTest" {
            Given "SomeSetup" {
                It "does something" {
                    Do-Something | Should Be "Work"
                }
            }
        }
    }

    Defines a BDD-style test fixture and a case in the fixture.
#>
function It {
    param (
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [scriptblock] $ScriptBlock,
        [switch] $OutputResults
    )

    Test-Case "It" @args @PSBoundParameters
}

################################################
# Test template creation
################################################

$systemUnderTestTemplate =
@'
"
function Add-Numbers {
    param ([int] `$x, [int] `$y)
    return `$x + `$y
}
"
'@

$testFileTemplate =
@'
"TestScope "$($_.TestScriptName).ps1" {

    # enable PSMock (comment this out if not using mocks)
    Enable-Mock | iex

    # import the script
    . `$TestScriptPath\$($_.TestScriptName).ps1

    Describing "Calculator" {

        Given "two numbers" {
            TestSetup {
                Mock Add-Numbers { 90 } -When {`$x -eq 0}
                Mock Add-Numbers { 91 } -When {`$y -eq 0}
            }

            It "Add-Numbers Normal" {
                Add-Numbers 1 2 | should be 3
            }

            It "Add-Numbers With X=0" {
                Add-Numbers 0 2 | should be 90
            }

            It "Add-Numbers With Y=0" {
                Add-Numbers 1 0 | should be 91
            }
        }
    }
}
"
'@

<#
.Synopsis
    Generates a Test Project template with two files: One that defines a function and another one that contains its tests.
.Description
    Generates a Test Project template with two files: One that defines a function and another one that contains its tests.
.Example
    New-TestProject -filename "pruebacontemplate"

    Creates .\pruebacontemplate.ps1 and .\pruebacontemplate.Tests.ps1

.Example
    New-TestProject -filename "pruebacontemplate" -Path "c:\zz\x" -OnlyTestFile

    Creates c:\zz\x\pruebacontemplate.Tests.ps1

.Parameter Filename
    The name of the test file to generate. New-TestProject will create Filename.ps1 and Filename.Tests.ps1.

.Parameter Path
    The path to place the test files. Defaults to the current path.

.Parameter OnlyTestFile
    Add this switch to only create the test file and not the script file. Useful when adding tests to an existing script.

.Parameter Force
    Enables New-TestProject to overwrite existing files.
#>
function New-TestProject
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [String]
        $Filename,

        [Parameter(Position=1)]
        [String]
        $Path = '.',

        [switch]
        $OnlyTestFile,

        [switch] $Force
    )

    # don't let people accidentally overwrite their code
    $NoClobber = !($Force)

    $parameters = @{ "TestScriptName" = $Filename }

    if (!$OnlyTestFile) {
        Invoke-Template $parameters $systemUnderTestTemplate | Out-File (Join-Path $Path "$Filename.ps1") -Encoding ascii -NoClobber:$NoClobber
    }

    Invoke-Template $parameters $testFileTemplate | Out-File (Join-Path $Path "$Filename.Tests.ps1") -Encoding ascii -NoClobber:$NoClobber
}

################################################
# Exports
################################################
Export-ModuleMember Invoke-Tests, Test-Case, Format-AsNUnit, 
    New-TestFolder, New-TestFile, Register-TestCleanup,
    TestSetup, TestTearDown,
    TestFixture, TestCase,
    TestScope, Describing, Given, It,
    New-TestProject