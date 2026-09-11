# Deep Freeze 250 Club
#
# DESIGN. An honor roll, not a scoreboard: nobody's number matters once they
# are past 250, only that they got there. So the hero is the threshold itself
# -- "250" next to a snowflake wearing the medal -- and the members get their
# own frame, every name the same size, in the order they joined.
#
# Two frames, because a legible snowflake and seven legible names do not both
# fit in 64x32. Private apps are a single image, so the Worker in ../cloudflare
# alternates between the two PNGs this renders on each panel refresh.

ICE = "#8FD8FF"
INK = "#F4F7FF"
DIM = "#7C8AA5"
GOLD = "#FFC83D"
GOLD_DK = "#B8780A"
RIBBON = "#E0303A"

# 19x19, eight arms with a V of branches on each. Six arms is the true shape,
# but at this size the 30-degree diagonals break into loose pixels and stop
# reading as arms; eight clean 45s read as a snowflake from across the room.
FLAKE = """
.........W.........
.........W.........
.......W.W.W.......
...W.W..WWW..W.W...
....WW...W...WW....
...WWW...W...WWW...
......W..W..W......
..W....W.W.W....W..
...W....WWW....W...
WWWWWWWWWWWWWWWWWWW
...W....WWW....W...
..W....W.W.W....W..
......W..W..W......
...WWW...W...WWW...
....WW...W...WW....
...W.W..WWW..W.W...
.......W.W.W.......
.........W.........
.........W.........
"""
FLAKE_W = 19
FLAKE_H = 19

# 5x5 medal face; k is a black ring drawn around it so it lifts off the flake.
MEDAL = """
.kkkkk.
kkGGGkk
kGGYGGk
kGYYYGk
kGGYGGk
kkGGGkk
.kkkkk.
"""
MEDAL_LEGEND = {"G": GOLD, "Y": "#FFF3B0", "k": "#000000"}

FONT_H = {"10x16": 16, "8x12": 12, "5x7": 7, "4x5": 5, "picopixel": 5}

STRIP_H = 7


def _strip(c, label):
    c.rect(0, 0, c.width - 1, STRIP_H - 1, fill = ICE)
    c.text(label, c.width // 2, 1, font = "4x5", color = "black", align = "center")


def _flake_with_medal(c, x, y):
    """The flake wearing its medal: a red V of ribbon from the upper arms and
    a gold medal hanging below, podium style. A medal pinned to the flake's
    center was tried first and read as a gold button -- at 19 px the ribbon
    is what says "medal", so it gets to cover some of the flake."""
    c.sprite(FLAKE, x, y, color = ICE)
    # Two 2-px ribbon strips converging from the upper diagonals to the medal.
    for i in range(10):
        lx = x + 5 + (i * 3) // 10
        rx = x + 13 - (i * 3) // 10
        yy = y + 6 + i
        c.pixel(lx, yy, RIBBON)
        c.pixel(lx + 1, yy, RIBBON)
        c.pixel(rx, yy, RIBBON)
        c.pixel(rx - 1, yy, RIBBON)
    c.sprite(MEDAL, x + 6, y + 15, legend = MEDAL_LEGEND)
    return 22


def _hero(c, art):
    """Strip, flake with medal, and the threshold as the hero number."""
    c.fill("black")
    _strip(c, "DEEP FREEZE")
    tw = c.text_width("250", font = "10x16")
    x0 = (c.width - (FLAKE_W + 3 + tw)) // 2
    art(c, x0, STRIP_H + 1)
    tx = x0 + FLAKE_W + 3
    c.text("250", tx, STRIP_H + 2, font = "10x16", color = INK)
    c.text("CLUB", tx + tw // 2, 25, font = "5x7", color = ICE, align = "center")


# 5x5 flake for the members strip and the spare list slot.
TINY_FLAKE = """
W.W.W
.WWW.
WWWWW
.WWW.
W.W.W
"""

# The order people joined, which is the order they are listed.
MEMBERS = "ARIC, JORI, ANDREA, TRENT, ANDY, TALYNN, DANA"

# Two columns of four rows of 4x5. The longest names, ANDREA and TALYNN, are
# 29 px -- inside a 32 px column with a pixel to spare on each side. Row pitch
# is 6: five of glyph and the one-pixel gap the spacing rules require.
COL_W = 32
ROW_Y = [8, 14, 20, 26]
SLOTS = 8


def _fit(c, s, x, y, w, fonts, color, align = "left"):
    """Biggest font that fits `w`, then hard-clipped -- nothing in the drawing
    API clips, so an overflowing name would silently run into its neighbor."""
    pick = fonts[len(fonts) - 1]
    for f in fonts:
        if c.text_width(s, font = f) <= w:
            pick = f
            break
    t = s
    for _ in range(len(s)):
        if c.text_width(t, font = pick) <= w:
            break
        t = t[:len(t) - 1]
    c.text(t, x, y, font = pick, color = color, align = align)


def _members(ctx):
    raw = str(ctx.inputs.get("members", MEMBERS))
    out = []
    for n in raw.split(","):
        n = n.strip().upper()
        if n != "":
            out.append(n)
    return out


def club(c, ctx):
    _hero(c, _flake_with_medal)


def members(c, ctx):
    c.fill("black")
    label = "250 CLUB"
    c.rect(0, 0, c.width - 1, STRIP_H - 1, fill = ICE)
    c.text(label, c.width // 2, 1, font = "4x5", color = "black", align = "center")
    lw = c.text_width(label, font = "4x5")
    left = c.width // 2 - lw // 2
    c.sprite(TINY_FLAKE, left - 9, 1, color = "black")
    c.sprite(TINY_FLAKE, left + lw + 4, 1, color = "black")

    names = _members(ctx)
    # Eight slots. Seven members leave one over, which gets a flake rather
    # than a hole; past eight, the last slot counts who did not fit.
    shown = names
    extra = 0
    if len(names) > SLOTS:
        shown = names[:SLOTS - 1]
        extra = len(names) - len(shown)

    # Column-major, so the list reads down like a list.
    for i in range(SLOTS):
        col = i // len(ROW_Y)
        row = i % len(ROW_Y)
        cx = col * COL_W + COL_W // 2
        y = ROW_Y[row]
        if i < len(shown):
            _fit(c, shown[i], cx, y, COL_W - 2, ["4x5", "picopixel"], INK,
                 align = "center")
        elif extra > 0:
            _fit(c, "+" + str(extra) + " MORE", cx, y, COL_W - 2,
                 ["4x5", "picopixel"], DIM, align = "center")
            break
        else:
            c.sprite(TINY_FLAKE, cx - 2, y, color = ICE)
            break
