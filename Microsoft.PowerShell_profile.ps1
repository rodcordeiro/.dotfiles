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
    if ($(Split-Path -Path $pwd -Leaf) -eq 'android') {
        $CmdPromptCurrentFolder = "$(Split-Path -Path $(Split-Path -Path $pwd -Parent) -Leaf)\$(Split-Path -Path $pwd -Leaf)"
    }
    elseif ($(Split-Path -Path $pwd -Leaf) -eq '.github') {
        $CmdPromptCurrentFolder = "$(Split-Path -Path $(Split-Path -Path $pwd -Parent) -Leaf)\$(Split-Path -Path $pwd -Leaf)"
    }
    elseif ($(Split-Path -Path $pwd -Leaf) -eq 'src') {
        $CmdPromptCurrentFolder = "$(Split-Path -Path $(Split-Path -Path $pwd -Parent) -Leaf)\$(Split-Path -Path $pwd -Leaf)"
    }
    elseif ($(Split-Path -Path $pwd -Leaf) -eq '.ci') {
        $CmdPromptCurrentFolder = "$(Split-Path -Path $(Split-Path -Path $pwd -Parent) -Leaf)\$(Split-Path -Path $pwd -Leaf)"
    }
    elseif ($(Split-Path -Path $pwd -Leaf) -eq '.azuredevops') {
        $CmdPromptCurrentFolder = "$(Split-Path -Path $(Split-Path -Path $pwd -Parent) -Leaf)\$(Split-Path -Path $pwd -Leaf)"
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
    $host.ui.rawui.WindowTitle = $Title + "$(if($PWD.Path -eq $env:USERPROFILE){" ~HOME"} else {"$CmdPromptCurrentFolder"})"

    Write-Host "$CmdPromptCurrentFolder " -NoNewline
    
    if (Test-Path -Path .git) {
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

function clone {
    <# 
    .SYNOPSIS 
        Function to customize repositories cloning with some validations.
    .DESCRIPTION
        Function to customize repositories cloning with some validations. It validates the folder and the repository link.
    .Parameter <Path>
        Repository link
    .Parameter <Folder>
        Provides you the possibility of cloning the repository on a different folder. Pass the desired folder path.
    .Parameter <Alias>
        Provides you the possibility of changing the destiny folder name.
    .Parameter <Confirm>
        Forces execution
    .EXAMPLE
        clone https://github.com/user/repo.git
    .EXAMPLE
        clone https://github.com/user/repo.git -y
    .EXAMPLE
        clone https://github.com/user/repo.git -Folder test
    .EXAMPLE
        clone https://github.com/user/repo.git -Alias someTest
    .EXAMPLE
        clone https://github.com/user/repo.git someTest
    #>

    param(
        [parameter(ValueFromPipelineByPropertyName, HelpMessage = "Please, enter the repository link for download")][string]$Path,
        [parameter(ValueFromPipelineByPropertyName, HelpMessage = "Provides you the possibility of changing the destiny folder name.")][string]$Alias,
        [parameter(ValueFromPipelineByPropertyName, HelpMessage = "Provides you the possibility of cloning the repository on a different folder. Pass the desired folder path.")][string]$Folder,
        [parameter(HelpMessage = "Please, enter the repository link for download")][Alias('y', 'yes')][Switch] $confirm
    )

    if (!$Path) {
        Write-Host "You must provide a repository to clone!"
    }
    $repository = $Path
    $destiny = if ($Folder) { $Folder } else { $pwd }
    $localFolder = if ($Alias) { $Alias } else { $(Split-Path -Path $repository -Leaf) }

    if ($(Split-Path -Path $destiny -Leaf) -eq 'personal' -Or $(Split-Path -Path $destiny -Leaf) -eq 'pda' -Or $(Split-Path -Path $destiny -Leaf) -eq 'estudos' -Or $confirm) {
        if ($folder) { Set-Location $(Resolve-Path -Path $Folder) }
        git clone $repository $(if ($Alias) { $Alias })
        Set-Location $(Resolve-Path -Path $localFolder)
        return
    }

    $response = Read-Host "You're outside of the predefined projects folders. Do you want to proceed? ([Y]es/[N]o)"
    if ($response -eq 'Y' -Or $response -eq 'y' -Or $response -eq 'S' -Or $response -eq 's') {
        if ($folder) { Set-Location $(Resolve-Path -Path $Folder) }
        git clone $repository $(if ($Alias) { $Alias })
        Set-Location $(Resolve-Path -Path $localFolder)
        return
    }
    Write-Host "Cancelling cloning projects. Have a nice day!"
}

## ALIASES
Set-Alias insomnia "$($env:USERPROFILE)\AppData\Local\insomnia\Insomnia.exe"
Set-Alias activate ".\.venv\scripts\activate"
Set-Alias beekeeper "$($env:USERPROFILE)\AppData\Local\Programs\beekeeper-studio\Beekeeper Studio.exe"
Set-Alias la "@(ls -ah;ls)"

## PERSONAL_VARIABLES
$env:GOOGLE_TOKEN = "AIzaSyDbRlNXxJf272Sg4Zdr5e1-vQjWw6veL-I"
