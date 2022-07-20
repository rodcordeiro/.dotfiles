Add-Type -AssemblyName PresentationCore, PresentationFramework

function Notify {
    <# 
    .SYNOPSIS 
        Shows a notification
    .DESCRIPTION
        Shows a notification modal on terminal, allowing to use as alert.
    .Parameter <Title>
        The modal title
    .Parameter <Message>
        The modal message
    .Parameter <Quiet>
        Allows to run silently
    .EXAMPLE
        notify -Title "Title" -Message "Some usefull message"
    .EXAMPLE
        notify -Title Title -Message Usefull_message
    .EXAMPLE
        notify Title "Some usefull message"
    #>
    
    param(
        [parameter(ValueFromPipelineByPropertyName, HelpMessage = "Please, enter the message title")][string]$Title,
        [parameter(ValueFromPipelineByPropertyName, HelpMessage = "Please, inform the message")][string]$Message,
        [parameter(HelpMessage = "Allows to run quietly")][Alias('s', 'q')][Switch]$Quiet
        # [parameter(ValueFromPipelineByPropertyName, HelpMessage = "Please, inform the notification type")][ValidateSet("Warning", "Info", "Error")][string]$Type
    )
    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    if (!$Title) {
        $Title = "Alerta !!"
    }
    if (!$Message) {
        $Message = "Terminei algo!"
    }
    
    
    #$msgBody = "Reboot the computer now?"
    # $msgTitle = "Confirm Reboot"
    # $msgButton = 'YesNoCancel'
    # $msgImage = 'Question'
    # $Result = [System.Windows.MessageBox]::Show($msgBody,$msgTitle,$msgButton,$msgImage)
    # Write-Host "The user chose: $Result [" ($result).value__ "]"
    if (!$Quiet) {
        # [console]::beep(440, 1000)
        (New-Object System.Media.SoundPlayer "C:\Windows\Media\chimes.wav").Play()
    }
    $Result = [System.Windows.MessageBox]::Show($Message, $Title, 0, 0)
}

Export-ModuleMember -Function Notify

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
        Write-Output "You must provide a repository to clone!"
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

Export-ModuleMember -Function clone


function Get-Repositories {
    $CurrentLocation = $PWD
    $projectFolders = $(Get-ChildItem -Path "~/projetos" -depth 0 -Recurse)
    $repos = $($projectFolders | ForEach-Object {
            $f = $_
            $folders = $(Get-ChildItem -Path "~/projetos/$_" -depth 0 -Recurse) | ForEach-Object { "~/projetos/$f/$_" }
            $repositories = @()
            $folders | ForEach-Object {
                $folder = $_
                Set-Location $folder
                $git = isInsideGit
                if ($(git remote -v | Select-String 'fetch')) {
                    $remote = $($(git remote -v | Select-String 'fetch').ToString().split('')[1])
                    $branches = $(git branches | select-string -Pattern "  remotes")
                    $result = [pscustomobject]@{
                        "repo"     = "$remote";
                        "branches" = @($branches | select-string -Pattern "HEAD" -NotMatch | ForEach-Object { $_.ToString().Replace("  remotes/origin/", '') });
                        "alias"    = "$(Split-Path -Path $(Resolve-Path -Path $folder) -Leaf)"
                    }
        
                    $repositories += $result
                }
            }
            $data = [pscustomobject]@{
                "Parent" = "~/projetos/$_";
                "repos"  = $($repositories | ConvertTo-Json)
            }
            $data
        })
    Set-Location $CurrentLocation
    $repos
}

Export-ModuleMember -Function Get-Repositories

function Import-Repositories {
    param(
        [parameter(ValueFromPipelineByPropertyName)]$Repos
    )
    $Repos | ForEach-Object {
        $Folder = $_
        if ($($(Test-Path -Path $(Resolve-Path -Path $Folder.Parent)) -eq $True)) {
            Set-Location $Folder.Parent
            $repos = $($Folder.repos | ConvertFrom-Json)
            $repos | ForEach-Object {
                clone -Alias $_.alias -Folder $Folder -Path $_.repo
                if ($_.branches) {
                    $_.branches  | ForEach-Object {
                        git checkout $_
                        git pull --set-upstream origin $_
                    }
                }
                git push -u origin --all                
            }
        }
        else {
            New-Item -Type Directory $Folder.Parent
            Set-Location $Folder.Parent
            $repos = $($Folder.repos | ConvertFrom-Json)
            $repos | ForEach-Object {
                clone -Alias $_.alias -Folder $Folder -Path $_.repo
                if ($_.branches) {
                    $_.branches  | ForEach-Object {
                        git checkout $_
                        git pull --set-upstream origin $_
                    }
                }
                git push -u origin --all                
            }
        }
    }
}

Export-ModuleMember -Function Download-Repositories

Function Discord {
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]$Content,
        [parameter(ValueFromPipelineByPropertyName)][String]$Username,
        [parameter(ValueFromPipelineByPropertyName)][String]$Avatar,
        [parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]$Webhook
    )
    $headers = @{}
    $headers.Add("Content-Type", "application/json")
    
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    
    if (!$Content) {
        $Content = "Some hello"
    }
    if (!$Avatar) {
        $Avatar = "https://rodcordeiro.github.io/shares/img/vader.png"
    }
    if (!$Username) {
        $Username = "Lord Vader"
    }
    $body = @{
        "content"    = $Content;
        "username"   = $Username;
        "avatar_url" = $Avatar
    }    
    if (!$Webhook) {
        $Webhook = $env:disc_testes
    }

    Invoke-WebRequest -Uri $Webhook -Method POST -Headers $headers -WebSession $session -Body "$($body | ConvertTo-Json)" -ErrorAction SilentlyContinue
}
Export-ModuleMember -Function Discord

