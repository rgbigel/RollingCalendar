[CmdletBinding()]
param (
  [Parameter()]
  [string]$Time = '0',

  [Parameter()]
  [ValidateSet('1w', '2w', '3w', '4w')]
  [Alias('Frequ')]
  [string]$Frequency = '4w',

  [Parameter()]
  [Alias('o')]
  [string]$OutputDir = 'C:\Temp',

  [Parameter()]
  [switch]$NoShow,

  [Parameter()]
  [switch]$SendToPrinter,

  [Parameter()]
  [switch]$ResetUrl,

  [Alias('h', '?')]
  [switch]$Help
)

<#
.SYNOPSIS
    Renders a rolling calendar view (1 to 4 weeks from the current Monday)
    as a DIN A4 landscape PDF via Headless Edge.
.DESCRIPTION
    Module: RollingCalendar/Invoke-RollingCalendar.ps1
    Purpose: Renders a rolling Outlook ICS calendar as a landscape PDF.
    Path: RollingCalendar/Invoke-RollingCalendar.ps1
    Authors: rgbig
    Version: 1.1.0
    Date: 2026-09-30
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Help) {
  Write-Host 'Usage: pwsh -File Invoke-RollingCalendar.ps1 [-Time HH:mm|HHmm|yyyyMMdd_HHmm|yyyyMMdd_HHmmss] [-Frequency 1w|2w|3w|4w] [-OutputDir <directory>] [-NoShow] [-SendToPrinter] [-ResetUrl] [-Help]'
  return
}

$RegKeyPath = 'HKCU:\Environment'
$EnvVarName = 'OUTLOOK_ROLLING_CALENDAR_ICS_URL'

# ==============================================================================
# 1. SELF-ELEVATION (required when configuring Task Scheduler)
# ==============================================================================
function Test-IsAdmin {
  [CmdletBinding()]
  param()

  <#
  .SYNOPSIS
      Tests whether the current process is elevated.
  #>
  $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]$identity
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Resolve-ValidTime {
  [CmdletBinding()]
  param(
    [string]$RawTime
  )

  <#
  .SYNOPSIS
      Validates an interactive calendar export time.
  .PARAMETER RawTime
      The time value to validate.
  #>

  while ($true) {
    if ($RawTime -eq '0') { return $null }

    if ($RawTime -match '^\d{8}_(\d{2})(\d{2})(?:\d{2})?$') {
      $normalized = "$($Matches[1]):$($Matches[2])"
    }
    else {
      $normalized = $RawTime -replace '[^\d:]', ''
    }
    if ($normalized -match '^(\d{1,2}):(\d{2})$' -or $normalized -match '^(\d{1,2})(\d{2})$') {
      $h = [int]$Matches[1]
      $m = [int]$Matches[2]
      if ($h -ge 0 -and $h -le 23 -and $m -ge 0 -and $m -le 59) {
        return ('{0:D2}:{1:D2}' -f $h, $m)
      }
    }

    Write-Host ("Time value '$RawTime' is invalid (use HH:mm, HHmm, yyyyMMdd_HHmm, or yyyyMMdd_HHmmss).") -ForegroundColor Red
    $RawTime = Read-Host "Please enter a valid time (or '0' to skip task scheduling)"
  }
}

$parsedTime = Resolve-ValidTime -RawTime $Time

