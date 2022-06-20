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
    if(!$Webhook){
        $Webhook = $env:disc_testes
    }

    Invoke-WebRequest -Uri $Webhook -Method POST -Headers $headers -WebSession $session -Body "$($body | ConvertTo-Json)" -ErrorAction SilentlyContinue
}
Export-ModuleMember -Function Discord

function Update-Repos {
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
    #         New-Item -Type File -Name package.json -Value $content
    #     } else {
    #         return $False
        # }
    # }
    
    # $projectFolders = $(Get-ChildItem -Path "~/projetos" -depth 0 -Recurse)
    # $f = 'pda'
    $folders = Get-Repositories
    # $repositories = @()
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
            if($git -and $(git remote -v | Select-String 'fetch')){
                # $branch = $(git branch | select-string "\*").ToString().split(" ")[1]
                # UpdatePDAlib
                $git_dir = $(Split-Path -Path $(git rev-parse --show-toplevel) -Leaf)
                $git_index = $PWD.ToString().IndexOf($git_dir)
                $CmdPromptCurrentFolder = $PWD.ToString().Substring($git_index)

                git add .
                git commit -m '[skip ci] Updating repositories'
                git pull origin --all
                git push -u origin --all
                Discord -Avatar "https://rodcordeiro.github.io/shares/img/eu.jpg" -Content "Atualizado o $CmdPromptCurrentFolder" -Username "Script do rod" -Webhook $env:disc_darthside
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

function Timer{
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        $Time
    )
    # Timeout /T $time    
    node -e "setTimeout(()=>console.log('Time finished'),$($Time * 1000))"
}
Export-ModuleMember -Function Timer



<#
 INFORMATION
  From this point below, there's the imported and useful functions that I'm not the creator. 
  Some of them I remembered to keep the author name/url. Sorry for those who I didn't credited enough.
#>

# Author: Microsoft
# URL: 

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

# Author: Adam the Automator
# URL: https://github.com/adbertram/Random-PowerShell-Work/blob/master/PowerShell%20Internals/Write-Params.ps1
function Write-Param
{
	<#
	.SYNOPSIS
		Write-Param is a simple function that writes the parameters used for the calling function out to the console. This is useful
		 in debugging situations where you have function "trees" where you have dozens of functions calling each and want to see
		what parameters are being passed to each function via the console.
	
		No need to pass any parameters to Write-Param. It uses the PS call stack to find what function called it and all the parameters
		used.
        
		
	.EXAMPLE
		function MyFunction {
			param(
				[Parameter()]
				[string]$Param1,
	
				[Parameter()]
				[string]$Param2
			)
	
			Write-Params
		}
	
		PS> MyFunction -Param1 'hello' -Param2 'whatsup'
		
		This example would output the following to the Verbose stream:
	
		Function: Get-LocalGroup - Params used: {Param1=hello, Param2=whatsup}
		
	#>
	[CmdletBinding()]
	param ()
	$caller = (Get-PSCallStack)[1]
	Write-Verbose -Message "Function: $($caller.Command) - Params used: $($caller.Arguments)"
}

Export-ModuleMember -Function Write-Param

# Author: Adam the Automator
# URL: https://github.com/adbertram/Random-PowerShell-Work/blob/master/PowerShell%20Internals/ConvertTo-CleanScript.ps1
function ConvertTo-CleanScript
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Path,
	
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string[]]$ToRemove = ''
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try
		{
			$Ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)	
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
}
Export-ModuleMember -Function ConvertTo-CleanScript

# Author: Adam the Automator
# URL: https://github.com/adbertram/Random-PowerShell-Work/blob/master/Random%20Stuff/Invoke-WindowsDiskCleanup.ps1
Function Invoke-ClearDisk
{
    Write-Log -Message 'Clearing CleanMgr.exe automation settings.'

    $getItemParams = @{
        Path        = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*'
        Name        = 'StateFlags0001'
        ErrorAction = 'SilentlyContinue'
    }
    Get-ItemProperty @getItemParams | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue

    $enabledSections = @(
        'Active Setup Temp Folders'
        'BranchCache'
        'Content Indexer Cleaner'
        'Device Driver Packages'
        'Downloaded Program Files'
        'GameNewsFiles'
        'GameStatisticsFiles'
        'GameUpdateFiles'
        'Internet Cache Files'
        'Memory Dump Files'
        'Offline Pages Files'
        'Old ChkDsk Files'
        'Previous Installations'
        'Recycle Bin'
        'Service Pack Cleanup'
        'Setup Log Files'
        'System error memory dump files'
        'System error minidump files'
        'Temporary Files'
        'Temporary Setup Files'
        'Temporary Sync Files'
        'Thumbnail Cache'
        'Update Cleanup'
        'Upgrade Discarded Files'
        'User file versions'
        'Windows Defender'
        'Windows Error Reporting Archive Files'
        'Windows Error Reporting Queue Files'
        'Windows Error Reporting System Archive Files'
        'Windows Error Reporting System Queue Files'
        'Windows ESD installation files'
        'Windows Upgrade Log Files'
    )

    Write-Verbose -Message 'Adding enabled disk cleanup sections...'
    foreach ($keyName in $enabledSections) {
        $newItemParams = @{
            Path         = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$keyName"
            Name         = 'StateFlags0001'
            Value        = 1
            PropertyType = 'DWord'
            ErrorAction  = 'SilentlyContinue'
        }
        $null = New-ItemProperty @newItemParams
    }

    Write-Verbose -Message 'Starting CleanMgr.exe...'
    Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -NoNewWindow -Wait

    Write-Verbose -Message 'Waiting for CleanMgr and DismHost processes...'
    Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process

}

Export-ModuleMember -Function Invoke-ClearDisk

# Author: Adam the Automator
# URL: https://github.com/adbertram/Random-PowerShell-Work/blob/master/Random%20Stuff/Confirm-Choice.ps1
function Confirm-Choice {
	[OutputType('boolean')]
	[CmdletBinding()]
	param
	(		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$Title,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$PromptMessage
	)

	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	
	if ($PSBoundParameters.ContainsKey('Title')) {
		Write-Host -Object $Title -ForegroundColor Cyan	
	}
	
	Write-Host -Object $PromptMessage -ForegroundColor Cyan	
	$result = $host.ui.PromptForChoice($null, $null, $Options, 1) 

	switch ($result) {
		0 {
			$true
		}
		1 {
			$false
		}
	}
}

Export-ModuleMember -Function Confirm-Choice