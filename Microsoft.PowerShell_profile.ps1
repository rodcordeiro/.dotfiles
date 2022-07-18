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

Import-Module "$($env:USERPROFILE)\projetos\personal\.dotfiles\my_module\mymodule.psd1"

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
Set-LoggingDefaultLevel -Level 'WARNING'
Add-LoggingTarget -Name Console
Add-LoggingTarget -Name File -Configuration @{Path = 'C:\Scripts\script_log.%{+%Y%m%d}.log'; Level = 'WARNING' }

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
  # # $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
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
  # if ($(Split-Path -Path $PWD -Leaf) -ne '.git') {
  #   if ($(Test-Path -Path "$PWD\.git") -ne $False) {
  #     return $true
  #   }
  #   if ($(Test-Path -Path "$PWD\..\.git") -ne $False) {
  #     return $true
  #   }
  #   if ($(Test-Path -Path "$PWD\..\..\.git") -ne $False) {
  #     return $true
  #   }    
  #   if ($(Test-Path -Path "$PWD\..\..\..\.git") -ne $False) {
  #     return $true
  #   }
  #   if ($(Test-Path -Path "$PWD\..\..\..\..\.git") -ne $False) {
  #     return $true
  #   }
  #   return $false
  # }
  # return $true
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

## PERSONAL_VARIABLES
$env:PAT = ""
$env:GOOGLE_TOKEN = ""
$env:disc_darthside = "https://discord.com/api/webhooks/912344934001029160/G_KBojJ9HfJn-6_FNE_mTE1ILfvJYuxBo1kw2uPxMh3xZxArH8ukIReSMP7bHQPPPXT-"
$env:disc_testes = ""
$env:PSGToken = "" 

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
