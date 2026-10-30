[CmdletBinding()]
param(
    [string]$RimWorldDir = 'D:\SteamLibrary\steamapps\common\RimWorld',
    [string]$HarmonyAssemblyPath = 'D:\SteamLibrary\steamapps\workshop\content\294100\2009463077\1.7\Assemblies\0Harmony.dll',
    [switch]$RunLayoutChecks
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    & dotnet build Source/WorkshopFilter/WorkshopFilter.csproj -c Release "-p:RimWorldDir=$RimWorldDir" "-p:HarmonyAssemblyPath=$HarmonyAssemblyPath" --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
    New-Item -ItemType Directory -Path '1.7/Assemblies' -Force | Out-Null
    Copy-Item -LiteralPath 'Source/WorkshopFilter/bin/Release/net10.0/WorkshopFilter.dll' -Destination '1.7/Assemblies/WorkshopFilter.dll'
    & dotnet run --project Tests/WorkshopFilter.Tests.csproj -c Release
    if ($LASTEXITCODE -ne 0) { throw 'Filter checks failed.' }
    if ($RunLayoutChecks) {
        & dotnet run --project Tests/Layout/LayoutChecks.csproj -c Release "-p:RimWorldDir=$RimWorldDir" "-p:HarmonyAssemblyPath=$HarmonyAssemblyPath"
        if ($LASTEXITCODE -ne 0) { throw 'Layout checks failed.' }
    }
    & (Join-Path $PSScriptRoot 'check-project.ps1') -RimWorldDir $RimWorldDir -HarmonyAssemblyPath $HarmonyAssemblyPath
} finally { Pop-Location }
