$psake.use_exit_on_error = $true

#########################################
# to build a new version
# 1. git tag 1.0.x
# 2. build package
#########################################

properties {
    $baseDir = $psake.build_script_dir
    $version = git describe --abbrev=0 --tags
    $changeset = (git log -1 $version --pretty=format:%H)
}

Task default -depends Test
Task Package -depends Test, Version-Module, Package-Nuget, Unversion-Module { }

# run tests
Task Test { 
    Import-Module .\PSate.psm1 -Force

    Get-ChildItem tests -Filter "*.Tests.ps1" -Recurse:$Recurse |% {
        try {
            $scriptName = $_.FullName
            & $_.FullName
            Write-Host "PASS: $($_.FullName)"
        }
        catch {
            Write-Host "FAIL: $scriptName"

            throw $_
        }
    }
}

# package the nuget file
Task Package-Nuget {

    # make sure there is a build directory
    if (Test-Path "$baseDir\build") {
        Remove-Item "$baseDir\build" -Recurse -Force
    }
    mkdir "$baseDir\build"

    # pack it up
    nuget pack "$baseDir\PSate.nuspec" -OutputDirectory "$baseDir\build" -NoPackageAnalysis -version $version
}

# update the version number in the file
Task Version-Module {
    (Get-Content "$baseDir\PSate.psm1") |
      % {$_ -replace '\$version\$', "$version" } |
      % {$_ -replace '\$changeset\$', "$changeset" } |
      Set-Content "$baseDir\PSate.psm1"
}

# clear out the version information in the file
Task Unversion-Module {
    git checkout "$baseDir\PSate.psm1"
}