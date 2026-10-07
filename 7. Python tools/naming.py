"""File-naming rule shared by every tool in this folder.

Stata and the Python tools write file names with spaces, never underscores.
tidy() turns an internal key such as "fig_2_18_ihdi_loss" into the file name
stem "Figure 2.18 IHDI loss", so both sides agree on every name.
"""
import re

ACRONYMS = {
    "hdi", "ihdi", "gdi", "gii", "ydi", "cdi", "ldi", "mpi", "lfs", "hies",
    "pslm", "pdhs", "pmms", "wef", "gggi", "grp", "wdi", "undp", "nhdr", "pbs",
    "ocac", "cmi", "gva", "le", "adm1", "kp", "pci", "u5mr", "ppp", "na",
    "ipr", "br", "lcu", "cpi", "kpbos", "pide", "sbos", "mopdsi", "unicef",
    "ophi", "icf", "nips", "hdro", "dhs", "mics", "mics6", "pes", "sr257",
    "json", "html", "pdf", "gdp", "gni", "lfpr", "t4", "csv",
}
SPECIAL = {"rebuilt": "reproduced", "minwage": "minimum wage",
           "pakistan": "Pakistan", "geoboundaries": "geoBoundaries"}


def tidy(stem: str) -> str:
    """Return a readable, underscore-free version of an internal file stem."""
    t = [x for x in re.split(r"[_]+", stem) if x != ""]
    out = []
    i = 0
    while i < len(t):
        w = t[i]
        nxt = t[i + 1] if i + 1 < len(t) else ""
        # fig_2_18 -> Figure 2.18 ; fig_map_4_1 -> Map 4.1 ; figure_2_18 -> Figure 2.18
        if w.lower() in ("fig", "figure") and nxt.lower() == "map" and i + 3 < len(t):
            out.append(f"Map {t[i + 2]}.{t[i + 3]}")
            i += 4
            continue
        if w.lower() in ("fig", "figure", "map") and nxt.isdigit() and i + 2 < len(t) and t[i + 2].isdigit():
            out.append(f"{'Map' if w.lower() == 'map' else 'Figure'} {nxt}.{t[i + 2]}")
            i += 3
            continue
        if w.lower() == "fig":
            out.append("Figure")
            i += 1
            continue
        # 2018_19 -> 2018-19 ; 1990_91 -> 1990-91
        if re.fullmatch(r"\d{4}", w) and re.fullmatch(r"\d{2}", nxt):
            out.append(f"{w}-{nxt}")
            i += 2
            continue
        m = re.fullmatch(r"(nhdr2020)?table(\d+)([a-z]?)", w.lower())
        if m:
            out.append(("NHDR2020 " if m.group(1) else "") + f"Table {m.group(2)}{m.group(3).upper()}")
            i += 1
            continue
        m = re.fullmatch(r"table0?(\d+)", w, flags=re.I)
        if m:
            out.append(f"Table {m.group(1)}")
            i += 1
            continue
        if w.lower() in ACRONYMS:
            out.append(w.upper())
        elif w.lower() in SPECIAL:
            out.append(SPECIAL[w.lower()])
        elif w.lower() == "nhdr2020":
            out.append("NHDR2020")
        else:
            out.append(w)
        i += 1
    s = " ".join(out)
    return s[:1].upper() + s[1:]


def tidy_name(name: str) -> str:
    """tidy() applied to a file name, keeping its extension."""
    if "." in name:
        stem, ext = name.rsplit(".", 1)
        return f"{tidy(stem)}.{ext}"
    return tidy(name)


if __name__ == "__main__":
    for s in ["fig_2_18_ihdi_loss", "fig_map_4_1_cdi_2018_19", "cdi_rebuilt_2007_08_2018_19",
              "table2a_education_replication_2018_19", "nhdr2020_table2a", "cdi_method_table4",
              "nhdr_replication", "checks", "figure_2_18", "figure_2_18_p25", "Table_2A",
              "pak_adm1_geoboundaries_coordinates", "wdi_pakistan_by_sex", "lfs_population_minwage",
              "extract_pbs_na_table2", "PBS_Census_2017_Table01_population_by_sex", "map_4_1",
              "pdhs_q5", "mics6", "gap_summary", "hdr2020_technical_notes"]:
        print(f"{s:45s} -> {tidy(s)}")
