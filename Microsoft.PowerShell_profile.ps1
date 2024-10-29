# Changes output encoding to UTF8
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding

# Modules imports
Import-Module Terminal-Icons
import-module PSScriptAnalyzer
# Import-Module platyPS  # https://github.com/PowerShell/platyPS
Import-Module Logging # https://logging.readthedocs.io/en/latest/functions/Add-LoggingLevel/
Import-Module PSSQLite # https://github.com/RamblingCookieMonster/PSSQLite
Import-Module SecurityFever
Import-Module ProfileFever
Import-Module WindowsConsoleFonts
Import-Module psrod
import-module psrabbitmq

# Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineOption -HistorySearchCursorMovesToEnd

# Autosuggestions for PSReadline
Set-PSReadlineOption -ShowToolTips
# PredictionSource, history search commands used
# Set-PSReadlineOption -PredictionSource History


# Clears terminal before starting
Clear-Host

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
function GetAllFiles {
  $items = @(Get-ChildItem -Hidden; Get-ChildItem)
  $items
}


function Get-ExitTime {
  param(
    [datetime]$Entrada,
    [datetime]$Almoco,
    [datetime]$Retorno
  )
  return timer $($($(CalcularSaida -Entrada $Entrada -Almoco $Almoco -Retorno $Retorno -Output).TimeOfDay.TotalSeconds) - $([datetime]::Now.TimeOfDay.TotalSeconds)); Show-Notification -ToastTitle 'É hora de partir!'
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
    Write-Host "[$($CurrentBranch.ToString().split(" ")[1])]" -ForegroundColor cyan -NoNewline
    if (git status | select-string "Changes not staged for commit") {
      Write-host '*' -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Changes to be committed:") {
      # Write-host '::' -ForegroundColor gray  -NoNewline
      Write-host $Glyphs.MENU -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Your branch is ahead") {
      Write-host $Glyphs.TArrow -ForegroundColor gray  -NoNewline
    }
    elseif (git status | select-string "Your branch is behind") {
      Write-host $Glyphs.DArrow -ForegroundColor gray  -NoNewline
    }
    else {
      # Write-host ' ' -ForegroundColor gray  -NoNewline
    }
    if ($(Test-Path -Path "$(git rev-parse --show-toplevel)/.deprecated")) {
      Write-host '[DEPRECATED]' -ForegroundColor white -BackgroundColor red  -NoNewline  
    }
  }
   
      
  return "$(if ($IsAdmin) { ' #' } else { ' $' })> "
}


