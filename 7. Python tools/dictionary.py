"""Write the variable dictionary and the output descriptions for the results workbook.

    python "7. Python tools/dictionary.py"

Writes two files into "1. Dos", both read by Section 27.2 of the do file:
    Variable dictionary.csv   File, Variable, Label: a descriptive name (80 characters
                              at most, Stata's limit for a variable label) for every
                              column of every result table in the workbook
    Output descriptions.csv   File, Sheet, Headline: the worksheet name and the one-line
                              description printed at the top of each worksheet

The labels are written here once, by hand, from the code that creates each
variable; the rules below only spell out year suffixes and prefixes that mean
the same thing everywhere (pub_ = as printed in NHDR 2020, and so on).
Run with a run folder as argument to list any column that has no label yet:
    python "7. Python tools/dictionary.py" "8. Stata runs/Run YYYYMMDD HHMMSS"
"""
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOS = ROOT / "1. Dos"

# ---------------------------------------------------------------------------------------------
# Worksheets: file stem, sheet name (31 characters at most), headline.
# ---------------------------------------------------------------------------------------------
SHEETS = [
    ("HDI all microdata", "HDI from microdata",
     "Human Development Index (HDI), NHDR 2020 Table 1 construction, 2006-07 and 2018-19, by region and income "
     "quintile: published values beside values reproduced from HIES and PDHS microdata."),
    ("Table 2A education replication 2018-19", "Education 2018-19",
     "Adult literacy (15+) and net enrolment (5-14), HIES 2018-19, against NHDR 2020 Table 2A, by region and "
     "income quintile."),
    ("Table 2A education replication 2006-07", "Education 2006-07",
     "Adult literacy (15+) and net enrolment (5-14), HIES 2005-06 (NHDR's 2006-07), against NHDR 2020 Table 2A."),
    ("UNDP index validation", "HDI construction check",
     "Each published dimension index of NHDR 2020 Table 1 recomputed from the Table 2A indicators with the "
     "NHDR construction, to confirm the goalposts."),
    ("Life expectancy inversion", "Life expectancy recovered",
     "Life expectancy recovered from NHDR's published health index (25 to 90 years goalposts), and the under-five "
     "mortality it implies under two model life table families."),
    ("Provincial mortality MICS6", "Child mortality MICS6 province",
     "Under-five mortality from the MICS6 birth histories, ten years before each survey, by province, and the "
     "life expectancy it implies."),
    ("Divisional mortality MICS6", "Child mortality MICS6 division",
     "Under-five mortality from the MICS6 birth histories, ten years before each survey, by division."),
    ("District mortality MICS6", "Child mortality MICS6 district",
     "Under-five mortality from the MICS6 birth histories, ten years before each survey, by district, with flags "
     "for implausibly low or thin estimates."),
    ("PDHS under5 mortality", "Child mortality PDHS",
     "Under-five mortality from the PDHS birth histories (DHS synthetic cohort method), 2006-07, 2012-13 and "
     "2017-18, by region and sex, five and ten years before each survey."),
    ("PDHS anthropometry", "Stunting and wasting PDHS",
     "Stunting and wasting of children under five, PDHS 2012-13 and 2017-18 (WHO 2006 standards), by region and "
     "sex."),
    ("PDHS CDI health inputs", "CDI health inputs PDHS",
     "Child Development Index (CDI) health inputs from PDHS microdata: under-five survival, children not stunted "
     "and not wasted, by region and sex."),
    ("PDHS wealth quintile mortality", "Child mortality by wealth PDHS",
     "Under-five mortality and implied life expectancy by PDHS household wealth quintile, 2006-07 and 2017-18."),
    ("GRP coverage by status 2018-19", "GRP coverage",
     "Gross regional product (GRP) 2018-19: share of national value added whose provincial split comes from an "
     "obtained allocator, a substitute, or none."),
    ("GRP allocator shares 2018-19", "GRP allocator shares",
     "Gross regional product 2018-19: provincial shares (%) of each national accounts sub-sector, from the "
     "allocator used for it."),
    ("GRP source comparison 2018-19", "GRP four estimates",
     "Provincial shares (%) of GDP: this reproduction against KP Bureau of Statistics (2021), Pasha (2021) and "
     "PIDE (2022)."),
    ("GRP per capita 2018-19", "GRP per head",
     "Gross regional product per head in PPP dollars, 2018-19, relative to Pakistan, against NHDR's relative "
     "income."),
    ("Income level diagnosis", "Income level",
     "What NHDR's provincial income column tracks: provincial income relative to Pakistan under five candidate "
     "measures."),
    ("Income quintile diagnosis", "Income quintiles",
     "Largest gap between NHDR's quintile income ratios and the microdata ratios, with quintiles ranked on "
     "expenditure or on income."),
    ("Provincial index 2024-25 survey basis", "HDI 2024-25 survey basis",
     "HDI 2024-25 with every input as the surveys report it (HIES 2024-25, MICS6 or PDHS mortality), beside the "
     "published 2018-19 values."),
    ("Provincial index 2024-25 final", "HDI 2024-25",
     "HDI 2024-25 on one instrument and one price basis with the 2018-19 index, by region."),
    ("Decomposition final", "HDI change 2018-24 by dimension",
     "Change in the HDI from 2018-19 to 2024-25 split into education, health and income contributions (percent "
     "of the 2018-19 level)."),
    ("Chain consistency sensitivity", "HDI pace and sensitivity",
     "Pace of HDI improvement (index points per thousand a year), 2006-07 to 2018-19 and 2018-19 to 2024-25, "
     "and the effect of changing survey instrument."),
    ("District education 2019-20", "District education 2019-20",
     "Adult literacy and net enrolment by district, PSLM 2019-20, with standard errors."),
    ("District index", "District HDI",
     "District Human Development Index, NHDR 2020 construction, PSLM 2019-20 education, MICS6 mortality and HIES "
     "income, ranked."),
    ("Divisional index", "Divisional HDI",
     "Divisional Human Development Index, NHDR 2020 construction, population-weighted from districts."),
    ("IHDI method Table 3", "IHDI method check",
     "Inequality-adjusted HDI (IHDI): NHDR 2020 Table 3 recomputed from the published quintile values, to "
     "confirm the method (Atkinson, epsilon = 1)."),
    ("IHDI 2018-19 microdata", "IHDI 2018-19 microdata",
     "Inequality-adjusted HDI 2018-19 with the inequality terms computed from HIES 2018-19 and MICS6 microdata."),
    ("IHDI 2018-19 PDHS", "IHDI 2018-19 PDHS",
     "Inequality-adjusted HDI 2018-19 with the health inequality term from PDHS 2017-18 wealth quintiles."),
    ("IHDI 2006-07 microdata", "IHDI 2006-07 microdata",
     "Inequality-adjusted HDI 2006-07 with the inequality terms computed from HIES 2005-06 microdata."),
    ("IHDI 2006-07 PDHS", "IHDI 2006-07 PDHS",
     "Inequality-adjusted HDI 2006-07 with the health inequality term from PDHS 2006-07 wealth quintiles."),
    ("IHDI all microdata", "IHDI from microdata",
     "Inequality-adjusted HDI, 2006-07 and 2018-19, every dimension and inequality term from the microdata, "
     "against NHDR 2020 Table 3."),
    ("IHDI 2024-25", "IHDI 2024-25",
     "Inequality-adjusted HDI 2024-25 from HIES 2024-25, beside 2018-19 on the same basis."),
    ("GDI method Table 6", "GDI method check",
     "Gender Development Index (GDI): NHDR 2020 Table 6 recomputed from the published Table 6A indicators."),
    ("GDI 2006-07 reproduced", "GDI 2006-07",
     "Gender Development Index 2006-07 with education by sex reproduced from HIES 2005-06."),
    ("GDI reproduced 2018-19 2024-25", "GDI 2018-19 and 2024-25",
     "Gender Development Index 2018-19 and 2024-25 reproduced from HIES and LFS microdata, by region and sex."),
    ("GII method Table 7", "GII method check",
     "Gender Inequality Index (GII): NHDR 2020 Table 7 recomputed from the published Table 7A indicators."),
    ("GII 2006-07 reproduced", "GII 2006-07",
     "Gender Inequality Index 2006-07 with care and schooling reproduced from HIES 2005-06."),
    ("GII 2018-19 reproduced", "GII 2018-19",
     "Gender Inequality Index 2018-19 on reproduced inputs, and the effect of swapping each reproduced input into "
     "NHDR's printed set."),
    ("GII 2018-19 all microdata", "GII 2018-19 all microdata",
     "Gender Inequality Index 2018-19 with every input from microdata: HIES 2018-19 care and schooling, LFS "
     "2017-18 early marriage and participation."),
    ("GII 2024-25", "GII 2024-25",
     "Gender Inequality Index 2024-25 from HIES 2024-25 and LFS 2024-25, beside 2018-19."),
    ("LFS 2017-18 participation", "LFS 2017-18 participation",
     "Labour force participation by sex and women 15-19 ever married, LFS 2017-18, against NHDR's 2018-19 "
     "column (Table 7A)."),
    ("CDI method Table 4", "CDI method check",
     "Child Development Index (CDI): NHDR 2020 Table 4 recomputed from the published Table 4A indicators."),
    ("CDI reproduced 2007-08 2018-19", "CDI 2007-08 and 2018-19",
     "Child Development Index 2007-08 and 2018-19 reproduced from HIES, LFS and PSLM microdata, against NHDR "
     "Tables 4 and 4A."),
    ("CDI reproduced PDHS", "CDI with PDHS inputs",
     "Child Development Index 2007-08 and 2018-19 with survival, stunting and wasting taken from PDHS microdata."),
    ("CDI 2024-25", "CDI 2024-25",
     "Child Development Index 2024-25 from HIES 2024-25 and LFS 2024-25, beside 2018-19 on the same basis."),
    ("CDI 2024-25 PDHS", "CDI 2024-25 PDHS",
     "Child Development Index 2024-25 with the PDHS 2017-18 health inputs from microdata."),
    ("YDI method Table 5", "YDI method check",
     "Youth Development Index (YDI): NHDR 2020 Table 5 recomputed from the published Table 5A indicators."),
    ("YDI 2017-18 2024-25", "YDI 2012-13 to 2024-25",
     "Youth Development Index (ages 15-29) reproduced from LFS 2012-13, 2017-18 and 2024-25, by region."),
    ("YDI survival PMMS 2019", "YDI youth survival PMMS",
     "Youth (15-29) annual survival from the Pakistan Maternal Mortality Survey 2019 household deaths, by "
     "region."),
    ("LDI method Table 8", "LDI method check",
     "Labour Development Index (LDI): NHDR 2020 Table 8 recomputed from the published Table 8A indicators."),
    ("LDI 2012-13 2017-18 2024-25", "LDI 2012-13 to 2024-25",
     "Labour Development Index including decent work, reproduced from LFS microdata and WDI GDP, by region."),
    ("MPI 2019-20 national provincial", "MPI 2019-20 provinces",
     "Multidimensional Poverty Index (MPI) 2019-20 from PSLM 2019-20, national and provincial, against the "
     "official MPI report."),
    ("MPI 2019-20 districts", "MPI 2019-20 districts",
     "Multidimensional Poverty Index 2019-20 by district, PSLM 2019-20, against the official report with its 95% "
     "intervals."),
    ("MPI 2019-20 divisions", "MPI 2019-20 divisions",
     "Multidimensional Poverty Index 2019-20 by division, PSLM 2019-20."),
    ("MPI 2014-15 national provincial", "MPI 2014-15",
     "Multidimensional Poverty Index 2014-15 (harmonized), PSLM 2014-15, national and provincial."),
    ("MPI change 2014-15 2019-20", "MPI change 2014-19",
     "Change in the Multidimensional Poverty Index from 2014-15 to 2019-20 (harmonized), by province and area."),
    ("MPI change districts", "MPI change by district",
     "Change in the Multidimensional Poverty Index from 2014-15 to 2019-20 by district."),
    ("Series HDI Pakistan", "Series HDI and IHDI",
     "Pakistan HDI, IHDI, Palma and Pashum ratios for 2006-07, 2012-13, 2015-16 and 2018-19, all from "
     "microdata (Figures 2.18 to 2.20)."),
    ("Series GDI Pakistan", "Series GDI",
     "Pakistan Gender Development Index by sex for 2006-07, 2012-13, 2015-16 and 2018-19 (Figure 4.9)."),
    ("Series GII Pakistan", "Series GII",
     "Pakistan Gender Inequality Index and its inputs for 2006-07, 2012-13, 2015-16 and 2018-19 (Figure 4.11)."),
    ("HDI Pasha income", "HDI with Pasha income",
     "Human Development Index with provincial income per head set to Pasha's estimates (IPR 2015, BR 2021) "
     "and HIES for the split within each province, against NHDR Table 1 and the all-microdata HDI."),
    ("PSLM district rounds tested", "PSLM 2006-07 and 2008-09 tested",
     "Literacy, enrolment and child immunization from the PSLM 2006-07 and 2008-09 district rounds, against "
     "NHDR's 2006-07 (Table 2A) and 2007-08 (Table 4A) values. Tested, not used in any index."),
    ("WEF GGGI Pakistan", "WEF Global Gender Gap",
     "World Economic Forum Global Gender Gap Index, Pakistan score and rank by edition, transcribed from the WEF "
     "reports (Figure 4.8)."),
]

