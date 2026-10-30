[CmdletBinding()]
param([string]$RimWorldDir = 'D:\SteamLibrary\steamapps\common\RimWorld')
$ErrorActionPreference = 'Stop'
# Runs in PowerShell against Scribe itself; does not build or launch a test executable.
# Only synthetic XML under artifacts is touched, never the player's saves or config.
$root = Split-Path -Parent $PSScriptRoot
if (-not ('WorkshopFilterSaveLoadContext' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Reflection;
using System.Runtime.Loader;
public sealed class WorkshopFilterSaveLoadContext : AssemblyLoadContext
{
    private readonly string gameDirectory;
    public WorkshopFilterSaveLoadContext(string gameDirectory) : base(true) { this.gameDirectory = gameDirectory; }
    protected override Assembly Load(AssemblyName name)
    {
        // Use the host framework but isolate game libraries from PowerShell's own packages.
        if (name.Name.StartsWith("System.") || name.Name == "mscorlib" || name.Name == "netstandard") return null;
        string path = Path.Combine(gameDirectory, name.Name + ".dll");
        return File.Exists(path) ? LoadFromAssemblyPath(path) : null;
    }
}
'@
}
$loadContext = [WorkshopFilterSaveLoadContext]::new((Resolve-Path -LiteralPath $RimWorldDir).ProviderPath)
$game = $loadContext.LoadFromAssemblyPath((Join-Path $RimWorldDir 'Assembly-CSharp.dll'))
$mod = $loadContext.LoadFromAssemblyPath((Join-Path $root '1.7\Assemblies\WorkshopFilter.dll'))
$flags = [Reflection.BindingFlags]'Public,NonPublic,Instance,Static'
# Profiling reads the running game's preferences; they do not exist in this harness.
$game.GetType('Verse.DeepProfiler', $true).GetField('enabled', $flags).SetValue($null, $false)
$stateType = $mod.GetType('WorkshopFilter.FilterState', $true)
$stackType = $game.GetType('RimWorld.BillStack', $true)
$context = $mod.GetType('WorkshopFilter.FilterContext', $true)
$states = $context.GetField('States', $flags).GetValue($null)
$patch = $mod.GetType('WorkshopFilter.BillFilterSavePatch', $true).GetMethod('Postfix', $flags)
$scribe = $game.GetType('Verse.Scribe', $true)
$saver = $scribe.GetField('saver').GetValue($null)
$loader = $scribe.GetField('loader').GetValue($null)
$fixtureRoot = Join-Path $root ('artifacts\save-check\' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null

function New-Stack { return ,([Activator]::CreateInstance($stackType, [object[]]@(,$null))) }
function New-State([string]$modId, $layer, [bool]$nudist) {
    $value = [Activator]::CreateInstance($stateType, $true)
    $stateType.GetField('ModId', $flags).SetValue($value, $modId)
    $stateType.GetField('Layer', $flags).SetValue($value, $layer)
    $stateType.GetField('NudistOnly', $flags).SetValue($value, $nudist)
    return $value
}
function Read-State($stack) {
    if ($null -eq $stack) { throw 'Null stack passed into Read-State.' }
    $lookup = [object[]]::new(2)
    $lookup[0] = $stack
    if ($states.GetType().GetMethod('TryGetValue').Invoke($states, $lookup)) { return $lookup[1] }
    return $null
}
function Save-Stacks([string]$path, [object[]]$stacks) {
    try {
        $saver.InitSaving($path, 'root')
        for ($i = 0; $i -lt $stacks.Count; $i++) {
            $scribe.GetMethod('EnterNode').Invoke($null, @("bench$i")) | Out-Null
            $stacks[$i].ExposeData()
            $patch.Invoke($null, @($stacks[$i])) | Out-Null
            $scribe.GetMethod('ExitNode').Invoke($null, $null) | Out-Null
        }
        $saver.FinalizeSaving()
    } finally { $scribe.GetMethod('ForceStop').Invoke($null, $null) | Out-Null }
}
function Load-Stacks([string]$path, [int]$count) {
    $loaded = @()
    try {
        $loader.InitLoading($path)
        for ($i = 0; $i -lt $count; $i++) {
            $stack = New-Stack
            $scribe.GetMethod('EnterNode').Invoke($null, @("bench$i")) | Out-Null
            $stack.ExposeData()
            $patch.Invoke($null, @($stack)) | Out-Null
            $scribe.GetMethod('ExitNode').Invoke($null, $null) | Out-Null
            $loaded += ,$stack
        }
        $loader.FinalizeLoading()
    } finally { $scribe.GetMethod('ForceStop').Invoke($null, $null) | Out-Null }
    if ($loaded.Count -ne $count) { throw "Unexpected fixture count: $($loaded.Count), expected $count" }
    return ,$loaded
}
$script:checks = 0
function Assert-Check([bool]$condition, [string]$label) {
    if (-not $condition) { throw $label }
    $script:checks++
}

# Synthetic mod and layer, held only in this isolated process.
$packType = $game.GetType('Verse.ModContentPack', $true)
$pack = [Runtime.CompilerServices.RuntimeHelpers]::GetUninitializedObject($packType)
$packType.GetField('packageIdInt', $flags).SetValue($pack, 'workshopfilter.testfixture')
$handlerType = $game.GetType('Verse.ModAssemblyHandler', $true)
$assemblyHandler = [Activator]::CreateInstance($handlerType, [object[]]@($pack))
$handlerType.GetField('loadedAssemblies').GetValue($assemblyHandler).Add($mod)
$packType.GetField('assemblies', $flags).SetValue($pack, $assemblyHandler)
$runningMods = $game.GetType('Verse.LoadedModManager', $true).GetProperty('RunningModsListForReading').GetValue($null)
$runningMods.Add($pack)
$layerType = $game.GetType('Verse.ApparelLayerDef', $true)
$layer = [Activator]::CreateInstance($layerType)
$layerType.GetField('defName').SetValue($layer, 'WorkshopFilter_TestLayer')
$database = $game.GetType('Verse.DefDatabase`1', $true).MakeGenericType($layerType)
$database.GetMethod('Add', [type[]]@($layerType)).Invoke($null, @($layer)) | Out-Null
try {
    $first = New-Stack
    $second = New-Stack
    $firstState = New-State 'workshopfilter.testfixture' 'WorkshopFilter_TestLayer' $true
    $secondState = New-State 'workshopfilter.testfixture' $null $false
    $states.Add($first, $firstState)
    $states.Add($second, $secondState)
    $savePath = Join-Path $fixtureRoot 'current.xml'
    Save-Stacks $savePath @($first, $second)
    $loaded = Load-Stacks $savePath 2
    $a = Read-State $loaded[0]
    $b = Read-State $loaded[1]
    Assert-Check ($null -ne $a) 'First bench state was not restored.'
    Assert-Check ($stateType.GetField('ModId', $flags).GetValue($a) -eq 'workshopfilter.testfixture') 'Mod filter round trip failed.'
    Assert-Check ($stateType.GetField('Layer', $flags).GetValue($a) -eq 'WorkshopFilter_TestLayer') 'Custom layer round trip failed.'
    Assert-Check ($stateType.GetField('NudistOnly', $flags).GetValue($a) -eq $true) 'Nudist filter round trip failed.'
    Assert-Check ($null -eq $stateType.GetField('Layer', $flags).GetValue($b) -and
        $stateType.GetField('NudistOnly', $flags).GetValue($b) -eq $false) 'Bench selections are not independent.'
    [xml]$oldSave = Get-Content -LiteralPath $savePath -Raw
    foreach ($node in @($oldSave.SelectNodes('//workshopFilter'))) { $node.ParentNode.RemoveChild($node) | Out-Null }
    $oldPath = Join-Path $fixtureRoot 'legacy.xml'
    $oldSave.Save($oldPath)
    $legacy = Load-Stacks $oldPath 2
    Assert-Check ($null -eq (Read-State $legacy[0]) -and $null -eq (Read-State $legacy[1])) 'Legacy save must start without filters.'
    $runningMods.Remove($pack) | Out-Null
    $database.GetMethod('Clear').Invoke($null, $null) | Out-Null
    $missing = Read-State (Load-Stacks $savePath 2)[0]
    Assert-Check ($null -eq $stateType.GetField('ModId', $flags).GetValue($missing)) 'Removed mod restriction was not cleared.'
    Assert-Check ($null -eq $stateType.GetField('Layer', $flags).GetValue($missing)) 'Removed layer restriction was not cleared.'
    Assert-Check ($stateType.GetField('NudistOnly', $flags).GetValue($missing) -eq $true) 'Unrelated nudist criterion should survive cleanup.'
    Write-Output "$script:checks Scribe save/load checks passed. Synthetic XML: $fixtureRoot"
} finally {
    $runningMods.Remove($pack) | Out-Null
    $database.GetMethod('Clear').Invoke($null, $null) | Out-Null
    $scribe.GetMethod('ForceStop').Invoke($null, $null) | Out-Null
}
