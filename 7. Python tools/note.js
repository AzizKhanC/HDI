// Technical note on the NHDR 2020 reproduction, written as a Word file.
//   node note.js "<output .docx>" "<run folder>"
// "Build outputs.py" calls it after a run. The check count and run name are read
// from the run folder and the variable annex from "2. Notes/Raw variable inventory.csv".
// The other figures in the text are those of the run named in footnote 2; a run that
// changes them needs the text below revised to match.
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, FootnoteReferenceRun, Header, Footer, AlignmentType, PageNumber,
  Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle, HeadingLevel, TabStopType, PageBreak,
} = require("docx");

// NHDR 2020 palette: red titles, orange sub-heads and table heads, navy figures, beige bands.
const RED = "EF4429", NAVY = "1F6288", ORANGE = "F36F25", BEIGE = "F3E9E0", GREY = "58595B";
const OUT = process.argv[2];
const RUN = process.argv[3] || "";
const ROOT = path.resolve(__dirname, "..");

// ---------------------------------------------------------------- run facts
function readCsv(file) {
  const text = fs.readFileSync(file, "utf8").replace(/^﻿/, "");
  const rows = [];
  let row = [], cur = "", q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) {
      if (c === '"' && text[i + 1] === '"') { cur += '"'; i++; }
      else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ",") { row.push(cur); cur = ""; }
    else if (c === "\n") { row.push(cur.replace(/\r$/, "")); rows.push(row); row = []; cur = ""; }
    else cur += c;
  }
  if (cur || row.length) { row.push(cur); rows.push(row); }
  return rows;
}
let runName = path.basename(RUN || "");
let nChecks = 299, nPass = 298;
if (RUN && fs.existsSync(path.join(RUN, "Checks.txt"))) {
  const lines = fs.readFileSync(path.join(RUN, "Checks.txt"), "utf8").split(/\r?\n/).slice(1).filter((l) => l.trim());
  nChecks = lines.length;
  nPass = lines.filter((l) => l.startsWith("PASS")).length;
}
const nFail = nChecks - nPass;
const invPath = path.join(ROOT, "2. Notes", "Raw variable inventory.csv");
let inv = [];
if (fs.existsSync(invPath)) inv = readCsv(invPath).slice(1).filter((r) => r.length >= 5);

// ---------------------------------------------------------------- text helpers
// {{x}} = key figure (bold, navy); ^n^ = footnote reference
function runs(text) {
  const out = [];
  for (const part of text.split(/(\{\{[^}]+\}\}|\^\d+\^)/)) {
    if (!part) continue;
    if (part.startsWith("{{")) out.push(new TextRun({ text: part.slice(2, -2), bold: true, color: NAVY }));
    else if (/^\^\d+\^$/.test(part)) out.push(cite(parseInt(part.slice(1, -1))));
    else out.push(new TextRun(part));
  }
  return out;
}
// Each citation gets its own footnote, numbered in order of appearance. A source cited
// again gets a new footnote that reads "Footnote n.", as Word allows one reference per note.
let fnCount = 0;
const firstNum = {}, noteSrc = {};
function cite(src) {
  fnCount += 1;
  if (!(src in firstNum)) { firstNum[src] = fnCount; noteSrc[fnCount] = src; }
  else noteSrc[fnCount] = -firstNum[src];
  return new FootnoteReferenceRun(fnCount);
}
let pno = 0;
function P(lead, text) {
  pno += 1;
  const kids = [new TextRun(`${pno}.\t`)];
  if (lead) kids.push(new TextRun({ text: lead + " ", bold: true }));
  return new Paragraph({
    children: kids.concat(runs(text)), spacing: { after: 140, line: 264 },
    indent: { left: 460, hanging: 460 }, tabStops: [{ type: TabStopType.LEFT, position: 460 }],
    alignment: AlignmentType.JUSTIFIED,
  });
}
function plain(text, opts = {}) {
  return new Paragraph({ children: runs(text), spacing: { after: 140, line: 264 }, alignment: AlignmentType.JUSTIFIED, ...opts });
}
const H1 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, keepNext: true, keepLines: true, children: [new TextRun(t)], spacing: { before: 280, after: 140 } });
const H2 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, keepNext: true, keepLines: true, children: [new TextRun(t)], spacing: { before: 180, after: 100 } });

// ---------------------------------------------------------------- tables
const edge = { style: BorderStyle.SINGLE, size: 4, color: "D5BEAB" };
const borders = { top: edge, bottom: edge, left: edge, right: edge };
function cell(text, width, { head = false, band = false, align = AlignmentType.LEFT, size = 15 } = {}) {
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading: head ? { fill: ORANGE, type: ShadingType.CLEAR } : band ? { fill: BEIGE, type: ShadingType.CLEAR } : undefined,
    margins: { top: 40, bottom: 40, left: 70, right: 70 },
    children: [new Paragraph({ alignment: align, children: [new TextRun({ text, size, bold: head, color: head ? "FFFFFF" : undefined })] })],
  });
}
function table(widths, header, rows, { numCols = [], size = 15, bandOn = null } = {}) {
  const total = widths.reduce((a, b) => a + b, 0);
  return new Table({
    width: { size: total, type: WidthType.DXA }, columnWidths: widths,
    rows: [new TableRow({ tableHeader: true, children: header.map((h, i) => cell(h, widths[i], { head: true, size })) })].concat(
      rows.map((r, k) => new TableRow({
        cantSplit: true,
        children: r.map((v, i) => cell(String(v), widths[i], {
          band: bandOn ? bandOn(r, k) : false, size,
          align: numCols.includes(i) ? AlignmentType.RIGHT : AlignmentType.LEFT,
        })),
      }))),
  });
}
const tnote = (t) => new Paragraph({ children: [new TextRun({ text: t, size: 15, color: GREY })], spacing: { before: 60, after: 160 } });

