<#PSScriptInfo
.VERSION 1.0
.GUID 55081cab-08e3-4c05-96bb-a70c79cb5b3b
.AUTHOR Rodrigo Cordeiro <rodrigomendoncca@gmail.com>
.COMPANYNAME 
.COPYRIGHT 
.TAGS PersonalConfiguration PersonalAssistant Terminal Powershell
.LICENSEURI 
.PROJECTURI https://rodcordeiro.com.br/
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
#>

<# 
.DESCRIPTION 
 Profile configuration 
#> 

Param()

## Configs
$console = $host.ui.rawui

$console.BackgroundColor = "black"
$console.foregroundcolor = "cyan"

if ((New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    $Title = "< GODMODE />"
}
else {
    $Title = "< RodC0rdeiro />"
}
$console.WindowTitle = $Title


function SignScripts {
    <# 
.SYNOPSIS 
    Sign a script with a certificate 
.DESCRIPTION
    Sign a script with a valid certificate
.Parameter <Path>
    Path to script to sign
.Example
    sign ./example.ps1
.Example
    sign C:\Scripts\example.ps1
#> 
    
    param([parameter(ValueFromPipelineByPropertyName)][string]$Path)
    if (!$Path) {
        Write-Host "You must pass the path argument"
        Break
    }
    Write-Host ""
    $certificates = Get-ChildItem cert:\LocalMachine\My
    if (!$certificates) {
        return Write-Host "There's no available certificate. Please refer to https://guidooliveira.com/gerando-certificados-para-assinar-digitalmente-seus-scripts/ for instructions about creating sign certificate"
    }
    $counter = 1;
    Write-Host "Bellow are the available certificates:"
    $certificates | ForEach-Object {
        $cer = $_ | Select-Object Subject
        Write-Host "$counter | $cer"
        $counter = $counter + 1
    }
    Write-Host ""
      
    $opt = $(Read-Host -Prompt "Enter the certificate number choosed") - 1
    $certificate = $certificates[$opt]
      
    Set-AuthenticodeSignature $Path $certificate
}

function vscode {
    <# 
    .SYNOPSIS 
        Opens VSCode with some customization
    .DESCRIPTION
        Opens VSCode with some customization
    .Parameter <Path>
        Path to folder to be opened
    .Example
        vscode ./example.ps1
    .Example
        vscode C:\Scripts\example.ps1
    .Example
        vscode
    .Example
        vscode .
    #> 
        
    param([parameter(ValueFromPipelineByPropertyName)][string]$Path)
        
    if (!$Path) {
        $Path = $PWD
    }
    if (Get-Command code-insiders) {
        $code = $(get-command code-insiders).source
    }
    elseif (Get-Command code) {
        $code = $(get-command code).source
    }
    else {
        Write-Host "VSCode not installed. Please verify";
        Break;
    }
    Start-Process -FilePath $code -ArgumentList "$(Resolve-Path -Path $Path)"
}

function Prompt {
    <# 
    .SYNOPSIS 
        Changes PS Prompt
    .DESCRIPTION
        Changes PS Prompt
    #> 
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf
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
            Write-host '*' -ForegroundColor gray  -NoNewline 
        }
        elseif (git status | select-string "Changes to be committed:") { 
            Write-host '::' -ForegroundColor gray  -NoNewline
        }
        
        elseif (git status | select-string "Your branch is ahead") { 
            Write-host '^' -ForegroundColor gray  -NoNewline
        }
        else {
            Write-host '' -ForegroundColor gray  -NoNewline
        }
    }
    
    Write-host ($(if ($IsAdmin) { ' #' } else { ' $' })) -NoNewline
    return "> "    
}
   
## ALIASES
Set-Alias sign SignScripts
Set-Alias code vscode
$projetos = "C:\Users\$env:username\Projetos"
