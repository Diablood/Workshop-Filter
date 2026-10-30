using RimWorld;
using UnityEngine;
using Verse;

namespace WorkshopFilter;

internal sealed class Dialog_ProductFilter : Window
{
    private readonly List<RecipeDef> recipes;
    private readonly FilterState state;
    private readonly Action? changed;
    private readonly List<ModContentPack> mods;
    private readonly List<ApparelLayerDef> layers;
    private readonly bool showLayerFilter;

    public override Vector2 InitialSize => new(580f, showLayerFilter ? 382f : 298f);

    internal Dialog_ProductFilter(ThingDef table, FilterState state) : this([table], state) { }

    internal Dialog_ProductFilter(IEnumerable<ThingDef> tables, FilterState state, Action? changed = null)
    {
        recipes = tables.Distinct().SelectMany(t => t.AllRecipes).Distinct().ToList();
        this.state = state;
        this.changed = changed;
        var products = recipes.SelectMany(r => r.products).Select(p => p.thingDef).Distinct().ToList();
        showLayerFilter = products.Any(p => p.apparel != null);
        // A hidden criterion must never silently restrict the product list.
        if (!showLayerFilter && (state.Layer != null || state.NudistOnly))
        {
            state.Layer = null;
            state.NudistOnly = false;
            changed?.Invoke();
        }
        mods = products.Select(p => p.modContentPack).Where(m => m != null)
            .Distinct().OrderBy(m => m.Name).ToList();
        layers = products.Where(p => p.apparel != null).SelectMany(p => p.apparel.layers)
            .Distinct().OrderBy(l => l.drawOrder).ThenBy(l => l.label).ToList();
        doCloseX = true;
        doCloseButton = true;
        closeOnClickedOutside = true;
        absorbInputAroundWindow = true;
    }

    public override void DoWindowContents(Rect inRect)
    {
        Text.Font = GameFont.Medium;
        Widgets.Label(new Rect(0f, 0f, inRect.width - 30f, 35f), "WF_Title".Translate());
        Text.Font = GameFont.Small;
        Widgets.Label(new Rect(0f, 44f, inRect.width, 48f),
            (showLayerFilter ? "WF_Explanation" : "WF_ExplanationModOnly").Translate());
        Widgets.Label(new Rect(0f, 100f, 100f, 30f), "WF_Mod".Translate());
        var selectedMod = mods.FirstOrDefault(m => m.PackageId == state.ModId);
        if (Widgets.ButtonText(new Rect(105f, 98f, inRect.width - 105f, 30f),
            selectedMod?.Name ?? "WF_AllMods".Translate().ToString()))
        {
            Find.WindowStack.Add(new Dialog_FilterChoice("WF_ChooseMod".Translate(), "WF_AllMods".Translate(),
                () => SetMod(null), mods.Select(m => new FilterChoice(m.Name, $"{m.Name} {m.PackageId}", () => SetMod(m.PackageId)))));
        }
        if (showLayerFilter)
        {
            Widgets.Label(new Rect(0f, 142f, 100f, 30f), "WF_Layer".Translate());
            var selectedLayer = layers.FirstOrDefault(l => l.defName == state.Layer);
            if (Widgets.ButtonText(new Rect(105f, 140f, inRect.width - 105f, 30f),
                selectedLayer?.LabelCap.ToString() ?? "WF_AllLayers".Translate().ToString()))
            {
                Find.WindowStack.Add(new Dialog_FilterChoice("WF_ChooseLayer".Translate(), "WF_AllLayers".Translate(),
                    () => SetLayer(null), layers.Select(l => new FilterChoice(
                        $"{l.LabelCap} ({l.modContentPack?.Name})", $"{l.label} {l.defName} {l.modContentPack?.Name}",
                        () => SetLayer(l.defName)))));
            }
            var nudistRect = new Rect(0f, 182f, inRect.width, 30f);
            bool nudistOnly = state.NudistOnly;
            Widgets.CheckboxLabeled(nudistRect, "WF_Nudist".Translate(), ref nudistOnly);
            TooltipHandler.TipRegion(nudistRect, "WF_NudistTip".Translate());
            if (nudistOnly != state.NudistOnly)
            {
                state.NudistOnly = nudistOnly;
                changed?.Invoke();
            }
        }
        float footerY = showLayerFilter ? 225f : 141f;
        int count = recipes.Count(r => r.AvailableNow && state.Matches(r));
        Widgets.Label(new Rect(0f, footerY + 4f, inRect.width - 180f, 40f), "WF_Count".Translate(count));
        if (Widgets.ButtonText(new Rect(inRect.width - 170f, footerY, 170f, 30f), "WF_Reset".Translate()))
        {
            state.ModId = null;
            state.Layer = null;
            state.NudistOnly = false;
            changed?.Invoke();
        }
    }

    private void SetMod(string? value)
    {
        state.ModId = value;
        changed?.Invoke();
    }

    private void SetLayer(string? value)
    {
        state.Layer = value;
        changed?.Invoke();
    }
}