// ---------------------------------------------------------------- footnotes
const FN = {
  1: "UNDP Pakistan. 2020. Pakistan National Human Development Report 2020. The Three Ps of Inequality: Power, People, and Policy. Islamabad. Statistical tables and technical notes, pp. 239-261.",
  2: `NHDR2020 reproduction from microdata.do (folder 1. Dos), Stata 18 SE, ${runName ? "8. Stata runs/" + runName : "the latest run"}. Published values come from the source in footnote {1} and reproduced values from this run unless stated otherwise. Folder 3. Tables holds every annex cell.`,
  3: "Pakistan Bureau of Statistics (PBS). Household Integrated Economic Survey (HIES) 2005-06, 2007-08, 2011-12, 2015-16, 2018-19 and 2024-25; Labour Force Survey (LFS) 2006-07, 2012-13, 2014-15, 2017-18, 2018-19 and 2024-25; Pakistan Social and Living Standards Measurement (PSLM) survey 2014-15 and 2019-20. Microdata as released by PBS.",
  4: "National Institute of Population Studies (NIPS) and ICF. Pakistan Demographic and Health Survey (PDHS) 2006-07, 2012-13 and 2017-18, standard recode files; Pakistan Maternal Mortality Survey (PMMS) 2019. The DHS Program, downloaded 29 September 2026.",
  5: "The DHS Program. DHS-Indicators-Stata, Chap08_CM/CM_CHILD.do. GitHub repository DHSProgram/DHS-Indicators-Stata. Method in S.O. Rutstein and G. Rojas. 2006. Guide to DHS Statistics. Calverton, MD: ORC Macro.",
  6: "A.J. Coale, P. Demeny and B. Vaughan. 1983. Regional Model Life Tables and Stable Populations. Second edition. New York: Academic Press. West family, levels 13 to 24.",
  7: "NIPS and Macro International. 2008. PDHS 2006-07; NIPS and ICF International. 2013. PDHS 2012-13; NIPS and ICF. 2019. PDHS 2017-18. Under-five mortality for the five years before each survey.",
  8: "World Bank. World Development Indicators (WDI): GNI per capita, PPP (current international $), NY.GNP.PCAP.PP.CD; life expectancy at birth by sex, SP.DYN.LE00.FE.IN and SP.DYN.LE00.MA.IN; proportion of seats held by women in national parliaments, SG.GEN.PARL.ZS; GDP at current prices and consumer price index. API, last updated 13 July 2026.",
  9: "Pasha (2019), as cited in NHDR 2020, Technical note 3; not public. Held instead: H.A. Pasha. 2015. Growth of the Provincial Economies. Institute for Policy Reform; and H.A. Pasha. 2021. Size of provincial economies. Business Recorder, 17 August 2021. The do file applies Pasha's allocator scheme to the 22 PBS sub-sectors and allocates 95.0 percent of 2018-19 GDP.",
  10: "World Economic Forum. The Global Gender Gap Report, editions 2006 to 2018 and 2020 to 2025. Pakistan's score and rank are transcribed from each report, with page and table, in 6. Raw data/Published/WEF GGGI Pakistan.csv; the reports are held in 6. Raw data/Documents/Sources downloaded/WEF.",
};

// ---------------------------------------------------------------- content
const body = [];
body.push(new Paragraph({ children: [new TextRun({ text: "Reproducing the NHDR 2020 indices from survey microdata", bold: true, size: 32, color: RED })], spacing: { after: 80 } }));
body.push(new Paragraph({ children: [new TextRun({ text: "Technical note on method, variables, results and divergences", size: 24, color: NAVY })], spacing: { after: 60 } }));
body.push(new Paragraph({ children: [new TextRun({ text: "2 October 2026", size: 20, color: GREY })], spacing: { after: 240 } }));

body.push(H1("EXECUTIVE SUMMARY"));
body.push(plain("This note reports the reproduction, from survey microdata, of the Statistical Annex of the Pakistan National Human Development Report 2020 (NHDR 2020), Tables 1 to 8A, and of the 28 index figures and maps in its chapters.^1^ One Stata do file reads the raw files of the Household Integrated Economic Survey (HIES), the Labour Force Survey (LFS), the Pakistan Social and Living Standards Measurement (PSLM) survey, the Pakistan Demographic and Health Survey (PDHS), the Pakistan Maternal Mortality Survey (PMMS) and the Multiple Indicator Cluster Surveys (MICS6). It computes the Human Development Index (HDI) and its six companion indices with the construction NHDR used, which the do file recovers by inverting the published tables. The run reported here passes " + `{{${nPass} of ${nChecks}}}` + " validation checks.^2^"));
body.push(plain("Education reproduces exactly. Literacy and net enrolment from HIES match the 15 domain totals of Table 2A, and an HDI built on microdata education with NHDR's own life expectancy and income lies within {{0.0002}} of all 30 published domain values. With life expectancy and income also taken from the microdata, Pakistan's HDI for 2018-19 is {{0.567}} against the published 0.570, while two provinces move further: Punjab {{0.582}} against 0.572 and Sindh {{0.561}} against 0.574. Two undisclosed inputs account for the movement. NHDR does not name the model life table that turns under-five mortality into life expectancy, and PDHS 2017-18 mortality read through the Coale-Demeny West table gives Punjab 65.3 years against NHDR's 63.9. NHDR's provincial income pattern matches neither HIES nor any published estimate of regional product: Sindh's income per head is 1.22 times the national figure in NHDR and 1.03 times in HIES consumption."));
body.push(plain("The national income level of 2018-19 traces to the World Bank: gross national income (GNI) per head in purchasing power parity (PPP) dollars, averaged over the fiscal year, gives {{4,925}} against NHDR's 4,922. The same rule gives 3,350 for 2006-07, while NHDR prints 4,135, a value no WDI series reproduces. The 2006-07 HDI for Pakistan therefore falls to {{0.516}} against the published 0.529 once income comes from the World Bank series."));
body.push(plain("The companion indices sit closer. The Child Development Index (CDI) is within 0.025 of Table 4 in all ten domain-years and the Youth Development Index (YDI) for 2017-18 within 0.011 of Table 5. The Gender Development Index (GDI) for 2018-19 is {{0.793}} against 0.777, because LFS earnings give women a larger share of income than NHDR's figures imply. The Gender Inequality Index (GII) for 2018-19 is {{0.519}} against 0.548, because no survey on disk reproduces NHDR's early-marriage rate of 20.0 percent. The Labour Development Index (LDI) with decent work for 2017-18 is {{0.422}} against 0.442, because NHDR's labor share implies gross domestic product (GDP) on the national accounts base that PBS retired in 2017.^2^"));
body.push(plain("The figures now carry four survey years where NHDR draws four. HIES 2011-12 and 2015-16, PDHS 2012-13 and LFS 2014-15 supply the intermediate points of the HDI, inequality-adjusted HDI (IHDI), GDI and GII series, and the World Economic Forum (WEF) reports supply Pakistan's Global Gender Gap Index for every edition from 2006 to 2025.^10^ Figure 4.12, the CDI by sex, remains the one figure not reproduced."));
body.push(plain("NHDR attributes its provincial income to \"Pasha (2019) and HIES\". Pasha (2019) is not public. The two Pasha estimates that are public do not reproduce NHDR's provincial income column. NHDR prints Khyber Pakhtunkhwa at {{0.79}} times national income per head in 2018-19, Pasha's 2021 estimate gives 0.91 and his 2015 estimate 0.94. NHDR's Sindh figure of 1.22 equals Pasha's 2014-15 value and its Balochistan figure of 0.73 sits near his 2018-19 value, so the printed column matches no single Pasha estimate. An HDI built on Pasha's 2018-19 pattern, with everything else as NHDR printed it, reproduces Punjab and Balochistan within 0.001 and misses KP by 0.007 and Sindh by 0.004.^2^"));
body.push(plain("The reproduced LDI rises in 2014-15 and, without its decent-work dimension, falls back in 2017-18, where NHDR's Figure 4.4 rises in both steps. Two inputs drive the movement. The skill premium jumps to 2.89 in 2014-15 and drops to 2.57 in 2017-18 because LFS wages of managers and professionals rise 28 percent between 2012-13 and 2014-15 while elementary wages rise 19 percent, and the order reverses in the next round; the occupation mix barely moves. The provincial labor share swings because the provincial GDP shares behind it come from two Pasha estimates on different bases, which move Balochistan from 2.9 to 4.8 percent of GDP. Holding the 2018-19 shares fixed narrows Balochistan's labor share from a range of 0.37 to 0.62 to a range of 0.31 to 0.41.^2^"));
body.push(plain("The five PSLM district rounds added to the package (2004-05 to 2012-13) were tested where NHDR names a PSLM source. PSLM 2006-07 gives adult literacy of 51.8 percent against NHDR's 50.7 for 2006-07, which HIES 2005-06 matches within 0.1 point, and PSLM 2006-07 and 2008-09 give full immunization of 82 and 85 percent nationally against NHDR's 73 for 2007-08. Neither round reproduces the printed values across all provinces, so the HIES inputs stay and the PSLM results are reported alongside.^2^"));
body.push(plain("Section I sets out the scope and approach. Section II describes the data and the variables. Section III reports the results index by index. Section IV lists the problems found, in the code and in the report. Section V proposes next steps. Annex 1 gives, for each indicator, the survey, file and variables used and the source NHDR names. Annex 2 summarizes the headline comparisons. Annex 3 describes the package and how to run it. Annex 4 lists every survey variable the do file reads, with the label stored in the survey file."));

