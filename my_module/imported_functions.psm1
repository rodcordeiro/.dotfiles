<#
 .DESCRIPTION
  Here lies the functions that I'm not the author but they're really usefull on my daily activities,
  or just for some interesting works. Some of them I remembered to keep the author name/url.
  Sorry for those who I didn't credited enough.
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

function ConvertFrom-Timestamp {
    param (
        [String]$unixTimeStamp,
        [Alias('V')][Switch]$Verbose
    )
    $epochStart = Get-Date 01.01.1970 
    $millisStamp = ($epochStart + ([System.TimeSpan]::frommilliseconds($unixTimeStamp))).ToLocalTime()
    $millisStampOutput = $millisStamp.ToString("yyyy-MM-dd HH:mm:ss.ffffff")
    # $millisStampClipboard = $millisStamp.ToString("HH:mm:ss.ffffff") 
    if($Verbose){ 
        Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        Write-Host "Datetime: $millisStampOutput" -ForegroundColor Cyan
        # Write-Host "Clipping: $millisStampClipboard" -ForegroundColor Cyan
        Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"    
    } else {
        Write-Host $millisStampOutput
    }

    # $millisStampClipboard = $millisStamp.ToString("HH:mm:ss.ffffff") | clip
}
Export-ModuleMember -Function ConvertFrom-Timestamp

