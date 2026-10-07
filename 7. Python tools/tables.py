"""NHDR 2020 Statistical Annex Tables 1 to 8A, published against reproduced from microdata.

Reads the result tables the do file writes into a run folder and the published
tables in "6. Raw data/Published", and writes one workbook with a sheet per
annex table, a CSV per sheet and a summary of the largest gaps. Called by
"Build outputs.py"; on its own, from the package folder:

    python "7. Python tools/tables.py" "8. Stata runs/Run YYYYMMDD HHMMSS" "3. Tables"

Every reproduced cell is one of three kinds, and the workbook says which:
    reproduced   computed from the survey microdata in "6. Raw data"
    as printed   an input the microdata on disk cannot supply, carried from the
                 published table so that the index can still be computed
                 (grey italic in the workbook)
    external     a non-survey input taken from an official series (World Bank
                 WDI), as NHDR does (grey italic, marked in the notes)
    n.a.         not reproduced
"""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

ROOT = Path(__file__).resolve().parents[1]
PUB = ROOT / "6. Raw data" / "Published"
DOMAINS = ["Pakistan", "Pakistan-Urban", "Pakistan-Rural", "Punjab", "Punjab-Urban", "Punjab-Rural", "Sindh",
           "Sindh-Urban", "Sindh-Rural", "Khyber Pakhtunkhwa", "Khyber Pakhtunkhwa-Urban",
           "Khyber Pakhtunkhwa-Rural", "Balochistan", "Balochistan-Urban", "Balochistan-Rural"]
PROV5 = ["Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan"]


def nhdr_index(lit, ner, le, pci):
    e = (2 / 3) * lit / 100 + (1 / 3) * ner / 100
    h = (le - 25) / 65
    i = (np.log(pci) - np.log(100)) / (np.log(100000) - np.log(100))
    return e, h, i, (e * h * i) ** (1 / 3)


def status(v):
    return "Low" if v < 0.55 else ("Medium" if v < 0.7 else "High")


# Row 2 of each sheet: what the table shows and where its reproduced values come from.
ABOUT = {
    "Table 1": "Human Development Index (HDI) and its dimension indices (education, health, income) for Pakistan, "
               "the provinces, and their urban and rural parts, by income quintile. Reproduced from HIES 2005-06 "
               "and 2018-19 (literacy, enrolment, consumption) and PDHS 2006-07 and 2017-18 (child mortality, "
               "turned into life expectancy).",
    "Table 2A": "The four HDI indicators behind Table 1: adult literacy, net enrolment, life expectancy at birth and "
                "income per head, by region and income quintile.",
    "Table 3": "Inequality-adjusted Human Development Index (IHDI): the HDI discounted for inequality across income "
               "quintiles (Atkinson measure, epsilon = 1) in each dimension.",
    "Table 4": "Child Development Index (CDI) and its three sub-indices (living standard; education; health and "
               "nutrition), by region. Reproduced from HIES 2007-08 and 2018-19, LFS and PDHS microdata.",
    "Table 4A": "The eleven CDI indicators: income per child equivalent, children in the top two quintiles, child "
                "work, enrolment by level, education spending, immunization, stunting, wasting and under-five "
                "survival.",
    "Table 5": "Youth Development Index (YDI) for ages 15 to 29 and its five sub-indices (schooling, employment, "
               "higher education, full employment, survival). Reproduced from LFS 2017-18 and PMMS 2019.",
    "Table 5A": "The five YDI indicators: mean years of schooling, employment-to-population ratio, higher education "
                "attainment, full employment and youth survival.",
    "Table 6": "Gender Development Index (GDI): female HDI divided by male HDI, with the dimension indices by sex. "
               "Reproduced from HIES (education), LFS (earnings) and World Bank WDI (life expectancy by sex).",
    "Table 6A": "The GDI indicators by sex: adult literacy, net enrolment, life expectancy at birth and estimated "
                "earned income per head.",
    "Table 7": "Gender Inequality Index (GII): the loss from inequality between women and men in reproductive "
               "health, empowerment and the labour market (0 = equality).",
    "Table 7A": "The GII indicators: women without prenatal and postnatal care, women 15 to 19 ever married, "
                "women's seats in parliament, secondary education and labour force participation by sex.",
    "Table 8": "Labour Development Index (LDI) including decent work, and its five sub-indices. Reproduced from LFS "
               "2012-13 and 2017-18 with World Bank WDI GDP and Pasha's provincial GDP shares.",
    "Table 8A": "The LDI indicators: employment-to-population ratio, labour share of GDP, skill premium, human "
                "capital (years of schooling of workers) and incidence of decent work.",
}


