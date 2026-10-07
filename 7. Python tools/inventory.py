"""List every raw survey variable the do file reads, with its label from the survey file.

    python "7. Python tools/inventory.py"

Writes "2. Notes/Raw variable inventory.csv": survey, file, variable, the label
stored in the file itself, and the do-file sections that read it. A variable is
listed when the do file names it in the code that loads that file (from the
load statement to the next one). Labels are read from the .dta or .sav
metadata, so they are the publisher's own wording.
"""
import csv
import re
from pathlib import Path

import pyreadstat

ROOT = Path(__file__).resolve().parents[1]
DO = ROOT / "1. Dos" / "NHDR2020 reproduction from microdata.do"
RAW = ROOT / "6. Raw data"

SURVEY = {  # global -> (folder under 6. Raw data, survey name)
    "h05": ("HIES 2005-06", "HIES 2005-06"), "h07": ("HIES 2007-08", "HIES 2007-08"),
    "h11": ("HIES 2011-12", "HIES 2011-12"), "h15": ("HIES 2015-16/PBS Stata files", "HIES 2015-16"),
    "h18": ("HIES 2018-19", "HIES 2018-19"), "h24": ("HIES 2024-25", "HIES 2024-25"),
    "p14": ("PSLM 2014-15", "PSLM 2014-15"), "p19": ("PSLM 2019-20", "PSLM 2019-20"),
    "lfs06": ("LFS 2006-07", "LFS 2006-07"), "lfs12": ("LFS 2012-13", "LFS 2012-13"),
    "lfs14": ("LFS 2014-15", "LFS 2014-15"), "lfs17": ("LFS 2017-18", "LFS 2017-18"),
    "lfs": ("LFS 2018-19", "LFS 2018-19"), "lfs24": ("LFS 2024-25", "LFS 2024-25"),
    "pd06": ("PDHS/PK_2006-07_DHS_09292026_925_170967", "PDHS 2006-07"),
    "pd12": ("PDHS/PK_2012-13_DHS_09292026_924_170967", "PDHS 2012-13"),
    "pd17": ("PDHS/PK_2017-18_DHS_09292026_924_170967", "PDHS 2017-18"),
    "pmms": ("PDHS/PK_2019_MATERNALMORTALITYSURVEY_09292026_916_170967", "PMMS 2019"),
}
# What the do file takes each unlabeled LFS 2006-07 column to be (Section 22.2d).
USED_AS = {
    ("lfs2006-07.sav", "_v4"): "sex", ("lfs2006-07.sav", "_v5"): "age",
    ("lfs2006-07.sav", "_v6"): "marital status",
    ("lfs2006-07.sav", "_v18"): "employment question 1 (code 1 = employed)",
    ("lfs2006-07.sav", "_v19"): "employment question 2 (code 1 = employed)",
    ("lfs2006-07.sav", "_v20"): "employment question 3 (codes 1, 2 = employed)",
    ("lfs2006-07.sav", "_v24"): "status in employment (1 to 4 = paid employee)",
    ("lfs2006-07.sav", "_v50"): "weekly cash earnings",
    ("lfs2006-07.sav", "_v51"): "monthly cash earnings",
    ("lfs2006-07.sav", "_v113"): "unemployment question (1 to 5 = active)",
}
_PERS = ["hhcode", "idc", "age", "psu", "province", "region", "scq01", "scq05", "scq06"]
_KIDS = ["hhcode", "psu", "province", "year_c", "month_c", "shq5_1", "shq5_4", "shq5_7"]
PSLM_TESTED = [
    ("PSLM 2006-07", "PSLM 2006-07", "section b.dta", ["hhcode", "idc", "age"]),
    ("PSLM 2006-07", "PSLM 2006-07", "section c.dta", _PERS),
    ("PSLM 2006-07", "PSLM 2006-07", "section h.dta", _KIDS),
    ("PSLM 2006-07", "PSLM 2006-07", "sec_a.dta", ["hhcode", "month", "year"]),
    ("PSLM 2006-07", "PSLM 2006-07", "hhweights.dta", ["hhcode", "weights"]),
    ("PSLM 2008-09", "PSLM 2008-09", "sec_b.dta", ["hhcode", "idc", "age"]),
    ("PSLM 2008-09", "PSLM 2008-09", "sec_c.dta", _PERS),
    ("PSLM 2008-09", "PSLM 2008-09", "section_h.dta", _KIDS),
    ("PSLM 2008-09", "PSLM 2008-09", "sec_a.dta", ["hhcode", "int_date"]),
    ("PSLM 2008-09", "PSLM 2008-09", "weights_file.dta", ["psu", "weights"]),
]
# A file is named as "$global/file" or, for PMMS, as "`pmms'/file".
PATH = re.compile(r"(?:\$|`)(" + "|".join(sorted(SURVEY, key=len, reverse=True))
                  + r")'?/([^\"|]+?\.(?:dta|DTA|sav))")
