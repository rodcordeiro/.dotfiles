# Clears terminal before starting
Clear-Host

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
import-module psrabbitmq
Import-Module psrod
import-module psbanky

# Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineOption -HistorySearchCursorMovesToEnd

# Autosuggestions for PSReadline
Set-PSReadlineOption -ShowToolTips

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

function totp {
  Get-TOTP -SharedSecret $env:TORRA_TOTP_SHARED_SECRET
}

function Coluna {
  timer 300
  $strings = @(   
    "Ajustar a porra da coluna!",
    "Olha a postura, ou vai acabar com menos carisma!",
    "Ja falei do carai da postura hoje?",
    "Vamos, ajuste a postura, cavaleiro torto nao ganha XP.",
    "Arruma a coluna, ou o clerigo vai cobrar caro pra curar isso.",
    "Goblins tem uma postura melhor que voce, pelos deuses!",
    "Tirou 1 no dado de Constituicao? Levanta essa coluna, guerreiro!",
    "O que e isso, tirou um nos dados? Arrume essa coluna rapaz!",
    "Se continuar assim, ate o dragao vai ter do de você.",
    "A coluna torta nao da bonus de defesa, ajuste isso ja!",
    "Lembre-se: postura correta da vantagem em testes de Força.",
    "Torto desse jeito, nem o bardo consegue te convencer de que esta bem.",
    "Sente-se como se estivesse em um banquete real, nao numa taverna caindo aos pedaços.",
    "Se voce fosse um elfo, ja estaria ouvindo sermao sobre postura ha horas.",
    "Um heroi de verdade mantem a coluna ereta, ate no campo de batalha.",
    "Veio corcunda!"
  )
  # Randomly select one string
  $message = Get-Random -InputObject $strings
  tts $message
  Coluna
} 
function Agua {
  timer 600
  $strings = @(
    "E hora da hidrataçao! Repetindo, e hora da hidrataçao!",
    "Bebe agua, abençoado, ou vai receber dano por desidrataçao!",
    "Olha a agua, nao va falhar no teste de sobrevivencia.",
    "Um gole de agua por obséquio, seu HP depende disso.",
    "Faz o favor de tomar uma aguinha? Seu rim agradece e o clerigo tambem.",
    "Ate o dragao bebe agua, quem dira voce.",
    "Se hidratar e como recarregar poçoes de mana, beba agua!",
    "Você está em estado 'Desidratado'. Solução: beber agua.",
    "Falha critica em sobrevivencia? Nao, e so desidrataçao. Beba agua!",
    "A hidrataçao e o segredo dos herois, siga o exemplo dos bardos!",
    "Olha a agua, se nao o mestre vai aplicar dano nao letal.",
    "Bebe agua, ou vai acordar com condiçao 'exausto' no proximo descanso longo.",
    "Um guerreiro sabio sabe que hidrataçao e metade da batalha!",
    "Ate os goblins param pra beber agua, o que voce esta esperando?",
    "Sem agua, voce nao vai ganhar bonus de ataque, confia.",
    "Olha a agua"
  )
  # Randomly select one string
  $message = Get-Random -InputObject $strings
  tts $message
  Agua
}





## ALIASES
Set-Alias insomnia "$($env:USERPROFILE)\AppData\Local\insomnia\Insomnia.exe"
Set-Alias postman "$($env:USERPROFILE)\AppData\Local\Postman\Postman.exe"
# Set-Alias activate ".\.venv\scripts\activate"
# Set-Alias beekeeper "$($env:USERPROFILE)\AppData\Local\Programs\beekeeper-studio\Beekeeper Studio.exe"
# Set-Alias yt "C:\tools\youtube-dl.exe"
Set-Alias la GetAllFiles
Set-Alias ssms "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 20\Common7\IDE\ssms.exe"
Set-Alias vi nvim
Set-Alias vim nvim

## PERSONAL_VARIABLES
$env:PAT = ""
$env:GOOGLE_TOKEN = ""
$env:disc_darthside = ""
$env:DISCORD_WEBHOOK = ""
$env:PSGToken = ""
$env:DEV_TOKEN = ""
$env:DEV_APP_ID = ""
$env:ASPNETCORE_ENVIRONMENT = ""
$env:NODE_ENV = ""
$env:TORRA_TOTP_SHARED_SECRET = ""
$env:JAVA_HOME = ""
# $env:ANDROID_HOME = 'C:\Android\Sdk'
# $env:Path = "$env:Path;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\tools;$env:ANDROID_HOME\tools\bin;$env:ANDROID_HOME\platform-tools"
$env:Path = "$env:Path;$env:USERPROFILE\tools\nvim\bin"

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# start-job -FilePath C:\Users\rodrigo.cordeiro\Documents\WindowsPowerShell\rabbitmq_notifications.ps1 -Name Rabbit_messages | Out-Null