if ($parsedTime -and (-not (Test-IsAdmin))) {
  Write-Host 'Task scheduling requires administrator privileges. Starting elevation...' -ForegroundColor Yellow
  $allArgs = @('-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Time', "`"$parsedTime`"", '-Frequency', "`"$Frequency`"")
  $allArgs += @('-OutputDir', "`"$OutputDir`"")
  if ($NoShow)          { $allArgs += '-NoShow' }
  if ($SendToPrinter)   { $allArgs += '-SendToPrinter' }
  if ($ResetUrl)        { $allArgs += '-ResetUrl' }

  $pwshExe = (Get-Process -Id $PID).Path
  Start-Process -FilePath $pwshExe -ArgumentList $allArgs -Verb RunAs
  exit 0
}

# ==============================================================================
# 2. REGISTRY PERSISTENCE FOR ICS URL (HKCU:\Environment)
# ==============================================================================
function Test-IcsUrl {
  [CmdletBinding()]
  param(
    [string]$Url
  )

  <#
  .SYNOPSIS
      Tests whether an ICS URL returns calendar content.
  .PARAMETER Url
      The ICS URL to request.
  #>
  if ([string]::IsNullOrWhiteSpace($Url) -or -not ($Url -match '^https?://')) {
    return $false
  }
  try {
    Write-Host 'Checking ICS URL accessibility...' -ForegroundColor DarkGray
    $testReq = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 10 -UseBasicParsing
    return ($testReq.StatusCode -eq 200 -and $testReq.Content -match 'BEGIN:VCALENDAR')
  }
  catch {
    return $false
  }
}

function Get-OrPromptIcsUrl {
  [CmdletBinding()]
  param(
    [switch]$ForcePrompt,
    [string]$RegistryKeyPath,
    [string]$EnvironmentVariableName
  )

  <#
  .SYNOPSIS
      Retrieves a stored ICS URL or prompts for a validated replacement.
  .PARAMETER ForcePrompt
      Forces the interactive URL prompt.
  .PARAMETER RegistryKeyPath
      The registry key that stores the URL.
  .PARAMETER EnvironmentVariableName
      The environment-variable name used for the URL.
  #>

  $currentVal = $null
  if (Test-Path $RegistryKeyPath) {
    $registryValues = Get-ItemProperty -Path $RegistryKeyPath -Name $EnvironmentVariableName -ErrorAction SilentlyContinue
    $urlProperty = if ($registryValues) { $registryValues.PSObject.Properties[$EnvironmentVariableName] } else { $null }
    if ($urlProperty) {
      $currentVal = [string]$urlProperty.Value
    }
  }

  if ($ForcePrompt -or [string]::IsNullOrWhiteSpace($currentVal)) {
    if (-not $ForcePrompt) {
      Write-Warning "No stored ICS URL found at '$RegistryKeyPath\$EnvironmentVariableName'."
    }

    while ($true) {
      $inputUrl = (Read-Host 'Please enter the Outlook ICS publishing URL').Trim()
      if (Test-IcsUrl -Url $inputUrl) {
        if (-not (Test-Path $RegistryKeyPath)) {
          New-Item -Path $RegistryKeyPath -Force | Out-Null
        }
        Set-ItemProperty -Path $RegistryKeyPath -Name $EnvironmentVariableName -Value $inputUrl -Type String
        [Environment]::SetEnvironmentVariable($EnvironmentVariableName, $inputUrl, [EnvironmentVariableTarget]::Process)
        Write-Host 'URL successfully verified and saved to HKCU:\Environment.' -ForegroundColor Green
        return $inputUrl
      }
      else {
        Write-Host 'Invalid URL or no VCALENDAR response. Please try again.' -ForegroundColor Red
      }
    }
  }
  else {
    [Environment]::SetEnvironmentVariable($EnvironmentVariableName, $currentVal, [EnvironmentVariableTarget]::Process)
    return $currentVal
  }
}

# ==============================================================================
# 3. TASK SCHEDULER SETUP (non-retroactive)
# ==============================================================================
function Register-CalendarTask {
  [CmdletBinding()]
  param(
    [string]$ValidTime,
    [string]$Frequ,
    [string]$ScriptPath,
    [string]$OutputDir,
    [switch]$NoShow,
    [switch]$PrintOnCompletion
  )

  <#
  .SYNOPSIS
      Registers the recurring calendar export task.
  .PARAMETER ValidTime
      The validated task start time.
  .PARAMETER Frequ
      The recurrence interval in weeks.
  .PARAMETER ScriptPath
      The script invoked by the scheduled task.
    .PARAMETER OutputDir
      The directory for generated calendar files.
    .PARAMETER NoShow
      Suppresses opening the generated PDF after export.
  .PARAMETER PrintOnCompletion
      Adds the print option to the scheduled invocation.
  #>

  $weeksInterval = [int]($Frequ -replace 'w', '')
  $taskName      = 'Outlook-RollingCalendar-Export'
  $pwshExe       = (Get-Process -Id $PID).Path

  $now       = Get-Date
  $timeParts = $ValidTime.Split(':')

  # Determine next Monday
  $daysUntilMonday = ([int][DayOfWeek]::Monday - [int]$now.DayOfWeek)
  if ($daysUntilMonday -lt 0) { $daysUntilMonday += 7 }
  $candidate = $now.Date.AddDays($daysUntilMonday).AddHours([int]$timeParts[0]).AddMinutes([int]$timeParts[1])

  # Never schedule retroactively in the past
  if ($candidate -le $now) {
    $candidate = $candidate.AddDays(7)
  }

  $arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`" -Frequency $Frequ -OutputDir `"$OutputDir`""
  if ($NoShow) { $arguments += ' -NoShow' }
  if ($PrintOnCompletion) { $arguments += ' -SendToPrinter' }

  $action   = New-ScheduledTaskAction -Execute $pwshExe -Argument $arguments
  $trigger  = New-ScheduledTaskTrigger -Weekly -WeeksInterval $weeksInterval -DaysOfWeek Monday -At $candidate
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
  Write-Host ("Task schedule registered: Every $weeksInterval week(s) on Mondays at $ValidTime.") -ForegroundColor Green
  Write-Host ("Next scheduled run: $($candidate.ToString('MM/dd/yyyy HH:mm')) (calendar will be created immediately).") -ForegroundColor DarkGray
}

# ==============================================================================
# 4. INITIALIZATION & DATA RETRIEVAL
# ==============================================================================
$IcsUrl = Get-OrPromptIcsUrl -ForcePrompt:$ResetUrl -RegistryKeyPath $RegKeyPath -EnvironmentVariableName $EnvVarName

if ($parsedTime) {
  Register-CalendarTask -ValidTime $parsedTime -Frequ $Frequency -ScriptPath $PSCommandPath -OutputDir $OutputDir -NoShow:$NoShow -PrintOnCompletion:$SendToPrinter
}

# Time window calculation from current Monday
$today = (Get-Date).Date
$delta = [int]$today.DayOfWeek - 1
if ($delta -lt 0) { $delta = 6 }
$startMonday = $today.AddDays(-$delta)

$weekCount = [int]($Frequency -replace 'w', '')
$totalDays = $weekCount * 7
$endWindow = $startMonday.AddDays($totalDays)

Write-Host '[1/3] Fetching ICS calendar...' -ForegroundColor Cyan
try {
  $icsContent = Invoke-RestMethod -Uri $IcsUrl -Method Get -TimeoutSec 30
}
catch {
  Write-Warning 'Fetch failed. The sharing URL may have expired.'
  $IcsUrl     = Get-OrPromptIcsUrl -ForcePrompt
  $icsContent = Invoke-RestMethod -Uri $IcsUrl -Method Get -TimeoutSec 30
}

Write-Host "[2/3] Processing events incl. predecessor tasks and RRULE ($weekCount week(s))..." -ForegroundColor Cyan

# Unfold lines (RFC 5545 unfolding)
$unfoldedLines = [System.Collections.Generic.List[string]]::new()
$rawLines      = $icsContent -split "`r?`n"
for ($i = 0; $i -lt $rawLines.Length; $i++) {
  $line = $rawLines[$i]
  while (($i + 1 -lt $rawLines.Length) -and ($rawLines[$i + 1] -match '^[ \t]')) {
    $line += $rawLines[$i + 1].Substring(1)
    $i++
  }
  $unfoldedLines.Add($line)
}

$events = @{}

# Registers an event entry for each active day within the calendar window
function Add-SpanEvent {
  [CmdletBinding()]
  param(
    [datetime]$StartDate,
    [datetime]$EndDate,
    [string]$TimeStr,
  [string]$Summary,
  [datetime]$CalendarStart,
  [datetime]$CalendarEnd,
  [hashtable]$Events
  )

  <#
  .SYNOPSIS
    Adds a calendar event to each visible day in the calendar window.
  .PARAMETER StartDate
    The event start time.
  .PARAMETER EndDate
    The event end time.
  .PARAMETER TimeStr
    The display time for a timed event.
  .PARAMETER Summary
    The event summary.
  .PARAMETER CalendarStart
    The first visible calendar day.
  .PARAMETER CalendarEnd
    The exclusive end of the calendar window.
  .PARAMETER Events
    The mutable day-keyed event collection.
  #>

  # Overlap check with calendar window
  if ($StartDate -ge $CalendarEnd -or $EndDate -le $CalendarStart) {
    return
  }

  $loopDate = if ($StartDate -lt $CalendarStart) { $CalendarStart } else { $StartDate.Date }

  # All-day events have midnight as exclusive EndDate
  $lastDate = if ($EndDate.Date -lt $CalendarEnd) {
    if ($EndDate.TimeOfDay.TotalSeconds -eq 0 -and $EndDate -gt $StartDate) {
      $EndDate.Date.AddDays(-1)
    }
    else {
      $EndDate.Date
    }
  }
  else {
    $CalendarEnd.AddDays(-1)
  }

  $isMultiDay = ($EndDate - $StartDate).TotalHours -gt 24

  while ($loopDate -le $lastDate) {
    $dKey = $loopDate.ToString('yyyy-MM-dd')
    if (-not $Events.ContainsKey($dKey)) {
      $Events[$dKey] = [System.Collections.Generic.List[PSObject]]::new()
    }

    # Visual indicator when the event started before the calendar grid
    $displayPrefix = ''
    if ($loopDate -eq $CalendarStart -and $StartDate -lt $CalendarStart) {
      $displayPrefix = '>> '
    }

    $Events[$dKey].Add([PSCustomObject]@{
      Time       = if ($isMultiDay) { '' } else { $TimeStr }
      Summary    = "$displayPrefix$Summary"
      IsMultiDay = $isMultiDay
    })

    $loopDate = $loopDate.AddDays(1)
  }
}

# ICS parsing & recurrence expansion
$inEvent    = $false
$evSummary  = ''
$evDtStart  = ''
$evDtEnd    = ''
$evDuration = ''
$evRRule    = ''

foreach ($line in $unfoldedLines) {
  if ($line -match '^BEGIN:VEVENT') {
    $inEvent    = $true
    $evSummary  = 'Event'
    $evDtStart  = ''
    $evDtEnd    = ''
    $evDuration = ''
    $evRRule    = ''
  }
  elseif ($line -match '^END:VEVENT') {
    $inEvent = $false

    if ($evDtStart -match '(\d{4})(\d{2})(\d{2})') {
      $sYear   = [int]$Matches[1]
      $sMonth  = [int]$Matches[2]
      $sDay    = [int]$Matches[3]
      $sHour   = 0
      $sMin    = 0
      $hasTime = $false
      if ($evDtStart -match 'T(\d{2})(\d{2})') {
        $sHour   = [int]$Matches[1]
        $sMin    = [int]$Matches[2]
        $hasTime = $true
      }
      $baseStart = [datetime]::new($sYear, $sMonth, $sDay, $sHour, $sMin, 0)
      $timeStr   = if ($hasTime) { '{0:D2}:{1:D2}' -f $sHour, $sMin } else { '' }

      # Determine end date
      $baseEnd = $null
      if ($evDtEnd -match '(\d{4})(\d{2})(\d{2})') {
        $eYear  = [int]$Matches[1]
        $eMonth = [int]$Matches[2]
        $eDay   = [int]$Matches[3]
        $eHour  = 0
        $eMin   = 0
        if ($evDtEnd -match 'T(\d{2})(\d{2})') {
          $eHour = [int]$Matches[1]
          $eMin  = [int]$Matches[2]
        }
        $baseEnd = [datetime]::new($eYear, $eMonth, $eDay, $eHour, $eMin, 0)
      }
      elseif ($evDuration -match 'P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?)?') {
        $dDays   = if ($Matches[1]) { [int]$Matches[1] } else { 0 }
        $dHours  = if ($Matches[2]) { [int]$Matches[2] } else { 0 }
        $dMins   = if ($Matches[3]) { [int]$Matches[3] } else { 0 }
        $baseEnd = $baseStart.AddDays($dDays).AddHours($dHours).AddMinutes($dMins)
      }
      else {
        $baseEnd = if ($hasTime) { $baseStart } else { $baseStart.AddDays(1) }
      }

      $durationSpan = $baseEnd - $baseStart

      if ([string]::IsNullOrWhiteSpace($evRRule)) {
        Add-SpanEvent -StartDate $baseStart -EndDate $baseEnd -TimeStr $timeStr -Summary $evSummary -CalendarStart $startMonday -CalendarEnd $endWindow -Events $events
      }
      else {
        # Parse RRULE parameters
        $ruleParams = @{}
        $evRRule -replace '^RRULE:', '' -split ';' | ForEach-Object {
          $parts = $_ -split '='
          if ($parts.Length -eq 2) { $ruleParams[$parts[0]] = $parts[1] }
        }

        $freq      = $ruleParams['FREQ']
        $interval  = if ($ruleParams.ContainsKey('INTERVAL')) { [int]$ruleParams['INTERVAL'] } else { 1 }
        $untilDate = if ($ruleParams.ContainsKey('UNTIL') -and $ruleParams['UNTIL'] -match '(\d{4})(\d{2})(\d{2})') {
          [datetime]::ParseExact("$($Matches[1])-$($Matches[2])-$($Matches[3])", 'yyyy-MM-dd', $null)
        }
        else { $endWindow }

        $curStart  = $baseStart
        $stepCount = 0
        $maxLimit  = if ($ruleParams.ContainsKey('COUNT')) { [int]$ruleParams['COUNT'] } else { 500 }

        while ($curStart -lt $endWindow -and $curStart -le $untilDate -and $stepCount -lt $maxLimit) {
          $curEnd = $curStart + $durationSpan

          if ($freq -eq 'DAILY') {
            Add-SpanEvent -StartDate $curStart -EndDate $curEnd -TimeStr $timeStr -Summary $evSummary -CalendarStart $startMonday -CalendarEnd $endWindow -Events $events
            $curStart = $curStart.AddDays($interval)
          }
          elseif ($freq -eq 'WEEKLY') {
            if ($ruleParams.ContainsKey('BYDAY')) {
              $byDays   = $ruleParams['BYDAY'] -split ','
              $dayMap   = @{ 'MO' = 1; 'TU' = 2; 'WE' = 3; 'TH' = 4; 'FR' = 5; 'SA' = 6; 'SU' = 0 }
              $weekBase = $curStart.AddDays(-([int]$curStart.DayOfWeek))
              foreach ($bd in $byDays) {
                if ($dayMap.ContainsKey($bd)) {
                  $targetStart = $weekBase.AddDays($dayMap[$bd])
                  $targetEnd   = $targetStart + $durationSpan
                  if ($targetStart -ge $baseStart -and $targetStart -le $untilDate) {
                    Add-SpanEvent -StartDate $targetStart -EndDate $targetEnd -TimeStr $timeStr -Summary $evSummary -CalendarStart $startMonday -CalendarEnd $endWindow -Events $events
                  }
                }
              }
            }
            else {
              Add-SpanEvent -StartDate $curStart -EndDate $curEnd -TimeStr $timeStr -Summary $evSummary -CalendarStart $startMonday -CalendarEnd $endWindow -Events $events
            }
            $curStart = $curStart.AddDays(7 * $interval)
          }
          elseif ($freq -eq 'MONTHLY') {
            Add-SpanEvent -StartDate $curStart -EndDate $curEnd -TimeStr $timeStr -Summary $evSummary -CalendarStart $startMonday -CalendarEnd $endWindow -Events $events
            $curStart = $curStart.AddMonths($interval)
          }
          else {
            Add-SpanEvent -StartDate $curStart -EndDate $curEnd -TimeStr $timeStr -Summary $evSummary -CalendarStart $startMonday -CalendarEnd $endWindow -Events $events
            break
          }
          $stepCount++
        }
      }
    }
  }
  elseif ($inEvent) {
    if ($line -match '^SUMMARY:(.*)$') {
      $evSummary = $Matches[1] -replace '\\,', ',' -replace '\\;', ';'
    }
    elseif ($line -match '^DTSTART.*:(.*)$') {
      $evDtStart = $Matches[1]
    }
    elseif ($line -match '^DTEND.*:(.*)$') {
      $evDtEnd = $Matches[1]
    }
    elseif ($line -match '^DURATION.*:(.*)$') {
      $evDuration = $Matches[1]
    }
    elseif ($line -match '^RRULE:(.*)$') {
      $evRRule = $Matches[0]
    }
  }
}

# ==============================================================================
# 5. GENERATE PRINT HTML MATRIX
# ==============================================================================
$gridCellsHtml = ''
for ($d = 0; $d -lt $totalDays; $d++) {
  $cellDate     = $startMonday.AddDays($d)
  $key          = $cellDate.ToString('yyyy-MM-dd')
  $isTodayClass = if ($cellDate -eq $today) { ' is-today' } else { '' }

  $dayLabel = if ($cellDate.Day -eq 1 -or $d -eq 0) {
    '{0}. {1}' -f $cellDate.Day, ($cellDate.ToString('MMM'))
  }
  else {
    $cellDate.Day.ToString()
  }

  $eventItemsHtml = ''
  if ($events.ContainsKey($key)) {
    # All-day / multi-day events first, then sorted by time
    $sorted = $events[$key] | Sort-Object { -not $_.IsMultiDay }, { $_.Time }
    foreach ($ev in $sorted) {
      $prefix         = if ($ev.Time) { "<span class='event-time'>$($ev.Time)</span>" } else { '' }
      $multiClass     = if ($ev.IsMultiDay) { ' multiday' } else { '' }
      $eventItemsHtml += "<div class='event-item$multiClass'>$prefix$([System.Web.HttpUtility]::HtmlEncode($ev.Summary))</div>"
    }
  }

  $gridCellsHtml += @"
    <div class='day-cell$isTodayClass'>
      <div class='day-header'><span class='day-number'>$dayLabel</span></div>
      <div class='events-list'>$eventItemsHtml</div>
    </div>
"@
}

$periodStr = '{0:MM/dd/yyyy} - {1:MM/dd/yyyy}' -f $startMonday, ($startMonday.AddDays($totalDays - 1))
$titleStr  = "$weekCount-Week Preview ($periodStr)"

$fullHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>$titleStr</title>
  <style>
    :root {
      --border-color: #cbd5e1;
      --today-bg: #eff6ff;
      --header-bg: #f8fafc;
      --text-main: #0f172a;
      --accent: #2563eb;
      --multiday-bg: #e2e8f0;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      color: var(--text-main);
      padding: 0;
      background: #fff;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      padding: 6px 4px 4px 4px;
    }
    .title { font-size: 15px; font-weight: 700; }
    .period { font-size: 12px; color: #64748b; }
    .grid {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      grid-template-rows: 24px repeat($weekCount, 1fr);
      border-top: 1px solid var(--border-color);
      border-left: 1px solid var(--border-color);
      height: 185mm;
    }
    .weekday-header {
      background: var(--header-bg);
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      text-align: center;
      line-height: 24px;
      border-right: 1px solid var(--border-color);
      border-bottom: 1px solid var(--border-color);
    }
    .day-cell {
      border-right: 1px solid var(--border-color);
      border-bottom: 1px solid var(--border-color);
      padding: 4px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      page-break-inside: avoid;
    }
    .day-cell.is-today { background-color: var(--today-bg); }
    .day-header { display: flex; justify-content: flex-end; margin-bottom: 2px; }
    .day-number { font-size: 11px; font-weight: 700; color: #475569; }
    .day-cell.is-today .day-number {
      background: var(--accent);
      color: #fff;
      border-radius: 50%;
      width: 18px;
      height: 18px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }
    .events-list { flex: 1; display: flex; flex-direction: column; gap: 2px; overflow: hidden; }
    .event-item {
      font-size: 10px;
      background: #f1f5f9;
      border-left: 3px solid var(--accent);
      padding: 1px 3px;
      border-radius: 2px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      line-height: 1.25;
    }
    .event-item.multiday {
      background: var(--multiday-bg);
      border-left: 3px solid #64748b;
      font-weight: 500;
    }
    .event-time { font-weight: 700; color: #64748b; margin-right: 4px; }
    @page {
      size: landscape;
      margin: 8mm;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="title">$weekCount-Week Preview</div>
    <div class="period">$periodStr</div>
  </div>
  <div class="grid">
    <div class="weekday-header">Mon</div>
    <div class="weekday-header">Tue</div>
    <div class="weekday-header">Wed</div>
    <div class="weekday-header">Thu</div>
    <div class="weekday-header">Fri</div>
    <div class="weekday-header">Sat</div>
    <div class="weekday-header">Sun</div>
    $gridCellsHtml
  </div>
</body>
</html>
"@

if (-not (Test-Path -Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$tempHtml  = Join-Path -Path $OutputDir -ChildPath 'temp_calendar.html'
$outputPdf = Join-Path -Path $OutputDir -ChildPath "Calendar_${weekCount}W_$(Get-Date -Format 'yyyy-MM-dd').pdf"

Set-Content -Path $tempHtml -Value $fullHtml -Encoding utf8

# ==============================================================================
# 6. HEADLESS PDF EXPORT VIA EDGE
# ==============================================================================
function Invoke-EdgePdfExport {
  [CmdletBinding()]
  param(
    [string]$EdgePath,
    [string]$InputFileUri,
    [string]$OutputPdf
  )

  <#
  .SYNOPSIS
      Renders the calendar HTML to PDF with captured Edge diagnostics.
  .PARAMETER EdgePath
      The Edge executable path.
  .PARAMETER InputFileUri
      The calendar HTML file URI.
  .PARAMETER OutputPdf
      The expected PDF output path.
  #>

  if (-not (Test-Path -LiteralPath $EdgePath)) {
    throw "Microsoft Edge was not found at '$EdgePath'."
  }

  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $EdgePath
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  foreach ($argument in @(
      '--headless',
      '--disable-gpu',
      '--run-all-compositor-stages-before-draw',
      '--no-pdf-header-footer',
      "--print-to-pdf=$OutputPdf",
      $InputFileUri
    )) {
    $null = $startInfo.ArgumentList.Add($argument)
  }

  $edgeProcess = [System.Diagnostics.Process]::new()
  $edgeProcess.StartInfo = $startInfo
  if (-not $edgeProcess.Start()) {
    throw 'Microsoft Edge could not be started for PDF rendering.'
  }

  $standardOutputTask = $edgeProcess.StandardOutput.ReadToEndAsync()
  $standardErrorTask = $edgeProcess.StandardError.ReadToEndAsync()
  $edgeProcess.WaitForExit()
  $standardOutput = $standardOutputTask.GetAwaiter().GetResult()
  $standardError = $standardErrorTask.GetAwaiter().GetResult()

  $unexpectedErrors = @($standardError -split "`r?`n" | Where-Object {
      -not [string]::IsNullOrWhiteSpace($_) -and
      $_ -notmatch 'Every renderer should have at least one task provided by a primary task provider\.' -and
      $_ -notmatch '^\d+ bytes written to file '
    })
  $hasPdf = (Test-Path -LiteralPath $OutputPdf) -and ((Get-Item -LiteralPath $OutputPdf).Length -gt 0)
  if ($edgeProcess.ExitCode -ne 0 -or -not $hasPdf) {
    $diagnostics = @($standardOutput, $standardError | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join [Environment]::NewLine
    throw "Edge PDF rendering failed (exit code $($edgeProcess.ExitCode)). $diagnostics"
  }

  foreach ($errorLine in $unexpectedErrors) {
    Write-Warning "Edge diagnostic: $errorLine"
  }
}

Write-Host '[3/3] Rendering PDF via Headless Edge...' -ForegroundColor Cyan

$edgePath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
if (-not (Test-Path -Path $edgePath)) {
  $edgePath = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
}

$fileUri = "file:///$($tempHtml -replace '\\', '/')"

Invoke-EdgePdfExport -EdgePath $edgePath -InputFileUri $fileUri -OutputPdf $outputPdf

Write-Host "PDF created successfully: $outputPdf" -ForegroundColor Green

if ($SendToPrinter) {
  Write-Host 'Sending print job to default printer...' -ForegroundColor Cyan
  Start-Process -FilePath $outputPdf -Verb Print -PassThru | Out-Null
}

if (-not $NoShow) {
  Start-Process -FilePath $outputPdf
}
