# our test case that we can mock an internal function

function Get-Number {
    "Enter a number:"
    [int] $i = Read-Host
    $i
}

function Add-Numbers {
    return (Get-Number) + (Get-Number)
}
