"""Build the slide deck that explains the NHDR 2020 reproduction.

    python "7. Python tools/deck.py"                      (latest complete run)
    python "7. Python tools/deck.py" "8. Stata runs/Run YYYYMMDD HHMMSS"

Writes "2. Notes/NHDR2020 reproduction deck.pptx". Every chart is a native,
editable PowerPoint chart built from the run's result tables; every shape is a
native shape. Arial throughout, no text below 16 pt, ADB palette, and the
sources of each slide in its speaker notes.
"""
import sys
from pathlib import Path

import pandas as pd
from pptx import Presentation
from pptx.chart.data import CategoryChartData
from pptx.dml.color import RGBColor
from pptx.enum.chart import XL_CHART_TYPE, XL_LEGEND_POSITION, XL_LABEL_POSITION
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
RUNS = ROOT / "8. Stata runs"

# ADB palette, read from the ADB colour palette image
BLUE, MID, LIGHT, PALE = "007DB7", "0098D7", "44BFE9", "8BD9F8"
TEAL, GREEN, LIME = "00A2CC", "8DC63F", "B1D233"
RED, ORANGE, AMBER, YELLOW = "E9532B", "F06D2A", "F28429", "F3E600"
GREY, INK, WHITE = "E6E6E6", "262626", "FFFFFF"
FONT = "Arial"


def rgb(h):
    return RGBColor.from_string(h)


def latest_run():
    done = [p for p in RUNS.glob("Run *") if (p / "NHDR replication results.xlsx").exists()]
    return max(done, key=lambda p: p.name)