TOKEN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def read_meta(path):
    reader = pyreadstat.read_sav if path.suffix.lower() == ".sav" else pyreadstat.read_dta
    try:
        _, m = reader(str(path), metadataonly=True)
    except pyreadstat.ReadstatError:
        # older Stata files store labels in a Windows code page
        _, m = reader(str(path), metadataonly=True, encoding="latin1")
    return m.column_names_to_labels


def main():
    lines = DO.read_text(encoding="utf-8").split("\n")
    section = []
    cur = "0"
    for l in lines:
        m = re.match(r"\* SECTION (\w+)", l)
        if m:
            cur = m.group(1)
        section.append(cur)
    # Section 0 only checks that each file exists, so it does not count as a read.
    hits = [(i, m.group(1), m.group(2)) for i, l in enumerate(lines) for m in PATH.finditer(l)
            if section[i] != "0" and not l.lstrip().startswith("*")]
    # group path-bearing lines that sit together (a foreach list of files)
    groups, last = [], -10
    for i, g, f in hits:
        if i - last > 2:
            groups.append([])
        groups[-1].append((i, g, f))
        last = i
    starts = [grp[0][0] for grp in groups] + [len(lines)]
    found = {}
    # MICS6 birth histories are read in one loop under a local path
    mics = sorted((RAW / "MICS6").glob("*/bh.sav"))
    for gi, grp in enumerate(groups):
        a, b = grp[0][0], min(starts[gi + 1], grp[0][0] + 400)
        block = [l.split("//")[0] for l in lines[a:b] if not l.lstrip().startswith("*")]
        toks = set(TOKEN.findall("\n".join(block)))
        for i, g, f in grp:
            folder, survey = SURVEY[g]
            path = RAW / folder / f
            if not path.exists():
                continue
            meta = read_meta(path)
            low = {k.lower(): k for k in meta}
            # Stata's import spss renames the n-th column whose SPSS name is not a
            # valid Stata name (LFS 2006-07: SECTION_4.4.5 and so on) to _vn.
            bad = [k for k in meta if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]{0,31}", k)]
            for t in toks:
                k = low.get(t.lower())
                m = re.fullmatch(r"_v(\d+)", t)
                if k is None and m and path.suffix.lower() == ".sav" and int(m.group(1)) <= len(bad):
                    k = bad[int(m.group(1)) - 1]
                    meta = dict(meta)
                    use = USED_AS.get((f, t), "")
                    meta[k] = (f"{meta[k] or 'no label in file'}, read in Stata as {t}"
                               + (f", used as {use}" if use else ""))
                if k is None:
                    continue
                key = (survey, f, k)
                found.setdefault(key, [meta[k] or "", set()])[1].add(section[i])
    i_mics = next(i for i, l in enumerate(lines) if "$mics/`d'/bh.sav" in l)
    toks = set(TOKEN.findall("\n".join(lines[i_mics:i_mics + 140])))
    for p in mics:
        meta = read_meta(p)
        low = {k.lower(): k for k in meta}
        for t in toks:
            k = low.get(t.lower())
            if k:
                found.setdefault((f"MICS6 {p.parent.name}", "bh.sav", k), [meta[k] or "", set()])[1].add("8")
    # Section 23.6 reads the PSLM district rounds through program arguments, so
    # their files are listed here by hand, with the variables the program names.
    for survey, folder, fname, cols in PSLM_TESTED:
        path = RAW / folder / fname
        if not path.exists():
            continue
        meta = read_meta(path)
        for v in cols:
            if v in meta:
                found.setdefault((survey, fname, v), [meta[v] or "", set()])[1].add("23")
    out = ROOT / "2. Notes" / "Raw variable inventory.csv"
    with open(out, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["Survey", "File", "Variable", "Label in the survey file", "Do-file sections"])
        for (s, f, v), (lab, secs) in sorted(found.items()):
            w.writerow([s, f, v, lab, ", ".join(sorted(secs, key=lambda x: (len(x), x)))])
    print(len(found), "variables written to", out)


if __name__ == "__main__":
    main()
