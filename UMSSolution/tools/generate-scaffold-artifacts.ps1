$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outDir = Join-Path $root 'generated/ums-boilerplate-agent-skill'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$projectNames = @(
    'UMS.Domain',
    'UMS.Domain.Tests',
    'UMS.Application',
    'UMS.Application.Tests',
    'UMS.Infrastructure',
    'UMS.Infrastructure.Tests',
    'UMS.API',
    'UMS.API.Tests'
)

$allFiles = foreach ($p in $projectNames) {
    & rg --files $p -g '!**/bin/**' -g '!**/obj/**' -g '!**/graphify-out/**'
}
$allFiles = $allFiles | Sort-Object
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Convert-ToLf([string]$s) {
    return ($s -replace "`r`n", "`n") -replace "`r", "`n"
}

function Escape-BashSingleQuoted([string]$s) {
    return $s -replace "'", "'\''"
}

function Get-Packages([string]$csproj) {
    [xml]$xml = Get-Content -Raw -LiteralPath (Join-Path $root $csproj)
    $items = @()
    foreach ($pr in $xml.Project.ItemGroup.PackageReference) {
        if ($null -eq $pr) { continue }
        if ($pr.Include -and $pr.Version) {
            $items += [pscustomobject]@{ Include = $pr.Include; Version = $pr.Version }
        }
    }
    return $items
}

function Get-References([string]$csproj) {
    [xml]$xml = Get-Content -Raw -LiteralPath (Join-Path $root $csproj)
    $items = @()
    foreach ($ref in $xml.Project.ItemGroup.ProjectReference) {
        if ($null -eq $ref) { continue }
        if ($ref.Include) { $items += $ref.Include }
    }
    return $items
}

$packageMap = [ordered]@{}
$referenceMap = [ordered]@{}
foreach ($p in $projectNames) {
    $csproj = Join-Path $p "$p.csproj"
    $packageMap[$p] = @(Get-Packages $csproj)
    $referenceMap[$p] = @(Get-References $csproj)
}