body.push(H1("I. SCOPE AND APPROACH"));
body.push(H2("A. Coverage"));
body.push(P("Tables.", "The reproduction covers the eight annex tables and their indicator tables: the HDI (Tables 1 and 2A) for 15 domains (Pakistan, its urban and rural parts, the four provinces and their urban and rural parts) and the consumption quintiles of each, the IHDI (Table 3), the CDI (Tables 4 and 4A), the YDI (Tables 5 and 5A), the GDI (Tables 6 and 6A), the GII (Tables 7 and 7A) and the LDI (Tables 8 and 8A). The HDI, IHDI, GDI and GII refer to 2006-07 and 2018-19, the CDI to 2007-08 and 2018-19, the YDI to 2001-02 and 2017-18, and the LDI to 2012-13 and 2017-18. The do file adds the Multidimensional Poverty Index (MPI) for 2014-15 and 2019-20, a district and divisional HDI from PSLM 2019-20, and every index for 2024-25."));
body.push(P("Figures and maps.", "Twenty-four figures and four maps in Chapters 2 to 5 present index results. Twenty-seven are redrawn in NHDR's style, with the report's chart forms, categories, colors and typeface (Roboto Condensed, extracted from the report PDF), and each sits beside the published figure in folder 4. Plots. Figure 4.8 plots the World Economic Forum's Global Gender Gap Index, which has no survey counterpart, so its values are transcribed from the WEF reports and stored with page references.^10^ Figure 4.12, the CDI by sex, is not reproduced. NHDR does not state how it splits income and education spending by sex. Its All rows equal the simple mean of the male and female rows (1,449 and 1,253 rupees average to 1,351), so each sex was computed separately, but the natural rule, household income per child equivalent averaged over boys and over girls in HIES 2018-19, gives a boy-to-girl ratio of 1.004 against the printed 1.156."));
body.push(H2("B. Method"));
body.push(P("Construction.", "NHDR 2020 describes its methods in technical notes but omits several parameters, so the do file recovers them by inverting the published tables. The HDI weights literacy two-thirds and enrolment one-third, sets health goalposts at 25 and 90 years and income goalposts at 100 and 100,000 PPP dollars, and aggregates by geometric mean. No United Nations Development Programme (UNDP) vintage uses this combination, yet it reproduces all 120 published dimension indices within 0.0011."));
body.push(P("Checks.", `Each run writes a log and a file of ${nChecks} validation checks. A check compares a reproduced value with the figure printed by NHDR, the Pakistan Bureau of Statistics (PBS), PDHS or UNDP, or with the value an independent Python implementation produced from the same raw files. The run reported here passes ${nPass}. ` + (nFail === 1 ? "The one failure, male wasting in Table 4A, stays in the file on purpose and is discussed in Section IV." : `The ${nFail} failures are listed in Checks.txt.`)));
body.push(P("Three kinds of cell.", "Each reproduced cell carries one of three labels in the annex workbook. Reproduced means computed from the microdata on disk. As printed marks an input that no file on disk can supply, carried from the published table so that the index can still be computed; the workbook shows these in grey italics. External marks a non-survey series NHDR also takes from outside, such as World Bank life expectancy by sex. A cell left unreproduced reads n.a. Three survey rounds NHDR used are not on disk: LFS 2001-02, LFS 2007-08 and PSLM 2007-08. Each figure keeps the axis slot of a missing year and marks it n.a."));
body.push(P("HDI with all three dimensions from the microdata.", "Life expectancy comes from PDHS under-five mortality over the ten years before each survey, computed by the synthetic-cohort method of the Demographic and Health Surveys (DHS) Program and read through the Coale-Demeny West model life table.^5^ ^6^ Income comes from HIES consumption per head, scaled so that Pakistan equals the WDI GNI per head in PPP dollars, fiscal-year average.^8^ The domain and quintile relativities therefore come from the survey and the national level from the World Bank. Three versions of each HDI isolate the input that moves it: microdata education only, microdata education and life expectancy, and all three dimensions from the microdata."));
body.push(P("Intermediate years.", "NHDR's figures draw 2006-07, 2012-13, 2015-16 and 2018-19. The do file maps them to HIES 2005-06, 2011-12, 2015-16 and 2018-19 for education and income, to PDHS 2006-07, 2012-13 and 2017-18 for mortality (for 2015-16, the PDHS 2017-18 birth history shifted back 24 months), to LFS 2006-07, 2012-13, 2014-15 and 2017-18 for earnings, participation and early marriage, and to WDI for national income, life expectancy by sex and parliamentary seats."));

