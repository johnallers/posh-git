Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Load posh-git module from current directory
Import-Module .\posh-git

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
# Import-Module posh-git


# Set up a simple prompt, adding the git prompt parts inside git repos
function prompt {
	$real = $?
    $realLASTEXITCODE = $LASTEXITCODE
    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

	$backgroundColor = $GitPromptSettings.PathBackgroundColor
	$pieces = $pwd.ProviderPath.Split([System.IO.Path]::DirectorySeparatorChar) | Where {$_ -match "\S"}
	$path = @()
	if ($pwd.ProviderPath.Length -gt ($Host.UI.RawUI.WindowSize.Width / 5) -and $pieces.Length -gt 2) {
		$front = $pieces | Select-Object -first 1
		$back = $pieces | Select-Object -last 1
		$path = @($front, $GitPromptSettings.PathCollapseSeperator, $back)
	} else {
		$path = $pieces
	}
	Write-Host ([System.String]::Join($GitPromptSettings.PathSeperator, $path)) -nonewline -BackgroundColor $backgroundColor

    Write-VcsStatus

    $global:LASTEXITCODE = $realLASTEXITCODE
	$color = [ConsoleColor]::Magenta
	if ($real) {
		Write-Host (" " + ([char]0x25BA).ToString()) -NoNewLine -BackgroundColor $backgroundColor
	} else {
		Write-Host (" " + ([char]0x25BA).ToString()) -NoNewLine -ForegroundColor $color -BackgroundColor $backgroundColor
	}
    return " "
}

Enable-GitColors

Pop-Location

Start-SshAgent -Quiet