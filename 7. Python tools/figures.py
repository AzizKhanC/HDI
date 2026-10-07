"""Redraw the NHDR 2020 index figures and maps in the report's own style, with
the values reproduced from the survey microdata.

Each figure keeps the report's chart type, years, categories, colours and type
(Roboto Condensed, read from the report PDF), so that it can be laid beside
the published figure for a like-for-like comparison. A year the microdata on
disk cannot reproduce keeps its slot on the axis and is marked "n.a.".

Called by "Build outputs.py". On its own, from the package folder:
    python "7. Python tools/figures.py" "8. Stata runs/Run YYYYMMDD HHMMSS" "4. Plots/2. Figures reproduced NHDR style"

Inputs are the result tables the do file writes into the run folder.
"""
import sys
import textwrap
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import font_manager as fm
from matplotlib.patches import Circle, PathPatch, Polygon, Rectangle
from matplotlib.path import Path as MPath

ROOT = Path(__file__).resolve().parents[1]
FONTS = Path(__file__).resolve().parent / "Fonts"
for f in FONTS.glob("*.ttf"):
    fm.fontManager.addfont(str(f))


def _fam(stem):
    for f in FONTS.glob(stem + ".ttf"):
        return [fm.FontProperties(fname=str(f)).get_name(), "Arial"]
    return ["Arial"]


REG, LIGHT, BOLD = _fam("RobotoCondensed-Regular"), _fam("RobotoCondensed-Light"), _fam("RobotoCondensed-Bold")
ITAL, LITAL, TITLE = _fam("RobotoCondensed-Italic"), _fam("RobotoCondensed-LightItalic"), _fam("Roboto-Bold")

# The report's palette, read from the PDF drawings.
RED, ORANGE, BEIGE, GREY = "#EF4429", "#F36F25", "#F3E9E0", "#58595B"
NAVY, AMBER, TEAL, LTEAL = "#1F6288", "#F9A032", "#008E9E", "#00B0B7"
GREEN, GOLD, TAN, DTEAL = "#4D7942", "#EFB113", "#D5BEAB", "#077F8D"
COPPER, DORANGE = "#D1952A", "#E17F26"
PROV_COL = {"Balochistan": AMBER, "Khyber Pakhtunkhwa": ORANGE, "Punjab": NAVY, "Sindh": TEAL,
            "Pakistan": GREEN}
NA_COL = "#9A8F86"

plt.rcParams.update({"font.family": LIGHT, "font.size": 7, "axes.linewidth": 0.8,
                     "savefig.facecolor": "white", "figure.facecolor": "white"})

COL1, COL2, NARROW = 2.7, 4.52, 1.78    # column widths in inches, as in the report

# Each figure takes the size of its published crop (pixels at 110 dpi), so that one inch
# here is one inch of the report and the report's type sizes apply unchanged.
CROP = {"Figure 2.18": (299, 993), "Figure 2.19": (297, 364), "Figure 2.20": (497, 840),
        "Figure 3.6": (298, 670), "Figure 3.10": (298, 389), "Figure 3.13": (297, 337),
        "Figure 3.16": (300, 320), "Figure 3.19": (297, 323), "Figure 3.22": (600, 343),
        "Figure 3.23": (297, 637), "Figure 3.28": (298, 623), "Figure 4.1": (498, 616),
        "Figure 4.4": (297, 538), "Figure 4.5": (297, 903), "Figure 4.6": (498, 629),
        "Figure 4.7": (196, 945), "Figure 4.8": (298, 312), "Figure 4.12": (497, 493), "Figure 4.9": (300, 672), "Figure 4.10": (196, 868),
        "Figure 4.11": (297, 327), "Figure 4.13": (498, 504), "Figure 4.15": (200, 981),
        "Figure 5.19": (297, 711), "Map 4.1": (792, 745), "Map 4.2": (793, 708), "Map 4.3": (792, 733),
        "Map 4.4": (792, 756)}


def text_w(fig, s, family, size):
    """Width of a string in inches."""
    t = fig.text(0, 0, s, fontfamily=family, fontsize=size)
    w = t.get_window_extent(fig.canvas.get_renderer()).width / fig.dpi
    t.remove()
    return w


def wrap_to(fig, s, family, size, width):
    lines, cur = [], ""
    for word in s.split():
        test = (cur + " " + word).strip()
        if text_w(fig, test, family, size) <= width or not cur:
            cur = test
        else:
            lines.append(cur)
            cur = word
    return lines + ([cur] if cur else [])


# ---------------------------------------------------------------------------------------
# Frame: label, title, beige panels, source line
# ---------------------------------------------------------------------------------------
class Frame:
    def __init__(self, label, title, w, h, source):
        if label in CROP:
            w, h = CROP[label][0] / 110, CROP[label][1] / 110
        self.fig = plt.figure(figsize=(w, h))
        self.w, self.h = w, h
        f = self.fig
        kind, num = label.split()
        top = 1 - 0.07 / h
        k = kind.upper() + " "
        f.text(0.0, top, k, fontfamily=REG, fontsize=8, va="top")
        f.text(text_w(f, k, REG, 8) / w, top, num, fontfamily=BOLD, fontsize=8, va="top")
        y_rule = 1 - 0.25 / h
        f.add_artist(Rectangle((0, y_rule - 0.03 / h), 0.55 / w, 0.045 / h, transform=f.transFigure,
                               color=RED, lw=0))
        f.add_artist(Rectangle((0, y_rule), 1, 0.008 / h, transform=f.transFigure, color=RED, lw=0))
        y = 1 - 0.36 / h
        for ln in wrap_to(f, title, TITLE, 9, w - 0.05):
            f.text(0, y, ln, fontfamily=TITLE, fontsize=9, color=RED, va="top")
            y -= 0.155 / h
        self.top = y - 0.07 / h
        self.bottom = 0.0
        if source:
            lab = "Source: "
            first = w - text_w(f, lab, BOLD, 6.5) - 0.05
            words = source.split()
            l1 = wrap_to(f, source, LIGHT, 6.5, first)[0]
            rest = source[len(l1):].strip()
            sl = [l1] + (wrap_to(f, rest, LIGHT, 6.5, w - 0.05) if rest else [])
            ys = 0.04 / h + 0.115 / h * (len(sl) - 1)
            f.text(0, ys, lab, fontfamily=BOLD, fontsize=6.5, color=RED, va="bottom")
            f.text(text_w(f, lab, BOLD, 6.5) / w, ys, sl[0], fontfamily=LIGHT, fontsize=6.5, color=RED,
                   va="bottom")
            for ln in sl[1:]:
                ys -= 0.115 / h
                f.text(0, ys, ln, fontfamily=LIGHT, fontsize=6.5, color=RED, va="bottom")
            self.bottom = (0.04 + 0.115 * len(sl) + 0.07) / h

    def panel(self, y0, y1, x0=0.0, x1=1.0, pad=(0.42, 0.12, 0.38, 0.12)):
        """A beige panel between fractions y0 and y1 of the free area; returns axes inside.
        pad = (left, right, bottom, top) in inches."""
        f = self.fig
        span = self.top - self.bottom
        b = self.bottom + y0 * span
        t = self.bottom + y1 * span
        f.add_artist(Rectangle((x0, b), x1 - x0, t - b - 0.03 / self.h, transform=f.transFigure,
                               color=BEIGE, lw=0, zorder=0))
        l, r, bb, tt = pad
        ax = f.add_axes([x0 + l / self.w, b + bb / self.h, (x1 - x0) - (l + r) / self.w,
                         (t - b) - (bb + tt) / self.h - 0.03 / self.h])
        ax.set_facecolor("none")
        for s in ax.spines.values():
            s.set_visible(False)
        ax.tick_params(length=0, labelsize=6.5, pad=2)
        for lab in ax.get_xticklabels() + ax.get_yticklabels():
            lab.set_fontfamily(LIGHT)
        return ax

    def save(self, path):
        self.fig.savefig(path, dpi=300)
        plt.close(self.fig)


def grid_y(ax, ticks, fmt="{:.3f}", zero_line=True, label=None):
    ax.set_yticks(ticks)
    ax.set_yticklabels([("0" if t == 0 else fmt.format(t)) for t in ticks], fontfamily=LIGHT, fontsize=6.5)
    for t in ticks:
        if t != 0 or not zero_line:
            ax.axhline(t, color=TAN, lw=0.5, zorder=0.5)
    if zero_line:
        ax.axhline(ticks[0], color="black", lw=1.1, zorder=3)
    if label:
        ax.text(0, 1.02, label, transform=ax.transAxes, fontfamily=LITAL, fontsize=6.5, ha="right",
                va="bottom")