# Author: Warren Frame
# Url: https://github.com/RamblingCookieMonster/PowerShell/blob/master/Get-ScheduledTasks.ps1
function Get-ScheduledTasks {  
    <#
    .SYNOPSIS
        Get scheduled task information from a system
    
    .DESCRIPTION
        Get scheduled task information from a system

        Uses Schedule.Service COM object, falls back to SchTasks.exe as needed.
        When we fall back to SchTasks, we add empty properties to match the COM object output.

    .PARAMETER ComputerName
        One or more computers to run this against

    .PARAMETER Folder
        Scheduled tasks folder to query.  By default, "\"

    .PARAMETER Recurse
        If specified, recurse through folders below $folder.
        
        Note:  We also recurse if we use SchTasks.exe

    .PARAMETER Path
        If specified, path to export XML files
        
        Details:
            Naming scheme is computername-taskname.xml
            Please note that the base filename is used when importing a scheduled task.  Rename these as needed prior to importing!

    .PARAMETER Exclude
        If specified, exclude tasks matching this regex (we use -notmatch $exclude)

    .PARAMETER CompatibilityMode
        If specified, pull scheduled tasks only with the schtasks.exe command, which works against older systems.
    
        Notes:
            Export is not possible with this switch.
            Recurse is implied with this switch.
    
    .EXAMPLE
    
        #Get scheduled tasks from the root folder of server1 and c-is-ts-91
        Get-ScheduledTasks server1, c-is-ts-91

    .EXAMPLE

        #Get scheduled tasks from all folders on server1, not in a Microsoft folder
        Get-ScheduledTasks server1 -recurse -Exclude "\\Microsoft\\"

    .EXAMPLE
    
        #Get scheduled tasks from all folders on server1, not in a Microsoft folder, and export in XML format (can be used to import scheduled tasks)
        Get-ScheduledTasks server1 -recurse -Exclude "\\Microsoft\\" -path 'D:\Scheduled Tasks'

    .NOTES
    
        Properties returned    : When they will show up
            ComputerName       : All queries
            Name               : All queries
            Path               : COM object queries, added synthetically if we fail back from COM to SchTasks
            Enabled            : COM object queries
            Action             : All queries.  Schtasks.exe queries include both Action and Arguments in this property
            Arguments          : COM object queries
            UserId             : COM object queries
            LastRunTime        : All queries
            NextRunTime        : All queries
            Status             : All queries
            Author             : All queries
            RunLevel           : COM object queries
            Description        : COM object queries
            NumberOfMissedRuns : COM object queries

        Thanks to help from Brian Wilhite, Jaap Brasser, and Jan Egil's functions:
            http://gallery.technet.microsoft.com/scriptcenter/Get-SchedTasks-Determine-5e04513f
            http://gallery.technet.microsoft.com/scriptcenter/Get-Scheduled-tasks-from-3a377294
            http://blog.crayon.no/blogs/janegil/archive/2012/05/28/working_2D00_with_2D00_scheduled_2D00_tasks_2D00_from_2D00_windows_2D00_powershell.aspx

    .FUNCTIONALITY
        Computers

    #>
    [cmdletbinding(
        DefaultParameterSetName='COM'
    )]
    param(
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0
        )]
        [Alias("host","server","computer")]
        [string[]]$ComputerName = "localhost",

        [parameter()]
        [string]$folder = "\",

        [parameter(ParameterSetName='COM')]
        [switch]$recurse,

        [parameter(ParameterSetName='COM')]
        [validatescript({
            #Test path if provided, otherwise allow $null
            if($_){
                Test-Path -PathType Container -path $_ 
            }
            else {
                $true
            }
        })]
        [string]$Path = $null,

        [parameter()]
        [string]$Exclude = $null,

        [parameter(ParameterSetName='SchTasks')]
        [switch]$CompatibilityMode
    )
    Begin{

        if(-not $CompatibilityMode){
            $sch = New-Object -ComObject Schedule.Service
        
            #thanks to Jaap Brasser - http://gallery.technet.microsoft.com/scriptcenter/Get-Scheduled-tasks-from-3a377294
            function Get-AllTaskSubFolders {
                [cmdletbinding()]
                param (
                    # Set to use $Schedule as default parameter so it automatically list all files
                    # For current schedule object if it exists.
                    $FolderRef = $sch.getfolder("\"),

                    [switch]$recurse
                )

                #No recurse?  Return the folder reference
                if (-not $recurse) {
                    $FolderRef
                }
                #Recurse?  Build up an array!
                else {
                    Try{
                        #This will fail on older systems...
                        $folders = $folderRef.getfolders(1)

                        #Extract results into array
                        $ArrFolders = @(
                            if($folders) {
                                foreach ($fold in $folders) {
                                    $fold
                                    if($fold.getfolders(1)) {
                                        Get-AllTaskSubFolders -FolderRef $fold
                                    }
                                }
                            }
                        )
                    }
                    Catch{
                        #If we failed and the expected error, return folder ref only!
                        if($_.tostring() -like '*Exception calling "GetFolders" with "1" argument(s): "The request is not supported.*')
                        {
                            $folders = $null
                            Write-Warning "GetFolders failed, returning root folder only: $_"
                            Return $FolderRef
                        }
                        else{
                            Throw $_
                        }
                    }

                    #Return only unique results
                        $Results = @($ArrFolders) + @($FolderRef)
                        $UniquePaths = $Results | select -ExpandProperty path -Unique
                        $Results | ?{$UniquePaths -contains $_.path}
                }
            } #Get-AllTaskSubFolders
        }

        function Get-SchTasks {
            [cmdletbinding()]
            param([string]$computername, [string]$folder, [switch]$CompatibilityMode)
            
            #we format the properties to match those returned from com objects
            $result = @( schtasks.exe /query /v /s $computername /fo csv |
                convertfrom-csv |
                ?{$_.taskname -ne "taskname" -and $_.taskname -match $( $folder.replace("\","\\") ) } |
                select @{ label = "ComputerName"; expression = { $computername } },
                    @{ label = "Name"; expression = { $_.TaskName } },
                    @{ label = "Action"; expression = {$_."Task To Run"} },
                    @{ label = "LastRunTime"; expression = {$_."Last Run Time"} },
                    @{ label = "NextRunTime"; expression = {$_."Next Run Time"} },
                    "Status",
                    "Author"
            )

            if($CompatibilityMode){
                #User requested compat mode, don't add props
                $result    
            }
            else{
                #If this was a failback, we don't want to affect display of props for comps that don't fail... include empty props expected for com object
                #We also extract task name and path to parent for the Name and Path props, respectively
                foreach($item in $result){
                    $name = @( $item.Name -split "\\" )[-1]
                    $taskPath = $item.name
                    $item | select ComputerName, @{ label = "Name"; expression = {$name}}, @{ label = "Path"; Expression = {$taskPath}}, Enabled, Action, Arguments, UserId, LastRunTime, NextRunTime, Status, Author, RunLevel, Description, NumberOfMissedRuns
                }
            }
        } #Get-SchTasks
    }    
    Process{
        #loop through computers
        foreach($computer in $computername){
        
            #bool in case com object fails, fall back to schtasks
            $failed = $false
        
            write-verbose "Running against $computer"
            Try {
            
                #use com object unless in compatibility mode.  Set compatibility mode if this fails
                if(-not $compatibilityMode){      

                    Try{
                        #Connect to the computer
                        $sch.Connect($computer)
                        
                        if($recurse)
                        {
                            $AllFolders = Get-AllTaskSubFolders -FolderRef $sch.GetFolder($folder) -recurse -ErrorAction stop
                        }
                        else
                        {
                            $AllFolders = Get-AllTaskSubFolders -FolderRef $sch.GetFolder($folder) -ErrorAction stop
                        }
                        Write-verbose "Looking through $($AllFolders.count) folders on $computer"
                
                        foreach($fold in $AllFolders){
                
                            #Get tasks in this folder
                            $tasks = $fold.GetTasks(0)
                
                            Write-Verbose "Pulling data from $($tasks.count) tasks on $computer in $($fold.name)"
                            foreach($task in $tasks){
                            
                                #extract helpful items from XML
                                $Author = ([regex]::split($task.xml,'<Author>|</Author>'))[1] 
                                $UserId = ([regex]::split($task.xml,'<UserId>|</UserId>'))[1] 
                                $Description =([regex]::split($task.xml,'<Description>|</Description>'))[1]
                                $Action = ([regex]::split($task.xml,'<Command>|</Command>'))[1]
                                $Arguments = ([regex]::split($task.xml,'<Arguments>|</Arguments>'))[1]
                                $RunLevel = ([regex]::split($task.xml,'<RunLevel>|</RunLevel>'))[1]
                                $LogonType = ([regex]::split($task.xml,'<LogonType>|</LogonType>'))[1]
                            
                                #convert state to status
                                Switch ($task.State) { 
                                    0 {$Status = "Unknown"} 
                                    1 {$Status = "Disabled"} 
                                    2 {$Status = "Queued"} 
                                    3 {$Status = "Ready"} 
                                    4 {$Status = "Running"} 
                                }

                                #output the task details
                                if(-not $exclude -or $task.Path -notmatch $Exclude){
                                    $task | select @{ label = "ComputerName"; expression = { $computer } }, 
                                        Name,
                                        Path,
                                        Enabled,
                                        @{ label = "Action"; expression = {$Action} },
                                        @{ label = "Arguments"; expression = {$Arguments} },
                                        @{ label = "UserId"; expression = {$UserId} },
                                        LastRunTime,
                                        NextRunTime,
                                        @{ label = "Status"; expression = {$Status} },
                                        @{ label = "Author"; expression = {$Author} },
                                        @{ label = "RunLevel"; expression = {$RunLevel} },
                                        @{ label = "Description"; expression = {$Description} },
                                        NumberOfMissedRuns
                            
                                    #if specified, output the results in importable XML format
                                    if($path){
                                        $xml = $task.Xml
                                        $taskname = $task.Name
                                        $xml | Out-File $( Join-Path $path "$computer-$taskname.xml" )
                                    }
                                }
                            }
                        }
                    }
                    Catch{
                        Write-Warning "Could not pull scheduled tasks from $computer using COM object, falling back to schtasks.exe"
                        Try{
                            Get-SchTasks -computername $computer -folder $folder -ErrorAction stop
                        }
                        Catch{
                            Write-Error "Could not pull scheduled tasks from $computer using schtasks.exe:`n$_"
                            Continue
                        }
                    }             
                }

                #otherwise, use schtasks
                else{
                
                    Try{
                        Get-SchTasks -computername $computer -folder $folder -CompatibilityMode -ErrorAction stop
                    }
                     Catch{
                        Write-Error "Could not pull scheduled tasks from $computer using schtasks.exe:`n$_"
                        Continue
                     }
                }

            }
            Catch{
                Write-Error "Error pulling Scheduled tasks from $computer`: $_"
                Continue
            }
        }
    }
}

#Author: Warren Frame  
# https://github.com/RamblingCookieMonster/PowerShell/blob/master/Get-UserSession.ps1
function Get-UserSession {
    <#  
    .SYNOPSIS  
        Retrieves all user sessions from local or remote computers(s)
    
    .DESCRIPTION
        Retrieves all user sessions from local or remote computer(s).
        
        Note:   Requires query.exe in order to run
        Note:   This works against Windows Vista and later systems provided the following registry value is in place
                HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\AllowRemoteRPC = 1
        Note:   If query.exe takes longer than 15 seconds to return, an error is thrown and the next computername is processed.  Suppress this with -erroraction silentlycontinue
        Note:   If $sessions is empty, we return a warning saying no users.  Suppress this with -warningaction silentlycontinue
    
    .PARAMETER computername
        Name of computer(s) to run session query against
                  
    .parameter parseIdleTime
        Parse idle time into a timespan object
    
    .parameter timeout
        Seconds to wait before ending query.exe process.  Helpful in situations where query.exe hangs due to the state of the remote system.
                        
    .FUNCTIONALITY
        Computers
    
    .EXAMPLE
        Get-usersession -computername "server1"
    
        Query all current user sessions on 'server1'
    
    .EXAMPLE
        Get-UserSession -computername $servers -parseIdleTime | ?{$_.idletime -gt [timespan]"1:00"} | ft -AutoSize
    
        Query all servers in the array $servers, parse idle time, check for idle time greater than 1 hour.
    
    .NOTES
        Thanks to Boe Prox for the ideas - http://learn-powershell.net/2010/11/01/quick-hit-find-currently-logged-on-users/
    
    .LINK
        http://gallery.technet.microsoft.com/Get-UserSessions-Parse-b4c97837
    
    #> 
        [cmdletbinding()]
        Param(
            [Parameter(
                Position = 0,
                ValueFromPipeline = $True)]
            [string[]]$computername = "localhost",
    
            [switch]$parseIdleTime,
    
            [validaterange(0,120)]$timeout = 15
        )             
    
        ForEach($computer in $computername) {
            
            #start query.exe using .net and cmd /c.  We do this to avoid cases where query.exe hangs
    
                #build temp file to store results.  Loop until this works
                    Do{
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        start-sleep -Milliseconds 300
                    }
                    Until(test-path $tempfile)
    
                #Record date.  Start process to run query in cmd.  I use starttime independently of process starttime due to a few issues we ran into
                    $startTime = Get-Date
                    $p = Start-Process -FilePath C:\windows\system32\cmd.exe -ArgumentList "/c query user /server:$computer > $tempfile" -WindowStyle hidden -passthru
    
                #we can't read in info or else it will freeze.  We cant run waitforexit until we read the standard output, or we run into issues...
                #handle timeouts on our own by watching hasexited
                    $stopprocessing = $false
                    do{
                        
                        #check if process has exited
                        $hasExited = $p.HasExited
                    
                        #check if there is still a record of the process
                        Try { $proc = get-process -id $p.id -ErrorAction stop }
                        Catch { $proc = $null }
    
                        #sleep a bit
                        start-sleep -seconds .5
    
                        #check if we have timed out, unless the process has exited
                        if( ( (Get-Date) - $startTime ).totalseconds -gt $timeout -and -not $hasExited -and $proc){
                            $p.kill()
                            $stopprocessing = $true
                            remove-item $tempfile -force
                            Write-Error "$computer`: Query.exe took longer than $timeout seconds to execute"
                        }
                    }
                    until($hasexited -or $stopProcessing -or -not $proc)
                    if($stopprocessing){ Continue }
    
                    #if we are still processing, read the output!
                    $sessions = get-content $tempfile
                    remove-item $tempfile -force
            
            #handle no results
            if($sessions){
    
                1..($sessions.count -1) | % {
                
                    #Start to build the custom object
                    $temp = "" | Select ComputerName, Username, SessionName, Id, State, IdleTime, LogonTime
                    $temp.ComputerName = $computer
    
                    #The output of query.exe is dynamic. 
                    #strings should be 82 chars by default, but could reach higher depending on idle time.
                    #we use arrays to handle the latter.
    
                    if($sessions[$_].length -gt 5){
                        #if the length is normal, parse substrings
                        if($sessions[$_].length -le 82){
                               
                            $temp.Username = $sessions[$_].Substring(1,22).trim()
                            $temp.SessionName = $sessions[$_].Substring(23,19).trim()
                            $temp.Id = $sessions[$_].Substring(42,4).trim()
                            $temp.State = $sessions[$_].Substring(46,8).trim()
                            $temp.IdleTime = $sessions[$_].Substring(54,11).trim()
                            $logonTimeLength = $sessions[$_].length - 65
                            try{
                                $temp.LogonTime = get-date $sessions[$_].Substring(65,$logonTimeLength).trim()
                            }
                            catch{
                                $temp.LogonTime = $sessions[$_].Substring(65,$logonTimeLength).trim() | out-null
                            }
    
                        }
                        #Otherwise, create array and parse
                        else{                                       
                            $array = $sessions[$_] -replace "\s+", " " -split " "
                            $temp.Username = $array[1]
                    
                            #in some cases the array will be missing the session name.  array indices change
                            if($array.count -lt 9){
                                $temp.SessionName = ""
                                $temp.Id = $array[2]
                                $temp.State = $array[3]
                                $temp.IdleTime = $array[4]
                                $temp.LogonTime = get-date $($array[5] + " " + $array[6] + " " + $array[7])
                            }
                            else{
                                $temp.SessionName = $array[2]
                                $temp.Id = $array[3]
                                $temp.State = $array[4]
                                $temp.IdleTime = $array[5]
                                $temp.LogonTime = get-date $($array[6] + " " + $array[7] + " " + $array[8])
                            }
                        }
    
                        #if specified, parse idle time to timespan
                        if($parseIdleTime){
                            $string = $temp.idletime
                    
                            #quick function to handle minutes or hours:minutes
                            function convert-shortIdle {
                                param($string)
                                if($string -match "\:"){
                                    [timespan]$string
                                }
                                else{
                                    New-TimeSpan -minutes $string
                                }
                            }
                    
                            #to the left of + is days
                            if($string -match "\+"){
                                $days = new-timespan -days ($string -split "\+")[0]
                                $hourMin = convert-shortIdle ($string -split "\+")[1]
                                $temp.idletime = $days + $hourMin
                            }
                            #. means less than a minute
                            elseif($string -like "." -or $string -like "none"){
                                $temp.idletime = [timespan]"0:00"
                            }
                            #hours and minutes
                            else{
                                $temp.idletime = convert-shortIdle $string
                            }
                        }
                    
                        #Output the result
                        $temp
                    }
                }
            }            
            else{ Write-warning "$computer`: No sessions found" }
        }
    }


#Author: Warren Frame
#URL: https://github.com/RamblingCookieMonster/PowerShell/blob/master/New-DynamicParam.ps1

Function New-DynamicParam {
    <#
        .SYNOPSIS
            Helper function to simplify creating dynamic parameters
        
        .DESCRIPTION
            Helper function to simplify creating dynamic parameters
    
            Example use cases:
                Include parameters only if your environment dictates it
                Include parameters depending on the value of a user-specified parameter
                Provide tab completion and intellisense for parameters, depending on the environment
    
            Please keep in mind that all dynamic parameters you create will not have corresponding variables created.
               One of the examples illustrates a generic method for populating appropriate variables from dynamic parameters
               Alternatively, manually reference $PSBoundParameters for the dynamic parameter value
    
        .NOTES
            Credit to http://jrich523.wordpress.com/2013/05/30/powershell-simple-way-to-add-dynamic-parameters-to-advanced-function/
                Added logic to make option set optional
                Added logic to add RuntimeDefinedParameter to existing DPDictionary
                Added a little comment based help
    
            Credit to BM for alias and type parameters and their handling
    
        .PARAMETER Name
            Name of the dynamic parameter
    
        .PARAMETER Type
            Type for the dynamic parameter.  Default is string
    
        .PARAMETER Alias
            If specified, one or more aliases to assign to the dynamic parameter
    
        .PARAMETER ValidateSet
            If specified, set the ValidateSet attribute of this dynamic parameter
    
        .PARAMETER Mandatory
            If specified, set the Mandatory attribute for this dynamic parameter
    
        .PARAMETER ParameterSetName
            If specified, set the ParameterSet attribute for this dynamic parameter
    
        .PARAMETER Position
            If specified, set the Position attribute for this dynamic parameter
    
        .PARAMETER ValueFromPipelineByPropertyName
            If specified, set the ValueFromPipelineByPropertyName attribute for this dynamic parameter
    
        .PARAMETER HelpMessage
            If specified, set the HelpMessage for this dynamic parameter
        
        .PARAMETER DPDictionary
            If specified, add resulting RuntimeDefinedParameter to an existing RuntimeDefinedParameterDictionary (appropriate for multiple dynamic parameters)
            If not specified, create and return a RuntimeDefinedParameterDictionary (appropriate for a single dynamic parameter)
    
            See final example for illustration
    
        .EXAMPLE
            
            function Show-Free
            {
                [CmdletBinding()]
                Param()
                DynamicParam {
                    $options = @( gwmi win32_volume | %{$_.driveletter} | sort )
                    New-DynamicParam -Name Drive -ValidateSet $options -Position 0 -Mandatory
                }
                begin{
                    #have to manually populate
                    $drive = $PSBoundParameters.drive
                }
                process{
                    $vol = gwmi win32_volume -Filter "driveletter='$drive'"
                    "{0:N2}% free on {1}" -f ($vol.Capacity / $vol.FreeSpace),$drive
                }
            } #Show-Free
    
            Show-Free -Drive <tab>
    
        # This example illustrates the use of New-DynamicParam to create a single dynamic parameter
        # The Drive parameter ValidateSet populates with all available volumes on the computer for handy tab completion / intellisense
    
        .EXAMPLE
    
        # I found many cases where I needed to add more than one dynamic parameter
        # The DPDictionary parameter lets you specify an existing dictionary
        # The block of code in the Begin block loops through bound parameters and defines variables if they don't exist
    
            Function Test-DynPar{
                [cmdletbinding()]
                param(
                    [string[]]$x = $Null
                )
                DynamicParam
                {
                    #Create the RuntimeDefinedParameterDictionary
                    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            
                    New-DynamicParam -Name AlwaysParam -ValidateSet @( gwmi win32_volume | %{$_.driveletter} | sort ) -DPDictionary $Dictionary
    
                    #Add dynamic parameters to $dictionary
                    if($x -eq 1)
                    {
                        New-DynamicParam -Name X1Param1 -ValidateSet 1,2 -mandatory -DPDictionary $Dictionary
                        New-DynamicParam -Name X1Param2 -DPDictionary $Dictionary
                        New-DynamicParam -Name X3Param3 -DPDictionary $Dictionary -Type DateTime
                    }
                    else
                    {
                        New-DynamicParam -Name OtherParam1 -Mandatory -DPDictionary $Dictionary
                        New-DynamicParam -Name OtherParam2 -DPDictionary $Dictionary
                        New-DynamicParam -Name OtherParam3 -DPDictionary $Dictionary -Type DateTime
                    }
            
                    #return RuntimeDefinedParameterDictionary
                    $Dictionary
                }
                Begin
                {
                    #This standard block of code loops through bound parameters...
                    #If no corresponding variable exists, one is created
                        #Get common parameters, pick out bound parameters not in that set
                        Function _temp { [cmdletbinding()] param() }
                        $BoundKeys = $PSBoundParameters.keys | Where-Object { (get-command _temp | select -ExpandProperty parameters).Keys -notcontains $_}
                        foreach($param in $BoundKeys)
                        {
                            if (-not ( Get-Variable -name $param -scope 0 -ErrorAction SilentlyContinue ) )
                            {
                                New-Variable -Name $Param -Value $PSBoundParameters.$param
                                Write-Verbose "Adding variable for dynamic parameter '$param' with value '$($PSBoundParameters.$param)'"
                            }
                        }
    
                    #Appropriate variables should now be defined and accessible
                        Get-Variable -scope 0
                }
            }
    
        # This example illustrates the creation of many dynamic parameters using New-DynamicParam
            # You must create a RuntimeDefinedParameterDictionary object ($dictionary here)
            # To each New-DynamicParam call, add the -DPDictionary parameter pointing to this RuntimeDefinedParameterDictionary
            # At the end of the DynamicParam block, return the RuntimeDefinedParameterDictionary
            # Initialize all bound parameters using the provided block or similar code
    
        .FUNCTIONALITY
            PowerShell Language
    
    #>
    param(
        
        [string]
        $Name,
        
        [System.Type]
        $Type = [string],
    
        [string[]]
        $Alias = @(),
    
        [string[]]
        $ValidateSet,
        
        [switch]
        $Mandatory,
        
        [string]
        $ParameterSetName="__AllParameterSets",
        
        [int]
        $Position,
        
        [switch]
        $ValueFromPipelineByPropertyName,
        
        [string]
        $HelpMessage,
    
        [validatescript({
            if(-not ( $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] -or -not $_) )
            {
                Throw "DPDictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object, or not exist"
            }
            $True
        })]
        $DPDictionary = $false
     
    )
        #Create attribute object, add attributes, add to collection   
            $ParamAttr = New-Object System.Management.Automation.ParameterAttribute
            $ParamAttr.ParameterSetName = $ParameterSetName
            if($mandatory)
            {
                $ParamAttr.Mandatory = $True
            }
            if($Position -ne $null)
            {
                $ParamAttr.Position=$Position
            }
            if($ValueFromPipelineByPropertyName)
            {
                $ParamAttr.ValueFromPipelineByPropertyName = $True
            }
            if($HelpMessage)
            {
                $ParamAttr.HelpMessage = $HelpMessage
            }
     
            $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
            $AttributeCollection.Add($ParamAttr)
        
        #param validation set if specified
            if($ValidateSet)
            {
                $ParamOptions = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet
                $AttributeCollection.Add($ParamOptions)
            }
    
        #Aliases if specified
            if($Alias.count -gt 0) {
                $ParamAlias = New-Object System.Management.Automation.AliasAttribute -ArgumentList $Alias
                $AttributeCollection.Add($ParamAlias)
            }
    
     
        #Create the dynamic parameter
            $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)
        
        #Add the dynamic parameter to an existing dynamic parameter dictionary, or create the dictionary and add it
            if($DPDictionary)
            {
                $DPDictionary.Add($Name, $Parameter)
            }
            else
            {
                $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
                $Dictionary.Add($Name, $Parameter)
                $Dictionary
            }
    }

#Author: Warren Frame
#Link: https://github.com/RamblingCookieMonster/PowerShell/blob/master/ConvertTo-FlatObject.ps1
Function ConvertTo-FlatObject {
    <#
    .SYNOPSIS
        Flatten an object to simplify discovery of data

    .DESCRIPTION
        Flatten an object.  This function will take an object, and flatten the properties using their full path into a single object with one layer of properties.

        You can use this to flatten XML, JSON, and other arbitrary objects.

        This can simplify initial exploration and discovery of data returned by APIs, interfaces, and other technologies.

        NOTE:
            Use tools like Get-Member, Select-Object, and Show-Object to further explore objects.
            This function does not handle certain data types well.  It was original designed to expand XML and JSON.

    .PARAMETER InputObject
        Object to flatten

    .PARAMETER Exclude
        Exclude any nodes in this list.  Accepts wildcards.

        Example:
            -Exclude price, title

    .PARAMETER ExcludeDefault
        Exclude default properties for sub objects.  True by default.

        This simplifies views of many objects (e.g. XML) but may exclude data for others (e.g. if flattening a process, ProcessThread properties will be excluded)

    .PARAMETER Include
        Include only leaves in this list.  Accepts wildcards.

        Example:
            -Include Author, Title

    .PARAMETER Value
        Include only leaves with values like these arguments.  Accepts wildcards.

    .PARAMETER MaxDepth
        Stop recursion at this depth.

    .INPUTS
        Any object

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .EXAMPLE

        #Pull unanswered PowerShell questions from StackExchange, Flatten the data to date a feel for the schema
        Invoke-RestMethod "https://api.stackexchange.com/2.0/questions/unanswered?order=desc&sort=activity&tagged=powershell&pagesize=10&site=stackoverflow" |
            ConvertTo-FlatObject -Include Title, Link, View_Count

            $object.items[0].owner.link : http://stackoverflow.com/users/1946412/julealgon
            $object.items[0].view_count : 7
            $object.items[0].link       : http://stackoverflow.com/questions/26910789/is-it-possible-to-reuse-a-param-block-across-multiple-functions
            $object.items[0].title      : Is it possible to reuse a &#39;param&#39; block across multiple functions?
            $object.items[1].owner.link : http://stackoverflow.com/users/4248278/nitin-tyagi
            $object.items[1].view_count : 8
            $object.items[1].link       : http://stackoverflow.com/questions/26909879/use-powershell-to-retreive-activated-features-for-sharepoint-2010
            $object.items[1].title      : Use powershell to retreive Activated features for sharepoint 2010
            ...

    .EXAMPLE

        #Set up some XML to work with
        $object = [xml]'
            <catalog>
               <book id="bk101">
                  <author>Gambardella, Matthew</author>
                  <title>XML Developers Guide</title>
                  <genre>Computer</genre>
                  <price>44.95</price>
               </book>
               <book id="bk102">
                  <author>Ralls, Kim</author>
                  <title>Midnight Rain</title>
                  <genre>Fantasy</genre>
                  <price>5.95</price>
               </book>
            </catalog>'

        #Call the flatten command against this XML
            ConvertTo-FlatObject $object -Include Author, Title, Price

            #Result is a flattened object with the full path to the node, using $object as the root.
            #Only leaf properties we specified are included (author,title,price)

                $object.catalog.book[0].author : Gambardella, Matthew
                $object.catalog.book[0].title  : XML Developers Guide
                $object.catalog.book[0].price  : 44.95
                $object.catalog.book[1].author : Ralls, Kim
                $object.catalog.book[1].title  : Midnight Rain
                $object.catalog.book[1].price  : 5.95

        #Invoking the property names should return their data if the orginal object is in $object:
            $object.catalog.book[1].price
                5.95

            $object.catalog.book[0].title
                XML Developers Guide

    .EXAMPLE

        #Set up some XML to work with
            [xml]'<catalog>
               <book id="bk101">
                  <author>Gambardella, Matthew</author>
                  <title>XML Developers Guide</title>
                  <genre>Computer</genre>
                  <price>44.95</price>
               </book>
               <book id="bk102">
                  <author>Ralls, Kim</author>
                  <title>Midnight Rain</title>
                  <genre>Fantasy</genre>
                  <price>5.95</price>
               </book>
            </catalog>' |
                ConvertTo-FlatObject -exclude price, title, id

        Result is a flattened object with the full path to the node, using XML as the root.  Price and title are excluded.

            $Object.catalog                : catalog
            $Object.catalog.book           : {book, book}
            $object.catalog.book[0].author : Gambardella, Matthew
            $object.catalog.book[0].genre  : Computer
            $object.catalog.book[1].author : Ralls, Kim
            $object.catalog.book[1].genre  : Fantasy

    .EXAMPLE
        #Set up some XML to work with
            [xml]'<catalog>
               <book id="bk101">
                  <author>Gambardella, Matthew</author>
                  <title>XML Developers Guide</title>
                  <genre>Computer</genre>
                  <price>44.95</price>
               </book>
               <book id="bk102">
                  <author>Ralls, Kim</author>
                  <title>Midnight Rain</title>
                  <genre>Fantasy</genre>
                  <price>5.95</price>
               </book>
            </catalog>' |
                ConvertTo-FlatObject -Value XML*, Fantasy

        Result is a flattened object filtered by leaves that matched XML* or Fantasy

            $Object.catalog.book[0].title : XML Developers Guide
            $Object.catalog.book[1].genre : Fantasy

    .EXAMPLE
        #Get a single process with all props, flatten this object.  Don't exclude default properties
        Get-Process | select -first 1 -skip 10 -Property * | ConvertTo-FlatObject -ExcludeDefault $false

        #NOTE - There will likely be bugs for certain complex objects like this.
                For example, $Object.StartInfo.Verbs.SyncRoot.SyncRoot... will loop until we hit MaxDepth. (Note: SyncRoot is now addressed individually)

    .NOTES
        I have trouble with algorithms.  If you have a better way to handle this, please let me know!

    .FUNCTIONALITY
        General Command
    #>
    [cmdletbinding()]
    param(

        [parameter( Mandatory = $True,
                    ValueFromPipeline = $True)]
        [PSObject[]]$InputObject,

        [string[]]$Exclude = "",

        [bool]$ExcludeDefault = $True,

        [string[]]$Include = $null,

        [string[]]$Value = $null,

        [int]$MaxDepth = 10
    )
    Begin
    {
        #region FUNCTIONS

            #Before adding a property, verify that it matches a Like comparison to strings in $Include...
            Function IsIn-Include {
                param($prop)
                if(-not $Include) {$True}
                else {
                    foreach($Inc in $Include)
                    {
                        if($Prop -like $Inc)
                        {
                            $True
                        }
                    }
                }
            }

            #Before adding a value, verify that it matches a Like comparison to strings in $Value...
            Function IsIn-Value {
                param($val)
                if(-not $Value) {$True}
                else {
                    foreach($string in $Value)
                    {
                        if($val -like $string)
                        {
                            $True
                        }
                    }
                }
            }

            Function Get-Exclude {
                [cmdletbinding()]
                param($obj)

                #Exclude default props if specified, and anything the user specified.  Thanks to Jaykul for the hint on [type]!
                    if($ExcludeDefault)
                    {
                        Try
                        {
                            $DefaultTypeProps = @( $obj.gettype().GetProperties() | Select -ExpandProperty Name -ErrorAction Stop )
                            if($DefaultTypeProps.count -gt 0)
                            {
                                Write-Verbose "Excluding default properties for $($obj.gettype().Fullname):`n$($DefaultTypeProps | Out-String)"
                            }
                        }
                        Catch
                        {
                            Write-Verbose "Failed to extract properties from $($obj.gettype().Fullname): $_"
                            $DefaultTypeProps = @()
                        }
                    }

                    @( $Exclude + $DefaultTypeProps ) | Select -Unique
            }

            #Function to recurse the Object, add properties to object
            Function Recurse-Object {
                [cmdletbinding()]
                param(
                    $Object,
                    [string[]]$path = '$Object',
                    [psobject]$Output,
                    $depth = 0
                )

                # Handle initial call
                    Write-Verbose "Working in path $Path at depth $depth"
                    Write-Debug "Recurse Object called with PSBoundParameters:`n$($PSBoundParameters | Out-String)"
                    $Depth++

                #Exclude default props if specified, and anything the user specified.
                    $ExcludeProps = @( Get-Exclude $object )

                #Get the children we care about, and their names
                    $Children = $object.psobject.properties | Where {$ExcludeProps -notcontains $_.Name }
                    Write-Debug "Working on properties:`n$($Children | select -ExpandProperty Name | Out-String)"

                #Loop through the children properties.
                foreach($Child in @($Children))
                {
                    $ChildName = $Child.Name
                    $ChildValue = $Child.Value

                    Write-Debug "Working on property $ChildName with value $($ChildValue | Out-String)"
                    # Handle special characters...
                        if($ChildName -match '[^a-zA-Z0-9_]')
                        {
                            $FriendlyChildName = "'$ChildName'"
                        }
                        else
                        {
                            $FriendlyChildName = $ChildName
                        }

                    #Add the property.
                        if((IsIn-Include $ChildName) -and (IsIn-Value $ChildValue) -and $Depth -le $MaxDepth)
                        {
                            $ThisPath = @( $Path + $FriendlyChildName ) -join "."
                            $Output | Add-Member -MemberType NoteProperty -Name $ThisPath -Value $ChildValue
                            Write-Verbose "Adding member '$ThisPath'"
                        }

                    #Handle null...
                        if($ChildValue -eq $null)
                        {
                            Write-Verbose "Skipping NULL $ChildName"
                            continue
                        }

                    #Handle evil looping.  Will likely need to expand this.  Any thoughts on a better approach?
                        if(
                            (
                                $ChildValue.GetType() -eq $Object.GetType() -and
                                $ChildValue -is [datetime]
                            ) -or
                            (
                                $ChildName -eq "SyncRoot" -and
                                -not $ChildValue
                            )
                        )
                        {
                            Write-Verbose "Skipping $ChildName with type $($ChildValue.GetType().fullname)"
                            continue
                        }

                     #Check for arrays by checking object type (this is a fix for arrays with 1 object) otherwise check the count of objects
                        if (($ChildValue.GetType()).basetype.Name -eq "Array") {
                            $IsArray = $true
                        }
                        else {
                            $IsArray = @($ChildValue).count -gt 1
                        }

                        $count = 0

                    #Set up the path to this node and the data...
                        $CurrentPath = @( $Path + $FriendlyChildName ) -join "."

                    #Exclude default props if specified, and anything the user specified.
                        $ExcludeProps = @( Get-Exclude $ChildValue )

                    #Get the children's children we care about, and their names.  Also look for signs of a hashtable like type
                        $ChildrensChildren = $ChildValue.psobject.properties | Where {$ExcludeProps -notcontains $_.Name }
                        $HashKeys = if($ChildValue.Keys -notlike $null -and $ChildValue.Values)
                        {
                            $ChildValue.Keys
                        }
                        else
                        {
                            $null
                        }
                        Write-Debug "Found children's children $($ChildrensChildren | select -ExpandProperty Name | Out-String)"

                    #If we aren't at max depth or a leaf...
                    if(
                        (@($ChildrensChildren).count -ne 0 -or $HashKeys) -and
                        $Depth -lt $MaxDepth
                    )
                    {
                        #This handles hashtables.  But it won't recurse...
                            if($HashKeys)
                            {
                                Write-Verbose "Working on hashtable $CurrentPath"
                                foreach($key in $HashKeys)
                                {
                                    Write-Verbose "Adding value from hashtable $CurrentPath['$key']"
                                    $Output | Add-Member -MemberType NoteProperty -name "$CurrentPath['$key']" -value $ChildValue["$key"]
                                    $Output = Recurse-Object -Object $ChildValue["$key"] -Path "$CurrentPath['$key']" -Output $Output -depth $depth
                                }
                            }
                        #Sub children?  Recurse!
                            else
                            {
                                if($IsArray)
                                {
                                    foreach($item in @($ChildValue))
                                    {
                                        Write-Verbose "Recursing through array node '$CurrentPath'"
                                        $Output = Recurse-Object -Object $item -Path "$CurrentPath[$count]" -Output $Output -depth $depth
                                        $Count++
                                    }
                                }
                                else
                                {
                                    Write-Verbose "Recursing through node '$CurrentPath'"
                                    $Output = Recurse-Object -Object $ChildValue -Path $CurrentPath -Output $Output -depth $depth
                                }
                            }
                        }
                    }

                $Output
            }

        #endregion FUNCTIONS
    }
    Process
    {
        Foreach($Object in $InputObject)
        {
            #Flatten the XML and write it to the pipeline
                Recurse-Object -Object $Object -Output $( New-Object -TypeName PSObject )
        }
    }
}

#Author: Ivo Dias
#URL: https://github.com/IGDEXE/PS-Google-Catch/blob/master/GoogleSearch.psm1
function Get-GoogleAnswer {
    param (
        $mensagemErro
    )

    # Abre uma pesquisa com o termo que deu erro
    Start-Process "https://www.google.com/search?q=$mensagemErro"
}






Export-ModuleMember -Function '*'