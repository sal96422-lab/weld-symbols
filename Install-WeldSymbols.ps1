param(
  [string]$SupportPath,
  [switch]$AllProfiles
)

$ErrorActionPreference = 'Stop'

function Write-Step {
  param([string]$Message)
  Write-Host "[WELDSYM] $Message"
}

function Get-AutoCADSupportFolders {
  param([string]$ExplicitPath)

  if ($ExplicitPath) {
    return @((Resolve-Path -LiteralPath $ExplicitPath).Path)
  }

  $autodeskRoot = Join-Path $env:APPDATA 'Autodesk'
  $found = @()

  if (Test-Path -LiteralPath $autodeskRoot) {
    $found = Get-ChildItem -LiteralPath $autodeskRoot -Directory -Recurse -ErrorAction SilentlyContinue |
      Where-Object {
        $_.Name -ieq 'Support' -and
        $_.FullName -match '\\AutoCAD [^\\]+\\R[^\\]+\\[^\\]+\\Support$'
      } |
      Sort-Object FullName -Unique |
      Select-Object -ExpandProperty FullName
  }

  if (-not $found -or $found.Count -eq 0) {
    $fallback = Join-Path $env:APPDATA 'Autodesk\AutoCAD 2027\R26.0\enu\Support'
    New-Item -ItemType Directory -Force -Path $fallback | Out-Null
    $found = @($fallback)
  }

  return @($found)
}

function Copy-RequiredFiles {
  param(
    [string]$SourceRoot,
    [string]$TargetSupport
  )

  $files = @(
    @{ Source = 'weldsym_cmd.lsp'; Target = 'weldsym_safe.lsp' },
    @{ Source = 'installed_weldsym_safe.lsp'; Target = 'installed_weldsym_safe.lsp' },
    @{ Source = 'weldsym.lsp'; Target = 'weldsym.lsp' },
    @{ Source = 'weldsym.dcl'; Target = 'weldsym.dcl' },
    @{ Source = 'WELDSYM.mnu'; Target = 'WELDSYM.mnu' },
    @{ Source = 'weldright16.bmp'; Target = 'weldright16.bmp' },
    @{ Source = 'weldright32.bmp'; Target = 'weldright32.bmp' },
    @{ Source = 'weldright64.bmp'; Target = 'weldright64.bmp' },
    @{ Source = 'weldleft16.bmp'; Target = 'weldleft16.bmp' },
    @{ Source = 'weldleft32.bmp'; Target = 'weldleft32.bmp' },
    @{ Source = 'weldleft64.bmp'; Target = 'weldleft64.bmp' },
    @{ Source = 'weldfield16.bmp'; Target = 'weldfield16.bmp' },
    @{ Source = 'weldfield32.bmp'; Target = 'weldfield32.bmp' },
    @{ Source = 'weldfield64.bmp'; Target = 'weldfield64.bmp' },
    @{ Source = 'weldaround16.bmp'; Target = 'weldaround16.bmp' },
    @{ Source = 'weldaround32.bmp'; Target = 'weldaround32.bmp' },
    @{ Source = 'weldaround64.bmp'; Target = 'weldaround64.bmp' },
    @{ Source = 'weldtail16.bmp'; Target = 'weldtail16.bmp' },
    @{ Source = 'weldtail32.bmp'; Target = 'weldtail32.bmp' },
    @{ Source = 'weldtail64.bmp'; Target = 'weldtail64.bmp' },
    @{ Source = 'weldtail1-16.bmp'; Target = 'weldtail1-16.bmp' },
    @{ Source = 'weldtail1-32.bmp'; Target = 'weldtail1-32.bmp' },
    @{ Source = 'weldtail2-16.bmp'; Target = 'weldtail2-16.bmp' },
    @{ Source = 'weldtail2-32.bmp'; Target = 'weldtail2-32.bmp' },
    @{ Source = 'weldsym_type_picker.ps1'; Target = 'weldsym_type_picker.ps1' },
    @{ Source = 'weldsym_type_picker_server.ps1'; Target = 'weldsym_type_picker_server.ps1' }
  )

  foreach ($file in $files) {
    $src = Join-Path $SourceRoot $file.Source
    if (-not (Test-Path -LiteralPath $src)) {
      throw "Missing required installer file: $src"
    }
  }

  New-Item -ItemType Directory -Force -Path $TargetSupport | Out-Null

  foreach ($file in $files) {
    Copy-Item -LiteralPath (Join-Path $SourceRoot $file.Source) -Destination (Join-Path $TargetSupport $file.Target) -Force
  }

  $typeImagesSource = Join-Path $SourceRoot 'type_images'
  $typeImagesTarget = Join-Path $TargetSupport 'type_images'
  if (-not (Test-Path -LiteralPath $typeImagesSource)) {
    throw "Missing required type image folder: $typeImagesSource"
  }

  New-Item -ItemType Directory -Force -Path $typeImagesTarget | Out-Null
  Get-ChildItem -LiteralPath $typeImagesSource -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $typeImagesTarget $_.Name) -Force
  }
}

function Update-AcadDoc {
  param([string]$TargetSupport)

  $acadDoc = Join-Path $TargetSupport 'acaddoc.lsp'
  $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

  if (Test-Path -LiteralPath $acadDoc) {
    Copy-Item -LiteralPath $acadDoc -Destination "$acadDoc.weldsym-backup-$timestamp" -Force
    $content = Get-Content -LiteralPath $acadDoc -Raw
  } else {
    $content = ";;; acaddoc.lsp - loads automatically for every drawing session`r`n"
  }

  $content = [regex]::Replace($content, '(?ms)\r?\n?;;; BEGIN WELDSYM AUTOLOAD.*?;;; END WELDSYM AUTOLOAD\r?\n?', "`r`n")
  $lines = $content -split '\r?\n' | Where-Object { $_ -notmatch 'weldsym_safe\.lsp' }
  $content = ($lines -join "`r`n").TrimEnd()

  $block = @'

;;; BEGIN WELDSYM AUTOLOAD
(load (findfile "weldsym_safe.lsp"))
(if (fboundp 'weldsym:ensure-toolbar) (vl-catch-all-apply 'weldsym:ensure-toolbar '()))
;;; END WELDSYM AUTOLOAD
'@

  Set-Content -LiteralPath $acadDoc -Value ($content + $block + "`r`n") -Encoding ASCII
}

$sourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$targets = Get-AutoCADSupportFolders -ExplicitPath $SupportPath

Write-Step "Source: $sourceRoot"
Write-Step "AutoCAD support folders found: $($targets.Count)"

foreach ($target in $targets) {
  Write-Step "Installing to: $target"
  Copy-RequiredFiles -SourceRoot $sourceRoot -TargetSupport $target
  Update-AcadDoc -TargetSupport $target
}

Write-Host ''
Write-Host 'Install complete.'
Write-Host 'Open AutoCAD, then run WELDTOOLBAR if the toolbar is not already visible.'
Write-Host 'Main command: WELDSYM'