class Sheet:
    """A long table: id columns, then for each quantity a (published, reproduced, flag) triple."""

    def __init__(self, name, title, ids, quantities, notes="", about=""):
        self.name, self.title, self.ids, self.q, self.notes = name, title, ids, quantities, notes
        self.about = about or ABOUT.get(name, "")
        self.rows = []

    def add(self, idvals, values):
        """values: {quantity: (published, reproduced, kind)}; kind in reproduced/as printed/n.a."""
        self.rows.append((idvals, values))

    def frame(self):
        recs = []
        for idv, vals in self.rows:
            r = dict(zip(self.ids, idv))
            for q, fmt, tol in self.q:
                p, m, k = vals.get(q, (np.nan, np.nan, "n.a."))
                r[f"{q}: published in NHDR 2020"] = p
                r[f"{q}: reproduced from microdata"] = m if k != "n.a." else np.nan
                r[f"{q}: difference, reproduced minus published"] = (m - p) if (k in ("reproduced", "external") and pd.notna(p) and pd.notna(m)) else np.nan
                r[f"{q}: basis of the reproduced value"] = k
            recs.append(r)
        return pd.DataFrame(recs)


HEAD = PatternFill("solid", fgColor="F36F25")   # NHDR 2020 orange
SUB = PatternFill("solid", fgColor="F3E9E0")    # NHDR 2020 beige
BAND = PatternFill("solid", fgColor="FBF6F1")
GAP = PatternFill("solid", fgColor="FCE4D6")
EDGE = Side(style="thin", color="D5BEAB")
BOX = Border(left=EDGE, right=EDGE, top=EDGE, bottom=EDGE)


def write_sheet(wb, sh):
    ws = wb.create_sheet(sh.name)
    ws["A1"] = sh.title
    ws["A1"].font = Font(name="Arial", bold=True, size=11, color="EF4429")
    ws["A2"] = sh.about
    ws["A2"].font = Font(name="Arial", size=9, color="333333")
    if sh.notes:
        ws["A3"] = "Note: " + sh.notes
        ws["A3"].font = Font(name="Arial", italic=True, size=8, color="555555")
    r0 = 5
    col = 1
    for name in sh.ids:
        c = ws.cell(row=r0, column=col, value=name)
        ws.merge_cells(start_row=r0, start_column=col, end_row=r0 + 1, end_column=col)
        col += 1
    for q, fmt, tol in sh.q:
        ws.cell(row=r0, column=col, value=q)
        ws.merge_cells(start_row=r0, start_column=col, end_row=r0, end_column=col + 2)
        for j, lab in enumerate(["Published in NHDR 2020", "Reproduced from microdata",
                                 "Difference (reproduced minus published)"]):
            ws.cell(row=r0 + 1, column=col + j, value=lab)
        col += 3
    for rr in (r0, r0 + 1):
        for c in range(1, col):
            cell = ws.cell(row=rr, column=c)
            cell.fill = HEAD if rr == r0 else SUB
            cell.font = Font(name="Arial", bold=True, size=8, color="FFFFFF" if rr == r0 else "58595B")
            cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
            cell.border = BOX
    r = r0 + 2
    for idv, vals in sh.rows:
        total = any(str(v) in ("All", "Pakistan") for v in idv[:2]) and "Q" not in str(idv)
        for c, v in enumerate(idv, start=1):
            cell = ws.cell(row=r, column=c, value=v)
            cell.font = Font(name="Arial", size=8, bold=total)
            cell.border = BOX
        c = len(idv) + 1
        for q, fmt, tol in sh.q:
            p, m, k = vals.get(q, (np.nan, np.nan, "n.a."))
            cells = [p, m if k != "n.a." else "n.a.",
                     (m - p) if (k in ("reproduced", "external") and pd.notna(p) and pd.notna(m)) else None]
            for j, v in enumerate(cells):
                v = None if (isinstance(v, float) and np.isnan(v)) else v
                cell = ws.cell(row=r, column=c + j, value=v)
                cell.font = Font(name="Arial", size=8)
                cell.border = BOX
                if isinstance(v, (int, float)):
                    cell.number_format = fmt
                if j == 1 and k in ("as printed", "external"):
                    cell.font = Font(name="Arial", size=8, italic=True, color="808080")
                if j == 1 and k == "n.a.":
                    cell.font = Font(name="Arial", size=8, italic=True, color="A0A0A0")
                    cell.alignment = Alignment(horizontal="center")
                if j == 2 and v is not None and abs(v) > tol:
                    cell.fill = GAP
            c += 3
        r += 1
    ws.freeze_panes = ws.cell(row=r0 + 2, column=len(sh.ids) + 1)
    for c in range(1, col):
        ws.column_dimensions[get_column_letter(c)].width = 22 if c <= len(sh.ids) else 12
    ws.row_dimensions[r0].height = 30
    ws.row_dimensions[r0 + 1].height = 34