class Deck:
    def __init__(self):
        self.prs = Presentation()
        self.prs.slide_width, self.prs.slide_height = Inches(13.333), Inches(7.5)
        self.blank = self.prs.slide_layouts[6]

    def slide(self, title, notes, kicker=None):
        s = self.prs.slides.add_slide(self.blank)
        if kicker:
            self.text(s, 0.55, 0.28, 12.2, 0.4, [(kicker, 16, False, MID)])
        self.text(s, 0.55, 0.62 if kicker else 0.4, 12.2, 1.0, [(title, 28, True, BLUE)])
        bar = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.55), Inches(1.62), Inches(1.6), Inches(0.08))
        self.fill(bar, ORANGE)
        line = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(2.15), Inches(1.645), Inches(10.6), Inches(0.03))
        self.fill(line, GREY)
        s.notes_slide.notes_text_frame.text = notes
        return s

    @staticmethod
    def fill(shape, color, line=False):
        shape.fill.solid()
        shape.fill.fore_color.rgb = rgb(color)
        if line:
            shape.line.color.rgb = rgb(line)
        else:
            shape.line.fill.background()
        shape.shadow.inherit = False

    def text(self, s, x, y, w, h, paras, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP, shape=None):
        box = shape if shape is not None else s.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
        tf = box.text_frame
        tf.word_wrap = True
        tf.vertical_anchor = anchor
        tf.margin_left = tf.margin_right = Inches(0.08)
        for i, (t, size, bold, color) in enumerate(paras):
            para = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
            para.alignment = align
            r = para.add_run()
            r.text = t
            r.font.name, r.font.size, r.font.bold = FONT, Pt(max(size, 16)), bold
            r.font.color.rgb = rgb(color)
            para.space_after = Pt(6)
        return box

    def card(self, s, x, y, w, h, color, head, body, head_size=20, body_size=16, text_color=WHITE):
        b = s.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(x), Inches(y), Inches(w), Inches(h))
        b.adjustments[0] = 0.06
        self.fill(b, color)
        paras = [(head, head_size, True, text_color)] + [(t, body_size, False, text_color) for t in body]
        self.text(s, 0, 0, 0, 0, paras, shape=b)
        b.text_frame.margin_left = b.text_frame.margin_right = Inches(0.15)
        b.text_frame.margin_top = Inches(0.1)
        return b

    def badge(self, s, x, y, d, color, label):
        c = s.shapes.add_shape(MSO_SHAPE.OVAL, Inches(x), Inches(y), Inches(d), Inches(d))
        self.fill(c, color)
        self.text(s, 0, 0, 0, 0, [(label, 20, True, WHITE)], align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE, shape=c)
        c.text_frame.margin_left = c.text_frame.margin_right = 0

    def chart(self, s, kind, x, y, w, h, cats, series, colors, number_format="0.000", ymin=None, ymax=None,
              labels=True, legend=True, label_pos=None):
        cd = CategoryChartData()
        cd.categories = cats
        for name, vals in series:
            cd.add_series(name, vals)
        gf = s.shapes.add_chart(kind, Inches(x), Inches(y), Inches(w), Inches(h), cd)
        ch = gf.chart
        ch.font.name, ch.font.size = FONT, Pt(16)
        ch.has_legend = legend
        if legend:
            ch.legend.position = XL_LEGEND_POSITION.BOTTOM
            ch.legend.include_in_layout = False
            ch.legend.font.size, ch.legend.font.name = Pt(16), FONT
        va = ch.value_axis
        va.has_major_gridlines = True
        va.major_gridlines.format.line.color.rgb = rgb(GREY)
        va.tick_labels.font.size = Pt(16)
        va.tick_labels.number_format, va.tick_labels.number_format_is_linked = number_format, False
        va.format.line.fill.background()
        if ymin is not None:
            va.minimum_scale = ymin
        if ymax is not None:
            va.maximum_scale = ymax
        ch.category_axis.tick_labels.font.size = Pt(16)
        ch.category_axis.format.line.color.rgb = rgb(INK)
        for ser, col in zip(ch.plots[0].series, colors):
            if kind in (XL_CHART_TYPE.LINE_MARKERS, XL_CHART_TYPE.LINE):
                ser.format.line.color.rgb = rgb(col)
                ser.format.line.width = Pt(3.5)
                ser.marker.format.fill.solid()
                ser.marker.format.fill.fore_color.rgb = rgb(col)
                ser.marker.format.line.color.rgb = rgb(col)
                ser.marker.size = 10
                ser.smooth = False
            else:
                ser.format.fill.solid()
                ser.format.fill.fore_color.rgb = rgb(col)
                # Yellow bars need an outline to read on white.
                if col == YELLOW:
                    ser.format.line.color.rgb = rgb(AMBER)
                    ser.format.line.width = Pt(1.5)
        if labels:
            pl = ch.plots[0]
            pl.has_data_labels = True
            dl = pl.data_labels
            dl.font.size, dl.font.name = Pt(16), FONT
            dl.number_format, dl.number_format_is_linked = number_format, False
            if kind in (XL_CHART_TYPE.LINE_MARKERS, XL_CHART_TYPE.LINE):
                dl.position = XL_LABEL_POSITION.ABOVE
            else:
                dl.position = XL_LABEL_POSITION.OUTSIDE_END
        if label_pos:
            for ser, pos in zip(ch.plots[0].series, label_pos):
                ser.data_labels.position = pos
                ser.data_labels.font.size, ser.data_labels.font.name = Pt(16), FONT
        if kind == XL_CHART_TYPE.COLUMN_CLUSTERED:
            ch.plots[0].gap_width = 60
            ch.plots[0].overlap = -10
        return ch


