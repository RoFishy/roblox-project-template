param([Parameter(Mandatory)][string]$Project)

$content = Get-Content -Raw -LiteralPath $Project
$content = [regex]::Replace($content, '("\$path"\s*:\s*")\.\./\.\./', '$1')
[IO.File]::WriteAllText((Join-Path (Get-Location).Path '.active-place.project.json'), $content)
