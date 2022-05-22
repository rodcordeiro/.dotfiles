# Changes output encoding to UTF8
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding

# Modules imports
Import-Module Terminal-Icons
Import-Module "$($env:USERPROFILE)\projetos\personal\.dotfiles\MyModule.psm1"
import-module PSScriptAnalyzer

## Needed modules
# Microsoft.PowerShell.Management
# Microsoft.PowerShell.Security
# Microsoft.PowerShell.Utility
# MyModule
# PackageManagement
# PowerShellGet
# PSReadline
# psscriptanalyzer
# Terminal-Icons
# WindowsConsoleFonts


# Set terminal configs
Set-ConsoleFont "LiterationMono NF"
Set-TerminalIconsTheme -ColorTheme devblackops -IconTheme devblackops

# Clears terminal before starting
Clear-Host

# Customizing prompt
function Prompt {
  <#
    .SYNOPSIS
        Changes PS Prompt
    .DESCRIPTION
        Changes PS Prompt
    #>
  $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  # $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
  $is_inside_git = isInsideGit
  if ($is_inside_git) {
    $git_dir = $(Split-Path -Path $(git rev-parse --show-toplevel) -Leaf)
    $git_index = $PWD.ToString().IndexOf($git_dir)
    $CmdPromptCurrentFolder = $PWD.ToString().Substring($git_index)
  }
  else {
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf 
  }
  # Write-Host "$($CmdPromptUser.Name.split("\")[1]) " -ForegroundColor green -NoNewline

  if ($IsAdmin) {
    $Title = "< GODMODE />"
  }
  else {
    $Title = "< RodC0rdeiro />"
  }
  $host.ui.rawui.WindowTitle = $Title + "$(if($PWD.Path -eq $env:USERPROFILE){" ~HOME"} else {" $CmdPromptCurrentFolder"})"

  Write-Host "$CmdPromptCurrentFolder " -NoNewline
   
    
  if ($is_inside_git) {
    $CurrentBranch = git branch | select-string "\*"
    Write-Host "($($CurrentBranch.ToString().split(" ")[1]))" -ForegroundColor cyan -NoNewline
    if (git status | select-string "Changes not staged for commit") {
      Write-host '* ' -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Changes to be committed:") {
      Write-host ':: ' -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Your branch is ahead") {
      Write-host '^ ' -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Your branch is behind") {
      Write-host '| ' -ForegroundColor gray  -NoNewline
    }
    else {
      Write-host ' ' -ForegroundColor gray  -NoNewline
    }
  }
   
  return "$(if ($IsAdmin) { ' #' } else { ' $' })> "    
}

# My personal functions
Function isInsideGit() {
  if ($(Split-Path -Path $PWD -Leaf) -ne '.git') {
    if ($(Test-Path -Path "$PWD\.git") -ne $False) {
      return Resolve-Path -Path "$PWD"
    }
    if ($(Test-Path -Path "$PWD\..\.git") -ne $False) {
      return Resolve-Path -Path "$PWD\.."
    }
    if ($(Test-Path -Path "$PWD\..\..\.git") -ne $False) {
      return Resolve-Path -Path "$PWD\..\.."
    }    
    if ($(Test-Path -Path "$PWD\..\..\..\.git") -ne $False) {
      return Resolve-Path -Path "$PWD\..\..\.."
    }
  }
  else {
    return Resolve-Path -Path "$PWD"
  }
}

function ReloadModule() {
  Remove-Module MyModule
  Import-Module "$($env:USERPROFILE)\projetos\personal\.dotfiles\MyModule.psm1"  
}

function compress() {
  <#
    .SYNOPSIS
    Compress build folder into app zipped file.
    .DESCRIPTION
        Compress build folder into app zipped file.
    .EXAMPLE
        compress
    #>
  Compress-Archive .\build\* .\app.zip -Force
}

function GetAllFiles {
  $items = @(Get-ChildItem -Hidden; Get-ChildItem)
  $items
}
 
## ALIASES
Set-Alias insomnia "$($env:USERPROFILE)\AppData\Local\insomnia\Insomnia.exe"
Set-Alias activate ".\.venv\scripts\activate"
Set-Alias beekeeper "$($env:USERPROFILE)\AppData\Local\Programs\beekeeper-studio\Beekeeper Studio.exe"
Set-Alias yt "C:\tools\youtube-dl.exe"
Set-Alias la GetAllFiles
Set-Alias ssms "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe"

## PERSONAL_VARIABLES
$env:GOOGLE_TOKEN = ""
