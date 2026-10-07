NHDR 2020 REPRODUCTION FROM SURVEY MICRODATA
============================================

This folder reproduces the subnational indices of UNDP Pakistan's National
Human Development Report 2020 (NHDR 2020) from the raw survey files, checks
every result against the printed tables, and carries the method to 2024-25.

Indices: Human Development Index (HDI), Inequality-adjusted HDI (IHDI), Child
Development Index (CDI), Youth Development Index (YDI), Gender Development
Index (GDI), Gender Inequality Index (GII), Labour Development Index (LDI), and
the Multidimensional Poverty Index (MPI).

Start with "2. Notes/NHDR2020 reproduction note.pdf": what was done, which
survey and variable feeds each indicator against what UNDP used, the results,
and the problems found. "2. Notes/NHDR2020 reproduction deck.pptx" gives the
same story in 15 slides, with editable charts and sources in the notes.


FOLDERS
-------
1. Dos             The Stata do file, and the two files its results workbook
                   reads: Variable dictionary.csv (a descriptive name for every
                   result column) and Output descriptions.csv (the headline of
                   every worksheet).
2. Notes           The technical note (Word and PDF), the slide deck, Raw
                   variable inventory.csv (every survey variable read, with its
                   label) and File rename log.csv.
3. Tables          NHDR Statistical Annex Tables 1 to 8A, published against
                   reproduced: one workbook (a sheet per table, each opening
                   with a description), a CSV per table and Gap summary.json.
4. Plots           1. Figures juxtaposed: each published figure beside its
                      reproduction, one PNG each and one PDF of all.
                   2. Figures reproduced NHDR style: the reproductions alone.
                   3. Figures published: the figures cropped from the report.
                   4. Stata charts: the charts Stata draws, kept for reference.
5. Output CSVs     Every result table of the latest run (Results), the figure
                   data (Figure data), Checks.txt, the Stata log and the
                   results workbook. Run.txt names the run they come from.
6. Raw data        Every input. See its own README.txt.
7. Python tools    Build outputs.py and the modules it calls, and the report
                   fonts (Fonts).
8. Stata runs      One folder per run of the do file.


HOW TO RUN
----------
Needs: Stata 16 or later; Python 3 with the packages in
"7. Python tools/requirements.txt"; for the Word note only, Node.js.

1. Stata. Open Stata, change directory to this folder (or to "1. Dos"), then
       do "1. Dos/NHDR2020 reproduction from microdata.do"
   About five minutes. The run writes "8. Stata runs/Run YYYYMMDD HHMMSS".
   Open Checks.txt there first: each check reads PASS or FAIL. The current
   run passes 301 of 302; the one failure (male wasting, NHDR Table 4A) is a
   known inconsistency in the report, explained in the note.
   Batch mode, from a command prompt in "1. Dos":
       "C:\Program Files\Stata18\StataSE-64.exe" /e do "NHDR2020 reproduction from microdata.do"

2. Python. From this folder:
       python "7. Python tools/Build outputs.py"
   It takes the latest complete run and refreshes folders 3, 4 and 5, the
   slide deck, and the Word note (if step 3 has been done once). On the machine this was built
   on, the environment is called adb-sindh:
       conda run -n adb-sindh python "7. Python tools/Build outputs.py"
   A new environment: pip install -r "7. Python tools/requirements.txt"

3. Word note (once). In "7. Python tools": npm install
   Then step 2 also rebuilds "2. Notes/NHDR2020 reproduction note.docx".
   Its text quotes the results of the run it was written for; the check
   count, run name and variable annex update on their own.

4. Variable dictionary (only when a result table gains a column). In this
   folder:  python "7. Python tools/dictionary.py" "8. Stata runs/Run YYYYMMDD HHMMSS"
   It lists any column without a descriptive name; add the name in
   dictionary.py and rerun.


CONVENTIONS
-----------
- File and folder names use spaces, never underscores. Survey files in
  "6. Raw data" keep their publishers' names so they can be matched to the
  downloads.
- Nothing is overwritten in "6. Raw data" or in an earlier run folder.
- "Reproduced" means computed from the microdata here. "As printed" marks an
  input no file on disk can supply, carried from the report so that an index
  can still be computed. "External" marks a non-survey series such as World
  Bank income or life expectancy by sex.
- A year the microdata cannot reproduce keeps its slot in a figure and reads
  n.a. Figure 4.12 (CDI by sex) is not reproduced: the report does not state
  how it splits income by sex.
- "8. Stata runs/Run 20261002 170407 stopped early, ignore" is a run that
  stopped on a path error while the folder was being reorganized. It is kept
  because nothing is deleted.

- Two sensitivity versions sit beside the main results. "HDI Pasha income.csv"
  sets each province's income to Pasha's published estimates (Section 20.7),
  to show how far NHDR's income column is from Pasha's. The LDI file carries
  lshare_fs and ldidw_fs, with Pasha's 2018-19 provincial GDP shares held
  fixed in every year (Section 25.2).
- The PSLM district rounds 2006-07 and 2008-09 are tested against NHDR's
  2006-07 and 2007-08 inputs ("PSLM district rounds tested.csv", Section
  23.6). They do not reproduce them better than HIES, so no index uses them.
