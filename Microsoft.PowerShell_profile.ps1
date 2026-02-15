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
import-module PSRabbitMQ
Import-Module psrod
import-module pshabitica
# import-module psbanky
# import-module psmoneto
import-module CredentialManager

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


#region Prompt
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

function Update-ExpoToken {
  if ($PWD.Path -match [regex]::Escape("C:\Users\$env:USERNAME\projetos\torra")) {
    $env:expo_token = '[REPLACE_THIS]'
  }
  else {
    $env:expo_token = "[REPLACE_THIS]"
  }
}


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
  
  Update-ExpoToken

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
#endregion Prompt

#region Functions

function GetAllFiles {
  $items = @(Get-ChildItem -Hidden; Get-ChildItem)
  $items
}
function Auth {
  <#
.SYNOPSIS
Realiza autenticação no sistema de autenticação da Torra (Auth API) e gera tokens de acesso.

.DESCRIPTION
A função Auth permite autenticar usuários nos diversos sistemas internos da Torra, retornando o token de acesso (`accessToken`) 
ou o token de SSO (`magic`) conforme os parâmetros informados. 

Ela também suporta autenticação para sistemas mobile, integração com ambiente de produção ou homologação, e opções de saída 
direta do token no console ou via clipboard.

.PARAMETER Sistema
Define o sistema para o qual será realizada a autenticação.  
Aceita apenas valores predefinidos, representando cada módulo interno da Torra:
- Admin
- Amostra
- Agendamento
- Fidc
- Inventario
- Remarcacao
- Recebimento
- PushPull
- Etiqueta
- CliqueRetira
- Admissoes

Exemplo:  
`-Sistema Agendamento`

.PARAMETER Sso
Indica que a autenticação deve retornar o token de SSO (Single Sign-On).  
Quando informado, a função retorna (ou copia) o token mágico (`magic`) utilizado para logins unificados.  
Use em conjunto com `-Output` para exibir no console.

.PARAMETER Mobile
Define que a autenticação deve abrir o aplicativo mobile correspondente ao sistema informado, 
passando o token de SSO via deep link.  
Compatível apenas com sistemas configurados no `$MobileMap` (ex: Admin, Inventario, Recebimento, PushPull).  
Requer que o parâmetro `-Sso` esteja definido.

.PARAMETER Output
Quando presente, exibe o token de acesso ou SSO diretamente no console (em vez de copiar para a área de transferência).

.PARAMETER UseProd
Alterna o ambiente de autenticação de homologação para produção.  
Por padrão, o ambiente utilizado é o de homologação (`http://hml.api.torratorra.com.br:5703`).  
Quando definido, usa o endpoint de produção (`https://api.torratorra.com.br:5703`).

.EXAMPLE
# Autenticação simples para o sistema de agendamento (token copiado automaticamente para a área de transferência)
Auth -Sistema Agendamento

.EXAMPLE
# Autenticação retornando o token no console
Auth -Sistema Recebimento -Output

.EXAMPLE
# Autenticação com SSO, exibindo o token mágico no console
Auth -Sistema Admin -Sso -Output

.EXAMPLE
# Autenticação mobile (abrirá o app correspondente via deep link)
Auth -Sistema PushPull -Sso -Mobile

.EXAMPLE
# Autenticação em ambiente de produção
Auth -Sistema Agendamento -UseProd

.NOTES
Autor: Rodrigo Cordeiro  
Versão: 1.0  
Última atualização: 2025-11-06  

.LINK
https://api.torratorra.com.br/Auth/v1/Autenticacao
#>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(
      'Admin'        ,
      'Amostra'      ,
      'Agendamento'  ,
      'Fidc'         ,
      'Inventario'   ,
      'Remarcacao'   ,
      'Recebimento'  ,
      'PushPull'     ,
      'Etiqueta'     ,
      'CliqueRetira' ,
      'Admissoes',
      'PainelVendas'
    )]
    [string]
    $Sistema,
    [Parameter(Mandatory = $false)]
    [switch]
    $Sso,
    [Parameter(Mandatory = $false)]
    [switch]
    $Mobile,
    [Parameter(Mandatory = $false)]
    [switch]
    $Output,
    [Parameter(Mandatory = $false)]
    [switch]
    $UseProd
  )
  begin {
        
    if (-not $PSBoundParameters.ContainsKey('Verbose')) {
      $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
    }
    if (-not $PSBoundParameters.ContainsKey('Confirm')) {
      $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
    }
    if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
      $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
    }
    if (-not $PSBoundParameters.ContainsKey('ErrorActionPreference')) {
      $ErrorActionPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ErrorActionPreference')
    }

        
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]" 
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept", "application/json")
    $headers.Add("x-torra-client", "rodrigo")

    $Map = @{
      Admin        = 1
      Amostra      = 2
      Agendamento  = 3
      Fidc         = 9
      Inventario   = 7
      Remarcacao   = 5
      Recebimento  = 14    
      PushPull     = 17
      Etiqueta     = 4
      CliqueRetira = 12
      Admissoes    = 16
      PainelVendas = 20
    }

    $MobileMap = @{
      Admin       = "ttadmin"
      Inventario  = "ttinventario"
      Remarcacao  = "ttremarcacao"
      Recebimento = "ttrecebimento"
      PushPull    = "ttpushpull"
    }
        
  }
  process {
    if (-not $Sistema) {
      $sistema = 'Admin'
    }
        
    if (-not $Map[$Sistema]) {
      throw "Sistema ainda não mapeado"
    }
    if ($Mobile -and (-not $MobileMap[$Sistema])) {
      throw "UriSchema ainda não mapeado"
    }
    
    $scheme = "http://hml-"
        
    if ($UseProd) {
      $scheme = "https://"
    }
    $uri = "$($scheme)[REPLACE_THIS]"
    $authEndpoint = [URI]::EscapeUriString("$uri/Auth/v1/Autenticacao")
    $reauthEndpoint = [URI]::EscapeUriString("$uri/Auth/v1/Autenticacao/refresh-Token")
    $ssoEndpoint = [URI]::EscapeUriString("$uri/Auth/v1/Autenticacao/sso/request")

    $Body = @{
      login         = "[REPLACE_THIS]";
      senha         = "[REPLACE_THIS]";
      codigocliente = [REPLACE_THIS]
      codigoEmpresa = [REPLACE_THIS]
      codigoSistema = $Map[$Sistema]
    }

    $auth = Invoke-RestMethod $authEndpoint -Method 'POST' -Headers $headers -Body $($body | ConvertTo-Json)
        
    if (-not $auth.autenticado) {
      throw "Falha na autenticacao"
    }
    $headers.Add("Authorization", "Bearer " + $auth.accessToken)
        
    $reauth = Invoke-RestMethod $reauthEndpoint -Method 'POST' -Headers $headers -Body $($body | ConvertTo-Json)
        
        
    if ((-not $Sso) -and (-not $Mobile)) {
      if ($Output) {
        return Write-Output $reauth.accessToken
      }
      $reauth.accessToken | clip
      return    
    }

    $Body["refreshToken"] = $reauth.refreshToken 

    $magic = Invoke-RestMethod $ssoEndpoint -Method 'POST' -Headers $headers -Body $($body | ConvertTo-Json)
    if (-not $Mobile) {
      if ($Output) {
                
        return Write-Output $magic
      }
      $magic | clip
      return 
    }
    $scheme = $MobileMap[$Sistema]
    npx uri-scheme open "$($scheme)://sso?sso=$magic" --android
  }
}


