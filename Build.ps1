param (
    [string] $target = "default"
)

# import these before calling psake so the functions are available at the global level
Import-Module psake
Import-Module ..\PShould\PShould.psm1
Import-Module ..\PSMock\PSMock.psm1

Invoke-psake .\Build.psake.ps1 -taskList $target
