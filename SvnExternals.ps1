function SvnExt {
    if ($args) {
        Push-Location
        $gitRootPaths = Get-ChildItem -Recurse -Force -Filter .git
        foreach($gitRoot in $gitRootPaths) {
            if (Test-Path ($gitRoot.FullName + "\svn")) {
                Set-Location $gitRoot.Parent.FullName
                if ($svnExtSupportedCommands.git -Contains $args[0]) {
                    DisplayCommandInfo("git", $args)
                    & git $args
                    continue
                }
                else {
                    if ($svnExtSupportedCommands.gitsvn -contains $args[0]) {
                        DisplayCommandInfo("git svn", $args)
                        & git svn $args
                        continue
                    }
                    break
                }
            }
        }
        Write-Host
        Pop-Location
    }
}

function private:DisplayCommandInfo($cmd, $args){
    Write-Host
    Write-Host " Directory: "(Get-Location)
    Write-Host "   Command:" $cmd $args
    Write-Host
}

$svnExtSupportedCommands = @{
    gitsvn = @(
        "fetch",
        "rebase",
        "dcommit"
        )
    git = @(
        "status",
        "checkout"
        )
}