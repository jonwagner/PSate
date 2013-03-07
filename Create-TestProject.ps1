$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
<#
.Synopsis
   Generates Test Project with  two files: One that defines a function and another one that contains its tests.
.DESCRIPTION
   Generates Test Project with  two files: One that defines a function and another one that contains its tests.
.EXAMPLE
    Create-TestProject  -filename "pruebacontemplate" -Path "c:\zz\x" 
.EXAMPLE
   Create-TestProject  -filename "pruebacontemplate" -Path "c:\zz\x" -OnlyTestFile
#>
function Create-TestProject
{
    [CmdletBinding()]
    Param
    (
        # Descripción de ayuda de Parám1
        [Parameter(Mandatory=$true,
                   Position=0)]
        [String]
        $filename,
        [Parameter(Mandatory=$true,
                   Position=1)]     
        [String]
        $Path,
        [Parameter(Position=2)]     
        [switch]
        $OnlyTestFile
    )
    try
    {
        if ($OnlyTestFile -eq $false){
            Get-Content "$scriptDirectory\SkeletonF.TXT" | Out-File "$path\$filename.ps1" -Encoding ascii
        }
        $skt_content=Get-Content "$scriptDirectory\Skeleton.TXT"     
        $skt_contentT=($skt_content -replace "var_internalscripname",  $filename)    
        $skt_contentT | Out-File "$path\$filename.Tests.ps1" -Encoding ascii
    }
    catch
    {
        throw

    }
}