def axis_break(ax, y, x=-0.045):
    ax.text(x, y, "//", transform=ax.get_yaxis_transform(), fontsize=7, rotation=-15, ha="center",
            va="center", color=GREY)


def na(ax, x, y=None, rot=0, size=6, transform=None):
    tr = transform or ax.get_xaxis_transform()
    ax.text(x, 0.04 if y is None else y, "n.a.", transform=tr, ha="center", va="bottom", fontsize=size,
            fontfamily=ITAL, color=NA_COL, rotation=rot)


def dot(ax, x, y, text, fc, r_pts=11, tc="white", fs=6.2, ec="none"):
    ax.scatter([x], [y], s=r_pts ** 2, color=fc, zorder=5, edgecolors=ec, linewidths=0.8)
    ax.text(x, y, text, ha="center", va="center", color=tc, fontsize=fs, fontfamily=REG, zorder=6)


def f3(v):
    return f"{v:.3f}"


# ---------------------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------------------
class Data:
    def __init__(self, run):
        r = Path(run)
        self.H = pd.read_csv(r / "HDI all microdata.csv")
        self.I = pd.read_csv(r / "IHDI all microdata.csv")
        self.L = pd.read_csv(r / "LDI 2012-13 2017-18 2024-25.csv")
        self.Y = pd.read_csv(r / "YDI 2017-18 2024-25.csv")
        self.G = pd.read_csv(r / "GDI reproduced 2018-19 2024-25.csv")
        self.GII06 = pd.read_csv(r / "GII 2006-07 reproduced.csv")
        self.GII18 = pd.read_csv(r / "GII 2018-19 all microdata.csv")
        self.C = pd.read_csv(r / "CDI reproduced PDHS.csv")
        self.F519 = pd.read_csv(r / "Figure 5.19 data.csv")
        self.geo = pd.read_csv(ROOT / "6. Raw data" / "Geo" / "Pak ADM1 geoBoundaries coordinates.csv")
        self.S = pd.read_csv(r / "Series HDI Pakistan.csv")
        self.SG = pd.read_csv(r / "Series GDI Pakistan.csv")
        self.SI = pd.read_csv(r / "Series GII Pakistan.csv")
        self.W = pd.read_csv(r / "WEF GGGI Pakistan.csv")
        self.PM = pd.read_csv(r / "YDI survival PMMS 2019.csv").set_index("region").survival_pmms

    def ser(self, year, col, q="All"):
        d = self.S[(self.S.year == year) & (self.S.quintile == q)]
        return float(d[col].iloc[0])

    def gdi(self, year, sex, col):
        d = self.SG[(self.SG.year == year) & (self.SG.sex == sex)]
        return float(d[col].iloc[0])

    def gii(self, year):
        return float(self.SI[self.SI.year == year].s_gii.iloc[0])

    def isurv(self, region):
        """Youth survival index from PMMS 2019 (goalposts 0.9970 to 0.9999)."""
        return (float(self.PM[region]) - 0.9970) / (0.9999 - 0.9970)

    def ydi_pmms(self, region):
        """The 2017-18 YDI with PMMS 2019 survival in place of the printed value."""
        return (sum(self.ydi(region, c) for c in ["r_i_mys", "r_i_epr", "r_i_hied", "r_i_full"])
                + self.isurv(region)) / 5

    def hdi(self, year, dom, q="All", col="hdi_ehi"):
        d = self.H[(self.H.year == year) & (self.H.domain == dom) & (self.H.quintile == q)]
        return float(d[col].iloc[0])

    def ihdi(self, year, dom, col):
        d = self.I[(self.I.year == year) & (self.I.domain == dom)]
        return float(d[col].iloc[0])

    def ldi(self, region, year, col):
        d = self.L[(self.L.region == region) & (self.L.year == year)]
        return float(d[col].iloc[0])

    def ydi(self, region, col, year="2017-18"):
        d = self.Y[(self.Y.region == region) & (self.Y.year == year)]
        return float(d[col].iloc[0])


YEARS_HDI = ["2006-07", "2012-13", "2015-16", "2018-19"]
YEARS4 = ["2006-07", "2012-13", "2015-16", "2018-19"]
XPOS_HDI = [0, 6, 9, 12]


# ---------------------------------------------------------------------------------------
# Chapter 2
# ---------------------------------------------------------------------------------------
def fig_2_18(D, out):
    F = Frame("Figure 2.18", "HDI and IHDI, and the loss in human development due to inequality, (2006-2019)",
              COL1, 10.9, "Reproduced from HIES 2005-06, 2011-12, 2015-16 and 2018-19, PDHS 2006-07, 2012-13 "
              "and 2017-18 microdata, and WDI GNI per head (PPP).")
    ax = F.panel(0.40, 1.0, pad=(0.45, 0.1, 0.55, 0.3))
    xs = [0, 2.4, 3.3, 4.2]
    for x, yr in zip(xs, YEARS4):
        h, i = D.ser(yr, "s_hdi"), D.ser(yr, "ihdi")
        ax.bar(x - 0.17, h, 0.3, color=ORANGE, zorder=2)
        ax.bar(x + 0.17, i, 0.3, color=GREY, zorder=2)
        ax.text(x - 0.17, h + 0.008, f3(h), ha="center", va="bottom", fontsize=5.8, fontfamily=REG, rotation=90)
        ax.text(x + 0.17, i + 0.008, f3(i), ha="center", va="bottom", fontsize=5.8, fontfamily=REG, rotation=90)
    ax.text(xs[0] - 0.3, D.ser("2006-07", "s_hdi") + 0.06, "HDI", fontsize=6.5, fontfamily=LIGHT)
    ax.text(xs[0] + 0.05, D.ser("2006-07", "ihdi") + 0.06, "IHDI", fontsize=6.5, fontfamily=LIGHT)
    ax.set_xlim(-0.6, 4.75)
    ax.set_ylim(0, 0.62)
    grid_y(ax, [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6], label="HDI/IHDI")
    ax.set_xticks(xs)
    ax.set_xticklabels(YEARS4, rotation=90, fontfamily=BOLD, fontsize=6.5)
    ax2 = F.panel(0.0, 0.385, pad=(0.45, 0.1, 0.55, 0.25))
    vs = [D.ser(yr, "loss") for yr in YEARS4]
    ax2.plot(xs, vs, color="black", lw=1.6, zorder=3)
    for x, v in zip(xs, vs):
        dot(ax2, x, v, f"{v:.1f}", "black", r_pts=15, fs=6.5)
    ax2.text(0.05, 7.62, "Loss in Human Development", fontsize=6.5, fontfamily=LIGHT)
    ax2.set_xlim(-0.6, 4.75)
    ax2.set_ylim(5.4, 8.2)
    ax2.set_yticks([5.4, 6, 7, 8])
    ax2.set_yticklabels(["0", "6", "7", "8"], fontsize=6.5)
    for t in [6, 7, 8]:
        ax2.axhline(t, color=TAN, lw=0.5, zorder=0.5)
    ax2.axhline(5.4, color="black", lw=1.1)
    axis_break(ax2, 5.7)
    ax2.text(0, 1.02, "%", transform=ax2.transAxes, fontfamily=LITAL, fontsize=6.5, ha="right")
    ax2.set_xticks(xs)
    ax2.set_xticklabels(YEARS4, rotation=90, fontfamily=BOLD, fontsize=6.5)
    F.save(out / "Figure 2.18.png")


def fig_2_19(D, out):
    F = Frame("Figure 2.19", "Contribution of each dimension to the loss in human development, (2018-2019)",
              COL1, 4.05, "Reproduced from HIES 2018-19 and PDHS 2017-18 microdata.")
    ax = F.panel(0.0, 1.0, pad=(0.1, 0.1, 0.1, 0.1))
    a = {k: D.ihdi("2018-19", "Pakistan", c) for k, c in
         [("Income", "a_inc_m"), ("Education", "a_edu_m"), ("Health", "a_health_m")]}
    tot = sum(a.values())
    sh = {k: 100 * v / tot for k, v in a.items()}
    cols = {"Income": DORANGE, "Education": "#007B7B", "Health": GOLD}
    order = ["Education", "Health", "Income"]
    vals = [sh[k] for k in order]
    ax.pie(vals, colors=[cols[k] for k in order], startangle=90, counterclock=False,
           wedgeprops=dict(width=0.36, edgecolor="none"), radius=1.0)
    ax.set_aspect("equal")
    ax.text(1.0, 0.72, f"Education\n", fontsize=6.8, fontfamily=LIGHT, ha="left")
    ax.text(1.0, 0.70, f"{sh['Education']:.0f}%", fontsize=6.8, fontfamily=BOLD, color="#007B7B", ha="left",
            va="top")
    ax.text(1.12, 0.1, "Health\n", fontsize=6.8, fontfamily=LIGHT, ha="left")
    ax.text(1.12, 0.08, f"{sh['Health']:.0f}%", fontsize=6.8, fontfamily=BOLD, color=GOLD, ha="left", va="top")
    ax.text(-1.05, 0.72, "Income\n", fontsize=6.8, fontfamily=LIGHT, ha="right")
    ax.text(-1.05, 0.70, f"{sh['Income']:.0f}%", fontsize=6.8, fontfamily=BOLD, color=DORANGE, ha="right",
            va="top")
    ax.set_xlim(-1.6, 1.6)
    ax.set_ylim(-1.15, 1.15)
    F.save(out / "Figure 2.19.png")


