[CmdletBinding()]
param()

<#
.SYNOPSIS
    Validates RollingCalendar script structure without invoking external services.
.DESCRIPTION
    Module: RollingCalendar/tests/Invoke-RollingCalendar.Tests.ps1
    Purpose: Guards PowerShell entrypoint and advanced-function contracts.
    Path: RollingCalendar/tests/Invoke-RollingCalendar.Tests.ps1
    Authors: rgbig, Workspace_AI Governance
    Version: 1.2.0
    Date: 2026-10-02
#>

Describe 'Invoke-RollingCalendar quality contract' {
  BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Invoke-RollingCalendar.ps1'
    $scriptText = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)
  }

  It 'parses without errors' {
    $parseErrors | Should -BeNullOrEmpty
  }

  It 'begins with the advanced script declaration' {
    $scriptText.TrimStart() | Should -Match '^\[CmdletBinding\(\)\]\r?\nparam'
  }

  It 'defines each internal function as an advanced function' {
    $functionNames = @(
      'Test-IsAdmin',
      'Resolve-ValidTime',
      'Test-IcsUrl',
      'Get-OrPromptIcsUrl',
      'Register-CalendarTask',
      'Add-SpanEvent',
      'Invoke-EdgePdfExport'
    )

    foreach ($functionName in $functionNames) {
      $pattern = "function\s+$functionName\s*\{\s*\r?\n\s*\[CmdletBinding\(\)\]\s*\r?\n\s*param"
      $scriptText | Should -Match $pattern
    }
  }

  It 'passes calendar state explicitly to the event collector' {
    @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Add-SpanEvent' }, $true)).Count | Should -Be 1
    $scriptText | Should -Match 'Add-SpanEvent.*-CalendarStart \$startMonday.*-CalendarEnd \$endWindow.*-Events \$events'
  }

  It 'supports the documented time formats' {
    $scriptText | Should -Match 'yyyyMMdd_HHmmss'
    $scriptText | Should -Match "RawTime -match '\^\\d\{8\}_"
  }

  It 'uses the C:\Temp output-directory contract and NoShow switch' {
    $scriptText | Should -Match "\[Alias\('o'\)\]"
    $scriptText | Should -Match 'C:\\Temp'
    $scriptText | Should -Match '\[switch\]\$NoShow'
    $scriptText | Should -Not -Match 'OpenAfterExport'
  }

  It 'captures Edge diagnostics and verifies the rendered PDF' {
    $scriptText | Should -Match 'RedirectStandardError = \$true'
    $scriptText | Should -Match 'Every renderer should have at least one task provided by a primary task provider'
    $scriptText | Should -Match '\^\\d\+ bytes written to file '
    $scriptText | Should -Match '\$edgeProcess\.ExitCode -ne 0 -or -not \$hasPdf'
  }

  It 'defines the Culture parameter with German default and Locale alias' {
    $scriptText | Should -Match "\[Alias\('Locale'\)\]"
    $scriptText | Should -Match '\[string\]\$Culture = ''de-DE'''
    $scriptText | Should -Match '\[System\.Globalization\.CultureInfo\]::GetCultureInfo\(\$Culture\)'
  }

  It 'implements dynamic localized weekday headers and short date formatting' {
    $scriptText | Should -Match 'GetAbbreviatedDayName'
    $scriptText | Should -Match 'TwoLetterISOLanguageName'
    $scriptText | Should -Match 'v\$ScriptVersion'
  }
}