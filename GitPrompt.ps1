# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$global:GitPromptSettings = New-Object PSObject -Property @{
    DefaultForegroundColor    = $Host.UI.RawUI.ForegroundColor

    PathSeperator             = (" " + ([char]0x25BA).ToString() + " ")
	AheadIndicator            = ([char]0x25B2).ToString()
	AddedIndicator            = "+"
	
	PathBackgroundColor       = [ConsoleColor]::Black
	PathForegroundColor       = $Host.UI.RawUI.ForegroundColor
    CleanBackgroundColor      = [ConsoleColor]::DarkGreen
	DirtyBackgroundColor      = [ConsoleColor]::Red

    ShowStatusWhenZero        = $true

    AutoRefreshIndex          = $true

    EnablePromptStatus        = !$Global:GitMissing
    EnableFileStatus          = $true
    RepositoriesInWhichToDisableFileStatus = @( ) # Array of repository paths

    EnableWindowTitle         = 'posh~git ~ '
	KnownPaths                = @{
									"dev" = "C:\development";
									"~" = "$env:homedrive$env:homepath";
								}
    Debug                     = $false
}

$WindowTitleSupported = $true
if (Get-Module NuGet) {
    $WindowTitleSupported = $false
}

function Write-Prompt($Object, $ForegroundColor, $BackgroundColor = -1) {
    if ($BackgroundColor -lt 0) {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
}

function Write-GitStatus($status) {
    $s = $global:GitPromptSettings
    if ($status -and $s) {
        Write-Prompt $s.PathSeperator -BackgroundColor $s.PathBackgroundColor -ForegroundColor $s.PathForegroundColor
        $branchBackgroundColor = $s.CleanBackgroundColor
		$modifiers = " "

        if($s.EnableFileStatus -and $status.HasWorking) {
            if($s.ShowStatusWhenZero -or $status.Working.Added) {
			  $branchBackgroundColor = $s.DirtyBackgroundColor
            }
        }
		if($s.EnableFileStatus -and $status.HasIndex) {
			if($s.ShowStatusWhenZero -or $status.Index.Added -or $status.Index.Deleted) {
			  $branchBackgroundColor = $s.DirtyBackgroundColor
            }
		}
		if($s.HasUntracked) {
			$modifiers = $modifiers + $s.AddedIndicator
		}
		if($s.EnableFileStatus -and $s.AheadBy -gt 0) {
			$modifiers = $modifiers + $s.AheadIndicator
		}
		if ($modifiers -eq " ") {
			Write-Prompt ($status.Branch) -BackgroundColor $branchBackgroundColor -ForegroundColor $s.DefaultForegroundColor
		} else {
			Write-Prompt ($status.Branch + $modifiers + " ") -BackgroundColor $branchBackgroundColor -ForegroundColor $s.DefaultForegroundColor
		}

        if ($WindowTitleSupported -and $s.EnableWindowTitle) {
            if( -not $Global:PreviousWindowTitle ) {
                $Global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
            }
            $repoName = Split-Path -Leaf (Split-Path $status.GitDir)
            $prefix = if ($s.EnableWindowTitle -is [string]) { $s.EnableWindowTitle } else { '' }
            $Host.UI.RawUI.WindowTitle = "$prefix$repoName [$($status.Branch)]"
        }
    } elseif ( $Global:PreviousWindowTitle ) {
        $Host.UI.RawUI.WindowTitle = $Global:PreviousWindowTitle
		#>
    }
}

if((Get-Variable -Scope Global -Name VcsPromptStatuses -ErrorAction SilentlyContinue) -eq $null) {
    $Global:VcsPromptStatuses = @()
}
function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses += {
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
}