def fig_2_20(D, out):
    F = Frame("Figure 2.20", "HDI by quintiles at the national level and by inequality measures, (2006-2019)",
              COL2, 9.3, "Reproduced from HIES 2005-06, 2011-12, 2015-16 and 2018-19, PDHS 2006-07, 2012-13 "
              "and 2017-18 microdata, and WDI GNI per head (PPP).")
    xmap = dict(zip(YEARS_HDI, XPOS_HDI))
    xs = [xmap[y] for y in YEARS4]
    ax = F.panel(0.42, 1.0, pad=(0.45, 1.05, 0.35, 0.25))
    for q in ["Q1", "Q2", "Q3", "Q4", "Q5", "All"]:
        ys = [D.ser(y, "s_hdi", q) for y in YEARS4]
        c = GREEN if q == "All" else GREY
        ax.plot(xs, ys, color=c if q == "All" else "#3A3A3A", lw=1.6 if q == "All" else 0.8, zorder=3)
        for x, v in zip(xs, ys):
            dot(ax, x, v, f3(v), c, r_pts=16, fs=6.0)
        lab = "Pakistan" if q == "All" else "Quintile " + q[1]
        ax.text(xmap["2018-19"] + 0.75, ys[-1], lab, va="center", fontsize=7,
                fontfamily=BOLD if q == "All" else LIGHT, color=GREEN if q == "All" else "black")
    ax.set_xlim(-0.8, 12.8)
    ax.set_ylim(0.27, 0.73)
    ax.set_yticks([0.27, 0.3, 0.4, 0.5, 0.6, 0.7])
    ax.set_yticklabels(["0", "0.3", "0.4", "0.5", "0.6", "0.7"], fontsize=6.5)
    for t in [0.3, 0.4, 0.5, 0.6, 0.7]:
        ax.axhline(t, color=TAN, lw=0.5, zorder=0.5)
    ax.axhline(0.27, color="black", lw=1.1)
    axis_break(ax, 0.285)
    ax.text(0, 1.02, "HDI", transform=ax.transAxes, fontfamily=LITAL, fontsize=6.5, ha="right")
    ax.set_xticks(XPOS_HDI)
    ax.set_xticklabels(YEARS_HDI, fontfamily=BOLD, fontsize=6.5)

    def ratio_panel(y0, y1, name, col_name, col, ylim, yt, ylab):
        a = F.panel(y0, y1, pad=(0.45, 1.05, 0.3, 0.3))
        vs = [D.ser(y, col_name) for y in YEARS4]
        a.plot(xs, vs, color=col, lw=1.5, zorder=3)
        for x, v in zip(xs, vs):
            dot(a, x, v, f"{v:.2f}", col, r_pts=14, fs=6.0)
        a.text(1.0, 1.05, name, transform=a.transAxes, ha="right", fontfamily=BOLD, fontsize=7)
        a.set_xlim(-0.8, 12.8)
        a.set_ylim(*ylim)
        a.set_yticks(yt)
        a.set_yticklabels(ylab, fontsize=6.5)
        for t in yt[1:]:
            a.axhline(t, color=TAN, lw=0.5, zorder=0.5)
        a.axhline(yt[0], color="black", lw=1.1)
        a.set_xticks(XPOS_HDI)
        a.set_xticklabels(YEARS_HDI, fontfamily=BOLD, fontsize=6.5)
        return a

    a1 = ratio_panel(0.21, 0.41, "Modified Palma ratio", "palma", RED, (1.4, 1.9), [1.4, 1.6, 1.8],
                     ["0", "1.6", "1.8"])
    axis_break(a1, 1.5)
    ratio_panel(0.0, 0.20, "Pashum ratio", "pashum", LTEAL, (0, 0.25), [0, 0.2], ["0", "0.2"])
    F.save(out / "Figure 2.20.png")


# ---------------------------------------------------------------------------------------
# Chapter 3
# ---------------------------------------------------------------------------------------
PROVS = ["Balochistan", "Khyber Pakhtunkhwa", "Punjab", "Sindh"]
PLAB = ["Balochistan", "Khyber\nPakhtunkhwa", "Punjab", "Sindh"]


def gradient_bar(ax, x, color, width=0.32, peak=0.55, spread=0.32):
    from matplotlib.colors import to_rgb
    n = 256
    y = np.linspace(0, 1, n)
    alpha = 0.10 + 0.85 * np.exp(-((y - peak) / spread) ** 2)
    alpha = np.minimum(alpha, 0.95) * np.clip(1 - y ** 6, 0, 1) * np.clip(y * 6, 0, 1) + 0.03
    img = np.zeros((n, 1, 4))
    img[:, 0, :3] = to_rgb(color)
    img[:, 0, 3] = alpha
    ax.imshow(img, extent=[x - width / 2, x + width / 2, 0, 1], origin="lower", aspect="auto", zorder=1)
    for t in np.arange(0.1, 1.0, 0.1):
        ax.plot([x - width / 2, x + width / 2], [t, t], color="white", lw=0.35, alpha=0.6, zorder=1.5)


def tick_mark(ax, x, v, ls="-", width=0.32, label=True, dx=0.2, lw=1.8, fs=6.3):
    ax.plot([x - width / 2, x + width / 2], [v, v], color="black", lw=lw, ls=ls, zorder=4,
            solid_capstyle="butt")
    if label:
        ax.text(x + dx, v, f3(v), va="center", fontsize=fs, fontfamily=LIGHT)


def bars_axes(ax, n):
    ax.set_xlim(-0.5, n - 0.5)
    ax.set_ylim(0, 1.0)
    t = np.round(np.arange(0, 1.01, 0.1), 1)
    ax.set_yticks(t)
    ax.set_yticklabels(["0"] + [f"{v:.3f}" for v in t[1:]], fontsize=6.3)
    ax.text(0, 1.02, "HDI", transform=ax.transAxes, fontfamily=LITAL, fontsize=6.5, ha="right")
    ax.set_xticks(range(n))


def fig_3_6(D, out):
    F = Frame("Figure 3.6", "Provincial Human Development Index, (2018-2019)", COL1, 7.45,
              "Reproduced from HIES 2018-19 and PDHS 2017-18 microdata.")
    ax = F.panel(0.0, 1.0, pad=(0.45, 0.1, 0.45, 0.3))
    for k, p in enumerate(PROVS):
        gradient_bar(ax, k, PROV_COL[p])
        tick_mark(ax, k, D.hdi("2018-19", p))
    bars_axes(ax, 4)
    ax.set_xticklabels(PLAB, fontsize=6.5)
    F.save(out / "Figure 3.6.png")


def petal(ax, ang, r, col, w=0.085):
    th = np.deg2rad(ang)
    tip = np.array([r * np.cos(th), r * np.sin(th)])
    nrm = np.array([-np.sin(th), np.cos(th)])
    mid = tip * 0.55
    c1, c2 = mid + nrm * w * r / 0.5, mid - nrm * w * r / 0.5
    verts = [(0, 0), tuple(c1), tuple(tip), tuple(c2), (0, 0)]
    codes = [MPath.MOVETO, MPath.CURVE3, MPath.LINETO, MPath.CURVE3, MPath.LINETO]
    path = MPath([(0, 0), tuple(c1), tuple(tip), tuple(c2), (0, 0)],
                 [MPath.MOVETO, MPath.CURVE3, MPath.CURVE3, MPath.CURVE3, MPath.CURVE3])
    ax.add_patch(PathPatch(path, facecolor=col, edgecolor="none", zorder=3))


