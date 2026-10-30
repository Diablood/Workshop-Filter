[CmdletBinding()]
param(
    [string]$RimWorldDir = 'D:\SteamLibrary\steamapps\common\RimWorld',
    [string]$HarmonyAssemblyPath = 'D:\SteamLibrary\steamapps\workshop\content\294100\2009463077\1.7\Assemblies\0Harmony.dll',
    [string]$DubsMintMenusAssemblyPath = 'D:\SteamLibrary\steamapps\workshop\content\294100\1446523594\1.7\Assemblies\DubsMintMenus.dll'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sdkVersion = (& dotnet --version).Trim()
$dotnetRoot = Split-Path -Parent (Get-Command dotnet -CommandType Application).Source
Add-Type -Path (Join-Path $dotnetRoot "sdk\$sdkVersion\System.Reflection.MetadataLoadContext.dll")
$modDll = Join-Path $root '1.7\Assemblies\WorkshopFilter.dll'
[string[]]$paths = @((Get-ChildItem -LiteralPath $RimWorldDir -Filter '*.dll').FullName) + @($HarmonyAssemblyPath, $modDll)
if (Test-Path -LiteralPath $DubsMintMenusAssemblyPath -PathType Leaf) { $paths += $DubsMintMenusAssemblyPath }
$context = [System.Reflection.MetadataLoadContext]::new([System.Reflection.PathAssemblyResolver]::new($paths), 'System.Private.CoreLib')
try {
    $game = $context.LoadFromAssemblyPath((Join-Path $RimWorldDir 'Assembly-CSharp.dll'))
    $mod = $context.LoadFromAssemblyPath($modDll)
    if (@($mod.GetReferencedAssemblies() | Where-Object Name -eq 'DubsMintMenus').Count -ne 0) {
        throw 'Dubs Mint Menus must remain optional: assembly dependency found.'
    }
    $flags = [System.Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly'
    $patches = @($mod.GetTypes() | Where-Object { $_.GetCustomAttributesData().AttributeType.FullName -contains 'HarmonyLib.HarmonyPatch' })
    if ($patches.Count -ne 3) { throw 'Expected three Harmony patch classes.' }
    foreach ($patch in $patches) {
        $attribute = $patch.GetCustomAttributesData() | Where-Object { $_.AttributeType.FullName -eq 'HarmonyLib.HarmonyPatch' }
        $type = $game.GetType($attribute.ConstructorArguments[0].Value.FullName, $true)
        $methodName = [string]$attribute.ConstructorArguments[1].Value
        if ($attribute.ConstructorArguments.Count -eq 3) { $methodName = 'get_' + $methodName }
        $methods = @($type.GetMethods($flags) | Where-Object Name -eq $methodName)
        if ($methods.Count -ne 1) { throw "Ambiguous or missing patch target $methodName" }
        $method = $methods[0]
        foreach ($handler in $patch.GetMethods($flags)) {
            if ($handler.Name -notin @('Prefix', 'Postfix')) { continue }
            foreach ($parameter in $handler.GetParameters()) {
                if ($parameter.Name -eq '__instance') { $expected = $type }
                elseif ($parameter.Name -eq '__result') { $expected = $method.ReturnType }
                else {
                    $targetParameters = @($method.GetParameters() | Where-Object Name -eq $parameter.Name)
                    if ($targetParameters.Count -ne 1) { throw "Missing parameter $($parameter.Name)" }
                    $expected = $targetParameters[0].ParameterType
                }
                $actual = $parameter.ParameterType
                if ($actual.IsByRef) { $actual = $actual.GetElementType() }
                if ($actual.FullName -ne $expected.FullName) { throw "Parameter mismatch: $($parameter.Name)" }
            }
        }
        Write-Output "Patch signature verified: $($type.FullName).$methodName"
    }
    if (Test-Path -LiteralPath $DubsMintMenusAssemblyPath -PathType Leaf) {
        $dubs = $context.LoadFromAssemblyPath($DubsMintMenusAssemblyPath)
        $panel = $dubs.GetType('DubsMintMenus.Patch_BillStack_DoListing', $true)
        $draw = @($panel.GetMethods($flags) | Where-Object Name -eq 'Dobills')
        $expectedTypes = @('UnityEngine.Rect', 'System.Collections.Generic.HashSet`1[[Verse.Building, Assembly-CSharp', 'System.Collections.Generic.List`1[[Verse.RecipeDef, Assembly-CSharp')
        if ($draw.Count -ne 1 -or -not $draw[0].IsStatic -or $draw[0].ReturnType.FullName -ne 'System.Void') {
            throw 'Optional Dubs Mint Menus panel target changed.'
        }
        $parameters = $draw[0].GetParameters()
        if ($parameters.Count -ne 3) { throw 'Dubs panel parameter count changed.' }
        $handler = $mod.GetType('WorkshopFilter.DubsMintMenusCompatibility', $true).GetMethod('DrawRecipePanel', $flags)
        $handlerParameters = $handler.GetParameters()
        for ($i = 0; $i -lt 3; $i++) {
            $actual = $handlerParameters[$i].ParameterType
            if ($actual.IsByRef) { $actual = $actual.GetElementType() }
            if (-not $parameters[$i].ParameterType.FullName.StartsWith($expectedTypes[$i]) -or
                $actual.FullName -ne $parameters[$i].ParameterType.FullName -or $handlerParameters[$i].Name -ne "__$i") {
                throw "Dubs panel parameter $i changed."
            }
        }
        Write-Output 'Optional Dubs Mint Menus panel signature verified; no assembly dependency.'
    }
} finally { $context.Dispose() }
[xml]$about = Get-Content -LiteralPath (Join-Path $root 'About/About.xml') -Raw
[xml]$folders = Get-Content -LiteralPath (Join-Path $root 'LoadFolders.xml') -Raw
if ($about.ModMetaData.packageId -ne 'diablood.workshopfilter' -or $about.ModMetaData.author -ne 'Diablood') {
    throw 'Package identity and author must use Diablood.'
}
[xml]$versionProps = Get-Content -LiteralPath (Join-Path $root 'Directory.Build.props') -Raw
$version = [string]$versionProps.Project.PropertyGroup.Version
if ($version -notmatch '^\d+\.\d+\.\d+$' -or $about.ModMetaData.modVersion -ne $version -or
    [Reflection.AssemblyName]::GetAssemblyName($modDll).Version.ToString() -ne "$version.0") {
    throw 'Mod metadata, assembly and project versions must agree.'
}
if ((Get-Content -LiteralPath (Join-Path $root 'CHANGELOG.md') -Raw) -notmatch "(?m)^## $([regex]::Escape($version)) — ") {
    throw 'Current version is missing from the changelog.'
}
Write-Output "Mod version verified: $version"
if ($about.ModMetaData.supportedVersions.li -ne '1.7' -or $null -eq $folders.loadFolders.'v1.7') { throw 'Invalid target game version.' }
if (@($about.ModMetaData.modDependencies.li | Where-Object packageId -eq 'dubwise.dubsmintmenus').Count) {
    throw 'Dubs Mint Menus must not be a required mod dependency.'
}
[xml]$english = Get-Content -LiteralPath (Join-Path $root 'Languages/English/Keyed/WorkshopFilter.xml') -Raw
[xml]$french = Get-Content -LiteralPath (Join-Path $root 'Languages/French/Keyed/WorkshopFilter.xml') -Raw
$enKeys = @($english.LanguageData.ChildNodes | Where-Object NodeType -eq Element | ForEach-Object Name)
$frKeys = @($french.LanguageData.ChildNodes | Where-Object NodeType -eq Element | ForEach-Object Name)
if (Compare-Object $enKeys $frKeys) { throw 'Translation keys differ.' }
$source = (Get-ChildItem -LiteralPath (Join-Path $root 'Source/WorkshopFilter') -Filter '*.cs' | Get-Content -Raw) -join "`n"
$usedKeys = [regex]::Matches($source, '"(WF_[A-Za-z]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
foreach ($key in $usedKeys) { if ($key -notin $enKeys) { throw "Missing translation: $key" } }
Write-Output 'Metadata, XML and translation checks passed. Runtime patching requires in-game validation.'
