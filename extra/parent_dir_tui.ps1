# PowerShell wrapper for parent_dir_tui
# Usage: . .\extra\parent_dir_tui.ps1   (dot-source to define functions)
# Then press Alt+Left / Alt+Right in your terminal.
#
# Requires: PSReadLine module (built-in on PowerShell 5.1+)

$script:PERV_DIR_FOR_TUI = ""

function Invoke-ParentDirTui {
    param([string]$Offset)

    $out = & parent_dir_tui $Offset $script:PERV_DIR_FOR_TUI $PWD
    if ($LASTEXITCODE -ne 0) { return }

    $tabIndex = $out.IndexOf("`t")
    if ($tabIndex -lt 0) { return }

    $newDir = $out.Substring(0, $tabIndex)
    $script:PERV_DIR_FOR_TUI = $out.Substring($tabIndex + 1)

    if ($newDir -and (Test-Path $newDir -PathType Container)) {
        Set-Location $newDir
    }
}

function Invoke-ParentDirTuiLeft {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    Invoke-ParentDirTui -Offset "-1"
}

function Invoke-ParentDirTuiRight {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    Invoke-ParentDirTui -Offset "+1"
}

# Bind Alt+Left and Alt+Right
Set-PSReadLineKeyHandler -Chord "Alt+LeftArrow" -ScriptBlock { Invoke-ParentDirTuiLeft }
Set-PSReadLineKeyHandler -Chord "Alt+RightArrow" -ScriptBlock { Invoke-ParentDirTuiRight }