$treeLines = foreach ($p in $projectNames) {
    "- $p"
    $projectFiles = $allFiles | Where-Object { $_ -like "$p*" }
    foreach ($f in $projectFiles) { "  - " + ($f.Substring($p.Length).TrimStart('\', '/')) }
}

$packageLines = foreach ($p in $projectNames) {
    "- $p"
    if ($packageMap[$p].Count -eq 0) { "  - none" }
    foreach ($pkg in $packageMap[$p]) { "  - $($pkg.Include) $($pkg.Version)" }
}

$referenceLines = foreach ($p in $projectNames) {
    "- $p"
    if ($referenceMap[$p].Count -eq 0) { "  - none" }
    foreach ($r in $referenceMap[$p]) { "  - $r" }
}

$namespaceHitLines = & rg -n "\bUMS\b|UMS\." UMS.Domain UMS.Domain.Tests UMS.Application UMS.Application.Tests UMS.Infrastructure UMS.Infrastructure.Tests UMS.API UMS.API.Tests -g '!**/bin/**' -g '!**/obj/**' -g '!**/graphify-out/**' |
    ForEach-Object { "- $_" }

$skillPrompt = @"
# UMS Boilerplate Solution Scaffolder Agent Skill

Use this skill when the user wants to create a new .NET 10 Clean Architecture solution that exactly replicates the UMS boilerplate with a different root namespace.

## Input Parameter Handling

Ask the user for ``ProjectName`` if it was not provided. Treat ``ProjectName`` as the new root namespace and project prefix. Accept only a C#-safe root namespace matching ``^[A-Za-z_][A-Za-z0-9_]*$`` unless the user intentionally updates the scripts to support dotted namespace roots.

## Fast Execution Path

Run one of the bundled self-contained scripts from this skill folder:

PowerShell:

````powershell
./Scaffold.ps1 -ProjectName MyProduct
````

Bash:

````bash
./Scaffold.sh --ProjectName MyProduct
````

The scripts are intentionally self-contained: they embed every scaffolded ``.cs``, ``.csproj``, JSON/config, HTTP, and binary asset payload directly. Do not look for external templates.

## Manual Execution Rules

If script execution is not possible, reproduce the same workflow manually:

1. Ask for ``ProjectName``.
2. Run ``dotnet new sln -n {ProjectName}`` from the target directory. With .NET 10 this creates ``{ProjectName}.slnx``.
3. Create these projects with ``net10.0``:
   - ``{ProjectName}.Domain`` via ``dotnet new classlib``
   - ``{ProjectName}.Application`` via ``dotnet new classlib``
   - ``{ProjectName}.Infrastructure`` via ``dotnet new classlib``
   - ``{ProjectName}.API`` via ``dotnet new webapi``
   - ``{ProjectName}.Domain.Tests`` via ``dotnet new xunit``
   - ``{ProjectName}.Application.Tests`` via ``dotnet new xunit``
   - ``{ProjectName}.Infrastructure.Tests`` via ``dotnet new xunit``
   - ``{ProjectName}.API.Tests`` via ``dotnet new xunit``
4. Add all 8 projects to the ``.slnx`` with ``dotnet sln add``.
5. Add package references exactly as mapped below.
6. Add project references exactly as mapped below.
7. Replace all generated files with the embedded boilerplate contents, changing path prefix ``UMS`` to ``{ProjectName}`` and replacing the root namespace token ``UMS`` in file contents with ``{ProjectName}``.
8. Run ``dotnet restore`` and preferably ``dotnet build``.

## Templating Rules

- Replace root namespace token ``UMS`` with ``{ProjectName}`` in ``.cs``, ``.csproj``, ``.json``, ``.http``, and launch/config files.
- Rename project folders and project files from ``UMS.*`` to ``{ProjectName}.*``.
- Preserve the internal folder tree and file names below each project.
- Preserve package versions, ``PrivateAssets``, ``IncludeAssets``, content metadata, and project references.
- Do not scaffold graphify caches, ``bin``, or ``obj`` folders.

## Folder Tree

$($treeLines -join "`n")

## NuGet Packages

$($packageLines -join "`n")

## Project References

$($referenceLines -join "`n")

## Root Namespace Occurrences To Replace

$($namespaceHitLines -join "`n")
"@
[System.IO.File]::WriteAllText((Join-Path $outDir 'SkillPrompt.md'), $skillPrompt, $utf8NoBom)

$ps = New-Object System.Text.StringBuilder
[void]$ps.AppendLine(@'
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [string]$OutputPath = "."
)

$ErrorActionPreference = 'Stop'

if ($ProjectName -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
    throw "ProjectName must be a valid C# root namespace: letters, digits, underscore, and not starting with a digit."
}

function Invoke-Step([string]$Command, [string[]]$Arguments) {
    Write-Host "> dotnet $Command $($Arguments -join ' ')"
    & dotnet $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "dotnet $Command failed with exit code $LASTEXITCODE" }
}

function Get-ProjectDir([string]$Suffix) { return "$ProjectName.$Suffix" }
function Get-ProjectPath([string]$Suffix) { return Join-Path (Get-ProjectDir $Suffix) "$ProjectName.$Suffix.csproj" }

$Root = Join-Path (Resolve-Path $OutputPath).Path $ProjectName
if (Test-Path $Root) { throw "Output directory already exists: $Root" }
New-Item -ItemType Directory -Force -Path $Root | Out-Null

Push-Location $Root
try {
    Invoke-Step 'new' @('sln', '-n', $ProjectName)

    Invoke-Step 'new' @('classlib', '-n', (Get-ProjectDir 'Domain'), '-f', 'net10.0')
    Invoke-Step 'new' @('classlib', '-n', (Get-ProjectDir 'Application'), '-f', 'net10.0')
    Invoke-Step 'new' @('classlib', '-n', (Get-ProjectDir 'Infrastructure'), '-f', 'net10.0')
    Invoke-Step 'new' @('webapi', '-n', (Get-ProjectDir 'API'), '-f', 'net10.0', '--no-https')
    Invoke-Step 'new' @('xunit', '-n', (Get-ProjectDir 'Domain.Tests'), '-f', 'net10.0')
    Invoke-Step 'new' @('xunit', '-n', (Get-ProjectDir 'Application.Tests'), '-f', 'net10.0')
    Invoke-Step 'new' @('xunit', '-n', (Get-ProjectDir 'Infrastructure.Tests'), '-f', 'net10.0')
    Invoke-Step 'new' @('xunit', '-n', (Get-ProjectDir 'API.Tests'), '-f', 'net10.0')

    $projectSuffixes = @('API', 'Application', 'Domain', 'Infrastructure', 'Domain.Tests', 'Application.Tests', 'Infrastructure.Tests', 'API.Tests')
    foreach ($suffix in $projectSuffixes) { Invoke-Step 'sln' @('add', (Get-ProjectPath $suffix)) }

    function Add-Package([string]$Suffix, [string]$Package, [string]$Version) {
        Invoke-Step 'add' @((Get-ProjectPath $Suffix), 'package', $Package, '--version', $Version)
    }

'@)

foreach ($p in $projectNames) {
    $suffix = $p.Substring(4)
    foreach ($pkg in $packageMap[$p]) {
        [void]$ps.AppendLine("    Add-Package '$suffix' '$($pkg.Include)' '$($pkg.Version)'")
    }
}

[void]$ps.AppendLine(@'

    function Add-ProjectReference([string]$FromSuffix, [string]$ToSuffix) {
        Invoke-Step 'add' @((Get-ProjectPath $FromSuffix), 'reference', (Get-ProjectPath $ToSuffix))
    }

'@)

foreach ($p in $projectNames) {
    $fromSuffix = $p.Substring(4)
    foreach ($r in $referenceMap[$p]) {
        $target = [System.IO.Path]::GetFileNameWithoutExtension($r)
        $toSuffix = $target.Substring(4)
        [void]$ps.AppendLine("    Add-ProjectReference '$fromSuffix' '$toSuffix'")
    }
}

[void]$ps.AppendLine(@'

    foreach ($suffix in $projectSuffixes) {
        $dir = Join-Path $Root (Get-ProjectDir $suffix)
        if ((Resolve-Path $dir).Path -notlike "$Root*") { throw "Refusing to clean outside scaffold root: $dir" }
        Get-ChildItem -LiteralPath $dir -Force | Remove-Item -Recurse -Force
    }

    function Convert-TemplatePath([string]$RelativePath) {
        return ($RelativePath -replace 'UMS', $ProjectName) -replace '\\', [System.IO.Path]::DirectorySeparatorChar
    }

    function Write-TemplateFile([string]$RelativePath, [string]$Content) {
        $target = Join-Path $Root (Convert-TemplatePath $RelativePath)
        $dir = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $rendered = [regex]::Replace($Content, '\bUMS\b', $ProjectName)
        Set-Content -LiteralPath $target -Value $rendered -NoNewline -Encoding UTF8
    }

    function Write-BinaryFile([string]$RelativePath, [string]$Base64Content) {
        $target = Join-Path $Root (Convert-TemplatePath $RelativePath)
        $dir = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        [System.IO.File]::WriteAllBytes($target, [Convert]::FromBase64String($Base64Content))
    }

'@)

$i = 0
foreach ($f in $allFiles) {
    $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
    if ($ext -in @('.jpg', '.jpeg', '.png', '.gif', '.ico', '.webp')) {
        $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Join-Path $root $f)))
        [void]$ps.AppendLine("    Write-BinaryFile '$($f -replace '\\','\')' @'")
        [void]$ps.AppendLine($b64)
        [void]$ps.AppendLine("'@")
    }
    else {
        $content = Convert-ToLf (Get-Content -Raw -LiteralPath (Join-Path $root $f))
        [void]$ps.AppendLine("    Write-TemplateFile '$($f -replace '\\','\')' @'")
        [void]$ps.Append($content)
        if (-not $content.EndsWith("`n")) { [void]$ps.AppendLine() }
        [void]$ps.AppendLine("'@")
    }
    $i++
}

[void]$ps.AppendLine(@'

    Invoke-Step 'restore' @()
    Write-Host "Scaffold complete: $Root"
}
finally {
    Pop-Location
}
'@)
[System.IO.File]::WriteAllText((Join-Path $outDir 'Scaffold.ps1'), $ps.ToString(), $utf8NoBom)

$sh = New-Object System.Text.StringBuilder
[void]$sh.AppendLine(@'
#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME=""
OUTPUT_PATH="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ProjectName|-ProjectName|--project-name|-p)
      PROJECT_NAME="${2:-}"
      shift 2
      ;;
    --OutputPath|--output-path|-o)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Usage: ./Scaffold.sh --ProjectName MyProduct [--OutputPath .]" >&2
  exit 2
fi

if [[ ! "$PROJECT_NAME" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "ProjectName must be a valid C# root namespace: letters, digits, underscore, and not starting with a digit." >&2
  exit 2
fi

ROOT="$(cd "$OUTPUT_PATH" && pwd)/$PROJECT_NAME"
if [[ -e "$ROOT" ]]; then
  echo "Output directory already exists: $ROOT" >&2
  exit 1
fi
mkdir -p "$ROOT"

run_dotnet() {
  echo "> dotnet $*"
  dotnet "$@"
}

project_dir() { printf '%s.%s' "$PROJECT_NAME" "$1"; }
project_path() { printf '%s/%s.%s.csproj' "$(project_dir "$1")" "$PROJECT_NAME" "$1"; }

pushd "$ROOT" >/dev/null

run_dotnet new sln -n "$PROJECT_NAME"
run_dotnet new classlib -n "$(project_dir Domain)" -f net10.0
run_dotnet new classlib -n "$(project_dir Application)" -f net10.0
run_dotnet new classlib -n "$(project_dir Infrastructure)" -f net10.0
run_dotnet new webapi -n "$(project_dir API)" -f net10.0 --no-https
run_dotnet new xunit -n "$(project_dir Domain.Tests)" -f net10.0
run_dotnet new xunit -n "$(project_dir Application.Tests)" -f net10.0
run_dotnet new xunit -n "$(project_dir Infrastructure.Tests)" -f net10.0
run_dotnet new xunit -n "$(project_dir API.Tests)" -f net10.0

PROJECT_SUFFIXES=(API Application Domain Infrastructure Domain.Tests Application.Tests Infrastructure.Tests API.Tests)
for suffix in "${PROJECT_SUFFIXES[@]}"; do
  run_dotnet sln add "$(project_path "$suffix")"
done

add_package() {
  local suffix="$1"
  local package="$2"
  local version="$3"
  run_dotnet add "$(project_path "$suffix")" package "$package" --version "$version"
}

'@)

foreach ($p in $projectNames) {
    $suffix = $p.Substring(4)
    foreach ($pkg in $packageMap[$p]) {
        [void]$sh.AppendLine("add_package '$(Escape-BashSingleQuoted $suffix)' '$(Escape-BashSingleQuoted $pkg.Include)' '$(Escape-BashSingleQuoted $pkg.Version)'")
    }
}

[void]$sh.AppendLine(@'

add_project_reference() {
  local from_suffix="$1"
  local to_suffix="$2"
  run_dotnet add "$(project_path "$from_suffix")" reference "$(project_path "$to_suffix")"
}

'@)

foreach ($p in $projectNames) {
    $fromSuffix = $p.Substring(4)
    foreach ($r in $referenceMap[$p]) {
        $target = [System.IO.Path]::GetFileNameWithoutExtension($r)
        $toSuffix = $target.Substring(4)
        [void]$sh.AppendLine("add_project_reference '$(Escape-BashSingleQuoted $fromSuffix)' '$(Escape-BashSingleQuoted $toSuffix)'")
    }
}

[void]$sh.AppendLine(@'

for suffix in "${PROJECT_SUFFIXES[@]}"; do
  dir="$ROOT/$(project_dir "$suffix")"
  case "$dir" in
    "$ROOT"/*) rm -rf "$dir"/* "$dir"/.[!.]* "$dir"/..?* 2>/dev/null || true ;;
    *) echo "Refusing to clean outside scaffold root: $dir" >&2; exit 1 ;;
  esac
done

write_template_file() {
  local rel="$1"
  local target_rel="${rel//UMS/$PROJECT_NAME}"
  local target="$ROOT/$target_rel"
  mkdir -p "$(dirname "$target")"
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  PROJECT_NAME="$PROJECT_NAME" perl -0pi -e 's/\bUMS\b/$ENV{PROJECT_NAME}/g' "$tmp"
  mv "$tmp" "$target"
}

write_binary_file() {
  local rel="$1"
  local target_rel="${rel//UMS/$PROJECT_NAME}"
  local target="$ROOT/$target_rel"
  mkdir -p "$(dirname "$target")"
  base64 -d > "$target"
}

'@)

$i = 0
foreach ($f in $allFiles) {
    $relForSh = $f -replace '\\', '/'
    $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
    if ($ext -in @('.jpg', '.jpeg', '.png', '.gif', '.ico', '.webp')) {
        $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Join-Path $root $f)))
        $delim = "__UMS_BINARY_${i}__"
        [void]$sh.AppendLine("write_binary_file '$(Escape-BashSingleQuoted $relForSh)' << '$delim'")
        [void]$sh.AppendLine($b64)
        [void]$sh.AppendLine($delim)
    }
    else {
        $content = Convert-ToLf (Get-Content -Raw -LiteralPath (Join-Path $root $f))
        $delim = "__UMS_FILE_${i}__"
        [void]$sh.AppendLine("write_template_file '$(Escape-BashSingleQuoted $relForSh)' << '$delim'")
        [void]$sh.Append($content)
        if (-not $content.EndsWith("`n")) { [void]$sh.AppendLine() }
        [void]$sh.AppendLine($delim)
    }
    $i++
}

[void]$sh.AppendLine(@'

run_dotnet restore
popd >/dev/null
printf 'Scaffold complete: %s\n' "$ROOT"
'@)
[System.IO.File]::WriteAllText((Join-Path $outDir 'Scaffold.sh'), $sh.ToString(), $utf8NoBom)

Write-Host "Generated artifacts in $outDir"
Write-Host "Files embedded: $($allFiles.Count)"
