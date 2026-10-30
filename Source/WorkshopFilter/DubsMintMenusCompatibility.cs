using HarmonyLib;
using RimWorld;
using UnityEngine;
using Verse;

namespace WorkshopFilter;

// No assembly reference: a missing optional mod leaves the native implementation intact.
internal static class DubsMintMenusCompatibility
{
    [ThreadStatic] private static HashSet<BillStack>? renderedPanels;

    internal static void BeginListing() => renderedPanels?.Clear();
    internal static bool HasPanel(BillStack stack) => renderedPanels?.Contains(stack) == true;

    internal static void Install(Harmony harmony)
    {
        var type = AccessTools.TypeByName("DubsMintMenus.Patch_BillStack_DoListing");
        if (type == null) return;
        var target = AccessTools.DeclaredMethod(type, "Dobills",
            [typeof(Rect), typeof(HashSet<Building>), typeof(List<RecipeDef>)]);
        if (target == null || !target.IsStatic || target.ReturnType != typeof(void))
        {
            Log.Warning("[Workshop Filter] Dubs Mint Menus recipe panel signature changed; optional integration skipped.");
            return;
        }
        try
        {
            harmony.Patch(target, prefix: new HarmonyMethod(typeof(DubsMintMenusCompatibility), nameof(DrawRecipePanel)));
            Log.Message("[Workshop Filter] Dubs Mint Menus recipe panel integration enabled.");
        }
        catch (Exception ex)
        {
            Log.Warning($"[Workshop Filter] Optional Dubs Mint Menus integration could not be enabled: {ex}");
        }
    }

    private static void DrawRecipePanel(ref Rect __0, HashSet<Building> __1, ref List<RecipeDef> __2)
    {
        var tables = __1.Where(t => t is IBillGiver).ToList();
        if (tables.Count == 0) return;
        renderedPanels ??= new HashSet<BillStack>();
        foreach (var table in tables) renderedPanels.Add(((IBillGiver)table).BillStack);
        var states = tables.Select(t => FilterContext.States.GetValue(((IBillGiver)t).BillStack,
            _ => new FilterState())).ToList();
        // Work on a copy of the display list only. GetBills is also used by templates
        // and bill creation, which must never be restricted by presentation filters.
        if (states.Any(s => s.Active))
        {
            var eligible = new HashSet<RecipeDef>();
            for (int i = 0; i < tables.Count; i++)
                foreach (var recipe in tables[i].def.AllRecipes.Where(states[i].Matches))
                    eligible.Add(recipe);
            __2 = __2.Where(eligible.Contains).ToList();
        }

        // Dubs positions its search row at rect.y - 8. Reserve a new row above it,
        // keeping the search, tabs and scroll view together in their original layout.
        var button = new Rect(__0.xMax + 26f, __0.y - 8f, 200f, 29f);
        __0.y += 34f;
        __0.height = Mathf.Max(0f, __0.height - 34f);
        var font = Text.Font;
        var anchor = Text.Anchor;
        Text.Font = GameFont.Small;
        Text.Anchor = TextAnchor.UpperLeft;
        try
        {
            if (Widgets.ButtonText(button, (states.Any(s => s.Active) ? "WF_FilterActive" : "WF_Filter").Translate()))
            {
                if (states.Count == 1)
                    Find.WindowStack.Add(new Dialog_ProductFilter(tables[0].def, states[0]));
                else
                {
                    var combined = new FilterState
                    {
                        ModId = states.Select(s => s.ModId).Distinct().Count() == 1 ? states[0].ModId : null,
                        Layer = states.Select(s => s.Layer).Distinct().Count() == 1 ? states[0].Layer : null,
                        NudistOnly = states.All(s => s.NudistOnly)
                    };
                    Find.WindowStack.Add(new Dialog_ProductFilter(tables.Select(t => t.def), combined, () =>
                    {
                        foreach (var state in states)
                        {
                            state.ModId = combined.ModId;
                            state.Layer = combined.Layer;
                            state.NudistOnly = combined.NudistOnly;
                        }
                    }));
                }
            }
            TooltipHandler.TipRegion(button, FilterTooltip.Build(states));
        }
        finally
        {
            Text.Font = font;
            Text.Anchor = anchor;
        }
    }
}
