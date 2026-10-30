namespace WorkshopFilter;

// Independent of game objects so the multi-product semantics can be tested directly.
internal sealed record ProductMetadata(string? ModId, IReadOnlyCollection<string> Layers, bool NudistCompatible = false);

internal static class ProductFilter
{
    internal static bool IsNudistCompatible(bool isApparel, bool countsAsClothing, bool coversTorsoOrLegs) =>
        isApparel && (!countsAsClothing || !coversTorsoOrLegs);

    internal static bool Matches(IEnumerable<ProductMetadata> products, string? modId, string? layer, bool nudistOnly = false)
    {
        if (modId == null && layer == null && !nudistOnly) return true;
        // All predicates must match the SAME final product.
        return products.Any(p => (modId == null || p.ModId == modId)
            && (layer == null || p.Layers.Contains(layer))
            && (!nudistOnly || p.NudistCompatible));
    }
}
