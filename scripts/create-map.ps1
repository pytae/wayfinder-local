[CmdletBinding()]
param(
    [Parameter()]
    [AllowEmptyString()]
    [string]$Slug = '',

    [Parameter()]
    [AllowEmptyString()]
    [string]$Idea = '',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceRoot = (Get-Location).Path,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Tracker = 'local-markdown'
)

$ErrorActionPreference = 'Stop'

function Write-Result {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Value,

        [Parameter(Mandatory = $true)]
        [int]$ExitCode
    )

    $Value | ConvertTo-Json -Depth 8
    exit $ExitCode
}

function ConvertTo-MapSlug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Normalize([System.Text.NormalizationForm]::FormD)
    $builder = [System.Text.StringBuilder]::new()

    foreach ($character in $normalized.ToCharArray()) {
        $category = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($character)
        if ($category -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($character)
        }
    }

    $candidate = $builder.ToString().Normalize([System.Text.NormalizationForm]::FormC).ToLowerInvariant()
    $candidate = [System.Text.RegularExpressions.Regex]::Replace($candidate, "['’]", '')
    $candidate = [System.Text.RegularExpressions.Regex]::Replace($candidate, '[^a-z0-9]+', '-').Trim('-')

    if ([string]::IsNullOrWhiteSpace($candidate)) {
        $hashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
        try {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
            $hash = [System.BitConverter]::ToString($hashAlgorithm.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
            $candidate = "project-$($hash.Substring(0, 12))"
        }
        finally {
            $hashAlgorithm.Dispose()
        }
    }

    if ($candidate.Length -gt 64) {
        $candidate = $candidate.Substring(0, 64).TrimEnd('-')
    }

    return $candidate
}

$root = [System.IO.Path]::GetFullPath($WorkspaceRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    Write-Result -ExitCode 2 -Value @{
        status = 'invalid'
        reason = 'workspace-root-not-found'
        workspaceRoot = $root
    }
}

$ideaValue = $Idea.Trim()
$slugValue = $Slug.Trim()
$derivedSlug = $false

if ([string]::IsNullOrWhiteSpace($slugValue)) {
    if ([string]::IsNullOrWhiteSpace($ideaValue)) {
        Write-Result -ExitCode 2 -Value @{
            status = 'invalid'
            reason = 'slug-or-idea-required'
            workspaceRoot = $root
        }
    }

    $slugValue = ConvertTo-MapSlug -Value $ideaValue
    $derivedSlug = $true
}

if ($slugValue -notmatch '^[a-z0-9][a-z0-9-]{0,63}$') {
    Write-Result -ExitCode 2 -Value @{
        status = 'invalid'
        reason = 'invalid-slug'
        slug = $slugValue
        expected = 'lowercase letters, digits, and hyphens; maximum 64 characters'
        workspaceRoot = $root
    }
}

if ($Tracker -notmatch '^[a-z0-9][a-z0-9-]{0,63}$') {
    Write-Result -ExitCode 2 -Value @{
        status = 'invalid'
        reason = 'invalid-tracker'
        tracker = $Tracker
        workspaceRoot = $root
    }
}

$mapDirectory = [System.IO.Path]::GetFullPath((Join-Path $root "data\wayfinder\$slugValue"))
$mapPath = Join-Path $mapDirectory 'map.md'

if (Test-Path -LiteralPath $mapPath -PathType Leaf) {
    Write-Result -ExitCode 3 -Value @{
        status = 'already-exists'
        reason = 'map-not-overwritten'
        slug = $slugValue
        tracker = $Tracker
        canonicalPath = $mapPath
        workspaceRoot = $root
    }
}

New-Item -ItemType Directory -Path $mapDirectory -Force | Out-Null

$ideaBlock = $ideaValue
if ([string]::IsNullOrWhiteSpace($ideaBlock)) {
    $ideaBlock = '_Not provided yet._'
}

$mapBody = @"
---
slug: $slugValue
tracker: $Tracker
---

## Destination

_To be established while charting._

## Notes

Initial idea:

$ideaBlock

## Decisions so far

## Not yet specified

## Out of scope
"@

$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($mapPath, $mapBody, $utf8WithoutBom)

Write-Result -ExitCode 0 -Value @{
    status = 'created'
    slug = $slugValue
    derivedSlug = $derivedSlug
    tracker = $Tracker
    canonicalPath = $mapPath
    workspaceRoot = $root
}