def petal_at(ax, x0, y0, ang, r, col):
    th = np.deg2rad(ang)
    tip = np.array([x0 + r * np.cos(th), y0 + r * np.sin(th)])
    nrm = np.array([-np.sin(th), np.cos(th)])
    mid = (np.array([x0, y0]) + tip) / 2
    c1, c2 = mid + nrm * r * 0.35, mid - nrm * r * 0.35
    ax.add_patch(PathPatch(MPath([(x0, y0), tuple(c1), tuple(tip), tuple(c2), (x0, y0)],
                                 [MPath.MOVETO, MPath.CURVE3, MPath.CURVE3, MPath.CURVE3, MPath.CURVE3]),
                           facecolor=col, edgecolor="none", zorder=3))


Q_COL = ["#00A6A6", "#2D6A8E", "#0B3C5D", ORANGE, RED]


def fig_petal(D, out, num, prov, title):
    F = Frame(f"Figure {num}", title, COL1, 4.35, "Reproduced from HIES 2018-19 and PDHS 2017-18 microdata.")
    ax = F.panel(0.0, 1.0, pad=(0.1, 0.1, 0.1, 0.1))
    vals = [D.hdi("2018-19", prov, f"Q{k}") for k in range(1, 6)]
    rmax = 0.8 if max(vals) > 0.7 else 0.7
    rings = np.round(np.arange(0.3, rmax + 0.001, 0.1), 1)
    th = np.linspace(0, np.pi, 200)
    for r in rings:
        ax.plot(r * np.cos(th), r * np.sin(th), ls=(0, (1, 2)), color="black", lw=0.6, zorder=1)
        ax.plot([-r, -r], [0, -0.03], color="black", lw=0.6)
        ax.plot([r, r], [0, -0.03], color="black", lw=0.6)
        ax.text(-r - 0.02, 0.06, f"{r:.1f}", rotation=70, fontsize=6.3, ha="right", va="bottom")
    angles = [158, 124, 90, 57, 24]
    for k, (a, v) in enumerate(zip(angles, vals)):
        petal(ax, a, v, Q_COL[k])
        thr = np.deg2rad(a)
        rr = v * 0.62
        rot = a if a <= 90 else a - 180
        ax.text(rr * np.cos(thr), rr * np.sin(thr), f3(v), rotation=rot, color="white", fontsize=6.3,
                fontfamily=REG, ha="center", va="center", zorder=5, rotation_mode="anchor")
    ax.add_patch(Circle((0, 0), 0.012, color="black", zorder=6))
    ax.text(-0.22, -0.08, "HDI", fontfamily=LITAL, fontsize=6.5)
    lx = -0.42
    for k in range(5):
        x = lx + k * 0.2
        petal_at(ax, x, rmax + 0.17, 40, 0.06, Q_COL[k])
        ax.text(x + 0.06, rmax + 0.2, f"Q{k+1}", fontsize=6.8, va="center")
    ax.text(lx - 0.02, rmax + 0.1, "Poorest", fontsize=6.8)
    ax.text(lx + 0.8, rmax + 0.1, "Richest", fontsize=6.8)
    ax.set_xlim(-rmax - 0.15, rmax + 0.15)
    ax.set_ylim(-0.15, rmax + 0.28)
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    F.save(out / f"Figure {num}.png")


def fig_3_22(D, out):
    F = Frame("Figure 3.22", "Ratio of the top to the bottom quintile by dimension of the HDI, (2018-2019)",
              COL2, 3.15, "Reproduced from HIES 2018-19 and PDHS 2017-18 microdata.")
    ax = F.panel(0.0, 1.0, pad=(0.4, 0.15, 0.4, 0.15))
    fam = {"Balochistan": ["#FEC131", AMBER, "#F9A032"], "Khyber Pakhtunkhwa": ["#EF886E", "#EC7D30", ORANGE],
           "Punjab": ["#689EBC", "#4D87A8", NAVY], "Sindh": [LTEAL, TEAL, DTEAL],
           "Pakistan": ["#6F9C63", "#638C58", GREEN]}
    doms = PROVS + ["Pakistan"]
    for k, d in enumerate(doms):
        for j, (c, lab) in enumerate([("m_education_index", "Education"), ("m_health_index", "Health"),
                                      ("m_income_index", "Income")]):
            v = D.hdi("2018-19", d, "Q5", c) / D.hdi("2018-19", d, "Q1", c)
            x = k * 1.1 + (j - 1) * 0.17
            ax.bar(x, v, 0.15, color=fam[d][j], zorder=2)
            if k == 0:
                ax.text(x, v + 0.08, lab, rotation=90, ha="center", va="bottom", fontsize=6.5, fontfamily=BOLD)
    ax.set_ylim(0, 3.6)
    grid_y(ax, [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5], fmt="{:g}", label="Ratio")
    ax.set_xticks([k * 1.1 for k in range(5)])
    ax.set_xticklabels(["Balochistan", "Khyber\nPakhtunkhwa", "Punjab", "Sindh", "Pakistan"],
                       fontfamily=BOLD, fontsize=6.8)
    ax.set_xlim(-0.45, 4.85)
    F.save(out / "Figure 3.22.png")


def two_tick_bars(D, out, num, title, h, pairs, legend):
    F = Frame(f"Figure {num}", title, COL1, h, "Reproduced from HIES 2018-19 and PDHS 2017-18 microdata.")
    ax = F.panel(0.0, 1.0, pad=(0.45, 0.1, 0.45, 0.35))
    for k, p in enumerate(PROVS):
        gradient_bar(ax, k, PROV_COL[p])
        a, b = pairs(p)
        tick_mark(ax, k, a)
        tick_mark(ax, k, b, ls=(0, (1, 1)), lw=1.2)
    bars_axes(ax, 4)
    ax.set_xticklabels(PLAB, fontsize=6.5, fontfamily=BOLD)
    ax.plot([0.55, 0.62], [1.045, 1.045], transform=ax.transAxes, color="black", lw=1.8, clip_on=False)
    ax.text(0.64, 1.045, legend[0], transform=ax.transAxes, va="center", fontsize=6.3)
    ax.plot([0.8, 0.87], [1.045, 1.045], transform=ax.transAxes, color="black", lw=1.1, ls=(0, (1, 1)),
            clip_on=False)
    ax.text(0.89, 1.045, legend[1], transform=ax.transAxes, va="center", fontsize=6.3)
    F.save(out / f"Figure {num}.png")


def fig_3_23(D, out):
    two_tick_bars(D, out, "3.23", "Loss of human development due to inequality: HDI and IHDI by province, "
                  "(2018-2019)", 7.1,
                  lambda p: (D.hdi("2018-19", p), D.ihdi("2018-19", p, "ihdi_m")), ("HDI", "IHDI"))


def fig_3_28(D, out):
    two_tick_bars(D, out, "3.28", "Rural and urban HDIs by province, (2018-2019)", 6.95,
                  lambda p: (D.hdi("2018-19", p + "-Urban"), D.hdi("2018-19", p + "-Rural")),
                  ("Urban HDI", "Rural HDI"))


# ---------------------------------------------------------------------------------------
# Chapter 4
# ---------------------------------------------------------------------------------------
YEARS_YDI = ["2001-02", "2007-08", "2012-13", "2017-18"]


def band_axes(ax, xs, labels, ylim=(0, 1.0), ylab="HDI"):
    for x in xs:
        ax.add_patch(Rectangle((x - 0.18, ylim[0]), 0.36, ylim[1] - ylim[0], color=TAN, alpha=0.75, lw=0,
                               zorder=0.6))
    ax.set_xticks(xs)
    ax.set_xticklabels(labels, fontfamily=BOLD, fontsize=6.5)


