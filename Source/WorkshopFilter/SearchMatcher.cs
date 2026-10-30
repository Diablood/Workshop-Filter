using System.Globalization;

namespace WorkshopFilter;

internal static class SearchMatcher
{
    internal static bool Matches(string text, string query) => query
        .Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries)
        .All(term => CultureInfo.CurrentCulture.CompareInfo.IndexOf(text, term,
            CompareOptions.IgnoreCase | CompareOptions.IgnoreNonSpace) >= 0);
}
