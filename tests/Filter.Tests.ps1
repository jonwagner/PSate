$scriptPath = Split-Path -parent $PSCommandPath

Invoke-Tests "$scriptPath\Filter.Example.ps1" -Output Results | Should Count 4
Invoke-Tests "$scriptPath\Filter.Example.ps1" -Output Results -Filter A | Should Count 2
Invoke-Tests "$scriptPath\Filter.Example.ps1" -Output Results -Filter B | Should Count 2
Invoke-Tests "$scriptPath\Filter.Example.ps1" -Output Results -Filter *,1 | Should Count 2
Invoke-Tests "$scriptPath\Filter.Example.ps1" -Output Results -Filter *,2 | Should Count 2
Invoke-Tests "$scriptPath\Filter.Example.ps1" -Output Results -Filter A,1 | Should Count 1
Invoke-Tests "$scriptPath\Filter.Example.ps1" -Output Results -Filter B,2 | Should Count 1