body.push(H1("II. DATA AND VARIABLES"));
body.push(P("Surveys.", "The reproduction uses HIES 2005-06, 2007-08, 2011-12, 2015-16, 2018-19 and 2024-25, LFS 2006-07, 2012-13, 2014-15, 2017-18, 2018-19 and 2024-25, and PSLM 2014-15 and 2019-20, and tests PSLM 2006-07 and 2008-09,^3^ PDHS 2006-07, 2012-13 and 2017-18 and PMMS 2019,^4^ and the MICS6 birth histories of the four provinces. GDP, prices and national income come from the World Development Indicators (WDI),^8^ and provincial product from Pasha's allocator scheme.^9^ Annex 1 lists, for each indicator, the file and variables used and the source NHDR names. Annex 4 lists all " + inv.length + " survey variables the do file reads, with each file's own label."));
body.push(P("Education.", "Literacy is s2aq01 (reads and writes with understanding) for persons aged 15 and over in HIES 2018-19 (plist, sec_2ab) and HIES 2005-06 (roster with weights, sec 2a). Net enrolment uses s2bq01 (currently attending) and s2bq14 (class attended) for children aged 5 to 14, counted only at the school level matching the child's age. The annex defines net enrolment as attendance in any class from 1 to 10, which gives 62.0 percent for Pakistan in 2018-19 against the printed 37.0. Only the level-matched rate reproduces all 15 domains. NHDR's 2006-07 column uses 2005-06 data, as its own footnote states,^1^ and HIES 2005-06 reproduces it within 0.07 points."));
body.push(P("Life expectancy.", "Under-five mortality comes from the PDHS birth recode: b3 (date of birth), b5 (child alive), b7 (age at death in months), v005 (weight), v008 (date of interview), v024 (region), v025 (urban or rural) and v190 (wealth quintile). NHDR states that it estimated life expectancy from under-five mortality but does not name the life table. Through the West family, PDHS mortality places provincial life expectancy 0.4 to 2.0 years from NHDR's, in both directions."));
body.push(P("Income.", "Consumption per head is t_exp (annual household consumption) from HIES 2018-19 sec_12ce divided by household size, and the consumption-module aggregate of the other rounds (section codes 1000 to 5000, value columns v1 to v4, annualized by PBS's own rule). NHDR's quintiles are consumption quintiles. NHDR attributes its provincial incomes to Pasha (2019) and HIES."));
body.push(P("Child, youth, gender and labor indices.", "The CDI draws on HIES (income and education spending per child equivalent, enrolment by level, immunization), LFS 2017-18 (child work) and PDHS (survival, stunting, wasting). NHDR names PSLM 2007-08 for enrolment and immunization in 2007-08. The YDI draws on LFS 2017-18 for schooling, employment and full employment, and on PMMS 2019 for youth survival: deaths at ages 15 to 29 since January 2016 in the household deaths file over person-years in the household roster. The GDI takes education by sex from HIES and earned income by sex from LFS wages, split by the UNDP method with the census female population share. The GII takes care and schooling from HIES and participation and early marriage from LFS 2017-18. The LDI uses LFS 2012-13, 2014-15, 2017-18 and 2024-25."));
body.push(P("PSLM district rounds.", "The package now holds PSLM 2004-05 (CWIQ), 2006-07, 2008-09, 2010-11 and 2012-13, besides 2014-15 and 2019-20. NHDR names PSLM 2006-07 for the 2006-07 column of Table 1 and PSLM 2007-08 for the 2007-08 enrolment and immunization of the CDI. Section 23.6 of the do file reads PSLM 2006-07 and 2008-09 on the rules used everywhere else: literacy from scq01, level-matched enrolment from scq05 and scq06, and full immunization at 12 to 23 months from shq5_1, shq5_4 and shq5_7, with age from the birth year and month against the interview date. Literacy in 2006-07 comes out at 51.8 percent against 50.7, enrolment 5 to 14 at 36.7 against 34.7, and immunization at 81.8 percent in 2006-07 and 84.6 in 2008-09 against 73. For immunization PSLM 2006-07 sits closer than HIES 2007-08 in KP (79.0 against the printed 74, HIES 58.2) and Balochistan (57.5 against 57, HIES 42.4), and further away nationally (81.8 against 73, HIES 68.9), in Punjab (87.5 against 76, HIES 76.5) and in Sindh (74.2 against 67, HIES 62.0). Literacy and enrolment sit closer on HIES: HIES 2007-08 puts every CDI enrolment rate within 0.6 points of Table 4A, PSLM 2006-07 within 2.8. No round on disk reproduces the 2007-08 column, so HIES 2007-08, the survey of the same year, stays as the input. PSLM 2007-08 itself, a provincial round, is not held.^2^"));
body.push(P("Variable names in the outputs.", "Every result table carries short variable names in its comma-separated values (CSV) file. The results workbook written by each run replaces them with full descriptive names from 1. Dos/Variable dictionary.csv and opens every sheet with a one-line description from 1. Dos/Output descriptions.csv. The annex workbook in 3. Tables names each quantity in full, with published, reproduced and difference columns."));

