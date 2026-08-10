[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Reference,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceRoot = (Get-Location).Path
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

function Resolve-FullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )

    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path $BasePath $Path
    }

    return [System.IO.Path]::GetFullPath($Path)
}

function Get-MapMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $lines = @(Get-Content -LiteralPath $Path -TotalCount 80)
    $metadata = @{}

    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') {
        return $metadata
    }

    for ($index = 1; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        if ($line.Trim() -eq '---') {
            break
        }

        if ($line -match '^\s*(slug|tracker)\s*:\s*["'']?([^"'']+?)["'']?\s*$') {
            $metadata[$matches[1].ToLowerInvariant()] = $matches[2].Trim()
        }
    }

    return $metadata
}

$root = Resolve-FullPath -Path $WorkspaceRoot -BasePath (Get-Location).Path
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    Write-Result -ExitCode 2 -Value @{
        status = 'unresolved'
        reason = 'workspace-root-not-found'
        workspaceRoot = $root
        checked = @($root)
    }
}

$referenceValue = $Reference.Trim()

if ($referenceValue -match '^https?://') {
    Write-Result -ExitCode 0 -Value @{
        status = 'direct'
        referenceType = 'url'
        canonicalReference = $referenceValue
        workspaceRoot = $root
    }
}

if ($referenceValue -match '^#?\d+$') {
    Write-Result -ExitCode 0 -Value @{
        status = 'tracker-reference'
        referenceType = 'issue-number'
        canonicalReference = $referenceValue
        workspaceRoot = $root
    }
}

$looksLikePath = [System.IO.Path]::IsPathRooted($referenceValue) -or
    $referenceValue.Contains('/') -or
    $referenceValue.Contains('\') -or
    $referenceValue.EndsWith('.md', [System.StringComparison]::OrdinalIgnoreCase)

if ($looksLikePath) {
    $path = Resolve-FullPath -Path $referenceValue -BasePath $root

    if (Test-Path -LiteralPath $path -PathType Container) {
        $path = Join-Path $path 'map.md'
    }

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Result -ExitCode 2 -Value @{
            status = 'unresolved'
            reason = 'path-not-found'
            workspaceRoot = $root
            checked = @($path)
        }
    }

    $metadata = Get-MapMetadata -Path $path
    if ([string]::IsNullOrWhiteSpace([string]$metadata.slug) -or
        [string]::IsNullOrWhiteSpace([string]$metadata.tracker)) {
        Write-Result -ExitCode 4 -Value @{
            status = 'invalid-map'
            reason = 'missing-frontmatter'
            required = @('slug', 'tracker')
            canonicalPath = $path
            checked = @($path)
        }
    }

    Write-Result -ExitCode 0 -Value @{
        status = 'resolved'
        referenceType = 'path'
        canonicalPath = $path
        slug = $metadata.slug
        tracker = $metadata.tracker
        workspaceRoot = $root
        checked = @($path)
    }
}

if ($referenceValue -notmatch '^[a-z0-9][a-z0-9-]{0,63}$') {
    Write-Result -ExitCode 2 -Value @{
        status = 'unresolved'
        reason = 'invalid-slug'
        workspaceRoot = $root
        reference = $referenceValue
        expected = 'lowercase letters, digits, and hyphens; maximum 64 characters'
    }
}

$checked = [System.Collections.Generic.List[string]]::new()
$candidates = [System.Collections.Generic.List[object]]::new()
$configPath = Join-Path $root '.wayfinder\maps.json'
$checked.Add($configPath)

if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    try {
        $config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
        $mapping = $null
        if ($null -ne $config.maps) {
            $property = $config.maps.PSObject.Properties[$referenceValue]
            if ($null -ne $property) {
                $mapping = $property.Value
            }
        }

        if ($null -ne $mapping) {
            $configuredPath = Resolve-FullPath -Path ([string]$mapping) -BasePath $root
            $checked.Add($configuredPath)
            if (Test-Path -LiteralPath $configuredPath -PathType Leaf) {
                $candidates.Add([pscustomobject]@{ source = 'project-alias'; path = $configuredPath })
            }
        }
    }
    catch {
        Write-Result -ExitCode 2 -Value @{
            status = 'unresolved'
            reason = 'invalid-project-config'
            workspaceRoot = $root
            configPath = $configPath
            error = $_.Exception.Message
            checked = @($checked)
        }
    }
}

$canonicalPaths = @(
    (Join-Path $root "data\wayfinder\$referenceValue\map.md"),
    (Join-Path $root ".wayfinder\$referenceValue\map.md")
)

foreach ($canonicalPath in $canonicalPaths) {
    $fullPath = [System.IO.Path]::GetFullPath($canonicalPath)
    $checked.Add($fullPath)
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        $candidates.Add([pscustomobject]@{ source = 'canonical-location'; path = $fullPath })
    }
}

$uniqueCandidates = @($candidates | Group-Object { $_.path.ToLowerInvariant() } | ForEach-Object { $_.Group[0] })

if ($uniqueCandidates.Count -eq 0) {
    Write-Result -ExitCode 2 -Value @{
        status = 'unresolved'
        reason = 'slug-not-found'
        slug = $referenceValue
        workspaceRoot = $root
        checked = @($checked)
    }
}

if ($uniqueCandidates.Count -gt 1) {
    Write-Result -ExitCode 3 -Value @{
        status = 'ambiguous'
        reason = 'multiple-maps-found'
        slug = $referenceValue
        workspaceRoot = $root
        candidates = @($uniqueCandidates)
        checked = @($checked)
    }
}

$candidate = $uniqueCandidates[0]
$metadata = Get-MapMetadata -Path $candidate.path

if ([string]::IsNullOrWhiteSpace([string]$metadata.slug) -or
    [string]::IsNullOrWhiteSpace([string]$metadata.tracker)) {
    Write-Result -ExitCode 4 -Value @{
        status = 'invalid-map'
        reason = 'missing-frontmatter'
        required = @('slug', 'tracker')
        canonicalPath = $candidate.path
        checked = @($checked)
    }
}

if ($metadata.slug -ne $referenceValue) {
    Write-Result -ExitCode 4 -Value @{
        status = 'invalid-map'
        reason = 'slug-mismatch'
        requestedSlug = $referenceValue
        mapSlug = $metadata.slug
        canonicalPath = $candidate.path
        checked = @($checked)
    }
}

Write-Result -ExitCode 0 -Value @{
    status = 'resolved'
    referenceType = 'slug'
    source = $candidate.source
    slug = $metadata.slug
    tracker = $metadata.tracker
    canonicalPath = $candidate.path
    workspaceRoot = $root
    checked = @($checked)
}