def fig_4_1(D, out):
    F = Frame("Figure 4.1", "Trends in the national Youth Development Index and its sub-indices, (2001-2018)",
              COL2, 6.9, "Reproduced from LFS 2012-13 and 2017-18, and PMMS 2019 microdata.")
    ax = F.panel(0.0, 1.0, pad=(0.45, 1.6, 0.35, 0.25))
    xs = [0, 1, 2, 3]
    band_axes(ax, xs, YEARS_YDI)
    for k in range(2):
        na(ax, xs[k], y=0.03, transform=ax.transData)
    series = [("ydi", "Youth Development Index", ORANGE, "-", 1.4),
              ("surv", "Youth Survival Index", "black", "-", 1.0),
              ("r_i_mys", "Years of schooling of youth", "black", "-", 1.8),
              ("r_i_hied", "% of enrolled youth in higher education", "black", (0, (2, 1.5)), 1.0),
              ("r_i_epr", "Youth employment-to-population ratio", "black", "-", 0.6),
              ("r_i_full", "% of fully employed youth", "black", (0, (2.5, 1.2)), 2.0)]
    end = []
    for c, lab, col, ls, lw in series:
        if c == "ydi":
            v17 = D.ydi_pmms("Pakistan")
            ax.plot([2.82, 3.18], [v17, v17], color=col, lw=lw + 0.6, zorder=4)
        elif c == "surv":
            v17 = D.isurv("Pakistan")
            ax.plot([2.82, 3.18], [v17, v17], color=col, lw=lw + 0.6, zorder=4)
        else:
            v12, v17 = D.ydi("Pakistan", c, "2012-13"), D.ydi("Pakistan", c)
            ax.plot([2, 3], [v12, v17], color=col, ls=ls, lw=lw, zorder=4)
        end.append((v17, lab, col))
    ax.text(2, 0.03, "YDI and survival n.a.", ha="center", va="bottom", fontsize=5.5, fontfamily=ITAL,
            color=NA_COL, rotation=90)
    ylab_pos = []
    for v, lab, col in sorted(end, reverse=True):
        yl = v
        while any(abs(yl - p) < 0.028 for p in ylab_pos):
            yl -= 0.028
        ylab_pos.append(yl)
        ax.plot([3.2, 3.32], [v, yl], color="#777", lw=0.5)
        ax.text(3.35, yl, f"{lab} {v:.3f}", va="center", fontsize=6.3, color=ORANGE if col == ORANGE else "black")
    ax.set_xlim(-0.4, 3.3)
    ax.set_ylim(0, 1.0)
    t = np.round(np.arange(0, 1.01, 0.1), 1)
    ax.set_yticks(t)
    ax.set_yticklabels(["0"] + [f"{v:.3f}" for v in t[1:]], fontsize=6.3)
    ax.text(0, 1.02, "HDI", transform=ax.transAxes, fontfamily=LITAL, fontsize=6.5, ha="right")
    F.save(out / "Figure 4.1.png")


def fig_4_4(D, out):
    F = Frame("Figure 4.4", "Labour Development Index, normal and including decent work, (2012-2018)", COL1, 6.0,
              "Reproduced from LFS 2012-13, 2014-15 and 2017-18 microdata, with WDI GDP.")
    ax = F.panel(0.0, 1.0, pad=(0.42, 0.15, 0.35, 0.2))
    yrs = ["2012-13", "2014-15", "2017-18"]
    xs = [0, 2, 5]
    for col, lab, c, dy in [("r_ldin", "LDI Normal", NAVY, -0.004), ("r_ldidw", "LDI including decent work", ORANGE,
                                                                     0.0028)]:
        v = [D.ldi("Pakistan", y, col) for y in yrs]
        ax.plot(xs, v, color=c, lw=1.0)
        ax.scatter(xs, v, color=c, s=10, zorder=4)
        for x, vv in zip(xs, v):
            ax.text(x, vv + (0.0016 if c == ORANGE else -0.0022), f3(vv), fontsize=6, ha="center", color=c,
                    va="bottom" if c == ORANGE else "top")
        ax.text(3.5, np.interp(3.5, xs, v) + dy, lab, fontfamily=BOLD, fontsize=6.5, ha="center", va="center")
    ax.set_ylim(0.374, 0.452)
    ax.set_yticks([0.374, 0.38, 0.39, 0.40, 0.41, 0.42, 0.43, 0.44, 0.45])
    ax.set_yticklabels(["0", "0.38", "0.39", "0.40", "0.41", "0.42", "0.43", "0.44", "0.45"], fontsize=6.3)
    for t in [0.38, 0.39, 0.40, 0.41, 0.42, 0.43, 0.44, 0.45]:
        ax.axhline(t, color=TAN, lw=0.5, zorder=0.5)
    ax.axhline(0.374, color="black", lw=1.1)
    axis_break(ax, 0.377)
    ax.set_xticks(xs)
    ax.set_xticklabels(yrs, fontfamily=BOLD, fontsize=6.5)
    ax.set_xlim(-0.3, 5.3)
    F.save(out / "Figure 4.4.png")


LDI_DIMS = [("epr", "Employment to population", RED), ("skillprem", "Skill premium", ORANGE),
            ("lshare", "Share of labour income", COPPER), ("humcap", "Human capital", NAVY),
            ("decentwork", "Incidence of decent work", LTEAL)]


def fig_4_5(D, out):
    F = Frame("Figure 4.5", "Changes in the dimensions of the national Labour Development Index, (2012-2018)",
              COL1, 10.1, "Reproduced from LFS 2012-13 and 2017-18 microdata, with WDI GDP.")
    ax = F.panel(0.0, 1.0, pad=(0.42, 0.15, 0.2, 1.05))
    for k, (c, lab, col) in enumerate(LDI_DIMS):
        a, b = D.ldi("Pakistan", "2012-13", c), D.ldi("Pakistan", "2017-18", c)
        v = 100 * (b - a) / a
        ax.bar(k, v, 0.55, color=col, zorder=2)
        ax.text(k, v + (0.4 if v >= 0 else -0.4), f"{v:.0f}%", ha="center", va="bottom" if v >= 0 else "top",
                fontsize=6.3)
    y1 = ax.get_position().y1
    for k, (c, lab, col) in enumerate(LDI_DIMS):
        yy = y1 + (0.95 - 0.16 * k) / F.h
        F.fig.add_artist(Rectangle((0.03, yy - 0.035 / F.h), 0.08 / F.w, 0.08 / F.h, transform=F.fig.transFigure,
                                   color=col, lw=0))
        F.fig.text(0.03 + 0.13 / F.w, yy, lab, fontsize=6.5, va="center")
    ax.set_ylim(-11, 31)
    grid_y(ax, [-10, -5, 0, 5, 10, 15, 20, 25, 30], fmt="{:g}", zero_line=False, label="%")
    ax.axhline(0, color="black", lw=1.0)
    ax.set_xticks([])
    ax.set_xlim(-0.6, 4.6)
    F.save(out / "Figure 4.5.png")


def fig_4_6(D, out):
    F = Frame("Figure 4.6", "Provincial Labour Development Index rankings by indicator values, (2017-2018)", COL2,
              7.0, "Reproduced from LFS 2017-18 microdata, with WDI GDP and Pasha's provincial shares.")
    ax = F.panel(0.0, 1.0, pad=(0.45, 0.9, 0.2, 0.75))
    cols = [("r_i_ep", "Employment\nto population\nratio"), ("r_i_ls", "Share of\nlabour income\nin GDP"),
            ("r_i_sp", "Skill\npremium"), ("r_i_hc", "Human\ncapital"), ("r_i_dw", "Incidence of\ndecent work")]
    pc = {"Balochistan": GOLD, "Khyber Pakhtunkhwa": DORANGE, "Sindh": TEAL, "Punjab": NAVY}
    ranks = {}
    for j, (c, lab) in enumerate(cols):
        v = {p: D.ldi(p, "2017-18", c) for p in PROVS}
        order = sorted(PROVS, key=lambda p: -v[p])
        for r, p in enumerate(order):
            ranks.setdefault(p, []).append(r + 1)
        ax.add_patch(Rectangle((j - 0.13, 0.8), 0.26, 3.4, color=TAN, alpha=0.8, lw=0, zorder=0.5))
        for k in range(20):
            ax.add_patch(Rectangle((j - 0.13, 4.2 + k * 0.04), 0.26, 0.04, color=TAN, alpha=0.8 * (1 - k / 20),
                                   lw=0, zorder=0.5))
        ax.text(j, 0.45, lab, ha="center", va="bottom", fontsize=6.3)
    for p, rk in ranks.items():
        xs, ys = [], []
        for j, r in enumerate(rk):
            xs += [j - 0.13, j + 0.13]
            ys += [r, r]
        ax.plot(xs, ys, color=pc[p], lw=1.3, zorder=3)
        ax.text(4.25, rk[-1], p.replace(" P", "\nP"), va="center", fontsize=6.3)
    ax.set_ylim(5.2, 0.4)
    ax.set_xlim(-0.4, 4.2)
    ax.set_yticks([1, 2, 3, 4, 5])
    ax.set_yticklabels(["1", "2", "3", "4", "5"], fontsize=6.3)
    ax.text(-0.42, 0.75, "LDI\nRanking", fontfamily=LITAL, fontsize=6.3, ha="right", va="center")
    ax.set_xticks([])
    F.save(out / "Figure 4.6.png")