body.push(H1("III. RESULTS"));
body.push(H2("A. Human Development Index"));
body.push(P("Domain values.", "With all three dimensions from the microdata, the 2018-19 HDI is {{0.567}} for Pakistan against 0.570, {{0.582}} for Punjab against 0.572, {{0.561}} for Sindh against 0.574, {{0.544}} for Khyber Pakhtunkhwa (KP) against 0.546 and {{0.476}} for Balochistan against 0.473. In 2006-07 Pakistan is {{0.516}} against 0.529. The national gap in 2006-07 comes from income: the WDI level is 3,350 PPP dollars against NHDR's 4,135."));
body.push(P("Sources of the divergence.", "Microdata education alone leaves all 30 domain values within 0.0002 of the published HDI. Adding PDHS life expectancy moves Punjab to 0.579 and Sindh to 0.569 in 2018-19. Adding survey income moves Punjab to 0.582 and Sindh to 0.561. Health and income therefore account for the provincial divergence, in roughly equal parts, and education for none of it."));
body.push(P("Series.", "Pakistan's reproduced HDI is {{0.516}} in 2006-07, {{0.539}} in 2012-13, {{0.557}} in 2015-16 and {{0.567}} in 2018-19 (Figure 2.18)."));
body.push(P("Quintiles.", "The national quintile HDIs for 2018-19 are 0.418, 0.495, 0.543, 0.618 and 0.702, against NHDR's 0.420, 0.495, 0.552, 0.617 and 0.698. The modified Palma ratio (richest over poorest quintile) is {{1.68}} against 1.67, and the Pashum ratio, which reproduces NHDR's printed values as the mean step between successive quintiles, is 0.14 in both. Quintile literacy and enrolment differ from Table 2A by up to 7.5 points, because NHDR's quintile rows do not average to its own domain totals, a pattern no cut of the HIES distribution reproduces."));
body.push(P("Thin cells.", "PDHS supports life expectancy for Pakistan and the provinces. It does not support it for wealth quintiles within the urban or rural part of a province: rural Balochistan's richest quintile holds 9 births in the ten-year window. The reproduced quintile rows below province level should be read with that limit."));
body.push(H2("B. Provincial income: NHDR, Pasha and HIES"));
body.push(P("Two measures of provincial income.", "Pasha's estimates are gross regional product per head: national value added allocated to provinces by sector-specific indicators, divided by provincial population. They count where output is produced, so Karachi's port, manufacturing and financial services raise Sindh. HIES consumption per head counts what households spend, wherever the income behind it was earned, including remittances and transfers. The do file uses HIES consumption for the provincial and quintile pattern and the WDI GNI per head for the national level, because consumption is the only income measure on disk that reproduces NHDR's quintile rows."));
const INC = [
  ["Balochistan", "0.843", "0.614", "0.708", "0.727", "0.715", "0.551", "0.755"],
  ["Khyber Pakhtunkhwa", "0.687", "0.827", "0.876", "0.787", "0.906", "0.940", "0.849"],
  ["Punjab", "0.985", "0.943", "1.042", "0.993", "1.005", "0.961", "1.063"],
  ["Sindh", "1.263", "1.178", "1.035", "1.222", "1.122", "1.220", "1.028"],
];
body.push(table([1700, 900, 1050, 950, 900, 1050, 1250, 1226], ["Province", "NHDR 2006-07", "Pasha 2007-08", "HIES 2005-06", "NHDR 2018-19", "Pasha 2018-19", "Pasha 2014-15", "HIES 2018-19"], INC, { numCols: [1, 2, 3, 4, 5, 6, 7] }));
body.push(tnote("Income per head relative to Pakistan. NHDR: Table 2A. Pasha 2007-08 and 2014-15: Pasha (2015), Institute for Policy Reform, gross regional product per head at constant 2005-06 prices. Pasha 2018-19: Pasha (2021), Business Recorder, current factor cost. HIES: consumption per head, person weighted. Values from HDI Pasha income.csv of the run in footnote 2."));
body.push(P("Pasha does not reproduce NHDR either.", "No Pasha estimate held matches NHDR's column. In 2018-19 NHDR's Sindh figure (1.222) equals Pasha's 2014-15 value (1.220), its Balochistan figure (0.727) is near Pasha's 2018-19 value (0.715) and HIES (0.755), and its KP figure (0.787) lies below both Pasha estimates (0.906 and 0.940). In 2006-07 the gaps are larger: NHDR puts Balochistan at 0.843 and KP at 0.687, while Pasha's 2007-08 estimate gives 0.614 and 0.827, the reverse ordering. Pasha (2019), the source NHDR names, may hold other values; it is not public."));
body.push(P("The HDI on Pasha's income.", "Section 20.7 of the do file sets each province's income relative to Pakistan to Pasha's and keeps HIES for the split within the province. With NHDR's own life expectancy and national income level, the only change from the published HDI is the provincial income pattern. On Pasha's 2018-19 pattern the 2018-19 HDI is {{0.573}} for Punjab against 0.572, {{0.472}} for Balochistan against 0.473, {{0.553}} for KP against 0.546 and {{0.570}} for Sindh against 0.574. On Pasha's 2014-15 pattern Sindh is exact at 0.574 and Balochistan falls to 0.460. On Pasha's 2007-08 pattern the 2006-07 HDI misses Balochistan by 0.014 (0.456 against 0.470) and KP by 0.009. The provincial income pattern alone moves a provincial HDI by up to 0.014, and no single public source reproduces it.^2^"));
body.push(H2("C. Inequality-adjusted HDI"));
body.push(P("IHDI.", "The reproduced 2018-19 IHDI for Pakistan is {{0.529}} against 0.534, a loss to inequality of {{6.68}} percent against 6.26. Income inequality accounts for most of the loss in both. The largest gap is KP in 2006-07, a loss of 4.79 percent against 6.74, because HIES 2005-06 consumption is more equal across KP's quintiles than NHDR's income series (Atkinson index 0.104 against 0.157). The series loss is 6.79, 5.84, 6.53 and 6.68 percent for the four years.^2^"));
body.push(H2("D. Child Development Index"));
body.push(P("CDI.", "The CDI is within 0.025 of Table 4 in all ten domain-years; Pakistan is {{0.573}} against 0.575 in 2018-19. The largest gap is Punjab 2018-19, 0.630 against 0.655, where education spending per child equivalent is 53.3 rupees against 67.1 and income per child equivalent 1,334 against 1,488. Immunization for 2007-08 comes from HIES 2007-08 because NHDR's source, PSLM 2007-08, is not on disk, and HIES gives KP 58.2 percent against 74 and Balochistan 42.4 against 57. Survival is within 0.0005 of Table 4A and stunting within 0.05 points in all 15 cells.^2^"));
body.push(H2("E. Youth Development Index"));
body.push(P("YDI.", "The 2017-18 YDI is within 0.011 of Table 5 in all seven rows; Pakistan is {{0.604}} against 0.605. Youth survival from PMMS 2019 matches six of seven cells within 0.00012. Balochistan gives 0.9986 against 0.9990, which moves its survival index from 0.690 to 0.551 because the goalposts span only 0.0029. Employment to population in Balochistan is 38.7 percent against 32.9, and no definition tested reproduces the printed value.^2^"));
body.push(H2("F. Gender Development and Gender Inequality Indices"));
body.push(P("GDI.", "With NHDR's life expectancy by sex, the 2018-19 GDI is {{0.793}} against 0.777. Female earned income is 1,799 PPP dollars against 1,673 and male income 7,899 against 9,335. NHDR's pair implies a female income share of 0.146 and a population-weighted mean of about 5,600 dollars, above the 4,922 of its HDI, so neither its wage ratio nor its income level can be recovered from what it published. The four-year series takes life expectancy by sex from the WDI, as NHDR has UNDP values for its two printed years only, and gives 0.726, 0.775, 0.793 and 0.811 (Figure 4.9). For 2006-07 the series uses LFS 2006-07 earnings: female income 881 against NHDR's 1,385, at the lower WDI national level."));
body.push(P("GII.", "With every survey input from the microdata, the GII is {{0.557}} for 2006-07 against 0.582 and {{0.519}} for 2018-19 against 0.548, and 0.468 for Punjab in 2018-19 against 0.500. Participation from LFS 2017-18 matches Table 7A exactly (20.1 and 68.0 percent for Pakistan), care without prenatal or postnatal contact within 0.5 points and schooling within 0.6. Early marriage drives the gap: 12.6 percent of women aged 15 to 19 are ever married in LFS 2017-18 against NHDR's 20.0, and 12.3 percent in LFS 2006-07 against 20.3. LFS 2006-07 also gives participation of 17.9 and 68.2 percent against the printed 19.6 and 69.5. With NHDR's printed labor inputs, the 2006-07 GII is within 0.0011 of Table 7.^2^"));
body.push(H2("G. Labour Development Index"));
body.push(P("LDI.", "The 2017-18 LDI with decent work is {{0.422}} for Pakistan against 0.442. Employment, skill premium, human capital and decent work reproduce closely; the labor share does not. The reproduced share is 0.330 against 0.42 in 2017-18 and 0.289 against 0.32 in 2012-13. NHDR's 0.32 implies 2012-13 GDP of about Rs 22.4 trillion, the level on the 2005-06 base, against Rs 25.0 trillion on the current series. With NHDR's labor shares substituted, all 14 reproduced LDI values are within 0.01 of Table 8. LFS 2014-15 adds the 2014-15 point of Figure 4.4: 0.417."));
body.push(P("Wage ratios and rankings.", "LFS wages give a female-to-male ratio for KP of 0.95 in 2012-13 and 1.08 in 2017-18, and 0.97 for Balochistan in 2017-18; NHDR does not print the underlying values. The provincial ranking in Figure 4.6 changes as a result: the reproduced decent-work dimension ranks KP first, where NHDR ranks Balochistan first."));
body.push(P("National series.", "The reproduced LDI with decent work rises from {{0.397}} in 2012-13 to {{0.416}} in 2014-15 and {{0.422}} in 2017-18. Without decent work it reads 0.393, 0.418 and 0.410, where NHDR's Figure 4.4 draws about 0.41, 0.44 and 0.44 (read from the chart, which prints no values). The skill premium drives the turn. Mean monthly wages of managers and professionals rise from Rs 24,229 to Rs 31,045 between LFS 2012-13 and 2014-15 (28 percent) while those of plant operators and elementary workers rise from Rs 9,015 to Rs 10,749 (19 percent), lifting the premium from 2.69 to 2.89. By LFS 2017-18 elementary wages have risen 31 percent and top wages 17 percent, and the premium falls to 2.57. The occupation mix of paid employees stays near 12 to 13 percent in the top groups and 43 to 46 percent in the bottom groups, so the movement is in wages, not in who is employed. Sindh shows it most: its premium goes 2.87, 3.62, 3.15.^2^"));
body.push(P("Provincial swings.", "The labor share divides LFS labor income by provincial GDP, and provincial GDP is national GDP times a provincial share. The shares come from two Pasha estimates: IPR 2015 at constant 2005-06 prices for 2007-08 and 2014-15, and Business Recorder 2021 at current factor cost for 2018-19, interpolated between. Balochistan is 2.9 percent of GDP in the first and 4.8 percent in the second, so its share jumps between rounds and its labor share runs 0.47, 0.62 and 0.37. LFS 2014-15 adds to the spike: it counts 1.35 million self-employed in Balochistan against 1.00 million in 2012-13 and 1.03 million in 2017-18, and labor income credits each at 0.8 of the mean wage. Holding the 2018-19 shares fixed in every year gives 0.31, 0.41 and 0.34, and Balochistan's LDI 0.358, 0.421 and 0.377 against 0.395, 0.464 and 0.385. Both versions are in the results (lshare_fs, ldidw_fs).^2^"));
body.push(H2("H. Global Gender Gap Index"));
body.push(P("WEF.", "Pakistan's Global Gender Gap Index score runs from 0.543 in the 2006 edition to 0.564 in 2020 and 0.567 in 2025, and its rank from 112th to 151st and 148th. The 2019 edition does not exist: WEF published the 2020 report in December 2019. Each value is read from the report's ranking table, and the file records page and table for each edition.^10^"));