function Get-ExitTime {
  param(
    [datetime]$Entrada,
    [datetime]$Almoco,
    [datetime]$Retorno
  )
  return timer $($($(CalcularSaida -Entrada $Entrada -Almoco $Almoco -Retorno $Retorno -Output).TimeOfDay.TotalSeconds) - $([datetime]::Now.TimeOfDay.TotalSeconds)); Show-Notification -ToastTitle 'É hora de partir!'
}

function totp {
  Get-TOTP -SharedSecret $env:TORRA_TOTP_SHARED_SECRET
}

function Coluna {
  param(
    [switch]$Speak
  )
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
  if ($Speak) {
    tts $message
  }
  Show-Notification -ToastTitle "Coluna!" -ToastText $message -IconUri "https://atlas-content-cdn.pixelsquid.com/assets_v2/240/2409631179109046100/jpeg-600/G03.jpg" -Group 'posture_notification' -Tag 'posture_notification'
  Coluna -silent:$silent
}

function Agua {
  param(
    [switch]$Speak
  )
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
  if ($Speak) {
    tts $message
  }
  Show-Notification -ToastTitle "Olha a áaagua!" -ToastText $message -IconUri "https://png.pngtree.com/png-clipart/20240615/original/pngtree-glass-with-water-isolated-png-image_15329246.png" -Group 'water_notification' -Tag 'water_notification'
  Agua -silent:$silent
}
 
