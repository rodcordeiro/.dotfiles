# Changes output encoding to UTF8
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding

# Modules imports
Import-Module Terminal-Icons
import-module PSScriptAnalyzer
Import-Module platyPS  # https://github.com/PowerShell/platyPS
Import-Module Logging # https://logging.readthedocs.io/en/latest/functions/Add-LoggingLevel/
Import-Module PSSQLite # https://github.com/RamblingCookieMonster/PSSQLite
Import-Module SecurityFever
Import-Module ProfileFever
Import-Module WindowsConsoleFonts

Import-Module "$($env:USERPROFILE)\projetos\personal\.dotfiles\my_module\mymodule.psd1"


# Set terminal configs
Set-ConsoleFont "LiterationMono NF"
Set-TerminalIconsTheme -ColorTheme devblackops -IconTheme devblackops
Set-LoggingDefaultLevel -Level 'WARNING'
Add-LoggingTarget -Name Console
Add-LoggingTarget -Name File -Configuration @{Path = 'C:\Scripts\script_log.%{+%Y%m%d}.log'; Level = 'WARNING' }
Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineOption -ShowToolTips



# Clears terminal before starting
Clear-Host

# Readline options
## Tab completion

$Glyphs = [PSCustomObject]@{
  Branch  = "$([char]0xE0A0)" #  Version control branch
  LN      = "$([char]0xE0A1)" #  LN (line) symbol
  Padlock = "$([char]0xE0A2)" #  Closed padlock
  TArrow  = "$([char]0x2191)"
  DArrow  = "$([char]0x2193)" #  Rightwards black arrowhead
  RArrow  = "$([char]0xE0B0)" #  Rightwards black arrowhead
  WRArrow = "$([char]0xE0B1)" #  Rightwards arrowhead
  LArrow  = "$([char]0xE0B2)" #  Leftwards black arrowhead
  WLArrow = "$([char]0xE0B3)" #  Leftwards arrowhead
  NBSP    = "$([char]0x00A0)"
  MENU    = "$([char]0x2261)"
}

# BG = FG
enum Colors {
  Black = "9"
  DarkBlue = "15"
  DarkGreen = "15"
  DarkCyan = "0"
  DarkRed = "15"
  DarkMagenta = "15"
  DarkYellow = "0"
  Gray = "0"
  DarkGray = "6"
  Blue = "0"
  Green = "0"
  Cyan = "0"
  Red = "0"
  Magenta = "0"
  Yellow = "0"
  White = "0"
}

# Customizing prompt
function Prompt {
  <#
    .SYNOPSIS
        Changes PS Prompt
    .DESCRIPTION
        Changes PS Prompt
    #>
  
  $BackgroundColor = [Console]::BackgroundColor
  $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  # # $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
  $is_inside_git = isInsideGit
  
  if ($is_inside_git) {
    Write-Host $Glyphs.NBSP -BackgroundColor $([Colors]::$BackgroundColor).value__ -NoNewline
    Write-Host $Glyphs.Branch -BackgroundColor $([Colors]::$BackgroundColor).value__ -ForegroundColor $BackgroundColor -NoNewline
    Write-Host $Glyphs.RArrow -ForegroundColor $([Colors]::$BackgroundColor).value__ -NoNewline
    Write-Host $Glyphs.NBSP -BackgroundColor $BackgroundColor -NoNewline
    
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
      Write-host '*' -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Changes to be committed:") {
      Write-host '::' -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Your branch is ahead") {
      Write-host $Glyphs.TArrow -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Your branch is behind") {
      Write-host $Glyphs.DArrow -ForegroundColor gray  -NoNewline
    }
    else {
      Write-host ' ' -ForegroundColor gray  -NoNewline
    }
    if ($(Test-Path -Path "$(git rev-parse --show-toplevel)/.deprecated")) {
      Write-host '[DEPRECATED]' -ForegroundColor white -BackgroundColor red  -NoNewline  
    }
  }
   
      
  return "$(if ($IsAdmin) { ' #' } else { ' $' })> "
}

# My personal functions
Function isInsideGit() {
  try {
    if (git rev-parse --is-inside-work-tree) {
      return $true
    }
    return $false
  }
  catch {
    return $false
  }
}

function ReloadModule() {
  Remove-Module mymodule  
  Import-Module "$($env:USERPROFILE)\projetos\personal\.dotfiles\my_module\mymodule.psd1"  
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
 
function ReloadPDA {
  remove-module pspda;
  import-Module "$($env:USERPROFILE)\projetos\personal\PSPDA\pspda.psd1" -Verbose
}

## ALIASES
Set-Alias insomnia "$($env:USERPROFILE)\AppData\Local\insomnia\Insomnia.exe"
Set-Alias activate ".\.venv\scripts\activate"
Set-Alias beekeeper "$($env:USERPROFILE)\AppData\Local\Programs\beekeeper-studio\Beekeeper Studio.exe"
Set-Alias yt "C:\tools\youtube-dl.exe"
Set-Alias la GetAllFiles
Set-Alias ssms "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe"
Set-Alias '??' Get-GoogleAnswer
Set-Alias 'Check-Network' Read-NetworkSpeed

## PERSONAL_VARIABLES
$env:PAT = ""
$env:GOOGLE_TOKEN = ""
$env:disc_darthside = ""
$env:disc_testes = ""
$env:PSGToken = "" 

$env:ANDROID_HOME = 'C:\Android\Sdk'
$env:Path = "$env:Path;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\tools;$env:ANDROID_HOME\tools\bin;$env:ANDROID_HOME\platform-tools"


# https://en.wikipedia.org/wiki/ANSI_escape_code
# https://superuser.com/questions/1259900/how-to-colorize-the-powershell-prompt

# https://stackoverflow.com/questions/56216923/change-powershell-command-color
# Get-PSReadlineOption
# CommandColor                           : "$([char]0x1b)[93m"
# CommentColor                           : "$([char]0x1b)[32m"
# ContinuationPromptColor                : "$([char]0x1b)[96m"
# DefaultTokenColor                      : "$([char]0x1b)[96m"
# EmphasisColor                          : "$([char]0x1b)[96m"
# ErrorColor                             : "$([char]0x1b)[91m"
# KeywordColor                           : "$([char]0x1b)[92m"
# MemberColor                            : "$([char]0x1b)[97m"
# NumberColor                            : "$([char]0x1b)[97m"
# OperatorColor                          : "$([char]0x1b)[90m"
# ParameterColor                         : "$([char]0x1b)[90m"
# SelectionColor                         : "$([char]0x1b)[30;106m"
# StringColor                            : "$([char]0x1b)[36m"
# TypeColor                              : "$([char]0x1b)[37m"
# VariableColor                          : "$([char]0x1b)[92m"


# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
