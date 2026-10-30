using HarmonyLib;
using RimWorld;
using System.Runtime.CompilerServices;
using System.Reflection.Emit;
using UnityEngine;
using Verse;

namespace WorkshopFilter;

public sealed class WorkshopFilterMod : Mod
{
    public WorkshopFilterMod(ModContentPack content) : base(content)
    {
        var harmony = new Harmony("diablood.workshopfilter");
        harmony.PatchAll();
        Log.Message($"[Workshop Filter] v{typeof(WorkshopFilterMod).Assembly.GetName().Version} loaded.");
        LongEventHandler.ExecuteWhenFinished(() => DubsMintMenusCompatibility.Install(harmony));
    }
}

internal sealed class FilterState : IExposable
{
    public FilterState() { }
    internal string? ModId;
    internal string? Layer;
    internal bool NudistOnly;
    internal bool Active => ModId != null || Layer != null || NudistOnly;
    private string? cachedModId;
    private string? cachedLayer;
    private bool cachedNudistOnly;
    private readonly Dictionary<RecipeDef, bool> matches = new();

    public void ExposeData()
    {
        Scribe_Values.Look(ref ModId, "modId");
        Scribe_Values.Look(ref Layer, "layer");
        Scribe_Values.Look(ref NudistOnly, "nudistOnly", false);
        if (Scribe.mode == LoadSaveMode.PostLoadInit)
        {
            // Removed mods/defs must not leave an invisible, unselectable restriction.
            if (ModId != null && !LoadedModManager.RunningModsListForReading.Any(m => m.PackageId == ModId)) ModId = null;
            if (Layer != null && DefDatabase<ApparelLayerDef>.GetNamedSilentFail(Layer) == null) Layer = null;
            matches.Clear();
        }
    }

    internal bool Matches(RecipeDef recipe)
    {
        if (!Active) return true;
        if (cachedModId != ModId || cachedLayer != Layer || cachedNudistOnly != NudistOnly)
        {
            matches.Clear();
            cachedModId = ModId;
            cachedLayer = Layer;
            cachedNudistOnly = NudistOnly;
        }
        if (matches.TryGetValue(recipe, out bool result)) return result;
        result = ProductFilter.Matches(recipe.products.Select(p => DescribeProduct(p.thingDef)), ModId, Layer, NudistOnly);
        matches.Add(recipe, result);
        return result;
    }

    private static ProductMetadata DescribeProduct(ThingDef product)
    {
        var apparel = product.apparel;
        // Same rule as ThoughtWorker_NudistNude: counted clothing only prevents
        // the nude thought if it covers the Torso or Legs body-part group.
        bool compatible = ProductFilter.IsNudistCompatible(apparel != null,
            apparel?.countsAsClothingForNudity ?? false,
            apparel?.bodyPartGroups.Any(g => g == BodyPartGroupDefOf.Torso || g == BodyPartGroupDefOf.Legs) ?? false);
        return new ProductMetadata(product.modContentPack?.PackageId,
            apparel?.layers.Select(l => l.defName).ToArray() ?? [], compatible);
    }
}

[HarmonyPatch(typeof(BillStack), nameof(BillStack.ExposeData))]
internal static class BillFilterSavePatch
{
    private static void Postfix(BillStack __instance)
    {
        FilterContext.States.TryGetValue(__instance, out var state);
        Scribe_Deep.Look(ref state, "workshopFilter");
        if (Scribe.mode == LoadSaveMode.LoadingVars)
        {
            FilterContext.States.Remove(__instance);
            if (state != null) FilterContext.States.Add(__instance, state);
        }
    }
}

internal static class FilterContext
{
    internal static readonly ConditionalWeakTable<BillStack, FilterState> States = new();
    [ThreadStatic] internal static ThingDef? Table;
    [ThreadStatic] internal static List<RecipeDef>? Recipes;

    internal static List<FloatMenuOption> MakeOptions(ThingDef table, FilterState state,
        Func<List<FloatMenuOption>> original)
    {
        if (!state.Active) return original();
        var previousTable = Table;
        var previousRecipes = Recipes;
        // Fetch outside the scope: never mutate the game's cached recipe list.
        var filtered = table.AllRecipes.Where(state.Matches).ToList();
        try
        {
            Table = table;
            Recipes = filtered;
            return original();
        }
        finally
        {
            Table = previousTable;
            Recipes = previousRecipes;
        }
    }
}

[HarmonyPatch(typeof(ThingDef), nameof(ThingDef.AllRecipes), MethodType.Getter)]
internal static class RecipeListPatch
{
    private static void Postfix(ThingDef __instance, ref List<RecipeDef> __result)
    {
        if (ReferenceEquals(__instance, FilterContext.Table) && FilterContext.Recipes != null)
            __result = FilterContext.Recipes;
    }
}

[HarmonyPatch(typeof(BillStack), nameof(BillStack.DoListing))]
internal static class BillListingPatch
{
    private static bool layoutReady;

    [HarmonyPriority(Priority.First)]
    private static void Prefix(BillStack __instance, ref Func<List<FloatMenuOption>> recipeOptionsMaker)
    {
        DubsMintMenusCompatibility.BeginListing();
        // Pawns also own BillStacks for surgery. Only buildings expose product filters.
        if (__instance.billGiver is not Building table) return;
        var state = FilterContext.States.GetValue(__instance, _ => new FilterState());
        var original = recipeOptionsMaker;
        recipeOptionsMaker = () => FilterContext.MakeOptions(table.def, state, original);
    }

    private static void Postfix(BillStack __instance, Rect rect)
    {
        if (!layoutReady || DubsMintMenusCompatibility.HasPanel(__instance)
            || __instance.billGiver is not Building table || __instance.Count >= BillStack.MaxCount) return;
        var state = FilterContext.States.GetValue(__instance, _ => new FilterState());
        var button = new Rect(rect.x, rect.y + 35f, Mathf.Min(200f, rect.width), 29f);
        if (button.width < 70f) return;
        if (Widgets.ButtonText(button, (state.Active ? "WF_FilterActive" : "WF_Filter").Translate()))
            Find.WindowStack.Add(new Dialog_ProductFilter(table.def, state));
        TooltipHandler.TipRegion(button, FilterTooltip.Build([state]));
    }

    private static float HeaderHeight(BillStack stack) =>
        stack.billGiver is Building && stack.Count < BillStack.MaxCount
            && !DubsMintMenusCompatibility.HasPanel(stack) ? 69f : 35f;

    private static IEnumerable<CodeInstruction> Transpiler(IEnumerable<CodeInstruction> instructions)
    {
        var codes = instructions.ToList();
        // Change both the native scroll viewport Y and its height subtraction.
        // The Add bill/paste/close header keeps its original position.
        var offsets = codes.Where(c => c.opcode == OpCodes.Ldc_R4 && c.operand is float f && f == 35f).ToList();
        layoutReady = offsets.Count == 2;
        if (!layoutReady)
        {
            Log.Warning("[Workshop Filter] Bill header layout changed; native filter button hidden to avoid overlapping controls.");
            return codes;
        }
        var height = AccessTools.DeclaredMethod(typeof(BillListingPatch), nameof(HeaderHeight));
        var result = new List<CodeInstruction>();
        foreach (var code in codes)
        {
            if (offsets.Contains(code))
            {
                code.opcode = OpCodes.Ldarg_0;
                code.operand = null;
                result.Add(code);
                result.Add(new CodeInstruction(OpCodes.Call, height));
            }
            else result.Add(code);
        }
        return result;
    }
}