# ---------------------------------------------------------------------------------------------
# Labels. COMMON holds names that mean the same thing wherever they appear; FILE holds
# names whose meaning depends on the table.
# ---------------------------------------------------------------------------------------------
COMMON = {
    "domain": "Region (Pakistan, province, or urban/rural part)",
    "region": "Region (Pakistan or province)",
    "province": "Province",
    "province_name": "Province",
    "division_name": "Division",
    "district": "District (lower case, matching key)",
    "district_name": "District",
    "area": "Area (Pakistan, province, urban or rural part)",
    "quintile": "Income quintile (All, or Q1 poorest to Q5 richest)",
    "q": "Quintile",
    "year": "Year (NHDR survey year)",
    "round": "Survey round",
    "survey": "Survey round",
    "sex": "Sex",
    "sexname": "Sex",
    "births": "Births in the window (unweighted count)",
    "window_months": "Window before the survey, months",
    "window_years": "Window before the survey, years",
    "u5mr_per_1000": "Under-five mortality rate, deaths per 1,000 live births",
    "survival": "Under-five survival (1 minus under-five mortality)",
    "deaths_weighted": "Under-five deaths in the window, weighted",
    "le_west": "Life expectancy at birth from under-five mortality, Coale-Demeny West (years)",
    "le_south_asian": "Life expectancy at birth from under-five mortality, UN South Asian (years)",
    "pdhs_q5": "PDHS 2017-18 published under-five mortality, ten years (per 1,000)",
    "lit_published": "Adult literacy rate 15+, published NHDR 2020 Table 2A (%)",
    "ner_published": "Net enrolment rate 5-14, published NHDR 2020 Table 2A (%)",
    "lit_reproduced": "Adult literacy rate 15+, reproduced from HIES microdata (%)",
    "ner_reproduced": "Net enrolment rate 5-14, reproduced from HIES microdata (%)",
    "lit_diff": "Adult literacy, reproduced minus published (percentage points)",
    "ner_diff": "Net enrolment, reproduced minus published (percentage points)",
    "lit_pub": "Adult literacy rate 15+, published NHDR 2020 (%)",
    "ner_pub": "Net enrolment rate 5-14, published NHDR 2020 (%)",
    "le_pub": "Life expectancy at birth, published NHDR 2020 (years)",
    "pci_pub": "Income per head, published NHDR 2020 (PPP $)",
    "le_pdhs": "Life expectancy at birth from PDHS under-five mortality, West model (years)",
    "pci_micro": "Income per head from HIES consumption, scaled to WDI GNI per head (PPP $)",
    "cons": "Consumption per head per year, HIES (rupees)",
    "lit15": "Adult literacy rate 15+ (%)",
    "lit": "Adult literacy rate 15+, published NHDR 2020 (%)",
    "ner": "Net enrolment rate 5-14 (%)",
    "le": "Life expectancy at birth (years)",
    "pci": "Income per head (PPP $)",
    "pci_ppp": "Income per head (PPP $)",
    "life_years": "Life expectancy at birth (years)",
    "education_index": "Education index",
    "health_index": "Health index",
    "income_index": "Income index",
    "hdi": "Human Development Index (HDI)",
    "classification": "Human development level (Low < 0.55 <= Medium < 0.70 <= High)",
    "literacy_15plus": "Adult literacy rate 15+ (%)",
    "lit_15plus": "Adult literacy rate 15+ (%)",
    "ner_5_14": "Net enrolment rate 5-14 (%)",
    "literacy_se_pp": "Standard error of adult literacy (percentage points)",
    "ner_se_pp": "Standard error of net enrolment (percentage points)",
    "clusters": "Sample clusters (primary sampling units)",
    "pop_w": "Population, weighted",
    "pop": "Population, weighted",
    "rank": "Rank (1 = highest)",
    "status": "Development level",
    "seats_f": "Seats in parliament held by women (%)",
    "seats_m": "Seats in parliament held by men (%)",
    "no_care_f": "Women without prenatal and postnatal care, published NHDR (%)",
    "evm1519_f": "Women 15-19 ever married, published NHDR (%)",
    "sec_f": "Women 10+ with primary education or higher, published NHDR (%)",
    "sec_m": "Men 10+ with primary education or higher, published NHDR (%)",
    "lfpr_f": "Labour force participation rate, women 15+, published NHDR (%)",
    "lfpr_m": "Labour force participation rate, men 15+, published NHDR (%)",
    "raw_no_care_f": "Women without prenatal and postnatal care, reproduced from HIES (%)",
    "raw_sec_f": "Women 10+ with primary education or higher, reproduced from HIES (%)",
    "raw_sec_m": "Men 10+ with primary education or higher, reproduced from HIES (%)",
    "raw_evm1519_f": "Women 15-19 ever married, reproduced from LFS (%)",
    "raw_lfpr_f": "Labour force participation rate, women 15+, reproduced from LFS (%)",
    "raw_lfpr_m": "Labour force participation rate, men 15+, reproduced from LFS (%)",
    "pub_gii": "Gender Inequality Index (GII), published NHDR 2020",
    "pub_cdi": "Child Development Index (CDI), published NHDR 2020",
    "pub_ydi": "Youth Development Index (YDI), published NHDR 2020",
    "pub_ldidw": "Labour Development Index with decent work, published NHDR 2020",
    "pub_hdi": "Human Development Index (HDI), published NHDR 2020",
    "pub_ihdi": "Inequality-adjusted HDI (IHDI), published NHDR 2020",
    "pub_loss": "Overall loss in HDI from inequality, published NHDR 2020 (%)",
    "malelfs1718": "Male labour force participation, PBS LFS 2017-18 report (%)",
    "femalelfs1718": "Female labour force participation, PBS LFS 2017-18 report (%)",
    "malelfs1819": "Male labour force participation, PBS LFS 2018-19 report (%)",
    "femalelfs1819": "Female labour force participation, PBS LFS 2018-19 report (%)",
    "malelfs2425": "Male labour force participation, PBS LFS 2024-25 report (%)",
    "femalelfs2425": "Female labour force participation, PBS LFS 2024-25 report (%)",
    "income_pce": "Income per child equivalent, real rupees (CDI)",
    "top2": "Children in the top two income quintiles (%)",
    "notwork": "Children 10-14 not working (%)",
    "ner_p": "Net enrolment, primary (%)",
    "ner_m": "Net enrolment, middle (%)",
    "ner_x": "Net enrolment, matric (%)",
    "eec": "Education spending per child equivalent",
    "immun": "Children 12-23 months fully immunized (%)",
    "notstunted": "Children under five not stunted (%)",
    "notwasted": "Children under five not wasted (%)",
    "mys": "Mean years of schooling, youth 15-29",
    "epr": "Employment-to-population ratio",
    "hied": "Youth 15-29 with higher education (%)",
    "fullemp": "Employed youth working full time (%)",
    "lshare": "Labour share of GDP",
    "skillprem": "Skill premium: top to bottom occupation wage ratio",
    "humcap": "Human capital: mean years of schooling of the labour force",
    "decentwork": "Incidence of decent work (%)",
    "H": "Headcount ratio, share of people poor (%)",
    "A": "Intensity, average deprivation among the poor (%)",
    "MPI": "Multidimensional Poverty Index (MPI), reproduced",
    "mpi": "Multidimensional Poverty Index, published report",
    "h": "Headcount ratio, published report (%)",
    "a": "Intensity, published report (%)",
}

