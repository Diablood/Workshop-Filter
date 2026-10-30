# Workshop Filter

[Français](README.md) · [Source](https://github.com/Diablood/Workshop-Filter)

**Version 0.3.1 — RimWorld 1.7**

Author: **Diablood**. Package ID: `diablood.workshopfilter` (formerly `diabl.workshopfilter` before 0.3.1). The local deployment script accepts the old identity and preserves any existing Workshop item ID. Ensure the new package ID is active after updating. Filter save types and keys are unchanged.

Find the products you want to craft without scrolling through every recipe. Workshop Filter adds combinable filters to the workshop's Add bill menu and supports Dubs Mint Menus when installed.

- **Source mod:** the mod defining the final product, with Core and DLC listed separately.
- **Apparel layer:** vanilla and modded layers are discovered from the workshop's recipes, including recipes not yet researched. The control appears only if a recipe produces apparel.
- **Nudist compatible:** one checkbox, using the game's nudity rule. Checked shows only compatible apparel, including eligible headgear and accessories; unchecked applies no nudity restriction.
- **Search:** find mods and layers by name or internal identifier, ignoring case and accents.
- **Saved per workshop:** your choices survive saving and loading. Existing saves start with no filters. Removed mods or layers have their corresponding criterion cleared.
- **Hover summary:** see active criteria, including mixed selections in the Dubs workshop window.

All active criteria must match the same final product. Existing bills, ingredient filters and crafting behavior remain unchanged. Recipes without declared final products are visible without filters and excluded when a product filter is active.

## Install

Requires **Harmony**. Dubs Mint Menus is **optional**.

Extract the release's `WorkshopFilter` folder into `RimWorld/Mods` and enable Harmony, then Workshop Filter. Avoid enabling a local copy and a Workshop copy at the same time.

Open a workshop's Bills tab and click **Filter products**. With Dubs, the button appears above its recipe search instead. Choose criteria, then close the window or click outside; selections apply immediately. **Reset** clears all criteria.

## Compatibility and saves

Supports the native workshop menu and the optional Dubs Mint Menus recipe panels, including multiple selected workshops. Other mods replacing the entire bill interface may need an adapter. Recipes generating products only through a custom worker, without `RecipeDef.products`, cannot be classified by these filters.

User-reported in-game checks passed for 0.3.0. Automated checks cover filtering, search and synthetic Scribe save/load round trips. Removal and downgrading have not received a dedicated full-game test; see [README.md](README.md) for development and verification details.

## Development and feedback

Build requires .NET 10, a local RimWorld 1.7 installation and the installed Harmony assembly. All scripts live in `tools/`: `tools/build.ps1` builds and checks, `tools/deploy.cmd` installs a clean local copy, and `tools/prepare-release.ps1` prepares the distribution archive and Workshop content without uploading them. Scripts resolve project paths from their own location and work from other working directories. `LayoutChecks` runs only when explicitly requested.

For a bug report, include the game/mod versions, affected workshop, selected filters, relevant interface mods, reproduction steps and a relevant log excerpt.

Code: MIT. Artwork is separate; see [LICENSING.md](LICENSING.md). [Changelog](CHANGELOG.md).
