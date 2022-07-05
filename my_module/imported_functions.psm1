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