def fig_4_7(D, out):
    F = Frame("Figure 4.7", "Gender wage ratios, (2012-2018)", NARROW, 10.5,
              "Reproduced from LFS 2012-13, 2014-15 and 2017-18 microdata.")
    doms = [("Punjab", NAVY), ("Sindh", TEAL), ("Khyber Pakhtunkhwa", DORANGE), ("Balochistan", GOLD),
            ("Pakistan", GREEN)]
    yrs, xs = ["2012-13", "2014-15", "2017-18"], [0, 2, 5]
    n = len(doms)
    for k, (d, col) in enumerate(doms):
        ax = F.panel(1 - (k + 1) / n + 0.01, 1 - k / n, pad=(0.32, 0.15, 0.25, 0.22))
        v = [D.ldi(d, y, "wr") for y in yrs]
        top = 1.2 if max(v) > 0.95 else 0.8
        ax.add_patch(Rectangle((0, 0), 5, top, color=col, lw=0, zorder=1))
        ax.plot(xs, v, color="white", lw=1.1, zorder=3)
        ax.scatter(xs, v, color="white", s=6, zorder=4)
        for x, vv in zip(xs, v):
            ax.text(x + (0.12 if x == 0 else (-0.12 if x == 5 else 0)), vv + 0.04, f"{vv:.2f}", color="white",
                    fontsize=5.8, ha="left" if x == 0 else ("right" if x == 5 else "center"), zorder=5)
        ax.set_xlim(0, 5)
        ax.set_ylim(0, top)
        tk = [0, 0.2, 0.4, 0.6, 0.8] + ([1.0, 1.2] if top > 1 else [])
        ax.set_yticks(tk)
        ax.set_yticklabels(["0"] + [f"{t:g}" for t in tk[1:]], fontsize=6)
        ax.set_xticks(xs)
        ax.set_xticklabels(yrs, fontsize=6)
        ax.text(0.5, 1.04, d, transform=ax.transAxes, ha="center", fontfamily=BOLD, fontsize=6.5)
        ax.text(-0.05, 1.04, "Ratio", transform=ax.transAxes, ha="right", fontfamily=LITAL, fontsize=6)
    F.save(out / "Figure 4.7.png")


def fig_4_9(D, out):
    F = Frame("Figure 4.9", "Pakistan Gender Development Index, (2006-2019)", COL1, 7.45,
              "Reproduced from HIES 2005-06, 2011-12, 2015-16 and 2018-19, LFS 2006-07, 2012-13, 2014-15 and "
              "2018-19 microdata; life expectancy by sex and GNI per head from WDI.")
    ax = F.panel(0.0, 1.0, pad=(0.45, 0.1, 0.35, 0.45))
    xmap = dict(zip(YEARS_HDI, XPOS_HDI))
    xs = [xmap[y] for y in YEARS4]
    for x in XPOS_HDI:
        ax.add_patch(Rectangle((x - 0.7, 0), 1.4, 1.0, color=TAN, alpha=0.55, lw=0, zorder=0.4))
    f = [D.gdi(y, 2, "g_hdi") for y in YEARS4]
    m = [D.gdi(y, 1, "g_hdi") for y in YEARS4]
    g = [D.gdi(y, 2, "gdi") for y in YEARS4]
    for v, ls, lw in [(f, (0, (2, 1.2)), 1.8), (m, "-", 2.2), (g, "-", 0.8)]:
        ax.plot(xs, v, color="black", ls=ls, lw=lw, zorder=3)
        ax.text(xs[-1] + 0.8, v[-1], f3(v[-1]), va="center", fontsize=6)
    leg = [("Female HDI", (0, (2, 1.2)), 1.8), ("Male HDI", "-", 2.2), ("GDI Pakistan", "-", 0.8)]
    for k, (lab, ls, lw) in enumerate(leg):
        x0 = 0.02 + k * 0.33
        ax.plot([x0, x0 + 0.08], [1.07, 1.07], transform=ax.transAxes, color="black", ls=ls, lw=lw, clip_on=False)
        ax.text(x0 + 0.1, 1.07, lab, transform=ax.transAxes, va="center", fontsize=6.3)
    ax.set_xlim(-1, 14.3)
    ax.set_ylim(0, 1.0)
    t = np.round(np.arange(0, 1.01, 0.1), 1)
    ax.set_yticks(t)
    ax.set_yticklabels(["0"] + [f"{v:.3f}" for v in t[1:]], fontsize=6.3)
    ax.text(0, 1.0, "HDI", transform=ax.transAxes, fontfamily=LITAL, fontsize=6.5, ha="right", va="bottom")
    ax.set_xticks(XPOS_HDI)
    ax.set_xticklabels(YEARS_HDI, fontfamily=BOLD, fontsize=6.3)
    F.save(out / "Figure 4.9.png")


def fig_4_10(D, out):
    F = Frame("Figure 4.10", "Female and male earnings, (2006-2019)", NARROW, 9.5,
              "Reproduced from LFS 2006-07, 2012-13, 2014-15 and 2018-19 microdata, with WDI GNI per head (PPP) "
              "and the Census 2017 female share.")
    ax = F.panel(0.0, 1.0, pad=(0.1, 0.1, 0.1, 0.35))
    ax.text(0.5, 1.03, "Estimated earned income PPP $", transform=ax.transAxes, ha="center", fontfamily=BOLD,
            fontsize=6.3)
    ys = [3.3, 2.2, 1.1, 0.0]
    for yr, y in zip(YEARS4, ys):
        f, m = D.gdi(yr, 2, "pci_sex"), D.gdi(yr, 1, "pci_sex")
        R = 0.42 * np.sqrt(m / 9335)
        r = 0.42 * np.sqrt(f / 9335)
        ax.add_patch(Circle((0, y), R, color=NAVY, zorder=2))
        ax.add_patch(Circle((0, y - R + r), r, color=ORANGE, zorder=3))
        ax.text(0, y + 0.08, f"{m:,.0f}", color="white", ha="center", fontfamily=BOLD, fontsize=6.3, zorder=4)
        ax.text(0, y - R + r, f"{f:,.0f}", color="white", ha="center", va="center", fontfamily=BOLD,
                fontsize=5.6, zorder=4)
        if yr == "2006-07":
            ax.text(0, y + R * 0.62, "Male", color="white", ha="center", fontfamily=BOLD, fontsize=6.3, zorder=4)
            ax.text(0, y - R + 2 * r + 0.02, "Female", color="white", ha="center", fontfamily=BOLD, fontsize=5.6,
                    zorder=4)
        ax.text(0, y - 0.47, yr, ha="center", fontfamily=BOLD, fontsize=6.3)
    ax.set_xlim(-0.55, 0.55)
    ax.set_ylim(-0.6, 3.8)
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    F.save(out / "Figure 4.10.png")


def fig_4_11(D, out):
    F = Frame("Figure 4.11", "Pakistan's Gender Inequality Index over the years, (2006-2019)", COL1, 3.6,
              "Reproduced from HIES 2005-06, 2011-12 and 2018-19, PSLM 2014-15, and LFS 2006-07, 2012-13, "
              "2014-15 and 2017-18 microdata; seats from WDI.")
    ax = F.panel(0.0, 1.0, pad=(0.35, 0.15, 0.3, 0.15))
    xmap = dict(zip(YEARS_HDI, XPOS_HDI))
    xs = [xmap[y] for y in YEARS4]
    vs = [D.gii(y) for y in YEARS4]
    ax.plot(xs, vs, color=ORANGE, lw=1.6)
    for x, v in zip(xs, vs):
        dot(ax, x, v, f3(v), ORANGE, r_pts=13, fs=5.8)
    ax.set_ylim(0.25, 0.62)
    ax.set_yticks([0.25, 0.4, 0.6])
    ax.set_yticklabels(["0", "0.4", "0.6"], fontsize=6.3)
    for t in [0.4, 0.6]:
        ax.axhline(t, color=TAN, lw=0.5, zorder=0.5)
    ax.axhline(0.25, color="black", lw=1.1)
    axis_break(ax, 0.32)
    ax.set_xticks(XPOS_HDI)
    ax.set_xticklabels(YEARS_HDI, fontfamily=BOLD, fontsize=6.3)
    ax.set_xlim(-1, 13)
    F.save(out / "Figure 4.11.png")


