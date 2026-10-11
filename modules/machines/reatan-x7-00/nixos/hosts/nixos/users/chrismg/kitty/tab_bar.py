from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title
from kitty.utils import color_as_int


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Draw separated, rounded tab capsules on the tab-bar background."""
    bar_bg = as_rgb(color_as_int(draw_data.default_bg))
    tab_bg = screen.cursor.bg
    tab_fg = screen.cursor.fg

    # Keep one blank cell between capsules and paint the rounded edges in
    # the tab's background color. Kitty includes the Powerline glyphs.
    screen.cursor.bg = bar_bg
    screen.cursor.fg = tab_bg
    screen.draw("")

    screen.cursor.bg = tab_bg
    screen.cursor.fg = tab_fg
    screen.draw(" ")

    title_width = max(0, max_tab_length - 4)
    title_start = screen.cursor.x
    draw_title(draw_data, screen, tab, index, title_width)
    overflow = screen.cursor.x - title_start - title_width
    if overflow > 0:
        screen.cursor.x -= overflow + 1
        screen.draw("…")

    screen.draw(" ")
    screen.cursor.bg = bar_bg
    screen.cursor.fg = tab_bg
    screen.draw("")

    if screen.cursor.x < screen.columns:
        screen.cursor.fg = 0
        screen.draw(" ")

    return screen.cursor.x
