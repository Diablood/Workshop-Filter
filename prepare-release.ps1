[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [string]$RimWorldDir = 'D:\SteamLibrary\steamapps\common\RimWorld',
    [string]$HarmonyAssemblyPath = 'D:\SteamLibrary\steamapps\workshop\content\294100\2009463077\1.7\Assemblies\0Harmony.dll'
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $SkipBuild) { & (Join-Path $root 'build.ps1') -RimWorldDir $RimWorldDir -HarmonyAssemblyPath $HarmonyAssemblyPath }
else { & (Join-Path $root 'tools/check-project.ps1') -RimWorldDir $RimWorldDir -HarmonyAssemblyPath $HarmonyAssemblyPath }
[xml]$about = Get-Content -LiteralPath (Join-Path $root 'About/About.xml') -Raw
$version = [string]$about.ModMetaData.modVersion
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid release version.' }
$relativeFiles = @(Get-Content -LiteralPath (Join-Path $root 'tools/package-files.json') -Raw | ConvertFrom-Json)
if (Test-Path -LiteralPath (Join-Path $root 'About/PublishedFileId.txt')) { $relativeFiles += 'About/PublishedFileId.txt' }
foreach ($relative in $relativeFiles) {
    $source = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $source.StartsWith($root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Invalid or missing package file: $relative" }
}
if ((Get-Item -LiteralPath (Join-Path $root 'About/Preview.png')).Length -ge 1MB) { throw 'Workshop preview must be below 1 MiB.' }
Add-Type -AssemblyName System.Drawing
$preview = [Drawing.Image]::FromFile((Join-Path $root 'About/Preview.png'))
try { if ($preview.Width -ne $preview.Height) { throw 'Workshop preview must be square.' } }
finally { $preview.Dispose() }
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff')
$releaseRoot = Join-Path $root "artifacts/releases/$version/$stamp"
$content = Join-Path $releaseRoot 'WorkshopFilter'
New-Item -ItemType Directory -Path $content -Force | Out-Null
$records = @()
foreach ($relative in $relativeFiles) {
    $source = Join-Path $root $relative
    $target = Join-Path $content $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $target
    $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if ($hash -ne (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) { throw "Staging mismatch: $relative" }
    $records += [ordered]@{ path = $relative; bytes = (Get-Item -LiteralPath $target).Length; sha256 = $hash }
}
$zipPath = Join-Path $releaseRoot "WorkshopFilter-$version-RimWorld1.7.zip"
Compress-Archive -LiteralPath $content -DestinationPath $zipPath
$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $entries = @($archive.Entries | Where-Object Name -ne '')
    $expected = @($relativeFiles | ForEach-Object { "WorkshopFilter/$_" })
    if (Compare-Object ($expected | Sort-Object) ($entries.FullName | Sort-Object)) { throw 'Unexpected archive content.' }
    foreach ($entry in $entries) {
        $relative = $entry.FullName.Substring('WorkshopFilter/'.Length)
        $stream = $entry.Open()
        $hasher = [Security.Cryptography.SHA256]::Create()
        try { $hash = [Convert]::ToHexString($hasher.ComputeHash($stream)) }
        finally { $hasher.Dispose(); $stream.Dispose() }
        if ($hash -ne ($records | Where-Object path -eq $relative).sha256) { throw "Archive hash mismatch: $relative" }
    }
} finally { $archive.Dispose() }
$manifest = [ordered]@{
    version = $version
    packageId = [string]$about.ModMetaData.packageId
    appId = 294100
    repository = [string]$about.ModMetaData.url
    preparedUtc = [DateTime]::UtcNow.ToString('o')
    sourceCommit = $null
    steamUploadPerformed = $false
    files = $records
}
if (Test-Path -LiteralPath (Join-Path $root '.git')) {
    $commit = & git -C $root rev-parse HEAD 2>$null
    if ($LASTEXITCODE -eq 0) { $manifest.sourceCommit = $commit.Trim() }
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $releaseRoot 'manifest.json') -Encoding utf8NoBOM
$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
"$zipHash  $([IO.Path]::GetFileName($zipPath))" | Set-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt') -Encoding utf8NoBOM
Copy-Item -LiteralPath $zipPath -Destination (Join-Path $root "artifacts/WorkshopFilter-$version-RimWorld1.7.zip") -Force
Copy-Item -LiteralPath $zipPath -Destination (Join-Path $root 'artifacts/WorkshopFilter-1.7.zip') -Force
Write-Output "Release $version prepared: $releaseRoot"
Write-Output "$($records.Count) runtime files verified against the source, staging folder and ZIP. No upload performed."
