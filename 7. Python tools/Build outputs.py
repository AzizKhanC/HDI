"""
Refresh folders 2 to 5 of the package from one Stata run.

Run this after the do file in "1. Dos" has finished. From the package folder:

    cd "D:\Aziz\Development\HDI\stata\NHDR2020 replication from microdata"
    conda run -n adb-sindh python "7. Python tools/Build outputs.py"
    conda run -n adb-sindh python "7. Python tools/Build outputs.py" "8. Stata runs/Run 20261002 172234" //change to latest

With no argument it takes the latest complete run in "8. Stata runs" (one that
reached the end and wrote its results workbook). It copies, never moves: the
run folder stays as Stata wrote it, and files of the same name in folders 3 to
5 are replaced by this run's versions. It then rebuilds the Word note in
"2. Notes" if Node.js and the docx package are installed (see README.txt).

What it writes
    3. Tables                                  annex Tables 1 to 8A, published against reproduced
    4. Plots/1. Figures juxtaposed             each published figure beside its reproduction
    4. Plots/2. Figures reproduced NHDR style  the reproduced figures and maps on their own
    4. Plots/3. Figures published              the published figures cropped from the report
    4. Plots/4. Stata charts                   the charts Stata draws, and their side-by-side pages
    5. Output CSVs                             every result table, the checks and the log
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import figures
import inventory
import juxtapose
import tables

ROOT = HERE.parent
RUNS = ROOT / "8. Stata runs"
RESULTS_XLSX = "NHDR replication results.xlsx"


def latest_run():
    done = [p for p in RUNS.glob("Run *") if (p / RESULTS_XLSX).exists()]
    if not done:
        sys.exit(f"No complete run in {RUNS}. Run the do file in '1. Dos' first.")
    return max(done, key=lambda p: p.name)


def main(run=None):
    run = Path(run) if run else latest_run()
    if not run.is_absolute():
        run = ROOT / run
    print("building from", run.name)
    plots = ROOT / "4. Plots"
    d = {"tables": ROOT / "3. Tables",
         "side": plots / "1. Figures juxtaposed",
         "nhdr": plots / "2. Figures reproduced NHDR style",
         "pub": plots / "3. Figures published",
         "charts": plots / "4. Stata charts" / "Charts",
         "charts_side": plots / "4. Stata charts" / "Side by side",
         "out": ROOT / "5. Output CSVs"}
    for p in d.values():
        p.mkdir(parents=True, exist_ok=True)

    tables.main(run, d["tables"])
    figures.main(run, d["nhdr"])
    juxtapose.export_published(d["pub"])
    juxtapose.main("nhdr", d["nhdr"], d["side"])
    for f in list(run.glob("Figure *.png")) + list(run.glob("Map *.png")):
        shutil.copy2(f, d["charts"] / f.name)
    juxtapose.main("stata", run, d["charts_side"])

    res, figd = d["out"] / "Results", d["out"] / "Figure data"
    res.mkdir(exist_ok=True)
    figd.mkdir(exist_ok=True)
    for f in run.glob("*.csv"):
        shutil.copy2(f, (figd if f.name.startswith("Figure ") else res) / f.name)
    for name in ["Checks.txt", "NHDR replication.log", RESULTS_XLSX]:
        if (run / name).exists():
            shutil.copy2(run / name, d["out"] / name)
    (d["out"] / "Run.txt").write_text(
        f"Folders 3 to 5 were built from '8. Stata runs/{run.name}'.\n", encoding="utf-8")

    # The Word note, if Node.js and the docx package are available.
    # The docx package is found in this folder (after npm install) or on NODE_PATH.
    note = HERE / "note.js"
    have_docx = (HERE / "node_modules" / "docx").exists() or any(
        (Path(p) / "docx").exists() for p in os.environ.get("NODE_PATH", "").split(os.pathsep) if p)
    if shutil.which("node") and have_docx:
        inventory.main()
        target = ROOT / "2. Notes" / "NHDR2020 reproduction note.docx"
        subprocess.run(["node", str(note), str(target), str(run)], check=True, cwd=HERE)
        print("note written to", target)
    else:
        print("Word note skipped: run 'npm install' in '7. Python tools' to enable it.")
    # The slide deck (python-pptx), from the same run.
    import deck
    deck.main(run)
    print("done")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