body.push(H1("IV. PROBLEMS FOUND"));
body.push(H2("A. Defects in the reproduction code, corrected"));
body.push(P("Under-five mortality.", "PDHS records age at death in whole years from 12 months on: {{84}} percent of deaths at 12 to 59 months in 2006-07, and 72 and 73 percent in 2012-13 and 2017-18, sit at exactly 12, 24, 36 or 48 months. An earlier version of the routine dated each death as birth date plus that age and counted a death in the cohort entering an age segment before the period only if the date fell inside the period. Rounding pulled those dates back and the deaths dropped out, leaving under-five mortality at 91.0, 86.9 and 71.7 per 1,000 against the published 94, 89 and 74.^7^ The routine is now a line-by-line port of the DHS Program's own code, which weights the deaths of both edge cohorts by one half whatever their date, and returns {{94.17}}, {{89.01}} and {{74.00}}.^5^"));
body.push(P("CDI survival window.", "The earlier code took ten-year mortality for Pakistan by sex in both CDI years. Table 4A uses ten years in 2007-08 and five years in 2018-19: Pakistan male survival is 0.920 on five years and 0.913 on ten, against a printed 0.920. With this rule and the corrected mortality, all 30 survival cells are within 0.0005."));
body.push(P("Vaccination age.", "PDHS 2017-18 is a seventh-round DHS survey, which measures a child's age from the day of birth (b19). The earlier code used the interview month less the birth month, which shifts children across the 12 and 23 month edges. Basic vaccination at 12 to 23 months is now 65.6 percent against the published 66, up from 65.1.^7^"));
body.push(P("PDHS 2006-07 anthropometry.", "The household member file of PDHS 2006-07 carries the height and weight variables hc1, hc70 and hc72, but every value is empty because that round did not measure children. The code tested only for the variable names and stopped. It now tests for values and keeps NHDR's printed anthropometry for 2007-08."));
body.push(P("Charts.", "The charts Stata draws in Section 26 took some values from printed inputs and labelled two charts as Figures 4.7 and 4.8 that are not NHDR's Figures 4.7 and 4.8. The NHDR-style set in folder 4. Plots carries the like-for-like comparison, and the Stata charts stay in their own subfolder for reference."));
body.push(H2("B. Inconsistencies in NHDR 2020"));
body.push(P("Map 4.2 and Table 5.", "Map 4.2 prints provincial YDI values of 0.435 for Balochistan, 0.572 for KP, 0.621 for Punjab and 0.630 for Sindh. Table 5 prints 0.517, 0.524, 0.614 and 0.637 for the same index and year. The two cannot both hold."));
body.push(P("Male wasting.", "Table 4A's male not-wasted values run 0.1 to 1.3 points above the PDHS 2017-18 microdata (Balochistan 82.1 against 80.8), and its national male wasting rate of 7.2 percent differs from the 7.6 percent PDHS published.^7^ Female cells match within 0.31 points. De jure children, the children's file, joint validity rules, unweighted means and flagged codes were all tested, and none closes the gap."));
body.push(P("Early marriage.", "Table 7A prints 20.0 percent of women aged 15 to 19 as ever married in 2018-19 and 20.3 percent in 2006-07, and attributes the columns to the LFS. LFS 2018-19 gives 12.3 percent, LFS 2017-18 12.6 and LFS 2006-07 12.3, so the printed rates match none of them.^1^ ^3^"));
body.push(P("Provincial income source.", "NHDR attributes Table 2A's provincial incomes to Pasha (2019) and HIES. Neither public Pasha estimate nor HIES reproduces the column (Section III.B): KP's 0.787 in 2018-19 lies below both Pasha estimates, and the 2006-07 ordering of Balochistan above KP is the reverse of Pasha's."));
body.push(P("National income for 2006-07.", "NHDR prints 4,135 PPP dollars as Pakistan's income per head in 2006-07. The WDI fiscal-year average is 3,350, and no WDI vintage or PPP series held reproduces 4,135, while the same rule reproduces NHDR's 2018-19 value within 3 dollars."));
body.push(P("Labor share.", "The labor shares of Table 8A imply GDP on the national accounts base that PBS replaced in 2017, while the rest of the report uses the current base."));
body.push(P("YDI technical note.", "The note gives the survival goalposts as 0.9770 to 0.9999, but only 0.9970 to 0.9999 reproduces all 14 survival indices of Table 5. Its equation 6 divides four indices by four, while Table 5 averages all five. Enrolment in higher education is in fact attainment: the enrolment reading gives 13.2 percent for Pakistan against the printed 16.6, and attainment gives 16.6.^1^"));
body.push(P("Net enrolment.", "The annex definition of net enrolment (any class from 1 to 10) yields 62.0 percent in 2018-19, against the 37.0 printed.^1^ The printed values follow a level-matched rate that the annex does not describe."));
body.push(P("LDI aggregation.", "The LDI note describes an arithmetic mean in its introduction and a geometric mean in its Step 3. Table 8 is the geometric mean; the arithmetic mean misses Pakistan female 2012-13 by 0.047."));
body.push(P("Survey years.", "Tables 4A and 7A attribute their 2018-19 labor indicators to LFS 2018-19. LFS 2017-18 reproduces participation exactly and child work within 0.3 points, while LFS 2018-19 does not, so the column labelled 2018-19 is LFS 2017-18. NHDR's Punjab also includes Islamabad Capital Territory in the LFS-based tables."));
body.push(P("Undisclosed parameters.", "NHDR does not name its model life table, publish its provincial income series or state its goalposts. The GDI income index runs to 75,000 PPP dollars while the HDI runs to 100,000."));
body.push(H2("C. Limits of the reproduction"));
body.push(P("Scope limits.", "Quintile life expectancy below province level rests on few births and ranks households on PDHS wealth rather than HIES consumption. Life expectancy by sex in the GDI and parliamentary seats in the GII are external values in NHDR and here come from the WDI. The CDI by sex is not built, and the three missing survey rounds leave the corresponding years n.a."));

body.push(H1("V. NEXT STEPS"));
body.push(P("Request from UNDP Pakistan.", "Ask the NHDR team for the model life table, Pasha (2019) and the provincial income series derived from it for Table 2A, the 2006-07 national income level, the source of the early-marriage rates in Table 7A, the data behind Map 4.2, and the rule that splits CDI income and education spending by sex. The first four account for most of the remaining divergence in the HDI and the GII."));
body.push(P("Obtain the missing rounds.", "LFS 2001-02, LFS 2007-08 and PSLM 2007-08 would fill the remaining n.a. years and the CDI immunization and child-work inputs for 2007-08."));
body.push(P("Extend the do file.", "Report quintile life expectancy only for Pakistan and the provinces until a pooled or smoothed estimator is adopted for smaller domains, and add the CDI by sex once UNDP states its rule."));

