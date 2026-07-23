param(
    [string]$PlaceName,
    [string]$ServePort
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    [Console]::Error.WriteLine("Error: $Message")
    exit 1
}

if (-not $PlaceName -or $args.Count -gt 0) {
    [Console]::Error.WriteLine("Usage: scripts\create-place.bat <PlaceName> [ServePort]")
    exit 1
}

if ($PlaceName -notmatch '^[A-Za-z][A-Za-z0-9_-]*$' -or $PlaceName.Contains('..')) {
    Fail "place name must start with an ASCII letter and contain only letters, numbers, underscores, and hyphens"
}

$root = Split-Path -Parent $PSScriptRoot
$placeDirectory = Join-Path $root "places\$PlaceName"
$sourceDirectory = Join-Path $root "src\Places\$PlaceName"

if (Test-Path -LiteralPath $placeDirectory) { Fail "places/$PlaceName already exists" }
if (Test-Path -LiteralPath $sourceDirectory) { Fail "src/Places/$PlaceName already exists" }

$usedPorts = @()
Get-ChildItem -LiteralPath (Join-Path $root 'places') -Directory | ForEach-Object {
    $source = Join-Path $root "src\Places\$($_.Name)"
    if ((Test-Path -LiteralPath (Join-Path $_.FullName 'default.project.json') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $_.FullName 'build.project.json') -PathType Leaf) -and
        (Test-Path -LiteralPath $source -PathType Container)) {
        try {
            $value = (Get-Content -Raw -LiteralPath (Join-Path $_.FullName 'default.project.json') | ConvertFrom-Json).servePort
            if ($value -is [int] -or $value -is [long]) {
                if ($value -ge 1 -and $value -le 65535) { $usedPorts += [int]$value }
            }
        } catch {}
    }
}

if ($ServePort) {
    if ($ServePort -notmatch '^\d+$') { Fail "port must contain only digits" }
    $parsedPort = 0
    if (-not [int]::TryParse($ServePort, [ref]$parsedPort) -or $parsedPort -lt 1 -or $parsedPort -gt 65535) {
        Fail "port must be between 1 and 65535"
    }
    if ($usedPorts -contains $parsedPort) { Fail "port $parsedPort is already used by another place" }
} else {
    $parsedPort = 34872
    while ($usedPorts -contains $parsedPort) {
        $parsedPort++
        if ($parsedPort -gt 65535) { Fail "no available development port exists from 34872 through 65535" }
    }
}

$createdPlace = $false
$createdSource = $false

try {
    New-Item -ItemType Directory -Path $placeDirectory | Out-Null
    $createdPlace = $true
    New-Item -ItemType Directory -Path $sourceDirectory | Out-Null
    $createdSource = $true

    @('Core', 'Client\Systems', 'Client\Modules', 'Server\Systems', 'Server\Modules') | ForEach-Object {
        $directory = New-Item -ItemType Directory -Path (Join-Path $sourceDirectory $_) -Force
        New-Item -ItemType File -Path (Join-Path $directory.FullName '.gitkeep') | Out-Null
    }

    foreach ($projectType in @('default', 'build')) {
        $template = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot "place.$projectType.project.json.template")
        $project = $template.Replace('__PLACE_NAME__', $PlaceName).Replace('__SERVE_PORT__', [string]$parsedPort)
        [IO.File]::WriteAllText((Join-Path $placeDirectory "$projectType.project.json"), $project)
    }
} catch {
    if ($createdPlace) { Remove-Item -LiteralPath $placeDirectory -Recurse -Force }
    if ($createdSource) { Remove-Item -LiteralPath $sourceDirectory -Recurse -Force }
    throw
}

Write-Output "Created place `"$PlaceName`""
Write-Output "Port: $parsedPort"
Write-Output ""
Write-Output "Local files:"
Write-Output "  places/$PlaceName"
Write-Output "  src/Places/$PlaceName"
Write-Output ""
Write-Output "Develop:"
Write-Output "  scripts\dev.bat $PlaceName"
Write-Output ""
Write-Output "Build:"
Write-Output "  scripts\build.bat $PlaceName"
Write-Output ""
Write-Output "Analyze:"
Write-Output "  sh scripts/analyze.sh $PlaceName"
Write-Output ""
Write-Output "This creates local project structure only; it does not create a Roblox cloud place."
