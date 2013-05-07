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

	$parts = $pwd.ProviderPath
	$backgroundColor = [ConsoleColor]::Black
	Write-Host ([System.String]::Join((([char]0x25BA).ToString()), $parts.Split([System.IO.Path]::DirectorySeparatorChar))) -nonewline -BackgroundColor $backgroundColor

    Write-VcsStatus

    $global:LASTEXITCODE = $realLASTEXITCODE
	$color = [ConsoleColor]::Magenta
	if ($real) {
		Write-Host (([char]0x25BA).ToString()) -NoNewLine -BackgroundColor $backgroundColor
	} else {
		Write-Host (([char]0x25BA).ToString()) -NoNewLine -ForegroundColor $color -BackgroundColor $backgroundColor
	}
    return " "
}

Enable-GitColors

Pop-Location

Start-SshAgent -Quiet