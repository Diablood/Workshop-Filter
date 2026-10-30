using WorkshopFilter;

int checks = 0;
void Check(string name, bool actual, bool expected)
{
    if (actual != expected) throw new Exception(name);
    checks++;
}
ProductMetadata[] products = [new("ludeon.rimworld", ["OnSkin", "Middle"]), new("author.mod", ["CustomOuter"])];
Check("Unfiltered productless recipe stays visible", ProductFilter.Matches([], null, null), true);
Check("Productless recipe excluded by mod", ProductFilter.Matches([], "author.mod", null), false);
Check("Productless recipe excluded by layer", ProductFilter.Matches([], null, "Middle"), false);
Check("Vanilla source", ProductFilter.Matches(products, "ludeon.rimworld", null), true);
Check("Mod source", ProductFilter.Matches(products, "author.mod", null), true);
Check("Other mod excluded", ProductFilter.Matches(products, "other.mod", null), false);
Check("Vanilla layer", ProductFilter.Matches(products, null, "Middle"), true);
Check("Custom layer", ProductFilter.Matches(products, null, "CustomOuter"), true);
Check("Other layer excluded", ProductFilter.Matches(products, null, "Belt"), false);
Check("Combined criteria", ProductFilter.Matches(products, "author.mod", "CustomOuter"), true);
Check("Criteria cannot match different products", ProductFilter.Matches(products, "author.mod", "Middle"), false);
Check("Non apparel with all layers", ProductFilter.Matches([new("author.mod", [])], "author.mod", null), true);
Check("Non apparel with selected layer", ProductFilter.Matches([new("author.mod", [])], null, "Middle"), false);
Check("Unknown product owner is retained unfiltered", ProductFilter.Matches([new(null, [])], null, null), true);
Check("Items are not nudist apparel", ProductFilter.IsNudistCompatible(false, false, false), false);
Check("Normal torso or leg clothing prevents nudity", ProductFilter.IsNudistCompatible(true, true, true), false);
Check("Explicitly non-counting apparel allows nudity", ProductFilter.IsNudistCompatible(true, false, true), true);
Check("Headgear allows nudity even when counted as clothing", ProductFilter.IsNudistCompatible(true, true, false), true);
Check("Non-counting accessories allow nudity", ProductFilter.IsNudistCompatible(true, false, false), true);
Check("Nudist filter excludes productless recipes", ProductFilter.Matches([], null, null, true), false);
Check("Nudist filter excludes ordinary apparel", ProductFilter.Matches(products, null, null, true), false);
ProductMetadata[] nudistProducts = [new("author.mod", ["CustomHat"], true), new("ludeon.rimworld", ["OnSkin"], false)];
Check("Nudist compatible recipe included", ProductFilter.Matches(nudistProducts, null, null, true), true);
Check("All three criteria combined", ProductFilter.Matches(nudistProducts, "author.mod", "CustomHat", true), true);
Check("Nudist and mod must match same product", ProductFilter.Matches(nudistProducts, "ludeon.rimworld", null, true), false);
Check("Nudist and layer must match same product", ProductFilter.Matches(nudistProducts, null, "OnSkin", true), false);
Check("Unchecked allows non-compatible products", ProductFilter.Matches(nudistProducts, "ludeon.rimworld", "OnSkin", false), true);
Check("Empty search includes all choices", SearchMatcher.Matches("Couche externe", ""), true);
Check("Whitespace search includes all choices", SearchMatcher.Matches("Couche externe", "   "), true);
Check("Search ignores casing", SearchMatcher.Matches("Vanilla Expanded", "VANILLA"), true);
Check("Search ignores accents", SearchMatcher.Matches("Vêtements épais", "vetements epais"), true);
Check("Search terms match in any order", SearchMatcher.Matches("Couche externe CustomMod", "custom couche"), true);
Check("All search terms are required", SearchMatcher.Matches("Couche externe", "couche interne"), false);
Check("Internal identifiers can be searched", SearchMatcher.Matches("Couche externe Custom_Outer", "custom_outer"), true);
Console.WriteLine($"{checks} filtering and search checks passed.");
