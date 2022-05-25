Add-Type -AssemblyName PresentationCore, PresentationFramework

function Show-Calendar {
<#
 .Synopsis
  Displays a visual representation of a calendar.

 .Description
  Displays a visual representation of a calendar. This function supports multiple months
  and lets you highlight specific date ranges or days.

 .Parameter Start
  The first month to display.

 .Parameter End
  The last month to display.

 .Parameter FirstDayOfWeek
  The day of the month on which the week begins.

 .Parameter HighlightDay
  Specific days (numbered) to highlight. Used for date ranges like (25..31).
  Date ranges are specified by the Windows PowerShell range syntax. These dates are
  enclosed in square brackets.

 .Parameter HighlightDate
  Specific days (named) to highlight. These dates are surrounded by asterisks.

 .Example
   # Show a default display of this month.
   Show-Calendar

 .Example
   # Display a date range.
   Show-Calendar -Start "March, 2010" -End "May, 2010"

 .Example
   # Highlight a range of days.
   Show-Calendar -HighlightDay (1..10 + 22) -HighlightDate "December 25, 2008"
#>
param(
        [DateTime] $start = [DateTime]::Today,
        [DateTime] $end = $start,
        $firstDayOfWeek,
        [int[]] $highlightDay,
        [string[]] $highlightDate = [DateTime]::Today.ToString()
    )
    
    ## Determine the first day of the start and end months.
    $start = New-Object DateTime $start.Year, $start.Month, 1
    $end = New-Object DateTime $end.Year, $end.Month, 1
    
    ## Convert the highlighted dates into real dates.
    [DateTime[]] $highlightDate = [DateTime[]] $highlightDate
    
    ## Retrieve the DateTimeFormat information so that the
    ## calendar can be manipulated.
    $dateTimeFormat = (Get-Culture).DateTimeFormat
    if ($firstDayOfWeek) {
        $dateTimeFormat.FirstDayOfWeek = $firstDayOfWeek
    }
    
    $currentDay = $start
    
    ## Process the requested months.
    while ($start -le $end) {
        ## Return to an earlier point in the function if the first day of the month
        ## is in the middle of the week.
        while ($currentDay.DayOfWeek -ne $dateTimeFormat.FirstDayOfWeek) {
            $currentDay = $currentDay.AddDays(-1)
        }
    
        ## Prepare to store information about this date range.
        $currentWeek = New-Object PsObject
        $dayNames = @()
        $weeks = @()
    
        ## Continue processing dates until the function reaches the end of the month.
        ## The function continues until the week is completed with
        ## days from the next month.
        while (($currentDay -lt $start.AddMonths(1)) -or
            ($currentDay.DayOfWeek -ne $dateTimeFormat.FirstDayOfWeek)) {
            ## Determine the day names to use to label the columns.
            $dayName = "{0:ddd}" -f $currentDay
            if ($dayNames -notcontains $dayName) {
                $dayNames += $dayName
            }
    
            ## Pad the day number for display, highlighting if necessary.
            $displayDay = " {0,2} " -f $currentDay.Day
    
            ## Determine whether to highlight a specific date.
            if ($highlightDate) {
                $compareDate = New-Object DateTime $currentDay.Year,
                $currentDay.Month, $currentDay.Day
                if ($highlightDate -contains $compareDate) {
                    $displayDay = "*" + ("{0,2}" -f $currentDay.Day) + "*"
                }
            }
    
            ## Otherwise, highlight as part of a date range.
            if ($highlightDay -and ($highlightDay[0] -eq $currentDay.Day)) {
                $displayDay = "[" + ("{0,2}" -f $currentDay.Day) + "]"
                $null, $highlightDay = $highlightDay
            }
    
            ## Add the day of the week and the day of the month as note properties.
            $currentWeek | Add-Member NoteProperty $dayName $displayDay
    
            ## Move to the next day of the month.
            $currentDay = $currentDay.AddDays(1)
    
            ## If the function reaches the next week, store the current week
            ## in the week list and continue.
            if ($currentDay.DayOfWeek -eq $dateTimeFormat.FirstDayOfWeek) {
                $weeks += $currentWeek
                $currentWeek = New-Object PsObject
            }
        }
    
        ## Format the weeks as a table.
        $calendar = $weeks | Format-Table $dayNames -AutoSize | Out-String
    
        ## Add a centered header.
        $width = ($calendar.Split("`n") | Measure-Object -Maximum Length).Maximum
        $header = "{0:MMMM yyyy}" -f $start
        $padding = " " * (($width - $header.Length) / 2)
        $displayCalendar = " `n" + $padding + $header + "`n " + $calendar
        $displayCalendar.TrimEnd()
    
        ## Move to the next month.
        $start = $start.AddMonths(1)
    
    }
}
Export-ModuleMember -Function Show-Calendar

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
        [parameter(HelpMessage = "Allows to run quietly")][Alias('s','q')][Switch]$Quiet
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
    if(!$Quiet) {
     [console]::beep(440, 1000)
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

Export-ModuleMember -Function clone


function Get-Repositories {
    $projectFolders = $(Get-ChildItem -Path "~/projetos" -depth 0 -Recurse)
    $repos = $($projectFolders | ForEach-Object {
        $f = $_
        $folders = $(Get-ChildItem -Path "~/projetos/$_" -depth 0 -Recurse) | ForEach-Object {"~/projetos/$f/$_"}
        $repositories = @()
        $folders | ForEach-Object {
            $folder = $_
            Set-Location $folder
            $git = isInsideGit
            if($(git remote -v | Select-String 'fetch')){
                $remote = $($(git remote -v | Select-String 'fetch').ToString().split('')[1])
                $branches = $(git branches | select-string -Pattern "  remotes")
                $result = [pscustomobject]@{
                    "repo"     = "$remote";
                    "branches" = @($branches | select-string -Pattern "HEAD" -NotMatch | ForEach-Object { $_.ToString().Replace("  remotes/origin/",'') });
                    "alias"    = "$(Split-Path -Path $(Resolve-Path -Path $folder) -Leaf)"
                }
        
                $repositories += $result
            }
        }
        $data = [pscustomobject]@{
            "Parent"="~/projetos/$_";
            "repos" = $($repositories | ConvertTo-Json)
        }
        $data
    })
    $($repos | ConvertTo-Json)
}

Export-ModuleMember -Function Get-Repositories

function Download-Repositories {
    param(
        [parameter(ValueFromPipelineByPropertyName)]$Repos
    )
    $Repos | ForEach-Object {
        $Folder = $_
        if($($(Test-Path -Path $(Resolve-Path -Path $Folder.Parent)) -eq $True)){
            Set-Location $Folder.Parent
            $repos = $($Folder.repos | ConvertFrom-Json)
            $repos | ForEach-Object {
                clone -Alias $_.alias -Folder $Folder -Path $_.repo
                if ($_.branches){
                    $_.branches  | ForEach-Object {
                        git checkout $_
                        git pull --set-upstream origin $_
                    }
                }
                git push -u origin --all                
            }
        } else {
            New-Item -Type Directory $Folder.Parent
            Set-Location $Folder.Parent
            $repos = $($Folder.repos | ConvertFrom-Json)
            $repos | ForEach-Object {
                clone -Alias $_.alias -Folder $Folder -Path $_.repo
                if ($_.branches){
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

Function Discord{
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]$Content,
        [parameter(ValueFromPipelineByPropertyName)][String]$Username = "Lord Vader",
        [parameter(ValueFromPipelineByPropertyName)][String]$Avatar = "https://rodcordeiro.github.io/shares/img/vader.png",
        [parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]$Webhook
    )
    $headers=@{}
    $headers.Add("Content-Type", "application/json")
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $cookie = New-Object System.Net.Cookie
    $cookie.Name = '__dcfduid'
    $cookie.Value = '70ead174dc3e11ec93a222460b8f3269'
    $cookie.Domain = 'discord.com'
    $session.Cookies.Add($cookie)
    $cookie = New-Object System.Net.Cookie
    $cookie.Name = '__sdcfduid'
    $cookie.Value = '70ead174dc3e11ec93a222460b8f3269fc65095b989f46f97df0c8ab371d8eda42a59488273f8ee85f051879a758bd2d'
    $cookie.Domain = 'discord.com'
    $session.Cookies.Add($cookie)
    $cookie = New-Object System.Net.Cookie
    $cookie.Name = '__cfruid'
    $cookie.Value = '6b1779458ec0c7a52d5c3823f010c6c2bc22c533-1653492128'
    $cookie.Domain = 'discord.com'
    $session.Cookies.Add($cookie)
    $git_dir = $(Split-Path -Path $(git rev-parse --show-toplevel) -Leaf)
    $git_index = $PWD.ToString().IndexOf($git_dir)
    $CmdPromptCurrentFolder = $PWD.ToString().Substring($git_index)
    if(!$Content){
        $Content="Some hello"
    }
    $content = @{
        "content"=$Content;
        "username"= $Username;
        "avatar_url"= $Avatar
    }
    $Webhook = $env:Discord_Webhook
    $($content | ConvertTo-Json)
    Invoke-WebRequest -Uri $Webhook -Method POST -Headers $headers -WebSession $session -Body "$($content | ConvertTo-Json)"
}
Export-ModuleMember -Function Discord


function Update-Repos {
    function hasPdaLib{
        $pkg = $(get-Content -Path .\package.json | ConvertFrom-Json)
        $dependencies = $($pkg.Dependencies | Select-String "pdasolutions")
        
        if($dependencies){
            return $True
        } else {
            return $False
        }
    }
    function UpdatePDAlib{
        yarn remove @pdasolutions/web
        yarn add @pdasolucoes/web
        
        $pkg = $(get-Content -Path .\package.json | ConvertFrom-Json)
        $scripts = $pkg.scripts.updateLib
        $scripts
        if($scripts){
            $content = $(get-Content -Path .\package.json).Replace("pdasolutions","pdasolucoes")
            Remove-Item .\package.json -Force
            New-Item -Type File -Name package.json -Value $content
        } else {
            return $False
        }
    }
    
    $projectFolders = $(Get-ChildItem -Path "~/projetos" -depth 0 -Recurse)
    $f = 'pda'
    $folders = $(Get-ChildItem -Path "~/projetos/$f" -depth 0 -Recurse) | ForEach-Object {"~/projetos/$f/$_"}
    # $repositories = @()
    $folders | ForEach-Object {
        $folder = $_
        Set-Location $folder
        $git = isInsideGit
        $lib = hasPdaLib
        if($git -and $lib){
            $branch = $(git branch | select-string "\*").ToString().split(" ")[1]
            UpdatePDAlib
            git add .
            git commit -m '[skip ci] Updating pda lib'
            git push
            Discord -Webhook $env:disc_darthside
      }
    }
}

Export-ModuleMember -Function Update-Repos