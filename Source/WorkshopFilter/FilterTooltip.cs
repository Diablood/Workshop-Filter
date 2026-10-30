using RimWorld;
using Verse;

namespace WorkshopFilter;

internal static class FilterTooltip
{
    internal static string Build(IReadOnlyCollection<FilterState> states)
    {
        var lines = new List<string> { "WF_Tooltip".Translate() };
        if (states.Count > 1) lines.Add("WF_SelectedTables".Translate(states.Count));
        if (!states.Any(s => s.Active))
        {
            lines.Add("WF_NoActiveFilters".Translate());
            return string.Join("\n", lines);
        }
        var modIds = states.Select(s => s.ModId).Distinct().ToList();
        if (modIds.Any(id => id != null))
        {
            string value = modIds.Count > 1 ? "WF_Mixed".Translate().ToString()
                : LoadedModManager.RunningModsListForReading.FirstOrDefault(m => m.PackageId == modIds[0])?.Name ?? modIds[0]!;
            lines.Add($"{"WF_Mod".Translate()} : {value}");
        }
        var layerIds = states.Select(s => s.Layer).Distinct().ToList();
        if (layerIds.Any(id => id != null))
        {
            string value = layerIds.Count > 1 ? "WF_Mixed".Translate().ToString()
                : DefDatabase<ApparelLayerDef>.GetNamedSilentFail(layerIds[0])?.LabelCap.ToString() ?? layerIds[0]!;
            lines.Add($"{"WF_Layer".Translate()} : {value}");
        }
        if (states.Any(s => s.NudistOnly))
            lines.Add(states.All(s => s.NudistOnly) ? "WF_Nudist".Translate().ToString()
                : $"{"WF_Nudist".Translate()} : {"WF_Mixed".Translate()}");
        return string.Join("\n", lines);
    }
}