def main(run=None):
    run = Path(run) if run else latest_run()
    if not run.is_absolute():
        run = ROOT / run
    chk = pd.read_csv(run / "Checks.txt", sep="\t")
    n_chk, n_pass = len(chk), int((chk.status == "PASS").sum())
    H = pd.read_csv(run / "HDI all microdata.csv")
    P = pd.read_csv(run / "HDI Pasha income.csv")
    L = pd.read_csv(run / "LDI 2012-13 2017-18 2024-25.csv")
    C = pd.read_csv(run / "CDI reproduced PDHS.csv")
    G = pd.read_csv(run / "GDI reproduced 2018-19 2024-25.csv")
    GI = pd.read_csv(run / "GII 2018-19 all microdata.csv").set_index("domain")
    PS = pd.read_csv(run / "PSLM district rounds tested.csv")
    CR = pd.read_csv(run / "CDI reproduced 2007-08 2018-19.csv")
    src_run = f"Reproduced values: NHDR2020 reproduction from microdata.do, 8. Stata runs/{run.name}."
    src_nhdr = "Published values: UNDP Pakistan (2020), Pakistan National Human Development Report 2020, Statistical Annex Tables 1 to 8A."
    PROV = ["Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan"]
    SHORT = {"Pakistan": "Pakistan", "Punjab": "Punjab", "Sindh": "Sindh", "Khyber Pakhtunkhwa": "KP",
             "Balochistan": "Balochistan"}
    D = Deck()

    # 1 ---------------------------------------------------------------- title
    s = D.prs.slides.add_slide(D.blank)
    band = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, Inches(13.333), Inches(7.5))
    D.fill(band, BLUE)
    for i, (col, x) in enumerate([(MID, 9.2), (TEAL, 10.4), (LIGHT, 11.6)]):
        r = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(x), Inches(0), Inches(1.2), Inches(7.5))
        D.fill(r, col)
    acc = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.7), Inches(3.55), Inches(2.2), Inches(0.1))
    D.fill(acc, ORANGE)
    D.text(s, 0.7, 1.4, 8.2, 2.1, [("Reproducing the NHDR 2020 indices from survey microdata", 40, True, WHITE)])
    D.text(s, 0.7, 3.85, 8.2, 1.5, [("What reproduces, what does not, and why", 24, False, WHITE),
                                    (f"{n_pass} of {n_chk} validation checks pass", 20, True, YELLOW)])
    D.text(s, 0.7, 6.4, 8.2, 0.5, [("4 October 2026", 18, False, WHITE)])
    s.notes_slide.notes_text_frame.text = (
        "Scope: UNDP Pakistan, National Human Development Report 2020 (NHDR 2020), Statistical Annex Tables 1 to 8A "
        "and the 28 index figures and maps. " + src_run)

    # 2 ---------------------------------------------------------------- scope
    s = D.slide(f"Seven NHDR indices rebuilt from raw survey files; {n_pass} of {n_chk} checks pass",
                "Sources: " + src_nhdr + " " + src_run +
                " The one failing check is male wasting in Table 4A, which the PDHS 2017-18 microdata do not support.",
                kicker="WHAT WAS REPRODUCED")
    idx = [("HDI", "Human Development Index", "Tables 1, 2A", BLUE),
           ("IHDI", "Inequality-adjusted HDI", "Table 3", MID),
           ("CDI", "Child Development Index", "Tables 4, 4A", TEAL),
           ("YDI", "Youth Development Index", "Tables 5, 5A", GREEN),
           ("GDI", "Gender Development Index", "Tables 6, 6A", ORANGE),
           ("GII", "Gender Inequality Index", "Tables 7, 7A", RED),
           ("LDI", "Labour Development Index", "Tables 8, 8A", AMBER),
           ("MPI", "Multidimensional Poverty Index", "2014-15, 2019-20", LIGHT)]
    for k, (a, name, tab, col) in enumerate(idx):
        x = 0.55 + (k % 4) * 3.1
        y = 2.0 + (k // 4) * 2.35
        D.card(s, x, y, 2.9, 2.1, col, a, [name, tab], head_size=28, body_size=16)
    D.text(s, 0.55, 6.75, 12.2, 0.6, [("Years: 2006-07 and 2018-19 as published, the figure years 2012-13 and 2015-16, "
                                       "and every index carried to 2024-25.", 16, False, INK)])

    # 3 ---------------------------------------------------------------- pipeline
    s = D.slide("One do file runs from raw microdata to every annex table in about five minutes",
                "Sources: package folder NHDR2020 replication from microdata, README.txt. Surveys: PBS HIES, LFS and "
                "PSLM; NIPS and ICF PDHS 2006-07, 2012-13, 2017-18 and PMMS 2019; UNICEF MICS6. " + src_run,
                kicker="HOW IT RUNS")
    steps = [("6. Raw data", ["HIES, LFS, PSLM", "PDHS, PMMS, MICS6", "Published tables"], BLUE),
             ("1. Dos", ["Stata do file", "27 sections", f"{n_chk} checks"], MID),
             ("8. Stata runs", ["Log and checks", "Result CSVs", "Labelled workbook"], TEAL),
             ("7. Python tools", ["Annex tables", "NHDR-style figures", "Note and deck"], GREEN),
             ("2 to 5", ["Notes, tables", "Plots, CSVs", "For the team"], ORANGE)]
    for k, (head, body, col) in enumerate(steps):
        x = 0.55 + k * 2.5
        ch = s.shapes.add_shape(MSO_SHAPE.CHEVRON if k else MSO_SHAPE.PENTAGON, Inches(x), Inches(2.3),
                                Inches(2.55), Inches(1.1))
        D.fill(ch, col)
        D.text(s, 0, 0, 0, 0, [(head, 20, True, WHITE)], align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE, shape=ch)
        D.text(s, x + 0.1, 3.6, 2.3, 2.0, [(t, 18, False, INK) for t in body])
    D.text(s, 0.55, 5.55, 12.2, 1.6, [("HIES: Household Integrated Economic Survey. LFS: Labour Force Survey. PSLM: Pakistan "
                                       "Social and Living Standards Measurement. PDHS: Pakistan Demographic and Health Survey. "
                                       "PMMS: Pakistan Maternal Mortality Survey. MICS6: Multiple Indicator Cluster Surveys, "
                                       "round 6.", 16, False, INK)])

    # 4 ---------------------------------------------------------------- construction
    s = D.slide("NHDR's HDI is a hybrid that no UNDP vintage uses, recovered by inverting its own tables",
                "Sources: " + src_nhdr + " Inversion: do file Section 5; all 120 published dimension indices "
                "(15 domains, 2 years, 4 quantities) reproduce within 0.0011. " + src_run, kicker="METHOD")
    parts = [("Education", "Two-thirds adult literacy 15+, one-third net enrolment 5-14", "pre-2010 UNDP weights", BLUE),
             ("Health", "Life expectancy, goalposts 25 and 90 years", "neither vintage", TEAL),
             ("Income", "Log income per head, 100 to 100,000 purchasing power parity (PPP) dollars", "neither vintage", GREEN),
             ("Aggregation", "Geometric mean of the three indices", "post-2010 UNDP", ORANGE)]
    for k, (h, b, tag, col) in enumerate(parts):
        D.card(s, 0.55 + k * 3.1, 2.0, 2.9, 2.9, col, h, [b, tag], head_size=22)
    tile = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.55), Inches(5.25), Inches(12.2), Inches(1.4))
    D.fill(tile, GREY)
    D.text(s, 0, 0, 0, 0, [("120 of 120 published dimension indices reproduce within 0.0011, the rounding of "
                            "Table 2A's one-decimal inputs.", 22, True, BLUE)], anchor=MSO_ANCHOR.MIDDLE, shape=tile)

    # 5 ---------------------------------------------------------------- HDI
    a = H[(H.year == "2018-19") & (H.quintile == "All")].set_index("domain")
    doms = ["Pakistan"] + PROV
    s = D.slide("Education reproduces exactly; health and income move the provincial HDI",
                "Sources: " + src_nhdr + " Reproduced: HDI all microdata.csv. Education from HIES 2018-19; life "
                "expectancy from PDHS 2017-18 under-five mortality, ten years, Coale-Demeny West; income from HIES "
                "consumption scaled to WDI GNI per head, PPP, fiscal-year average (4,925). " + src_run,
                kicker="HUMAN DEVELOPMENT INDEX, 2018-19 (KP: KHYBER PAKHTUNKHWA)")
    D.chart(s, XL_CHART_TYPE.COLUMN_CLUSTERED, 0.45, 1.85, 8.6, 5.4, [SHORT[d] for d in doms],
            [("Published", [round(a.loc[d, "p_hdi"], 3) for d in doms]),
             ("Microdata education", [round(a.loc[d, "hdi_e"], 3) for d in doms]),
             ("All three from microdata", [round(a.loc[d, "hdi_ehi"], 3) for d in doms])],
            [BLUE, LIGHT, ORANGE], ymin=0.40, ymax=0.62, labels=False)
    D.card(s, 9.3, 2.0, 3.5, 2.4, BLUE, "Education", ["All 30 domain totals within 0.0002 of the published HDI"])
    D.card(s, 9.3, 4.6, 3.5, 2.4, ORANGE, "Health and income",
           [f"Punjab {a.loc['Punjab', 'hdi_ehi']:.3f} against 0.572; Sindh {a.loc['Sindh', 'hdi_ehi']:.3f} against 0.574"])

    # 6 ---------------------------------------------------------------- income relatives
    p = P[(P.year == "2018-19") & (P.quintile == "All") & (P.domain.isin(PROV))].set_index("domain")
    s = D.slide("NHDR's provincial income matches no single Pasha estimate",
                "Sources: NHDR 2020 Table 2A (income per head by province over Pakistan). H.A. Pasha (2015), Growth of "
                "the Provincial Economies, Institute for Policy Reform: gross regional product per head, constant "
                "2005-06 prices, 2014-15. H.A. Pasha (2021), Business Recorder, 17 August 2021: current factor cost, "
                "2018-19. HIES 2018-19 consumption per head. Pasha (2019), the source NHDR names, is not public. "
                "Values: HDI Pasha income.csv. " + src_run, kicker="PROVINCIAL INCOME PER HEAD, PAKISTAN = 1.00, 2018-19")
    D.chart(s, XL_CHART_TYPE.COLUMN_CLUSTERED, 0.45, 1.85, 8.6, 5.4, [SHORT[d] for d in PROV],
            [("NHDR 2020", [round(p.loc[d, "rel_nhdr"], 2) for d in PROV]),
             ("Pasha 2018-19", [round(p.loc[d, "rel_pasha"], 2) for d in PROV]),
             ("Pasha 2014-15", [round(p.loc[d, "rel_pasha_alt"], 2) for d in PROV]),
             ("HIES consumption", [round(p.loc[d, "rel_hies"], 2) for d in PROV])],
            [BLUE, ORANGE, YELLOW, GREEN], number_format="0.00", ymin=0.4, ymax=1.35, labels=False)
    D.card(s, 9.3, 2.0, 3.5, 1.55, BLUE, "Sindh", [f"NHDR {p.loc['Sindh', 'rel_nhdr']:.2f} equals Pasha 2014-15 "
                                                    f"({p.loc['Sindh', 'rel_pasha_alt']:.2f})"])
    D.card(s, 9.3, 3.7, 3.5, 1.55, ORANGE, "KP", [f"NHDR {p.loc['Khyber Pakhtunkhwa', 'rel_nhdr']:.2f}, below both "
                                                  "Pasha estimates"])
    D.card(s, 9.3, 5.4, 3.5, 1.6, GREEN, "Two concepts", ["Pasha counts output where produced; HIES counts household "
                                                          "spending"], body_size=16)

    # 7 ---------------------------------------------------------------- HDI on Pasha income
    s = D.slide("On Pasha's 2018-19 income, Punjab and Balochistan match; KP and Sindh do not",
                "HDI built with microdata education, NHDR's own life expectancy and national income level (4,922), and "
                "each province's income relative to Pakistan set to Pasha's; HIES keeps the split within provinces. "
                "Do file Section 20.7; HDI Pasha income.csv. " + src_nhdr + " " + src_run,
                kicker="HDI 2018-19 WITH PASHA'S PROVINCIAL INCOME")
    D.chart(s, XL_CHART_TYPE.COLUMN_CLUSTERED, 0.45, 1.85, 8.6, 5.4, [SHORT[d] for d in PROV],
            [("Published HDI", [round(p.loc[d, "p_hdi"], 3) for d in PROV]),
             ("Pasha 2018-19 income", [round(p.loc[d, "hdi_pasha_nl"], 3) for d in PROV]),
             ("Pasha 2014-15 income", [round(p.loc[d, "hdi_pasha_alt"], 3) for d in PROV])],
            [BLUE, ORANGE, YELLOW], ymin=0.40, ymax=0.60, labels=False)
    gaps = {d: p.loc[d, "hdi_pasha_nl"] - p.loc[d, "p_hdi"] for d in PROV}
    for k, d in enumerate(PROV):
        col = GREEN if abs(gaps[d]) < 0.002 else RED
        D.card(s, 9.3, 2.0 + k * 1.25, 3.5, 1.1, col, SHORT[d],
               [f"{p.loc[d, 'hdi_pasha_nl']:.3f} against {p.loc[d, 'p_hdi']:.3f} published"], head_size=18)

    # 8 ---------------------------------------------------------------- LDI national
    n = L[L.region == "Pakistan"].set_index("year").loc[["2012-13", "2014-15", "2017-18"]]
    up_top = n.loc["2014-15", "wtop"] / n.loc["2012-13", "wtop"] - 1
    up_bot = n.loc["2014-15", "wbot"] / n.loc["2012-13", "wbot"] - 1
    up_top2 = n.loc["2017-18", "wtop"] / n.loc["2014-15", "wtop"] - 1
    up_bot2 = n.loc["2017-18", "wbot"] / n.loc["2014-15", "wbot"] - 1
    s = D.slide("The LDI turns because wages of the top occupations turn, not because jobs changed",
                "LFS 2012-13, 2014-15 and 2017-18 microdata; mean monthly wages of paid employees in ISCO groups 1-2 "
                "and 8-9; occupation shares ptop and pbot. LDI with and without decent work: LDI 2012-13 2017-18 "
                "2024-25.csv. NHDR Figure 4.4 rises in both steps (about 0.41, 0.44, 0.44, read from the chart). "
                + src_run, kicker="LABOUR DEVELOPMENT INDEX, PAKISTAN")
    D.chart(s, XL_CHART_TYPE.LINE_MARKERS, 0.45, 1.85, 6.4, 5.4, list(n.index),
            [("LDI with decent work", [round(v, 3) for v in n.r_ldidw]),
             ("LDI without decent work", [round(v, 3) for v in n.r_ldin]),
             ("Skill premium index", [round(v, 3) for v in n.r_i_sp])],
            [BLUE, GREEN, RED], ymin=0.30, ymax=0.45, labels=False)
    D.card(s, 7.1, 2.0, 5.7, 1.6, BLUE, "2012-13 to 2014-15",
           [f"Top wages +{100 * up_top:.0f}%, bottom +{100 * up_bot:.0f}%: premium {n.loc['2012-13', 'skillprem']:.2f} "
            f"to {n.loc['2014-15', 'skillprem']:.2f}"])
    D.card(s, 7.1, 3.75, 5.7, 1.6, ORANGE, "2014-15 to 2017-18",
           [f"Top wages +{100 * up_top2:.0f}%, bottom +{100 * up_bot2:.0f}%: premium falls to "
            f"{n.loc['2017-18', 'skillprem']:.2f}"])
    D.card(s, 7.1, 5.5, 5.7, 1.5, GREEN, "Occupation mix stable",
           [f"Top groups {100 * n.ptop.min():.0f} to {100 * n.ptop.max():.0f}% of paid employees, "
            f"bottom {100 * n.pbot.min():.0f} to {100 * n.pbot.max():.0f}%"])

    # 9 ---------------------------------------------------------------- LDI Balochistan
    b = L[L.region == "Balochistan"].set_index("year").loc[["2012-13", "2014-15", "2017-18"]]
    s = D.slide("Balochistan's labor share swings because Pasha's two estimates use different bases",
                "Provincial GDP = WDI current-price GDP x provincial share. Shares: Pasha IPR 2015 (constant 2005-06 "
                "prices; Balochistan 2.9% in 2014-15) and Pasha 2021 (current factor cost; 4.8% in 2018-19), "
                "interpolated between. Fixed-share version holds the 2018-19 shares in every year (lshare_fs). "
                "LFS self-employed in Balochistan: 1.00, 1.35 and 1.03 million. " + src_run,
                kicker="LABOR SHARE OF GDP, BALOCHISTAN")
    D.chart(s, XL_CHART_TYPE.LINE_MARKERS, 0.45, 1.85, 7.6, 5.4, list(b.index),
            [("Interpolated Pasha shares", [round(v, 2) for v in b.lshare]),
             ("Pasha 2018-19 shares held fixed", [round(v, 2) for v in b.lshare_fs])],
            [RED, BLUE], number_format="0.00", ymin=0.2, ymax=0.7,
            label_pos=[XL_LABEL_POSITION.ABOVE, XL_LABEL_POSITION.BELOW])
    D.card(s, 8.3, 2.0, 4.5, 2.3, RED, "Basis change",
           ["Pasha 2015: 2.9% of GDP at constant prices", "Pasha 2021: 4.8% at current factor cost"])
    D.card(s, 8.3, 4.5, 4.5, 2.5, BLUE, "Fixed shares",
           [f"Labor share {b.lshare_fs.min():.2f} to {b.lshare_fs.max():.2f} instead of "
            f"{b.lshare.min():.2f} to {b.lshare.max():.2f}", "LFS 2014-15 also counts more self-employed"])

    # 10 --------------------------------------------------------------- companion indices
    cdi = C[(C.region == "Pakistan") & (C.year == "2018-19")].iloc[0]
    gdi = G[(G.domain == "Pakistan") & (G.survey == "2018_19")].iloc[0]
    ldi = n.loc["2017-18"]
    comp = [("CDI 2018-19", 0.575, round(cdi.h_cdi, 3)), ("YDI 2017-18", 0.605, 0.604),
            ("GDI 2018-19", 0.777, round(gdi.gdi, 3)), ("GII 2018-19", 0.548, round(GI.loc["Pakistan", "m_gii"], 3)),
            ("LDI 2017-18", 0.442, round(ldi.r_ldidw, 3))]
    s = D.slide("The companion indices land within 0.03 of the published values for Pakistan",
                "Sources: " + src_nhdr + " CDI: CDI reproduced PDHS.csv. YDI with PMMS 2019 youth survival: "
                "3. Tables, Table 5. GDI with NHDR's life expectancy by sex: GDI reproduced 2018-19 2024-25.csv. GII: "
                "GII 2018-19 all microdata.csv. LDI: LDI 2012-13 2017-18 2024-25.csv. " + src_run,
                kicker="PAKISTAN, PUBLISHED AGAINST REPRODUCED")
    D.chart(s, XL_CHART_TYPE.COLUMN_CLUSTERED, 0.45, 1.85, 8.6, 5.4, [c[0] for c in comp],
            [("Published", [c[1] for c in comp]), ("Reproduced", [c[2] for c in comp])], [BLUE, ORANGE],
            ymin=0.3, ymax=0.85, labels=True)
    D.card(s, 9.3, 2.0, 3.5, 2.4, GREEN, "Close", ["CDI, YDI within 0.002"])
    D.card(s, 9.3, 4.6, 3.5, 2.4, RED, "Apart", ["GDI: LFS earnings", "GII: early marriage", "LDI: GDP base"])

    # 11 --------------------------------------------------------------- code defects
    s = D.slide("Four defects in the reproduction code were found and fixed",
                "Sources: DHS Program, DHS-Indicators-Stata, Chap08_CM/CM_CHILD.do; Rutstein and Rojas (2006), Guide to "
                "DHS Statistics; PDHS final reports 2006-07, 2012-13, 2017-18 (under-five mortality 94, 89, 74). "
                + src_run, kicker="WHAT WE CORRECTED")
    fixes = [("1", "Child deaths dropped", "Age at death heaped at whole years pushed deaths out of the window. "
              "A line-by-line port of the DHS code returns 94.17, 89.01 and 74.00 per 1,000.", BLUE),
             ("2", "CDI survival window", "Table 4A uses ten years in 2007-08 and five in 2018-19. All 30 cells "
              "now within 0.0005.", TEAL),
             ("3", "Vaccination age", "PDHS 2017-18 dates age from the day of birth (b19). Basic "
              "vaccination 65.6% against 66.", GREEN),
             ("4", "Empty anthropometry", "PDHS 2006-07 carries height and weight fields with no values. "
              "The code now tests for values.", ORANGE)]
    for k, (num, h, body, col) in enumerate(fixes):
        x = 0.55 + k * 3.1
        D.badge(s, x + 1.05, 1.95, 0.8, col, num)
        D.card(s, x, 2.9, 2.9, 3.9, col, h, [body], head_size=20)

    # 12 --------------------------------------------------------------- NHDR inconsistencies
    s = D.slide("NHDR 2020 contradicts itself or its sources in six places",
                "Sources: NHDR 2020 Map 4.2, Tables 2A, 4A, 5, 7A and technical notes; PBS LFS 2006-07, 2017-18 and "
                "2018-19 microdata; PDHS 2017-18 microdata; WDI NY.GNP.PCAP.PP.CD. " + src_run,
                kicker="WHAT THE REPORT GETS WRONG")
    inc = [("Map 4.2 vs Table 5", "Provincial YDI: 0.435, 0.572, 0.621, 0.630 in the map; 0.517, 0.524, 0.614, "
            "0.637 in the table", BLUE),
           ("Early marriage", "20.0% of women 15-19 in 2018-19; every LFS round gives 12.3 to 12.6%", RED),
           ("2006-07 income", "4,135 PPP dollars; WDI gives 3,350 and no series gives 4,135", ORANGE),
           ("YDI goalposts", "Note prints 0.9770; only 0.9970 reproduces Table 5", TEAL),
           ("Net enrolment", "Annex definition gives 62.0%; the printed 37.0 is level matched", GREEN),
           ("Male wasting", "Table 4A sits up to 1.3 points above the PDHS microdata", AMBER)]
    for k, (h, body, col) in enumerate(inc):
        D.card(s, 0.55 + (k % 3) * 4.1, 2.0 + (k // 3) * 2.45, 3.9, 2.25, col, h, [body], head_size=20)

    # 13 --------------------------------------------------------------- PSLM
    ps = PS[PS.region.isin(["Pakistan"] + PROV)]
    hies = CR[(CR.year == "2007-08")].set_index("region")
    p06 = ps[ps["round"] == "2006-07"].set_index("region")
    p08 = ps[ps["round"] == "2008-09"].set_index("region")
    s = D.slide("The PSLM district rounds do not reproduce NHDR's 2007-08 immunization either",
                "Full immunization at 12-23 months: BCG, DPT3 and polio 3 by card, recall or campaign. PSLM 2006-07 and "
                "2008-09 district rounds (do file Section 23.6, PSLM district rounds tested.csv); HIES 2007-08 "
                "(CDI reproduced 2007-08 2018-19.csv); NHDR 2020 Table 4A, 2007-08 column, which names PSLM 2007-08 "
                "(not held). " + src_run, kicker="FULL IMMUNIZATION, CHILDREN 12-23 MONTHS, PERCENT")
    D.chart(s, XL_CHART_TYPE.COLUMN_CLUSTERED, 0.45, 1.85, 9.2, 5.4, [SHORT[d] for d in ["Pakistan"] + PROV],
            [("NHDR 2007-08", [float(p06.loc[d, "pub_immun"]) for d in ["Pakistan"] + PROV]),
             ("HIES 2007-08", [round(hies.loc[d, "immun"], 1) for d in ["Pakistan"] + PROV]),
             ("PSLM 2006-07", [round(p06.loc[d, "immun"], 1) for d in ["Pakistan"] + PROV]),
             ("PSLM 2008-09", [round(p08.loc[d, "immun"], 1) for d in ["Pakistan"] + PROV])],
            [BLUE, GREEN, ORANGE, YELLOW], number_format="0", ymin=0, ymax=100, labels=False)
    D.card(s, 9.9, 2.0, 2.9, 4.9, BLUE, "Verdict", ["PSLM is closer in KP and Balochistan, further in Punjab, Sindh "
                                                    "and nationally", "HIES 2007-08 stays as input"], head_size=20)

    # 14 --------------------------------------------------------------- asks
    s = D.slide("Four items from UNDP Pakistan would close most of the remaining gap",
                "Sources: findings of this reproduction; " + src_run, kicker="NEXT STEPS")
    asks = [("1", "Pasha (2019) and the provincial income series of Table 2A", BLUE),
            ("2", "The model life table behind provincial life expectancy", TEAL),
            ("3", "The source of the early-marriage rates in Table 7A", ORANGE),
            ("4", "The 2006-07 national income level and the CDI split by sex", GREEN)]
    for k, (num, t, col) in enumerate(asks):
        y = 2.0 + k * 1.2
        D.badge(s, 0.7, y, 0.9, col, num)
        bar = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(1.8), Inches(y), Inches(10.9), Inches(0.9))
        D.fill(bar, GREY)
        D.text(s, 0, 0, 0, 0, [(t, 22, False, INK)], anchor=MSO_ANCHOR.MIDDLE, shape=bar)

    # 15 --------------------------------------------------------------- package
    s = D.slide("The package runs end to end from one shared folder",
                "Source: NHDR2020 replication from microdata/README.txt. Stata 16 or later; Python packages in "
                "7. Python tools/requirements.txt; Node.js for the Word note.", kicker="FOR THE TEAM")
    fold = [("1. Dos", "Do file and variable dictionary", BLUE), ("2. Notes", "Note, deck, variable inventory", MID),
            ("3. Tables", "Annex Tables 1 to 8A", TEAL), ("4. Plots", "Figures side by side", LIGHT),
            ("5. Output CSVs", "Latest results and checks", GREEN), ("6. Raw data", "Every input, with sources", LIME),
            ("7. Python tools", "Tables, figures, note, deck", ORANGE), ("8. Stata runs", "One folder per run", AMBER)]
    for k, (h, b_, col) in enumerate(fold):
        tc = INK if col in (LIME, LIGHT) else WHITE
        D.card(s, 0.55 + (k % 4) * 3.1, 2.0 + (k // 4) * 2.4, 2.9, 2.1, col, h, [b_], head_size=22, text_color=tc)

    out = ROOT / "2. Notes" / "NHDR2020 reproduction deck.pptx"
    D.prs.save(out)
    print("deck written to", out, "from", run.name)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
