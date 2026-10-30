[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RimWorldDir = 'D:\SteamLibrary\steamapps\common\RimWorld',
    [string]$HarmonyAssemblyPath = 'D:\SteamLibrary\steamapps\workshop\content\294100\2009463077\1.7\Assemblies\0Harmony.dll'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = (Resolve-Path -LiteralPath $RimWorldDir).ProviderPath
if (-not (Test-Path -LiteralPath (Join-Path $gameRoot 'Assembly-CSharp.dll') -PathType Leaf)) {
    throw 'RimWorldDir must point to the RimWorld 1.7 installation.'
}
$modsRoot = [IO.Path]::GetFullPath((Join-Path $gameRoot 'Mods'))
$destination = [IO.Path]::GetFullPath((Join-Path $modsRoot 'WorkshopFilter'))

function Assert-SafeDestination {
    # Verify the absolute destination before any recursive removal, including rollback.
    if ([IO.Path]::GetDirectoryName($destination) -ne $modsRoot -or
        [IO.Path]::GetFileName($destination) -ne 'WorkshopFilter') {
        throw "Unsafe deployment destination: $destination"
    }
    foreach ($path in @($modsRoot, $destination)) {
        if ((Test-Path -LiteralPath $path) -and
            ((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Deployment does not replace linked directories: $path"
        }
    }
    if (Test-Path -LiteralPath $destination) {
        $links = @(Get-ChildItem -LiteralPath $destination -Recurse -Force |
            Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
        if ($links.Count -gt 0) { throw 'The installed mod contains linked paths; deployment stopped.' }
    }
}

Assert-SafeDestination
if (Test-Path -LiteralPath $destination) {
    $installedAbout = Join-Path $destination 'About\About.xml'
    if (-not (Test-Path -LiteralPath $installedAbout -PathType Leaf)) {
        throw 'Existing WorkshopFilter directory is not an identified mod. It will not be overwritten.'
    }
    [xml]$installed = Get-Content -LiteralPath $installedAbout -Raw
    if ($installed.ModMetaData.packageId -notin @('diablood.workshopfilter', 'diabl.workshopfilter')) {
        throw 'Existing WorkshopFilter directory belongs to another mod. It will not be overwritten.'
    }
}
if (-not $PSCmdlet.ShouldProcess($destination, 'Build, validate and deploy Workshop Filter (back up any previous installation)')) {
    return
}
if (Get-Process -Name RimWorld -ErrorAction SilentlyContinue) {
    throw 'Close RimWorld before deploying, then run tools/deploy.cmd again.'
}

& (Join-Path $PSScriptRoot 'build.ps1') -RimWorldDir $gameRoot -HarmonyAssemblyPath $HarmonyAssemblyPath

$runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$stage = Join-Path $projectRoot "artifacts\deploy\$runId\WorkshopFilter"
New-Item -ItemType Directory -Path $stage -Force | Out-Null
# Explicit runtime payload: source code, build output dependencies and tests are excluded.
$runtimeFiles = @(Get-Content -LiteralPath (Join-Path $projectRoot 'tools/package-files.json') -Raw | ConvertFrom-Json)
foreach ($entry in $runtimeFiles) {
    $target = Join-Path $stage $entry
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $target -Force
}
# Preserve the Workshop item's identity across clean local reinstalls.
$sourceId = Join-Path $projectRoot 'About/PublishedFileId.txt'
$installedId = Join-Path $destination 'About/PublishedFileId.txt'
$idFiles = @(@($sourceId, $installedId) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
$ids = @($idFiles | ForEach-Object { (Get-Content -LiteralPath $_ -Raw).Trim() } | Select-Object -Unique)
if ($ids.Count -gt 1 -or @($ids | Where-Object { $_ -notmatch '^\d+$' }).Count) { throw 'Invalid or conflicting Workshop item IDs.' }
if ($idFiles.Count -gt 0) { Copy-Item -LiteralPath $idFiles[0] -Destination (Join-Path $stage 'About/PublishedFileId.txt') }

function Assert-InstalledFiles([string]$reference, [string]$actual) {
    $sourceFiles = @(Get-ChildItem -LiteralPath $reference -File -Recurse)
    $actualFiles = @(Get-ChildItem -LiteralPath $actual -File -Recurse)
    if ($sourceFiles.Count -ne $actualFiles.Count) { throw 'Deployment file count differs.' }
    foreach ($file in $sourceFiles) {
        $relative = [IO.Path]::GetRelativePath($reference, $file.FullName)
        $copy = Join-Path $actual $relative
        if (-not (Test-Path -LiteralPath $copy -PathType Leaf) -or
            (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash) {
            throw "Deployment verification failed: $relative"
        }
    }
}

Assert-SafeDestination
$backup = $null
if (Test-Path -LiteralPath $destination) {
    $backup = Join-Path $projectRoot "artifacts\backups\$runId\WorkshopFilter"
    New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
    Copy-Item -LiteralPath $destination -Destination $backup -Recurse -Force
    Assert-InstalledFiles $destination $backup
    Write-Output "Previous installation backed up: $backup"
}
New-Item -ItemType Directory -Path $modsRoot -Force | Out-Null
if (Get-Process -Name RimWorld -ErrorAction SilentlyContinue) {
    throw 'RimWorld was started during the build. Close it and run tools/deploy.cmd again.'
}
try {
    Assert-SafeDestination
    if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Recurse -Force }
    Copy-Item -LiteralPath $stage -Destination $destination -Recurse -Force
    Assert-InstalledFiles $stage $destination
} catch {
    $deploymentError = $_
    Assert-SafeDestination
    if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Recurse -Force }
    if ($null -ne $backup) {
        Copy-Item -LiteralPath $backup -Destination $destination -Recurse -Force
        Assert-InstalledFiles $backup $destination
        Write-Warning 'Deployment failed; the previous installation was restored.'
    }
    throw $deploymentError
}
Write-Output "Deployment verified (SHA-256): $destination"
Write-Output 'Enable Harmony and Workshop Filter in the game mod list. In-game behavior still requires testing.'