function Deploy {
  param(
    [parameter(ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Admin', 'Amostra')]
    [string]$Projeto
  )
  begin {
    
    switch ($Projeto) {
      "Admin" {
        $buildCommand = "pnpm build";
        $destinationPath = "/var/www/html";
      }
      "Amostra" { 
        $buildCommand = "pnpm build:dev";
        $destinationPath = "/var/www/amostra";
      }
      Default {
        throw "Projeto inválido!"
      }
    }

  }
  process {
    Invoke-Expression $buildCommand -ErrorAction Stop;
    if ($?) {
      scp -r ./dist frontend:/home/rodrigo.cordeiro@torra.local;
      show-notification Deploy 'Insira a senha para finalizar o deploy'
      ssh -t frontend "sudo cp -rf /home/$($env:USERNAME)@torra.local/dist/* $($destinationPath)"
    }
  }
}

function totp {
  Get-TOTP -SharedSecret $env:TORRA_TOTP_SHARED_SECRET
}

function Coluna {
  timer 300
  Show-Notification -ToastTitle 'Ajustar coluna' -ToastText 'Erga-se, pavao. Aprume-se Leopardo'
  Coluna
} 
function Agua {
  timer 300
  Show-Notification -ToastTitle 'Beber Agua' -ToastText 'Hora da hidratação \o/'
  Agua
}

function auth {
  param(
    [Switch]$Sso,
    [Switch]$Admin,
    [Int]$Sistema,
    [Switch]$Write
  )
  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]" 
  $headers.Add("Content-Type", "application/json")
  $headers.Add("Accept", "application/json")
  
  if (!$Sistema) {
    throw "Sistema não informado!"
  }
  
  # $env:TORRA_TOTP_SHARED_SECRET
  if ($Admin) {
    $user = ""
    $body = "{`"login`": `"`", `"senha`": `"T$`" `}"
  }
  else {
    $user = ""
    $body = "{`"login`": `"`", `"senha`": `"@`" `, `"otp`": `"$(totp)`"  }"
  }
  
  $refresh_token = $(Invoke-RestMethod 'http://hml.api.torratorra.com.br:5703/Auth/v1/Autenticacao' -Method 'POST' -Headers $headers -Body $body)
  
  if (!$refresh_token) { throw $refresh_token }

  $body = "  {    `"login`": `"$user`",    `"refreshToken`": `"$($refresh_token.refreshToken)`",    `"codigoCliente`": `"1`",    `"codigoEmpresa`": `"1`",    `"codigoSistema`": $Sistema }  "
  $response = Invoke-RestMethod 'http://hml.api.torratorra.com.br:5703/Auth/v1/Autenticacao/refresh-Token' -Method 'POST' -Headers $headers -Body $body
  
  if ($Sso) {
    $headers.Add("Authorization", "Bearer " + $response.accessToken)
    $body = "  {    `"refreshToken`": `"$($refresh_token.refreshToken)`" }  "
    $responseSso = Invoke-RestMethod 'http://hml.api.torratorra.com.br:5703/Auth/v1/Autenticacao/sso/request' -Method 'POST' -Headers $headers -Body $body
    if ($Write) {
      Write-Host $responseSso
    }
    else {
      $responseSso | clip
    }
    
    return
  }

  if ($Write) {
    Write-Host $response.accessToken
  }
  else {
    $response.accessToken | clip
  }
  
}




## ALIASES
Set-Alias insomnia "$($env:USERPROFILE)\AppData\Local\insomnia\Insomnia.exe"
Set-Alias postman "$($env:USERPROFILE)\AppData\Local\Postman\Postman.exe"
# Set-Alias activate ".\.venv\scripts\activate"
# Set-Alias beekeeper "$($env:USERPROFILE)\AppData\Local\Programs\beekeeper-studio\Beekeeper Studio.exe"
# Set-Alias yt "C:\tools\youtube-dl.exe"
Set-Alias la GetAllFiles
Set-Alias ssms "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 20\Common7\IDE\ssms.exe"
Set-Alias '??' Get-GoogleAnswer
Set-Alias 'Check-Network' Read-NetworkSpeed
Set-Alias vi nvim
Set-Alias vim nvim

## PERSONAL_VARIABLES
$env:PAT = ''
$env:GOOGLE_TOKEN = ''
$env:disc_darthside = ''
$env:DISCORD_WEBHOOK = ''
$env:PSGToken = ''
$env:DEV_TOKEN = ''
$env:DEV_APP_ID = ''
$env:ASPNETCORE_ENVIRONMENT = ''
$env:NODE_ENV = ''
$env:TORRA_TOTP_SHARED_SECRET = ''
# 
# [string] $strUser = '@@@@@'
# $strPass = ConvertTo-SecureString -String '@@@@@' -AsPlainText -Force
# $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($strUser, $strPass)

# $env:Rabbit_Params = @{
#   ComputerName = '@@@@@';
#   Timeout      = 100000;
#   Credential   = $Cred;
#   QueueName    = 'ps1';
#   Exchange     = "xxx";
#   ExchangeType = "Topic";
#   Ssl          = "None"
# }
# $env:Rabbit_Connection = New-RabbitMqConnectionFactory -ComputerName @@@@@ -Credential $Cred

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.2.13-hotspot"
# $env:ANDROID_HOME = 'C:\Android\Sdk'
# $env:Path = "$env:Path;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\tools;$env:ANDROID_HOME\tools\bin;$env:ANDROID_HOME\platform-tools"
$env:Path = "$env:Path;$env:USERPROFILE\tools\nvim\bin"

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# start-job -FilePath C:\@@@@@\rabbitmq_notifications.ps1 -Name Rabbit_messages | Out-Null