FILE = {
    "UNDP index validation": {
        "quantity": "Index compared (education, health, income, HDI)",
        "replicated": "Index recomputed from the Table 2A indicators",
        "published": "Index as printed in NHDR 2020 Table 1",
        "diff": "Recomputed minus published",
        "absdiff": "Absolute difference",
        "within_0001": "Equal at three decimals (1 = yes)",
        "within_0002": "Within one unit of the third decimal (1 = yes)",
    },
    "Life expectancy inversion": {
        "health_index_published": "Health index, published NHDR 2020 Table 1",
        "life_printed_table2a": "Life expectancy at birth, published NHDR 2020 Table 2A (years)",
        "life_recovered": "Life expectancy recovered from the health index, 25 + 65 x index (years)",
        "life_band_low": "Lower bound of recovered life expectancy, rounding of the index (years)",
        "life_band_high": "Upper bound of recovered life expectancy, rounding of the index (years)",
        "gap_years": "Printed minus recovered life expectancy (years)",
        "consistent": "Printed value within the rounding band (1 = yes)",
        "q5_implied_west": "Under-five mortality implied, Coale-Demeny West (per 1,000)",
        "q5_implied_south_asian": "Under-five mortality implied, UN South Asian (per 1,000)",
    },
    "Provincial mortality MICS6": {
        "mics6_q5_10y": "Under-five mortality, MICS6, ten years before the survey (per 1,000)",
        "le_west_from_pdhs": "Life expectancy from PDHS 2017-18 published under-five mortality (years)",
        "nhdr_le_recovered": "Life expectancy recovered from NHDR's published health index (years)",
        "le_gap_mics_minus_pdhs": "Life expectancy, MICS6 minus PDHS basis (years)",
    },
    "District mortality MICS6": {
        "implausible": "Implausibly low: below 20 per 1,000 or under 15 weighted deaths (1 = yes)",
        "thin": "Fewer than 500 births in the window (1 = yes)",
        "key": "District matching key (lower case)",
    },
    "GRP coverage by status 2018-19": {
        "status": "Allocator status (obtained, substitute, unobtained)",
        "gva_rs_mn": "Gross value added covered, 2018-19 (million rupees)",
        "share_of_gdp_pct": "Share of national gross value added (%)",
    },
    "GRP allocator shares 2018-19": {
        "code": "National accounts sub-sector code (PBS Table 4)",
        "sub_sector": "National accounts sub-sector",
        "shareBalochistan": "Balochistan share of the sub-sector (%)",
        "shareKhyber_Pakhtunkhwa": "Khyber Pakhtunkhwa share of the sub-sector (%)",
        "sharePunjab": "Punjab share of the sub-sector (%)",
        "shareSindh": "Sindh share of the sub-sector (%)",
    },
    "GRP source comparison 2018-19": {
        "share_pctkpbos_2021": "Share of GDP, KP Bureau of Statistics nightlights 2021 (%)",
        "share_pctpasha_2021": "Share of GDP, Pasha 2021 (%)",
        "share_pctpide_2022": "Share of GDP, PIDE City Development Product 2022 (%)",
        
        "share_pct_reproduced": "Share of GDP, this reproduction (%)",
        "range_pts": "Range across the four estimates (percentage points)",
    },
    "GRP per capita 2018-19": {
        "grp_pc_ppp": "Gross regional product per head, 2018-19 (PPP $)",
        "grp_relative": "Gross regional product per head relative to Pakistan",
        "nhdr_relative": "NHDR 2020 income per head relative to Pakistan",
    },
    "Income level diagnosis": {
        "survey_income": "HIES 2018-19 income per head relative to Pakistan",
        "survey_consumption": "HIES 2018-19 consumption per head relative to Pakistan",
        "nhdr_printed": "NHDR 2020 income per head relative to Pakistan",
        "grp_relative": "Gross regional product per head relative to Pakistan (this reproduction)",
        "pasha_2018_19": "Pasha provincial GDP per head relative to Pakistan, 2018-19",
    },
    "Income quintile diagnosis": {
        "worstpc_exp": "Largest quintile gap vs NHDR ratios, quintiles ranked on expenditure",
        "worstpc_inc": "Largest quintile gap vs NHDR ratios, quintiles ranked on income",
        "aggregate": "Pakistan or a province (1), urban or rural part (0)",
    },
    "Provincial index 2024-25 survey basis": {
        "lit_10plus": "Literacy rate 10+ (%)",
        "pc_exp_rs": "Consumption per head per year, HIES 2024-25 (rupees)",
        "pci_ppp_survey": "Income per head, survey basis (PPP $)",
        "life_mics": "Life expectancy from MICS6 under-five mortality (years)",
        "life_pdhs": "Life expectancy from PDHS 2017-18 under-five mortality (years)",
        "sb_education_index": "Education index, survey basis",
        "sb_health_index": "Health index, survey basis, MICS6 mortality",
        "sb_income_index": "Income index, survey basis",
        "sb_hdi": "HDI 2024-25, survey basis, MICS6 mortality",
        "sb_classification": "Human development level, survey basis",
        "pd_education_index": "Education index, PDHS variant",
        "pd_health_index": "Health index, PDHS 2017-18 mortality",
        "pd_income_index": "Income index, PDHS variant",
        "pd_hdi": "HDI 2024-25, survey basis, PDHS mortality",
        "pd_classification": "Human development level, PDHS variant",
        "hdi_source_spread": "HDI with MICS6 mortality minus HDI with PDHS mortality",
        "edu_idx_2018_19": "Education index 2018-19, published NHDR 2020",
        "health_idx_2018_19": "Health index 2018-19, published NHDR 2020",
        "income_idx_2018_19": "Income index 2018-19, published NHDR 2020",
        "hdi_2006_07": "HDI 2006-07, published NHDR 2020",
        "hdi_2018_19": "HDI 2018-19, published NHDR 2020",
    },
    "Provincial index 2024-25 final": {
        "hdi_2006_07": "HDI 2006-07, published NHDR 2020",
        "hdi_2018_19": "HDI 2018-19, published NHDR 2020",
        "hdi": "Human Development Index (HDI) 2024-25",
        "change_since_2018_19": "HDI 2024-25 minus HDI 2018-19",
    },
    "Decomposition final": {
        "final_education_pct": "Education contribution to HDI change 2018-19 to 2024-25 (%)",
        "final_health_pct": "Health contribution to HDI change 2018-19 to 2024-25 (%)",
        "final_income_pct": "Income contribution to HDI change 2018-19 to 2024-25 (%)",
        "final_total_pct": "HDI change 2018-19 to 2024-25, log points (%)",
    },
    "Chain consistency sensitivity": {
        "hdi_2024_25_survey_basis": "HDI 2024-25, survey basis",
        "hdi_2006_07": "HDI 2006-07, published NHDR 2020",
        "hdi_2018_19": "HDI 2018-19, published NHDR 2020",
        "hdi_2024_25_final": "HDI 2024-25, one instrument and price basis",
        "pace_2006_2018": "Pace 2006-07 to 2018-19, index points per thousand a year",
        "pace_2018_2024": "Pace 2018-19 to 2024-25, index points per thousand a year",
        "pace_2018_2024_survey": "Pace 2018-19 to 2024-25, survey basis, points per thousand a year",
        "instrument_effect": "Part of the survey-basis HDI change due to the change of instrument",
    },
    "District index": {
        "life_source": "Level the life expectancy comes from (district, division, province)",
    },
    "Divisional index": {"districts": "Districts in the division"},
    "IHDI method Table 3": {
        "hdi_2006_07": "HDI 2006-07, recomputed from NHDR Table 2A",
        "hdi_2018_19": "HDI 2018-19, recomputed from NHDR Table 2A",
        "ihdi_2006_07": "IHDI 2006-07, recomputed from NHDR Table 2A quintiles",
        "ihdi_2018_19": "IHDI 2018-19, recomputed from NHDR Table 2A quintiles",
        "loss_2006_07": "Overall loss from inequality 2006-07, recomputed (%)",
        "loss_2018_19": "Overall loss from inequality 2018-19, recomputed (%)",
        "a_edu_2006_07": "Atkinson inequality in education 2006-07, Table 2A quintiles",
        "a_edu_2018_19": "Atkinson inequality in education 2018-19, Table 2A quintiles",
        "a_le_2006_07": "Atkinson inequality in life expectancy 2006-07, Table 2A quintiles",
        "a_le_2018_19": "Atkinson inequality in life expectancy 2018-19, Table 2A quintiles",
        "a_pci_2006_07": "Atkinson inequality in income 2006-07, Table 2A quintiles",
        "a_pci_2018_19": "Atkinson inequality in income 2018-19, Table 2A quintiles",
        "chi_2006_07": "Coefficient of human inequality 2006-07 (%)",
        "chi_2018_19": "Coefficient of human inequality 2018-19 (%)",
        "share_inc_2018_19": "Share of the 2018-19 loss due to income inequality (%)",
        "share_edu_2018_19": "Share of the 2018-19 loss due to education inequality (%)",
        "share_health_2018_19": "Share of the 2018-19 loss due to health inequality (%)",
    },
    "IHDI 2018-19 microdata": {
        "a_edu_raw": "Atkinson inequality in education, HIES microdata",
        "a_inc_raw": "Atkinson inequality in income, HIES income microdata",
        "a_cons_raw": "Atkinson inequality in income, HIES consumption microdata",
        "a_le_mics": "Atkinson inequality in life expectancy, MICS6 wealth quintiles",
        "ihdi_raw": "IHDI 2018-19, inequality terms from microdata",
        "loss_raw": "Overall loss from inequality, microdata terms (%)",
        "ihdi_1819_samebasis": "IHDI 2018-19 on the 2024-25 basis (consumption, NHDR health)",
    },
    "IHDI 2018-19 PDHS": {
        "a_le_pdhs": "Atkinson inequality in life expectancy, PDHS wealth quintiles",
        "a_edu_raw": "Atkinson inequality in education, HIES microdata",
        "a_inc_raw": "Atkinson inequality in income, HIES income microdata",
        "a_le_mics": "Atkinson inequality in life expectancy, MICS6 wealth quintiles",
        "ihdi_raw": "IHDI 2018-19, MICS6 health term",
        "ihdi_pdhs": "IHDI 2018-19, PDHS health term",
        "loss_pdhs": "Overall loss from inequality, PDHS health term (%)",
    },
    "IHDI 2006-07 microdata": {
        "a_edu_raw": "Atkinson inequality in education, HIES 2005-06 microdata",
        "a_cons": "Atkinson inequality in income, HIES 2005-06 consumption",
        "ihdi_raw_2006_07": "IHDI 2006-07, inequality terms from microdata",
        "loss_raw_2006_07": "Overall loss from inequality 2006-07, microdata terms (%)",
    },
    "IHDI 2006-07 PDHS": {
        "a_le_pdhs": "Atkinson inequality in life expectancy, PDHS 2006-07 wealth quintiles",
        "a_edu_raw": "Atkinson inequality in education, HIES 2005-06 microdata",
        "a_cons": "Atkinson inequality in income, HIES 2005-06 consumption",
        "ihdi_raw_2006_07": "IHDI 2006-07, NHDR health term",
        "loss_raw_2006_07": "Overall loss 2006-07, NHDR health term (%)",
        "ihdi_pdhs_2006_07": "IHDI 2006-07, PDHS health term",
        "loss_pdhs_2006_07": "Overall loss 2006-07, PDHS health term (%)",
    },
    "IHDI all microdata": {
        "hdi_ehi": "HDI, every dimension from microdata",
        "ihdi_m": "IHDI, every dimension and inequality term from microdata",
        "loss_m": "Overall loss from inequality, microdata (%)",
        "chi_m": "Coefficient of human inequality, microdata (%)",
        "a_edu_m": "Atkinson inequality in education, microdata",
        "a_health_m": "Atkinson inequality in life expectancy, PDHS wealth quintiles",
        "a_inc_m": "Atkinson inequality in income, HIES consumption",
    },
    "IHDI 2024-25": {
        "a_edu24": "Atkinson inequality in education, HIES 2024-25",
        "a_cons": "Atkinson inequality in income, HIES 2024-25 consumption",
        "a_le24": "Atkinson inequality in life expectancy, 2024-25",
        "hdi_2024_25": "HDI 2024-25",
        "ihdi_2024_25": "IHDI 2024-25",
        "loss_2024_25": "Overall loss from inequality 2024-25 (%)",
        "hdi_2018_19": "HDI 2018-19, published NHDR 2020",
        "ihdi_1819_samebasis": "IHDI 2018-19 on the 2024-25 basis",
        "loss_1819_samebasis": "Overall loss 2018-19 on the 2024-25 basis (%)",
        "ihdi_change": "IHDI 2024-25 minus IHDI 2018-19 (same basis)",
    },
    "GDI method Table 6": {
        "lit": "Adult literacy rate 15+, published NHDR 2020 Table 6A (%)",
        "ner": "Net enrolment rate, published NHDR 2020 Table 6A (%)",
        "le": "Life expectancy at birth, published NHDR 2020 Table 6A (years)",
        "pci": "Estimated earned income per head, published Table 6A (PPP $)",
        "gdi_edu": "Education index by sex, recomputed",
        "gdi_hea": "Life expectancy index by sex, recomputed",
        "gdi_inc": "Income index by sex, recomputed (goalpost 75,000)",
        "gdi_hdi": "HDI by sex, recomputed",
        "inc_idx_100k": "Income index by sex with the 100,000 goalpost",
        "gdi": "Gender Development Index (GDI), recomputed",
        "gdi_dev": "Deviation from gender parity, recomputed (%)",
    },
    "GDI 2006-07 reproduced": {
        "lit": "Adult literacy rate 15+, published NHDR 2020 Table 6A (%)",
        "ner": "Net enrolment rate, published NHDR 2020 Table 6A (%)",
        "le": "Life expectancy at birth, published Table 6A (years)",
        "pci": "Estimated earned income per head, published Table 6A (PPP $)",
        "lit_reproduced": "Adult literacy rate 15+ by sex, HIES 2005-06 (%)",
        "ner_reproduced": "Net enrolment rate by sex, HIES 2005-06 (%)",
        "r_edu": "Education index by sex, reproduced",
        "r_hea": "Life expectancy index by sex (published inputs)",
        "r_inc": "Income index by sex (published inputs)",
        "r_hdi": "HDI by sex, reproduced education",
        "r_gdi": "Gender Development Index, reproduced education",
    },
    "GDI reproduced 2018-19 2024-25": {
        "lit15": "Adult literacy rate 15+ by sex, HIES (%)",
        "ner": "Net enrolment rate 5-14 by sex, HIES (%)",
        "s_f": "Female share of earned income (UNDP method, LFS wages)",
        "s_f_w18": "Female share of earned income, 2018-19 wage ratio held",
        "cyear": "Census year used for the female population share",
        "female_share": "Female share of population, census",
        "le_2018_19": "Life expectancy 2018-19, published NHDR 2020 (years)",
        "pci_2018_19": "Income per head 2018-19, published NHDR 2020 (PPP $)",
        "life_years": "Life expectancy at birth, both sexes (years)",
        "pci_ppp": "Income per head, both sexes (PPP $)",
        "pci_all": "Income per head, both sexes, used for the split (PPP $)",
        "le_all": "Life expectancy, both sexes, used for the split (years)",
        "pci": "Estimated earned income per head by sex (PPP $)",
        "pci_w18": "Estimated earned income by sex, 2018-19 wage ratio held (PPP $)",
        "le": "Life expectancy at birth by sex (years)",
        "gdi_edu": "Education index by sex",
        "gdi_hea": "Life expectancy index by sex",
        "gdi_inc": "Income index by sex",
        "gdi_hdi": "HDI by sex",
        "w18_edu": "Education index by sex, 2018-19 wage ratio held",
        "w18_hea": "Life expectancy index by sex, 2018-19 wage ratio held",
        "w18_inc": "Income index by sex, 2018-19 wage ratio held",
        "w18_hdi": "HDI by sex, 2018-19 wage ratio held",
        "gdi": "Gender Development Index (GDI)",
        "gdi_w18": "Gender Development Index, 2018-19 wage ratio held",
        "gdi_dev": "Deviation from gender parity (%)",
    },
    "LFS 2017-18 participation": {
        "lfpr_f_1718": "Labour force participation, women 15+, LFS 2017-18 microdata (%)",
        "lfpr_m_1718": "Labour force participation, men 15+, LFS 2017-18 microdata (%)",
        "evm1519_f_1718": "Women 15-19 ever married, LFS 2017-18 microdata (%)",
    },
    "GII 2018-19 all microdata": {
        "lfpr_f_1718": "Labour force participation, women 15+, LFS 2017-18 microdata (%)",
        "lfpr_m_1718": "Labour force participation, men 15+, LFS 2017-18 microdata (%)",
        "evm1519_f_1718": "Women 15-19 ever married, LFS 2017-18 microdata (%)",
    },
    "GII 2018-19 reproduced": {
        "nopre": "Women with a recent birth and no prenatal care, HIES 2018-19 (share)",
        "nopost": "Women with a recent birth and no postnatal care, HIES 2018-19 (share)",
        "d_care": "GII change from swapping in reproduced care",
        "d_evm": "GII change from swapping in reproduced early marriage",
        "d_educ": "GII change from swapping in reproduced schooling",
        "d_lfpr": "GII change from swapping in reproduced participation",
    },
    "GII 2024-25": {
        "evm1519_f": "Women 15-19 ever married, LFS 2024-25 (%)",
        "lfpr_f": "Labour force participation, women 15+, LFS 2024-25 (%)",
        "lfpr_m": "Labour force participation, men 15+, LFS 2024-25 (%)",
        "no_care_f": "Women without prenatal and postnatal care, HIES 2024-25 (%)",
        "sec_f": "Women 10+ with primary education or higher, HIES 2024-25 (%)",
        "sec_m": "Men 10+ with primary education or higher, HIES 2024-25 (%)",
        "seats_f": "Seats held by women, 2018 assemblies (%)",
        "seats_m": "Seats held by men, 2018 assemblies (%)",
        "gii_change": "GII 2024-25 minus GII 2018-19 (reproduced basis)",
    },
    "CDI method Table 4": {
        "cdi_from_pub": "CDI as the mean of the published sub-indices",
    },
    "CDI reproduced 2007-08 2018-19": {
        "notwork_emp": "Children 10-14 not employed (employment only, %)",
    },
    "CDI reproduced PDHS": {
        "notwork_emp": "Children 10-14 not employed (employment only, %)",
        "survival_pd": "Under-five survival, PDHS microdata",
        "notstunted_pd": "Children under five not stunted, PDHS microdata (%)",
        "notwasted_pd": "Children under five not wasted, PDHS microdata (%)",
        "surv_h": "Under-five survival used (PDHS microdata)",
        "nst_h": "Not stunted used: PDHS microdata, or as printed if not measured (%)",
        "nwa_h": "Not wasted used: PDHS microdata, or as printed if not measured (%)",
        "anthro_from_pdhs": "Stunting and wasting from PDHS microdata (1 = yes)",
    },
    "CDI 2024-25": {
        "notwork_wide": "Children 10-14 not working, including work for own use (%)",
        "notwork": "Children 10-14 not employed (%)",
        "cdi_change": "CDI 2024-25 minus CDI 2018-19 (same basis)",
        "status_2024_25": "Child development level 2024-25",
    },
    "CDI 2024-25 PDHS": {
        "cdi_change_h": "CDI 2024-25 minus 2018-19, PDHS health inputs",
    },
    "PDHS anthropometry": {
        "stunted": "Children under five stunted, height-for-age below -2 SD (%)",
        "wasted": "Children under five wasted, weight-for-height below -2 SD (%)",
        "notstunted_pd": "Children under five not stunted (%)",
        "notwasted_pd": "Children under five not wasted (%)",
    },
    "PDHS CDI health inputs": {
        "survival_pd": "Under-five survival, ten years, PDHS microdata",
        "notstunted_pd": "Children under five not stunted, PDHS microdata (%)",
        "notwasted_pd": "Children under five not wasted, PDHS microdata (%)",
    },
    "PDHS wealth quintile mortality": {
        "q": "PDHS household wealth quintile",
        "le_pdhs": "Life expectancy at birth, West model (years)",
    },
    "YDI method Table 5": {
        "survival": "Youth annual survival, published NHDR 2020 Table 5A",
        "surv_idx_as_printed": "Survival index with the goalposts as printed (0.9770 to 0.9999)",
    },
    "YDI 2017-18 2024-25": {
        "survival": "Youth annual survival, published NHDR 2020 (held for other years)",
        "p_mys": "Mean years of schooling, published NHDR 2020",
        "p_epr": "Employment-to-population ratio, published NHDR 2020 (%)",
        "p_hied": "Youth with higher education, published NHDR 2020 (%)",
        "p_fullemp": "Employed youth working full time, published NHDR 2020 (%)",
        "status": "Youth development level",
    },
    "YDI survival PMMS 2019": {
        "deaths_w": "Deaths at ages 15-29 in the year before the survey, weighted",
        "py_w": "Person-years at ages 15-29, weighted",
        "survival_pmms": "Youth annual survival, PMMS 2019 microdata",
        "survival": "Youth annual survival, published NHDR 2020 Table 5A",
    },
    "LDI method Table 8": {
        "gm5": "LDI as the geometric mean of the five published sub-indices",
        "am5": "LDI as the arithmetic mean of the five published sub-indices",
    },
    "LDI 2012-13 2017-18 2024-25": {
        "ptop": "Share of paid employees who are managers or professionals (ISCO 1, 2)",
        "pbot": "Share of paid employees in plant or elementary jobs (ISCO 8, 9)",
        "Gf": "GDP at current prices with Pasha 2018-19 shares held fixed (rupees)",
        "lshare_fs": "Labour share of GDP, Pasha 2018-19 provincial shares held fixed",
        "i_ls_fs": "Labour share index, provincial shares held fixed",
        "ldidw_fs": "LDI with decent work, provincial shares held fixed",
        "wbar": "Mean monthly wage, paid employees (rupees)",
        "wtop": "Mean monthly wage, managers and professionals (rupees)",
        "wbot": "Mean monthly wage, plant operators and elementary jobs (rupees)",
        "wf": "Mean monthly wage, female paid employees (rupees)",
        "wm": "Mean monthly wage, male paid employees (rupees)",
        "mwok": "Paid employees earning above the minimum wage (share)",
        "dh": "Employed working more than 10 and under 48 hours a week (share)",
        "fe": "Employed in formal enterprises (share)",
        "cf": "Employed as contributing family workers (share)",
        "n_ee": "Paid employees, weighted count",
        "n_se": "Self-employed, weighted count",
        "n_emp": "Employed, weighted count",
        "wr": "Female to male mean wage ratio",
        "LI": "Labour income, 12 x mean wage x (employees + 0.8 self-employed), rupees",
        "G": "Gross domestic product at current prices, provincial share applied (rupees)",
        "i_ls_pub": "Labour share index with NHDR's published labour share",
        "ldidw_nhdr_ls": "LDI with decent work, NHDR's labour share swapped in",
        "p_epr": "Employment-to-population ratio, published NHDR 2020",
        "p_lshare": "Labour share of GDP, published NHDR 2020",
        "p_skillprem": "Skill premium, published NHDR 2020",
        "p_humcap": "Human capital, published NHDR 2020 (years)",
        "p_decentwork": "Incidence of decent work, published NHDR 2020 (%)",
        "status": "Labour development level",
    },
    "MPI 2019-20 districts": {
        "h_lo": "Headcount ratio, published lower 95% bound (%)",
        "h_hi": "Headcount ratio, published upper 95% bound (%)",
        "h_in_ci": "Reproduced headcount within the published interval (1 = yes)",
        "hdi": "District Human Development Index (this package)",
        "rank": "District HDI rank (1 = highest)",
        "area": "District as named in the MPI report",
        "mpi_lo": "MPI, published lower 95% bound",
        "mpi_hi": "MPI, published upper 95% bound",
        "d_mpi": "MPI reproduced minus published",
    },
    "MPI change 2014-15 2019-20": {
        "pub_d_mpi": "Change in MPI 2014-15 to 2019-20, published report",
    },
    "MPI change districts": {
        "district_2014_15": "PSLM 2014-15 district code",
    },
    "Series HDI Pakistan": {
        "lit15": "Adult literacy rate 15+, HIES (%)",
        "ner": "Net enrolment rate 5-14, HIES (%)",
        "pci": "Income per head, HIES consumption scaled to WDI GNI per head (PPP $)",
        "le": "Life expectancy at birth from PDHS under-five mortality (years)",
        "a_edu": "Atkinson inequality in education across quintiles",
        "a_health": "Atkinson inequality in life expectancy across PDHS wealth quintiles",
        "a_inc": "Atkinson inequality in income across quintiles",
        "ihdi": "Inequality-adjusted HDI (IHDI)",
        "loss": "Overall loss in HDI from inequality (%)",
        "palma": "Modified Palma ratio: HDI of richest quintile over poorest",
        "pashum": "Pashum ratio: mean ratio of successive quintile HDIs, minus 1",
    },
    "Series GDI Pakistan": {
        "sex": "Sex code (1 male, 2 female)",
        "lit15": "Adult literacy rate 15+ by sex, HIES (%)",
        "ner": "Net enrolment rate 5-14 by sex, HIES (%)",
        "ea_f": "Female share of the economically active population, LFS",
        "wage_ratio": "Female to male mean earnings of paid employees, LFS",
        "s_f": "Female share of earned income (UNDP method)",
        "le_sex": "Life expectancy at birth by sex, World Bank WDI (years)",
        "pci_all": "GNI per head, WDI, fiscal-year average (PPP $)",
        "pci_sex": "Estimated earned income per head by sex (PPP $)",
        "g_edu": "Education index by sex",
        "g_hea": "Life expectancy index by sex",
        "g_inc": "Income index by sex (goalpost 75,000)",
        "g_hdi": "HDI by sex",
        "gdi": "Gender Development Index (GDI)",
    },
    "Series GII Pakistan": {
        "seats_f": "Seats in parliament held by women, WDI SG.GEN.PARL.ZS (%)",
        "seats_m": "Seats in parliament held by men (%)",
        "no_care": "Women without prenatal and postnatal care, HIES/PSLM (%)",
        "sec_f": "Women 10+ with primary education or higher, HIES (%)",
        "sec_m": "Men 10+ with primary education or higher, HIES (%)",
        "lfpr_f": "Labour force participation, women 15+, LFS (%)",
        "lfpr_m": "Labour force participation, men 15+, LFS (%)",
        "evm1519": "Women 15-19 ever married, LFS (%)",
    },
    "HDI Pasha income": {
        "prov": "Province of the domain (Pakistan for national rows)",
        "rel_nhdr": "Province income per head relative to Pakistan, NHDR 2020 Table 2A",
        "rel_hies": "Province consumption per head relative to Pakistan, HIES",
        "rel_pasha": "Province product per head relative to Pakistan, Pasha (2007-08 or 2018-19)",
        "rel_pasha_alt": "Province product per head relative to Pakistan, Pasha IPR 2015, 2014-15",
        "pci_pasha_nl": "Income per head, Pasha provincial pattern, NHDR national level (PPP $)",
        "pci_pasha_alt": "Income per head, Pasha 2014-15 pattern, NHDR national level (PPP $)",
        "pci_pasha": "Income per head, Pasha provincial pattern, WDI national level (PPP $)",
        "hdi_pasha_nl": "HDI: microdata education, NHDR life expectancy, Pasha income pattern",
        "hdi_pasha_alt": "HDI as hdi_pasha_nl with Pasha's 2014-15 pattern (2018-19 only)",
        "hdi_pasha": "HDI: microdata education and life expectancy, Pasha income, WDI level",
        "p_hdi": "HDI from NHDR's printed inputs (Table 2A), NHDR construction",
    },
    "PSLM district rounds tested": {
        "round": "PSLM district round",
        "lit": "Adult literacy rate 15+, PSLM (%)",
        "pub_lit_2006_07": "Adult literacy rate 15+, NHDR Table 2A 2006-07 (%)",
        "ner514": "Net enrolment rate 5-14, level matched, PSLM (%)",
        "pub_ner_2006_07": "Net enrolment rate 5-14, NHDR Table 2A 2006-07 (%)",
        "ner_p": "Net enrolment, primary, ages 5-9, PSLM (%)",
        "pub_ner_p": "Net enrolment, primary, NHDR Table 4A 2007-08 (%)",
        "ner_m": "Net enrolment, middle, ages 10-12, PSLM (%)",
        "pub_ner_m": "Net enrolment, middle, NHDR Table 4A 2007-08 (%)",
        "ner_x": "Net enrolment, matric, ages 13-14, PSLM (%)",
        "pub_ner_x": "Net enrolment, matric, NHDR Table 4A 2007-08 (%)",
        "immun": "Children 12-23 months with BCG, DPT3 and polio 3, PSLM (%)",
        "pub_immun": "Children 12-23 months fully immunized, NHDR Table 4A 2007-08 (%)",
        "n_child": "Children aged 12-23 months in the sample (unweighted)",
    },
    "WEF GGGI Pakistan": {
        "edition": "Report edition (year)",
        "gggi_score": "Global Gender Gap Index score, Pakistan (0 to 1, 1 = parity)",
        "rank": "Pakistan's rank among countries covered",
        "source_report": "Source report",
        "source_file": "Local copy in 6. Raw data/Documents/Sources downloaded/WEF",
        "pdf_page": "Page of the report the value was read from",
        "url": "Web address of the report",
        "table": "Table the value was read from",
        "retrieved": "Date retrieved",
    },
}

