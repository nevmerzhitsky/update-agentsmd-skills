[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ImportedInstructionFiles {
    param(
        [Parameter(Mandatory)]
        [string]$IndexPath,
        [Parameter(Mandatory)]
        [string]$RootPath
    )

    $rootUri = [System.Uri]((Resolve-Path -LiteralPath $RootPath).Path + [System.IO.Path]::DirectorySeparatorChar)
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $orderedFiles = [System.Collections.Generic.List[string]]::new()

    function Visit-Imports {
        param([string]$ManifestPath)

        foreach ($line in [System.IO.File]::ReadAllLines($ManifestPath)) {
            if ($line -notmatch '^@(?<path>.+\.md)\s*$') {
                continue
            }

            $importPath = $Matches.path
            $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $ManifestPath) $importPath))
            if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
                throw "Instruction import does not exist: $importPath (from $ManifestPath)"
            }

            if (-not $seen.Add($resolvedPath)) {
                continue
            }

            $resolvedUri = [System.Uri]$resolvedPath
            if (-not $rootUri.IsBaseOf($resolvedUri)) {
                throw "Instruction import is outside the repository: $importPath"
            }

            $orderedFiles.Add($resolvedPath)
            Visit-Imports -ManifestPath $resolvedPath
        }
    }

    Visit-Imports -ManifestPath $IndexPath
    return $orderedFiles
}

$repositoryRootPath = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$indexPath = Join-Path $repositoryRootPath "docs\agents\index.md"
$outputPath = Join-Path $repositoryRootPath "AGENTS.override.md"

if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    throw "Missing instruction manifest: $indexPath"
}

$instructionFiles = @(Get-ImportedInstructionFiles -IndexPath $indexPath -RootPath $repositoryRootPath)
$rootUri = [System.Uri]($repositoryRootPath + [System.IO.Path]::DirectorySeparatorChar)
$output = [System.Text.StringBuilder]::new()
[void]$output.AppendLine("<!-- Generated from docs/agents/index.md by Update-CodexAgentsOverride.ps1. Do not edit manually. -->")

foreach ($instructionFile in $instructionFiles) {
    $instructionUri = [System.Uri]$instructionFile
    $relativePath = [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($instructionUri).ToString()).Replace('/', '/')
    [void]$output.AppendLine("<!-- Source: $relativePath -->")
    [void]$output.AppendLine([System.IO.File]::ReadAllText($instructionFile).Trim())
    [void]$output.AppendLine()
}

[System.IO.File]::WriteAllText($outputPath, $output.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Output "Generated $outputPath from $($instructionFiles.Count) instruction files."
