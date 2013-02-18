# PSate #

**PSate** (pronounced "sate" or "puh-sate"), meaning "to satisfy", is a test runner module for PowerShell.

PSate is part of the PSST PowerShell Suite for Testing:

* [PSMock - mocking for PowerShell](https://github.com/jonwagner/PSMock)
* [PShould - fluent assertions for PowerShell](https://github.com/jonwagner/PShould)
* [PSate - test runner for PowerShell](https://github.com/jonwagner/PSate)

## Examples ##

(Note: **should** below is from PShould)

Getting started TDD-style:

    TestFixture "Calculator" {
		TestSetup {
			$x = 1
			$y = 2
		}

        TestCase "Adds" {
            $x + $y | Should Be 3
        }

        TestCase "Subtracts" {
            $x - $y | Should Be -1
        }
    }

Getting started BDD-style:

    Describing "Calculator" {
		Given "1 and 2" {
			TestSetup {
				$x = 1
				$y = 2
			}
	
	        It "Adds" {
	            $x + $y | Should Be 3
	        }
	
	        It "Subtracts" {
	            $x - $y | Should Be -1
	        }
	    }
	}

Auto-tempfile support:

    Describing "FileStuff" {
        Given "nothing" {
            It "can create a test file" {
                # create a file
                $file = New-TestFile

                # do something with it

				# automatically cleaned up
            }
        }
    }

## Features ##

See the [PSate wiki](https://github.com/jonwagner/PSate/wiki) for full documentation.

* TDD- or BDD-style test cases
* Setup and TearDown support
* Run from Invoke-Tests or run individual tests (in ISE or command line)
* Works with or without PShould or PSMock
* Records test results, timings and execution stacks.
* Automatic management of folder, file, or other `New-Item` objects
* NUnit-compatible TestResults.xml output
* Integrates with automated build tools

# Getting PSate #

You can get PSate a variety of ways:

- PSGet - [http://psget.net/](http://psget.net)
	- Get PSGet
	- Install-Module -nugetpackageid PSate
	- PSate will be installed into as a global module
- NuGet - [http://nuget.org/packages/PSate](http://nuget.org/packages/PSate)
	- Install-Package PSate
	- PShould will be installed into your current project
- GitHub - [Download PSate.psm1](https://github.com/jonwagner/PSate/tree/master/PSate.psm1)
	- Copy the file to your modules folder or a local folder

## Credits ##

PShould was inspired by the great work by the [Pester](https://github.com/pester/Pester) team. See [[PSate v Pester]] for some differences between the two.