# GII components written by the nhdr_gii program, under any prefix.
GII_PARTS = {
    "health_f": "female reproductive health index", "emp_f": "female empowerment index",
    "emp_m": "male empowerment index", "g_f": "female gender index", "g_m": "male gender index",
    "harm": "harmonic mean of the gender indices", "health_bar": "mean reproductive health index",
    "emp_bar": "mean empowerment index", "lfpr_bar": "mean labour participation index",
    "g_fm": "reference gender index", "gii": "Gender Inequality Index (GII)",
}
GII_PREFIX = {
    "gii_": "recomputed from published inputs", "pub_": "published NHDR 2020",
    "raw_": "every input reproduced", "s1_": "NHDR inputs, reproduced care",
    "s2_": "NHDR inputs, reproduced early marriage", "s3_": "NHDR inputs, reproduced schooling",
    "s4_": "NHDR inputs, reproduced participation", "g24_": "2024-25", "m_": "all microdata",
    "r_": "reproduced 2006-07", "s_": "Pakistan series",
}
CDI_PARTS = {"sl": "living standard index", "edu": "education index", "hea": "health and nutrition index",
             "cdi": "Child Development Index (CDI)"}
CDI_PREFIX = {"m_": "recomputed from published inputs", "r_": "reproduced", "h_": "reproduced, PDHS health",
              "c18_": "2018-19 on the 2024-25 basis", "c24_": "2024-25", "c18h_": "2018-19, PDHS health",
              "c24h_": "2024-25, PDHS health", "pub_": "published NHDR 2020"}
