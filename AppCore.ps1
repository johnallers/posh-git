function Get-RepositoryDirectory {
	$gitDir = (Get-GitDirectory)
	if ($gitDir -eq $NULL) {
		Write-Error "Not in a git repository."
		return
	}
	return ($gitDir | Split-Path -Parent)
}

function Test-SvnAvailable {
	try { svn --version > $null } catch { }
	return $?
}

function Get-SvnInfo($repoRoot = $(Get-RepositoryDirectory)) {
	if ($repoRoot -eq $null) {
		return
	}
	Push-Location $repoRoot
	(git svn info) |
	where {$_ -match ":" } | 
	Foreach-Object -begin {
			$result = @{}
		} -process {
			$result.Add($_.Substring(0, $_.IndexOf(":")),  $_.Substring($_.IndexOf(":")+1).Trim())
		} -end {
			$result
		}
	Pop-Location
}

function Test-SvnAuthentication {
	if (Test-SvnAvailable -ne $true) {
		Write-Error "svn is not available"
		return
	}
	$svnUrl = (Get-SvnInfo).get_Item("URL")
	try {svn info --non-interactive "$svnUrl" } catch {}
	Write-Warning "svn is not authenticated. Run `"svn info`" against the remote to authenticate."
	return $?
}

function Set-SvnExternalOnRemote($ExternalPath, $RemoteRepository) {
	
}

function Get-AppCoreDirectory {
	$repoRoot = (Get-RepositoryDirectory)
	$appCoreConfig = (git config --path --file (Join-Path "$repoRoot" ".gitthycotic") thycotic.appcore.dir) 2> $null
	if ($appCoreConfig -eq $null) {
		Write-Error "Repository is not configured for AppCore."
		return
	}
	$appCoreLocation = Join-Path $repoRoot $appCoreConfig -Resolve
	return Join-Path $appCoreLocation "Thycotic.AppCore"
}

function Mount-AppCore {
	$appCore = Get-AppCoreDirectory
	if (Test-Path $appCore -PathType Container) {
		Write-Warning "AppCore already mounted in this repository."
		return
	}
	$repoRoot = (Get-RepositoryDirectory)
	$appCoreRepo = (git config --path --file (Join-Path "$repoRoot" ".gitthycotic") thycotic.appcore.src) 2> $null
	if ($appCoreRepo -eq $null) {
		$appCoreRepo = "..\Thycotic.AppCore"
	}
	if ((Test-Path $appCoreRepo -PathType Container) -eq $false) {
		Write-Error "Unable to find AppCore at location $appCoreRepo. Use git-config to set 'thycotic.appcore.src' to specify an alternative location"
		return
	}
	$mklink = "$env:windir\System32\mklink.exe"
	Invoke-Expression "cmd /c mklink /j `"$appCore`" `"$appCoreRepo`"" > $null
	Write-Host "AppCore mounted."
}

function Dismount-AppCore {
	$appCore = Get-AppCoreDirectory
	if ((Test-Path $appCore -PathType Container) -eq $false) {
		Write-Warning "AppCore is not mounted."
		return
	}
	Invoke-Expression "cmd /c rmdir `"$appCore`""
	Write-Host "AppCore unmounted."
}

function Update-AppCore {
	$appCore = Get-AppCoreDirectory
	if ((Test-Path $appCore -PathType Container) -eq $false) {
		Write-Error "AppCore is not initialized. Use Mount-AppCore."
		return
	}
	Write-Host "Updating AppCore..."
	Push-Location $appCore
	git svn rebase
	Pop-Location
}

function Update-Repository {
	$repoRoot = (Get-RepositoryDirectory)
	Push-Location $repoRoot
	git svn rebase
	Update-AppCore 2> $null
	Pop-Location
}

function Show-Repository {
	$repoRoot = (Get-RepositoryDirectory)
	Push-Location $repoRoot
	Write-Host $repoRoot -ForegroundColor ([ConsoleColor]::Green)
	git svn info
	$appCore = Get-AppCoreDirectory
	if (Test-Path $appCore -PathType Container) {
		Write-Host $appCore -ForegroundColor ([ConsoleColor]::Green)
		Push-Location $appCore
		git svn info
		Pop-Location
	}
	Pop-Location
}

function Push-Repository {
	$appCore = Get-AppCoreDirectory
	if (Test-Path $appCore -PathType Container) {
		Push-Location $appCore
		git svn dcommit
		Pop-Location
	}
	Push-Location (Get-RepositoryDirectory)
	git svn dcommit
	Pop-Location
}

function Switch-Branch ($BranchName) {
	if ($BranchName -eq $null) {
		Write-Error "-BranchName not specified."
		return
	}
	if ($BranchName -eq "trunk" -or $BranchName -eq "master") {
		$localName = "master"
	} else {
		$localName = "local/$BranchName"
	}
	if ($BranchName -eq "trunk") {
		$BranchName = "master"
	}
	$repoPath = (Get-RepositoryDirectory)
	Push-Location $repoPath
	$branchExistsLocally = (git branch | where {$_.Trim().EndsWith($localName)} | measure).Count -gt 0
	if ($branchExistsLocally) {
		Write-Host "Checkout out existing branch"
		git checkout $localName
	}
	else {
		Write-Host "Checkout out new branch"
		git checkout -b $localName $BranchName
	}
	$mainCommitUrl = git svn dcommit --dry-run
	Write-Host "Main repository will be $mainCommitUrl"
	$appCore = Get-AppCoreDirectory
	Pop-Location
	if (Test-Path $appCore -PathType Container) {
		Push-Location $appCore
		$branchExistsLocally = (git branch | where {$_.Trim().EndsWith($localName)} | measure).Count -gt 0
		if ($branchExistsLocally) {
			Write-Host "Checkout out existing branch"
			git checkout $localName
		}
		else {
			Write-Host "Checkout out new branch"
			git checkout -b $localName $BranchName
		}
		$appCoreCommitUrl = git svn dcommit --dry-run
		Write-Host "AppCore repository will be $appCoreCommitUrl"
		Pop-Location
	}
}

function Get-AppCoreName {
	$repoRoot = (Get-RepositoryDirectory)
	$appCoreConfig = (git config --path --file (Join-Path "$repoRoot" ".gitthycotic") thycotic.appcore.dir) 2> $null
	Write-Host $appCoreConfig
}

function New-Branch ($BranchName) {
	if ($BranchName -eq $null) {
		Write-Error "-BranchName not specified."
		return
	}
	if ((Test-SvnAvailable) -ne $true) {
		Write-Error "svn required for this command. Use Chocolately to install: `"cinst svn`""
	}
	$localName = "local/$BranchName"
	$repoPath = (Get-RepositoryDirectory)
	Push-Location $repoPath
	$branchExists = (git branch -a | where {$_.Trim().EndsWith($localName)} | measure).Count -gt 0
	if ($branchExists) {
		Write-Error "Branch $BranchName already exists."
		return
	}
	#Create project branch
	git svn branch -m "GIT - #0 - Creating new branch" $BranchName
	$appCore = Get-AppCoreDirectory
	Pop-Location
	#Make an appcore branch, if needed.
	if (Test-Path $appCore -PathType Container) {
		Push-Location $appCore
		git svn branch -m "GIT - #0 - Creating new branch" $BranchName
		Pop-Location
	}
	Switch-Branch $BranchName
}