def build(run):
    run = Path(run)
    H = pd.read_csv(run / "HDI all microdata.csv")
    I = pd.read_csv(run / "IHDI all microdata.csv")
    t1 = pd.read_csv(PUB / "NHDR2020 Table 1.csv").set_index("region")
    t2 = pd.read_csv(PUB / "NHDR2020 Table 2A.csv")
    t3 = pd.read_csv(PUB / "NHDR2020 Table 3.csv").set_index("region")
    t4 = pd.read_csv(PUB / "NHDR2020 Table 4.csv")
    t5 = pd.read_csv(PUB / "NHDR2020 Table 5.csv")
    t6 = pd.read_csv(PUB / "NHDR2020 Table 6.csv")
    t7 = pd.read_csv(PUB / "NHDR2020 Table 7.csv")
    t8 = pd.read_csv(PUB / "NHDR2020 Table 8.csv")
    sheets = []
    years = [("2006-07", "2006_07"), ("2018-19", "2018_19")]

    # ---- Table 1 --------------------------------------------------------------------------
    s = Sheet("Table 1", "Table 1. Human Development Index and its sub-indices, 2006-07 and 2018-19",
              ["Region", "Quintile", "Year"],
              [("Adult literacy index", "0.000", 0.01), ("Net enrolment index", "0.000", 0.01),
               ("Education index", "0.000", 0.01), ("Health index", "0.000", 0.01),
               ("Income index", "0.000", 0.01), ("HDI", "0.000", 0.01)],
              "Published domain rows are Table 1 as printed. Published quintile rows are Table 2A pushed through "
              "NHDR's construction, which reproduces every printed Table 1 value to within 0.0011.")
    for d in DOMAINS:
        for q in ["All", "Q1", "Q2", "Q3", "Q4", "Q5"]:
            for yr, yk in years:
                h = H[(H.year == yr) & (H.domain == d) & (H.quintile == q)].iloc[0]
                if q == "All":
                    p = t1.loc[d]
                    pub = [p[f"lit_idx_{yk}"], p[f"ner_idx_{yk}"], p[f"edu_idx_{yk}"], p[f"health_idx_{yk}"],
                           p[f"income_idx_{yk}"], p[f"hdi_{yk}"]]
                else:
                    pub = [h.lit_pub / 100, h.ner_pub / 100, h.p_education_index, h.p_health_index,
                           h.p_income_index, h.p_hdi]
                rep = [h.lit_reproduced / 100, h.ner_reproduced / 100, h.m_education_index, h.m_health_index,
                       h.m_income_index, h.hdi_ehi]
                s.add([d, q, yr], {n: (a, b, "reproduced") for (n, _, _), a, b in zip(s.q, pub, rep)})
    sheets.append(s)

    # ---- Table 2A -------------------------------------------------------------------------
    s = Sheet("Table 2A", "Table 2A. HDI indicator values, 2006-07 and 2018-19",
              ["Region", "Quintile", "Year"],
              [("Adult literacy rate (%)", "0.0", 1.0), ("Net enrolment rate (%)", "0.0", 1.0),
               ("Life expectancy at birth (years)", "0.0", 1.0), ("Per capita income (PPP $)", "#,##0", 250),
               ("PDHS births in the ten-year window", "#,##0", 1e12)],
              "Life expectancy: PDHS under-five mortality, ten years, Coale-Demeny West. Income: HIES consumption "
              "per head scaled so that Pakistan equals the WDI GNI per head in PPP dollars, fiscal-year average "
              "(external; 4,925 for 2018-19 against NHDR's 4,922, and 3,350 for 2006-07 against 4,135). "
              "Quintile rows of life expectancy use the PDHS wealth quintile.")
    for d in DOMAINS:
        for q in ["All", "Q1", "Q2", "Q3", "Q4", "Q5"]:
            for yr, yk in years:
                h = H[(H.year == yr) & (H.domain == d) & (H.quintile == q)].iloc[0]
                s.add([d, q, yr], {
                    "Adult literacy rate (%)": (h.lit_pub, h.lit_reproduced, "reproduced"),
                    "Net enrolment rate (%)": (h.ner_pub, h.ner_reproduced, "reproduced"),
                    "Life expectancy at birth (years)": (h.le_pub, h.le_pdhs, "reproduced"),
                    "Per capita income (PPP $)": (h.pci_pub, h.pci_micro,
                                                  "external" if (d == "Pakistan" and q == "All") else "reproduced"),
                    "PDHS births in the ten-year window": (np.nan, h.births, "reproduced")})
    sheets.append(s)

    # ---- Table 3 --------------------------------------------------------------------------
    s = Sheet("Table 3", "Table 3. Inequality-adjusted Human Development Index, 2006-07 and 2018-19",
              ["Region", "Year"],
              [("HDI", "0.000", 0.01), ("IHDI", "0.000", 0.01), ("Coefficient of human inequality (%)", "0.00", 0.5),
               ("Overall loss (%)", "0.00", 0.5), ("Inequality in education", "0.000", 0.01),
               ("Inequality in health", "0.0000", 0.001), ("Inequality in income", "0.000", 0.01)])
    for d in PROV5:
        for yr, yk in years:
            m = I[(I.year == yr) & (I.domain == d)].iloc[0]
            p = t3.loc[d]
            s.add([d, yr], {
                "HDI": (p[f"pub_hdi_{yk}"], m.hdi_ehi, "reproduced"),
                "IHDI": (p[f"pub_ihdi_{yk}"], m.ihdi_m, "reproduced"),
                "Coefficient of human inequality (%)": (p[f"pub_chi_{yk}"], m.chi_m, "reproduced"),
                "Overall loss (%)": (p[f"pub_loss_{yk}"], m.loss_m, "reproduced"),
                "Inequality in education": (p[f"pub_aedu_{yk}"], m.a_edu_m, "reproduced"),
                "Inequality in health": (p[f"pub_ahealth_{yk}"], m.a_health_m, "reproduced"),
                "Inequality in income": (p[f"pub_ainc_{yk}"], m.a_inc_m, "reproduced")})
    sheets.append(s)

    # ---- Tables 4 and 4A ------------------------------------------------------------------
    C = pd.read_csv(run / "CDI reproduced PDHS.csv")
    q4 = [("Living standard index", "0.000", 0.01), ("Education index", "0.000", 0.01),
          ("Health and nutrition index", "0.000", 0.01), ("CDI", "0.000", 0.01)]
    q4a = [("Income per child equivalent (real Rs)", "#,##0", 50), ("Children in top two quintiles (%)", "0.0", 1),
           ("Children 10-14 not working (%)", "0.0", 1), ("Net enrolment, primary (%)", "0", 1),
           ("Net enrolment, middle (%)", "0", 1), ("Net enrolment, matric (%)", "0", 1),
           ("Education spending per child equivalent", "0.0", 1), ("Fully immunized 12-23 months (%)", "0", 1),
           ("Children not stunted (%)", "0.0", 1), ("Children not wasted (%)", "0.0", 1),
           ("Under-five survival", "0.000", 0.0015)]
    s4 = Sheet("Table 4", "Table 4. Child Development Index and its sub-indices, 2007-08 and 2018-19",
               ["Region", "Sex", "Year"], q4, "The CDI is reproduced for both sexes together. Rows by sex are n.a.")
    s4a = Sheet("Table 4A", "Table 4A. Child Development Index indicator values, 2007-08 and 2018-19",
                ["Region", "Sex", "Year"], q4a,
                "2007-08: child work (LFS 2007-08) and stunting and wasting (PDHS 2006-07 did not measure "
                "children) are carried as printed. Immunization 2007-08 is from HIES 2007-08; NHDR used PSLM "
                "2007-08, which is not in 6. Raw data.")
    for _, p in t4.iterrows():
        c = C[(C.region == p.region) & (C.year == p.year)] if p.sex == "All" else C.iloc[0:0]
        if len(c):
            c = c.iloc[0]
            y07 = p.year == "2007-08"
            s4.add([p.region, p.sex, p.year], {
                "Living standard index": (p.pub_sl_idx, c.h_sl, "reproduced"),
                "Education index": (p.pub_edu_idx, c.h_edu, "reproduced"),
                "Health and nutrition index": (p.pub_health_idx, c.h_hea, "reproduced"),
                "CDI": (p.pub_cdi, c.h_cdi, "reproduced")})
            s4a.add([p.region, p.sex, p.year], {
                q4a[0][0]: (p.income_pce, c.income_pce, "reproduced"),
                q4a[1][0]: (p.top2, c.top2, "reproduced"),
                q4a[2][0]: (p.notwork, c.notwork, "as printed" if y07 else "reproduced"),
                q4a[3][0]: (p.ner_p, c.ner_p, "reproduced"),
                q4a[4][0]: (p.ner_m, c.ner_m, "reproduced"),
                q4a[5][0]: (p.ner_x, c.ner_x, "reproduced"),
                q4a[6][0]: (p.eec, c.eec, "reproduced"),
                q4a[7][0]: (p.immun, c.immun, "reproduced"),
                q4a[8][0]: (p.notstunted, c.nst_h, "as printed" if y07 else "reproduced"),
                q4a[9][0]: (p.notwasted, c.nwa_h, "as printed" if y07 else "reproduced"),
                q4a[10][0]: (p.survival, c.surv_h, "reproduced")})
        else:
            s4.add([p.region, p.sex, p.year], {
                "Living standard index": (p.pub_sl_idx, np.nan, "n.a."), "Education index": (p.pub_edu_idx, np.nan, "n.a."),
                "Health and nutrition index": (p.pub_health_idx, np.nan, "n.a."), "CDI": (p.pub_cdi, np.nan, "n.a.")})
            vals = [p.income_pce, p.top2, p.notwork, p.ner_p, p.ner_m, p.ner_x, p.eec, p.immun, p.notstunted,
                    p.notwasted, p.survival]
            s4a.add([p.region, p.sex, p.year], {n: (v, np.nan, "n.a.") for (n, _, _), v in zip(q4a, vals)})
    sheets += [s4, s4a]

    # ---- Tables 5 and 5A ------------------------------------------------------------------
    Y = pd.read_csv(run / "YDI 2017-18 2024-25.csv")
    P = pd.read_csv(run / "YDI survival PMMS 2019.csv").set_index("region")
    q5 = [("Years of schooling index", "0.000", 0.01), ("Employment-to-population index", "0.000", 0.01),
          ("Higher education index", "0.000", 0.01), ("Fully employed index", "0.000", 0.01),
          ("Youth survival index", "0.000", 0.05), ("YDI", "0.000", 0.01)]
    q5a = [("Mean years of schooling", "0.00", 0.1), ("Employment to population (%)", "0.00", 1),
           ("Higher education attainment (%)", "0.00", 1), ("Fully employed (%)", "0.00", 1),
           ("Youth survival", "0.0000", 0.0002)]
    s5 = Sheet("Table 5", "Table 5. Youth Development Index and its sub-indices, 2001-02 and 2017-18",
               ["Region", "Year"], q5,
               "Survival is PMMS 2019 reproduced from the household roster and deaths files. The YDI is the mean of "
               "the five indices with survival goalposts 0.9970 to 0.9999. 2001-02: LFS 2001-02 is not in 6. Raw data.")
    s5a = Sheet("Table 5A", "Table 5A. Youth Development Index indicator values, 2001-02 and 2017-18",
                ["Region", "Year"], q5a)
    for _, p in t5.iterrows():
        if p.year == "2017-18":
            y = Y[(Y.region == p.region) & (Y.year == "2017-18")].iloc[0]
            sv = P.loc[p.region, "survival_pmms"]
            isv = (sv - 0.9970) / (0.9999 - 0.9970)
            ydi = (y.r_i_mys + y.r_i_epr + y.r_i_hied + y.r_i_full + isv) / 5
            s5.add([p.region, p.year], {
                q5[0][0]: (p.pub_mys_idx, y.r_i_mys, "reproduced"), q5[1][0]: (p.pub_epr_idx, y.r_i_epr, "reproduced"),
                q5[2][0]: (p.pub_hied_idx, y.r_i_hied, "reproduced"), q5[3][0]: (p.pub_full_idx, y.r_i_full, "reproduced"),
                q5[4][0]: (p.pub_surv_idx, isv, "reproduced"), q5[5][0]: (p.pub_ydi, ydi, "reproduced")})
            s5a.add([p.region, p.year], {
                q5a[0][0]: (p.mys, y.mys, "reproduced"), q5a[1][0]: (p.epr, y.epr, "reproduced"),
                q5a[2][0]: (p.hied, y.hied, "reproduced"), q5a[3][0]: (p.fullemp, y.fullemp, "reproduced"),
                q5a[4][0]: (p.survival, sv, "reproduced")})
        else:
            s5.add([p.region, p.year], {n: (v, np.nan, "n.a.") for (n, _, _), v in
                                        zip(q5, [p.pub_mys_idx, p.pub_epr_idx, p.pub_hied_idx, p.pub_full_idx,
                                                 p.pub_surv_idx, p.pub_ydi])})
            s5a.add([p.region, p.year], {n: (v, np.nan, "n.a.") for (n, _, _), v in
                                         zip(q5a, [p.mys, p.epr, p.hied, p.fullemp, p.survival])})
    sheets += [s5, s5a]

    # ---- Tables 6 and 6A ------------------------------------------------------------------
    SG = pd.read_csv(run / "Series GDI Pakistan.csv")
    q6 = [("Education index", "0.000", 0.01), ("Life expectancy index", "0.000", 0.01),
          ("Income index", "0.000", 0.01), ("HDI by sex", "0.000", 0.01), ("GDI", "0.000", 0.01)]
    q6a = [("Adult literacy rate (%)", "0.0", 1), ("Net enrolment rate (%)", "0.0", 1),
           ("Life expectancy at birth (years)", "0.0", 1), ("Estimated earned income (PPP $)", "#,##0", 250)]
    s6 = Sheet("Table 6", "Table 6. Gender Development Index, 2006-07 and 2018-19", ["Sex", "Year"], q6,
               "Education by sex: HIES 2005-06 and 2018-19. Earned income by sex: UNDP split on LFS 2006-07 and "
               "2018-19 wages, WDI GNI per head (PPP) and the Census 2017 female share. Life expectancy by sex: "
               "WDI (external), because NHDR's UNDP values exist for its two printed years only.")
    s6a = Sheet("Table 6A", "Table 6A. Gender Development Index indicator values, 2006-07 and 2018-19",
                ["Sex", "Year"], q6a)
    for _, p in t6.iterrows():
        yr = p.year.replace("_", "-")
        g = SG[(SG.year == yr) & (SG.sexname == p.sex)].iloc[0]
        s6.add([p.sex, yr], {q6[0][0]: (p.pub_edu_idx, g.g_edu, "reproduced"),
                             q6[1][0]: (p.pub_le_idx, g.g_hea, "external"),
                             q6[2][0]: (p.pub_inc_idx, g.g_inc, "reproduced"),
                             q6[3][0]: (p.pub_hdi, g.g_hdi, "reproduced"),
                             q6[4][0]: (p.pub_gdi, g.gdi, "reproduced")})
        s6a.add([p.sex, yr], {q6a[0][0]: (p.lit, g.lit15, "reproduced"), q6a[1][0]: (p.ner, g.ner, "reproduced"),
                              q6a[2][0]: (p["le"], g.le_sex, "external"), q6a[3][0]: (p.pci, g.pci_sex, "reproduced")})
    sheets += [s6, s6a]

    # ---- Tables 7 and 7A ------------------------------------------------------------------
    M = pd.read_csv(run / "GII 2018-19 all microdata.csv").set_index("domain")
    M6 = pd.read_csv(run / "GII 2006-07 reproduced.csv").set_index("domain")
    SI = pd.read_csv(run / "Series GII Pakistan.csv")
    q7 = [("Female health", "0.000", 0.01), ("Female empowerment", "0.000", 0.01),
          ("Male empowerment", "0.000", 0.01), ("GII", "0.000", 0.01)]
    q7a = [("Without prenatal and postnatal care (%)", "0.0", 1), ("Women 15-19 ever married (%)", "0.0", 1),
           ("Seats in parliament, female (%)", "0.0", 0.1), ("Secondary education, female (%)", "0", 1),
           ("Secondary education, male (%)", "0", 1), ("Labour force participation, female (%)", "0.0", 1),
           ("Labour force participation, male (%)", "0.0", 1)]
    s7 = Sheet("Table 7", "Table 7. Gender Inequality Index, 2006-07 and 2018-19", ["Region", "Year"], q7,
               "Pakistan: care and schooling HIES 2005-06 and 2018-19; early marriage and participation LFS 2006-07 "
               "and 2017-18 (NHDR's labour year); seats WDI SG.GEN.PARL.ZS (external), which equals NHDR's values. "
               "Provinces 2006-07: early marriage and participation carried as printed (provincial codes of LFS "
               "2006-07 not established); provinces 2018-19 as Pakistan, with seats as printed.")
    s7a = Sheet("Table 7A", "Table 7A. Gender Inequality Index indicator values, 2006-07 and 2018-19",
                ["Region", "Year"], q7a)
    for _, p in t7.iterrows():
        yr = p.year.replace("_", "-")
        if p.region == "Pakistan":
            g = SI[SI.year == yr].iloc[0]
            s7.add([p.region, yr], {q7[0][0]: (np.nan, g.s_health_f, "reproduced"),
                                    q7[1][0]: (np.nan, g.s_emp_f, "reproduced"),
                                    q7[2][0]: (np.nan, g.s_emp_m, "reproduced"),
                                    q7[3][0]: (p.pub_gii, g.s_gii, "reproduced")})
            s7a.add([p.region, yr], {q7a[0][0]: (p.no_care_f, g.no_care, "reproduced"),
                                     q7a[1][0]: (p.evm1519_f, g.evm1519, "reproduced"),
                                     q7a[2][0]: (p.seats_f, g.seats_f, "external"),
                                     q7a[3][0]: (p.sec_f, g.sec_f, "reproduced"),
                                     q7a[4][0]: (p.sec_m, g.sec_m, "reproduced"),
                                     q7a[5][0]: (p.lfpr_f, g.lfpr_f, "reproduced"),
                                     q7a[6][0]: (p.lfpr_m, g.lfpr_m, "reproduced")})
        elif p.year == "2018_19":
            m = M.loc[p.region]
            s7.add([p.region, yr], {q7[0][0]: (np.nan, m.m_health_f, "reproduced"),
                                    q7[1][0]: (np.nan, m.m_emp_f, "reproduced"),
                                    q7[2][0]: (np.nan, m.m_emp_m, "reproduced"),
                                    q7[3][0]: (p.pub_gii, m.m_gii, "reproduced")})
            s7a.add([p.region, yr], {q7a[0][0]: (p.no_care_f, m.raw_no_care_f, "reproduced"),
                                     q7a[1][0]: (p.evm1519_f, m.evm1519_f_1718, "reproduced"),
                                     q7a[2][0]: (p.seats_f, m.seats_f, "as printed"),
                                     q7a[3][0]: (p.sec_f, m.raw_sec_f, "reproduced"),
                                     q7a[4][0]: (p.sec_m, m.raw_sec_m, "reproduced"),
                                     q7a[5][0]: (p.lfpr_f, m.lfpr_f_1718, "reproduced"),
                                     q7a[6][0]: (p.lfpr_m, m.lfpr_m_1718, "reproduced")})
        else:
            m = M6.loc[p.region]
            s7.add([p.region, yr], {q7[0][0]: (np.nan, m.r_health_f, "reproduced"),
                                    q7[1][0]: (np.nan, m.r_emp_f, "reproduced"),
                                    q7[2][0]: (np.nan, m.r_emp_m, "reproduced"),
                                    q7[3][0]: (p.pub_gii, m.r_gii, "reproduced")})
            s7a.add([p.region, yr], {q7a[0][0]: (p.no_care_f, m.raw_no_care_f, "reproduced"),
                                     q7a[1][0]: (p.evm1519_f, m.evm1519_f, "as printed"),
                                     q7a[2][0]: (p.seats_f, m.seats_f, "as printed"),
                                     q7a[3][0]: (p.sec_f, m.raw_sec_f, "reproduced"),
                                     q7a[4][0]: (p.sec_m, m.raw_sec_m, "reproduced"),
                                     q7a[5][0]: (p.lfpr_f, m.lfpr_f, "as printed"),
                                     q7a[6][0]: (p.lfpr_m, m.lfpr_m, "as printed")})
    sheets += [s7, s7a]

    # ---- Tables 8 and 8A ------------------------------------------------------------------
    L = pd.read_csv(run / "LDI 2012-13 2017-18 2024-25.csv")
    q8 = [("Employment-to-population index", "0.000", 0.01), ("Labour share index", "0.000", 0.01),
          ("Skill premium index", "0.000", 0.01), ("Human capital index", "0.000", 0.01),
          ("Decent work index", "0.000", 0.01), ("LDI with decent work", "0.000", 0.01)]
    q8a = [("Employment to population", "0.000", 0.01), ("Labour share of GDP", "0.00", 0.02),
           ("Skill premium", "0.00", 0.1), ("Human capital (years)", "0.00", 0.1),
           ("Incidence of decent work", "0.00", 1)]
    s8 = Sheet("Table 8", "Table 8. Labour Development Index including decent work, 2012-13 and 2017-18",
               ["Region", "Year"], q8, "GDP: WDI current-price series (2015-16 base). NHDR's labour share implies "
               "the pre-2017 (2005-06 base) GDP level.")
    s8a = Sheet("Table 8A", "Table 8A. Labour Development Index indicator values, 2012-13 and 2017-18",
                ["Region", "Year"], q8a)
    for _, p in t8.iterrows():
        l = L[(L.region == p.region) & (L.year == p.year)].iloc[0]
        s8.add([p.region, p.year], {q8[0][0]: (p.pub_epr_idx, l.r_i_ep, "reproduced"),
                                    q8[1][0]: (p.pub_lshare_idx, l.r_i_ls, "reproduced"),
                                    q8[2][0]: (p.pub_sp_idx, l.r_i_sp, "reproduced"),
                                    q8[3][0]: (p.pub_hc_idx, l.r_i_hc, "reproduced"),
                                    q8[4][0]: (p.pub_dw_idx, l.r_i_dw, "reproduced"),
                                    q8[5][0]: (p.pub_ldidw, l.r_ldidw, "reproduced")})
        s8a.add([p.region, p.year], {q8a[0][0]: (p.epr, l.epr, "reproduced"), q8a[1][0]: (p.lshare, l.lshare, "reproduced"),
                                     q8a[2][0]: (p.skillprem, l.skillprem, "reproduced"),
                                     q8a[3][0]: (p.humcap, l.humcap, "reproduced"),
                                     q8a[4][0]: (p.decentwork, l.decentwork, "reproduced")})
    sheets += [s8, s8a]
    return sheets