def nested(ax, x, y, big, small, cb, cs, scale, lab_b=None, lab_s=None, fs=6, top_label=None):
    R = scale * np.sqrt(big)
    r = scale * np.sqrt(small)
    ax.add_patch(Circle((x, y), R, color=cb, zorder=2))
    ax.add_patch(Circle((x, y - R + r), r, color=cs, zorder=3))
    ax.text(x, y - R + r, f3(small), color="white", ha="center", va="center", fontfamily=BOLD, fontsize=fs,
            zorder=5)
    if R - 2 * r > 0.18 * scale:
        ax.text(x, y + R - 0.35 * (R - r), f3(big), color="white", ha="center", va="center", fontfamily=BOLD,
                fontsize=fs, zorder=5)
    else:
        ax.text(x, y + R + 0.05 * scale, f3(big), ha="center", va="bottom", fontfamily=BOLD, fontsize=fs)


def fig_4_13(D, out):
    F = Frame("Figure 4.13", "The male and female Youth Development Index, (2018)", COL2, 5.05,
              "Reproduced from LFS 2017-18 and PMMS 2019 microdata.")
    ax = F.panel(0.0, 1.0, pad=(0.1, 0.1, 0.1, 0.1))
    M, W = "Pakistan - Male", "Pakistan - Female"
    ym, yf = D.ydi_pmms(M), D.ydi_pmms(W)
    R = 1.0 * np.sqrt(ym)
    r = 1.0 * np.sqrt(yf)
    ax.add_patch(Circle((0, 1.25), R, color=NAVY))
    ax.add_patch(Circle((0, 1.25 - R + r), r, color=ORANGE))
    ax.text(0, 1.25 + R - 0.22, "Male", color="white", ha="center", fontfamily=BOLD, fontsize=7)
    ax.text(0, 1.25 + R - 0.42, f"YDI\n{ym:.3f}", color="white", ha="center", va="top", fontfamily=REG, fontsize=6.5)
    ax.text(0, 1.25 - R + r + 0.12, "Female", color="white", ha="center", fontfamily=BOLD, fontsize=7)
    ax.text(0, 1.25 - R + r - 0.05, f"YDI\n{yf:.3f}", color="white", ha="center", va="top", fontfamily=REG,
            fontsize=6.5)
    subs = [("r_i_hied", "Percentage of\nenrolled youth\nin higher\neducation"), ("r_i_mys", "Years of\nschooling\nof youth"),
            ("r_i_epr", "Youth\nemployment\n-to- population\nratio"), ("r_i_full", "Percentage of\nfully employed\nyouth"),
            ("r_i_surv", "Youth\nsurvival\nrate")]
    xs = np.linspace(-2.2, 2.2, 5)
    ax.plot([xs[0], xs[-1]], [-0.05, -0.05], color="black", lw=0.6)
    ax.plot([0, 0], [-0.05, 1.25 - R], color="black", lw=0.6)
    for x, (c, lab) in zip(xs, subs):
        ax.plot([x, x], [-0.05, -0.12], color="black", lw=0.6)
        m, w = (D.isurv(M), D.isurv(W)) if c == "r_i_surv" else (D.ydi(M, c), D.ydi(W, c))
        if m >= w:
            nested(ax, x, -0.55, m, w, NAVY, ORANGE, 0.42)
        else:
            nested(ax, x, -0.55, w, m, ORANGE, NAVY, 0.42)
        ax.text(x, -1.0, lab, ha="center", va="top", fontsize=6.2)
    ax.set_xlim(-2.6, 2.6)
    ax.set_ylim(-1.7, 2.35)
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    F.save(out / "Figure 4.13.png")


def fig_4_15(D, out):
    F = Frame("Figure 4.15", "Dimensions of the Labour Development Index by sex, (2012-2018)", NARROW, 10.9,
              "Reproduced from LFS 2012-13, 2014-15 and 2017-18 microdata, with WDI GDP.")
    panels = [("epr", "Employment to population", "Ratio", (0, 0.75)),
              ("skillprem", "Skill premium", "Ratio", (0, 4.2)),
              ("lshare", "Share of labour income in GDP", "Ratio", (0, 0.5)),
              ("humcap", "Human capital", "Ratio", (0, 8)),
              ("decentwork", "Incidence of decent work", "%", (0, 22))]
    for k, (c, lab, unit, yl) in enumerate(panels):
        ax = F.panel(1 - (k + 1) / 5 + 0.005, 1 - k / 5, pad=(0.3, 0.12, 0.25, 0.3))
        ax.add_patch(Rectangle((0, yl[0]), 5, yl[1] - yl[0], color=TAN, alpha=0.75, lw=0, zorder=0.4))
        yrs = ["2012-13", "2014-15", "2017-18"]
        m = [D.ldi("Pakistan - Male", y, c) for y in yrs]
        f = [D.ldi("Pakistan - Female", y, c) for y in yrs]
        ax.plot([0, 2, 5], m, color="black", lw=1.0, ls=(0, (3, 1)))
        ax.plot([0, 2, 5], f, color="black", lw=1.0, ls=(0, (1, 1.2)))
        gap = 100 * (m[-1] - f[-1]) / f[-1]
        ax.plot([4.8, 4.8], [f[-1], m[-1]], color="black", lw=0.6)
        ax.text(4.75, (m[-1] + f[-1]) / 2, f"{gap:.0f}%", ha="right", va="center", fontfamily=BOLD, fontsize=6)
        ax.set_xlim(0, 5)
        ax.set_ylim(*yl)
        ax.set_xticks([0, 2, 5])
        ax.set_xticklabels(["2012-13", "2014-15", "2017-18"], fontsize=6)
        ax.text(0.55, 1.05, lab, transform=ax.transAxes, ha="center", fontfamily=BOLD, fontsize=6.3)
        ax.text(-0.04, 1.05, unit, transform=ax.transAxes, ha="right", fontfamily=LITAL, fontsize=6)
        if k == 0:
            ax.plot([0.3, 0.4], [1.28, 1.28], transform=ax.transAxes, color="black", lw=1.0, ls=(0, (3, 1)),
                    clip_on=False)
            ax.text(0.42, 1.28, "Male", transform=ax.transAxes, va="center", fontsize=6)
            ax.plot([0.62, 0.72], [1.28, 1.28], transform=ax.transAxes, color="black", lw=1.0, ls=(0, (1, 1.2)),
                    clip_on=False)
            ax.text(0.74, 1.28, "Female", transform=ax.transAxes, va="center", fontsize=6)
    F.save(out / "Figure 4.15.png")


def not_reproduced(out, label, title, line):
    F = Frame(label, title, COL1, 3.0, "")
    ax = F.panel(0.0, 1.0, pad=(0.1, 0.1, 0.1, 0.1))
    ax.text(0.5, 0.56, "Not reproduced", ha="center", va="center", fontfamily=BOLD, fontsize=9, color=NA_COL,
            transform=ax.transAxes)
    ax.text(0.5, 0.42, line, ha="center", va="center", fontfamily=ITAL, fontsize=6.8, color=NA_COL,
            transform=ax.transAxes, wrap=True)
    ax.set_xticks([])
    ax.set_yticks([])
    F.save(out / f"Figure {label.split()[1]}.png")


def fig_4_8(D, out):
    F = Frame("Figure 4.8", "Pakistan's performance on the Global Gender Gap Index, (2006-2025)", COL1, 3.0,
              "WEF, Global Gender Gap Report, editions 2006 to 2025 (score as printed in each edition).")
    ax = F.panel(0.0, 1.0, pad=(0.35, 0.15, 0.3, 0.15))
    W = D.W.sort_values("edition")
    ax.plot(W.edition, W.gggi_score, color=ORANGE, lw=1.4, zorder=3)
    lab = {2006, 2013, 2015, 2020, 2025}
    for _, r in W.iterrows():
        if r.edition in lab:
            dot(ax, r.edition, r.gggi_score, f"{r.gggi_score:.3f}", ORANGE, r_pts=13, fs=5.4)
        else:
            ax.scatter([r.edition], [r.gggi_score], color=ORANGE, s=9, zorder=4)
    ax.set_ylim(0.25, 0.62)
    ax.set_yticks([0.25, 0.4, 0.6])
    ax.set_yticklabels(["0", "0.4", "0.6"], fontsize=6.3)
    for t in [0.4, 0.6]:
        ax.axhline(t, color=TAN, lw=0.5, zorder=0.5)
    ax.axhline(0.25, color="black", lw=1.1)
    axis_break(ax, 0.32)
    ax.set_xticks([2006, 2013, 2015, 2020, 2025])
    ax.set_xticklabels(["2006", "2013", "2015", "2020", "2025"], fontfamily=BOLD, fontsize=6.3)
    ax.set_xlim(2005, 2026)
    F.save(out / "Figure 4.8.png")


def fig_4_12(D, out):
    not_reproduced(out, "Figure 4.12", "Gender-based Child Development Index, (2018-2019)",
                   "The do file builds the CDI for both sexes together only")


