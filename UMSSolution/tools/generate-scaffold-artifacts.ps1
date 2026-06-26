$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outDirs = @(
    (Join-Path $root 'generated/ums-boilerplate-agent-skill'),
    (Join-Path $root 'docs/template2'),
    (Join-Path $root 'docs/template3')
)
foreach ($dir in $outDirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

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

# Scan backend files using Get-ChildItem to avoid depending on external 'rg'
$allFiles = @()

foreach ($p in $projectNames) {
    $pdir = Join-Path $root $p
    if (Test-Path $pdir) {
        $files = @(Get-ChildItem -Path $pdir -Recurse -File | Where-Object {
            $_.FullName -notmatch '[\\/](bin|obj|graphify-out)[\\/]'
        } | ForEach-Object {
            $_.FullName.Substring($root.Length).TrimStart('\', '/')
        })
        $allFiles += $files
    }
}

$clientDir = Join-Path $root 'UMS.Client'
if (Test-Path $clientDir) {
    $clientFiles = @(Get-ChildItem -Path $clientDir -Recurse -File | Where-Object {
        $_.FullName -notmatch '[\\/](node_modules|dist)[\\/]' -and
        $_.Name -ne 'package-lock.json' -and
        $_.FullName -notmatch '[\\/]public[\\/]assets[\\/]img[\\/]'
    } | ForEach-Object {
        $_.FullName.Substring($root.Length).TrimStart('\', '/')
    })
    $allFiles += $clientFiles
}

$allFiles = $allFiles | Sort-Object
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Convert-ToLf([string]$s) {
    return ($s -replace "`r`n", "`n") -replace "`r", "`n"
}

function Escape-BashSingleQuoted([string]$s) {
    return $s -replace "'", "'\''"
}

function Get-PathHash([string]$path) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($path)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $md5.ComputeHash($bytes)
    $hashString = [System.BitConverter]::ToString($hashBytes) -replace '-'
    return $hashString
}

function Get-Packages([string]$csproj) {
    $csprojPath = Join-Path $root $csproj
    if (-not (Test-Path $csprojPath)) { return @() }
    [xml]$xml = Get-Content -Raw -LiteralPath $csprojPath
    $items = @()
    if ($xml.Project -and $xml.Project.ItemGroup) {
        foreach ($ig in $xml.Project.ItemGroup) {
            foreach ($pr in $ig.PackageReference) {
                if ($null -eq $pr) { continue }
                if ($pr.Include -and $pr.Version) {
                    $items += [pscustomobject]@{ Include = $pr.Include; Version = $pr.Version }
                }
            }
        }
    }
    return $items
}

function Get-References([string]$csproj) {
    $csprojPath = Join-Path $root $csproj
    if (-not (Test-Path $csprojPath)) { return @() }
    [xml]$xml = Get-Content -Raw -LiteralPath $csprojPath
    $items = @()
    if ($xml.Project -and $xml.Project.ItemGroup) {
        foreach ($ig in $xml.Project.ItemGroup) {
            foreach ($ref in $ig.ProjectReference) {
                if ($null -eq $ref) { continue }
                if ($ref.Include) { $items += $ref.Include }
            }
        }
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

$allProjectNames = $projectNames + 'UMS.Client'

$treeLines = foreach ($p in $allProjectNames) {
    "- $p"
    $projectFiles = $allFiles | Where-Object {
        $_ -eq $p -or $_.StartsWith("$p\") -or $_.StartsWith("$p/")
    }
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

$namespaceHitLines = [System.Collections.Generic.List[string]]::new()
foreach ($f in $allFiles) {
    $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
    if ($ext -notin @('.jpg', '.jpeg', '.png', '.gif', '.ico', '.webp', '.svg')) {
        $content = [System.IO.File]::ReadAllText((Join-Path $root $f), [System.Text.UTF8Encoding]::new($false))
        $lines = $content -split "`n"
        for ($lineIdx = 0; $lineIdx -lt $lines.Count; $lineIdx++) {
            $line = $lines[$lineIdx]
            if ($line -match '\bUMS\b|UMS\.') {
                $namespaceHitLines.Add(("- " + $f + ":" + ($lineIdx + 1) + ":" + $line.Trim()))
            }
        }
    }
}

$skillPrompt = @"
# UMS Boilerplate Solution Scaffolder Agent Skill

Use this skill when the user wants to create a new .NET 10 Clean Architecture + React 19 single-page application solution that exactly replicates the UMS boilerplate with a different root namespace.

## Input Parameter Handling

Ask the user for ``ProjectName`` if it was not provided. Treat ``ProjectName`` as the new root namespace and project prefix. Accept only a C#-safe root namespace matching ``^[A-Za-z_][A-Za-z0-9_]*$``.

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

The scripts are intentionally self-contained: they embed every scaffolded ``.cs``, ``.csproj``, JSON/config, HTTP, and React client asset payload directly. Do not look for external templates.

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
5. Clean standard templated defaults (Class1.cs, UnitTest1.cs, WeatherForecast.cs, Program.cs, Controllers/, *.http).
6. Write all the C# project files and configurations replacing namespace/import boundaries.
7. Create folder ``{ProjectName}.Client`` for the React application and write all client configuration and source files.
8. Run ``npm install`` inside ``{ProjectName}.Client``.
9. Run ``dotnet restore`` and ``dotnet build``.

## Templating Rules

- Replace root namespace token ``UMS`` with ``{ProjectName}`` in ``.cs``, ``.csproj``, ``.json``, ``.http``, and launch/config files using regex replacements.
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

foreach ($dir in $outDirs) {
    [System.IO.File]::WriteAllText((Join-Path $dir 'SkillPrompt.md'), $skillPrompt, $utf8NoBom)
}

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

# Generate random ports to prevent port conflicts when running multiple scaffolded projects
$HttpsPort = Get-Random -Minimum 7100 -Maximum 7299
$HttpPort = Get-Random -Minimum 5000 -Maximum 5099
$ClientPort = Get-Random -Minimum 5100 -Maximum 5199

Write-Host "Assigned Ports - HTTPS: $HttpsPort, HTTP: $HttpPort, Client Dev Server: $ClientPort" -ForegroundColor Cyan


function Invoke-Step([string]$Command, [string[]]$Arguments) {
    Write-Host "> dotnet $Command $($Arguments -join ' ')"
    & dotnet $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "dotnet $Command failed with exit code $LASTEXITCODE" }
}

function Get-ProjectDir([string]$Suffix) { return "$ProjectName.$Suffix" }
function Get-ProjectPath([string]$Suffix) { return Join-Path (Get-ProjectDir $Suffix) "$ProjectName.$Suffix.csproj" }

if ($OutputPath -and -not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null }
$Root = Join-Path (Resolve-Path $OutputPath).Path $ProjectName
if (Test-Path $Root) { throw "Output directory already exists: $Root" }
New-Item -ItemType Directory -Force -Path $Root | Out-Null

Push-Location $Root
try {
    Write-Host "Creating Solution..."
    Invoke-Step 'new' @('sln', '-n', $ProjectName)

    Write-Host "Creating C# Projects..."
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

    Write-Host "Cleaning Project Defaults..."
    function Clean-ProjectDefaults() {
        $dirs = @('Domain', 'Application', 'Infrastructure')
        foreach ($d in $dirs) {
            $path = Join-Path $Root (Join-Path (Get-ProjectDir $d) 'Class1.cs')
            if (Test-Path $path) { Remove-Item -Path $path -Force }
        }
        
        $testDirs = @('Domain.Tests', 'Application.Tests', 'Infrastructure.Tests', 'API.Tests')
        foreach ($td in $testDirs) {
            $path = Join-Path $Root (Join-Path (Get-ProjectDir $td) 'UnitTest1.cs')
            if (Test-Path $path) { Remove-Item -Path $path -Force }
        }
        
        $apiDir = Join-Path $Root (Get-ProjectDir 'API')
        $apiFiles = @('Program.cs', 'WeatherForecast.cs')
        foreach ($f in $apiFiles) {
            $path = Join-Path $apiDir $f
            if (Test-Path $path) { Remove-Item -Path $path -Force }
        }
        $controllersPath = Join-Path $apiDir 'Controllers'
        if (Test-Path $controllersPath) { Remove-Item -Path $controllersPath -Recurse -Force }
        
        if (Test-Path $apiDir) {
            Get-ChildItem -Path $apiDir -Filter "*.http" | Remove-Item -Force
        }
    }
    Clean-ProjectDefaults

    function Convert-TemplatePath([string]$RelativePath) {
        return ($RelativePath -replace 'UMS', $ProjectName) -replace '\\', [System.IO.Path]::DirectorySeparatorChar
    }

    function Write-TemplateFile([string]$RelativePath, [string]$Content) {
        $target = Join-Path $Root (Convert-TemplatePath $RelativePath)
        $dir = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        
        # 1. Write raw content first
        [System.IO.File]::WriteAllText($target, $Content, [System.Text.UTF8Encoding]::new($false))
        
        # 2. Read back, apply replacements, and write back
        $rendered = [System.IO.File]::ReadAllText($target, [System.Text.UTF8Encoding]::new($false))
        $rendered = [regex]::Replace($rendered, 'namespace UMS\b', "namespace $ProjectName")
        $rendered = [regex]::Replace($rendered, '\busing\s+(static\s+)?UMS\b', { param($m) "using " + $m.Groups[1].Value + $ProjectName })
        $rendered = [regex]::Replace($rendered, '<RootNamespace>UMS\b', "<RootNamespace>$ProjectName")
        $rendered = [regex]::Replace($rendered, '(?i)(<ProjectReference Include="[^"]*)UMS\.([^"]*")', {
            param($m)
            return $m.Value -replace 'UMS\.', "$ProjectName."
        })
        $rendered = [regex]::Replace($rendered, '(?i)([''"])UMS\.Client/', "${1}$ProjectName.Client/")
        $rendered = [regex]::Replace($rendered, '(?i)InternalsVisibleTo\("UMS\.', "InternalsVisibleTo(`"$ProjectName.")
        $rendered = [regex]::Replace($rendered, '\bUMS\.(Domain|Application|Infrastructure|API|Client)\b', "${ProjectName}.`$1")
        $rendered = [regex]::Replace($rendered, '\bums-client\b', ($ProjectName.ToLower() + "-client"))
        
        # Port replacements to avoid conflicts
        $rendered = $rendered -replace 'https://localhost:7122', "https://localhost:$HttpsPort"
        $rendered = $rendered -replace 'http://localhost:7122', "https://localhost:$HttpsPort"
        $rendered = $rendered -replace 'http://localhost:5055', "http://localhost:$HttpPort"
        $rendered = $rendered -replace 'http://localhost:5173', "http://localhost:$ClientPort"
        if ($RelativePath -match 'vite\.config\.ts$') {
            $rendered = $rendered -replace 'plugins: \[react\(\)\]', "plugins: [react()],`r`n  server: {`r`n    port: $ClientPort`r`n  }"
        }
        
        # Connection String & Database Name Replacement
        if ($RelativePath -match 'appsettings\.json$') {
            $rendered = [regex]::Replace($rendered, 'Database=(UMS|UMSDb|UMSDB)\b', "Database=${ProjectName}DB")
        }
        elseif ($RelativePath -match 'appsettings\.Testing\.json$') {
            $rendered = [regex]::Replace($rendered, 'Database=(UMS|UMSDbTest|UMSDBTest)\b', "Database=${ProjectName}DBTest")
        }
        
        [System.IO.File]::WriteAllText($target, $rendered, [System.Text.UTF8Encoding]::new($false))
    }

    function Write-Base64TemplateFile([string]$RelativePath, [string]$Base64Content) {
        $rawBytes = [System.Convert]::FromBase64String($Base64Content)
        $content = [System.Text.Encoding]::UTF8.GetString($rawBytes)
        Write-TemplateFile $RelativePath $content
    }

    function Write-BinaryFile([string]$RelativePath, [string]$Base64Content) {
        $target = Join-Path $Root (Convert-TemplatePath $RelativePath)
        $dir = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        [System.IO.File]::WriteAllBytes($target, [Convert]::FromBase64String($Base64Content))
    }

'@)

foreach ($f in $allFiles) {
    $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
    $isBinary = $ext -in @('.jpg', '.jpeg', '.png', '.gif', '.ico', '.webp', '.svg')
    if ($isBinary) {
        $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Join-Path $root $f)))
        [void]$ps.AppendLine("    Write-BinaryFile '$($f -replace '\\','/')' @'")
        [void]$ps.AppendLine($b64)
        [void]$ps.AppendLine("'@")
    }
    else {
        # Read using UTF-8 without BOM
        $content = Convert-ToLf ([System.IO.File]::ReadAllText((Join-Path $root $f), [System.Text.UTF8Encoding]::new($false)))
        $hasHereStringEnd = $content -match '(?m)^''@\r?$'
        if ($hasHereStringEnd) {
            $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
            [void]$ps.AppendLine("    Write-Base64TemplateFile '$($f -replace '\\','/')' @'")
            [void]$ps.AppendLine($b64)
            [void]$ps.AppendLine("'@")
        } else {
            [void]$ps.AppendLine("    Write-TemplateFile '$($f -replace '\\','/')' @'")
            [void]$ps.Append($content)
            if (-not $content.EndsWith("`n")) { [void]$ps.AppendLine() }
            [void]$ps.AppendLine("'@")
        }
    }
}

[void]$ps.AppendLine(@'

    Write-Host "Setting up React Client..."
    $clientDir = Join-Path $Root "$ProjectName.Client"
    if (Test-Path $clientDir) {
        Push-Location $clientDir
        try {
            if (Get-Command npm -ErrorAction SilentlyContinue) {
                Write-Host "Running npm install..."
                & npm install
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "npm install failed."
                }
            } else {
                Write-Warning "npm is not installed. Please run 'npm install' manually in: $clientDir"
            }
        } finally {
            Pop-Location
        }
    }

    Write-Host "Restoring and building solution..."
    Invoke-Step 'restore' @()
    Invoke-Step 'build' @()

    Write-Host "Checking for dotnet-ef tool..."
    $efInstalled = $false
    try {
        $efCheck = & dotnet ef --version 2>&1
        if ($LASTEXITCODE -eq 0) { $efInstalled = $true }
    } catch {}
    if (-not $efInstalled) {
        Write-Host "Installing dotnet-ef tool globally..."
        & dotnet tool install -g dotnet-ef
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to install dotnet-ef tool globally."
        }
    }

    Write-Host "Applying EF Core Migrations..." -ForegroundColor Cyan
    & dotnet ef database update --project "$Root\$ProjectName.Infrastructure" --startup-project "$Root\$ProjectName.API"
    if ($LASTEXITCODE -ne 0) { throw "EF Core Migration failed." }

    Write-Host "Scaffold complete: $Root"
}
finally {
    Pop-Location
}
'@)

foreach ($dir in $outDirs) {
    [System.IO.File]::WriteAllText((Join-Path $dir 'Scaffold.ps1'), $ps.ToString(), $utf8NoBom)
}

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

# Generate random ports to prevent port conflicts
HTTPS_PORT=$((7100 + RANDOM % 200))
HTTP_PORT=$((5000 + RANDOM % 100))
CLIENT_PORT=$((5100 + RANDOM % 100))

echo "Assigned Ports - HTTPS: $HTTPS_PORT, HTTP: $HTTP_PORT, Client Dev Server: $CLIENT_PORT"

# Resolve absolute path for ROOT
mkdir -p "$OUTPUT_PATH"
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

echo "Creating Solution..."
run_dotnet new sln -n "$PROJECT_NAME"

echo "Creating C# Projects..."
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

echo "Cleaning Project Defaults..."
clean_project_defaults() {
  local pdir
  for suffix in Domain Application Infrastructure; do
    pdir="$ROOT/$(project_dir "$suffix")"
    rm -f "$pdir/Class1.cs"
  done
  for suffix in Domain.Tests Application.Tests Infrastructure.Tests API.Tests; do
    pdir="$ROOT/$(project_dir "$suffix")"
    rm -f "$pdir/UnitTest1.cs"
  done
  
  local api_dir="$ROOT/$(project_dir API)"
  rm -f "$api_dir/Program.cs"
  rm -f "$api_dir/WeatherForecast.cs"
  rm -rf "$api_dir/Controllers"
  rm -f "$api_dir"/*.http
}
clean_project_defaults

replace_namespaces() {
  local filepath="$1"
  # Apply replacement rules using perl
  PROJECT_NAME="$PROJECT_NAME" perl -pi -e 's/\bnamespace UMS\b/namespace $ENV{PROJECT_NAME}/g' "$filepath"
  PROJECT_NAME="$PROJECT_NAME" perl -pi -e 's/\busing\s+(static\s+)?UMS\b/using $1$ENV{PROJECT_NAME}/g' "$filepath"
  PROJECT_NAME="$PROJECT_NAME" perl -pi -e 's/<RootNamespace>UMS\b/<RootNamespace>$ENV{PROJECT_NAME}/g' "$filepath"
  PROJECT_NAME="$PROJECT_NAME" perl -pi -e 'while (s/(<ProjectReference Include="[^"]*)\bUMS\./$1$ENV{PROJECT_NAME}./g) {}' "$filepath"
  PROJECT_NAME="$PROJECT_NAME" perl -pi -e "s/(['\"])UMS\.Client\//$1$ENV{PROJECT_NAME}.Client\//g" "$filepath"
  PROJECT_NAME="$PROJECT_NAME" perl -pi -e 's/InternalsVisibleTo\("UMS\./InternalsVisibleTo("$ENV{PROJECT_NAME}./g' "$filepath"
  PROJECT_NAME="$PROJECT_NAME" perl -pi -e 's/\bUMS\.(Domain|Application|Infrastructure|API|Client)\b/$ENV{PROJECT_NAME}.$1/g' "$filepath"
  
  local lower_name
  lower_name=$(echo "$PROJECT_NAME" | tr "[:upper:]" "[:lower:]")
  PROJECT_NAME_LOWER="$lower_name" perl -pi -e 's/\bums-client\b/$ENV{PROJECT_NAME_LOWER}-client/g' "$filepath"

  # Connection String & Database Name Replacement
  if [[ "$filepath" =~ appsettings\.json$ ]]; then
    PROJECT_NAME="$PROJECT_NAME" perl -pi -e 's/Database=(UMS|UMSDb|UMSDB)\b/Database=$ENV{PROJECT_NAME}DB/g' "$filepath"
  elif [[ "$filepath" =~ appsettings\.Testing\.json$ ]]; then
    PROJECT_NAME="$PROJECT_NAME" perl -pi -e 's/Database=(UMS|UMSDbTest|UMSDBTest)\b/Database=$ENV{PROJECT_NAME}DBTest/g' "$filepath"
  fi

  # Port replacements to avoid conflicts
  HTTPS_PORT="$HTTPS_PORT" perl -pi -e 's/https:\/\/localhost:7122/https:\/\/localhost:$ENV{HTTPS_PORT}/g' "$filepath"
  HTTPS_PORT="$HTTPS_PORT" perl -pi -e 's/http:\/\/localhost:7122/http:\/\/localhost:$ENV{HTTPS_PORT}/g' "$filepath"
  HTTP_PORT="$HTTP_PORT" perl -pi -e 's/http:\/\/localhost:5055/http:\/\/localhost:$ENV{HTTP_PORT}/g' "$filepath"
  CLIENT_PORT="$CLIENT_PORT" perl -pi -e 's/http:\/\/localhost:5173/http:\/\/localhost:$ENV{CLIENT_PORT}/g' "$filepath"

  if [[ "$filepath" =~ vite\.config\.ts$ ]]; then
    CLIENT_PORT="$CLIENT_PORT" perl -pi -e 's/plugins: \[react\(\)\]/plugins: [react()],\n  server: {\n    port: $ENV{CLIENT_PORT}\n  }/g' "$filepath"
  fi
}

write_template_file() {
  local rel="$1"
  local target_rel="${rel//UMS/$PROJECT_NAME}"
  local target="$ROOT/$target_rel"
  mkdir -p "$(dirname "$target")"
  # 1. Write raw heredoc content
  cat > "$target"
  # 2. In-place namespace replacement timing
  replace_namespaces "$target"
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
    $hash = Get-PathHash $relForSh
    $delim = "HEREDOC_$hash"
    $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
    $isBinary = $ext -in @('.jpg', '.jpeg', '.png', '.gif', '.ico', '.webp', '.svg')
    if ($isBinary) {
        $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Join-Path $root $f)))
        [void]$sh.AppendLine("write_binary_file '$(Escape-BashSingleQuoted $relForSh)' << '$delim'")
        [void]$sh.AppendLine($b64)
        [void]$sh.AppendLine($delim)
    }
    else {
        # Read using UTF-8 without BOM
        $content = Convert-ToLf ([System.IO.File]::ReadAllText((Join-Path $root $f), [System.Text.UTF8Encoding]::new($false)))
        [void]$sh.AppendLine("write_template_file '$(Escape-BashSingleQuoted $relForSh)' << '$delim'")
        [void]$sh.Append($content)
        if (-not $content.EndsWith("`n")) { [void]$sh.AppendLine() }
        [void]$sh.AppendLine($delim)
    }
    $i++
}

[void]$sh.AppendLine(@'

echo "Setting up React Client..."
CLIENT_DIR="$ROOT/${PROJECT_NAME}.Client"
if [[ -d "$CLIENT_DIR" ]]; then
  pushd "$CLIENT_DIR" >/dev/null
  if command -v npm &>/dev/null; then
    echo "Running npm install..."
    npm install || echo "Warning: npm install failed"
  else
    echo "Warning: npm is not installed. Please run 'npm install' manually in: $CLIENT_DIR"
  fi
  popd >/dev/null
fi

echo "Restoring and building solution..."
run_dotnet restore
run_dotnet build

echo "Checking for dotnet-ef tool..."
if ! command -v dotnet-ef &>/dev/null; then
  echo "Installing dotnet-ef tool globally..."
  dotnet tool install -g dotnet-ef || echo "Warning: dotnet-ef installation failed, attempting to run anyway..."
fi

echo "Applying EF Core Migrations..."
dotnet ef database update --project "$ROOT/$PROJECT_NAME.Infrastructure" --startup-project "$ROOT/$PROJECT_NAME.API"
if [ $? -ne 0 ]; then echo "Error: EF Core Migration failed." >&2; exit 1; fi

popd >/dev/null
printf 'Scaffold complete: %s\n' "$ROOT"
'@)

foreach ($dir in $outDirs) {
    [System.IO.File]::WriteAllText((Join-Path $dir 'Scaffold.sh'), $sh.ToString(), $utf8NoBom)
}

Write-Host "Generated artifacts in: $($outDirs -join ', ')"
Write-Host "Files embedded: $($allFiles.Count)"