YDI_PARTS = {"i_mys": "schooling index", "i_epr": "employment index", "i_hied": "higher education index",
             "i_full": "full employment index", "i_surv": "survival index", "ydi": "Youth Development Index (YDI)"}
LDI_PARTS = {"i_ep": "employment-to-population index", "i_ls": "labour share index",
             "i_sp": "skill premium index", "i_hc": "human capital index", "i_dw": "decent work index",
             "ldidw": "Labour Development Index with decent work", "ldin": "LDI without decent work"}
HDI_PARTS = {"education_index": "education index", "health_index": "health index",
             "income_index": "income index", "hdi": "HDI", "classification": "human development level"}
HDI_PREFIX = {"m_": "all from microdata", "p_": "published NHDR inputs", "e_": "microdata education only",
              "eh_": "microdata education and health", "s_": "Pakistan series", "sb_": "survey basis",
              "pd_": "PDHS mortality"}
PUB_IDX = {"lit_idx": "literacy index", "ner_idx": "enrolment index", "edu_idx": "education index",
           "le_idx": "life expectancy index", "inc_idx": "income index", "sl_idx": "living standard index",
           "health_idx": "health and nutrition index", "mys_idx": "schooling index",
           "epr_idx": "employment index", "hied_idx": "higher education index", "full_idx": "full employment index",
           "surv_idx": "survival index", "lshare_idx": "labour share index", "sp_idx": "skill premium index",
           "hc_idx": "human capital index", "dw_idx": "decent work index", "gdi": "Gender Development Index",
           "gdi_dev": "deviation from gender parity (%)", "hdi": "HDI", "ihdi": "IHDI",
           "chi": "coefficient of human inequality (%)", "loss": "overall loss from inequality (%)",
           "aedu": "inequality in education (Atkinson)", "ahealth": "inequality in health (Atkinson)",
           "ainc": "inequality in income (Atkinson)", "mpi": "MPI", "h": "headcount ratio (%)",
           "a": "intensity (%)", "d_mpi": "change in MPI"}