# ---------------------------------------------------------------------------------------
# Chapter 5
# ---------------------------------------------------------------------------------------
def fig_5_19(D, out):
    F = Frame("Figure 5.19", "Access to health services by wealth quintile (%), (2017-2018)", COL1, 7.9,
              "Reproduced from PDHS 2017-18 microdata.")
    ax = F.panel(0.0, 1.0, pad=(0.4, 0.15, 0.3, 0.75))
    d = D.F519[D.F519.q <= 5].sort_values("q")
    ser = [("tap", "Access to tap water", "s", ORANGE, -0.04), ("basicvac", "Coverage of basic vaccinations of children",
                                                                 "o", TEAL, 0.0),
           ("facility", "Child delivery in health facility", "D", AMBER, 0.04)]
    for x in range(5):
        ax.plot([x, x], [0, 100], color="black", lw=0.7, zorder=1)
    for x in range(5):
        row = sorted([(float(d[c].iloc[x]), col, mk) for c, lab, mk, col, dx in ser])
        ly = []
        for v, col, mk in row:
            ax.scatter([x], [v], marker=mk, color=col, s=28, zorder=4)
            y = v if not ly else max(v, ly[-1] + 5.2)
            ly.append(y)
            ax.text(x + 0.12, y, f"{v:.0f}", va="center", ha="left", color="white", fontsize=5.8, fontfamily=REG,
                    bbox=dict(boxstyle="square,pad=0.2", fc=col, ec="none"), zorder=5)
    for k, (c, lab, mk, col, dx) in enumerate(ser):
        ax.scatter([0.02], [1.16 - 0.055 * k], transform=ax.transAxes, marker=mk, color=col, s=24, clip_on=False)
        ax.text(0.06, 1.16 - 0.055 * k, lab, transform=ax.transAxes, va="center", fontsize=6.3)
    ax.set_ylim(0, 100)
    grid_y(ax, [0, 20, 40, 60, 80, 100], fmt="{:g}", label="%")
    ax.set_xticks(range(5))
    ax.set_xticklabels(["Q1", "Q2", "Q3", "Q4", "Q5"], fontfamily=BOLD, fontsize=6.5)
    ax.set_xlim(-0.4, 4.7)
    F.save(out / "Figure 5.19.png")


# ---------------------------------------------------------------------------------------
# Maps
# ---------------------------------------------------------------------------------------
CL_HIGH, CL_MED, CL_LOW = "#2E7764", "#C7B74E", "#D5515C"


def map_fig(D, out, num, title, short, name, vals, pak, source, reverse=False):
    F = Frame(f"Map {num}", title, 8.8, 8.3, source)
    f = F.fig
    span = F.top - F.bottom
    f.add_artist(Rectangle((0, F.bottom), 1, span - 0.03 / F.h, transform=f.transFigure, color=BEIGE, lw=0,
                           zorder=0))
    hi, me, lo = (CL_LOW, CL_MED, CL_HIGH) if reverse else (CL_HIGH, CL_MED, CL_LOW)

    def cls(v):
        return hi if v >= 0.7 else (me if v >= 0.55 else lo)

    lx, ly = 0.04, F.bottom + span * 0.86
    f.text(lx + 0.02, ly, f"{name} ({short})".upper(), fontfamily=BOLD, fontsize=6.5, transform=f.transFigure)
    for k, (lab, col, rng) in enumerate([("High " + short, hi, "0.700 and above"),
                                         ("Medium " + short, me, "0.550 - 0.699"),
                                         ("Low " + short, lo, "0.549 and below")]):
        yy = ly - 0.04 - k * 0.035
        f.text(lx + 0.09, yy, lab, ha="right", va="center", fontsize=6.3)
        f.add_artist(Rectangle((lx + 0.105, yy - 0.006), 0.075, 0.013, transform=f.transFigure, color=col, lw=0))
        f.text(lx + 0.2, yy, rng, va="center", fontsize=6.3)
    lead = f"{name} for Pakistan: "
    f.text(lx + 0.0, ly - 0.2, lead, fontfamily=BOLD, fontsize=6.3)
    f.text(lx + text_w(f, lead, BOLD, 6.3) / F.w, ly - 0.2, f"{pak:.3f}", fontfamily=BOLD, fontsize=6.3,
           bbox=dict(boxstyle="square,pad=0.15", fc=cls(pak), ec="none"))
    boxes = {"Balochistan": (0.36, 0.53), "Khyber Pakhtunkhwa": (0.68, 0.53), "Punjab": (0.36, 0.08),
             "Sindh": (0.68, 0.08)}
    geo = D.geo
    gname = {"Balochistan": "Balochistan", "Khyber Pakhtunkhwa": "Khyber Pakhtunkhwa", "Punjab": "Punjab",
             "Sindh": "Sindh"}
    for p, (bx, by) in boxes.items():
        bw, bh = 0.29, 0.36
        y0 = F.bottom + by * span
        a = f.add_axes([bx, y0 + 0.07 * span, bw, bh * span])
        a.set_facecolor("none")
        for s in a.spines.values():
            s.set_linewidth(0.8)
        a.set_xticks([])
        a.set_yticks([])
        sub = geo[geo.shape_name.str.contains(gname[p].split()[0], case=False)]
        for sid, g in sub.groupby("shape_id"):
            g = g.sort_values("seq")
            a.add_patch(Polygon(g[["lon", "lat"]].values, closed=True, facecolor=cls(vals[p]), edgecolor="none"))
        x0, x1, ya, yb = sub.lon.min(), sub.lon.max(), sub.lat.min(), sub.lat.max()
        cx, cy, half = (x0 + x1) / 2, (ya + yb) / 2, max(x1 - x0, yb - ya) / 2 * 1.12
        a.set_xlim(cx - half, cx + half)
        a.set_ylim(cy - half, cy + half)
        a.set_aspect("equal")
        f.text(bx + bw / 2, y0 + 0.045 * span, p.upper(), ha="center", fontsize=6.3)
        f.text(bx + bw / 2, y0 + 0.015 * span, f"{vals[p]:.3f}", ha="center", fontfamily=BOLD, fontsize=6.5)
    F.save(out / f"Map {num}.png")


def maps(D, out):
    C = D.C[D.C.year == "2018-19"].set_index("region").h_cdi
    map_fig(D, out, "4.1", "Pakistan Child Development Index, (2018-2019)", "CDI", "Child Development Index",
            {p: C[p] for p in PROVS}, C["Pakistan"],
            "Reproduced from HIES 2018-19, LFS 2017-18 and PDHS 2017-18 microdata.")
    Y = {p: D.ydi_pmms(p) for p in PROVS + ["Pakistan"]}
    map_fig(D, out, "4.2", "Pakistan Youth Development Index, (2017-2018)", "YDI", "Youth Development Index",
            Y, Y["Pakistan"], "Reproduced from LFS 2017-18 and PMMS 2019 microdata.")
    L = {p: D.ldi(p, "2017-18", "r_ldidw") for p in PROVS + ["Pakistan"]}
    map_fig(D, out, "4.3", "Pakistan Labour Development Index, (2017-2018)", "LDI", "Labour Development Index",
            L, L["Pakistan"], "Reproduced from LFS 2017-18 microdata, with WDI GDP and Pasha's provincial shares.")
    G = D.GII18.set_index("domain").m_gii
    map_fig(D, out, "4.4", "Pakistan Gender Inequality Index, (2018-2019)", "GII", "Gender Inequality Index",
            {p: G[p] for p in PROVS}, G["Pakistan"],
            "Reproduced from HIES 2018-19 and LFS 2017-18 microdata; seats as NHDR.", reverse=True)


def main(run, outdir):
    run, out = Path(run), Path(outdir)
    if not run.is_absolute():
        run = ROOT / run
    out.mkdir(parents=True, exist_ok=True)
    D = Data(run)
    for fn in [fig_2_18, fig_2_19, fig_2_20, fig_3_6, fig_3_22, fig_3_23, fig_3_28, fig_4_1, fig_4_4, fig_4_5,
               fig_4_6, fig_4_7, fig_4_8, fig_4_9, fig_4_10, fig_4_11, fig_4_12, fig_4_13, fig_4_15, fig_5_19, maps]:
        fn(D, out)
    for num, prov in [("3.10", "Punjab"), ("3.13", "Sindh"), ("3.16", "Khyber Pakhtunkhwa"), ("3.19", "Balochistan")]:
        fig_petal(D, out, num, prov, f"HDI by quintile, {prov}, (2018-2019)")
    print("written to", out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