// ---------------------------------------------------------------- Annex 1
body.push(new Paragraph({ children: [new PageBreak()] }));
body.push(H1("ANNEX 1: DATA SOURCES AND VARIABLES BY INDICATOR"));
const A1 = [
  ["HDI: adult literacy", "HIES. 2005-06 values 'computed from PSLM 2006-2007' (Table 1 note)", "HIES 2018-19 plist, sec_2ab. HIES 2005-06 roster with weights, sec 2a", "s2aq01 = 1, age 15+, person weight", "Domain totals exact (2018-19), within 0.07 points (2006-07)"],
  ["HDI: net enrolment", "HIES", "As above", "s2bq01 = 3, s2bq14 class matched to ages 5-9, 10-12, 13-14", "Domain totals exact"],
  ["HDI: life expectancy", "Under-five mortality, life table not named", "PDHS 2017-18 PKBR71FL. PDHS 2006-07 PKBR53FL", "b3, b5, b7, v005, v008, v024, v025, v190. Ten years. West family", "Provinces 0.4 to 2.0 years apart"],
  ["HDI: income per head", "Pasha (2019) and HIES", "HIES 2018-19 sec_12ce. HIES 2005-06 sec6abcd", "t_exp / household size. Codes 1000-5000, v1-v4. Scaled to WDI GNI per head (PPP)", "Sindh 1.03 x national against 1.22. Pasha 2021: 1.12"],
  ["IHDI: quintile inequality", "HDI database at quintile level", "As for the HDI", "Atkinson index, aversion 1, over consumption quintiles within domain", "Loss 6.68 against 6.26 percent"],
  ["CDI: income per child equivalent", "HIES and LFS 2007-08, 2018-19", "HIES 2007-08, 2018-19 consumption modules", "Child equivalents 2 + 1.4(adults - 1) + children. 2001-02 prices, WDI consumer price index", "Pakistan 1,275 against 1,351 rupees"],
  ["CDI: child work", "HIES and LFS 2007-08, 2018-19", "LFS 2017-18. 2007-08 as printed", "Employed or producing goods for own use, ages 10-14", "LFS 2017-18 within 0.3 points"],
  ["CDI: enrolment by level", "PSLM 2007-08, HIES 2018-19", "HIES 2007-08, 2018-19", "Level-matched rates, ages 5-9, 10-12, 13-14", "Within 0.5 points"],
  ["CDI: immunization", "PSLM 2007-08. HIES 2018-19", "HIES 2007-08 sec3b. HIES 2018-19 sec_3b", "s3bq04a, s3bq04d, s3bq04h (2007-08). s3bq4a, s3bq4d, s3bq4k (2018-19). Ages 12-23 months", "2007-08 up to 15.8 points apart"],
  ["CDI: survival", "PDHS 2006-07, 2017-18", "PKBR53FL, PKBR71FL", "DHS synthetic cohort, five or ten years by cell", "Within 0.0005"],
  ["CDI: stunting, wasting", "PDHS 2017-18", "PKPR71FL", "hc70, hc72 below -200. hc1 under 60. hv103 = 1. hv005", "Stunting within 0.05. Male wasting not reproduced"],
  ["YDI: schooling, employment, higher education, full employment", "LFS 2017-18", "LFS 2017-18 (SPSS release)", "Age 15-29. Highest level. Employed. Hours in main job", "Schooling within 0.03 years. Employment within 2 points except Balochistan"],
  ["YDI: youth survival", "PMMS 2019", "PMMS 2019 PKPQ7AFL, PKOD7AFL", "qh05, qh07, qh04, qhweight, qhintc. qh32c, qh33u, qh33n, qh31. Deaths at 15-29 since January 2016", "Six of seven within 0.00012"],
  ["GDI: education by sex", "HIES", "As for the HDI", "As for the HDI, by sex", "Exact"],
  ["GDI: earned income by sex", "National accounts, LFS, Census 2017", "LFS 2006-07, 2012-13, 2014-15, 2018-19", "Wages of paid employees, economically active population, UNDP split, census female share", "Female 1,799 against 1,673 (2018-19)"],
  ["GDI: life expectancy by sex", "Global Human Development Report 2018", "As printed (2006-07, 2018-19). WDI for the series", "SP.DYN.LE00.FE.IN, SP.DYN.LE00.MA.IN", "External input"],
  ["GII: no prenatal or postnatal care", "PSLM 2005-06, 2018-19", "HIES 2018-19 sec_4d. HIES 2005-06 sec 4d. HIES 2011-12 sec_4d. PSLM 2014-15 sec_i", "s4dq01 = 1, s4dq2a = 2, s4dq11a = 2 (HIES). siq01, siq02, siq10 (PSLM)", "Within 0.5 points"],
  ["GII: early marriage, women 15-19", "LFS 2006-07, 2018-19", "LFS 2006-07, 2012-13, 2014-15, 2017-18 (LFS 2018-19 tested)", "Marital status 2, 3, 4", "12.6 against 20.0 percent (2018-19). 12.3 against 20.3 (2006-07)"],
  ["GII: primary or higher schooling", "PSLM 2005-06, 2018-19", "HIES 2005-06 sec 2a. HIES 2018-19 sec_2ab", "s2bq05 or s2bq14 of 5 or above, age 10+", "Within 0.6 points"],
  ["GII: labor force participation", "LFS 2006-07, 2018-19", "LFS 2006-07, 2012-13, 2014-15, 2017-18", "Economically active, age 10+", "Exact on LFS 2017-18. 17.9 against 19.6 (women, 2006-07)"],
  ["GII: seats in parliament", "Khan and Naqvi (2018)", "WDI", "SG.GEN.PARL.ZS", "Equal to NHDR's values"],
  ["LDI: all five dimensions", "LFS 2012-13, 2017-18. Pasha (2019)", "LFS 2012-13 (Stata), 2014-15, 2017-18 (SPSS), 2024-25. WDI GDP", "Wages, status, hours, occupation group (ISCO-08), education, formal sector, minimum wage", "Labor share 0.330 against 0.42"],
  ["Figure 4.8: Global Gender Gap Index", "WEF Global Gender Gap Report 2020", "WEF reports, 2006 to 2025", "Score and rank, transcribed with page and table", "External input"],
  ["Figure 5.19", "PDHS 2017-18", "PKHR71FL, PKKR71FL", "hv201 codes 11-14. h2-h9 coded 1-3 with b19 12-23. m15 codes 20-49", "Vaccination 65.6, facility delivery 66.2 against 66 and 66"],
];
body.push(table([1500, 1500, 1900, 2526, 1600], ["Indicator", "NHDR 2020 source, as stated", "Survey and file used", "Variables and rules", "Result"], A1));
body.push(tnote("Sources: NHDR 2020 Statistical Annex and technical notes, and do-file Sections 3 to 26A. ISCO-08 = International Standard Classification of Occupations 2008; WEF = World Economic Forum. Survey abbreviations as in the text."));