function Get-AdoPipelineStatus {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$ExecutionUrl
  )
  $run = $true;
  while ($run) {
    try {
      if ($ExecutionUrl -match "https:\/\/dev\.azure\.com\/([^\/]+)\/([^\/]+)\/_build\/results\?buildId=(\d+)") {
        $org = $matches[1]
        $project = $matches[2]
        $buildId = $matches[3]
      }
      else {
        throw "Invalid Azure DevOps pipeline URL format."
      }
      $apiUrl = "https://dev.azure.com/$org/$project/_apis/build/builds/$($buildId)?api-version=7.0"
      $encodedPAT = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:PAT)"))
      $headers = @{
        "Authorization" = "Basic $encodedPAT"
      }
      $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
      $payload = [PSCustomObject]@{
        BuildId    = $response.id
        Status     = $response.status
        Result     = $response.result
        QueueTime  = $response.queueTime
        StartTime  = $response.startTime
        FinishTime = $response.finishTime
      }
            
      if ($response.status -eq 'completed') {
        $run = $false
        return $payload   
      }
      timer 30               
    }
    catch {
      Write-Error "Failed to retrieve pipeline status: $($_.Exception.Message)"
      $run = $false
    }
  }
}
#endregion Functions

#region ALIASES
Set-Alias insomnia "$($env:USERPROFILE)\AppData\Local\insomnia\Insomnia.exe"
Set-Alias postman "$($env:USERPROFILE)\AppData\Local\Postman\Postman.exe"
Set-Alias la GetAllFiles
Set-Alias ssms "C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\SSMS.exe"
Set-Alias vi vim
Set-Alias unmined unmined-cli.exe

## PERSONAL_VARIABLES
$env:PAT = "[REPLACE_THIS]"
$env:GOOGLE_TOKEN = "[REPLACE_THIS]"
$env:PSGToken = "[REPLACE_THIS]"

$env:disc_darthside = "REPLACE_THIS"
$env:DISCORD_WEBHOOK = "[REPLACE_THIS]"
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:NODE_ENV = 'development'
 
$env:JAVA_HOME = "C:\Users\[REPLACE_THIS]\Tools\jdk-25.0.1"
$env:ANDROID_HOME = "c:\Android\Sdk"
$env:Path = "${env:Path};${env:USERPROFILE}\tools\vim"
$env:Path = "${env:Path};${env:USERPROFILE}\tools\unmined"
$env:Path = "${env:Path};${env:JAVA_HOME}\bin;${env:ANDROID_HOME}\emulator;${env:ANDROID_HOME}\tools;${env:ANDROID_HOME}\tools\bin;${env:ANDROID_HOME}\platform-tools"
$env:Path = "${env:Path};${env:LOCALAPPDATA}\Microsoft\dotnet\"

$ChocolateyProfile = "${env:ChocolateyInstall}\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
#endregion ALIASES

$now = [Datetime]::Now
Show-Notification -ToastTitle 'Olha a coluna' -ToastText 'Nao esqueca de iniciar o lembrete da coluna.' -Schedule $now.AddSeconds(10)
Show-Notification -ToastTitle 'Olha a aaaagua' -ToastText 'Nao esqueca de iniciar o lembrete da agua.' -Schedule $now.AddSeconds(30)
# start-job -FilePath C:\Users\rodrigo.cordeiro\Documents\WindowsPowerShell\lembrete_agua.ps1 -Name lembrete_agua | Out-Null