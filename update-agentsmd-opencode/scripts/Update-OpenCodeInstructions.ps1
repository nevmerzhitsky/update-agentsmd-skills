[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryRoot
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

            $relativePath = [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($resolvedUri).ToString()).Replace('/', '/')
            $orderedFiles.Add($relativePath)
            Visit-Imports -ManifestPath $resolvedPath
        }
    }

    Visit-Imports -ManifestPath $IndexPath
    return $orderedFiles
}

$repositoryRootPath = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$indexPath = Join-Path $repositoryRootPath "docs\agents.md\index.md"
$configPath = Join-Path $repositoryRootPath "opencode.json"

if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    throw "Missing instruction manifest: $indexPath"
}
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Missing OpenCode configuration: $configPath"
}

$instructions = @(Get-ImportedInstructionFiles -IndexPath $indexPath -RootPath $repositoryRootPath)
$config = [System.IO.File]::ReadAllText($configPath) | ConvertFrom-Json
if ($null -eq $config.PSObject.Properties["instructions"]) {
    $config | Add-Member -NotePropertyName "instructions" -NotePropertyValue $instructions
}
else {
    $config.instructions = $instructions
}

$json = $config | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllText($configPath, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Write-Output "Updated $configPath with $($instructions.Count) instruction files."