# function hasPdaLib{
#     $pkg = $(get-Content -Path .\package.json | ConvertFrom-Json)
#     $dependencies = $($pkg.Dependencies | Select-String "pdasolutions")
        
#     if($dependencies){
#         return $True
#     } else {
#         return $False
#     }
# }
# function UpdatePDAlib{
#     yarn remove @pdasolutions/web
#     yarn add @pdasolucoes/web
        
#     $pkg = $(get-Content -Path .\package.json | ConvertFrom-Json)
#     $scripts = $pkg.scripts.updateLib
#     $scripts
#     if($scripts){
#         $content = $(get-Content -Path .\package.json).Replace("pdasolutions","pdasolucoes")
#         Remove-Item .\package.json -Force
#         New-Item -Type File -Name package.json -Value $content.ToString()
#     } else {
#         return $False
# }
# }
    

function Update-Repos {
    
    $folders = Get-Repositories
    Discord -Avatar "https://rodcordeiro.github.io/shares/img/eu.jpg" -Username "Script do rod" -Webhook $env:disc_testes -Content "Ignorem. Estou rodando um script de atualizacao automatica dos repositorios"
    $folders | ForEach-Object {
        $folder = $_
        $($Folder.repos | ConvertFrom-Json) | ForEach-Object {
            $repos = $_
            $repo = Resolve-Path -Path "$($folder.Parent)/$($repos.Alias)"
            Write-Output "Repo $repo"    
            Set-Location $repo
            $git = isInsideGit
            # $lib = hasPdaLib
            if ($git -and $(git remote -v | Select-String 'fetch')) {
                $branches = $(git branch | select-string -NotMatch "remote")
                $currentBranch = ''
                $branches | ForEach-Object {
                    if ($(git status | select-string "Changes not staged for commit") -or $(git status | select-string "Changes to be committed:")) {
                        git add .
                        git commit -m '[skip ci] Automatic repositories update'
                    }
                    git checkout $branch
                    $branch = $_.ToString().Replace(' ', '')
                    if ($branch -match '\*') {
                        $branch = $branch.split(" ")[1]
                        $currentBranch = $branch
                    }
                    
                    git add .
                    git commit -m '[skip ci] Automatic repositories update'
                    git pull origin 
                    git push -u origin $branch
                }
                Write-Output $currentBranch

                
                # UpdatePDAlib
                $git_dir = $(Split-Path -Path $(git rev-parse --show-toplevel) -Leaf)
                $git_index = $PWD.ToString().IndexOf($git_dir)
                $CmdPromptCurrentFolder = $PWD.ToString().Substring($git_index)

                Discord -Avatar "https://rodcordeiro.github.io/shares/img/eu.jpg" -Content "Atualizado o $CmdPromptCurrentFolder" -Username "Script do rod" -Webhook $env:disc_testes
            }
        }
    }
}

Export-ModuleMember -Function Update-Repos

Function ConvertTo-B64 {
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]$Content
    )
       
    node -e "const text = '$Content', p = Buffer.from(text.trim()).toString('base64');console.log(p);process.exit();"
}

Export-ModuleMember -Function ConvertTo-B64

function Timer {
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Time
    )
    
    node -e "const current = new Date();let time_to_await = $Time * 1000;const timer = current.getTime() + time_to_await,  timerParsed = new Date(timer);const interval = setInterval(() => {  if (time_to_await === 0) {    clearInterval(interval);  }  process.stdout.clearLine(0);  process.stdout.cursorTo(0);  process.stdout.write('Time remaining: '+time_to_await / 1000+'s');  time_to_await -= 1000;}, 1000);"
}
Export-ModuleMember -Function Timer

function ConvertTo-MarkdownTable {
    param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Columns,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory = $false)]
        [string[]]$RowsLabel,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$Rows,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory = $false)]
        [string]$OutFile
    )
    $table = @()
    $table += $(if ($RowsLabel) { '| ' }) + [String]::Join("", $($Columns | foreach-Object { "|$($_)" })) + "|"
    $table += $(if ($RowsLabel) { '|:- ' }) + [String]::Join("", $($Columns | foreach-Object { "|:-:" })) + "|"
    if ($RowsLabel) {
        $table += $RowsLabel | foreach-object {
            $app = $_ 
            return "|$app" + [String]::Join("", $($Columns | foreach-Object { "|$($Rows.$_.$app)" })) + "|"
        }
        
    }
    else {
        $table += $Rows | foreach-object {
            $row = $_
            return [String]::Join("", $($Columns | foreach-Object { "|$($row.$_)" })) + "|"
        }
    }
    if ($OutFile) {
        New-Item -Type file -Path $OutFile | Out-Null
        $table | ForEach-Object {
            Add-Content  -Path $OutFile -Value $_
        }
    }
    else {
        return $table
    }

}

Export-ModuleMember -Function ConvertTo-MarkdownTable
