using UnityEngine;
using Verse;

namespace WorkshopFilter;

internal sealed record FilterChoice(string Label, string SearchText, Action Select);

internal sealed class Dialog_FilterChoice : Window
{
    private readonly string title;
    private readonly string clearLabel;
    private readonly Action clear;
    private readonly List<FilterChoice> choices;
    private List<FilterChoice> visible;
    private string search = "";
    private Vector2 scroll;
    private bool focused;

    public override Vector2 InitialSize => new(460f, Mathf.Min(540f, UI.screenHeight - 40f));

    internal Dialog_FilterChoice(string title, string clearLabel, Action clear, IEnumerable<FilterChoice> choices)
    {
        this.title = title;
        this.clearLabel = clearLabel;
        this.clear = clear;
        this.choices = choices.ToList();
        visible = this.choices;
        layer = WindowLayer.Super;
        doCloseX = true;
        closeOnClickedOutside = true;
        absorbInputAroundWindow = true;
    }

    public override void DoWindowContents(Rect inRect)
    {
        Text.Font = GameFont.Medium;
        Widgets.Label(new Rect(0f, 0f, inRect.width - 30f, 32f), title);
        Text.Font = GameFont.Small;
        Widgets.Label(new Rect(0f, 42f, 100f, 30f), "WF_Search".Translate());
        GUI.SetNextControlName("WorkshopFilter.ChoiceSearch");
        string next = Widgets.TextField(new Rect(105f, 40f, inRect.width - 105f, 30f), search);
        if (!focused)
        {
            GUI.FocusControl("WorkshopFilter.ChoiceSearch");
            focused = true;
        }
        if (next != search)
        {
            search = next;
            visible = choices.Where(c => SearchMatcher.Matches(c.SearchText, search)).ToList();
            scroll = Vector2.zero;
        }
        if (Widgets.ButtonText(new Rect(0f, 82f, inRect.width, 30f), clearLabel))
        {
            clear();
            Close();
        }
        var viewport = new Rect(0f, 124f, inRect.width, Mathf.Max(0f, inRect.height - 124f));
        if (visible.Count == 0)
        {
            Widgets.Label(viewport, "WF_NoResults".Translate());
            return;
        }
        float width = viewport.width - 16f;
        var heights = visible.Select(c => Mathf.Max(32f, Text.CalcHeight(c.Label, width - 16f) + 12f)).ToArray();
        var content = new Rect(0f, 0f, width, heights.Sum() + 4f * (visible.Count - 1));
        Widgets.BeginScrollView(viewport, ref scroll, content);
        float y = 0f;
        for (int i = 0; i < visible.Count; i++)
        {
            if (Widgets.ButtonText(new Rect(0f, y, width, heights[i]), visible[i].Label))
            {
                visible[i].Select();
                Close();
            }
            y += heights[i] + 4f;
        }
        Widgets.EndScrollView();
    }
}
