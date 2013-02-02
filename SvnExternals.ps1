function SvnExt {
    if ($args) {
        Push-Location
        $gitRootPaths = Get-ChildItem -Recurse -Force -Filter .git
        foreach($gitRoot in $gitRootPaths) {
            if (Test-Path ($gitRoot.FullName + "\svn")) {
                Set-Location $gitRoot.Parent.FullName
                Write-Host
                Write-Host " Directory: "(Get-Location)
                if ($args[0] -eq "status") {
                    Write-Host "   Command:  git"$args
                    & git $args
                    continue
                }
                Write-Host "   Command:  git svn"$args
                & git svn $args
            }
        }
        Pop-Location
    }
}