YEAR = re.compile(r"^(.*?)_?((?:19|20)\d\d)_(\d\d)$")


def year_split(v):
    """'hdi_2018_19' -> ('hdi', '2018-19'); 'MPI_14' -> ('MPI', '2014-15')."""
    m = YEAR.match(v)
    if m and m.group(1):
        return m.group(1), f"{m.group(2)}-{m.group(3)}"
    m = re.match(r"^(.*)_(14|19)$", v)
    if m:
        return m.group(1), {"14": "2014-15", "19": "2019-20"}[m.group(2)]
    return v, ""


def label(file, v):
    if v in FILE.get(file, {}):
        return FILE[file][v]
    for pre, what in GII_PREFIX.items():
        if v.startswith(pre) and v[len(pre):] in GII_PARTS:
            return f"GII {GII_PARTS[v[len(pre):]]}, {what}".replace("GII Gender Inequality Index (GII)",
                                                                       "Gender Inequality Index (GII)")
    for pre, what in CDI_PREFIX.items():
        if v.startswith(pre) and v[len(pre):] in CDI_PARTS:
            p = CDI_PARTS[v[len(pre):]]
            return f"{p[0].upper() + p[1:] if p.startswith('C') else 'CDI ' + p}, {what}"
    for pre, what in [("m_", "recomputed from published inputs"), ("r_", "reproduced")]:
        if v.startswith(pre) and v[len(pre):] in YDI_PARTS:
            p = YDI_PARTS[v[len(pre):]]
            return f"{p if p.startswith('Y') else 'YDI ' + p}, {what}"
        if v.startswith(pre) and v[len(pre):] in LDI_PARTS:
            p = LDI_PARTS[v[len(pre):]]
            return f"{p if p.startswith('L') else 'LDI ' + p}, {what}"
    for pre, what in HDI_PREFIX.items():
        if v.startswith(pre) and v[len(pre):] in HDI_PARTS:
            p = HDI_PARTS[v[len(pre):]]
            return f"{p[0].upper() + p[1:]}, {what}"
    if v in ("hdi_e", "hdi_eh", "hdi_ehi"):
        return {"hdi_e": "HDI, microdata education, published health and income",
                "hdi_eh": "HDI, microdata education and health, published income",
                "hdi_ehi": "HDI, every dimension from microdata"}[v]
    stem, yr = year_split(v)
    tail = f", {yr}" if yr else ""
    if stem in COMMON and stem != v:
        return COMMON[stem] + tail
    if v in COMMON:
        return COMMON[v]
    if stem.startswith("pub_") and stem[4:] in PUB_IDX:
        return f"{PUB_IDX[stem[4:]][0].upper() + PUB_IDX[stem[4:]][1:]}{tail}, published"
    if stem in PUB_IDX or stem in ("ihdi", "chi", "loss", "hdi"):
        return f"{PUB_IDX.get(stem, stem)[0].upper() + PUB_IDX.get(stem, stem)[1:]}{tail}, reproduced"
    if stem.startswith("a_") and stem[2:] in ("edu", "le", "pci", "health", "inc"):
        what = {"edu": "education", "le": "life expectancy", "pci": "income", "health": "life expectancy",
                "inc": "income"}[stem[2:]]
        return f"Atkinson inequality in {what} across quintiles{tail}"
    if stem.startswith("d_"):
        return f"Change 2014-15 to 2019-20: {COMMON.get(stem[2:], stem[2:])}"
    if stem.startswith("p_"):
        base = COMMON.get(stem[2:], stem[2:])
        return f"{base}{tail}, published NHDR 2020"
    if stem.endswith("_1819"):
        return f"{COMMON.get(stem[:-5], stem[:-5])}, 2018-19 (2024-25 basis)"
    return ""


def main(run=None):
    rows, missing = [], []
    files = [f for f, _, _ in SHEETS]
    src = Path(run) if run else None
    if src and not src.is_absolute():
        src = ROOT / src
    for f in files:
        cols = None
        if src and (src / f"{f}.csv").exists():
            cols = list(csv.reader(open(src / f"{f}.csv", encoding="utf-8")))[0]
        names = cols if cols else sorted(set(FILE.get(f, {})))
        for v in names:
            lab = label(f, v)
            if len(lab) > 80:
                missing.append(f"TOO LONG {f} | {v} | {lab}")
            if not lab:
                missing.append(f"{f} | {v}")
            rows.append([f, v, lab])
    with open(DOS / "Variable dictionary.csv", "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["File", "Variable", "Label"])
        w.writerows(rows)
    with open(DOS / "Output descriptions.csv", "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["File", "Sheet", "Headline"])
        w.writerows(SHEETS)
    print(len(rows), "labels;", len(missing), "missing or too long")
    for m in missing:
        print("  ", m)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