// ---------------------------------------------------------------- Annex 2
body.push(H1("ANNEX 2: HEADLINE COMPARISONS"));
const A2 = [
  ["HDI", "Pakistan", "2018-19", "0.570", "0.567", "-0.003"],
  ["HDI", "Punjab", "2018-19", "0.572", "0.582", "0.010"],
  ["HDI", "Sindh", "2018-19", "0.574", "0.561", "-0.013"],
  ["HDI", "Khyber Pakhtunkhwa", "2018-19", "0.546", "0.544", "-0.002"],
  ["HDI", "Balochistan", "2018-19", "0.473", "0.476", "0.003"],
  ["HDI", "Pakistan", "2006-07", "0.529", "0.516", "-0.013"],
  ["IHDI", "Pakistan", "2018-19", "0.534", "0.529", "-0.005"],
  ["Loss due to inequality (%)", "Pakistan", "2018-19", "6.26", "6.68", "0.42"],
  ["CDI", "Pakistan", "2018-19", "0.575", "0.573", "-0.002"],
  ["YDI", "Pakistan", "2017-18", "0.605", "0.604", "-0.001"],
  ["GDI (NHDR life expectancy by sex)", "Pakistan", "2018-19", "0.777", "0.793", "0.016"],
  ["GII", "Pakistan", "2018-19", "0.548", "0.519", "-0.029"],
  ["GII", "Pakistan", "2006-07", "0.582", "0.557", "-0.025"],
  ["LDI with decent work", "Pakistan", "2017-18", "0.442", "0.422", "-0.020"],
  ["HDI, Pasha 2018-19 income pattern", "Sindh", "2018-19", "0.574", "0.570", "-0.004"],
  ["HDI, Pasha 2014-15 income pattern", "Sindh", "2018-19", "0.574", "0.574", "0.000"],
  ["HDI, Pasha 2018-19 income pattern", "Khyber Pakhtunkhwa", "2018-19", "0.546", "0.553", "0.007"],
  ["Income per head (PPP $)", "Pakistan", "2018-19", "4,922", "4,925", "3"],
  ["Income per head (PPP $)", "Pakistan", "2006-07", "4,135", "3,350", "-785"],
  ["Under-five mortality (per 1,000)", "PDHS 2006-07", "5 years", "94", "94.17", "0.17"],
  ["Under-five mortality (per 1,000)", "PDHS 2012-13", "5 years", "89", "89.01", "0.01"],
  ["Under-five mortality (per 1,000)", "PDHS 2017-18", "5 years", "74", "74.00", "0.00"],
];
body.push(table([2400, 1900, 1100, 1200, 1200, 1226], ["Quantity", "Domain or survey", "Year", "Published", "Reproduced", "Difference"], A2, { numCols: [3, 4, 5] }));
body.push(tnote(`Sources: NHDR 2020 Tables 1 to 8, PDHS final reports (footnote ${firstNum[7]}), WDI (footnote ${firstNum[8]}), and reproduced values from the run in footnote ${firstNum[2]}. Every annex cell is in 3. Tables/NHDR2020 annex tables published vs reproduced.xlsx.`));

// ---------------------------------------------------------------- Annex 3
body.push(H1("ANNEX 3: THE PACKAGE AND HOW TO RUN IT"));
body.push(plain("The package folder is self-contained. Open Stata in the package folder or in 1. Dos and run the do file; it finds its own paths and writes each run to 8. Stata runs. Then run 7. Python tools/Build outputs.py in the conda environment named in README.txt to refresh folders 2 to 5 from the latest run. The do file never changes a raw file, and the Python tools copy rather than move."));
const A3 = [
  ["1. Dos", "The do file, Variable dictionary.csv (a descriptive name for every result column) and Output descriptions.csv (the headline of every workbook sheet)."],
  ["2. Notes", "This note in Word and PDF, Raw variable inventory.csv (Annex 4 as a table) and the file rename log."],
  ["3. Tables", "Annex Tables 1 to 8A, published against reproduced, one sheet each with a headline row, a CSV per table and Gap summary.json."],
  ["4. Plots", "1. Figures juxtaposed: each published figure beside its reproduction. 2. Figures reproduced NHDR style. 3. Figures published, cropped from the report. 4. Stata charts, kept for reference."],
  ["5. Output CSVs", "Every result table of the latest run (Results), the figure data (Figure data), Checks.txt, the Stata log and the results workbook."],
  ["6. Raw data", "Every input: survey microdata as released, the published values with their sources (Published, Sources register.csv) and the source documents."],
  ["7. Python tools", "Build outputs.py and the modules it calls: tables.py, figures.py, juxtapose.py, dictionary.py, inventory.py, naming.py, note.js, and the report's fonts."],
  ["8. Stata runs", "One folder per run, with its log, checks, results workbook, CSV and DTA files and charts."],
];
body.push(table([1900, 7126], ["Folder", "Contents"], A3));
body.push(tnote("File and folder names use spaces, never underscores. Survey files keep the names their publishers gave them so that each can be matched to its download."));

// ---------------------------------------------------------------- Annex 4
body.push(new Paragraph({ children: [new PageBreak()] }));
body.push(H1("ANNEX 4: SURVEY VARIABLES READ BY THE DO FILE"));
body.push(plain(`The do file reads ${inv.length} variables from the survey files. The table gives each with the label stored in the file, as the publisher wrote it, and the do-file sections that read it. An empty label means the file carries none. Columns of the LFS 2006-07 SPSS file have names Stata cannot use, so Stata reads them as _v followed by their position among such columns, and the table gives the meaning the do file assigns. 7. Python tools/inventory.py rebuilds this list from the do file and the survey files.`));
let lastSurvey = "";
const invRows = inv.map((r) => {
  const row = [r[0] === lastSurvey ? "" : r[0], r[1], r[2], r[3], r[4]];
  lastSurvey = r[0];
  return row;
});
body.push(table([1250, 1450, 1500, 3926, 900], ["Survey", "File", "Variable", "Label in the survey file", "Sections"], invRows,
  { size: 13, bandOn: (r) => r[0] !== "" }));
body.push(tnote("Source: the survey files in 6. Raw data, read with their own metadata, and the do file in 1. Dos. Section numbers follow the do file's section map."));

// ---------------------------------------------------------------- footnotes, resolved
const footnotes = {};
for (let n = 1; n <= fnCount; n++) {
  const src = noteSrc[n];
  const text = src > 0 ? FN[src].replace(/\{(\d+)\}/g, (_, k) => String(firstNum[k])) : `Footnote ${-src}.`;
  footnotes[n] = { children: [new Paragraph({ children: [new TextRun({ text, size: 16, color: GREY })] })] };
}

// ---------------------------------------------------------------- document
const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { font: "Arial", size: 25, bold: true, color: RED }, paragraph: { spacing: { before: 280, after: 140 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { font: "Arial", size: 22, bold: true, color: ORANGE }, paragraph: { spacing: { before: 180, after: 100 }, outlineLevel: 1 } },
    ],
    characterStyles: [
      { id: "FootnoteReference", name: "Footnote Reference", run: { superScript: true, color: "000000" } },
    ],
  },
  footnotes,
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: "NHDR 2020 reproduction", size: 16, color: GREY })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: [PageNumber.CURRENT], size: 16, color: GREY })] })] }) },
    children: body,
  }],
});
Packer.toBuffer(doc).then((b) => { fs.writeFileSync(OUT, b); console.log("written", OUT); });