def main(run, outdir):
    run = Path(run)
    if not run.is_absolute():
        run = ROOT / run
    out = Path(outdir)
    (out / "CSV").mkdir(parents=True, exist_ok=True)
    sheets = build(run)
    wb = Workbook()
    ws = wb.active
    ws.title = "Read me"
    lines = ["NHDR 2020 Statistical Annex Tables 1 to 8A: published against reproduced from microdata",
             f"Reproduced values: {run.name} of NHDR2020 reproduction from microdata.do (folder 1. Dos).",
             "Each sheet opens with the table title (row 1), a one-line description of what it shows and "
             "where the reproduced values come from (row 2), and any caveat (row 3).",
             "",
             "Each quantity has three columns: Published (NHDR 2020, as printed), Reproduced, and Difference "
             "(reproduced minus published).",
             "Grey italic in a Reproduced column: an input the microdata on disk cannot supply, carried as printed.",
             "n.a.: not reproduced. Shaded Difference: larger than the tolerance stated for that quantity.",
             "Life expectancy: PDHS under-five mortality (DHS synthetic cohort, ten years) through the "
             "Coale-Demeny West model life table. NHDR does not name its life table.",
             "Income per head: HIES consumption per head, scaled so that Pakistan equals the World Bank WDI "
             "gross national income per head in PPP dollars (NY.GNP.PCAP.PP.CD), fiscal-year average.",
             "The CSV folder holds the same tables, one file per sheet. Each quantity has four columns there: "
             "published in NHDR 2020, reproduced from microdata, difference (reproduced minus published), and the "
             "basis of the reproduced value (reproduced, as printed, external or n.a.)."]
    for k, ln in enumerate(lines, start=1):
        ws.cell(row=k, column=1, value=ln).font = Font(name="Arial", size=9, bold=(k == 1))
    ws.column_dimensions["A"].width = 120
    summary = {}
    for sh in sheets:
        write_sheet(wb, sh)
        df = sh.frame()
        df.to_csv(out / "CSV" / f"{sh.name}.csv", index=False)
        summary[sh.name] = {}
        for q, fmt, tol in sh.q:
            d = df[f"{q}: difference, reproduced minus published"].abs()
            if d.notna().any():
                i = d.idxmax()
                summary[sh.name][q] = {"max_abs_diff": round(float(d.max()), 4),
                                       "where": " / ".join(str(df.loc[i, c]) for c in sh.ids),
                                       "median_abs_diff": round(float(d.median()), 4),
                                       "n": int(d.notna().sum()), "n_over_tol": int((d > tol).sum())}
    wb.save(out / "NHDR2020 annex tables published vs reproduced.xlsx")
    json.dump(summary, open(out / "Gap summary.json", "w"), indent=1)
    print("written", out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
