*==============================================================================*
*   NHDR 2020 REPRODUCTION FROM SURVEY MICRODATA
*
*   Reproduces the subnational indices of UNDP Pakistan's National Human
*   Development Report 2020 (NHDR 2020, "The Three Ps of Inequality") from
*   the raw survey files, checks every result against the printed tables,
*   and reproduces forward to the 2024-25 surveys.
*
*   File      NHDR2020 reproduction from microdata.do 
*   Author    Aziz Khan
*   Version    October 2026
*   Requires  Stata 16 or later. Runs in about five minutes on Stata 18 SE.
*==============================================================================*
*==============================================================================*

* Processing steps
* ----------
* 1. Open "1. Dos".
* 2. run "NHDR2020 reproduction from microdata.do"
* 3. You get your outputs ina new folder "8. Stata runs/Run YYYYMMDD HHMMSS".
* 4. To refresh the tables, figures and note in folders 2 to 5, run 7. Python tools/Build outputs.py" (see the package README.txt).
* This would need a separates env and might need a bit 

* What does this do file intend to replicate?
* ------------------
* NHDR 2020 Statistical Annex Tables 1 to 8A for 2006-07 and 2018-19, by province and urban or rural area:
*   HDI    Human Development Index                   Tables 1, 2A
*   IHDI   Inequality-adjusted Human Development Index   Table 3 ITheir version of HDI to capture inequality across the quintiles
*   CDI    Child Development Index                   Tables 4, 4A
*   YDI    Youth Development Index                   Tables 5, 5A
*   GDI    Gender Development Index                  Tables 6, 6A
*   GII    Gender Inequality Index                   Tables 7, 7A
*   LDI    Labour Development Index                  Tables 8, 8A

* To top it off:
* It adds the Multidimensional Poverty Index (MPI) of 2014-15 and 2019-20,
* a district and divisional HDI from PSLM 2019-20, every index for 2024-25,
* we juxtapose the visualizations throughout the UNHDR report against this excercise to compare where we might be veering off.

* Abbreviations 
* -------------------------------
*   HIES   Household Integrated Economic Survey, PBS (2005-06 to 2024-25)
*   PSLM   Pakistan Social and Living Standards Measurement survey
*   LFS    Labour Force Survey, PBS (2006-07 to 2024-25)
*   PDHS   Pakistan Demographic and Health Survey, NIPS and ICF. We had to register on the DHS website for this.
*   PMMS   Pakistan Maternal Mortality Survey 2019, NIPS and ICF, Same
*   MICS6  Multiple Indicator Cluster Surveys, round 6, UNICEF and the provincial bureaus of statistics
*   PBS    Pakistan Bureau of Statistics
*   WDI    World Development Indicators, World Bank
*   GRP    gross regional (provincial) product.Dr Pasha's work and articles go into much more detail.Two words Needs improvements,
*   PPP    purchasing power parity
*   CMC    century month code, the DHS and MICS date format

* Structure
* -----------
*   0    Setup: paths, output folder, log, checks file
*   1    Helper programs used throughout
*   2    Published reference values
*   3    Adult literacy, HIES 2018-19, against Table 2A
*   4    Net enrolment, level matched, against Table 2A (we call it ner)
*   5    The HDI construction
*   6    The current UNDP HDI construction, an external benchmark
*   7    Life expectancy from the HDI health index
*   8    Under-five mortality from the MICS6 birth histories
*   8A   Under-five mortality, stunting and wasting from PDHS 2006-07,2012-13 and 2017-18, and Figure 5.19
*   9    Gross regional product by province, Pasha's allocation. This is the main bone of contention. Multiple roads and multiple destination. *asha has written articles excoriating this  failure to document GRP. India does it.
*   10   HDR's income column: level, ranking, scale, We try to suss it out through different approaches. Would need confirmation. 
*   11   HIES 2024-25: We clean and check the new survey against PBS published benchmarks.
*   12   The HDI 2024-25 
*   13   The HDI 2024-25 on price basis, and its decomposition  since 2018-19
*   14   District education from PSLM 2019-20, with standard errors (helps us answer how sure are we>)
*   15   The district and divisional HDI
*   16   Inequality-adjusted Human Development Index (IHDI), Table 3
*   17   Gender Development Index (GDI), Tables 6 and 6A
*   18   Gender Inequality Index (GII), Tables 7 and 7A
*   19   Multidimensional Poverty Index (MPI), PSLM 2019-20
*   20   The 2006-07 columns from HIES 2005-06: education, GDI, GII, IHDI;
*        the HDI with every dimension from microdata (20.6) and with Pasha's
*        provincial income (20.7)
*   21   MPI 2014-15 and the change to 2019-20
*   22   The LFS rounds read on one basis (2006-07 to 2024-25)
*   23   Child Development Index (CDI), Tables 4 and 4A; PSLM 2006-07 and
*        2008-09 tested against the 2007-08 inputs (23.6)
*   24   Youth Development Index (YDI), Tables 5 and 5A
*   25   Labour Development Index (LDI), Tables 8 and 8A
*   26A  The four-year series behind the report figures
*   26   The report figures and maps
*   27   Summary of checks and the results workbook

*  What do get after the do run  8. Stata runs/Run YYYYMMDD HHMMSS")
* -----------------------------------------------------------------
*   NHDR replication.log            the full log
*   Checks.txt                      every validation check, PASS or FAIL
*   NHDR replication results.xlsx   one worksheet per results table, with a headline row and descriptive column names
*                                   (from "Output descriptions.csv" and
*                                   "Variable dictionary.csv" in "1. Dos")
*   *.csv, *.dta                    each results table on its own
*   Figure *.png, Map *.png         the charts of Sections 8A, 26 and 27

* Rules
* -----------
*   Province codes, after recoding in every survey: 1 Khyber Pakhtunkhwa,
*   2 Punjab, 3 Sindh, 4 Balochistan. Region: 1 rural, 2 urban. HIES 2005-06  numbers both the other way round and is recoded in Section 20.
*   Domains are Pakistan, the four provinces and the urban and rural part of each: 15 in all, the rows of NHDR Table 1.
*   Published files are read with asdouble, so that a value printed as 0.475
*   is compared as 0.475 and not as its nearest single-precision number.
*   A "published" check compares a result with the figure NHDR, PBS, MICS or UNDP . A "reference" check compares it with the value an
*   independent Python implementation produced from the same raw files.This 2Xs our confidence. UNDP might prefer python as they mentioned it one of the meetings
*   Each check label starts with a step number: Step n is Section n + 2  (Step 5A is Section 8A, Step 23A is Section 26A). Ease for looping and naming.


*==============================================================================*
* SECTION 0   SETUP
*==============================================================================*

version 16
clear all
set more off
set varabbrev off          // prevent Stata from guessing a variable name
set type double            // every new numeric variable is double precision
set linesize 160
set sortseed 20260925      // makes the order of tied observations repeatable

* ---- 0.1 Paths --------------------------------------------------------------
* root is the package folder, the one that holds "1. Dos" and "6. Raw data".
* Start Stata in either folder and root is found on its own. To run from
* anywhere else, set it first, for example:
*   global root "D:/Aziz/Development/HDI/stata/NHDR2020 replication from microdata"
if `"$root"' == "" {
    mata: st_local("here_ok", strofreal(direxists("6. Raw data")))
    mata: st_local("up_ok",   strofreal(direxists("../6. Raw data")))
    if `here_ok' global root `"`c(pwd)'"'
    else if `up_ok' {
        local here `"`c(pwd)'"'
        quietly cd ..
        global root `"`c(pwd)'"'
        quietly cd `"`here'"'
    }
    else {
        display as error `"Cannot find "6. Raw data". Set global root to the package folder."'
        exit 601
    }
}

global raw  "$root/6. Raw data"
global h18  "$raw/HIES 2018-19"        // HIES 2018-19, the NHDR 2020 base year
global h24  "$raw/HIES 2024-25"        // HIES 2024-25, the latest round
global p19  "$raw/PSLM 2019-20"        // PSLM 2019-20, the district round
global lfs  "$raw/LFS 2018-19"         // Labour Force Survey 2018-19
global lfs24 "$raw/LFS 2024-25"        // Labour Force Survey 2024-25
global h05  "$raw/HIES 2005-06"        // HIES 2005-06, NHDR's "2006-07" education
global h07  "$raw/HIES 2007-08"        // HIES 2007-08, the CDI's first year
global p14  "$raw/PSLM 2014-15"        // PSLM 2014-15, the first MPI round
global lfs12 "$raw/LFS 2012-13"        // Labour Force Survey 2012-13
global lfs17 "$raw/LFS 2017-18"        // Labour Force Survey 2017-18
global mics "$raw/MICS6"               // MICS6 birth histories, four provinces
global pub  "$raw/Published"           // published figures, with sources
global geo  "$raw/Geo"                 // province polygons for the maps
global pdhs "$raw/PDHS"                // PDHS recode files, three rounds
global pd06 "$pdhs/PK_2006-07_DHS_09292026_925_170967"   // PDHS 2006-07, as downloaded
global pd12 "$pdhs/PK_2012-13_DHS_09292026_924_170967"   // PDHS 2012-13
global pd17 "$pdhs/PK_2017-18_DHS_09292026_924_170967"   // PDHS 2017-18
* Rounds added for the figures' intermediate years (Section 26A).
global h11  "$raw/HIES 2011-12"           // HIES 2011-12, NHDR's "2012-13"
global h15  "$raw/HIES 2015-16/PBS Stata files"   // HIES 2015-16
global lfs14 "$raw/LFS 2014-15"        // Labour Force Survey 2014-15 (PBS SPSS release)
global lfs06 "$raw/LFS 2006-07"        // Labour Force Survey 2006-07 (PBS SPSS release)
global p06  "$raw/PSLM 2006-07"        // PSLM 2006-07 district round
global p08  "$raw/PSLM 2008-09"        // PSLM 2008-09 district round

* ---- 0.2 A new output folder for every run -----------------------------------
* The folder name has date and time of the run. Prevents overwriting.

local rundate = string(date(c(current_date), "DMY"), "%tdCCYYNNDD")
local runtime = subinstr(c(current_time), ":", "", .)
capture mkdir "$root/8. Stata runs"
global out "$root/8. Stata runs/Run `rundate' `runtime'"
capture mkdir "$out"
* Two runs started in the same second would share a folder. Stop ratherthan write over the first run.
capture confirm new file "$out/NHDR replication.log"
if _rc {
    display as error "Output folder $out is already in use. Wait a second and rerun."
    exit 602
}

* ---- 0.3 Log -----------------------------------------------------------------

capture log close _all
log using "$out/NHDR replication.log", text name(main)

display as text _n "NHDR 2020 replication, run started `c(current_date)' `c(current_time)'"
display as text "root   : $root"
display as text "output : $out" _n

* ---- 0.4 Confirm that every raw file is where the do file expects it --------

* The PDHS rounds  from the DHS Program as one zip per round. If round's folder does not exist yet but its zip does, the zip is unpacked. 
* in place with the official unzipfile command. Redundant after the first run
*HDS needs registeration and verification before they give  access

foreach b in "PK_2006-07_DHS_09292026_925_170967" "PK_2012-13_DHS_09292026_924_170967" ///
    "PK_2017-18_DHS_09292026_924_170967" {
    local probe = cond(strpos("`b'", "2006-07"), "PKBR53DT/PKBR53FL.DTA", ///
        cond(strpos("`b'", "2012-13"), "PKBR61DT/PKBR61FL.DTA", "PKBR71DT/PKBR71FL.DTA"))
    capture confirm file "$pdhs/`b'/`probe'"
    if _rc {
        capture confirm file "$pdhs/`b'.zip"
        if !_rc {
            local here `"`c(pwd)'"'
            capture mkdir "$pdhs/`b'"
            quietly cd "$pdhs/`b'"
            capture noisily unzipfile "$pdhs/`b'.zip", replace
            quietly cd `"`here'"'
        }
    }
}

* A missing file stops the run here, with its name, rather than halfway

local need
local need `"`need' "$h18/plist.dta" "$h18/sec_2ab.dta" "$h18/sec_6a.dta" "$h18/sec_10a.dta""'
local need `"`need' "$h18/sec_10b.dta" "$h18/sec_12ce.dta" "$h18/weight.dta""'
local need `"`need' "$h24/section_info.dta" "$h24/plist_roster.dta" "$h24/sec_2ab_education.dta""'
local need `"`need' "$h24/weight.dta" "$h24/sec_6a_consum_exp.dta""'
local need `"`need' "$p19/plist.dta" "$p19/secc1.dta" "$p19/sece.dta" "$lfs/LFS 2018-19.dta""'
local need `"`need' "$mics/Punjab 2017-18/bh.sav" "$mics/Sindh 2018-19/bh.sav""'
local need `"`need' "$mics/KP 2019/bh.sav" "$mics/Balochistan 2019-20/bh.sav""'
local need `"`need' "$pub/NHDR2020 Table 1.csv" "$pub/NHDR2020 Table 2A.csv""'
local need `"`need' "$pub/WDI Pakistan.csv" "$pub/Published benchmarks.csv""'
local need `"`need' "$pub/Model life tables.csv" "$pub/PDHS 2017-18 mortality.csv""'
local need `"`need' "$pub/PBS GVA subsector.csv" "$pub/PBS national accounts.csv""'
local need `"`need' "$pub/OCAC petroleum consumption.csv" "$pub/PBS electricity generation.csv""'
local need `"`need' "$pub/PBS CMI 2015-16.csv" "$pub/GRP published estimates.csv""'
local need `"`need' "$pub/Census 2017 population.csv""'
local need `"`need' "$h18/sec_4d.dta" "$h24/Sec_04d_pre_post_natal.dta" "$lfs24/LFS 2024-25.dta""'
local need `"`need' "$p19/secf1.dta" "$p19/secf2.dta" "$p19/secg.dta" "$p19/sech.dta""'
local need `"`need' "$p19/seci.dta" "$p19/secj.dta""'
local need `"`need' "$pub/NHDR2020 Table 3.csv" "$pub/NHDR2020 Table 6.csv" "$pub/NHDR2020 Table 7.csv""'
local need `"`need' "$pub/PBS LFS refined LFPR.csv" "$pub/Census female share.csv""'
local need `"`need' "$pub/WDI Pakistan by sex.csv" "$pub/Published benchmarks indices.csv""'
local need `"`need' "$pub/MPI 2019-20 published.csv" "$pub/MPI 2019-20 uncensored published.csv""'
local need `"`need' "$h05/roster with weights.dta" "$h05/sec 2a.dta" "$h05/sec6abcd.dta" "$h05/sec 4d.dta""'
local need `"`need' "$h07/plist.dta" "$h07/sec2a.dta" "$h07/sec3b.dta" "$h07/sec 6abcde.dta""'
local need `"`need' "$h18/sec_3b.dta" "$h24/Sec_03b_immunisation.dta""'
local need `"`need' "$p14/plist.dta" "$p14/sec_a.dta" "$p14/sec_c.dta" "$p14/sec_f1.dta" "$p14/sec_f2.dta""'
local need `"`need' "$p14/sec_g.dta" "$p14/sec_h.dta" "$p14/sec_i.dta""'
local need `"`need' "$lfs12/LFS-2012-13.dta" "$lfs17/LFS 2017-18.sav""'
local need `"`need' "$pub/NHDR2020 Table 4.csv" "$pub/NHDR2020 Table 5.csv" "$pub/NHDR2020 Table 8.csv""'
local need `"`need' "$pub/MPI 2014-15 harmonized published.csv" "$pub/PSLM district crosswalk 2014-15 2019-20.csv""'
local need `"`need' "$pub/WDI Pakistan CPI.csv" "$pub/WDI Pakistan GDP current LCU.csv" "$pub/LFS population minimum wage.csv""'
local need `"`need' "$geo/Pak ADM1 geoBoundaries coordinates.csv""'
* Section 26A: the intermediate rounds of the figures, and two published series.
local need `"`need' "$h11/plist.dta" "$h11/sec_2a.dta" "$h11/sec_6abcde.dta" "$h11/sec_4d.dta" "$h11/hh_weight.dta""'
local need `"`need' "$h15/plist.dta" "$h15/sec_2a.dta" "$h15/sec_4abcde.dta""'
local need `"`need' "$lfs14/LFS-2014-15.sav" "$lfs06/lfs2006-07.sav""'
local need `"`need' "$p06/section b.dta" "$p06/section c.dta" "$p06/section h.dta" "$p06/sec_a.dta""'
local need `"`need' "$p06/hhweights.dta" "$p08/sec_b.dta" "$p08/sec_c.dta" "$p08/section_h.dta""'
local need `"`need' "$p08/sec_a.dta" "$p08/weights_file.dta""'
local need `"`need' "$pub/WEF GGGI Pakistan.csv" "$pub/WDI Pakistan parliament.csv" "$pub/WDI Pakistan by sex.csv""'
local need `"`need' "$pd06/PKBR53DT/PKBR53FL.DTA" "$pd06/PKPR53DT/PKPR53FL.DTA""'
local need `"`need' "$pd12/PKBR61DT/PKBR61FL.DTA" "$pd12/PKPR61DT/PKPR61FL.DTA""'
local need `"`need' "$pd17/PKBR71DT/PKBR71FL.DTA" "$pd17/PKKR71DT/PKKR71FL.DTA""'
local need `"`need' "$pd17/PKPR71DT/PKPR71FL.DTA" "$pd17/PKHR71DT/PKHR71FL.DTA""'
foreach f of local need {
    capture confirm file `"`f'"'
    if _rc {
        display as error `"Missing raw file: `f'"'
        display as error "See 6. Raw data/README.txt for where each file comes from."
        exit 601
    }
}
display as text "All raw input files found." _n



* ---- 0.5 Checks file and counters ---------------------------------------------

* STRICT = 0 reports failed checks and carries on. STRICT = 1 stops at the
* first failed check.
global STRICT = 0
global NCHK   = 0
global NFAIL  = 0
global NFIG   = 0          // figures attempted (Sections 8A and 26)
global NFIGOK = 0          // figures written
file open chk using "$out/Checks.txt", write text
file write chk "status" _tab "check" _tab "computed" _tab "target" _tab "tolerance" _n


*==============================================================================*
* SECTION 1   HELPER PROGRAMS
*==============================================================================*

* Fifteen helper programs 

* ---- 1.1 nhdr_check: record one validation check ------------------------------

* label : what is being checked
* got   : the value the do file computed
* want  : the target, a published figure or the reference result
* tol   : tolerance: the largest absolute difference accepted as a match

capture program drop nhdr_check
program define nhdr_check
    syntax , LABel(string) GOT(string) WANT(real) TOL(real)
    local g = `got'
    local d = abs(`g' - `want')
    global NCHK = $NCHK + 1
    if `d' <= `tol' local status "PASS"
    else {
        local status "FAIL"
        global NFAIL = $NFAIL + 1
    }
    display as text "`status'  " as result %-66s `"`label'"' ///
        as text "  computed " as result %12.4f `g' ///
        as text "  target " as result %12.4f `want' ///
        as text "  tol " as result %7.4f `tol'
    file write chk "`status'" _tab `"`label'"' _tab %14.6f (`g') _tab ///
        %14.6f (`want') _tab %9.4f (`tol') _n
    if "`status'" == "FAIL" & $STRICT == 1 {
        display as error "A check failed and STRICT is 1. Stopping."
        exit 9
    }
end

* ---- 1.2 nhdr_stack_domains: put each record in its reporting domains/strata  -------
* Every person or household belongs to four of the 15 NHDR domains: Pakistan,
* Pakistan urban or rural, its province, and its province urban or ruraldomain, so that a single collapse by domain produces all 15 rows at once
* The program makes four copies of each record and labels each copy with one.
* Domain labels match the region column of the published tables exactly, for example "Khyber Pakhtunkhwa-Rural".

capture program drop nhdr_stack_domains
program define nhdr_stack_domains
    syntax , PROVince(varname) REGion(varname)
    tempvar pid copy pname rname
    gen long `pid' = _n
    expand 4
    bysort `pid': gen byte `copy' = _n
    gen str18 `pname' = ""
    replace `pname' = "Khyber Pakhtunkhwa" if `province' == 1
    replace `pname' = "Punjab"             if `province' == 2
    replace `pname' = "Sindh"              if `province' == 3
    replace `pname' = "Balochistan"        if `province' == 4
    gen str5 `rname' = ""
    replace `rname' = "Rural" if `region' == 1
    replace `rname' = "Urban" if `region' == 2
    gen str30 domain = ""
    replace domain = "Pakistan"                  if `copy' == 1
    replace domain = "Pakistan-" + `rname'       if `copy' == 2 & `rname' != ""
    replace domain = `pname'                     if `copy' == 3
    replace domain = `pname' + "-" + `rname'     if `copy' == 4 & `pname' != "" & `rname' != ""
    * A record with a missing province or region stays in the domains it
    * can be placed in and is dropped from the others.
    drop if domain == ""
end

* ---- 1.3 nhdr_quintile: equal-population quintiles within a group -----------

* Records are sorted on per capita welfare within each group, the weight is
* cumulated, and quintile = ceil(5 x cumulative share of the weight), kept between 1 and 5. Records with missing welfare or weight get no quintile.
* The cut is over everyone in the group, not only over the population in an indicator's own universe.
* Poorer households hold more children, so the
* 15-and-over population is not spread 20 percent per quintile, and the
* published quintile rows do not average to the published total. Cutting over
* all persons reproduces that behaviour.

capture program drop nhdr_quintile
program define nhdr_quintile
    syntax , WELfare(varname) WTvar(varname) BY(varname) GENerate(name)
    tempvar ok w0 cum tot
    gen byte `ok' = !missing(`welfare', `wtvar')
    gen double `w0' = cond(`ok', `wtvar', 0)
    * Missing welfare sorts last, beacuse it never enters the running sum.
    bysort `by' (`welfare'): gen double `cum' = sum(`w0')
    by `by': egen double `tot' = total(`w0')
    gen byte `generate' = ceil((`cum' / `tot') * 5) if `ok'
    replace `generate' = 1 if `generate' < 1 & `ok'
    replace `generate' = 5 if `generate' > 5 & `ok' & !missing(`generate')
end

* ---- 1.4 nhdr_index: the NHDR 2020 Human Development Index (HDI) construction ------------------------------

* Recovered by inversion from Table 1 in Section 5 and verified there against all 120 published dimension indices and composites.
*   education  E = (2/3)(literacy/100) + (1/3)(net enrolment/100) the pre-2010 UNDP education index
*   health     H = (LE - 25) / (90 - 25)  a 65-year band, neither the pre-2010 25 to 85 nor the post-2010 20 to 85. They mention one thing and do another. Consult the gaolposts.
*   income     I = (ln PCI - ln 100) / (ln 100,000 - ln 100). This too is a rule of thumb we dont see in a UNDP published reports. Needs to be clarified.
*   composite  HDI = (E x H x I)^(1/3), the post-2010 geometric mean, They used arithmetic pre-2010's
* Classification thresholds are those of the NHDR 2020 Readers' guide.

capture program drop nhdr_index
program define nhdr_index
    syntax , LITeracy(varname) ENRolment(varname) LIFE(varname) INCome(varname) ///
        [PREfix(string)]
    gen double `prefix'education_index = (2/3) * (`literacy' / 100) + (1/3) * (`enrolment' / 100)
    gen double `prefix'health_index    = (`life' - 25) / (90 - 25)
    gen double `prefix'income_index    = (ln(`income') - ln(100)) / (ln(100000) - ln(100)) //100k why?
    gen double `prefix'hdi = (`prefix'education_index * `prefix'health_index * ///
        `prefix'income_index)^(1/3)
    gen str24 `prefix'classification = ""
    replace `prefix'classification = "High human development"   if `prefix'hdi >= 0.700 & !missing(`prefix'hdi)
    replace `prefix'classification = "Medium human development" if `prefix'hdi >= 0.550 & `prefix'hdi < 0.700
    replace `prefix'classification = "Low human development"    if `prefix'hdi <  0.550
end

* ---- 1.5 nhdr_le_from_q5: life expectancy implied by under-five mortality ---
* We use implied because this var hasnt ben tracked properly across surveys
* Model life table families :, For each mortality level, the probability of dying before age five (q5) and life expectancy at birth (e0). Levels 13
* to 24 bracket Pakistan: e0 from 50.0 to 77.5 years. Life expectancy is constructed  by linear interpolation of e0 on ln(q5), because q5 falls geometrically
* across levels, and a linear reading would drift at the low-mortality end
* where Pakistan's better districts fall.  Outside the tabulated range the end level is used. The family parameters are loaded in Section 2.4.

capture program drop nhdr_le_from_q5
program define nhdr_le_from_q5
    syntax varname(numeric), GENerate(name) [FAMily(string)]
    if "`family'" == "" local family "west"
    local q5list ${MLT_`family'_q5}
    local e0list ${MLT_`family'_e0}
    local n : word count `q5list'
    local q1 : word 1 of `q5list'
    local e1 : word 1 of `e0list'
    local qn : word `n' of `q5list'
    local en : word `n' of `e0list'
    tempvar lq
    gen double `lq' = ln(`varlist' / 1000) if `varlist' > 0
    gen double `generate' = .
    * Mortality above the highest tabulated level: the level 13 value.
    replace `generate' = `e1' if `lq' >= ln(`q1') & !missing(`lq')
    * Mortality below the lowest tabulated level, including zero: level 24.
    replace `generate' = `en' if (`lq' <= ln(`qn')) | (`varlist' == 0)
    forvalues k = 1/`=`n'-1' {
        local qa : word `k' of `q5list'
        local qb : word `=`k'+1' of `q5list'
        local ea : word `k' of `e0list'
        local eb : word `=`k'+1' of `e0list'
        replace `generate' = `ea' + (`eb' - `ea') * (`lq' - ln(`qa')) / (ln(`qb') - ln(`qa')) ///
            if `lq' <= ln(`qa') & `lq' > ln(`qb') & !missing(`lq')
    }
end

* ---- 1.6 nhdr_q5_from_le: the inverse, used to doublecheck  life expectancy ------
* Interpolates ln(q5) on e0 within the family and returns q5 per 1,000.

capture program drop nhdr_q5_from_le
program define nhdr_q5_from_le
    syntax varname(numeric), GENerate(name) [FAMily(string)]
    if "`family'" == "" local family "west"
    local q5list ${MLT_`family'_q5}
    local e0list ${MLT_`family'_e0}
    local n : word count `q5list'
    local q1 : word 1 of `q5list'
    local e1 : word 1 of `e0list'
    local qn : word `n' of `q5list'
    local en : word `n' of `e0list'
    tempvar lq
    gen double `lq' = .
    replace `lq' = ln(`q1') if `varlist' <= `e1'
    replace `lq' = ln(`qn') if `varlist' >= `en' & !missing(`varlist')
    forvalues k = 1/`=`n'-1' {
        local qa : word `k' of `q5list'
        local qb : word `=`k'+1' of `q5list'
        local ea : word `k' of `e0list'
        local eb : word `=`k'+1' of `e0list'
        replace `lq' = ln(`qa') + (ln(`qb') - ln(`qa')) * (`varlist' - `ea') / (`eb' - `ea') ///
            if `varlist' >= `ea' & `varlist' < `eb'
    }
    gen double `generate' = exp(`lq') * 1000
end

* ---- 1.7 nhdr_q5: synthetic cohort under-five mortality ---------------------
*Another method for LE. MICS and DHS  uses this. 
* The DHS and MICS method (Rutstein and Rojas 2006, chapter 8). Births in the
* window before interview are split into eight age segments, in months:
* 0-1, 1-3, 3-6, 6-12, 12-24, 24-36, 36-48, 48-60.
* For each segment j   E_j = weighted births that survived to the start of the segment and whose
*          time since birth covers the whole segment (the exposed)
*    D_j = weighted deaths among the exposed at an age inside the segment
* and the segment probabilities are chained:  q5 = 1000 x (1 - prod_j (1 - D_j / E_j))
* The synthetic cohort refers to the middle of the window rather than to
* children born five years or more before the survey, which is what makes it comparable across provinces surveyed in different years.

* Expects, in memory, the MICS6 birth history fields
*    bh4c     date of birth, century month code
*    wdoi     date of interview, century month code
*    bh5      child alive: 1 yes, 2 no
*    bh9c     age at death in months, imputed
*    wmweight women's sample weight
* and replaces the data in memory with one row per group, holding
* u5mr_per_1000, births (unweighted, in the window) and deaths_weighted.

capture program drop nhdr_q5
program define nhdr_q5
    syntax , BY(varlist) WINDOW(integer)
    tempvar mb died agedth one dth5
    gen double `mb' = wdoi - bh4c                     // months since birth
    keep if inrange(`mb', 0, 12 * `window') & !missing(wmweight) & !missing(bh4c)
    gen byte `died' = (bh5 == 2)
    gen double `agedth' = bh9c if `died'              // age at death, dead only
    local elist
    local dlist
    local j = 0
    foreach seg in "0 1" "1 3" "3 6" "6 12" "12 24" "24 36" "36 48" "48 60" {
        local ++j
        local lo : word 1 of `seg'
        local hi : word 2 of `seg'
        * Reached the segment: alive, or died at age lo or later. A death with
        * no recorded age stays in the exposed and is never counted as a death,
        * which is the conservative treatment and the one the Python package
        * used.
        gen double _e`j' = wmweight * ((missing(`agedth') | `agedth' >= `lo') & `mb' >= `hi')
        gen double _d`j' = wmweight * ((missing(`agedth') | `agedth' >= `lo') & `mb' >= `hi' ///
            & `agedth' >= `lo' & `agedth' < `hi')
        local elist `elist' _e`j'
        local dlist `dlist' _d`j'
    }
    gen double `dth5' = wmweight * (`agedth' < 60)
    gen byte `one' = 1
    collapse (sum) `elist' `dlist' deaths_weighted=`dth5' (count) births=`one', by(`by')
    gen double _surv = 1
    forvalues j = 1/8 {
        replace _surv = _surv * (1 - _d`j' / _e`j') if _e`j' > 0
    }
    gen double u5mr_per_1000 = (1 - _surv) * 1000
    gen int window_years = `window'
    drop `elist' `dlist' _surv
end

* ---- 1.8 nhdr_district_key: a matching key for district names --------------

* PSLM and MICS6 spell the same district in up to four ways. The key is the
* name in lower case, with anything other than a to z or a space turned into
* a space and runs of spaces collapsed. An explicit alias list then maps the
* remaining spellings onto one key. The list is written out rather than rekying on a fuzzy matcher, which would pair Kohat with Kohlu.

capture program drop nhdr_district_key
program define nhdr_district_key
    syntax varname(string), GENerate(name)
    tempvar raw
    gen str60 `raw' = lower(`varlist')
    replace `raw' = ustrregexra(`raw', "[^a-z ]", " ")
    replace `raw' = stritrim(strtrim(`raw'))
    gen str60 `generate' = `raw'
    local pairs `" "d i khan" "dera ismail khan" "d g khan" "dg khan" "bajur" "bajor" "bunair" "buner" "charsada" "charsadda" "batagram" "batagram" "tor garh" "torghar" "abbottabad" "abbotabad" "haripur" "hari pur" "hari pur" "hari pur" "kurram" "kuram" "lakki marwat" "laki marwat" "mohmand" "mohmind" "nowshera" "nowshehra" "jehlum" "jhelum" "bhakhar" "bhakkar" "t t singh" "tt singh" "muzaffar garh" "muzaffargarh" "rahim yar khan" "ry khan" "shahdadkot" "shahdad kot" "umer kot" "umer kot" "mir pur khas" "mirpurk khas" "nowshero feroze" "naushahro feroze" "shaheed banazir abad" "shaheed benazirabad" "tando allah yar" "tando allahyar" "tando muhammad khan" "tando muhmmad khan" "kachhi bolan" "kachhi bolan" "kech turbat" "kech turbat" "nasirabad tamboo" "nasirabad" "musa khel" "musakhel" "qilla abdullah" "killa abdullah" "qilla saifullah" "killa saifullah" "shaheed sikandar abad" "shaheed sikandarabad" "sherani" "sheerani" "chagai" "chaghi" "panjgoor" "panjgur" "sibbi" "sibbi" "karachi malir" "karachi malir" "korangi" "karachi korangi" "'
    local n : word count `pairs'
    forvalues k = 1(2)`n' {
        local from : word `k' of `pairs'
        local to   : word `=`k'+1' of `pairs'
        * Matched on the normalized name before any alias is applied, so an
        * alias is applied once and never chained.
        replace `generate' = "`to'" if `raw' == "`from'"
    }
end

* ---- 1.9 nhdr_prov_long: one row of provincial values to long form ----------
* Published allocator tables haveth one column per province. This turns
* the four provincial columns of a single row into four rows of code,
* province and value, the shape the allocation in Section 9 needs.

capture program drop nhdr_prov_long
program define nhdr_prov_long
    syntax , CODE(string)
    keep punjab sindh khyberpakhtunkhwa balochistan
    gen byte _row = 1
    rename (punjab sindh khyberpakhtunkhwa balochistan) (v1 v2 v3 v4)
    reshape long v, i(_row) j(_p)
    gen str20 province = ""
    replace province = "Punjab"             if _p == 1
    replace province = "Sindh"              if _p == 2
    replace province = "Khyber Pakhtunkhwa" if _p == 3
    replace province = "Balochistan"        if _p == 4
    gen str8 code = "`code'"
    rename v value
    keep code province value
end

* ---- 1.10 nhdr_atkinson: inequality across groups, Atkinson with aversion 1 ---
* For each variable, within each group of the by() variable:
*     A = 1 - exp(mean(ln x)) / mean(x)
* one minus the ratio of the geometric to the arithmetic mean. Used over the
* five equal-population quintiles, so the unweighted means are exact.
* Creates <prefix><variable> on every row of the group.

capture program drop nhdr_atkinson
program define nhdr_atkinson
    syntax varlist(numeric), BY(varlist) PREfix(string)
    foreach v of local varlist {
        tempvar lv am gm
        gen double `lv' = ln(`v')
        bysort `by': egen double `am' = mean(`v')
        by `by': egen double `gm' = mean(`lv')
        gen double `prefix'`v' = 1 - exp(`gm') / `am'
        drop `lv' `am' `gm'
    }
end

* ---- 1.11 nhdr_gdi_hdi: HDI gender, Gender Development Index (GDI) ----
* As nhdr_index, except that the income index runs from 100 to 75,000 PPP dollars, the goalposts Table 6 is on (Section 17.1). This is also one of the many quirks of NH

capture program drop nhdr_gdi_hdi
program define nhdr_gdi_hdi
    syntax , LITeracy(varname) ENRolment(varname) LIFE(varname) INCome(varname) [PREfix(string)]
    if "`prefix'" == "" local prefix "gdi_"
    gen double `prefix'edu = (2/3) * (`literacy' / 100) + (1/3) * (`enrolment' / 100)
    gen double `prefix'hea = (`life' - 25) / (90 - 25)
    gen double `prefix'inc = (ln(`income') - ln(100)) / (ln(75000) - ln(100))
    gen double `prefix'hdi = (`prefix'edu * `prefix'hea * `prefix'inc)^(1/3)
end

* ---- 1.12 nhdr_gii: the Gender Inequality Index (GII), NHDR 2020 variant ---------
* Inputs in percent. See Section 18 for the formula and its recovery.
capture program drop nhdr_gii
program define nhdr_gii
    syntax , NOCare(varname) EVMarried(varname) SEATF(varname) SEATM(varname) ///
        SECF(varname) SECM(varname) LFPRF(varname) LFPRM(varname) [PREfix(string)]
    if "`prefix'" == "" local prefix "gii_"
    gen double `prefix'health_f   = sqrt(1 / (`nocare' * `evmarried'))
    gen double `prefix'emp_f      = sqrt((`seatf' / 100) * (`secf' / 100))
    gen double `prefix'emp_m      = sqrt((`seatm' / 100) * (`secm' / 100))
    gen double `prefix'g_f        = (`prefix'health_f * `prefix'emp_f * (`lfprf' / 100))^(1/3)
    gen double `prefix'g_m        = (1 * `prefix'emp_m * (`lfprm' / 100))^(1/3)
    gen double `prefix'harm       = 1 / ((1 / `prefix'g_f + 1 / `prefix'g_m) / 2)
    gen double `prefix'health_bar = (`prefix'health_f + 1) / 2
    gen double `prefix'emp_bar    = (`prefix'emp_f + `prefix'emp_m) / 2
    gen double `prefix'lfpr_bar   = ((`lfprf' + `lfprm') / 100) / 2
    gen double `prefix'g_fm       = (`prefix'health_bar * `prefix'emp_bar * `prefix'lfpr_bar)^(1/3)
    gen double `prefix'gii        = 1 - `prefix'harm / `prefix'g_fm
end

* ---- 1.13 nhdr_by_province: weighted means for Pakistan and the provinces ---
* Replaces the data in memory with five rows (Pakistan and the four Provinces), each holding the weighted mean of every listed variable over
* its own non-missing universe.
capture program drop nhdr_by_province
program define nhdr_by_province
    syntax , VARs(varlist) WGT(varname) PROVince(varname)
    drop if missing(`wgt')
    tempfile base prov
    save `base'
    collapse (mean) `vars' [aw=`wgt'], by(`province')
    gen str20 domain = ""
    replace domain = "Khyber Pakhtunkhwa" if `province' == 1
    replace domain = "Punjab"             if `province' == 2
    replace domain = "Sindh"              if `province' == 3
    replace domain = "Balochistan"        if `province' == 4
    drop if domain == ""
    drop `province'
    save `prov'
    use `base', clear
    collapse (mean) `vars' [aw=`wgt']
    gen str20 domain = "Pakistan"
    append using `prov'
end

* ---- 1.14 nhdr_earned_income: the female share of earned income ------------

* Income is the most tricjy of the three.
* The UNDP split (HDR 2019 Technical Note 3):  S_f = (W_f/W_m x EA_f) / (W_f/W_m x EA_f + EA_m)
* EA_f  female share of the economically active population aged 10 and over
* W_f/W_m  ratio of mean female to mean male annual earnings, paid employees
* Replaces the data in memory with one row per domain (Pakistan and the
* provinces) holding ea_f, wage_ratio and s_f.

capture program drop nhdr_earned_income
program define nhdr_earned_income
    syntax , SEX(varname) ACTive(varname) EARN(varname) AGE(varname) WGT(varname) DOMain(name)
    keep if `age' >= 10 & !missing(`age') & !missing(`wgt')
    gen double _af = `wgt' * (`active' == 1) * (`sex' == 2)
    gen double _am = `wgt' * (`active' == 1) * (`sex' == 1)
    gen double _xf = cond(!missing(`earn') & `sex' == 2, `wgt' * `earn', 0)
    gen double _xm = cond(!missing(`earn') & `sex' == 1, `wgt' * `earn', 0)
    gen double _nf = cond(!missing(`earn') & `sex' == 2, `wgt', 0)
    gen double _nm = cond(!missing(`earn') & `sex' == 1, `wgt', 0)
    tempfile ind prov
    save `ind'
    collapse (sum) _af _am _xf _xm _nf _nm, by(`domain')
    save `prov'
    use `ind', clear
    collapse (sum) _af _am _xf _xm _nf _nm
    gen str20 `domain' = "Pakistan"
    append using `prov'
    drop if `domain' == ""
    gen double ea_f       = _af / (_af + _am)
    gen double wage_ratio = (_xf / _nf) / (_xm / _nm)
    gen double s_f        = wage_ratio * ea_f / (wage_ratio * ea_f + (1 - ea_f))
    keep `domain' ea_f wage_ratio s_f
end

* ---- 1.15 nhdr_fig_done: count a figure and confirm its file was written ----

capture program drop nhdr_fig_done
program define nhdr_fig_done
    args file
    global NFIG = $NFIG + 1
    capture confirm file "`file'"
    if _rc display as error "Figure not written: `file'"
    else global NFIGOK = $NFIGOK + 1
end

*==============================================================================*
* SECTION 2   PUBLISHED REFERENCE VALUES
*==============================================================================*
* Everything the reproduction is checked against, loaded once. Each file in
* 6. Raw data/Published carries its source in 6. Raw data/Published/Sources register.csv.
* Numeric columns are read in double precision (asdouble), for the reason
* given under rules mentioned ealier.

* ---- 2.1 NHDR 2020 Statistical Annex Table 1: dimension indices ------------
* One row per domain. Columns lit_idx, ner_idx, edu_idx, health_idx,
* income_idx and hdi, for 2006-07 and 2018-19, each to three decimals.

import delimited using "$pub/NHDR2020 Table 1.csv", clear varnames(1) asdouble  encoding(utf-8) stringcols(1)
rename region domain //strata 
tempfile t1
save `t1'

* ---- 2.2 NHDR 2020 Statistical Annex Table 2A: the four indicators ---------
* One row per domain and quintile (All, Q1 to Q5): adult literacy and net
* enrolment in percent, life expectancy in years, per capita income in PPP
* dollars, for 2006-07 and 2018-19.
import delimited using "$pub/NHDR2020 Table 2A.csv", clear varnames(1) asdouble  encoding(utf-8) stringcols(1 2)
   
rename region domain
tempfile t2a
save `t2a'

* ---- 2.3 World Bank World Development Indicators, Pakistan ------------------
* Retrieved 25 September 2026, WDI last updated 13 July 2026. Nine values are:
*   SP.DYN.LE00.IN     life expectancy at birth, 2018 and 2024
*   NY.GNP.PCAP.PP.KD  GNI per head, constant 2021 PPP dollars, 2018 and 2024
*   NY.GNP.PCAP.PP.CD  GNI per head, current PPP dollars, 2006, 2018, 2024
*   PA.NUS.PPP         PPP conversion factor, rupees per dollar, 2006, 2018

import delimited using "$pub/WDI Pakistan.csv", clear varnames(1) asdouble encoding(utf-8)
foreach spec in "SP.DYN.LE00.IN 2018 le2018" "SP.DYN.LE00.IN 2024 le2024" ///
    "NY.GNP.PCAP.PP.KD 2018 gnik2018" "NY.GNP.PCAP.PP.KD 2024 gnik2024" ///
    "NY.GNP.PCAP.PP.CD 2006 gnic2006" "NY.GNP.PCAP.PP.CD 2018 gnic2018" ///
    "NY.GNP.PCAP.PP.CD 2024 gnic2024" "PA.NUS.PPP 2006 ppp2006" "PA.NUS.PPP 2018 ppp2018" {
    local c : word 1 of `spec'
    local y : word 2 of `spec'
    local s : word 3 of `spec'
    quietly summarize value if indicator_code == "`c'" & year == `y'
    if r(N) != 1 {
        display as error "WDI Pakistan.csv: expected one value for `c' `y', found `r(N)'"
        exit 459
    }
    scalar `s' = r(mean)
}
display as text "WDI: life expectancy 2018 " %6.3f le2018 ", 2024 " %6.3f le2024
display as text "WDI: GNI per head, constant 2021 PPP, 2018 " %9.2f gnik2018 ", 2024 " %9.2f gnik2024
display as text "WDI: GNI per head, current PPP, 2006 " %6.0f gnic2006 ", 2018 " %6.0f gnic2018 ", 2024 " %6.0f gnic2024
display as text "WDI: PPP conversion factor, 2006 " %8.4f ppp2006 ", 2018 " %8.4f ppp2018

* ---- 2.4 Model life tables ----------------------------------------------------
* Coale-Demeny West (1983) and United Nations South Asian (1982), levels 13  to 24. For each family the q5 and e0 values are stored as two globals,
* ordered from level 13 to level 24, and read by nhdr_le_from_q5.

import delimited using "$pub/Model life tables.csv", clear varnames(1) asdouble encoding(utf-8)
sort family level
foreach fam in west south_asian {
    global MLT_`fam'_q5 ""
    global MLT_`fam'_e0 ""
    forvalues i = 1/`=_N' {
        if family[`i'] == "`fam'" {
            global MLT_`fam'_q5 ${MLT_`fam'_q5} `=q5[`i']'
            global MLT_`fam'_e0 ${MLT_`fam'_e0} `=e0[`i']'
        }
    }
    display as text "model life table `fam', q5 by level: ${MLT_`fam'_q5}"
}
display as text "e0 by level, both families: $MLT_west_e0"

* ---- 2.5 Published benchmarks -----------------------------------------------
* PBS literacy for PSLM 2018-19 and HIES 2024-25, PBS consumption means for  both HIES rounds, the MICS6 published under-five mortality rates, and
* UNDP Pakistan's 2017 HDI with its four inputs. Stored as scalars bm_<id>.
import delimited using "$pub/Published benchmarks.csv", clear varnames(1) asdouble encoding(utf-8)
forvalues i = 1/`=_N' {
    local id = id[`i']
    scalar bm_`id' = value[`i']
}

* ---- 2.6 PDHS 2017-18 under-five mortality by province -----------------------
* Ten years before the survey for provinces, five years for Pakistan. Still usable since this var doesnt fluctuate much

import delimited using "$pub/PDHS 2017-18 mortality.csv", clear varnames(1) asdouble encoding(utf-8)
keep domain u5mr_per_1000
rename u5mr_per_1000 pdhs_q5
tempfile pdhs
save `pdhs'

* ---- 2.7 PBS national accounts, 2018-19 ----------------------------------------
* GNI at market prices and population, used only to show in Section 10 that the NHDR income control is not PBS GNI converted at the PPP factor.

import delimited using "$pub/PBS national accounts.csv", clear varnames(1) asdouble encoding(utf-8)
quietly summarize gni_mp_rs_mn if fiscal_year == "2018-19"
scalar gni_mp_1819 = r(mean)
quietly summarize population_mn if fiscal_year == "2018-19"
scalar pop_1819 = r(mean)

* ---- 2.8 Published benchmarks for the inequality and gender indices (IHDI, GDI, GII) ----------------------------
* NHDR 2020 Figures 2.19 and 2.20 and Chapter 4, and PBS LFS 2018-19 Table 4.
* Stored as scalars bm_<id>, like 2.5.

import delimited using "$pub/Published benchmarks indices.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 3)
forvalues i = 1/`=_N' {
    local id = id[`i']
    scalar bm_`id' = value[`i']
}


*==============================================================================*
* SECTION 3   ADULT LITERACY, HIES 2018-19, AGAINST NHDR TABLE 2A (HDI INPUT)
*==============================================================================*

* Source    PBS, HIES 2018-19 microdata
*             plist.dta     person roster: hhcode, idc, age, province, region, weights (person weight)
*             sec_2ab.dta   education: s2aq01 can read and write with  understanding (1 yes, 2 no)
*             sec_12ce.dta  household totals: t_income, t_exp (annual rupees)
* Universe  persons aged 15 and over with a valid literacy response
* Weight    the person weight on the roster
* Formula   L_D = 100 x sum_i (w_i x lit_i) / sum_i (w_i), over persons i in
*           domain D, where lit_i = 1 if the person reads and writes and 0 otherwise
* Target    Table 2A, lit_2018_19: 15 domains x (All, Q1 to Q5) = 90 values
* Result    all 15 domain totals match to the printed decimal. Quintile rows match to within about five points, for reasons given in Section 10.

* ---- 3.1 One record per person ---------------------------------------------

use hhcode idc age province region weights s1aq04 using "$h18/plist.dta", clear
* Household size is counted on the complete roster, before anything is dropped, because it divides household consumption into per capita terms.
bysort hhcode: gen int hhsize = _N
* The education section is matched on household, person, province and region, which is how the published rows were reproduced.
merge 1:1 hhcode idc province region using "$h18/sec_2ab.dta", keepusing(s2aq01 s2bq01 s2bq05 s2bq14) keep(master match) nogenerate
* Household consumption, the ranking variable for the quintile rows.
merge m:1 hhcode using "$h18/sec_12ce.dta", keepusing(t_income t_exp)  keep(master match) nogenerate
gen double pc_exp = t_exp / hhsize
gen double pc_inc = t_income / hhsize      // used by the IHDI in Section 16

* ---- 3.2 The literacy indicator -----------------------------------------------
* Missing outside the universe, so that any weighted mean over any domain
* restricts itself to the right population without a separate filter. Basically level matching is needed. Cohorts
gen double lit15 = (s2aq01 == 1) if age >= 15 & !missing(age) & !missing(s2aq01)


*==============================================================================*
* SECTION 4   NET ENROLMENT, LEVEL MATCHED, AGAINST NHDR TABLE 2A (HDI INPUT)
*==============================================================================*

* The annex defines net enrolment as children aged 5 to 14 attending classes
* 1 to 10, over all children aged 5 to 14. Applied literally that returns
* 62.0 percent for Pakistan in 2018-19 against a published 37.0. Six
* definitions were tested. The one that reproduces every domain is a
* level-matched net rate: a child counts only when enrolled at the school
* level that matches the child's age.
*     ages  5 to 9   classes 1 to 5    primary
*     ages 10 to 12  classes 6 to 8    middle
*     ages 13 to 14  classes 9 to 10   matric
* Katchi and pre-primary (class codes 25 to 28) are excluded by definition.
* Source    sec_2ab.dta: s2bq01 schooling status (3 currently attending),
*           s2bq14 class currently attending
* Universe  children aged 5 to 14
* Formula   N_D = 100 x sum_i (w_i x enr_i) / sum_i (w_i)
* Target    Table 2A, ner_2018_19

* ---- 4.1 The enrolment indicator ------------------------------------------------

gen double cls = s2bq14 if s2bq01 == 3                 // attending now
replace cls = . if inlist(cls, 25, 26, 27, 28) | cls > 10
gen double ner = ((inrange(age, 5, 9)   & inrange(cls, 1, 5))  | ///
                  (inrange(age, 10, 12) & inrange(cls, 6, 8))  | ///
                  (inrange(age, 13, 14) & inrange(cls, 9, 10))) if inrange(age, 5, 14)
tempfile h18p
save `h18p'

* ---- 4.2 Both indicators on the Table 2A layout ----------------------------------

* The published table gives every domain its own quintiles: Pakistan-Urban has its own Q1 to Q5, not the national cuts applied to urban residents,
* and likewise for every province and each urban and rural half. Quintiles
* are therefore cut within each domain, on per capita consumption.

keep hhcode idc province region weights pc_exp pc_inc lit15 ner
nhdr_stack_domains, province(province) region(region)
nhdr_quintile, welfare(pc_exp) wtvar(weights) by(domain) generate(q)
tempfile stacked edu_all
save `stacked'
collapse (mean) lit15 ner [aw=weights], by(domain)
gen str3 quintile = "All"
save `edu_all'
use `stacked', clear
drop if missing(q)
collapse (mean) lit15 ner [aw=weights], by(domain q)
gen str3 quintile = "Q" + string(q)
drop q
append using `edu_all'
replace lit15 = 100 * lit15
replace ner   = 100 * ner
rename (lit15 ner) (lit_reproduced ner_reproduced)
merge 1:1 domain quintile using `t2a', keepusing(lit_2018_19 ner_2018_19) ///
    keep(master match) nogenerate
rename (lit_2018_19 ner_2018_19) (lit_published ner_published)
gen double lit_diff = lit_reproduced - lit_published
gen double ner_diff = ner_reproduced - ner_published
sort domain quintile
tempfile edu1819
save `edu1819'

display as text _n "Step 1 and 2: domain totals, HIES 2018-19, against Table 2A"
list domain lit_reproduced lit_published lit_diff ner_reproduced ner_published ner_diff ///
    if quintile == "All", noobs sep(0) abbreviate(16)

* ---- 4.3 Checks ---------------------------------------------------------------------
* Published values are printed to one decimal, so itreproduce within 0.05 is an exact match. The tolerance of 0.06 leaves room for floating point only.
quietly summarize lit_reproduced if domain == "Pakistan" & quintile == "All"
nhdr_check, label("Step 1 literacy, Pakistan 2018-19 [published 57.4]")  got(`=r(mean)') want(57.4) tol(0.06)
quietly summarize ner_reproduced if domain == "Pakistan" & quintile == "All"
nhdr_check, label("Step 2 net enrolment, Pakistan 2018-19 [published 37.0]") ///
    got(`=r(mean)') want(37.0) tol(0.06)
gen double _absl = abs(lit_diff)
gen double _absn = abs(ner_diff)
quietly summarize _absl if quintile == "All"
nhdr_check, label("Step 1 literacy, worst of 15 domain totals, |gap| [published]") ///
    got(`=r(max)') want(0) tol(0.06)
quietly summarize _absn if quintile == "All"
nhdr_check, label("Step 2 enrolment, worst of 15 domain totals, |gap| [published]") ///
    got(`=r(max)') want(0) tol(0.06)
* Quintile rows: the reference is the worst gap the Python package corroborated
* Tied per capita values inside a household are ordered differently by the
* two programs, so the tolerance is wider.
quietly summarize _absl if quintile != "All"
nhdr_check, label("Step 1 literacy, worst of 75 quintile rows [reference 4.85]") ///
    got(`=r(max)') want(4.8488) tol(0.25)
quietly summarize _absn if quintile != "All"
nhdr_check, label("Step 2 enrolment, worst of 75 quintile rows [reference 5.06]") ///
    got(`=r(max)') want(5.0556) tol(0.25)
drop _absl _absn
export delimited using "$out/Table 2A education replication 2018-19.csv"
save "$out/Table 2A education replication 2018-19.dta"

*==============================================================================*
* SECTION 5   HUMAN DEVELOPMENT INDEX (HDI) CONSTRUCTION, RECOVERED BY INVERSION
*==============================================================================*

* NHDR 2020 says it follows "the standard methodology" of UNDP's global Human Development Reports and does not say which year. Solving the
* goalposts and weights out of the published dimension indices gives a versionthat no UNDP report uses (see nhdr_index in Section 1.4):
*     education   two-thirds literacy, one-third enrolment    (pre-2010 UNDP)
*     health      goalposts 25 and 90 years                    (neither)
*     income      goalposts 100 and 100,000 PPP dollars        (neither)
*     aggregation geometric mean                               (post-2010 UNDP)
* The recovery is verified here: 
*the published Table 2A indicators are pushed through the construction and compared with Table 1.
* Target    Table 1: education, health and income indices and the composite,
*           15 domains x 2 years = 120 values, printed to three decimals
* Result    worst absolute error 0.0011, which is the rounding of the one
*           decimal inputs in Table 2A 

use `t2a', clear
keep if quintile == "All"
drop quintile
tempfile t2a_all
save `t2a_all'

* Two national values used repeatedly below.
quietly summarize pci_2018_19 if domain == "Pakistan"
scalar pci_pak_1819 = r(mean)          // NHDR income control, 4,922 PPP dollars
quietly summarize le_2018_19 if domain == "Pakistan"
scalar le_pak_1819 = r(mean)           // NHDR life expectancy, 67.1 years
merge 1:1 domain using `t1', keep(match) nogenerate
foreach y in 2006_07 2018_19 {
    nhdr_index, literacy(lit_`y') enrolment(ner_`y') life(le_`y') income(pci_`y') prefix(r`y'_)
}

* One row per domain, year and derived quantity.
tempname ph
tempfile idxval
postfile `ph' str30 domain str8 year str16 quantity double(replicated published) using `idxval'
forvalues i = 1/`=_N' {
    foreach y in 2006_07 2018_19 {
        post `ph' (domain[`i']) ("`y'") ("education_index") (r`y'_education_index[`i']) (edu_idx_`y'[`i'])
        post `ph' (domain[`i']) ("`y'") ("health_index")    (r`y'_health_index[`i'])    (health_idx_`y'[`i'])
        post `ph' (domain[`i']) ("`y'") ("income_index")    (r`y'_income_index[`i'])    (income_idx_`y'[`i'])
        post `ph' (domain[`i']) ("`y'") ("hdi")             (r`y'_hdi[`i'])             (hdi_`y'[`i'])
    }
}
postclose `ph'
use `idxval', clear
gen double diff = replicated - published
gen double absdiff = abs(diff)
gen byte within_0001 = absdiff <= 0.0005        // equal at three decimals
gen byte within_0002 = absdiff <= 0.0015        // within one unit of the third decimal

display as text _n "Step 3: the recovered construction against Table 1"
foreach q in education_index health_index income_index hdi {
    quietly summarize absdiff if quantity == "`q'"
    local n  = r(N)
    local mx = r(max)
    quietly count if quantity == "`q'" & within_0001
    local a = r(N)
    quietly count if quantity == "`q'" & within_0002
    local b = r(N)
    display as text "  " %-16s "`q'" "  n " %3.0f `n' "  worst |error| " %6.4f `mx' ///
        "  within 0.001: " %2.0f `a' "/" %2.0f `n' "  within 0.002: " %2.0f `b' "/" %2.0f `n'
}
quietly count
nhdr_check, label("Step 3 values compared, 15 domains x 2 years x 4 [published]") ///
    got(`=r(N)') want(120) tol(0)
quietly summarize absdiff
nhdr_check, label("Step 3 worst |error| of 120 derived values [published]") ///
    got(`=r(max)') want(0) tol(0.0015)
nhdr_check, label("Step 3 worst |error| of 120 derived values [reference 0.0011]") ///
    got(`=r(max)') want(0.0011) tol(0.0001)
export delimited using "$out/UNDP index validation.csv"
save "$out/UNDP index validation.dta"


*==============================================================================*
* SECTION 6   THE CURRENT UNDP HDI CONSTRUCTION, AN EXTERNAL BENCHMARK
*==============================================================================*

* A separate check that the index arithmetic is coded correctly. UNDP Pakistan published Pakistan's 2017 HDI with its four inputs, citing the 2018 Statistical Update.
* The modern construction (HDR 2023-24 Technical Note 1) must return 0.562 from them with no fitting of any kind.
*     health     (LE - 20) / (85 - 20)
*     education  mean of min(EYS/18, 1) and min(MYS/15, 1)
*     income     (ln GNI - ln 100) / (ln 75,000 - ln 100)
*     composite  geometric mean
scalar m_h   = (bm_undp17_le - 20) / (85 - 20)
scalar m_e   = (min(bm_undp17_eys / 18, 1) + min(bm_undp17_mys / 15, 1)) / 2
scalar m_i   = (ln(bm_undp17_gni) - ln(100)) / (ln(75000) - ln(100))
scalar m_hdi = (m_h * m_e * m_i)^(1/3)
display as text _n "Step 3b: modern UNDP construction, Pakistan 2017"
display as text "  health " %7.5f m_h "  education " %7.5f m_e "  income " %7.5f m_i ///
    "  HDI " %7.5f m_hdi "  published " %5.3f bm_undp17_hdi
nhdr_check, label("Step 3b modern UNDP HDI, Pakistan 2017 [published 0.562]") ///
    got(`=m_hdi') want(`=bm_undp17_hdi') tol(0.0005)


*==============================================================================*
* SECTION 7   LIFE EXPECTANCY RECOVERED FROM THE HDI HEALTH INDEX
*==============================================================================*

* NHDR 2020 says provincial life expectancy was estimated from under-five mortality and does not name the model life table. Because the index
* arithmetic is exact (Section 5), the published health index is an exact
* record of the life expectancy that produced it:
*     H = (LE - 25) / 65,   so   LE = 25 + 65 x H
* A health index printed to three decimals pins LE to within  band = 0.5 x 0.001 x 65 = 0.0325 years, about twelve days.
* The recovered value is then set against the life expectancy printed in
* Table 2A, which is itself rounded to one decimal (plus or minus 0.05).
* Target    30 estimates, 15 domains x 2 years
* Result    all 30 inside the band, mean gap 0.004 years: Tables 1 and 2A
*           are one series

use `t1', clear
keep domain health_idx_2006_07 health_idx_2018_19
merge 1:1 domain using `t2a_all', keepusing(le_2006_07 le_2018_19) keep(match) nogenerate
reshape long health_idx_ le_, i(domain) j(year) string
rename (health_idx_ le_) (health_index_published life_printed_table2a)
gen double life_recovered = 25 + 65 * health_index_published
gen double life_band_low  = life_recovered - 0.0325
gen double life_band_high = life_recovered + 0.0325
gen double gap_years = life_recovered - life_printed_table2a
gen byte consistent = (life_printed_table2a >= life_band_low - 0.05) & ///
                      (life_printed_table2a <= life_band_high + 0.05)
* Audit of the unnamed model life table: the under-five mortality each
* recovered provincial life expectancy implies under the two families.
nhdr_q5_from_le life_recovered, generate(q5_implied_west) family(west)
nhdr_q5_from_le life_recovered, generate(q5_implied_south_asian) family(south_asian)

display as text _n "Step 4: life expectancy recovered by inverting the health index"
list domain year health_index_published life_recovered life_printed_table2a gap_years consistent, ///
    noobs sep(0) abbreviate(20)
display as text _n "  under-five mortality implied, provinces, 2018-19"
list domain life_recovered q5_implied_west q5_implied_south_asian ///
    if year == "2018_19" & inlist(domain, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan"), ///
    noobs sep(0)

quietly count if consistent
nhdr_check, label("Step 4 estimates inside the rounding band, of 30 [published]") ///
    got(`=r(N)') want(30) tol(0)
quietly summarize gap_years
nhdr_check, label("Step 4 mean gap, recovered minus printed, years [reference]") ///
    got(`=r(mean)') want(0.0043) tol(0.0005)
gen double _abs = abs(gap_years)
quietly summarize _abs
nhdr_check, label("Step 4 worst |gap|, years [reference 0.070]") ///
    got(`=r(max)') want(0.0700) tol(0.0005)
drop _abs
tempfile lerec
save `lerec'
export delimited using "$out/Life expectancy inversion.csv"
save "$out/Life expectancy inversion.dta"

*==============================================================================*
* SECTION 8   UNDER-FIVE MORTALITY FROM THE MICS6 BIRTH HISTORIES
*==============================================================================*

* Section 7 recovers what NHDR fed in. This section supplies an independent
* measurement to set against it, and does so for provinces, divisions and
* districts, which NHDR never attempted.
* Source    UNICEF and provincial bureaus of statistics, MICS6 birth history
*           recode bh.sav, four rounds:
*             Punjab 2017-18, Sindh 2018-19, Khyber Pakhtunkhwa 2019,
*             Balochistan 2019-20
*           Each round carries a full birth history with the district (hh7)
*           and division on every record and was designed to be
*           representative at district level. That combination exists nowhere
*           else in Pakistan's data.
* Fields    bh4c date of birth (CMC), wdoi date of interview (CMC), bh5 child
*           alive (1 yes, 2 no), bh9c age at death in months, wmweight
*           women's weight, hh7 district, division, psu
* Method    synthetic cohort q5 (nhdr_q5 in Section 1.7), then life
*           expectancy from the Coale-Demeny West family (Section 1.5)
* Windows   five years to validate against the published MICS figures, ten
*           years for provinces, divisions and districts, which buys the
*           precision a district estimate needs
* Result    Punjab 67.3 against a published 67, Sindh 45.2 against a
*           published 46, on 401,088 birth records

* ---- 8.1 Stack the four provincial birth histories ----------------------------
tempfile bh
local provs  `" "Punjab" "Sindh" "Khyber Pakhtunkhwa" "Balochistan" "'
local dirs   `" "Punjab 2017-18" "Sindh 2018-19" "KP 2019" "Balochistan 2019-20" "'
local rounds 2017-18 2018-19 2019 2019-20
forvalues k = 1/4 {
    local p : word `k' of `provs'
    local d : word `k' of `dirs'
    local r : word `k' of `rounds'
    import spss using "$mics/`d'/bh.sav", clear
    * Variable names are upper case in some rounds and lower case in others.
    rename *, lower
    * windex5, the household wealth quintile, is used by the IHDI (Section 16).
    keep bh4c wdoi bh5 bh9c wmweight hh7 division psu windex5
    * District and division names come from the value labels, which is how
    * MICS itself names them.
    decode hh7, generate(district)
    decode division, generate(division_name)
    drop hh7 division
    gen str20 province = "`p'"
    gen str8 mics_round = "`r'"
    if `k' > 1 append using `bh'
    save `bh', replace
}
quietly count
nhdr_check, label("Step 5 MICS6 birth records loaded, four rounds [reference]") ///
    got(`=r(N)') want(401088) tol(0)

* ---- 8.2 District to division lookup, as MICS6 assigns it --------------------
* Used in Section 15 for the divisional fallback of the health ladder and for
* the divisional roll-up.
keep province district division_name
drop if district == "" | division_name == ""
duplicates drop
nhdr_district_key district, generate(key)
tempfile d2v
save `d2v'
export delimited using "$out/District division lookup MICS6.csv"

* ---- 8.3 Validation against the published MICS6 figures, five-year window ----
use `bh', clear
nhdr_q5, by(province) window(5)
display as text _n "Step 5: provincial under-five mortality, five-year window"
list province u5mr_per_1000 births deaths_weighted, noobs sep(0)
quietly summarize u5mr_per_1000 if province == "Punjab"
nhdr_check, label("Step 5 Punjab q5, 5 years, MICS6 2017-18 [published 67]") ///
    got(`=r(mean)') want(`=bm_u5mr_mics_PUN') tol(1)
nhdr_check, label("Step 5 Punjab q5, 5 years [reference 67.28]") ///
    got(`=r(mean)') want(67.2827) tol(0.01)
quietly summarize u5mr_per_1000 if province == "Sindh"
nhdr_check, label("Step 5 Sindh q5, 5 years, MICS6 2018-19 [published 46]") ///
    got(`=r(mean)') want(`=bm_u5mr_mics_SIN') tol(1)
nhdr_check, label("Step 5 Sindh q5, 5 years [reference 45.18]") ///
    got(`=r(mean)') want(45.1829) tol(0.01)

* ---- 8.4 Provinces, ten-year window, and the life expectancy each implies ---
* Set against PDHS 2017-18, which covers the same years and returns
* systematically higher child mortality, and against the value NHDR used (recovered in Section 7).

use `bh', clear
nhdr_q5, by(province) window(10)
rename u5mr_per_1000 mics6_q5_10y
nhdr_le_from_q5 mics6_q5_10y, generate(le_west) family(west)
nhdr_le_from_q5 mics6_q5_10y, generate(le_south_asian) family(south_asian)
rename province domain
merge 1:1 domain using `pdhs', keep(master match) nogenerate
nhdr_le_from_q5 pdhs_q5, generate(le_west_from_pdhs) family(west)
* lerec holds two years per domain, so the 2018-19 value is taken explicitly.
preserve
use `lerec', clear
keep if year == "2018_19"
keep domain life_recovered
rename life_recovered nhdr_le_recovered
tempfile lerec1819
save `lerec1819'
restore
merge 1:1 domain using `lerec1819', keep(master match) nogenerate
gen double le_gap_mics_minus_pdhs = le_west - le_west_from_pdhs
rename domain province
display as text _n "Step 5: provincial under-five mortality, ten-year window, and implied life expectancy"
list province mics6_q5_10y le_west le_south_asian pdhs_q5 le_west_from_pdhs nhdr_le_recovered ///
    le_gap_mics_minus_pdhs, noobs sep(0) abbreviate(14)
* Punjab seems off
foreach pr in "Punjab 68.8139 68.2092" "Sindh 43.1638 73.6592" ///
    "Khyber_Pakhtunkhwa 36.6525 75.3047" "Balochistan 47.2439 72.7279" {
    local nm : word 1 of `pr'
    local q  : word 2 of `pr'
    local e  : word 3 of `pr'
    local nm = subinstr("`nm'", "_", " ", .)
    quietly summarize mics6_q5_10y if province == "`nm'"
    nhdr_check, label("Step 5 `nm' q5, 10 years [reference]") got(`=r(mean)') want(`q') tol(0.01)
    quietly summarize le_west if province == "`nm'"
    nhdr_check, label("Step 5 `nm' LE, West family [reference]") got(`=r(mean)') want(`e') tol(0.005)
}
tempfile provmort
save `provmort'
export delimited using "$out/Provincial mortality MICS6.csv"

* ---- 8.5 Divisions, ten-year window -------------------------------------------------
use `bh', clear
drop if division_name == ""
nhdr_q5, by(province division_name) window(10)
nhdr_le_from_q5 u5mr_per_1000, generate(le_west) family(west)
gsort -u5mr_per_1000
display as text _n "Step 5: divisions, highest under-five mortality first"
list province division_name u5mr_per_1000 births deaths_weighted le_west in 1/8, noobs sep(0)
quietly count
nhdr_check, label("Step 5 divisions estimated [reference 28]") got(`=r(N)') want(28) tol(0)
tempfile divmort
save `divmort'
export delimited using "$out/Divisional mortality MICS6.csv"

* ---- 8.6 Districts, ten-year window, and the plausibility screen --------------
use `bh', clear
drop if district == ""
nhdr_q5, by(province district) window(10)
nhdr_le_from_q5 u5mr_per_1000, generate(le_west) family(west)
* Pakistan's healthiest districts has near 40 deaths per thousand and its national rate lies between 46 and 74 depending on the survey. A district
* returning under 20, or fewer than 15 weighted deaths in ten years, is probably a reporting failure rather than low mortality: child deaths, and early
* neonatal deathsare the first thing a retrospective birth
* history loses. Such districts stay in the file, flagged, and are not used
* as district estimates in Section 15.

gen byte implausible = (u5mr_per_1000 < 20) | (deaths_weighted < 15)
gen byte thin = births < 500
gsort -u5mr_per_1000
display as text _n "Step 5: districts, highest under-five mortality first"
list province district u5mr_per_1000 births deaths_weighted le_west implausible in 1/10, noobs sep(0)
display as text _n "Districts that fail the plausibility screen"
list province district u5mr_per_1000 deaths_weighted if implausible, noobs sep(0)
quietly count
nhdr_check, label("Step 5 districts estimated [reference 129]") got(`=r(N)') want(129) tol(0)
quietly count if implausible
nhdr_check, label("Step 5 districts failing the screen [reference 21]") got(`=r(N)') want(21) tol(0)
quietly summarize u5mr_per_1000 if district == "Dera Bugti"
nhdr_check, label("Step 5 Dera Bugti q5, 10 years [reference 203.99]") ///
    got(`=r(mean)') want(203.985) tol(0.01)
nhdr_district_key district, generate(key)
tempfile distmort
save `distmort'
export delimited using "$out/District mortality MICS6.csv"

*==============================================================================*
* SECTION 8A   CHILD MORTALITY, STUNTING AND WASTING FROM PDHS 2006-07, 2012-13, 2017-18
*==============================================================================*

* Without this section the PDHS values NHDR 2020 used would enter as printed: child survival,
* stunting and wasting in the CDI (Table 4A), and the health gradient by
* quintile behind the IHDI (Tables 2A and 3). The PDHS microdata is in
* 6. Raw data/PDHS, as downloaded from the DHS Program, and this section reproduces
* them. Section 8 measured mortality from MICS6. This section measures it
* from the survey NHDR actually used.
* Source    NIPS and ICF, Pakistan Demographic and Health Survey, standard
*           recode files in Stata format
*             2006-07  PKBR53FL (births), PKKR53FL (children), PKPR53FL
*             2012-13  PKBR61FL, PKKR61FL, PKPR61FL (household members)
*             2017-18  PKBR71FL, PKKR71FL, PKPR71FL, PKHR71FL (households)
* Fields    v005 weight (x 1,000,000), v008 interview date (CMC), v024
*           region, v190 wealth quintile, b3 date of birth (CMC), b4 sex,
*           b5 alive (1 yes, 0 no), b7 age at death in months, h2 to h9
*           vaccinations, m15 place of delivery, hv005, hv024, hv103 slept
*           in the household last night, hv104 sex, hv201 water source,
*           hv270 wealth quintile, hc1 age in months, hc70 height-for-age
*           and hc72 weight-for-height z-scores x 100 (WHO 2006 standard)
* Domains   Regions are named from their value labels (8A.1), so the code
*           does not depend on how each round numbers them. Pakistan is the
*           national total as PDHS publishes it: Gilgit-Baltistan and Azad
*           Jammu and Kashmir are excluded (PDHS 2017-18 gives them zero
*           standard weight, README ON WEIGHTS), and Islamabad and FATA are
*           included. Provinces are the PDHS regions: Punjab without
*           Islamabad, Khyber Pakhtunkhwa without FATA.
* Method    Under-five mortality by the DHS synthetic cohort (Rutstein and
*           Rojas 2006, Guide to DHS Statistics 8.1): for each of eight age
*           segments, children born wholly inside the period count one
*           unit of exposure and the two cohorts that straddle its edges
*           count half, and deaths count when they occur inside the period.
*           This is the method behind every PDHS mortality table, and it is
*           written as nhdr_q5_dhs below. Section 8 keeps its simpler
*           single-cohort version for MICS6.
* What NHDR used, recovered from Table 4A and PDHS's published rates
*   survival    1 - q5/1000, with q5 over the five years before the survey
*               for Pakistan (74 in 2017-18, 94 in 2006-07) and the ten
*               years before it for each province (85, 77, 64, 78 in
*               2017-18, 6. Raw data/Published/PDHS 2017-18 mortality.csv). The
*               2007-08 CDI column takes PDHS 2006-07 and the 2018-19 column
*               PDHS 2017-18.
*   stunting    percent of de facto children under five below -2 SD height
*   wasting     for age and weight for height, the PDHS table definition
* Each reproduced input is checked against the value PDHS or NHDR printed.

* ---- 8A.0 NHDR Table 4 inputs, the targets of this section --------------------
* Section 23 builds its own copy. This section runs first, so it reads the
* published file itself.
import delimited using "$pub/NHDR2020 Table 4.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 3)
keep region sex year survival notstunted notwasted
tempfile t4pd
save `t4pd'

* ---- 8A.1 Helper programs ------------------------------------------------------
* nhdr_pdhs_region: a province name from the value label of a region
* variable. Records it cannot place get an empty name, and 8A.2 counts them.
capture program drop nhdr_pdhs_region
program define nhdr_pdhs_region
    syntax varname, GENerate(name)
    tempvar lab
    decode `varlist', generate(`lab')
    replace `lab' = lower(strtrim(`lab'))
    gen str20 `generate' = ""
    replace `generate' = "Punjab"             if strpos(`lab', "punjab") > 0
    replace `generate' = "Sindh"              if strpos(`lab', "sindh") > 0
    replace `generate' = "Khyber Pakhtunkhwa" if strpos(`lab', "khyber") > 0 | strpos(`lab', "nwfp") > 0 | ///
        strpos(`lab', "frontier") > 0 | inlist(`lab', "kp", "kpk")
    replace `generate' = "Balochistan"        if strpos(`lab', "baloch") > 0 | strpos(`lab', "baluch") > 0
    replace `generate' = "Islamabad"          if strpos(`lab', "islamabad") > 0 | `lab' == "ict"
    replace `generate' = "FATA"               if strpos(`lab', "fata") > 0 | strpos(`lab', "tribal") > 0
    replace `generate' = "Gilgit-Baltistan"   if strpos(`lab', "gilgit") > 0 | `lab' == "gb"
    replace `generate' = "AJK"                if strpos(`lab', "kashmir") > 0 | `lab' == "ajk"
end

* nhdr_q5_dhs: under-five mortality per 1,000, DHS synthetic cohort.
* In memory: b3, b5, b7, v005, v008. months() is the length of the period
* ending the month before the interview. Replaces the data with one row per
* group of by(), holding u5mr_per_1000 and births (unweighted births in the
* period).
* A line-by-line pasteof the DHS Program's own code (DHS-Indicators-Stata,
* Chap08_CM/CM_CHILD.do, prepare_child_file and make_risk_and_deaths), which
* reproduces the published rates of all three rounds to the printed digit.
* Until v4 this program dated each death (b3 + b7) and counted a death in
* the cohort that enters the segment before the period only if that date
* fell inside the period. b7 is recorded in whole years from 12 months on
* (72 to 84 percent of PDHS deaths at 12 to 59 months sit at exactly 12,
* 24, 36 or 48), so the date is pulled to the start of the year and those
* deaths fell out of the period: under-five mortality came out 2 to 3 per
* 1,000 low in every round. DHS weights the deaths of both straddling
* cohorts by one half whatever their date, and that rule alone closes the gap.

capture program drop nhdr_q5_dhs
program define nhdr_q5_dhs
    syntax , MONTHS(integer) [BY(varlist) OFFset(integer 0)]
    tempvar w sm em aad seg d1 d2 inw
    gen double `w'  = v005 / 1000000
    * The period runs from v008 - months to v008 - 1. The interview month is
    * left out, as in the DHS tables. offset() moves the whole period back by
    * that many months, as DHS does for periods other than the latest.
    gen double `sm' = v008 - `offset' - `months'
    gen double `em' = v008 - `offset' - 1
    drop if missing(b3) | b3 > `em'
    gen byte `inw' = (b3 >= `sm')
    * Age at death; a death at 60 months or more counts as a survivor here.
    gen double `aad' = b7 if b5 == 0
    replace `aad' = . if `aad' > 59
    gen byte   `seg' = .
    gen double `d1'  = .
    gen double `d2'  = .
    local j = 0
    foreach s in "0 1" "1 3" "3 6" "6 12" "12 24" "24 36" "36 48" "48 60" {
        local ++j
        local a1 : word 1 of `s'
        local a2 : word 2 of `s'
        replace `seg' = `j'       if !missing(`aad') & `aad' >= `a1' & `aad' < `a2'
        replace `d1'  = b3 + `a1' if `seg' == `j'
        replace `d2'  = b3 + `a2' if `seg' == `j'
    }
    * A death in a segment that runs past the end of the period is treated
    * as wholly inside it (DHS: dod_2 = end_month), only when the period ends
    * at the interview.
    if `offset' == 0 replace `d2' = `em' if !missing(`seg') & `d1' <= `em' & `d2' > `em'
    local elist
    local dlist
    local j = 0
    foreach s in "0 1" "1 3" "3 6" "6 12" "12 24" "24 36" "36 48" "48 60" {
        local ++j
        local a1 : word 1 of `s'
        local a2 : word 2 of `s'
        tempvar died risk
        * Deaths: 1 if the segment of death lies wholly in the period, one half
        * if it straddles the start or the end, whatever the date of death.
        gen double `died' = .
        replace `died' = 1  if `seg' == `j' & `d2' <= `em' & `d1' >= `sm'
        replace `died' = .5 if `seg' == `j' & `d2' >= `sm' & `d1' <  `sm'
        replace `died' = .5 if `seg' == `j' & `d2' >  `em' & `d1' <= `em'
        * Exposure: 1 if the segment lies wholly in the period and the child
        * reached it, one half if it straddles an edge and the child lived
        * through it.
        gen double `risk' = .
        replace `risk' = 1  if (missing(`seg') | `seg' >= `j') & b3 + `a2' <= `em' & b3 + `a1' >= `sm'
        replace `risk' = .5 if (missing(`seg') | `seg' >  `j') & b3 + `a2' >= `sm' & b3 + `a1' <  `sm'
        replace `risk' = .5 if (missing(`seg') | `seg' >  `j') & b3 + `a2' >  `em' & b3 + `a1' <= `em'
        replace `risk' = .5 if `died' == .5
        replace `died' = 0  if missing(`died') & `risk' > 0 & `risk' <= 1
        replace `risk' = 0  if missing(`risk') & `died' > 0 & `died' <= 1
        replace `risk' = 1  if `died' == 1
        gen double _e`j' = `w' * `risk' if !missing(`died')
        gen double _d`j' = `w' * `died'
        local elist `elist' _e`j'
        local dlist `dlist' _d`j'
    }
    local byopt
    if "`by'" != "" local byopt by(`by')
    collapse (sum) `elist' `dlist' births=`inw', `byopt'
    gen double _surv = 1
    forvalues j = 1/8 {
        replace _surv = _surv * (1 - _d`j' / _e`j') if _e`j' > 0
    }
    gen double u5mr_per_1000 = (1 - _surv) * 1000
    gen int window_months = `months'
    drop `elist' `dlist' _surv
end

* ---- 8A.2 Under-five mortality and survival, PDHS 2006-07, 2012-13, 2017-18 ---
* Rows: round, domain (Pakistan and the four provinces), sex (All, Male,
* Female) and window (60 or 120 months).
tempfile pdq5
local first = 1
foreach spec in "2006_07|$pd06/PKBR53DT/PKBR53FL.DTA" "2012_13|$pd12/PKBR61DT/PKBR61FL.DTA" ///
    "2017_18|$pd17/PKBR71DT/PKBR71FL.DTA" {
    local rd = substr("`spec'", 1, strpos("`spec'", "|") - 1)
    local fl = substr("`spec'", strpos("`spec'", "|") + 1, .)
    use v005 v008 v024 b3 b4 b5 b7 using "`fl'", clear
    nhdr_pdhs_region v024, generate(prov)
    quietly count if prov == ""
    nhdr_check, label("Step 5A PDHS `rd' births with an unplaced region [0]") got(`=r(N)') want(0) tol(0)
    drop if inlist(prov, "Gilgit-Baltistan", "AJK", "")
    gen str6 sex = cond(b4 == 1, "Male", cond(b4 == 2, "Female", ""))
    tempfile pdBR
    save `pdBR'
    foreach m in 60 120 {
        * Pakistan, both sexes and by sex.
        use `pdBR', clear
        nhdr_q5_dhs, months(`m')
        gen str20 domain = "Pakistan"
        gen str6 sex = "All"
        tempfile pdA
        save `pdA'
        use `pdBR', clear
        drop if sex == ""
        nhdr_q5_dhs, months(`m') by(sex)
        gen str20 domain = "Pakistan"
        append using `pdA'
        save `pdA', replace
        * The four provinces, both sexes and by sex.
        use `pdBR', clear
        keep if inlist(prov, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
        nhdr_q5_dhs, months(`m') by(prov)
        rename prov domain
        gen str6 sex = "All"
        append using `pdA'
        save `pdA', replace
        use `pdBR', clear
        keep if inlist(prov, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan") & sex != ""
        nhdr_q5_dhs, months(`m') by(prov sex)
        rename prov domain
        append using `pdA'
        gen str7 round = "`rd'"
        if `first' == 0 append using `pdq5'
        save `pdq5', replace
        local first = 0
    }
}
use `pdq5', clear
gen double survival = 1 - u5mr_per_1000 / 1000
order round domain sex window_months u5mr_per_1000 survival births
sort round window_months domain sex
display as text _n "Step 5A: PDHS under-five mortality, DHS synthetic cohort"
list if sex == "All", noobs sepby(round window_months) abbreviate(14)
save "$out/PDHS under5 mortality.dta", replace
export delimited using "$out/PDHS under5 mortality.csv", replace

* Checks against what PDHS published for the five years before each survey.
foreach spec in "2006_07 94" "2012_13 89" "2017_18 74" {
    local rd : word 1 of `spec'
    local q  : word 2 of `spec'
    quietly summarize u5mr_per_1000 if round == "`rd'" & domain == "Pakistan" & sex == "All" & window_months == 60
    nhdr_check, label("Step 5A PDHS `rd' under-five mortality, Pakistan, 5 years [published `q']") ///
        got(`=r(mean)') want(`q') tol(1)
}
* Provinces, ten years, PDHS 2017-18 (6. Raw data/Published/PDHS 2017-18 mortality.csv).
preserve
use `pdhs', clear
rename pdhs_q5 pub_q5
tempfile pubq5
save `pubq5'
restore
preserve
keep if round == "2017_18" & sex == "All" & window_months == 120 & domain != "Pakistan"
merge 1:1 domain using `pubq5', keep(match) nogenerate
gen double _g = abs(u5mr_per_1000 - pub_q5)
list domain u5mr_per_1000 pub_q5 _g, noobs sep(0)
quietly summarize _g
nhdr_check, label("Step 5A PDHS 2017-18 provincial q5, 10 years, worst of 4 [published]") ///
    got(`=r(max)') want(0) tol(1)
restore

* The survival input of the CDI, as NHDR defined it: five years for
* Pakistan both sexes, ten years for provinces and their sexes. Pakistan by
* sex differs between the columns: ten years in 2007-08 and five years in
* 2018-19. With the DHS rates that is the only reading that puts every
* cell within 0.0007 of Table 4A: Pakistan Male 2018-19 is 0.9203 on five
* years against 0.920 printed, and 0.913 on ten.
keep if inlist(round, "2006_07", "2017_18")
gen byte _w5 = (domain == "Pakistan" & sex == "All") | ///
    (domain == "Pakistan" & round == "2017_18")
keep if (_w5 & window_months == 60) | (!_w5 & window_months == 120)
drop _w5
gen str7 year = cond(round == "2006_07", "2007-08", "2018-19")
rename (domain survival) (region survival_pd)
keep region sex year survival_pd
tempfile pd_surv
save `pd_surv'
merge 1:1 region sex year using `t4pd', keepusing(survival) keep(master match) nogenerate
gen double _g = abs(survival_pd - survival)
display as text _n "Step 5A: CDI survival from PDHS against Table 4A"
list region sex year survival_pd survival _g, noobs sepby(year) abbreviate(12)
foreach y in 2007-08 2018-19 {
    quietly summarize _g if year == "`y'" & sex == "All"
    nhdr_check, label("Step 5A CDI survival `y', 5 domains, worst |gap| [published Table 4A]") ///
        got(`=r(max)') want(0) tol(0.0015)
    quietly summarize _g if year == "`y'" & sex != "All"
    nhdr_check, label("Step 5A CDI survival `y' by sex, 10 cells, worst |gap| [published Table 4A]") ///
        got(`=r(max)') want(0) tol(0.0015)
}
drop _g

* ---- 8A.3 Stunting and wasting -------------------------------------------------
* De facto children under five (hv103 = 1, hc1 under 60 months) with a valid
* z-score (hc70 and hc72 below 9990, which excludes the flagged and missing
* codes 9996 to 9999). Stunted: hc70 below -200. Wasted: hc72 below -200.
* PDHS 2006-07 did not measure children, which 8A.3 tests on the file itself.
* In that case the 2007-08 CDI keeps NHDR's printed anthropometry, and the
* PDHS 2012-13 values are shown beside it.
tempfile pdanth
local first = 1
foreach spec in "2006_07|$pd06/PKPR53DT/PKPR53FL.DTA" "2012_13|$pd12/PKPR61DT/PKPR61FL.DTA" ///
    "2017_18|$pd17/PKPR71DT/PKPR71FL.DTA" {
    local rd = substr("`spec'", 1, strpos("`spec'", "|") - 1)
    local fl = substr("`spec'", strpos("`spec'", "|") + 1, .)
    quietly describe using "`fl'", varlist
    local vl `r(varlist)'
    local has70 : list posof "hc70" in vl
    local has72 : list posof "hc72" in vl
    local has1  : list posof "hc1" in vl
    if `has70' == 0 | `has72' == 0 | `has1' == 0 {
        display as text "  PDHS `rd': no height and weight z-scores in the household member file"
        continue
    }
    use hv005 hv024 hv103 hv104 hc1 hc70 hc72 using "`fl'", clear
    * The recode carries hc1, hc70 and hc72 even when children were not
    * measured (PDHS 2006-07), so test for values, not only for the names.
    quietly count if !missing(hc1) & hc70 < 9990
    if r(N) == 0 {
        display as text "  PDHS `rd': height and weight z-scores are empty in the household member file"
        continue
    }
    nhdr_pdhs_region hv024, generate(prov)
    drop if inlist(prov, "Gilgit-Baltistan", "AJK", "")
    keep if hv103 == 1 & hc1 < 60 & !missing(hc1)
    gen double stunted = (hc70 < -200) if hc70 < 9990
    gen double wasted  = (hc72 < -200) if hc72 < 9990
    gen str6 sex = cond(hv104 == 1, "Male", cond(hv104 == 2, "Female", ""))
    gen double wt = hv005 / 1000000
    tempfile pdPR
    save `pdPR'
    * Pakistan and provinces, both sexes and by sex.
    collapse (mean) stunted wasted [aw=wt]
    gen str20 domain = "Pakistan"
    gen str6 sex = "All"
    tempfile pdB
    save `pdB'
    use `pdPR', clear
    drop if sex == ""
    collapse (mean) stunted wasted [aw=wt], by(sex)
    gen str20 domain = "Pakistan"
    append using `pdB'
    save `pdB', replace
    use `pdPR', clear
    keep if inlist(prov, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    collapse (mean) stunted wasted [aw=wt], by(prov)
    rename prov domain
    gen str6 sex = "All"
    append using `pdB'
    save `pdB', replace
    use `pdPR', clear
    keep if inlist(prov, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan") & sex != ""
    collapse (mean) stunted wasted [aw=wt], by(prov sex)
    rename prov domain
    append using `pdB'
    gen str7 round = "`rd'"
    if `first' == 0 append using `pdanth'
    save `pdanth', replace
    local first = 0
}
use `pdanth', clear
replace stunted = 100 * stunted
replace wasted  = 100 * wasted
gen double notstunted_pd = 100 - stunted
gen double notwasted_pd  = 100 - wasted
order round domain sex stunted wasted notstunted_pd notwasted_pd
sort round domain sex
display as text _n "Step 5A: PDHS stunting and wasting, de facto children under five, percent"
list, noobs sepby(round) abbreviate(14)
save "$out/PDHS anthropometry.dta", replace
export delimited using "$out/PDHS anthropometry.csv", replace
quietly count if round == "2006_07"
local anth06 = r(N)
display as text "  PDHS 2006-07 anthropometry rows: `anth06' (0 means the round did not measure children)"
foreach spec in "2012_13 45.0 10.8" "2017_18 37.6 7.1" {
    local rd : word 1 of `spec'
    local s  : word 2 of `spec'
    local w  : word 3 of `spec'
    quietly summarize stunted if round == "`rd'" & domain == "Pakistan" & sex == "All"
    nhdr_check, label("Step 5A PDHS `rd' stunting, Pakistan [published `s']") got(`=r(mean)') want(`s') tol(0.15)
    quietly summarize wasted if round == "`rd'" & domain == "Pakistan" & sex == "All"
    nhdr_check, label("Step 5A PDHS `rd' wasting, Pakistan [published `w']") got(`=r(mean)') want(`w') tol(0.15)
}
* The CDI inputs. 2018-19 is PDHS 2017-18. 2007-08 is PDHS 2006-07 where
* the round measured children, and otherwise stays as NHDR printed it.
keep if round == "2017_18" | round == "2006_07"
gen str7 year = cond(round == "2006_07", "2007-08", "2018-19")
rename domain region
keep region sex year notstunted_pd notwasted_pd
tempfile pd_anth
save `pd_anth'
merge 1:1 region sex year using `t4pd', keepusing(notstunted notwasted) keep(master match) nogenerate
gen double _gs = abs(notstunted_pd - notstunted)
gen double _gw = abs(notwasted_pd - notwasted)
display as text _n "Step 5A: CDI anthropometry from PDHS 2017-18 against Table 4A"
list region sex year notstunted_pd notstunted notwasted_pd notwasted, noobs sepby(year) abbreviate(12)
quietly summarize _gs if year == "2018-19"
nhdr_check, label("Step 5A CDI not stunted 2018-19, 15 cells, worst |gap| [published Table 4A]") ///
    got(`=r(max)') want(0) tol(0.6)
* Not wasted does not close, and no reading of the microdata closes it. The
* national rate here is PDHS's own (7.09 against 7.1 printed), and the five
* female cells sit within 0.31 of Table 4A. The male cells of Table 4A run
* 0.1 to 1.3 points above the microdata (Balochistan 82.1 against 80.8,
* Punjab 95.9 against 95.3), and its Pakistan male (7.2 percent wasted) is
* not PDHS's published 7.6. De jure children, the KR file, a joint validity
* rule, unweighted means and keeping flagged codes 9996 and 9998 were all
* tried, and none puts the 15 cells within 0.57. The 15-cell check stays,
* and fails, as a record that Table 4A's male wasting is not reproducible.
quietly summarize _gw if year == "2018-19"
nhdr_check, label("Step 5A CDI not wasted 2018-19, 15 cells, worst |gap| [published Table 4A]") ///
    got(`=r(max)') want(0) tol(0.6)
quietly summarize _gw if year == "2018-19" & sex == "Female"
nhdr_check, label("Step 5A CDI not wasted 2018-19, 5 female cells, worst |gap| [published Table 4A]") ///
    got(`=r(max)') want(0) tol(0.35)
drop _gs _gw

* The CDI health inputs from PDHS, one row per region, sex and year, used in
* Section 23.4b and 23.5.
use `pd_surv', clear
merge 1:1 region sex year using `pd_anth', nogenerate
tempfile pd_cdi
save `pd_cdi'
export delimited using "$out/PDHS CDI health inputs.csv", replace

* ---- 8A.4 The health gradient by wealth quintile ------------------------------
* NHDR's IHDI measures health inequality across quintiles with a life
* expectancy for each. From PDHS: under-five mortality by household wealth
* quintile (v190, the survey's national wealth index), ten years, converted
* to life expectancy through the Coale-Demeny West family (Section 1.5), as
* Section 16.2 does with MICS6. Rows: round, domain, quintile.
tempfile pdwq
local first = 1
foreach spec in "2006_07|$pd06/PKBR53DT/PKBR53FL.DTA" "2017_18|$pd17/PKBR71DT/PKBR71FL.DTA" {
    local rd = substr("`spec'", 1, strpos("`spec'", "|") - 1)
    local fl = substr("`spec'", strpos("`spec'", "|") + 1, .)
    use v005 v008 v024 v190 b3 b4 b5 b7 using "`fl'", clear
    nhdr_pdhs_region v024, generate(prov)
    drop if inlist(prov, "Gilgit-Baltistan", "AJK", "") | missing(v190)
    tempfile pdBRW
    save `pdBRW'
    nhdr_q5_dhs, months(120) by(v190)
    gen str20 domain = "Pakistan"
    tempfile pdC
    save `pdC'
    use `pdBRW', clear
    keep if inlist(prov, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    nhdr_q5_dhs, months(120) by(prov v190)
    rename prov domain
    append using `pdC'
    gen str7 round = "`rd'"
    if `first' == 0 append using `pdwq'
    save `pdwq', replace
    local first = 0
}
use `pdwq', clear
rename v190 q
nhdr_le_from_q5 u5mr_per_1000, generate(le_pdhs) family(west)
order round domain q u5mr_per_1000 le_pdhs births
sort round domain q
display as text _n "Step 5A: PDHS under-five mortality and life expectancy by wealth quintile, ten years"
list, noobs sepby(round domain) abbreviate(14)
quietly count if round == "2017_18"
nhdr_check, label("Step 5A PDHS 2017-18 wealth quintile rows, 5 domains x 5 [25]") got(`=r(N)') want(25) tol(0)
quietly count if round == "2006_07"
nhdr_check, label("Step 5A PDHS 2006-07 wealth quintile rows, 5 domains x 5 [25]") got(`=r(N)') want(25) tol(0)
save "$out/PDHS wealth quintile mortality.dta", replace
export delimited using "$out/PDHS wealth quintile mortality.csv", replace
tempfile pd_wq
save `pd_wq'

* ---- 8A.5 Figure 5.19: access to health services by wealth quintile, 2017-18 --
* NHDR Figure 5.19 draws three PDHS 2017-18 indicators by wealth quintile:
*   tap water      households whose main drinking water is piped (hv201 11
*                  to 14: into the dwelling, to the yard or plot, a public
*                  tap, or a neighbor's tap), household weights
*   vaccination    children 12 to 23 months, alive, with all basic
*                  vaccinations: BCG, three doses of DPT or pentavalent,
*                  three of polio and measles, by card or mother's report
*                  (h2 to h9 coded 1 to 3), the PDHS table definition
*   delivery       births in the five years before the survey delivered in a
*                  health facility (m15 20 to 49, public, private or NGO)
tempfile f519
local vac519 = .
local fac519 = .
capture noisily {
    use hv005 hv024 hv201 hv270 using "$pd17/PKHR71DT/PKHR71FL.DTA", clear
    nhdr_pdhs_region hv024, generate(prov)
    drop if inlist(prov, "Gilgit-Baltistan", "AJK", "")
    * 99 is the DHS code for a missing answer.
    gen double tap = inrange(hv201, 11, 14) if !missing(hv201) & hv201 != 99
    gen double wt = hv005 / 1000000
    rename hv270 q
    tempfile pdHW
    save `pdHW'
    collapse (mean) tap [aw=wt], by(q)
    tempfile pdTQ
    save `pdTQ'
    use `pdHW', clear
    collapse (mean) tap [aw=wt]
    gen byte q = 6
    append using `pdTQ'
    save `f519'
    use v005 v008 v024 v190 b3 b5 b19 h2 h3 h4 h5 h6 h7 h8 h9 m15 using "$pd17/PKKR71DT/PKKR71FL.DTA", clear
    nhdr_pdhs_region v024, generate(prov)
    drop if inlist(prov, "Gilgit-Baltistan", "AJK", "")
    * Age in months as DHS-7 tabulates it: b19, from the day of birth and
    * the day of interview. v008 - b3 (months only) moves children across
    * the 12 and 23 month edges and gives 65.1 percent with all basic
    * vaccinations, against 65.6 with b19 and 66 printed.
    gen double age_m = b19
    gen byte _got = 1
    foreach v in h2 h3 h4 h5 h6 h7 h8 h9 {
        replace _got = 0 if !inrange(`v', 1, 3)
    }
    gen double basicvac = _got if b5 == 1 & inrange(age_m, 12, 23)
    gen double facility = inrange(m15, 20, 49) if age_m < 60 & !missing(m15)
    gen double wt = v005 / 1000000
    rename v190 q
    tempfile pdKW
    save `pdKW'
    collapse (mean) basicvac facility [aw=wt], by(q)
    tempfile pdKQ
    save `pdKQ'
    use `pdKW', clear
    collapse (mean) basicvac facility [aw=wt]
    gen byte q = 6
    append using `pdKQ'
    merge 1:1 q using `f519', nogenerate
    foreach v in tap basicvac facility {
        replace `v' = 100 * `v'
    }
    gen str10 quintile = ""
    replace quintile = "Poorest" if q == 1
    replace quintile = "Second"  if q == 2
    replace quintile = "Middle"  if q == 3
    replace quintile = "Fourth"  if q == 4
    replace quintile = "Richest" if q == 5
    replace quintile = "Pakistan" if q == 6
    sort q
    quietly summarize basicvac if q == 6
    local vac519 = r(mean)
    quietly summarize facility if q == 6
    local fac519 = r(mean)
    save `f519', replace
    save "$out/Figure 5.19 data.dta", replace
    export delimited using "$out/Figure 5.19 data.csv", replace
    list quintile tap basicvac facility, noobs sep(0)
    graph bar (asis) tap basicvac facility, over(quintile, sort(q) label(labsize(small))) ///
        bar(1, color("0 125 183")) bar(2, color("141 198 63")) bar(3, color("233 83 43")) ///
        blabel(bar, format(%3.0f) size(vsmall)) ///
        ylabel(0(20)100, angle(0) labsize(small)) ytitle("Percent", size(small)) ///
        legend(order(1 "Access to tap water" 2 "Basic vaccination, children 12-23 months" ///
            3 "Delivery in a health facility") rows(1) position(6) size(small)) ///
        title("Figure 5.19  Richer households have more access to health services, 2017-18", size(medium)) ///
        note("PDHS 2017-18 microdata, national wealth quintiles. Pakistan excludes Gilgit-Baltistan and AJK.", ///
            size(vsmall)) graphregion(color(white)) plotregion(color(white))
    graph export "$out/Figure 5.19 health access wealth.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 5.19 health access wealth.png"
nhdr_check, label("Step 5A PDHS 2017-18 basic vaccination, 12-23 months [published 66]") ///
    got(`vac519') want(66) tol(0.55)
nhdr_check, label("Step 5A PDHS 2017-18 delivery in a health facility, 5 years [published 66]") ///
    got(`fac519') want(66) tol(0.55)


*==============================================================================*
* SECTION 9   GROSS REGIONAL PRODUCT (GRP) BY PROVINCE, PASHA'S  SCHEME
*==============================================================================*
* Pakistan has no official provincial accounts. PBS publishes national value
* added by sub-sector and stops there. Every provincial GDP figure in
* circulation is therefore an allocation of national value added across
* provinces using indicator shares. The canonical scheme is Pasha's
* (Institute for Policy Reform, 2015): each sub-sector gets a named allocator
* from a named source. It is applied here to the 22 PBS sub-sectors of the
* 2015-16 base, and every sub-sector has a status flag so that the sharef GDP resting on measured data is reported clearly
*     obtained     the allocator Pasha specifies, from the source he names
*     substitute   a documented second-best allocator
*     unobtained   no allocator: the sub-sector is left out of the totals,
*                  not spread by population, so the gap stays visible
* Formula   GRP_p = sum_s  V_s x a_sp / sum_p a_sp
*           V_s    national value added of sub-sector s, 2018-19, current
*                  basic prices (PBS National Accounts Table 4)
*           a_sp   the allocator for sub-sector s in province p
* Result    95.0 percent of GDP allocated. The 5.0 percent left out is mining
*           and quarrying (no free source of province-wise oil and gas
*           output) and financial and insurance activities (the State Bank
*           table of advances by province was not obtained).

* ---- 9.1 The scheme, sub-sector by sub-sector --------------------------------
* Allocator and source for each sub-sector:
*   A.1.i   Important crops     HIES household crop output value (substitute
*                               for the Agricultural Statistics Year Book)
*   A.1.ii  Other crops         as A.1.i
*   A.1.iii Cotton ginning      HIES household cotton output value
*   A.2     Livestock           HIES consumption of meat, dairy, eggs, fats
*   A.3     Forestry            HIES consumption of firewood
*   A.4     Fishing             HIES household fish catch (weakest allocator:
*                               marine catch is landed by commercial vessels
*                               no household survey observes)
*   B.1     Mining              none (Energy Yearbook is sold, not published), May be buy it later if needed. 
*   B.2.i   Large manufacturing PBS Census of Manufacturing Industries
*                               2015-16, census value added
*   B.2.ii  Small manufacturing LFS informal manufacturing employment
*   B.2.iii Slaughtering        HIES consumption of meat
*   B.3     Electricity, gas    PBS electricity generation by province,
*           and water           2020-21
*   B.4     Construction        LFS employment weighted by earnings
*   C.1     Trade               LFS employment weighted by earnings
*   C.2     Transport           OCAC consumption of petrol, diesel and
*                               furnace oil, 2018-19
*   C.3     Hotels, restaurants LFS employment
*   C.4     Information         LFS employment (substitute for PTA cellular
*                               subscribers)
*   C.5     Finance             none (SBP advances by province not obtained)
*   C.6     Real estate         HIES actual and imputed rent
*   C.7-C.10 Public administration, education, health, other services:
*                               LFS employment weighted by earnings
* Very rough buy we have to get somewhere
clear
input str8 code str48 sub_sector str10 status
"A.1.i"   "Important Crops"                               "substitute"
"A.1.ii"  "Other Crops"                                   "substitute"
"A.1.iii" "Cotton Ginning"                                "substitute"
"A.2"     "Livestock"                                     "obtained"
"A.3"     "Forestry"                                      "obtained"
"A.4"     "Fishing"                                       "substitute"
"B.1"     "Mining and Quarrying"                          "unobtained"
"B.2.i"   "Large Scale Manufacturing"                     "substitute"
"B.2.ii"  "Small Scale Manufacturing"                     "obtained"
"B.2.iii" "Slaughtering"                                  "obtained"
"B.3"     "Electricity Gas and Water supply"              "substitute"
"B.4"     "Construction"                                  "obtained"
"C.1"     "Wholesale and Retail trade"                    "obtained"
"C.2"     "Transportation and Storage"                    "obtained"
"C.3"     "Accommodation and Food Services"               "obtained"
"C.4"     "Information and Communication"                 "substitute"
"C.5"     "Financial and Insurance Activities"            "unobtained"
"C.6"     "Real Estate Activities Ownership of Dwellings" "obtained"
"C.7"     "Public Administration and Social Security"     "obtained"
"C.8"     "Education"                                     "obtained"
"C.9"     "Human Health and Social Work"                  "obtained"
"C.10"    "Other Private Services"                        "obtained"
end
tempfile scheme
save `scheme'
import delimited using "$pub/PBS GVA subsector.csv", clear varnames(1) asdouble encoding(utf-8) 
keep code gva_2018_19
merge 1:1 code using `scheme', assert(match) nogenerate
quietly summarize gva_2018_19
scalar gdp1819 = r(sum)
tempfile gva
save `gva'

* Coverage of GDP by allocator status.
collapse (sum) gva_rs_mn=gva_2018_19, by(status)
gen double share_of_gdp_pct = 100 * gva_rs_mn / gdp1819
display as text _n "Step 6: share of 2018-19 GDP by allocator status"
list, noobs sep(0)
export delimited using "$out/GRP coverage by status 2018-19.csv"

* ---- 9.2 Allocators from published administrative sources -------------------
* C.2 Transport: OCAC Pakistan Oil Report 2018-19, motor spirit, high speed
* diesel and furnace oil, metric tons, by province.
import delimited using "$pub/OCAC petroleum consumption.csv", clear varnames(1) asdouble encoding(utf-8)
keep if fiscal_year == "2018-19" & inlist(product, "MS", "HSD", "FO")
collapse (sum) punjab sindh khyberpakhtunkhwa balochistan
nhdr_prov_long, code("C.2")
tempfile sh
save `sh'

* B.3 Electricity: PBS, Trends in Electricity Generation, Table 4.7, GWh
* generated by province, 2020-21, the year nearest 2018-19 that was obtained.
import delimited using "$pub/PBS electricity generation.csv", clear varnames(1) asdouble encoding(utf-8)
keep if fiscal_year == "2020-21"
nhdr_prov_long, code("B.3")
append using `sh'
save `sh', replace

* B.2.i Large scale manufacturing: PBS Census of Manufacturing Industries
* 2015-16, census value added by province.
import delimited using "$pub/PBS CMI 2015-16.csv", clear varnames(1) asdouble encoding(utf-8)
keep if reference_year == "2015-16" & measure == "census value added"
nhdr_prov_long, code("B.2.i")
append using `sh'
save `sh', replace

* ---- 9.3 Allocators from the Labour Force Survey 2018-19 ----------------------
* Fields: Province, S05C10 industry of main job (PSIC 2010 class),
* S05C11 kind of enterprise, S05C13 persons engaged in the enterprise,
* S07C04 net monthly earnings from the main job, Weight.
use Province S05C10 S05C11 S05C13 S07C04 Weight using "$lfs/LFS 2018-19.dta", clear
gen str20 province = ""
replace province = "Khyber Pakhtunkhwa" if Province == 1
replace province = "Punjab"             if Province == 2
replace province = "Sindh"              if Province == 3
replace province = "Balochistan"        if Province == 4
* PSIC 2010 class to division. LFS stores the class as a number, so the
* leading zero of every class in divisions 01 to 09 is lost: class 0150,
* mixed farming, is stored as 150 and class 0510, coal mining, as 510. The
* division is therefore the stored class divided by 100 and truncated, for
* three and four digit values alike.
gen double psic_div = floor(S05C10 / 100) if inrange(S05C10, 100, 9999)
* Divisions onto PBS national accounts sub-sectors. Households as employers
* of domestic staff (division 97) go to other private services rather than
* being dropped: in Pakistan it is a large and mainly urban category, and
* leaving it out would tilt every service allocator toward rural provinces.
gen str8 ss = ""
replace ss = "A.1.i"  if psic_div == 1
replace ss = "A.3"    if psic_div == 2
replace ss = "A.4"    if psic_div == 3
replace ss = "B.1"    if inrange(psic_div, 5, 9)
replace ss = "B.2.i"  if inrange(psic_div, 10, 33)
replace ss = "B.3"    if inrange(psic_div, 35, 39)
replace ss = "B.4"    if inrange(psic_div, 41, 43)
replace ss = "C.1"    if inrange(psic_div, 45, 47)
replace ss = "C.2"    if inrange(psic_div, 49, 53)
replace ss = "C.3"    if inlist(psic_div, 55, 56)
replace ss = "C.4"    if inrange(psic_div, 58, 63)
replace ss = "C.5"    if inrange(psic_div, 64, 66)
replace ss = "C.6"    if psic_div == 68
replace ss = "C.7"    if psic_div == 84
replace ss = "C.8"    if psic_div == 85
replace ss = "C.9"    if inrange(psic_div, 86, 88)
replace ss = "C.10"   if inrange(psic_div, 69, 75) | inrange(psic_div, 77, 82) | inrange(psic_div, 90, 99)
drop if ss == "" | province == "" | missing(Weight)
quietly count
nhdr_check, label("Step 6 LFS employed persons with an industry code [reference]") ///
    got(`=r(N)') want(75210) tol(0)
* A worker with no reported earnings still counts in the headcount allocators
* and contributes nothing to the earnings-weighted ones, the conservative
* treatment for unpaid family workers and the self-employed.
gen double earn  = cond(missing(S07C04), 0, S07C04)
gen double w_emp = Weight
gen double w_inc = Weight * earn
* Small scale manufacturing, B.2.ii, on the PBS Labour Force Survey definition
* of the informal sector: individual ownership or partnership (S05C11 codes 8
* and 9) with fewer than ten persons engaged (S05C13).
gen byte informal = (ss == "B.2.i") & inlist(S05C11, 8, 9) & (S05C13 < 10)
tempfile lfsw
save `lfsw'

* Headcount shares.
keep if informal
collapse (sum) value=w_emp, by(province)
gen str8 code = "B.2.ii"
append using `sh'
save `sh', replace
foreach c in C.3 C.4 {
    use `lfsw', clear
    keep if ss == "`c'"
    collapse (sum) value=w_emp, by(province)
    gen str8 code = "`c'"
    append using `sh'
    save `sh', replace
}
* Earnings-weighted shares, where a worker in Karachi and a worker in
* Balochistan do not stand for the same value added.
foreach c in B.4 C.1 C.7 C.8 C.9 C.10 {
    use `lfsw', clear
    keep if ss == "`c'"
    collapse (sum) value=w_inc, by(province)
    gen str8 code = "`c'"
    append using `sh'
    save `sh', replace
}

* ---- 9.4 Allocators from HIES 2018-19 consumption --------------------------------
* Item codes, section 6: meat 11201 to 11204, milk, dairy and eggs 11401 to
* 11410, animal fats 11501, 11502 and 11506, firewood 45401 and 45402, actual
* and imputed rent 41101, 42101, 42102 and 42103. All four value columns count
* (purchased, received as wages in kind, own produced, received as gift). The
* annualization factor is common to every item in a block, so it cancels out
* of a share and is not applied.
use hhcode psu province itc v1 v2 v3 v4 ///
    if inrange(itc, 11201, 11204) | inrange(itc, 11401, 11410) | ///
       inlist(itc, 11501, 11502, 11506, 45401, 45402, 41101, 42101, 42102, 42103) ///
    using "$h18/sec_6a.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
merge m:1 psu using "$h18/weight.dta", keep(master match) nogenerate
gen double wv = v * weight
gen str20 province_name = ""
replace province_name = "Khyber Pakhtunkhwa" if province == 1
replace province_name = "Punjab"             if province == 2
replace province_name = "Sindh"              if province == 3
replace province_name = "Balochistan"        if province == 4
drop province
rename province_name province
drop if province == ""
gen byte meat  = inrange(itc, 11201, 11204)
gen byte dairy = inrange(itc, 11401, 11410)
gen byte fats  = inlist(itc, 11501, 11502, 11506)
gen byte fire  = inlist(itc, 45401, 45402)
gen byte rent  = inlist(itc, 41101, 42101, 42102, 42103)
tempfile hcons
save `hcons'
foreach spec in "A.2 (meat|dairy|fats)" "B.2.iii meat" "A.3 fire" "C.6 rent" {
    local c    : word 1 of `spec'
    local cond : word 2 of `spec'
    use `hcons', clear
    keep if `cond'
    collapse (sum) value=wv, by(province)
    gen str8 code = "`c'"
    append using `sh'
    save `sh', replace
}

* ---- 9.5 Allocators from HIES 2018-19 farm output -----------------------------------
* Section 10a: code 135 is the value of all crops, code 122 the value of
* cotton. Section 10b: code 171 is the value of fish catch. s10c3 is the
* value, in rupees. These substitute for the Agricultural Statistics Year
* Book, whose province tables are district-wise with no province summary.
foreach spec in "sec_10a 135 A.1.i" "sec_10a 135 A.1.ii" "sec_10a 122 A.1.iii" "sec_10b 171 A.4" {
    local f : word 1 of `spec'
    local k : word 2 of `spec'
    local c : word 3 of `spec'
    use psu province codes s10c3 if codes == `k' using "$h18/`f'.dta", clear
    merge m:1 psu using "$h18/weight.dta", keep(master match) nogenerate
    gen double value = cond(missing(s10c3), 0, s10c3) * weight
    gen str20 prov = ""
    replace prov = "Khyber Pakhtunkhwa" if province == 1
    replace prov = "Punjab"             if province == 2
    replace prov = "Sindh"              if province == 3
    replace prov = "Balochistan"        if province == 4
    drop if prov == ""
    drop province
    rename prov province
    collapse (sum) value, by(province)
    gen str8 code = "`c'"
    append using `sh'
    save `sh', replace
}

* ---- 9.6 Allocate and sum ----------------------------------------------------------
use `sh', clear
* A province with no records for an allocator gets a zero share, not a gap.
fillin code province
replace value = 0 if missing(value)
drop _fillin
bysort code: egen double value_total = total(value)
gen double share = value / value_total
tempfile shares
save `shares'
* The allocator share table, one row per sub-sector, percent.
keep code province share
replace share = 100 * share
replace province = subinstr(province, " ", "_", .)
reshape wide share, i(code) j(province) string
merge 1:1 code using `scheme', keepusing(sub_sector) keep(master match) nogenerate
display as text _n "Step 6: allocator shares, percent of each sub-sector"
list, noobs sep(0) abbreviate(20)
export delimited using "$out/GRP allocator shares 2018-19.csv"

* Which sub-sectors have no allocator.
use `shares', clear
keep code
duplicates drop
tempfile shcodes
save `shcodes'
use `gva', clear
merge 1:1 code using `shcodes', keep(master match)
gen byte allocated = (_merge == 3)
drop _merge
quietly summarize gva_2018_19 if !allocated
scalar unalloc = r(sum)
scalar coverage = 100 * (1 - unalloc / gdp1819)
display as text _n "Sub-sectors left out of the totals:"
list code sub_sector gva_2018_19 if !allocated, noobs sep(0)
display as text "Reconstruction allocates " %5.2f coverage " percent of GDP at basic prices."
nhdr_check, label("Step 6 share of GDP allocated to provinces, percent [reference]") ///
    got(`=coverage') want(94.9849) tol(0.01)

* Provincial totals.
use `shares', clear
merge m:1 code using `gva', keepusing(gva_2018_19 sub_sector status) keep(match) nogenerate
gen double gva_rs_mn = gva_2018_19 * share
export delimited code sub_sector status province gva_rs_mn using "$out/GRP allocation 2018-19.csv"
collapse (sum) grp_rs_mn=gva_rs_mn, by(province)
quietly summarize grp_rs_mn
gen double share_pct = 100 * grp_rs_mn / r(sum)
display as text _n "Step 6: gross regional product, 2018-19, Rs million and percent"
list, noobs sep(0)
foreach pr in "Punjab 57.6279" "Sindh 27.5940" "Khyber_Pakhtunkhwa 10.3646" "Balochistan 4.4135" {
    local nm : word 1 of `pr'
    local v  : word 2 of `pr'
    local nm = subinstr("`nm'", "_", " ", .)
    quietly summarize share_pct if province == "`nm'"
    nhdr_check, label("Step 6 `nm' share of national value added [reference]") ///
        got(`=r(mean)') want(`v') tol(0.01)
}
tempfile grptot
save `grptot'

* ---- 9.7 Four estimates of the same quantity ------------------------------------------
* This reconstruction against Pasha (Business Recorder 2021), the Khyber
* Pakhtunkhwa Bureau of Statistics nightlights estimate (2021) and PIDE's
* luminosity based City Development Product (2022, calendar 2019).
import delimited using "$pub/GRP published estimates.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 3 4)
keep if (source == "Pasha BR 2021" & year == "2018-19") | ///
        (source == "KP BOS nightlights 2021" & year == "2018-19") | ///
        (source == "PIDE RASTA 2022" & year == "2019")
keep if inlist(province, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
gen str12 est = ""
replace est = "pasha_2021" if source == "Pasha BR 2021"
replace est = "kpbos_2021" if source == "KP BOS nightlights 2021"
replace est = "pide_2022"  if source == "PIDE RASTA 2022"
keep province est share_pct
reshape wide share_pct, i(province) j(est) string
merge 1:1 province using `grptot', keepusing(share_pct) nogenerate
rename share_pct share_pct_reproduced
egen double hi = rowmax(share_pct_reproduced share_pctpasha_2021 share_pctkpbos_2021 share_pctpide_2022)
egen double lo = rowmin(share_pct_reproduced share_pctpasha_2021 share_pctkpbos_2021 share_pctpide_2022)
gen double range_pts = hi - lo
drop hi lo
display as text _n "Step 6: provincial share of national value added, four estimates, and the range"
list, noobs sep(0) abbreviate(22)
export delimited using "$out/GRP source comparison 2018-19.csv"

* ---- 9.8 Per head, in PPP dollars ---------------------------------------------------
* 2017 census populations (Khyber Pakhtunkhwa including the seven merged
* districts, as the LFS and HIES microdata do) and the 2018 World Bank GDP
* PPP conversion factor. Using the market exchange rate instead would cut
* the income index by roughly a third.
import delimited using "$pub/Census 2017 population.csv", clear varnames(1) asdouble encoding(utf-8)
keep province population_2017
merge 1:1 province using `grptot', keepusing(grp_rs_mn) nogenerate
gen double grp_pc_ppp = grp_rs_mn * 1e6 / population_2017 / ppp2018
quietly summarize grp_rs_mn
local g = r(sum)
quietly summarize population_2017
scalar grp_pc_ppp_pak = `g' * 1e6 / r(sum) / ppp2018
gen double grp_relative = grp_pc_ppp / grp_pc_ppp_pak
rename province domain
merge 1:1 domain using `t2a_all', keepusing(pci_2018_19) keep(master match) nogenerate
rename pci_2018_19 nhdr_pci_2018_19
gen double nhdr_relative = nhdr_pci_2018_19 / pci_pak_1819
rename domain province
display as text _n "Step 6: reconstructed GRP per head against the NHDR 2020 income column"
list, noobs sep(0) abbreviate(20)
foreach pr in "Punjab 1.07788" "Sindh 1.18572" "Khyber_Pakhtunkhwa 0.60034" "Balochistan 0.73567" {
    local nm : word 1 of `pr'
    local v  : word 2 of `pr'
    local nm = subinstr("`nm'", "_", " ", .)
    quietly summarize grp_relative if province == "`nm'"
    nhdr_check, label("Step 6 `nm' GRP per head relative to Pakistan [reference]") ///
        got(`=r(mean)') want(`v') tol(0.0005)
}
keep province grp_relative grp_pc_ppp nhdr_relative
tempfile grprel
save `grprel'
export delimited using "$out/GRP per capita 2018-19.csv"

*==============================================================================*
* SECTION 10   WHAT NHDR'S HDI INCOME COLUMN IS: LEVEL, RANKING, SCALE
*==============================================================================*
* The per capita income column of Table 2A is the one input the reproduction
* cannot reproduce. Three tests establish what it is.
*   Test 1  Where does the provincial pattern come from? Household survey
*           income and consumption, this GRP reconstruction and Pasha's 2021
*           estimate, each relative to Pakistan, against the printed pattern.
*   Test 2  What are the quintile rows cut on? Income and consumption
*           quintiles, each tested on all 15 domains.
*   Test 3  What sets the level? The World Bank GNI per head in PPP dollars
*           against PBS GNI at the PPP factor.
* Source    HIES 2018-19 sec_12ce.dta (t_income, t_exp, annual rupees per
*           household), plist.dta (household size), weight.dta (weight per PSU)
* Weight    population weight = household weight x household size

* Result    the level is the World Bank GNI control, the distribution is the
*           survey scaled up about threefold, the quintiles are consumption
*           quintiles, and the provincial pattern matches no published
*           estimate of regional product

* ---- 10.1 Household file -------------------------------------------------------
use hhcode using "$h18/plist.dta", clear
bysort hhcode: gen int hhsize = _N
by hhcode: keep if _n == 1
tempfile hhsize18
save `hhsize18'
use hhcode province region psu t_income t_exp using "$h18/sec_12ce.dta", clear
merge 1:1 hhcode using `hhsize18', keep(match) nogenerate
merge m:1 psu using "$h18/weight.dta", keep(match) nogenerate
gen double pc_inc = t_income / hhsize
gen double pc_exp = t_exp / hhsize
gen double pop_w  = weight * hhsize
drop if missing(pop_w)
tempfile inc18
save `inc18'

* ---- 10.2 Test 1, the provincial pattern ------------------------------------------
quietly summarize pc_inc [aw=pop_w]
scalar base_inc = r(mean)                 // survey income per head, rupees a year
quietly summarize pc_exp [aw=pop_w]
scalar base_exp = r(mean)
tempname pt
tempfile test1
postfile `pt' str20 province double(survey_income survey_consumption) using `test1'
forvalues k = 1/4 {
    local nm : word `k' of "Khyber Pakhtunkhwa" Punjab Sindh Balochistan
    quietly summarize pc_inc [aw=pop_w] if province == `k'
    local ri = r(mean) / base_inc
    quietly summarize pc_exp [aw=pop_w] if province == `k'
    local re = r(mean) / base_exp
    post `pt' ("`nm'") (`ri') (`re')
}
postclose `pt'
use `test1', clear
rename province domain
merge 1:1 domain using `t2a_all', keepusing(pci_2018_19) keep(master match) nogenerate
gen double nhdr_printed = pci_2018_19 / pci_pak_1819
drop pci_2018_19
rename domain province
merge 1:1 province using `grprel', keepusing(grp_relative) keep(master match) nogenerate
* Pasha, Business Recorder 2021: per capita GRP 2018-19 relative to Pakistan.
preserve
import delimited using "$pub/GRP published estimates.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 3 4)
keep if source == "Pasha BR 2021"
quietly summarize per_capita_rs if province == "Pakistan"
gen double pasha_2018_19 = per_capita_rs / r(mean)
keep province pasha_2018_19
tempfile pasha
save `pasha'
restore
merge 1:1 province using `pasha', keep(master match) nogenerate
display as text _n "Step 7, test 1: provincial per head values relative to Pakistan"
list, noobs sep(0) abbreviate(20)
* Mean absolute deviation of each candidate from the printed NHDR pattern.
foreach v in survey_income survey_consumption grp_relative pasha_2018_19 {
    gen double _d = abs(`v' - nhdr_printed)
    quietly summarize _d
    scalar mad_`v' = r(mean)
    display as text "  mean absolute deviation from NHDR, " %-20s "`v'" as result %7.4f r(mean)
    drop _d
}
nhdr_check, label("Step 7 test 1, Pasha 2021 deviation from NHDR [reference 0.061]") ///
    got(`=mad_pasha_2018_19') want(0.06072) tol(0.0005)
nhdr_check, label("Step 7 test 1, GRP reproduction deviation from NHDR [reference 0.080]") ///
    got(`=mad_grp_relative') want(0.0795) tol(0.001)
nhdr_check, label("Step 7 test 1, survey consumption deviation [reference 0.088]") ///
    got(`=mad_survey_consumption') want(0.08842) tol(0.0005)
nhdr_check, label("Step 7 test 1, survey income deviation [reference 0.103]") ///
    got(`=mad_survey_income') want(0.1027) tol(0.0005)
export delimited using "$out/Income level diagnosis.csv"

* ---- 10.3 Test 2, the ranking variable ------------------------------------------
* For every domain, quintiles are cut once on per capita income and once on
* per capita consumption. For each cut, the mean income of each quintile
* relative to the domain mean is compared with the published ratio Q_k / All.
* The worst gap in each domain is kept.
use `t2a', clear
keep domain quintile pci_2018_19
bysort domain: egen double pci_all = max(cond(quintile == "All", pci_2018_19, .))
drop if quintile == "All"
gen byte q = real(substr(quintile, 2, 1))
gen double want = pci_2018_19 / pci_all
keep domain q want
tempfile pubq
save `pubq'

use `inc18', clear
nhdr_stack_domains, province(province) region(region)
nhdr_quintile, welfare(pc_inc) wtvar(pop_w) by(domain) generate(q_pc_inc)
nhdr_quintile, welfare(pc_exp) wtvar(pop_w) by(domain) generate(q_pc_exp)
tempfile incst
save `incst'
collapse (mean) allm=pc_inc [aw=pop_w], by(domain)
tempfile allm
save `allm'
tempfile test2
local first = 1
foreach r in pc_inc pc_exp {
    use `incst', clear
    collapse (mean) m=pc_inc [aw=pop_w], by(domain q_`r')
    rename q_`r' q
    merge m:1 domain using `allm', nogenerate
    gen double got = m / allm
    merge 1:1 domain q using `pubq', keep(match) nogenerate
    gen double absd = abs(got - want)
    collapse (max) worst=absd, by(domain)
    gen str8 ranked_on = "`r'"
    if !`first' append using `test2'
    save `test2', replace
    local first = 0
}
reshape wide worst, i(domain) j(ranked_on) string
gen byte aggregate = inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
display as text _n "Step 7, test 2: worst quintile gap in each domain, by ranking variable"
list, noobs sep(0) abbreviate(16)
foreach r in pc_inc pc_exp {
    quietly summarize worst`r'
    scalar t2all_`r' = r(mean)
    quietly summarize worst`r' if aggregate
    scalar t2agg_`r' = r(mean)
    display as text "  ranked on `r': mean worst gap, 15 domains " as result %6.4f t2all_`r' ///
        as text ", five aggregate domains " as result %6.4f t2agg_`r'
}
nhdr_check, label("Step 7 test 2, consumption quintiles, 5 aggregates [reference 0.046]") ///
    got(`=t2agg_pc_exp') want(0.04568) tol(0.002)
nhdr_check, label("Step 7 test 2, income quintiles, 5 aggregates [reference 0.288]") ///
    got(`=t2agg_pc_inc') want(0.28806) tol(0.002)
nhdr_check, label("Step 7 test 2, consumption quintiles, 15 domains [reference 0.117]") ///
    got(`=t2all_pc_exp') want(0.11674) tol(0.002)
export delimited using "$out/Income quintile diagnosis.csv"

* ---- 10.4 Test 3, the level ------------------------------------------------------
scalar gni_pc_pbs = gni_mp_1819 * 1e6 / (pop_1819 * 1e6)
scalar underreport = pci_pak_1819 * ppp2018 / base_inc
display as text _n "Step 7, test 3: what sets the published level"
display as text "  GNI per head 2018-19, PBS, rupees          " as result %12.0fc gni_pc_pbs
display as text "  PPP conversion factor 2018, rupees per $   " as result %12.2f ppp2018
display as text "  PBS GNI per head at the PPP factor, $      " as result %12.0fc gni_pc_pbs / ppp2018
display as text "  World Bank GNI per head PPP 2018, $        " as result %12.0fc gnic2018
display as text "  NHDR printed, Pakistan 2018-19, $          " as result %12.0fc pci_pak_1819
display as text "  survey income per head, rupees a year      " as result %12.0fc base_inc
display as text "  implied underreporting factor              " as result %12.2f underreport
nhdr_check, label("Step 7 test 3, NHDR control against World Bank GNI PPP, percent") ///
    got(`=100 * abs(gnic2018 - pci_pak_1819) / gnic2018') want(0.449) tol(0.01)
nhdr_check, label("Step 7 test 3, underreporting factor [reference 3.03]") ///
    got(`=underreport') want(3.027) tol(0.005)

*==============================================================================*
* SECTION 11   HIES 2024-25: CHECKING THE NEW SURVEY AGAINST PBS
*==============================================================================*
* Before an index is built on a new round, the round has to be shown to be
* read correctly. Two checks against what PBS itself published.
* Source    PBS, HIES 2024-25 microdata, 30,123 households
*             section_info.dta       prcode, hhno, province, region
*             plist_roster.dta       prcode, hhno, idc, s1aq51 age
*             sec_2ab_education.dta  s2aq01 can read (1 yes), s2aq02 can write
*                                    (1 yes), s2bq01 status, s2bq10 class
*             weight.dta             weight per PSU (prcode)
*             sec_6a_consum_exp.dta  consumption, section header codes 1000,
*                                    2000, 4000, 5000 and value columns v1-v4
* Household consumption aggregate. The rule is the one PBS writes into the
* variable labels of its own 2018-19 summary file:
*     C_h = 26 x v(1000) + 12 x v(2000) + 12 x v(4000) + 1 x v(5000)
* 26 annualizes the fourteen-day food recall, 12 a monthly recall, and
* section 5000 is already annual. All four value columns count: purchased,
* received as wages in kind, own produced, and received as gift or
* assistance. Leaving out the in-kind columns understates rural consumption
* by about a fifth.
* Result    literacy (10 and over) within 0.48 points of PBS in every
*           province, consumption within 0.84 percent

* ---- 11.1 The 2018-19 aggregate first, same rule, as a control -----------------
use hhcode psu itc v1 v2 v3 v4 if inlist(itc, 1000, 2000, 4000, 5000) ///
    using "$h18/sec_6a.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
gen double a = v * cond(itc == 1000, 26, cond(itc == 5000, 1, 12))
collapse (sum) t_exp=a, by(hhcode psu)
merge 1:1 hhcode using `hhsize18', keep(match) nogenerate
merge m:1 psu using "$h18/weight.dta", keep(master match) nogenerate
drop if missing(weight)
quietly summarize t_exp [aw=weight]
scalar c18_hh = r(mean) / 12
nhdr_check, label("Step 8 HIES 2018-19 consumption per household a month [PBS 37,159]") ///
    got(`=c18_hh') want(`=bm_cons1819_hh_month') tol(`=0.01 * bm_cons1819_hh_month')
nhdr_check, label("Step 8 HIES 2018-19 consumption per household a month [reference]") ///
    got(`=c18_hh') want(37063.49) tol(1)

* ---- 11.2 HIES 2024-25 households ------------------------------------------------
use prcode hhno using "$h24/plist_roster.dta", clear
bysort prcode hhno: gen int hhsize = _N
by prcode hhno: keep if _n == 1
tempfile hhsize24
save `hhsize24'
use prcode hhno itc v1 v2 v3 v4 if inlist(itc, 1000, 2000, 4000, 5000) ///
    using "$h24/sec_6a_consum_exp.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
gen double a = v * cond(itc == 1000, 26, cond(itc == 5000, 1, 12))
collapse (sum) t_exp=a, by(prcode hhno)
merge 1:1 prcode hhno using `hhsize24', keep(match) nogenerate
merge 1:1 prcode hhno using "$h24/section_info.dta", keepusing(province region) ///
    keep(master match) nogenerate
merge m:1 prcode using "$h24/weight.dta", keep(master match) nogenerate
drop if missing(weight) | missing(hhsize) | hhsize <= 0
gen double pc_exp = t_exp / hhsize
gen double pop_w  = weight * hhsize
tempfile hh24
save `hh24'

quietly count
nhdr_check, label("Step 8 HIES 2024-25 households [PBS 30,123]") got(`=r(N)') want(30123) tol(0)
gen double m_exp = t_exp / 12
quietly summarize m_exp [aw=weight]
scalar c24_hh = r(mean)
quietly summarize m_exp [aw=weight] if region == 2
scalar c24_urban = r(mean)
quietly summarize m_exp [aw=weight] if region == 1
scalar c24_rural = r(mean)
quietly summarize hhsize [aw=weight]
scalar c24_size = r(mean)
gen double _num = t_exp * weight
gen double _den = hhsize * weight
quietly summarize _num
local num = r(sum)
quietly summarize _den
scalar c24_pc = `num' / r(sum) / 12
drop _num _den m_exp
display as text _n "Step 8: HIES 2024-25 consumption, rupees a month, against PBS"
display as text "  per household " as result %9.0fc c24_hh    as text "  PBS " as result %9.0fc bm_cons2425_hh_month
display as text "  urban         " as result %9.0fc c24_urban as text "  PBS " as result %9.0fc bm_cons2425_urban
display as text "  rural         " as result %9.0fc c24_rural as text "  PBS " as result %9.0fc bm_cons2425_rural
display as text "  per capita    " as result %9.0fc c24_pc    as text "  PBS " as result %9.0fc bm_cons2425_pc_month
display as text "  household size" as result %9.2f  c24_size  as text "  PBS " as result %9.2f  bm_cons2425_hhsize
nhdr_check, label("Step 8 HIES 2024-25 consumption per household [PBS 79,150, within 1%]") ///
    got(`=c24_hh') want(`=bm_cons2425_hh_month') tol(`=0.01 * bm_cons2425_hh_month')
nhdr_check, label("Step 8 HIES 2024-25 consumption per household [reference 78,557]") ///
    got(`=c24_hh') want(78556.99) tol(1)
nhdr_check, label("Step 8 HIES 2024-25 household size [PBS 5.98]") ///
    got(`=c24_size') want(`=bm_cons2425_hhsize') tol(0.03)

* ---- 11.3 HIES 2024-25 persons, literacy and enrolment -----------------------------
use prcode hhno idc province region s1aq51 s1aq03 using "$h24/plist_roster.dta", clear
merge 1:1 prcode hhno idc using "$h24/sec_2ab_education.dta", ///
    keepusing(s2aq01 s2aq02 s2bq01 s2bq05 s2bq10) keep(master match) nogenerate
merge m:1 prcode hhno using `hh24', keepusing(weight pc_exp) keep(master match) nogenerate
drop if missing(weight)
rename s1aq51 age
* In 2024-25 reading and writing are asked separately. Literate means both.
gen double lit15 = (s2aq01 == 1 & s2aq02 == 1) if age >= 15 & !missing(age) & !missing(s2aq01)
gen double lit10 = (s2aq01 == 1 & s2aq02 == 1) if age >= 10 & !missing(age) & !missing(s2aq01)
* Level-matched net enrolment, the Section 4 definition. The class field is
* s2bq10 in this round, not s2bq14.
gen double cls = s2bq10 if s2bq01 == 3
replace cls = . if inlist(cls, 25, 26, 27, 28) | cls > 10
gen double ner = ((inrange(age, 5, 9)   & inrange(cls, 1, 5))  | ///
                  (inrange(age, 10, 12) & inrange(cls, 6, 8))  | ///
                  (inrange(age, 13, 14) & inrange(cls, 9, 10))) if inrange(age, 5, 14)
* The person file is kept for the IHDI, GDI and GII in Sections 16 to 18.
tempfile p24
save `p24'
keep province region weight lit15 lit10 ner
nhdr_stack_domains, province(province) region(region)
collapse (mean) lit15 lit10 ner [aw=weight], by(domain)
foreach v in lit15 lit10 ner {
    replace `v' = 100 * `v'
}
rename (lit15 lit10 ner) (lit_15plus lit_10plus ner_5_14)
tempfile ind24
save `ind24'
display as text _n "Step 8: HIES 2024-25 literacy and enrolment by domain"
list, noobs sep(0)
foreach pr in "Pakistan PAK" "Punjab PUN" "Sindh SIN" "Khyber_Pakhtunkhwa KP" "Balochistan BAL" {
    local nm : word 1 of `pr'
    local id : word 2 of `pr'
    local nm = subinstr("`nm'", "_", " ", .)
    quietly summarize lit_10plus if domain == "`nm'"
    nhdr_check, label("Step 8 HIES 2024-25 literacy 10+, `nm' [PBS]") ///
        got(`=r(mean)') want(`=bm_lit10_hies2425_`id'') tol(0.5)
}
quietly summarize lit_15plus if domain == "Pakistan"
nhdr_check, label("Step 8 HIES 2024-25 literacy 15+, Pakistan [reference 59.99]") ///
    got(`=r(mean)') want(59.9899) tol(0.01)
quietly summarize ner_5_14 if domain == "Pakistan"
nhdr_check, label("Step 8 HIES 2024-25 net enrolment, Pakistan [reference 38.48]") ///
    got(`=r(mean)') want(38.4774) tol(0.01)


*==============================================================================*
* SECTION 12   HUMAN DEVELOPMENT INDEX (HDI) 2024-25, INPUTS AS THE SURVEYS REPORT
*==============================================================================*
* The recovered construction applied with every input taken as the newest
* available survey reports it. This is the survey-basis reading. Section 13
* places it on one instrument and one price basis, which gives the index
* reported in the technical note. Both are kept, because the gap between them
* measures how much of any movement belongs to the instrument rather than to
* the country.
*   education  HIES 2024-25, as measured in Section 11
*   health     MICS6 provincial life expectancy (Section 8.4) with NHDR's own
*              urban and rural offsets, +2.5 and -0.7 years, recovered from
*              the 2018-19 table
*   income     the HIES 2024-25 distribution scaled to the World Bank GNI per
*              head in current PPP dollars for 2024, the control that
*              reproduces the 2018-19 column (Section 10, test 3)

* ---- 12.1 Income, by domain -------------------------------------------------------
use `hh24', clear
quietly summarize pc_exp [aw=pop_w]
scalar nat_pc24 = r(mean)                 // survey consumption per head, rupees a year
scalar scale24  = gnic2024 / nat_pc24     // PPP dollars per survey rupee
display as text _n "Step 9: control " %6.0f gnic2024 " PPP dollars, survey per head Rs " ///
    %9.0fc nat_pc24 ", scale " %8.5f scale24
keep province region pc_exp pop_w
nhdr_stack_domains, province(province) region(region)
gen double _x = pc_exp * pop_w
collapse (sum) _x pop_w, by(domain)
gen double pc_exp_rs = _x / pop_w
gen double pci_ppp_survey = pc_exp_rs * scale24
drop _x
tempfile inc24
save `inc24'

* ---- 12.2 Health, by domain ------------------------------------------------------
* Pakistan is the population-weighted mean of the four provincial values.
use `inc24', clear
keep domain pop_w
keep if inlist(domain, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
rename domain province
merge 1:1 province using `provmort', keepusing(le_west le_west_from_pdhs) keep(match) nogenerate
foreach v in le_west le_west_from_pdhs {
    gen double _x = `v' * pop_w
    quietly summarize _x
    local num = r(sum)
    quietly summarize pop_w
    scalar nat_`v' = `num' / r(sum)
    drop _x
}
use `ind24', clear
merge 1:1 domain using `inc24', keepusing(pc_exp_rs pci_ppp_survey pop_w) nogenerate
gen str20 base = domain
replace base = substr(domain, 1, strpos(domain, "-") - 1) if strpos(domain, "-") > 0
gen str20 province = base
merge m:1 province using `provmort', keepusing(le_west le_west_from_pdhs) keep(master match) nogenerate
replace le_west           = nat_le_west           if base == "Pakistan"
replace le_west_from_pdhs = nat_le_west_from_pdhs if base == "Pakistan"
gen double off = 0
replace off =  2.5 if strpos(domain, "-Urban") > 0
replace off = -0.7 if strpos(domain, "-Rural") > 0
gen double life_mics = le_west + off
gen double life_pdhs = le_west_from_pdhs + off
drop base province le_west le_west_from_pdhs off

* ---- 12.3 The survey-basis index, and the same index on PDHS mortality. Essential the most important dimension is kept constant...

nhdr_index, literacy(lit_15plus) enrolment(ner_5_14) life(life_mics) income(pci_ppp_survey) prefix(sb_)
nhdr_index, literacy(lit_15plus) enrolment(ner_5_14) life(life_pdhs) income(pci_ppp_survey) prefix(pd_)
gen double hdi_source_spread = sb_hdi - pd_hdi
merge 1:1 domain using `t1', keepusing(hdi_2018_19 edu_idx_2018_19 health_idx_2018_19 ///
    income_idx_2018_19 hdi_2006_07) keep(master match) nogenerate
display as text _n "Step 9: the 2024-25 index, survey basis, and on PDHS mortality"
list domain lit_15plus ner_5_14 life_mics pci_ppp_survey sb_hdi pd_hdi hdi_2018_19, ///
    noobs sep(0) abbreviate(14)
quietly summarize sb_hdi if domain == "Pakistan"
nhdr_check, label("Step 9 Pakistan 2024-25, survey basis [reference 0.6057]") ///
    got(`=r(mean)') want(0.6057) tol(0.0005)
quietly summarize hdi_source_spread if domain == "Sindh"
nhdr_check, label("Step 9 Sindh, MICS6 against PDHS mortality, HDI spread [reference 0.030]") ///
    got(`=r(mean)') want(0.0303) tol(0.001)
tempfile sb24
save `sb24'
export delimited using "$out/Provincial index 2024-25 survey basis.csv"


*==============================================================================*
* SECTION 13   HUMAN DEVELOPMENT INDEX (HDI) 2024-25 ON ONE INSTRUMENT AND ONE PRICE BASIS, AND THE DECOMPOSITION OF THE CHANGE. Wont fly.
*==============================================================================*
* A composite index measures change only when every dimension is measured the
* same way at both ends of the comparison. Two conditions have to hold.
*   One instrument   a dimension moves on the same survey and definition in
*                    both years, or, where no new measurement exists, on a
*                    published national series rather than on a survey of a
*                    different vintage
*   One price basis  money values are in the prices of one base year and
*                    converted at one PPP benchmark
* Education meets both as measured. Health does not: Pakistan has fielded no
* provincial birth history since 2019-20, and every MICS6 round measures the
* 2018-19 vintage. Income does not either: current-dollar controls for 2018
* and 2024 rest on different ICP benchmark rounds and carry six years of
* world inflation between them. So:
*   health  LE_D,2024 = LE_D,2018 + (WB_LE_2024 - WB_LE_2018)
*           LE_D,2018 is the value NHDR printed in Table 2A, which Section 7
*           shows is the value it used, to within the rounding band. The
*           provincial pattern and NHDR's urban and rural offsets are held.
*   income  control_2024 = PCI_Pak,2018 x (rGNI_2024 / rGNI_2018)
*           rGNI is GNI per head in constant 2021 PPP dollars. The domain
*           distribution comes from HIES 2024-25:
*           PCI_D,2024 = control_2024 x (survey_pc_D / survey_pc_Pak)
*   education  as measured, HIES 2024-25
* The change is then decomposed with an exact identity. A geometric mean
* decomposes additively in logs:
*   ln HDI_1 - ln HDI_0 = (1/3)[ln E_1 - ln E_0] + (1/3)[ln H_1 - ln H_0]
*                        + (1/3)[ln I_1 - ln I_0]
* Result    Pakistan 0.588 against a published 0.570 for 2018-19, a pace of
*           3.1 index points per thousand a year against 3.4 over 2006-07 to
*           2018-19

* ---- 13.1 The two national carries ----------------------------------------------
scalar d_le  = le2024 - le2018            // life expectancy increment, years
scalar g_inc = gnik2024 / gnik2018        // real growth in GNI per head
scalar control24 = pci_pak_1819 * g_inc   // income control, 2018-19 price basis
display as text _n "Step 10: national carries"
display as text "  life expectancy, World Bank, 2018 " %6.3f le2018 ", 2024 " %6.3f le2024 ///
    ", increment " %6.3f d_le " years"
display as text "  real GNI per head, 2018 " %9.2f gnik2018 ", 2024 " %9.2f gnik2024 ///
    ", growth " %6.2f 100 * (g_inc - 1) " percent"
display as text "  income control 2024-25 = " %6.0f pci_pak_1819 " x " %7.5f g_inc " = " %7.1f control24
nhdr_check, label("Step 10 life expectancy increment, years [reference 1.318]") ///
    got(`=d_le') want(1.318) tol(0.0005)
nhdr_check, label("Step 10 income control 2024-25, PPP dollars [reference 5,407]") ///
    got(`=control24') want(5406.54) tol(0.5)

* ---- 13.2 The index ----------------------------------------------------------------------
use `sb24', clear
merge 1:1 domain using `t2a_all', keepusing(le_2018_19) keep(master match) nogenerate
gen double life_years = le_2018_19 + d_le
quietly summarize pc_exp_rs if domain == "Pakistan"
gen double pci_ppp = control24 * (pc_exp_rs / r(mean))
nhdr_index, literacy(lit_15plus) enrolment(ner_5_14) life(life_years) income(pci_ppp)
gen double change_since_2018_19 = hdi - hdi_2018_19
display as text _n "Step 10: THE 2024-25 INDEX"
list domain lit_15plus ner_5_14 life_years pci_ppp education_index health_index ///
    income_index hdi hdi_2018_19 change_since_2018_19, noobs sep(0) abbreviate(12)
foreach pr in "Pakistan 0.5885" "Punjab 0.5934" "Sindh 0.5787" "Khyber_Pakhtunkhwa 0.5773" ///
    "Balochistan 0.5105" "Sindh-Rural 0.4857" "Sindh-Urban 0.6464" ///
    "Pakistan-Urban 0.6488" "Pakistan-Rural 0.5507" {
    local nm : word 1 of `pr'
    local v  : word 2 of `pr'
    local nm = subinstr("`nm'", "_", " ", .)
    quietly summarize hdi if domain == "`nm'"
    nhdr_check, label("Step 10 HDI 2024-25, `nm' [reference]") got(`=r(mean)') want(`v') tol(0.0005)
}
tempfile fin24
save `fin24'
preserve
keep domain lit_15plus ner_5_14 life_years pci_ppp education_index health_index ///
    income_index hdi classification hdi_2006_07 hdi_2018_19 change_since_2018_19
export delimited using "$out/Provincial index 2024-25 final.csv"
save "$out/Provincial index 2024-25 final.dta"
restore

* ---- 13.3 Decomposition of the change, final and survey basis ----------------------------
foreach b in final survey {
    if "`b'" == "final"  local p ""
    if "`b'" == "survey" local p "sb_"
    gen double `b'_education_pct = 100 * (ln(`p'education_index) - ln(edu_idx_2018_19)) / 3
    gen double `b'_health_pct    = 100 * (ln(`p'health_index)    - ln(health_idx_2018_19)) / 3
    gen double `b'_income_pct    = 100 * (ln(`p'income_index)    - ln(income_idx_2018_19)) / 3
    gen double `b'_total_pct     = `b'_education_pct + `b'_health_pct + `b'_income_pct
}
display as text _n "Step 10: contribution to the change in the composite, percent, final basis"
list domain final_education_pct final_health_pct final_income_pct final_total_pct ///
    if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan"), ///
    noobs sep(0) abbreviate(20)
display as text _n "Same decomposition with every input as the surveys report it"
list domain survey_education_pct survey_health_pct survey_income_pct survey_total_pct ///
    if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan"), ///
    noobs sep(0) abbreviate(20)
foreach pr in "Pakistan 1.431 1.012 0.797" "Sindh 0.347 1.009 -0.602" "Balochistan 5.187 1.042 1.383" {
    local nm : word 1 of `pr'
    local e  : word 2 of `pr'
    local h  : word 3 of `pr'
    local i  : word 4 of `pr'
    quietly summarize final_education_pct if domain == "`nm'"
    nhdr_check, label("Step 10 `nm' education contribution, percent [reference]") got(`=r(mean)') want(`e') tol(0.005)
    quietly summarize final_health_pct if domain == "`nm'"
    nhdr_check, label("Step 10 `nm' health contribution, percent [reference]") got(`=r(mean)') want(`h') tol(0.005)
    quietly summarize final_income_pct if domain == "`nm'"
    nhdr_check, label("Step 10 `nm' income contribution, percent [reference]") got(`=r(mean)') want(`i') tol(0.005)
}
preserve
keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
keep domain final_*_pct
export delimited using "$out/Decomposition final.csv"
restore
preserve
keep domain hdi_2018_19 sb_hdi survey_*_pct
export delimited using "$out/Decomposition survey basis.csv"
restore

* ---- 13.4 Pace, and the sensitivity to the instrument ---------------------------------
* Index points per thousand a year. The instrument effect is the part of the
* survey-basis change that disappears once each dimension is on one
* instrument and one price basis.
gen double pace_2006_2018 = 1000 * (hdi_2018_19 - hdi_2006_07) / 12
gen double pace_2018_2024 = 1000 * (hdi - hdi_2018_19) / 6
gen double pace_2018_2024_survey = 1000 * (sb_hdi - hdi_2018_19) / 6
gen double instrument_effect = (sb_hdi - hdi_2018_19) - (hdi - hdi_2018_19)
display as text _n "Step 10: pace of improvement, index points per thousand a year"
list domain pace_2006_2018 pace_2018_2024 pace_2018_2024_survey instrument_effect, ///
    noobs sep(0) abbreviate(22)
quietly summarize pace_2018_2024 if domain == "Pakistan"
nhdr_check, label("Step 10 Pakistan pace 2018-19 to 2024-25 [reference 3.08]") ///
    got(`=r(mean)') want(3.0833) tol(0.05)
keep domain hdi_2006_07 hdi_2018_19 sb_hdi hdi pace_2006_2018 pace_2018_2024 ///
    pace_2018_2024_survey instrument_effect
rename (sb_hdi hdi) (hdi_2024_25_survey_basis hdi_2024_25_final)
export delimited using "$out/Chain consistency sensitivity.csv"

*==============================================================================*
* SECTION 14   DISTRICT EDUCATION FROM PSLM 2019-20, WITH
*              STANDARD ERRORS
*==============================================================================*
* PSLM 2019-20 is the most recent district round: 870,171 persons in 126
* districts and 5,673 primary sampling units, designed to support district
* inference on the social indicators. It carries no consumption module,
* which is why district income is modeled in Section 15 rather than measured.
* Source    PBS, PSLM 2019-20 microdata
*             plist.dta   hhcode, psu, province, region, district, idc, age,
*                         weights
*             secc1.dta   sc1q1a can read (1 yes), sc1q2a can write (1 yes),
*                         sc1q01 status (3 currently attending), sc1q14 class
* Indicators the Section 3 and 4 definitions: literacy 15 and over (reads
*           and writes), level-matched net enrolment 5 to 14
* Standard  linearized, one-stage cluster design with the PSU as the cluster,
* errors    for a weighted proportion p in a district with m clusters:
*               var(p) = m/(m-1) x sum_c (z_c - p x w_c)^2 / (sum_c w_c)^2
*           z_c = weighted sum of the indicator in cluster c, w_c = weighted
*           count. Reporting it is not decoration: a district estimate on
*           eight clusters carries an interval several points wide, and a
*           ranking of 126 districts on point estimates alone invents
*           differences the survey cannot see.

* ---- 14.1 Person file -----------------------------------------------------------

use hhcode psu province region district idc age weights using "$p19/plist.dta", clear
merge 1:1 hhcode idc using "$p19/secc1.dta", keepusing(sc1q1a sc1q2a sc1q01 sc1q14) ///
    keep(master match) nogenerate
decode district, generate(_dlab)
gen str40 district_name = proper(_dlab)
drop _dlab
gen str20 province_name = ""
replace province_name = "Khyber Pakhtunkhwa" if province == 1
replace province_name = "Punjab"             if province == 2
replace province_name = "Sindh"              if province == 3
replace province_name = "Balochistan"        if province == 4
gen double lit15  = (sc1q1a == 1 & sc1q2a == 1) if age >= 15 & !missing(age) & !missing(sc1q1a)
gen double lit10  = (sc1q1a == 1 & sc1q2a == 1) if age >= 10 & !missing(age) & !missing(sc1q1a)
gen double lit10r = (sc1q1a == 1)               if age >= 10 & !missing(age) & !missing(sc1q1a)
gen double cls = sc1q14 if sc1q01 == 3
replace cls = . if inlist(cls, 25, 26, 27, 28) | cls > 10
gen double ner = ((inrange(age, 5, 9)   & inrange(cls, 1, 5))  | ///
                  (inrange(age, 10, 12) & inrange(cls, 6, 8))  | ///
                  (inrange(age, 13, 14) & inrange(cls, 9, 10))) if inrange(age, 5, 14)
tempfile p19p
save `p19p'

* ---- 14.2 Provincial check against PBS ---------------------------------------------
* PBS published provincial literacy for this district round in the PSLM 2019-20
* District Level Report, Tables 2.14(a) (ages 10 and over) and 2.14(b) (ages 15
* and over), printed as whole percentages. Its Khyber Pakhtunkhwa figure
* includes the seven merged districts, as the microdata do. A reproduce within
* 0.5 of a whole-percent figure matches it.
display as text _n "Step 11: PSLM 2019-20 literacy against PBS, PSLM 2019-20 District Level Report"
display as text "  " %-20s "domain" "   10+ reproduced   PBS    15+ reproduced   PBS"
foreach pr in "Pakistan PAK" "Punjab PUN" "Sindh SIN" "Khyber_Pakhtunkhwa KP" "Balochistan BAL" {
    local nm : word 1 of `pr'
    local id : word 2 of `pr'
    local nm = subinstr("`nm'", "_", " ", .)
    if "`nm'" == "Pakistan" quietly summarize lit10 [aw=weights]
    else quietly summarize lit10 [aw=weights] if province_name == "`nm'"
    local l10 = 100 * r(mean)
    if "`nm'" == "Pakistan" quietly summarize lit15 [aw=weights]
    else quietly summarize lit15 [aw=weights] if province_name == "`nm'"
    local l15 = 100 * r(mean)
    display as text "  " %-20s "`nm'" as result %12.2f `l10' %7.0f bm_lit10_pslm1920_`id' ///
        %14.2f `l15' %7.0f bm_lit15_pslm1920_`id'
    nhdr_check, label("Step 11 PSLM 2019-20 literacy 10+, `nm' [PBS 2019-20]") ///
        got(`l10') want(`=bm_lit10_pslm1920_`id'') tol(0.5)
    nhdr_check, label("Step 11 PSLM 2019-20 literacy 15+, `nm' [PBS 2019-20]") ///
        got(`l15') want(`=bm_lit15_pslm1920_`id'') tol(0.5)
}
* For reference, Khyber Pakhtunkhwa without the merged districts (PSLM district
* codes 102, 112, 115, 121, 122, 124, 127), the definition PBS used before the
* merger.
quietly summarize lit10 [aw=weights] if province == 1 & !inlist(district, 102, 112, 115, 121, 122, 124, 127)
display as text "  Khyber Pakhtunkhwa without the merged districts, 10+ " as result %6.2f 100 * r(mean)
quietly summarize ner [aw=weights]
display as text "  net enrolment 5-14, level matched, Pakistan " as result %6.2f 100 * r(mean)

* ---- 14.3 District estimates ----------------------------------------------------------
collapse (mean) lit15 ner [aw=weights], by(province province_name district district_name)
replace lit15 = 100 * lit15
replace ner   = 100 * ner
rename (lit15 ner) (literacy_15plus ner_5_14)
tempfile d_edu
save `d_edu'

* ---- 14.4 Design-based standard errors -------------------------------------------------
foreach v in lit15 ner {
    use `p19p', clear
    keep if !missing(`v')
    gen double _z = `v' * weights
    * Cluster totals: z_c and w_c.
    collapse (sum) _z _w=weights, by(province district psu)
    bysort province district: gen int clusters = _N
    by province district: egen double _W = total(_w)
    by province district: egen double _Z = total(_z)
    gen double _dev2 = (_z - (_Z / _W) * _w)^2
    collapse (sum) _dev2 (first) clusters _W, by(province district)
    gen double `v'_se_pp = 100 * sqrt((clusters / (clusters - 1)) * _dev2 / _W^2) ///
        if clusters >= 2 & _W > 0
    rename clusters `v'_clusters
    keep province district `v'_se_pp `v'_clusters
    tempfile se_`v'
    save `se_`v''
}
use `d_edu', clear
merge 1:1 province district using `se_lit15', nogenerate
merge 1:1 province district using `se_ner', nogenerate
rename (lit15_se_pp lit15_clusters) (literacy_se_pp clusters)
drop ner_clusters
save `d_edu', replace
quietly count
nhdr_check, label("Step 11 districts estimated [reference 126]") got(`=r(N)') want(126) tol(0)
quietly summarize clusters, detail
display as text "  median clusters per district " as result %4.0f r(p50)
quietly count if clusters < 12
display as text "  districts with fewer than 12 PSUs, indicative only " as result r(N)
quietly summarize literacy_se_pp, detail
display as text "  median literacy standard error " as result %5.2f r(p50) ///
    as text " points, 90th percentile " as result %5.2f r(p90)
nhdr_check, label("Step 11 median district literacy standard error, points [reference 2.92]") ///
    got(`=r(p50)') want(2.9195) tol(0.01)
gsort -literacy_15plus
display as text _n "Step 11: ten most literate and ten least literate districts"
list province_name district_name literacy_15plus literacy_se_pp ner_5_14 clusters in 1/10, noobs sep(0)
list province_name district_name literacy_15plus literacy_se_pp ner_5_14 clusters in -10/l, noobs sep(0)
export delimited using "$out/District education 2019-20.csv"


*==============================================================================*
* SECTION 15   DISTRICT AND DIVISIONAL HUMAN DEVELOPMENT INDEX (HDI)
*==============================================================================*
* The recovered construction applied at district level.
*   education  PSLM 2019-20, Section 14
*   income     PSLM 2019-20 household income, per head, anchored to the NHDR
*              2018-19 provincial per capita income in PPP dollars, so that
*              the survey supplies only each district's position within its
*              province and the level adds no new assumption:
*                  PCI_d = inc_d x PCI_province(NHDR 2018-19) / inc_province
*   health     MICS6 life expectancy, with an explicit fallback ladder:
*                  district estimate, if it passes the plausibility screen
*                  else the division estimate, if under-five mortality is at
*                  least 20 per thousand
*                  else the province estimate
*              Every district carries a flag saying which rung it used.
* Divisions    population-weighted means of the district indicators, then the
*              index, never an average of district index values
* Result       126 districts from Karachi East (0.717) to Dera Bugti (0.358),
*              28 divisions

* ---- 15.1 District income per head ----------------------------------------------------
* PSLM 2019-20 section E, income of each earner. The nine income items are
* summed. Where they sum to zero, months worked (seaq08) times monthly
* earnings (seaq09) are used instead.
use hhcode idc seaq08 seaq09 seaq10 seaq15 seaq17 seaq19 seaq21 seaq23 seaq24 seaq25 seaq26 ///
    using "$p19/sece.dta", clear
egen double inc_items = rowtotal(seaq10 seaq15 seaq17 seaq19 seaq21 seaq23 seaq24 seaq25 seaq26)
gen double monthly = cond(missing(seaq08), 0, seaq08) * cond(missing(seaq09), 0, seaq09)
gen double pinc = cond(inc_items > 0, inc_items, monthly)
collapse (sum) hh_income=pinc, by(hhcode)
tempfile hhinc
save `hhinc'
use hhcode province region district psu weights using `p19p', clear
bysort hhcode: gen int hhsize = _N
by hhcode: keep if _n == 1
merge 1:1 hhcode using `hhinc', keep(master match) nogenerate
drop if missing(hhsize) | hhsize <= 0 | missing(weights)
gen double pc_income = hh_income / hhsize
gen double pop_w = weights * hhsize
gen double _x = pc_income * pop_w
collapse (sum) _x pop_w, by(province district)
gen double pc_income_rs = _x / pop_w
drop _x
merge 1:1 province district using `d_edu', nogenerate

* Anchor each province's districts to the NHDR 2018-19 provincial level.
gen str30 domain = province_name
merge m:1 domain using `t2a_all', keepusing(pci_2018_19) keep(master match) nogenerate
drop domain
bysort province: egen double _num = total(pc_income_rs * pop_w)
by province: egen double _den = total(pop_w)
gen double pci_ppp = pc_income_rs * pci_2018_19 / (_num / _den)
drop _num _den pci_2018_19

* ---- 15.2 Health, with the fallback ladder -----------------------------------------
nhdr_district_key district_name, generate(key)
* Rung 1, the district's own MICS6 estimate where it passes the screen.
preserve
use `distmort', clear
keep key le_west implausible
rename le_west le_district
tempfile dm
save `dm'
restore
merge m:1 key using `dm', keep(master match) generate(_mics)
gen byte in_mics6 = (_mics == 3)
drop _mics
replace le_district = . if implausible == 1
drop implausible
* The division MICS6 assigns the district to.
preserve
use `d2v', clear
keep key division_name
tempfile d2vk
save `d2vk'
restore
merge m:1 key using `d2vk', keep(master match) nogenerate
* Rung 2, the division estimate, where under-five mortality is at least 20.
preserve
use `divmort', clear
keep if u5mr_per_1000 >= 20
keep province division_name le_west
rename (province le_west) (province_name le_division)
tempfile dvok
save `dvok'
restore
merge m:1 province_name division_name using `dvok', keep(master match) nogenerate
* Rung 3, the province estimate.
preserve
use `provmort', clear
keep province le_west
rename (province le_west) (province_name le_province)
tempfile prle
save `prle'
restore
merge m:1 province_name using `prle', keep(master match) nogenerate

gen double life_years = le_district
gen str8 life_source = "district" if !missing(le_district)
replace life_source = "division" if missing(life_years) & !missing(le_division)
replace life_years  = le_division if missing(life_years) & !missing(le_division)
replace life_source = "province" if missing(life_years)
replace life_years  = le_province if missing(life_years)

quietly count if in_mics6
display as text _n "Step 12: PSLM districts matched to a MICS6 district: " as result r(N) as text " of 126"
display as text "Districts not matched by name (health falls back to the province):"
list province_name district_name if !in_mics6, noobs sep(0)
display as text "Life expectancy source used:"
tab life_source
foreach pr in "district 104" "division 16" "province 6" {
    local s : word 1 of `pr'
    local n : word 2 of `pr'
    quietly count if life_source == "`s'"
    nhdr_check, label("Step 12 districts whose health input is the `s' estimate [reference]") ///
        got(`=r(N)') want(`n') tol(0)
}

* ---- 15.3 The district index ------------------------------------------------------------
nhdr_index, literacy(literacy_15plus) enrolment(ner_5_14) life(life_years) income(pci_ppp)
gsort -hdi
gen int rank = _n
order rank province_name division_name district_name literacy_15plus literacy_se_pp ner_5_14 ///
    life_years life_source pci_ppp education_index health_index income_index hdi classification ///
    clusters pop_w
display as text _n "Step 12: DISTRICT HUMAN DEVELOPMENT INDEX, top 15 and bottom 15"
list rank province_name district_name literacy_15plus ner_5_14 life_years life_source pci_ppp hdi in 1/15, ///
    noobs sep(0) abbreviate(12)
list rank province_name district_name literacy_15plus ner_5_14 life_years life_source pci_ppp hdi in -15/l, ///
    noobs sep(0) abbreviate(12)
tab classification
quietly summarize hdi
display as text "range " as result %5.3f r(min) as text " to " as result %5.3f r(max) ///
    as text ", spread " as result %5.3f r(max) - r(min)
nhdr_check, label("Step 12 spread, highest to lowest district [reference 0.359]") ///
    got(`=r(max) - r(min)') want(0.3589) tol(0.001)
quietly summarize hdi if district_name == "Karachi East"
nhdr_check, label("Step 12 Karachi East, rank 1 [reference 0.7168]") got(`=r(mean)') want(0.7168) tol(0.0005)
quietly summarize hdi if district_name == "Dera Bugti"
nhdr_check, label("Step 12 Dera Bugti, rank 126 [reference 0.3579]") got(`=r(mean)') want(0.3579) tol(0.0005)
quietly summarize hdi if district_name == "Lahore"
nhdr_check, label("Step 12 Lahore [reference 0.6656]") got(`=r(mean)') want(0.6656) tol(0.0005)
foreach pr in "Low 65" "Medium 58" "High 3" {
    local c : word 1 of `pr'
    local n : word 2 of `pr'
    quietly count if classification == "`c' human development"
    nhdr_check, label("Step 12 districts in the `c' band [reference]") got(`=r(N)') want(`n') tol(0)
}
tempfile dindex
save `dindex'
drop key le_district le_division le_province in_mics6 pc_income_rs
export delimited using "$out/District index.csv"
save "$out/District index.dta"

* ---- 15.4 The divisional roll-up -------------------------------------------------------
use `dindex', clear
drop if division_name == ""
* Each indicator gets its own denominator, so a district with a missing value
* would drop out of that indicator's mean rather than pull it toward zero.
foreach v in literacy_15plus ner_5_14 life_years pci_ppp {
    gen double _x_`v' = `v' * pop_w
    gen double _w_`v' = cond(missing(`v'), ., pop_w)
}
collapse (sum) _x_literacy_15plus _x_ner_5_14 _x_life_years _x_pci_ppp ///
    _w_literacy_15plus _w_ner_5_14 _w_life_years _w_pci_ppp pop_w ///
    (count) districts=pop_w, by(province_name division_name)
foreach v in literacy_15plus ner_5_14 life_years pci_ppp {
    gen double `v' = _x_`v' / _w_`v'
    drop _x_`v' _w_`v'
}
nhdr_index, literacy(literacy_15plus) enrolment(ner_5_14) life(life_years) income(pci_ppp)
gsort -hdi
display as text _n "Step 12: DIVISIONAL HUMAN DEVELOPMENT INDEX"
list province_name division_name literacy_15plus ner_5_14 life_years pci_ppp hdi districts, ///
    noobs sep(0) abbreviate(14)
quietly count
nhdr_check, label("Step 12 divisions [reference 28]") got(`=r(N)') want(28) tol(0)
quietly summarize hdi if division_name == "Karachi"
nhdr_check, label("Step 12 Karachi division [reference 0.6861]") got(`=r(mean)') want(0.6861) tol(0.0005)
quietly summarize hdi if division_name == "Sibi"
nhdr_check, label("Step 12 Sibi division [reference 0.4514]") got(`=r(mean)') want(0.4514) tol(0.0005)
export delimited using "$out/Divisional index.csv"
save "$out/Divisional index.dta"


*==============================================================================*
* SECTION 16   INEQUALITY-ADJUSTED HUMAN DEVELOPMENT INDEX (IHDI), TABLE 3
*==============================================================================*
* NHDR 2020 says only that its IHDI follows UNDP's global method and that it
* is "computed using the database of the HDI at the quantile levels". The
* global IHDI measures inequality across individuals. NHDR measures it across
* the five consumption quintiles of Table 2A, which is why its losses (6 to 8
* percent) sit far below UNDP's 31 percent for Pakistan. The construction is
* recovered here by reproducing Table 3 from Table 2A alone.
*   Inequality in each dimension is the Atkinson index with aversion 1 over
*   the five quintile values:
*       A_x = 1 - GM(x_1..x_5) / AM(x_1..x_5)
*   where GM is the geometric and AM the arithmetic mean, taken over
*       education  the quintile education index, (2/3)L/100 + (1/3)N/100
*       health     the quintile life expectancy, in years
*       income     the quintile per capita income, in PPP dollars
*   Equal weights are exact because each quintile holds a fifth of the
*   population.
*       IHDI = HDI x [(1 - A_edu)(1 - A_health)(1 - A_income)]^(1/3)
*       coefficient of human inequality = 100 x (A_edu + A_health + A_income)/3
*       overall loss = 100 x (1 - IHDI / HDI)
*   HDI is the domain value from the All row of Table 2A (Section 5).
* Target    Table 3: 5 domains x 2 years, and the income, education and
*           health shares in Figure 2.19
* Result    every IHDI within 0.0015 of the printed value. The residual is the
*           rounding of the one-decimal quintile inputs.

* ---- 16.1 The method, recovered from the published quintile database ----------
import delimited using "$pub/NHDR2020 Table 3.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1)
rename region domain
tempfile t3
save `t3'

use `t2a', clear
keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
* Domain HDI from the All rows.
preserve
keep if quintile == "All"
foreach y in 2006_07 2018_19 {
    nhdr_index, literacy(lit_`y') enrolment(ner_`y') life(le_`y') income(pci_`y') prefix(d`y'_)
}
keep domain d2006_07_hdi d2018_19_hdi
rename (d2006_07_hdi d2018_19_hdi) (hdi_2006_07 hdi_2018_19)
tempfile hdi5
save `hdi5'
restore
* Quintile HDI, kept for the modified Palma ratio below.
drop if quintile == "All"
foreach y in 2006_07 2018_19 {
    gen double edu_`y' = (2/3) * (lit_`y' / 100) + (1/3) * (ner_`y' / 100)
    nhdr_index, literacy(lit_`y') enrolment(ner_`y') life(le_`y') income(pci_`y') prefix(q`y'_)
}
tempfile q5pub
save `q5pub'
nhdr_atkinson edu_2006_07 edu_2018_19 le_2006_07 le_2018_19 pci_2006_07 pci_2018_19, ///
    by(domain) prefix(a_)
collapse (first) a_*, by(domain)
merge 1:1 domain using `hdi5', nogenerate
foreach y in 2006_07 2018_19 {
    gen double ihdi_`y' = hdi_`y' * ((1 - a_edu_`y') * (1 - a_le_`y') * (1 - a_pci_`y'))^(1/3)
    gen double chi_`y'  = 100 * (a_edu_`y' + a_le_`y' + a_pci_`y') / 3
    gen double loss_`y' = 100 * (1 - ihdi_`y' / hdi_`y')
}
merge 1:1 domain using `t3', nogenerate
display as text _n "Step 13: IHDI reproduced from the Table 2A quintile database, against Table 3"
list domain hdi_2018_19 ihdi_2018_19 pub_ihdi_2018_19 loss_2018_19 pub_loss_2018_19 ///
    a_edu_2018_19 pub_aedu_2018_19 a_le_2018_19 pub_ahealth_2018_19 a_pci_2018_19 pub_ainc_2018_19, ///
    noobs sep(0) abbreviate(12)
list domain hdi_2006_07 ihdi_2006_07 pub_ihdi_2006_07 loss_2006_07 pub_loss_2006_07, ///
    noobs sep(0) abbreviate(12)
* Worst gap over the 10 domain-years for each published quantity. Tolerances
* follow the printed precision plus the rounding of the quintile inputs.
foreach spec in "ihdi ihdi 0.0015" "loss loss 0.15" "chi chi 0.15" "a_edu aedu 0.005" ///
    "a_le ahealth 0.0001" "a_pci ainc 0.002" {
    local mine : word 1 of `spec'
    local pub  : word 2 of `spec'
    local tol  : word 3 of `spec'
    gen double _g = max(abs(`mine'_2006_07 - pub_`pub'_2006_07), abs(`mine'_2018_19 - pub_`pub'_2018_19))
    quietly summarize _g
    nhdr_check, label("Step 13 IHDI method, worst |gap| in `pub', 10 domain-years [published]") ///
        got(`=r(max)') want(0) tol(`tol')
    drop _g
}
quietly summarize ihdi_2018_19 if domain == "Pakistan"
nhdr_check, label("Step 13 IHDI Pakistan 2018-19 [published 0.534]") got(`=r(mean)') want(0.534) tol(0.0006)
quietly summarize loss_2018_19 if domain == "Pakistan"
nhdr_check, label("Step 13 loss due to inequality, Pakistan 2018-19, percent [published 6.26]") ///
    got(`=r(mean)') want(6.26) tol(0.05)
* Figure 2.19: each dimension's share of the summed inequality, Pakistan 2018-19.
gen double share_inc_2018_19    = 100 * a_pci_2018_19 / (a_edu_2018_19 + a_le_2018_19 + a_pci_2018_19)
gen double share_edu_2018_19    = 100 * a_edu_2018_19 / (a_edu_2018_19 + a_le_2018_19 + a_pci_2018_19)
gen double share_health_2018_19 = 100 * a_le_2018_19  / (a_edu_2018_19 + a_le_2018_19 + a_pci_2018_19)
foreach s in "inc income" "edu edu" "health health" {
    local v : word 1 of `s'
    local b : word 2 of `s'
    quietly summarize share_`v'_2018_19 if domain == "Pakistan"
    nhdr_check, label("Step 13 Figure 2.19 `b' share of inequality, Pakistan 2018-19 [published]") ///
        got(`=r(mean)') want(`=bm_ihdi_contrib_`b'_1819') tol(1)
}
tempfile ihdi_pub
save `ihdi_pub'
export delimited using "$out/IHDI method Table 3.csv"

* The modified Palma ratio of Figure 2.20 is the HDI of the richest quintile
* over the HDI of the poorest, from the same database.
use `q5pub', clear
keep if domain == "Pakistan"
foreach y in 2006_07 2018_19 {
    quietly summarize q`y'_hdi if quintile == "Q5"
    local top = r(mean)
    quietly summarize q`y'_hdi if quintile == "Q1"
    scalar palma_`y' = `top' / r(mean)
}
display as text "  modified Palma ratio of quintile HDI, 2006-07 " as result %5.3f palma_2006_07 ///
    as text ", 2018-19 " as result %5.3f palma_2018_19
nhdr_check, label("Step 13 modified Palma ratio 2006-07 [published 1.73]") got(`=palma_2006_07') ///
    want(`=bm_palma_hdi_0607') tol(0.006)
nhdr_check, label("Step 13 modified Palma ratio 2018-19 [published 1.67]") got(`=palma_2018_19') ///
    want(`=bm_palma_hdi_1819') tol(0.006)

* ---- 16.2 The 2018-19 IHDI reproduced from the microdata ------------------------------
* Each dimension's quintile distribution is now measured rather than read:
*   education  the quintile literacy and enrolment reproduced in Section 4
*   income     HIES 2018-19 income per head in each consumption quintile,
*              which is how Table 2A was cut (Section 10, test 2). The IHDI
*              needs only the shape of the distribution, not its level.
*   health     MICS6 under-five mortality by household wealth quintile, ten
*              years, converted to life expectancy through the West family.
*              NHDR used PDHS 2017-18 by wealth quintile. That version is
*              built in 16.2b from the PDHS microdata read in Section 8A.
* The domain HDI is the Section 5 value, whose inputs are the published ones.

* Education by quintile.
use `edu1819', clear
keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
drop if quintile == "All"
gen byte q = real(substr(quintile, 2, 1))
gen double edu_raw = (2/3) * (lit_reproduced / 100) + (1/3) * (ner_reproduced / 100)
keep domain q edu_raw
tempfile qedu
save `qedu'
* Income and consumption by consumption quintile, persons weighted.
use `stacked', clear
keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
drop if missing(q)
collapse (mean) inc_raw=pc_inc cons_raw=pc_exp [aw=weights], by(domain q)
merge 1:1 domain q using `qedu', nogenerate
tempfile qinc
save `qinc'
* Health by wealth quintile, MICS6. Pakistan pools each province's own
* quintiles, because MICS6 builds a separate wealth index for every province.
use `bh', clear
drop if missing(windex5)
nhdr_q5, by(province windex5) window(10)
rename province domain
tempfile qmort
save `qmort'
use `bh', clear
drop if missing(windex5)
nhdr_q5, by(windex5) window(10)
gen str20 domain = "Pakistan"
append using `qmort'
nhdr_le_from_q5 u5mr_per_1000, generate(le_mics) family(west)
rename windex5 q
keep domain q u5mr_per_1000 le_mics
display as text _n "Step 13: MICS6 under-five mortality and life expectancy by wealth quintile, ten years"
list, noobs sep(5)
merge 1:1 domain q using `qinc', nogenerate
* NHDR's own quintile life expectancy, for the same-basis series in 16.3.
preserve
use `t2a', clear
drop if quintile == "All"
gen byte q = real(substr(quintile, 2, 1))
keep domain q le_2018_19
tempfile qle
save `qle'
restore
merge 1:1 domain q using `qle', keep(master match) nogenerate
nhdr_atkinson edu_raw inc_raw cons_raw le_mics le_2018_19, by(domain) prefix(a_)
collapse (first) a_*, by(domain)
merge 1:1 domain using `hdi5', keepusing(hdi_2018_19) nogenerate
merge 1:1 domain using `t3', keepusing(pub_ihdi_2018_19 pub_loss_2018_19 pub_aedu_2018_19 ///
    pub_ahealth_2018_19 pub_ainc_2018_19) nogenerate
gen double ihdi_raw = hdi_2018_19 * ((1 - a_edu_raw) * (1 - a_le_mics) * (1 - a_inc_raw))^(1/3)
gen double loss_raw = 100 * (1 - ihdi_raw / hdi_2018_19)
* Same basis as 2024-25 (16.3): consumption for income, NHDR's quintile life
* expectancy for health, reproduced education.
gen double ihdi_1819_samebasis = hdi_2018_19 * ((1 - a_edu_raw) * (1 - a_le_2018_19) * (1 - a_cons_raw))^(1/3)
display as text _n "Step 13: IHDI 2018-19 reproduced from the microdata, against Table 3"
list domain ihdi_raw pub_ihdi_2018_19 loss_raw pub_loss_2018_19 a_edu_raw pub_aedu_2018_19 ///
    a_le_mics pub_ahealth_2018_19 a_inc_raw a_cons_raw pub_ainc_2018_19, noobs sep(0) abbreviate(12)
gen double _g = abs(ihdi_raw - pub_ihdi_2018_19)
quietly summarize _g
nhdr_check, label("Step 13 IHDI 2018-19 from microdata, worst |gap| of 5 domains [published]") ///
    got(`=r(max)') want(0) tol(0.003)
drop _g
foreach spec in "a_edu_raw 0.04969" "a_inc_raw 0.13996" "a_cons_raw 0.14406" "a_le_mics 0.00080" "ihdi_raw 0.53246" {
    local v : word 1 of `spec'
    local r : word 2 of `spec'
    quietly summarize `v' if domain == "Pakistan"
    nhdr_check, label("Step 13 `v', Pakistan 2018-19 [reference `r']") got(`=r(mean)') want(`r') tol(0.001)
}
tempfile ihdi_raw
save `ihdi_raw'
export delimited using "$out/IHDI 2018-19 microdata.csv"

* ---- 16.2b The 2018-19 IHDI with the health gradient from PDHS 2017-18 -------
* Education and income as in 16.2. Health: life expectancy by wealth quintilefrom PDHS 2017-18 (Section 8A.4), the survey NHDR names. PDHS ranks
* households on its wealth index, while Table 2A ranks them on consumption,
* so the quintiles share a survey with NHDR but not a ranking variable.
use `pd_wq', clear
keep if round == "2017_18"
keep domain q le_pdhs
tempfile lepd18
save `lepd18'
nhdr_atkinson le_pdhs, by(domain) prefix(a_)
collapse (first) a_le_pdhs, by(domain)
merge 1:1 domain using `ihdi_raw', keepusing(a_edu_raw a_inc_raw a_le_mics hdi_2018_19 ihdi_raw ///
    pub_ihdi_2018_19 pub_ahealth_2018_19) nogenerate
gen double ihdi_pdhs = hdi_2018_19 * ((1 - a_edu_raw) * (1 - a_le_pdhs) * (1 - a_inc_raw))^(1/3)
gen double loss_pdhs = 100 * (1 - ihdi_pdhs / hdi_2018_19)
display as text _n "Step 13: IHDI 2018-19 from the microdata, health from PDHS 2017-18, against Table 3"
list domain a_le_pdhs a_le_mics pub_ahealth_2018_19 ihdi_pdhs ihdi_raw pub_ihdi_2018_19 loss_pdhs, ///
    noobs sep(0) abbreviate(14)
gen double _g = abs(ihdi_pdhs - pub_ihdi_2018_19)
quietly summarize _g
nhdr_check, label("Step 13 IHDI 2018-19, microdata with PDHS health, worst |gap| of 5 [published]") ///
    got(`=r(max)') want(0) tol(0.003)
drop _g
quietly count if !missing(ihdi_pdhs)
nhdr_check, label("Step 13 IHDI 2018-19 with PDHS health, domains [5]") got(`=r(N)') want(5) tol(0)
tempfile ihdi_pd
save `ihdi_pd'
export delimited using "$out/IHDI 2018-19 PDHS.csv"
* The PDHS quintile life expectancy beside the one NHDR printed.
use `lepd18', clear
merge 1:1 domain q using `qle', keep(master match) nogenerate
rename le_2018_19 le_nhdr_table2a
display as text _n "Step 13: quintile life expectancy, PDHS 2017-18 (West family) and NHDR Table 2A"
list domain q le_pdhs le_nhdr_table2a, noobs sepby(domain)

* ---- 16.3 The IHDI for 2024-25 ------------------------------------------------------
* The 2024-25 HDI is the Section 13 index. Its quintile distributions:
*   education  HIES 2024-25, quintiles cut on consumption per head within
*              each domain, the Section 4 rule
*   income     HIES 2024-25 consumption per head by consumption quintile.
*              The 2024-25 microdata in 6. Raw data carry no household income
*              aggregate of the kind sec_12ce.dta gives for 2018-19, so the
*              income distribution is proxied by consumption. On 2018-19 data
*              the two give Atkinson values of 0.140 (income) and 0.144
*              (consumption) for Pakistan against a published 0.138.
*   health     NHDR's 2018-19 quintile life expectancy carried forward by the
*              national increment, as in Section 13. No birth history has
*              been fielded since MICS6, so the health gradient is held.
* The 2018-19 comparator is ihdi_1819_samebasis from 16.2, built the same way.
use `p24', clear
keep if !missing(pc_exp) & !missing(weight)
nhdr_stack_domains, province(province) region(region)
keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
nhdr_quintile, welfare(pc_exp) wtvar(weight) by(domain) generate(q)
collapse (mean) lit15 ner cons=pc_exp [aw=weight], by(domain q)
gen double edu24 = (2/3) * lit15 + (1/3) * ner
merge 1:1 domain q using `qle', keep(master match) nogenerate
gen double le24 = le_2018_19 + d_le
nhdr_atkinson edu24 cons le24, by(domain) prefix(a_)
collapse (first) a_*, by(domain)
merge 1:1 domain using `fin24', keepusing(hdi) keep(master match) nogenerate
rename hdi hdi_2024_25
gen double ihdi_2024_25 = hdi_2024_25 * ((1 - a_edu24) * (1 - a_le24) * (1 - a_cons))^(1/3)
gen double loss_2024_25 = 100 * (1 - ihdi_2024_25 / hdi_2024_25)
merge 1:1 domain using `ihdi_raw', keepusing(ihdi_1819_samebasis hdi_2018_19 pub_ihdi_2018_19) nogenerate
gen double loss_1819_samebasis = 100 * (1 - ihdi_1819_samebasis / hdi_2018_19)
gen double ihdi_change = ihdi_2024_25 - ihdi_1819_samebasis
display as text _n "Step 13: THE IHDI FOR 2024-25, with 2018-19 on the same basis"
list domain hdi_2024_25 ihdi_2024_25 loss_2024_25 a_edu24 a_le24 a_cons ihdi_1819_samebasis ///
    loss_1819_samebasis ihdi_change, noobs sep(0) abbreviate(14)
quietly count
nhdr_check, label("Step 13 IHDI 2024-25 domains [5]") got(`=r(N)') want(5) tol(0)
quietly summarize ihdi_2024_25 if domain == "Pakistan"
nhdr_check, label("Step 13 IHDI Pakistan 2024-25 [reference 0.5492]") got(`=r(mean)') want(0.5492) tol(0.001)
export delimited using "$out/IHDI 2024-25.csv"


*==============================================================================*
* SECTION 17   GENDER DEVELOPMENT INDEX (GDI), TABLES 6 AND 6A
*==============================================================================*
* GDI = HDI_female / HDI_male, each sub-index built on the NHDR construction.
* Solving the goalposts out of Table 6 shows one departure from the HDI of
* Section 5: the GDI income index runs from 100 to 75,000 PPP dollars, the
* post-2010 UNDP band, while the HDI of Table 1 runs to 100,000. Life
* expectancy keeps the 25 to 90 band with no sex-specific goalposts.
*   female HDI_f = (E_f x H_f x I_f)^(1/3), male likewise
*   E = (2/3) L/100 + (1/3) N/100
*   H = (LE - 25) / 65
*   I = (ln PCI - ln 100) / (ln 75,000 - ln 100)
*   absolute deviation from parity = 100 x |GDI - 1|
* Sources, as NHDR names them
*   literacy and enrolment by sex  HIES microdata
*   life expectancy by sex         UNDP Human Development Report (68.1, 66.2)
*   income by sex                  "UNDP calculations based on National
*                                  Accounts, LFS and Population Census 2017"
* Target    Tables 6 and 6A, two sexes x two years

* ---- 17.1 The construction, recovered from Table 6A --------------------------------
import delimited using "$pub/NHDR2020 Table 6.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2)
nhdr_gdi_hdi, literacy(lit) enrolment(ner) life(le) income(pci)
* The same income index on the HDI's 100,000 goalpost, to show it fails.
gen double inc_idx_100k = (ln(pci) - ln(100)) / (ln(100000) - ln(100))
bysort year (sex): gen double gdi = gdi_hdi[1] / gdi_hdi[2]
gen double gdi_dev = 100 * abs(gdi - 1)
display as text _n "Step 14: GDI construction against Tables 6 and 6A"
list sex year gdi_edu pub_edu_idx gdi_hea pub_le_idx gdi_inc inc_idx_100k pub_inc_idx gdi_hdi pub_hdi gdi pub_gdi, ///
    noobs sep(0) abbreviate(10)
gen double _g = max(abs(gdi_edu - pub_edu_idx), abs(gdi_hea - pub_le_idx), abs(gdi_inc - pub_inc_idx), ///
    abs(gdi_hdi - pub_hdi), abs(gdi - pub_gdi))
quietly summarize _g
nhdr_check, label("Step 14 GDI construction, worst |gap| of 20 printed values [published]") ///
    got(`=r(max)') want(0) tol(0.0015)
gen double _h = abs(inc_idx_100k - pub_inc_idx)
quietly summarize _h
nhdr_check, label("Step 14 income goalpost 100,000 rejected: worst |gap| exceeds 0.01 [diagnostic]") ///
    got(`=(r(max) > 0.01)') want(1) tol(0)
drop _g _h
foreach spec in "2006_07 0.750 25.0" "2018_19 0.777 22.3" {
    local y : word 1 of `spec'
    local g : word 2 of `spec'
    local d : word 3 of `spec'
    quietly summarize gdi if year == "`y'"
    nhdr_check, label("Step 14 GDI `y' [published `g']") got(`=r(mean)') want(`g') tol(0.001)
    quietly summarize gdi_dev if year == "`y'"
    nhdr_check, label("Step 14 deviation from parity `y' [published `d']") got(`=r(mean)') want(`d') tol(0.1)
}
quietly summarize gdi_hdi if year == "2018_19"
nhdr_check, label("Step 14 mean of female and male HDI 2018-19 [published 0.564]") ///
    got(`=r(mean)') want(`=bm_gdi_avg_hdi_1819') tol(0.0006)
tempfile t6
save `t6'
export delimited using "$out/GDI method Table 6.csv"

* ---- 17.2 Literacy and enrolment by sex, HIES 2018-19 ------------------------------
use `h18p', clear
gen str6 sex = cond(s1aq04 == 2, "Female", cond(s1aq04 == 1, "Male", ""))
drop if sex == ""
tempfile h18sex
save `h18sex'
collapse (mean) lit15 ner [aw=weights], by(sex)
replace lit15 = 100 * lit15
replace ner   = 100 * ner
list, noobs sep(0)
foreach spec in "Female 45.8 36.0" "Male 69.6 37.9" {
    local s : word 1 of `spec'
    local l : word 2 of `spec'
    local n : word 3 of `spec'
    quietly summarize lit15 if sex == "`s'"
    nhdr_check, label("Step 14 literacy 15+, `s', HIES 2018-19 [published `l']") got(`=r(mean)') want(`l') tol(0.06)
    quietly summarize ner if sex == "`s'"
    nhdr_check, label("Step 14 net enrolment, `s', HIES 2018-19 [published `n']") got(`=r(mean)') want(`n') tol(0.06)
}
gen str20 domain = "Pakistan"
tempfile gedu18
save `gedu18'
* Provinces, for the provincial extension in 17.4.
use `h18sex', clear
gen str20 domain = ""
replace domain = "Khyber Pakhtunkhwa" if province == 1
replace domain = "Punjab"             if province == 2
replace domain = "Sindh"              if province == 3
replace domain = "Balochistan"        if province == 4
collapse (mean) lit15 ner [aw=weights], by(domain sex)
replace lit15 = 100 * lit15
replace ner   = 100 * ner
append using `gedu18'
save `gedu18', replace

* ---- 17.3 Earned income by sex, the UNDP method on LFS 2018-19 ----------------------
* UNDP (HDR 2019 Technical Note 3) splits income per head between the sexes
* with the female share of the wage bill:
*   S_f = (W_f/W_m x EA_f) / (W_f/W_m x EA_f + EA_m)
*   PCI_f = PCI x S_f / P_f        PCI_m = PCI x (1 - S_f) / P_m
* EA is each sex's share of the economically active population, W_f/W_m the
* ratio of mean female to mean male earnings of paid employees, and P each
* sex's share of the population (Census 2017, as NHDR states). PCI is the
* NHDR income control (Section 10). Economic activity follows the PBS
* definition, which this reproduction matches in all ten published cells (18.2):
*   employed    worked for pay or profit, or for family gain, or had a job
*               or enterprise and was absent (S05C02, S05C03, S05C04)
*   unemployed  not employed, and seeking work (S09C01), or available
*               (S09C04 1-6), or not seeking because ill, awaiting a job,
*               laid off or an apprentice (S09C06 1-4)
* Earnings: weekly pay x 52 or monthly pay x 12, paid employees only.
* NHDR printed 1,673 and 9,335 dollars. Those imply S_f = 0.146 given the
* Census 2017 female share, and a population-weighted mean of about 5,600
* dollars, not the 4,922 control of the HDI. Neither the wage ratio nor the
* income level NHDR used can be recovered from what it published.
use S04C05 S04C06 S04C07 S05C02 S05C03 S05C04 S07C03 S07C04 S09C01 S09C04 S09C06 ///
    Weight Province using "$lfs/LFS 2018-19.dta", clear
rename (S04C05 S04C06 S04C07 Weight Province) (sex age marital weight province)
gen byte employed = (S05C02 == 1) | (S05C03 == 1) | inlist(S05C04, 1, 2)
gen byte active = employed | (S09C01 == 1) | inrange(S09C04, 1, 6) | inlist(S09C06, 1, 2, 3, 4)
gen double earn = .
replace earn = S07C03 * 52 if S07C03 > 0 & !missing(S07C03)
replace earn = S07C04 * 12 if S07C04 > 0 & !missing(S07C04)
gen str20 domain = ""
replace domain = "Khyber Pakhtunkhwa" if province == 1
replace domain = "Punjab"             if province == 2
replace domain = "Sindh"              if province == 3
replace domain = "Balochistan"        if province == 4
tempfile lfs18
save `lfs18'
nhdr_earned_income, sex(sex) active(active) earn(earn) age(age) wgt(weight) domain(domain)
gen str7 survey = "2018_19"
tempfile ei18
save `ei18'
display as text _n "Step 14: female share of earned income, LFS 2018-19"
list, noobs sep(0)
quietly summarize ea_f if domain == "Pakistan"
nhdr_check, label("Step 14 female share of the labour force, LFS 2018-19 [reference 0.2377]") ///
    got(`=r(mean)') want(0.2377) tol(0.0005)
quietly summarize wage_ratio if domain == "Pakistan"
nhdr_check, label("Step 14 female to male mean earnings, LFS 2018-19 [reference 0.696]") ///
    got(`=r(mean)') want(0.6961) tol(0.001)

* ---- 17.4 The GDI reproduced for 2018-19 and carried to 2024-25 ------------------------
* National, as NHDR, and provincial as an extension. No survey gives life
* expectancy by sex for a province, so each province takes its own life
* expectancy plus the national female and male offsets (+1.0 and -0.9 years
* in 2018-19). The provincial GDI therefore measures the education and income
* gaps between women and men, with the health gap held at the national value.
* 2024-25 inputs
*   education  HIES 2024-25 by sex
*   health     68.1 and 66.2 carried forward by the World Bank change in
*              female and male life expectancy, 2018 to 2024
*   income     the UNDP split on LFS 2024-25, with the Section 13 control
*              and the Census 2023 female share
import delimited using "$pub/WDI Pakistan by sex.csv", clear varnames(1) asdouble encoding(utf-8)
foreach spec in "SP.DYN.LE00.FE.IN 2018 lef2018" "SP.DYN.LE00.FE.IN 2024 lef2024" ///
    "SP.DYN.LE00.MA.IN 2018 lem2018" "SP.DYN.LE00.MA.IN 2024 lem2024" {
    local c : word 1 of `spec'
    local y : word 2 of `spec'
    local s : word 3 of `spec'
    quietly summarize value if indicator_code == "`c'" & year == `y'
    scalar `s' = r(mean)
}
scalar le_f_1819 = 68.1
scalar le_m_1819 = 66.2
scalar le_f_2425 = le_f_1819 + (lef2024 - lef2018)
scalar le_m_2425 = le_m_1819 + (lem2024 - lem2018)
display as text "  life expectancy by sex 2024-25, chained: female " as result %6.3f le_f_2425 ///
    as text ", male " as result %6.3f le_m_2425
import delimited using "$pub/Census female share.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(2 4)
rename (region year) (domain cyear)
tempfile cen
save `cen'

* LFS 2024-25, activity on the 13th ICLS definition PBS still tabulates for
* comparison with earlier rounds: employed includes own-use farming, fishing
* and animal rearing (S5C8 1-3), and the unemployed are looking (S9C1) and available
* (S9C6). The reproduce matches PBS Table 3.13 in all ten cells (Section 18.3).
use S4C5 S4C6 S4C7 S5C1 S5C2 S5C3 S5C4 S5C8 S7C33 S7C43 S9C1 S9C6 Weights Province ///
    using "$lfs24/LFS 2024-25.dta", clear
rename (S4C5 S4C6 S4C7 Weights Province) (sex age marital weight province)
gen byte employed = (S5C1 == 1) | (S5C2 == 1) | (S5C3 == 1) | (S5C4 == 1) | inlist(S5C8, 1, 2, 3)
gen byte active = employed | ((S9C1 == 1) & (S9C6 == 1))
gen double earn = .
replace earn = S7C33 * 52 if S7C33 > 0 & !missing(S7C33)
replace earn = S7C43 * 12 if S7C43 > 0 & !missing(S7C43)
gen str20 domain = ""
replace domain = "Khyber Pakhtunkhwa" if province == 1
replace domain = "Punjab"             if province == 2
replace domain = "Sindh"              if province == 3
replace domain = "Balochistan"        if province == 4
tempfile lfs24
save `lfs24'
nhdr_earned_income, sex(sex) active(active) earn(earn) age(age) wgt(weight) domain(domain)
gen str7 survey = "2024_25"
append using `ei18'
* Sensitivity: the 2024-25 split with each domain's 2018-19 earnings ratio.
* The ratio of mean female to mean male earnings of paid employees rises from
* 0.70 to 0.95 between the two rounds, largely a change in who the paid
* female employees are (salaried teachers and health workers dominate), so
* the GDI is reported with and without it.
bysort domain (survey): gen double w18 = wage_ratio[1]
gen double s_f_w18 = w18 * ea_f / (w18 * ea_f + (1 - ea_f))
drop w18
list, noobs sep(0)
tempfile ei
save `ei'

* HIES 2024-25 education by sex.
use `p24', clear
gen str6 sex = cond(s1aq03 == 2, "Female", cond(s1aq03 == 1, "Male", ""))
drop if sex == ""
gen str20 domain = ""
replace domain = "Khyber Pakhtunkhwa" if province == 1
replace domain = "Punjab"             if province == 2
replace domain = "Sindh"              if province == 3
replace domain = "Balochistan"        if province == 4
preserve
collapse (mean) lit15 ner [aw=weight], by(sex)
gen str20 domain = "Pakistan"
tempfile gnat
save `gnat'
restore
collapse (mean) lit15 ner [aw=weight], by(domain sex)
append using `gnat'
replace lit15 = 100 * lit15
replace ner   = 100 * ner
gen str7 survey = "2024_25"
tempfile gedu24
save `gedu24'
use `gedu18', clear
gen str7 survey = "2018_19"
append using `gedu24'

* Assemble one row per domain, survey and sex.
merge m:1 domain survey using `ei', keepusing(s_f s_f_w18) nogenerate
gen int cyear = cond(survey == "2018_19", 2017, 2023)
merge m:1 domain cyear using `cen', keepusing(female_share) keep(master match) nogenerate
* Income control: NHDR 2018-19 per capita income, and the Section 13 index
* for 2024-25.
preserve
use `t2a_all', clear
keep domain pci_2018_19 le_2018_19
tempfile c18
save `c18'
use `fin24', clear
keep domain pci_ppp life_years
tempfile c24
save `c24'
restore
merge m:1 domain using `c18', keep(master match) nogenerate
merge m:1 domain using `c24', keep(master match) nogenerate
gen double pci_all = cond(survey == "2018_19", pci_2018_19, pci_ppp)
gen double le_all  = cond(survey == "2018_19", le_2018_19, life_years)
gen double pci = cond(sex == "Female", pci_all * s_f / female_share, pci_all * (1 - s_f) / (1 - female_share))
gen double pci_w18 = cond(sex == "Female", pci_all * s_f_w18 / female_share, ///
    pci_all * (1 - s_f_w18) / (1 - female_share))
* Life expectancy by sex: national values as above, provinces with the
* national offsets.
gen double le = .
replace le = le_f_1819 if sex == "Female" & survey == "2018_19"
replace le = le_m_1819 if sex == "Male"   & survey == "2018_19"
replace le = le_f_2425 if sex == "Female" & survey == "2024_25"
replace le = le_m_2425 if sex == "Male"   & survey == "2024_25"
quietly summarize le_all if domain == "Pakistan" & survey == "2018_19"
local nat18 = r(mean)
quietly summarize le_all if domain == "Pakistan" & survey == "2024_25"
local nat24 = r(mean)
replace le = le_all + (le - `nat18') if domain != "Pakistan" & survey == "2018_19"
replace le = le_all + (le - `nat24') if domain != "Pakistan" & survey == "2024_25"
nhdr_gdi_hdi, literacy(lit15) enrolment(ner) life(le) income(pci)
nhdr_gdi_hdi, literacy(lit15) enrolment(ner) life(le) income(pci_w18) prefix(w18_)
sort survey domain sex
by survey domain: gen double gdi = gdi_hdi[1] / gdi_hdi[2] if _N == 2
by survey domain: gen double gdi_w18 = w18_hdi[1] / w18_hdi[2] if _N == 2
gen double gdi_dev = 100 * abs(gdi - 1)
display as text _n "Step 14: GDI reproduced, 2018-19 and 2024-25 (provinces hold the national health gap)"
list survey domain sex lit15 ner le pci gdi_hdi gdi gdi_w18, noobs sepby(survey domain) abbreviate(10)
quietly summarize pci if domain == "Pakistan" & survey == "2018_19" & sex == "Female"
display as text "  female income, Pakistan 2018-19, reproduced " as result %7.0f r(mean) as text " against NHDR 1,673"
quietly summarize gdi if domain == "Pakistan" & survey == "2018_19"
display as text "  GDI Pakistan 2018-19, reproduced " as result %6.4f r(mean) as text " against NHDR 0.777"
quietly summarize gdi if domain == "Pakistan" & survey == "2024_25"
display as text "  GDI Pakistan 2024-25 " as result %6.4f r(mean)
quietly summarize gdi_w18 if domain == "Pakistan" & survey == "2024_25"
display as text "  GDI Pakistan 2024-25, 2018-19 earnings ratio held " as result %6.4f r(mean)
quietly summarize pci if domain == "Pakistan" & survey == "2018_19" & sex == "Female"
nhdr_check, label("Step 14 female income, Pakistan 2018-19, UNDP split [reference 1,799]") ///
    got(`=r(mean)') want(1798.79) tol(1)
quietly summarize pci if domain == "Pakistan" & survey == "2024_25" & sex == "Female"
nhdr_check, label("Step 14 female income, Pakistan 2024-25, UNDP split [reference 2,680]") ///
    got(`=r(mean)') want(2679.53) tol(1)
export delimited using "$out/GDI reproduced 2018-19 2024-25.csv"


*==============================================================================*
* SECTION 18   GENDER INEQUALITY INDEX (GII), TABLES 7 AND 7A
*==============================================================================*
* NHDR 2020 keeps UNDP's GII aggregation and replaces the two reproductive
* health indicators, maternal mortality and adolescent births, which have no
* provincial series:
*   health_f   = (1 / (NC x EM))^(1/2)
*                NC  percent of women who gave birth in the last three years
*                    without prenatal and postnatal care, the average of the
*                    two percentages
*                EM  percent of women aged 15 to 19 ever married
*   empower_f  = (PR_f x SE_f)^(1/2)   PR seat share, SE primary or higher
*   G_f = (health_f x empower_f x LFPR_f)^(1/3)
*   G_m = (1 x empower_m x LFPR_m)^(1/3)
*   HARM = 2 / (1/G_f + 1/G_m)
*   G_fm = (health_bar x empower_bar x LFPR_bar)^(1/3), with
*          health_bar = (health_f + 1)/2 and the others the simple means
*   GII = 1 - HARM / G_fm
* Solving the published panel shows the NC x EM product enters with no
* scaling: 10/MMR x 1/ABR in UNDP's formula becomes 1/(NC x EM) with both
* terms in percent.
* Target    Table 7: 5 domains x 2 years x 8 printed quantities

* ---- 18.1 The construction, recovered from Table 7A ------------------------------
import delimited using "$pub/NHDR2020 Table 7.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2)
rename region domain
nhdr_gii, nocare(no_care_f) evmarried(evm1519_f) seatf(seats_f) seatm(seats_m) ///
    secf(sec_f) secm(sec_m) lfprf(lfpr_f) lfprm(lfpr_m)
gen double _g = max(abs(gii_g_f - pub_g_f), abs(gii_g_m - pub_g_m), abs(gii_harm - pub_harm), ///
    abs(gii_gii - pub_gii), abs(gii_health_bar - pub_health_bar), abs(gii_emp_bar - pub_emp_bar), ///
    abs(gii_lfpr_bar - pub_lfpr_bar), abs(gii_g_fm - pub_g_fm))
display as text _n "Step 15: GII construction against Table 7"
list domain year gii_g_f pub_g_f gii_g_m pub_g_m gii_gii pub_gii _g, noobs sep(0) abbreviate(12)
quietly summarize _g
nhdr_check, label("Step 15 GII construction, worst |gap| of 80 printed values [published]") ///
    got(`=r(max)') want(0) tol(0.001)
drop _g
quietly summarize gii_gii if domain == "Pakistan" & year == "2018_19"
nhdr_check, label("Step 15 GII Pakistan 2018-19 [published 0.548]") got(`=r(mean)') want(0.548) tol(0.0006)
tempfile t7
save `t7'
export delimited using "$out/GII method Table 7.csv"

* ---- 18.2 The 2018-19 inputs reproduced from the microdata ----------------------------
* (a) Prenatal and postnatal care, HIES 2018-19 section 4D. Women who had a
*     live birth in the last three years (s4dq01 = 1). No prenatal care:
*     s4dq2a = 2. No postnatal check-up within six weeks: s4dq11a = 2.
*     Household weights. NC = average of the two percentages.
use hhcode psu province s4dq01 s4dq2a s4dq11a using "$h18/sec_4d.dta", clear
merge m:1 psu using "$h18/weight.dta", keep(master match) nogenerate
keep if s4dq01 == 1
gen double nopre  = (s4dq2a == 2)  if !missing(s4dq2a)
gen double nopost = (s4dq11a == 2) if !missing(s4dq11a)
nhdr_by_province, vars(nopre nopost) wgt(weight) province(province)
gen double no_care_f = 100 * (nopre + nopost) / 2
gen str7 year = "2018_19"
keep domain year no_care_f nopre nopost
tempfile r_nc18
save `r_nc18'
list, noobs sep(0)

* (b) Primary or higher, HIES 2018-19, persons 10 and over: completed class 5
*     or above (s2bq05 5 to 24), or attending class 5 or above now (s2bq14 5
*     to 24). This is the reading that reproduces all ten published cells.
use `h18p', clear
keep if age >= 10 & !missing(age)
gen double prim = (inrange(s2bq05, 5, 24)) | (s2bq01 == 3 & inrange(s2bq14, 5, 24))
gen double prim_f = prim if s1aq04 == 2
gen double prim_m = prim if s1aq04 == 1
nhdr_by_province, vars(prim_f prim_m) wgt(weights) province(province)
gen double sec_f = 100 * prim_f
gen double sec_m = 100 * prim_m
keep domain sec_f sec_m
gen str7 year = "2018_19"
tempfile r_se18
save `r_se18'

* (c) and (d) Ever married at 15 to 19, and labour force participation 10+,
*     LFS 2018-19 (activity as defined in Section 17.3).
use `lfs18', clear
gen double evm = inlist(marital, 2, 3, 4) if sex == 2 & inrange(age, 15, 19) & !missing(marital)
gen double lf_f = active if sex == 2 & age >= 10 & !missing(age)
gen double lf_m = active if sex == 1 & age >= 10 & !missing(age)
nhdr_by_province, vars(evm lf_f lf_m) wgt(weight) province(province)
gen double evm1519_f = 100 * evm
gen double lfpr_f = 100 * lf_f
gen double lfpr_m = 100 * lf_m
keep domain evm1519_f lfpr_f lfpr_m
gen str7 year = "2018_19"
tempfile r_lf18
save `r_lf18'

* Published comparators.
import delimited using "$pub/PBS LFS refined LFPR.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 5)
rename region domain
keep survey domain male female
reshape wide male female, i(domain) j(survey) string
tempfile pbslf
save `pbslf'

use `r_nc18', clear
merge 1:1 domain year using `r_se18', nogenerate
merge 1:1 domain year using `r_lf18', nogenerate
foreach v in no_care_f evm1519_f sec_f sec_m lfpr_f lfpr_m {
    rename `v' raw_`v'
}
merge 1:1 domain year using `t7', keepusing(no_care_f evm1519_f seats_f seats_m sec_f sec_m ///
    lfpr_f lfpr_m pub_gii) keep(master match) nogenerate
merge 1:1 domain using `pbslf', nogenerate
display as text _n "Step 15: GII inputs 2018-19, reproduced against Table 7A and PBS"
list domain raw_no_care_f no_care_f raw_evm1519_f evm1519_f raw_sec_f sec_f raw_sec_m sec_m, ///
    noobs sep(0) abbreviate(14)
list domain raw_lfpr_f femalelfs1819 femalelfs1718 lfpr_f raw_lfpr_m malelfs1819 malelfs1718 lfpr_m, ///
    noobs sep(0) abbreviate(14)
* Prenatal and postnatal care: Table 7A prints halves of whole percentages,
* the average of two rounded figures, so 0.6 is a match.
gen double _a = abs(raw_no_care_f - no_care_f)
quietly summarize _a
nhdr_check, label("Step 15 no prenatal/postnatal care, worst of 5 domains [published]") ///
    got(`=r(max)') want(0) tol(0.6)
* Primary or higher: whole percentages.
replace _a = max(abs(raw_sec_f - sec_f), abs(raw_sec_m - sec_m))
quietly summarize _a
nhdr_check, label("Step 15 primary or higher education, worst of 10 cells [published]") ///
    got(`=r(max)') want(0) tol(0.55)
* Labour force participation against PBS 2018-19.
replace _a = max(abs(raw_lfpr_f - femalelfs1819), abs(raw_lfpr_m - malelfs1819))
quietly summarize _a
nhdr_check, label("Step 15 LFPR 10+, LFS 2018-19 microdata vs PBS, worst of 10 cells [published]") ///
    got(`=r(max)') want(0) tol(0.05)
* What NHDR printed as 2018-19 labour force participation is the PBS 2017-18
* column, in all ten cells.
replace _a = max(abs(lfpr_f - femalelfs1718), abs(lfpr_m - malelfs1718))
quietly summarize _a
nhdr_check, label("Step 15 NHDR 2018-19 LFPR equals PBS LFS 2017-18, worst of 10 [published]") ///
    got(`=r(max)') want(0) tol(0.001)
* Ever married at 15 to 19: the reproduction matches PBS's own LFS 2018-19 table,
* and neither matches NHDR.
quietly summarize raw_evm1519_f if domain == "Pakistan"
nhdr_check, label("Step 15 women 15-19 ever married, LFS 2018-19 vs PBS Table 4 [published 12.31]") ///
    got(`=r(mean)') want(`=bm_lfs1819_evm1519_f') tol(0.05)
display as text "  NHDR prints 20.0 for Pakistan. No definition tested on LFS 2018-19 or HIES"
display as text "  2018-19 reproduces the NHDR column (see the technical note)."
drop _a

* The GII on reproduced inputs, and what each substitution moves.
* raw   : every reproduced input (seats stay published)
* swap_ : NHDR's inputs with one reproduced input swapped in
nhdr_gii, nocare(raw_no_care_f) evmarried(raw_evm1519_f) seatf(seats_f) seatm(seats_m) ///
    secf(raw_sec_f) secm(raw_sec_m) lfprf(raw_lfpr_f) lfprm(raw_lfpr_m) prefix(raw_)
nhdr_gii, nocare(raw_no_care_f) evmarried(evm1519_f) seatf(seats_f) seatm(seats_m) ///
    secf(sec_f) secm(sec_m) lfprf(lfpr_f) lfprm(lfpr_m) prefix(s1_)
nhdr_gii, nocare(no_care_f) evmarried(raw_evm1519_f) seatf(seats_f) seatm(seats_m) ///
    secf(sec_f) secm(sec_m) lfprf(lfpr_f) lfprm(lfpr_m) prefix(s2_)
nhdr_gii, nocare(no_care_f) evmarried(evm1519_f) seatf(seats_f) seatm(seats_m) ///
    secf(raw_sec_f) secm(raw_sec_m) lfprf(lfpr_f) lfprm(lfpr_m) prefix(s3_)
nhdr_gii, nocare(no_care_f) evmarried(evm1519_f) seatf(seats_f) seatm(seats_m) ///
    secf(sec_f) secm(sec_m) lfprf(raw_lfpr_f) lfprm(raw_lfpr_m) prefix(s4_)
gen double d_care  = s1_gii - pub_gii
gen double d_evm   = s2_gii - pub_gii
gen double d_educ  = s3_gii - pub_gii
gen double d_lfpr  = s4_gii - pub_gii
display as text _n "Step 15: GII 2018-19 on reproduced inputs, and the effect of each substitution"
list domain pub_gii raw_gii d_care d_evm d_educ d_lfpr, noobs sep(0) abbreviate(10)
quietly summarize raw_gii if domain == "Pakistan"
nhdr_check, label("Step 15 GII 2018-19 on reproduced inputs, Pakistan [reference 0.5102]") ///
    got(`=r(mean)') want(0.5102) tol(0.001)
tempfile gii18
save `gii18'
export delimited using "$out/GII 2018-19 reproduced.csv"

* ---- 18.3 The GII for 2024-25 ------------------------------------------------------
* Same definitions on the newest rounds:
*   NC          HIES 2024-25 section 4D (s4dq021 prenatal, s4dq111 postnatal)
*   EM, LFPR    LFS 2024-25, 13th ICLS activity (Section 17.4)
*   SE          HIES 2024-25, the 18.2 rule (s2bq05, s2bq10)
*   seats       held at the 2018 values. The 2024 assemblies seated their
*               reserved-seat members only after the Supreme Court decisions
*               of 2024 and 2025, and no settled count of women members by
*               assembly was located in a primary source. Holding the input
*               keeps the change attributable to the three measured
*               dimensions.
use prcode hhno province s4dq01 s4dq021 s4dq111 using "$h24/Sec_04d_pre_post_natal.dta", clear
merge m:1 prcode using "$h24/weight.dta", keep(master match) nogenerate
keep if s4dq01 == 1
gen double nopre  = (s4dq021 == 2) if !missing(s4dq021)
gen double nopost = (s4dq111 == 2) if !missing(s4dq111)
nhdr_by_province, vars(nopre nopost) wgt(weight) province(province)
gen double no_care_f = 100 * (nopre + nopost) / 2
keep domain no_care_f
tempfile r_nc24
save `r_nc24'

use `p24', clear
keep if age >= 10 & !missing(age)
gen double prim = (inrange(s2bq05, 5, 24)) | (s2bq01 == 3 & inrange(s2bq10, 5, 24))
gen double prim_f = prim if s1aq03 == 2
gen double prim_m = prim if s1aq03 == 1
nhdr_by_province, vars(prim_f prim_m) wgt(weight) province(province)
gen double sec_f = 100 * prim_f
gen double sec_m = 100 * prim_m
keep domain sec_f sec_m
tempfile r_se24
save `r_se24'

use `lfs24', clear
gen double evm = inlist(marital, 2, 3, 4) if sex == 2 & inrange(age, 15, 19) & !missing(marital)
gen double lf_f = active if sex == 2 & age >= 10 & !missing(age)
gen double lf_m = active if sex == 1 & age >= 10 & !missing(age)
nhdr_by_province, vars(evm lf_f lf_m) wgt(weight) province(province)
gen double evm1519_f = 100 * evm
gen double lfpr_f = 100 * lf_f
gen double lfpr_m = 100 * lf_m
keep domain evm1519_f lfpr_f lfpr_m
merge 1:1 domain using `r_nc24', nogenerate
merge 1:1 domain using `r_se24', nogenerate
merge 1:1 domain using `pbslf', keepusing(malelfs2425 femalelfs2425) nogenerate
gen double _a = max(abs(lfpr_f - femalelfs2425), abs(lfpr_m - malelfs2425))
quietly summarize _a
nhdr_check, label("Step 15 LFPR 10+, LFS 2024-25 microdata vs PBS Table 3.13, worst of 10 [published]") ///
    got(`=r(max)') want(0) tol(0.15)
drop _a
preserve
use `t7', clear
keep if year == "2018_19"
keep domain seats_f seats_m
tempfile seats
save `seats'
restore
merge 1:1 domain using `seats', nogenerate
nhdr_gii, nocare(no_care_f) evmarried(evm1519_f) seatf(seats_f) seatm(seats_m) ///
    secf(sec_f) secm(sec_m) lfprf(lfpr_f) lfprm(lfpr_m) prefix(g24_)
merge 1:1 domain using `gii18', keepusing(raw_gii pub_gii raw_no_care_f raw_evm1519_f raw_sec_f ///
    raw_sec_m raw_lfpr_f raw_lfpr_m) nogenerate
gen double gii_change = g24_gii - raw_gii
display as text _n "Step 15: THE GII FOR 2024-25, with 2018-19 on the same reproduced inputs"
list domain no_care_f raw_no_care_f evm1519_f raw_evm1519_f sec_f raw_sec_f lfpr_f raw_lfpr_f, ///
    noobs sep(0) abbreviate(12)
list domain pub_gii raw_gii g24_gii gii_change, noobs sep(0) abbreviate(12)
quietly summarize g24_gii if domain == "Pakistan"
nhdr_check, label("Step 15 GII 2024-25, Pakistan [reference 0.4577]") got(`=r(mean)') want(0.4577) tol(0.001)
export delimited using "$out/GII 2024-25.csv"


*==============================================================================*
* SECTION 19   MULTIDIMENSIONAL POVERTY INDEX (MPI), PSLM 2019-20
*==============================================================================*
* NHDR 2020 cites Pakistan's national MPI but does not compute one. The
* official 2019-20 MPI (Ministry of Planning, Development and Special
* Initiatives, UNICEF and OPHI, 2024) is built on the same PSLM 2019-20
* district round used in Sections 14 and 15, and publishes national,
* rural-urban, provincial and all 126 district values with confidence
* intervals. It is reproduced here from the microdata.
* Method    Alkire-Foster. Each household member takes the household's
*           deprivations. A person is poor when the weighted deprivation
*           score c is at least 1/3.
*               H = share of people poor, A = mean c among the poor,
*               MPI = H x A
* Indicators and weights, as in Table 1 of the report. Where the table's
* wording leaves a coding choice, the choice made here is the one that
* reproduces the published uncensored headcount of Appendix B:
*   Education (1/3)
*     years of schooling   1/6   no man OR no woman aged 10+ has completed
*                                class 5 (sc1q05 5-24, or attending class
*                                6+). A household with no man or no woman
*                                of that age is deprived on that side.
*     school attendance    1/8   any child 6 to 11 not attending (sc1q01)
*     education quality    1/24  any child 4 to 15 never enrolled or left
*                                because too expensive, too far, poor
*                                teaching, or no female or male teacher
*                                (sc1q02, sc1q10 codes 1 2 3 7 8)
*   Health (1/3)
*     immunisation         1/9   any child aged 1 to 4 missing BCG, Penta
*                                1-3, PCV 1-3, OPV 1-3, IPV or measles 1, or
*                                any child under one missing BCG or OPV 0.
*                                Card, recall and campaign doses all count.
*     antenatal care       1/9   any woman with a birth in the last three
*                                years and no prenatal consultation (secj)
*     assisted delivery    1/9   that birth attended by a relative, a
*                                traditional birth attendant or other
*                                (sjaq10 1 3 9)
*   Living standard (1/3)
*     water                1/21  source not piped, hand pump, motor pump,
*                                closed well, protected spring, bottled or
*                                filtration plant, or a round trip over 30
*                                minutes
*     sanitation           1/21  no flush toilet (sewer, septic tank, drain
*                                or pit)
*     walls                1/42  mud, raw brick, wood, plywood or other
*     overcrowding         1/42  4 or more people per room
*     electricity          1/21  lighting from neither the grid nor solar
*     cooking fuel         1/21  wood, dung, crop residue, coal or other
*     assets               1/21  (not more than two small assets OR no large
*                                asset) AND no car. Small: radio, TV, iron,
*                                fan, sewing machine, chair, watch, air
*                                cooler, bicycle, landline. Large:
*                                refrigerator or freezer, air conditioner,
*                                tractor, motorcycle, computer.
*     land and livestock   1/21  rural only: under 2.25 acres unirrigated AND
*                                under 1.125 acres irrigated, AND under 2
*                                cattle, 3 goats or sheep, 5 chickens and no
*                                draught animal
* Target    Appendix B, C and D of the MPI Report 2019-20
* Result    national MPI 0.145 against 0.146, H 30.4 against 30.5, every
*           province within 0.3 points of H, and 125 of 126 district
*           headcounts inside the published 95 percent interval

* ---- 19.1 Households ------------------------------------------------------------------
use hhcode psu province region district idc sb1q4 age weights using "$p19/plist.dta", clear
tempfile p19mpi
save `p19mpi'
bysort hhcode: gen int hhsize = _N
by hhcode: keep if _n == 1
keep hhcode psu province region district hhsize weights
tempfile mpihh
save `mpihh'

* ---- 19.2 Education deprivations ----------------------------------------------------
use `p19mpi', clear
merge 1:1 hhcode idc using "$p19/secc1.dta", keepusing(sc1q01 sc1q02 sc1q05 sc1q10 sc1q14) ///
    keep(master match) nogenerate
gen byte done5 = inrange(sc1q05, 5, 24) | (sc1q01 == 3 & inrange(sc1q14, 6, 24))
gen byte m_done = done5 if sb1q4 == 1 & age >= 10 & !missing(age)
gen byte f_done = done5 if sb1q4 == 2 & age >= 10 & !missing(age)
gen byte att_dep  = (sc1q01 != 3) if inrange(age, 6, 11)
gen byte qual_dep = inlist(sc1q02, 1, 2, 3, 7, 8) | inlist(sc1q10, 1, 2, 3, 7, 8) if inrange(age, 4, 15)
collapse (max) m_done f_done att_dep qual_dep, by(hhcode)
* A household with no man (or no woman) aged 10+ has nobody on that side
* who completed class 5.
gen byte d_yos  = (m_done != 1) | (f_done != 1)
gen byte d_att  = (att_dep == 1)
gen byte d_qual = (qual_dep == 1)
keep hhcode d_yos d_att d_qual
tempfile dedu
save `dedu'

* ---- 19.3 Health deprivations --------------------------------------------------------
use hhcode idc siaq5a siaq5b siaq5c siaq5d siaq5e siaq5f siaq5g siaq5h siaq5i siaq5j ///
    siaq5k siaq5l siaq5m using "$p19/seci.dta", clear
merge m:1 hhcode idc using `p19mpi', keepusing(age) keep(master match) nogenerate
foreach v in a b c d e f g h i j k l m {
    gen byte got_`v' = inlist(siaq5`v', 1, 2, 4)
}
gen byte full = got_a & got_b & got_c & got_d & got_e & got_f & got_g & got_i & got_j & ///
    got_k & got_l & got_m
gen byte imm_dep = (inrange(age, 1, 4) & !full) | (age == 0 & !(got_a & got_h))
collapse (max) imm_dep, by(hhcode)
gen byte d_imm = (imm_dep == 1)
keep hhcode d_imm
tempfile dimm
save `dimm'
use hhcode sjaq01 sjaq2a sjaq10 using "$p19/secj.dta", clear
keep if inlist(sjaq01, 1, 2)
gen byte anc_dep = (sjaq2a == 2)
gen byte del_dep = inlist(sjaq10, 1, 3, 9)
collapse (max) anc_dep del_dep, by(hhcode)
rename (anc_dep del_dep) (d_anc d_del)
tempfile dmat
save `dmat'

* ---- 19.4 Living standard deprivations ----------------------------------------------
use hhcode sf1q04 sf1q07 sf1q08 sf1q10 sf1q11_1c sf1q11_1d sf1q11_1e sf1q11_1f ///
    using "$p19/secf1.dta", clear
tempfile f1
save `f1'
use hhcode sf2q01 sf2q04 sf2q11 using "$p19/secf2.dta", clear
tempfile f2
save `f2'
* Assets: one flag per item code with a positive count.
use hhcode itc c02 using "$p19/sech.dta", clear
keep if c02 > 0 & !missing(c02)
gen byte own = 1
collapse (max) own, by(hhcode itc)
reshape wide own, i(hhcode) j(itc)
tempfile assets
save `assets'
* Land and livestock.
use hhcode itc sgaq01 sgaq03 sgaq31 sgaq05 using "$p19/secg.dta", clear
keep if sgaq01 == 1
gen double acres = sgaq03 * cond(sgaq31 == 1, 1, cond(sgaq31 == 2, 0.5, cond(sgaq31 == 3, 0.125, ///
    cond(sgaq31 == 4, 1 / 43.56, .)))) if itc == 1
gen double irr  = acres if itc == 1 & sgaq05 == 1
gen double rain = acres if itc == 1 & sgaq05 != 1
gen double cattle  = sgaq03 if itc == 4
gen double goats   = sgaq03 if itc == 5
gen double draught = sgaq03 if itc == 6
gen double poultry = sgaq03 if itc == 7
collapse (sum) irr rain cattle goats draught poultry, by(hhcode)
tempfile landlive
save `landlive'

use `mpihh', clear
merge 1:1 hhcode using `f1', keep(master match) nogenerate
merge 1:1 hhcode using `f2', keep(master match) nogenerate
merge 1:1 hhcode using `assets', keep(master match) nogenerate
merge 1:1 hhcode using `landlive', keep(master match) nogenerate
merge 1:1 hhcode using `dedu', keep(master match) nogenerate
merge 1:1 hhcode using `dimm', keep(master match) nogenerate
merge 1:1 hhcode using `dmat', keep(master match) nogenerate
foreach v in d_yos d_att d_qual d_imm d_anc d_del {
    replace `v' = 0 if missing(`v')
}
foreach k in 1 2 4 5 8 9 10 14 16 20 27 28 30 31 33 34 {
    capture confirm variable own`k'
    if _rc gen byte own`k' = 0
    replace own`k' = 0 if missing(own`k')
}
foreach v in irr rain cattle goats draught poultry {
    replace `v' = 0 if missing(`v')
}
* A missing water or toilet record counts as deprived, as an unimproved
* source would.
gen byte d_water = !inlist(sf2q01, 1, 2, 3, 4, 6, 8, 9, 10, 11, 13, 16, 18) | inlist(sf2q04, 3, 4, 5)
gen byte d_san   = !inlist(sf2q11, 2, 3, 4, 5)
gen byte d_walls = inlist(sf1q07, 2, 3, 4, 6)
gen byte d_crowd = (sf1q04 == 0) | ((hhsize / sf1q04) >= 4 & !missing(sf1q04) & sf1q04 > 0)
gen byte d_elec  = !inlist(sf1q10, 1, 2)
gen byte d_fuel  = inlist(sf1q08, 1, 6, 7, 8, 9)
gen byte small = own1 + own2 + own9 + own10 + own14 + own16 + own20 + own27 + own34 + (sf1q11_1c == 1)
gen byte large = own4 | own5 | own8 | own28 | own33 | (sf1q11_1d == 1) | (sf1q11_1e == 1) | (sf1q11_1f == 1)
gen byte car   = own30 | own31
gen byte d_assets = ((small <= 2) | !large) & !car
gen byte d_land = (rain < 2.25) & (irr < 1.125)
gen byte d_live = (cattle < 2) & (goats < 3) & (poultry < 5) & (draught < 1)
gen byte d_landlive = d_land & d_live & region == 1

* ---- 19.5 Identification and aggregation ------------------------------------------------
gen double c = (1/6) * d_yos + (1/8) * d_att + (1/24) * d_qual ///
    + (1/9) * (d_imm + d_anc + d_del) ///
    + (1/21) * (d_water + d_san + d_elec + d_fuel + d_assets + d_landlive) ///
    + (1/42) * (d_walls + d_crowd)
gen byte poor = (c >= 1/3 - 1e-9)
gen double pop_w = weights * hhsize
gen double c_poor = c if poor
decode district, generate(_dn)
gen str40 district_name = proper(_dn)
drop _dn
gen str20 province_name = ""
replace province_name = "Khyber Pakhtunkhwa" if province == 1
replace province_name = "Punjab"             if province == 2
replace province_name = "Sindh"              if province == 3
replace province_name = "Balochistan"        if province == 4
tempfile mpihh2
save `mpihh2'

* Uncensored headcounts, national, against Appendix B.
preserve
import delimited using "$pub/MPI 2019-20 uncensored published.csv", clear varnames(1) asdouble encoding(utf-8)
forvalues i = 1/`=_N' {
    scalar unc_`=indicator[`i']' = uncensored_headcount[`i']
}
restore
display as text _n "Step 16: uncensored headcount ratios, percent of population, against Appendix B"
local worst = 0
foreach d in yos att qual imm anc del water san walls crowd elec fuel assets landlive {
    quietly summarize d_`d' [aw=pop_w]
    local u = 100 * r(mean)
    local p = 100 * unc_`d'
    display as text "  " %-10s "`d'" as result %7.1f `u' as text "   published " as result %6.1f `p'
    if abs(`u' - `p') > `worst' local worst = abs(`u' - `p')
}
nhdr_check, label("Step 16 MPI uncensored headcounts, worst of 14 indicators, points [published]") ///
    got(`worst') want(0) tol(1.0)

* H, A and MPI for any grouping.
capture program drop nhdr_mpi_by
program define nhdr_mpi_by
    syntax , [BY(varlist)]
    local byopt
    if "`by'" != "" local byopt by(`by')
    collapse (mean) H=poor A=c_poor (rawsum) pop=pop_w [aw=pop_w], `byopt'
    replace H = 100 * H
    replace A = 100 * A
    gen double MPI = (H / 100) * (A / 100)
end

import delimited using "$pub/MPI 2019-20 published.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 3)
tempfile mpipub
save `mpipub'

use `mpihh2', clear
nhdr_mpi_by
gen str20 area = "Pakistan"
tempfile m_nat
save `m_nat'
use `mpihh2', clear
gen str20 area = cond(region == 1, "Rural", "Urban")
nhdr_mpi_by, by(area)
append using `m_nat'
tempfile m_nr
save `m_nr'
use `mpihh2', clear
rename province_name area
nhdr_mpi_by, by(area)
append using `m_nr'
merge 1:1 area using `mpipub', keepusing(mpi h a) keep(master match) nogenerate
display as text _n "Step 16: MPI 2019-20, national, rural-urban and provinces, against Appendix C"
list area MPI mpi H h A a, noobs sep(0)
foreach ar in Pakistan Rural Urban Punjab Sindh Khyber_Pakhtunkhwa Balochistan {
    local nm = subinstr("`ar'", "_", " ", .)
    quietly summarize MPI if area == "`nm'"
    local g = r(mean)
    quietly summarize mpi if area == "`nm'"
    nhdr_check, label("Step 16 MPI 2019-20, `nm' [published]") got(`g') want(`=r(mean)') tol(0.002)
    quietly summarize H if area == "`nm'"
    local g = r(mean)
    quietly summarize h if area == "`nm'"
    nhdr_check, label("Step 16 headcount H 2019-20, `nm' [published]") got(`g') want(`=r(mean)') tol(0.5)
    quietly summarize A if area == "`nm'"
    local g = r(mean)
    quietly summarize a if area == "`nm'"
    nhdr_check, label("Step 16 intensity A 2019-20, `nm' [published]") got(`g') want(`=r(mean)') tol(0.5)
}
quietly summarize MPI if area == "Pakistan"
nhdr_check, label("Step 16 MPI 2019-20, Pakistan [reference 0.14550]") got(`=r(mean)') want(0.14550) tol(0.0001)
quietly summarize H if area == "Pakistan"
nhdr_check, label("Step 16 headcount H 2019-20, Pakistan [reference 30.393]") got(`=r(mean)') want(30.393) tol(0.01)
export delimited using "$out/MPI 2019-20 national provincial.csv"

* ---- 19.6 Districts ---------------------------------------------------------------------
use `mpihh2', clear
nhdr_mpi_by, by(province_name district district_name)
gen str60 key = ustrregexra(lower(district_name), "[^a-z]", "")
tempfile m_d
save `m_d'
use `mpipub', clear
keep if level == "district"
gen str60 key = ustrregexra(lower(area), "[^a-z]", "")
replace key = "bajur"              if key == "bajaur"
replace key = "shaheedbanazirabad" if key == "shaheedbenazirabad"
keep key area mpi mpi_lo mpi_hi h h_lo h_hi a
merge 1:1 key using `m_d', generate(_m)
quietly count if _m == 3
nhdr_check, label("Step 16 districts matched to Appendix D [published 126]") got(`=r(N)') want(126) tol(0)
list area district_name if _m != 3, noobs sep(0)
keep if _m == 3
drop _m
gen double d_mpi = MPI - mpi
gen double abs_d = abs(d_mpi)
gen byte h_in_ci = (H >= h_lo) & (H <= h_hi)
quietly summarize abs_d, detail
display as text "  district MPI, median |gap| " as result %6.4f r(p50) as text ", worst " as result %6.4f r(max)
nhdr_check, label("Step 16 district MPI, median |gap| of 126 [published]") got(`=r(p50)') want(0) tol(0.003)
quietly correlate MPI mpi
nhdr_check, label("Step 16 district MPI, correlation with Appendix D [published]") ///
    got(`=r(rho)') want(1) tol(0.005)
quietly count if h_in_ci
nhdr_check, label("Step 16 district H inside the published 95% interval [reference 125 of 126]") ///
    got(`=r(N)') want(125) tol(0)
gsort -abs_d
display as text _n "Step 16: the eight districts furthest from Appendix D"
list province_name district_name MPI mpi H h A a in 1/8, noobs sep(0) abbreviate(12)

* ---- 19.7 Divisions, and the district MPI beside the district HDI -----------------------
* Divisions follow MICS6 (Section 8.2). Three PSLM districts are not named in
* MICS6 and are placed by their administrative division: Duki (Zhob, where
* MICS6 places Loralai), Shaheed Sikandarabad (Kalat), and Islamabad, which
* PSLM files under Punjab and is reported as its own unit.
nhdr_district_key district_name, generate(dkey)
preserve
use `d2v', clear
keep key division_name
rename key dkey
tempfile d2vk2
save `d2vk2'
restore
merge m:1 dkey using `d2vk2', keep(master match) nogenerate
replace division_name = "Zhob"                        if district_name == "Duki"
replace division_name = "Kalat"                       if district_name == "Shaheed Sikandar Abad"
replace division_name = "Islamabad Capital Territory" if district_name == "Islamabad"
quietly count if division_name == ""
nhdr_check, label("Step 16 districts without a division [0]") got(`=r(N)') want(0) tol(0)
merge 1:1 province_name district_name using `dindex', keepusing(hdi rank) keep(master match) generate(_h)
quietly count if _h == 3
display as text "  districts with both an HDI (Section 15) and an MPI: " as result r(N)
quietly correlate hdi MPI if _h == 3
display as text "  correlation, district HDI and district MPI: " as result %6.3f r(rho)
drop _h dkey key abs_d
order province_name division_name district_name MPI mpi H h h_lo h_hi h_in_ci A a hdi rank
export delimited using "$out/MPI 2019-20 districts.csv"
save "$out/MPI 2019-20 districts.dta"
* Division values from the person-level data, never an average of districts.
keep district division_name
duplicates drop
tempfile dv
save `dv'
use `mpihh2', clear
merge m:1 district using `dv', keep(master match) nogenerate
nhdr_mpi_by, by(province_name division_name)
gsort -MPI
display as text _n "Step 16: MPI 2019-20 by division"
list province_name division_name MPI H A pop, noobs sep(0) abbreviate(14)
quietly count
nhdr_check, label("Step 16 divisions [reference 29, 28 MICS6 divisions and ICT]") got(`=r(N)') want(29) tol(0)
export delimited using "$out/MPI 2019-20 divisions.csv"




*==============================================================================*
* SECTION 20   THE 2006-07 COLUMNS FROM HIES 2005-06: EDUCATION, GDI, GII, IHDI
*==============================================================================*
* NHDR 2020 heads its first year "2006-07", but Tables 2A, 6 and 6A carry the
* footnote "The values are used for 2005-2006". The education inputs of the
* HDI, IHDI, GDI and GII for that year come from HIES 2005-06. Sections 3 and
* 4 reproduced the 2018-19 column. This section reproduces the first one from the
* same kind of raw file, with the same rules.
* Source    PBS, HIES 2005-06 microdata (15,453 households)
*             roster with weights.dta  hhcode, idc, age, s1aq03 sex,
*                                      province, region, weight (the
*                                      household weight, on every member)
*             sec 2a.dta               s2aq01 reads with understanding,
*                                      s2bq01 status (3 attending now),
*                                      s2bq05 highest class passed, s2bq14
*                                      class attending now
*             sec6abcd.dta             consumption: header codes 1000, 2000,
*                                      4000 and 5000, value columns v1 to v4
*             sec 4d.dta               s4dq01 birth in the last three years,
*                                      s4dq02 prenatal care, s4dq11 postnatal
*                                      care (1 yes, 2 no)
* Codes     HIES 2005-06 numbers the provinces 1 Punjab, 2 Sindh, 3 NWFP,
*           4 Balochistan, and the regions 1 urban, 2 rural: the reverse of
*           every later round. Both are recoded to the convention of this
*           file. The assignment is not a guess: the only other reading
*           misses the Table 2A domain totals by up to 14 points.
*           Eight persons appear twice in sec 2a.dta, and the first record is kept.
* Result    literacy and enrolment within 0.07 points in all 15 domains,
*           GDI education by sex exact, the GII care input exact to the
*           printed whole percent

* ---- 20.1 One record per person, with consumption per head ----------------------
use hhcode itc v1 v2 v3 v4 if inlist(itc, 1000, 2000, 4000, 5000) using "$h05/sec6abcd.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
gen double a = v * cond(itc == 1000, 26, cond(itc == 5000, 1, 12))
collapse (sum) t_exp=a, by(hhcode)
tempfile c05
save `c05'
use hhcode idc s2aq01 s2bq01 s2bq05 s2bq14 using "$h05/sec 2a.dta", clear
duplicates drop hhcode idc, force
tempfile e05
save `e05'
use hhcode idc age s1aq03 province region weight using "$h05/roster with weights.dta", clear
bysort hhcode: gen int hhsize = _N
merge 1:1 hhcode idc using `e05', keep(master match) nogenerate
merge m:1 hhcode using `c05', keep(master match) nogenerate
gen double pc_exp = t_exp / hhsize
recode province (1 = 2) (2 = 3) (3 = 1) (4 = 4), generate(_p)
recode region (1 = 2) (2 = 1), generate(_r)
drop province region
rename (_p _r) (province region)
gen double lit15 = (s2aq01 == 1) if age >= 15 & !missing(age) & !missing(s2aq01)
gen double cls = s2bq14 if s2bq01 == 3
gen double ner = ((inrange(age, 5, 9)   & inrange(cls, 1, 5))  | ///
                  (inrange(age, 10, 12) & inrange(cls, 6, 8))  | ///
                  (inrange(age, 13, 14) & inrange(cls, 9, 10))) if inrange(age, 5, 14)
tempfile h05p
save `h05p'

* ---- 20.2 Literacy and enrolment on the Table 2A layout, 2006-07 column ---------
keep hhcode idc province region weight pc_exp lit15 ner
nhdr_stack_domains, province(province) region(region)
nhdr_quintile, welfare(pc_exp) wtvar(weight) by(domain) generate(q)
tempfile stacked05 edu05_all
save `stacked05'
collapse (mean) lit15 ner [aw=weight], by(domain)
gen str3 quintile = "All"
save `edu05_all'
use `stacked05', clear
drop if missing(q)
collapse (mean) lit15 ner [aw=weight], by(domain q)
gen str3 quintile = "Q" + string(q)
drop q
append using `edu05_all'
replace lit15 = 100 * lit15
replace ner   = 100 * ner
rename (lit15 ner) (lit_reproduced ner_reproduced)
merge 1:1 domain quintile using `t2a', keepusing(lit_2006_07 ner_2006_07) keep(master match) nogenerate
rename (lit_2006_07 ner_2006_07) (lit_published ner_published)
gen double lit_diff = lit_reproduced - lit_published
gen double ner_diff = ner_reproduced - ner_published
sort domain quintile
tempfile edu0506
save `edu0506'
display as text _n "Step 17: domain totals, HIES 2005-06, against the 2006-07 column of Table 2A"
list domain lit_reproduced lit_published lit_diff ner_reproduced ner_published ner_diff ///
    if quintile == "All", noobs sep(0) abbreviate(16)
quietly summarize lit_reproduced if domain == "Pakistan" & quintile == "All"
nhdr_check, label("Step 17 literacy, Pakistan 2006-07 [published 50.7]") got(`=r(mean)') want(50.7) tol(0.06)
quietly summarize ner_reproduced if domain == "Pakistan" & quintile == "All"
nhdr_check, label("Step 17 net enrolment, Pakistan 2006-07 [published 34.7]") got(`=r(mean)') want(34.7) tol(0.06)
gen double _absl = abs(lit_diff)
gen double _absn = abs(ner_diff)
* The published values carry one decimal. 0.07 admits the rounding of the
* printed figure plus the eight duplicate records.
quietly summarize _absl if quintile == "All"
nhdr_check, label("Step 17 literacy 2006-07, worst of 15 domain totals, |gap| [published]") ///
    got(`=r(max)') want(0) tol(0.07)
quietly summarize _absn if quintile == "All"
nhdr_check, label("Step 17 enrolment 2006-07, worst of 15 domain totals, |gap| [published]") ///
    got(`=r(max)') want(0) tol(0.07)
* Quintile rows behave as in 2018-19 (Section 10): the rows do not tie to the
* published quintiles because NHDR's ranking variable is not recoverable.
quietly summarize _absl if quintile != "All"
nhdr_check, label("Step 17 literacy 2006-07, worst of 75 quintile rows [reference 7.50]") ///
    got(`=r(max)') want(7.4997) tol(0.35)
quietly summarize _absn if quintile != "All"
nhdr_check, label("Step 17 enrolment 2006-07, worst of 75 quintile rows [reference 6.36]") ///
    got(`=r(max)') want(6.3561) tol(0.35)
drop _absl _absn
export delimited using "$out/Table 2A education replication 2006-07.csv"

* ---- 20.3 The GDI of 2006-07: education by sex, and the index ----------------------
* Same universes, split by sex (s1aq03: 1 male, 2 female). Life expectancy
* and income by sex are NHDR's own (Table 6A). Only education is survey data.
use `h05p', clear
collapse (mean) lit=lit15 ner [aw=weight], by(s1aq03)
replace lit = 100 * lit
replace ner = 100 * ner
gen str6 sex = cond(s1aq03 == 2, "Female", "Male")
rename (lit ner) (lit_reproduced ner_reproduced)
keep sex lit_reproduced ner_reproduced
tempfile gdi05
save `gdi05'
import delimited using "$pub/NHDR2020 Table 6.csv", clear varnames(1) asdouble encoding(utf-8) stringcols(1 2)
keep if year == "2006_07"
merge 1:1 sex using `gdi05', nogenerate
nhdr_gdi_hdi, literacy(lit_reproduced) enrolment(ner_reproduced) life(le) income(pci) prefix(r_)
gsort sex
gen double r_gdi = r_hdi[1] / r_hdi[2]
display as text _n "Step 17: GDI 2006-07, education by sex reproduced from HIES 2005-06, against Table 6A"
list sex lit_reproduced lit ner_reproduced ner r_hdi pub_hdi r_gdi pub_gdi, noobs sep(0) abbreviate(12)
gen double _g = max(abs(lit_reproduced - lit), abs(ner_reproduced - ner))
quietly summarize _g
nhdr_check, label("Step 17 GDI 2006-07 literacy and enrolment by sex, worst of 4 [published]") ///
    got(`=r(max)') want(0) tol(0.05)
quietly summarize r_gdi
nhdr_check, label("Step 17 GDI 2006-07 on reproduced education [published 0.750]") ///
    got(`=r(mean)') want(0.750) tol(0.0006)
drop _g
export delimited using "$out/GDI 2006-07 reproduced.csv"

* ---- 20.4 The GII of 2006-07: prenatal and postnatal care, and schooling -------------
* (a) Care, section 4D, women with a birth in the last three years, the 18.2
*     rule: NC = average of the percentages without prenatal care (s4dq02 = 2)
*     and without postnatal care (s4dq11 = 2). Household weights.
use hhcode idc s4dq01 s4dq02 s4dq11 using "$h05/sec 4d.dta", clear
preserve
use hhcode province weight using `h05p', clear
bysort hhcode: keep if _n == 1
tempfile hw05
save `hw05'
restore
merge m:1 hhcode using `hw05', keep(master match) nogenerate
keep if s4dq01 == 1
gen double nopre  = (s4dq02 == 2) if !missing(s4dq02)
gen double nopost = (s4dq11 == 2) if !missing(s4dq11)
nhdr_by_province, vars(nopre nopost) wgt(weight) province(province)
gen double raw_no_care_f = 100 * (nopre + nopost) / 2
keep domain raw_no_care_f
tempfile nc05
save `nc05'
* (b) Primary or higher, persons 10 and over. In 2005-06 the rule that
*     reproduces Table 7A is class 5 passed (s2bq05 5 to 24), or attending
*     class 6 or above now. The 2018-19 questionnaire records the class
*     attended differently, which is why Section 18 counts class 5 there.
use `h05p', clear
keep if age >= 10 & !missing(age)
gen double prim = inrange(s2bq05, 5, 24) | (s2bq01 == 3 & inrange(s2bq14, 6, 24))
gen double prim_f = prim if s1aq03 == 2
gen double prim_m = prim if s1aq03 == 1
nhdr_by_province, vars(prim_f prim_m) wgt(weight) province(province)
gen double raw_sec_f = 100 * prim_f
gen double raw_sec_m = 100 * prim_m
keep domain raw_sec_f raw_sec_m
merge 1:1 domain using `nc05', nogenerate
gen str7 year = "2006_07"
merge 1:1 domain year using `t7', keep(master match) nogenerate
display as text _n "Step 17: GII inputs 2006-07 reproduced from HIES 2005-06, against Table 7A"
list domain raw_no_care_f no_care_f raw_sec_f sec_f raw_sec_m sec_m, noobs sep(0) abbreviate(14)
* Table 7A prints whole percentages for all three, so 0.55 is a match.
gen double _a = abs(raw_no_care_f - no_care_f)
quietly summarize _a
nhdr_check, label("Step 17 no prenatal/postnatal care 2006-07, worst of 5 domains [published]") ///
    got(`=r(max)') want(0) tol(0.55)
replace _a = max(abs(raw_sec_f - sec_f), abs(raw_sec_m - sec_m))
quietly summarize _a
nhdr_check, label("Step 17 primary or higher 2006-07, worst of 10 cells [published]") ///
    got(`=r(max)') want(0) tol(0.65)
drop _a
* The GII of 2006-07 with the two survey inputs reproduced and NHDR's other
* inputs (ever married, seats, participation) as printed. Section 18 and the
* technical note explain why those three are not reproduced: no survey tested
* reproduces NHDR's ever-married column, and its participation rates are
* not those of LFS 2006-07 (Section 18 and the technical note).
nhdr_gii, nocare(raw_no_care_f) evmarried(evm1519_f) seatf(seats_f) seatm(seats_m) ///
    secf(raw_sec_f) secm(raw_sec_m) lfprf(lfpr_f) lfprm(lfpr_m) prefix(r_)
gen double _g = abs(r_gii - pub_gii)
list domain r_gii pub_gii _g, noobs sep(0)
quietly summarize _g
nhdr_check, label("Step 17 GII 2006-07 on reproduced care and schooling, worst of 5 [published]") ///
    got(`=r(max)') want(0) tol(0.002)
drop _g
export delimited using "$out/GII 2006-07 reproduced.csv"

* ---- 20.5 The IHDI of 2006-07 from the microdata ----------------------------------
* The 16.2 construction applied to the first year:
*   education  quintile literacy and enrolment reproduced in 20.2
*   income     HIES 2005-06 consumption per head by consumption quintile.
*              HIES 2005-06 has no household income aggregate in 6. Raw data, so
*              the shape of the income distribution is proxied by
*              consumption. On 2018-19 the two give Atkinson values of
*              0.144 and 0.140 (Section 16.2).
*   health     NHDR's quintile life expectancy for 2006-07 (Table 2A), and
*              in 20.5b the PDHS 2006-07 gradient from Section 8A.
use `stacked05', clear
keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
drop if missing(q)
collapse (mean) lit15 ner cons=pc_exp [aw=weight], by(domain q)
gen double edu_raw = (2/3) * lit15 + (1/3) * ner
preserve
use `t2a', clear
drop if quintile == "All"
gen byte q = real(substr(quintile, 2, 1))
keep domain q le_2006_07
tempfile qle05
save `qle05'
restore
merge 1:1 domain q using `qle05', keep(master match) nogenerate
nhdr_atkinson edu_raw cons le_2006_07, by(domain) prefix(a_)
collapse (first) a_*, by(domain)
merge 1:1 domain using `hdi5', keepusing(hdi_2006_07) nogenerate
merge 1:1 domain using `t3', keepusing(pub_ihdi_2006_07 pub_loss_2006_07 pub_aedu_2006_07 ///
    pub_ahealth_2006_07 pub_ainc_2006_07) nogenerate
gen double ihdi_raw_2006_07 = hdi_2006_07 * ((1 - a_edu_raw) * (1 - a_le_2006_07) * (1 - a_cons))^(1/3)
gen double loss_raw_2006_07 = 100 * (1 - ihdi_raw_2006_07 / hdi_2006_07)
display as text _n "Step 17: IHDI 2006-07 reproduced from HIES 2005-06, against Table 3"
list domain ihdi_raw_2006_07 pub_ihdi_2006_07 a_edu_raw pub_aedu_2006_07 a_cons pub_ainc_2006_07, ///
    noobs sep(0) abbreviate(14)
gen double _g = abs(ihdi_raw_2006_07 - pub_ihdi_2006_07)
quietly summarize _g
nhdr_check, label("Step 17 IHDI 2006-07 from microdata, worst |gap| of 5 domains [reference 0.0096]") ///
    got(`=r(max)') want(0.0096) tol(0.002)
quietly summarize ihdi_raw_2006_07 if domain == "Pakistan"
nhdr_check, label("Step 17 IHDI Pakistan 2006-07 from microdata [published 0.491]") ///
    got(`=r(mean)') want(0.491) tol(0.003)
drop _g
export delimited using "$out/IHDI 2006-07 microdata.csv"

* ---- 20.5b The 2006-07 IHDI with the health gradient from PDHS 2006-07 -------
tempfile i06m
save `i06m'
use `pd_wq', clear
keep if round == "2006_07"
keep domain q le_pdhs
nhdr_atkinson le_pdhs, by(domain) prefix(a_)
collapse (first) a_le_pdhs, by(domain)
merge 1:1 domain using `i06m', nogenerate
gen double ihdi_pdhs_2006_07 = hdi_2006_07 * ((1 - a_edu_raw) * (1 - a_le_pdhs) * (1 - a_cons))^(1/3)
gen double loss_pdhs_2006_07 = 100 * (1 - ihdi_pdhs_2006_07 / hdi_2006_07)
display as text _n "Step 17: IHDI 2006-07 from HIES 2005-06, health from PDHS 2006-07, against Table 3"
list domain a_le_pdhs a_le_2006_07 pub_ahealth_2006_07 ihdi_pdhs_2006_07 ihdi_raw_2006_07 pub_ihdi_2006_07, ///
    noobs sep(0) abbreviate(14)
gen double _g = abs(ihdi_pdhs_2006_07 - pub_ihdi_2006_07)
quietly summarize _g
nhdr_check, label("Step 17 IHDI 2006-07, microdata with PDHS health, worst |gap| of 5 [published]") ///
    got(`=r(max)') want(0) tol(0.012)
drop _g
export delimited using "$out/IHDI 2006-07 PDHS.csv"

* ---- 20.6 The HDI and IHDI with every dimension from the microdata -----------
* Sections 5 to 16 reproduce the education inputs of Tables 1, 2A and 3 from
* HIES, and recover NHDR's life expectancy and income per head from its own
* printed indices. This section replaces those two recovered inputs with
* survey values as well, so that every number in Tables 1, 2A and 3 has a
* microdata counterpart, for the 15 domains and their consumption quintiles.
*   education  literacy 15+ and level-matched net enrolment 5-14, HIES
*              (Sections 4 and 20.2), unchanged
*   health     life expectancy at birth from PDHS under-five mortality,
*              ten years before the survey, DHS synthetic cohort (8A.1),
*              read through the Coale-Demeny West family (1.5). PDHS 2017-18
*              for 2018-19, PDHS 2006-07 for 2006-07. Domains are the PDHS
*              regions and v025 urban/rural. Quintile rows use the PDHS
*              wealth quintile v190, the only ranking PDHS carries.
*   income     HIES consumption per head (2018-19 sec_12ce t_exp, 2005-06
*              the sec6abcd aggregate of 20.1), person weighted, scaled so
*              that Pakistan equals the World Bank GNI per head in PPP
*              dollars (current international $, NY.GNP.PCAP.PP.CD), the
*              average of the two calendar years of the survey's fiscal
*              year. NHDR's 2018-19 control (4,922) equals that average for
*              2018 and 2019 (4,925). Its 2006-07 control (4,135) matches no
*              year of the series (2005 and 2006 average 3,350), so the
*              series is used in every year, including the intermediate
*              years of Section 26A. The relativities across domains and
*              quintiles are the survey's.
* Three cumulative versions of each HDI show which input moves the result:
*   hdi_e    microdata education, NHDR life expectancy and income
*   hdi_eh   microdata education and life expectancy, NHDR income
*   hdi_ehi  every dimension from the microdata
capture program drop nhdr_pdhs_le_domains
program define nhdr_pdhs_le_domains
    syntax using/
    use v005 v008 v024 v025 v190 b3 b4 b5 b7 using `"`using'"', clear
    nhdr_pdhs_region v024, generate(prov)
    drop if inlist(prov, "Gilgit-Baltistan", "AJK", "")
    gen str5 area = cond(v025 == 1, "Urban", cond(v025 == 2, "Rural", ""))
    gen long _id = _n
    expand 4
    bysort _id: gen byte _c = _n
    gen str30 domain = ""
    replace domain = "Pakistan"              if _c == 1
    replace domain = "Pakistan-" + area      if _c == 2 & area != ""
    replace domain = prov                    if _c == 3 & inlist(prov, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    replace domain = prov + "-" + area       if _c == 4 & area != "" & ///
        inlist(prov, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    drop if domain == ""
    drop _id _c
    tempfile pdst pdall
    save `pdst'
    nhdr_q5_dhs, months(120) by(domain)
    gen byte q = 0
    save `pdall'
    use `pdst', clear
    drop if missing(v190)
    nhdr_q5_dhs, months(120) by(domain v190)
    rename v190 q
    append using `pdall'
    nhdr_le_from_q5 u5mr_per_1000, generate(le_pdhs) family(west)
    gen str3 quintile = cond(q == 0, "All", "Q" + string(q))
    keep domain quintile u5mr_per_1000 le_pdhs births
end

import delimited using "$pub/WDI Pakistan.csv", clear varnames(1) asdouble encoding(utf-8) ///
    stringcols(1 2)
keep if indicator_code == "NY.GNP.PCAP.PP.CD"
foreach y in 2005 2006 2011 2012 2015 2016 2018 2019 {
    quietly summarize value if year == `y'
    scalar gni`y' = r(mean)
}
scalar gnify_2006_07 = (gni2005 + gni2006) / 2
scalar gnify_2012_13 = (gni2011 + gni2012) / 2
scalar gnify_2015_16 = (gni2015 + gni2016) / 2
scalar gnify_2018_19 = (gni2018 + gni2019) / 2
display as text "  WDI GNI per head PPP, fiscal-year averages: 2006-07 " as result %6.0f gnify_2006_07 ///
    as text ", 2012-13 " as result %6.0f gnify_2012_13 as text ", 2015-16 " as result %6.0f gnify_2015_16 ///
    as text ", 2018-19 " as result %6.0f gnify_2018_19
nhdr_check, label("Step 17 WDI GNI PPP 2018-19 fiscal average against NHDR's control, percent [published 4922]") ///
    got(`=100 * abs(gnify_2018_19 - 4922) / 4922') want(0) tol(0.1)
tempfile hdim
local first = 1
foreach spec in "2018_19|$pd17/PKBR71DT/PKBR71FL.DTA|stacked|weights|edu1819|`=gnify_2018_19'" ///
    "2006_07|$pd06/PKBR53DT/PKBR53FL.DTA|stacked05|weight|edu0506|`=gnify_2006_07'" {
    tokenize "`spec'", parse("|")
    local yr `1'
    local pdf `3'
    local st `5'
    local wv `7'
    local ed `9'
    local pcipub `11'
    * Health
    nhdr_pdhs_le_domains using "`pdf'"
    tempfile le_`yr'
    save `le_`yr''
    * Income
    use ``st'', clear
    collapse (mean) cons=pc_exp [aw=`wv'], by(domain)
    gen str3 quintile = "All"
    tempfile in_`yr'
    save `in_`yr''
    use ``st'', clear
    drop if missing(q)
    collapse (mean) cons=pc_exp [aw=`wv'], by(domain q)
    gen str3 quintile = "Q" + string(q)
    drop q
    append using `in_`yr''
    quietly summarize cons if domain == "Pakistan" & quintile == "All"
    gen double pci_micro = cons * `pcipub' / r(mean)
    * Education, and the published inputs of the same year
    merge 1:1 domain quintile using ``ed'', keepusing(lit_reproduced ner_reproduced) nogenerate
    merge 1:1 domain quintile using `le_`yr'', keep(master match) nogenerate
    merge 1:1 domain quintile using `t2a', keepusing(lit_`yr' ner_`yr' le_`yr' pci_`yr') ///
        keep(master match) nogenerate
    rename (lit_`yr' ner_`yr' le_`yr' pci_`yr') (lit_pub ner_pub le_pub pci_pub)
    nhdr_index, literacy(lit_pub) enrolment(ner_pub) life(le_pub) income(pci_pub) prefix(p_)
    nhdr_index, literacy(lit_reproduced) enrolment(ner_reproduced) life(le_pub) income(pci_pub) prefix(e_)
    nhdr_index, literacy(lit_reproduced) enrolment(ner_reproduced) life(le_pdhs) income(pci_pub) prefix(eh_)
    nhdr_index, literacy(lit_reproduced) enrolment(ner_reproduced) life(le_pdhs) income(pci_micro) prefix(m_)
    gen str7 year = subinstr("`yr'", "_", "-", .)
    if `first' == 0 append using `hdim'
    save `hdim', replace
    local first = 0
}
use `hdim', clear
order year domain quintile lit_reproduced lit_pub ner_reproduced ner_pub le_pdhs le_pub u5mr_per_1000 births ///
    pci_micro pci_pub cons m_education_index p_education_index m_health_index p_health_index ///
    m_income_index p_income_index e_hdi eh_hdi m_hdi p_hdi m_classification p_classification
rename (e_hdi eh_hdi m_hdi) (hdi_e hdi_eh hdi_ehi)
sort year domain quintile
display as text _n "Step 17: the HDI with every dimension from the microdata, domain totals"
list year domain hdi_ehi p_hdi hdi_e hdi_eh le_pdhs le_pub pci_micro pci_pub if quintile == "All", ///
    noobs sepby(year) abbreviate(10)
quietly count if !missing(hdi_ehi)
nhdr_check, label("Step 17 HDI all-microdata cells, 15 domains x 6 rows x 2 years [180]") ///
    got(`=r(N)') want(180) tol(0)
quietly summarize p_hdi if domain == "Pakistan" & quintile == "All" & year == "2018-19"
nhdr_check, label("Step 17 HDI from Table 2A inputs, Pakistan 2018-19 [published 0.570]") ///
    got(`=r(mean)') want(0.570) tol(0.0015)
gen double _g = abs(hdi_e - p_hdi)
quietly summarize _g if quintile == "All"
nhdr_check, label("Step 17 HDI with microdata education only, worst |gap| of 30 domain totals [published]") ///
    got(`=r(max)') want(0) tol(0.003)
drop _g
save "$out/HDI all microdata.dta", replace
export delimited using "$out/HDI all microdata.csv", replace
tempfile hdiall
save `hdiall'

* The IHDI on the same basis, Table 3 domains: the Atkinson index over the
* five quintile values of the education index, life expectancy and income.
use `hdiall', clear
keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan") & quintile != "All"
nhdr_atkinson m_education_index le_pdhs pci_micro, by(year domain) prefix(a_)
collapse (first) a_m_education_index a_le_pdhs a_pci_micro, by(year domain)
rename (a_m_education_index a_le_pdhs a_pci_micro) (a_edu_m a_health_m a_inc_m)
tempfile ia
save `ia'
* The domain HDI is the All row.
use `hdiall', clear
keep if quintile == "All"
keep year domain hdi_ehi
merge 1:1 year domain using `ia', keep(using match) nogenerate
gen double ihdi_m = hdi_ehi * ((1 - a_edu_m) * (1 - a_health_m) * (1 - a_inc_m))^(1/3)
gen double chi_m  = 100 * (a_edu_m + a_health_m + a_inc_m) / 3
gen double loss_m = 100 * (1 - ihdi_m / hdi_ehi)
merge m:1 domain using `t3', keep(master match) nogenerate
gen double pub_ihdi = cond(year == "2018-19", pub_ihdi_2018_19, pub_ihdi_2006_07)
gen double pub_loss = cond(year == "2018-19", pub_loss_2018_19, pub_loss_2006_07)
gen double pub_hdi  = cond(year == "2018-19", pub_hdi_2018_19, pub_hdi_2006_07)
keep year domain hdi_ehi pub_hdi ihdi_m pub_ihdi chi_m loss_m pub_loss a_edu_m a_health_m a_inc_m
order year domain hdi_ehi pub_hdi ihdi_m pub_ihdi loss_m pub_loss chi_m a_edu_m a_health_m a_inc_m
sort year domain
display as text _n "Step 17: the IHDI with every dimension from the microdata, against Table 3"
list, noobs sepby(year) abbreviate(10)
quietly count if !missing(ihdi_m)
nhdr_check, label("Step 17 IHDI all-microdata, 5 domains x 2 years [10]") got(`=r(N)') want(10) tol(0)
export delimited using "$out/IHDI all microdata.csv", replace

* ---- 20.7 The HDI with Pasha's provincial income per head ---------------------
* NHDR names its income source as "Pasha (2019) and HIES". Pasha (2019) is not
* public and is not in 6. Raw data. Two Pasha estimates are held, with
* provincial product per head (6. Raw data/Published/GRP published estimates.csv):
*   Pasha IPR 2015  constant 2005-06 prices, for 1999-2000, 2007-08, 2014-15
*   Pasha BR 2021   current factor cost, for 2018-19
* Each province's income per head relative to Pakistan is set to Pasha's
* relative (2007-08 for NHDR's 2006-07 column, 2018-19 for 2018-19, with IPR
* 2015's 2014-15 as a second 2018-19 variant). HIES keeps the split within a
* province (urban, rural, quintiles); the Pakistan rows stay as they are.
*   pci_pasha     the national level of 20.6 (WDI), Pasha's provincial pattern
*   pci_pasha_nl  NHDR's national level (4,135 and 4,922), Pasha's pattern
* hdi_pasha_nl uses microdata education and NHDR's own life expectancy, so it
* differs from the published HDI only through the provincial income pattern.
* If Pasha's pattern were NHDR's, hdi_pasha_nl would match Table 1.
import delimited using "$pub/GRP published estimates.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 3 4)
keep if (source == "Pasha IPR 2015" & inlist(year, "2007-08", "2014-15")) | ///
    (source == "Pasha BR 2021" & year == "2018-19")
bysort source year: egen double pak_pc = max(cond(province == "Pakistan", per_capita_rs, .))
gen double rel = per_capita_rs / pak_pc
drop if province == "Pakistan"
gen str12 key = cond(year == "2007-08", "y0607", cond(year == "2018-19", "y1819", "y1415"))
keep province key rel
reshape wide rel, i(province) j(key) string
rename province prov
tempfile pasharel
save `pasharel'

use `hdiall', clear
gen str20 prov = domain
replace prov = substr(domain, 1, strpos(domain, "-") - 1) if strpos(domain, "-")
merge m:1 prov using `pasharel', keep(master match) nogenerate
* Relatives as the survey and as NHDR print them, domain totals
bysort year: egen double c_pak = max(cond(domain == "Pakistan" & quintile == "All", cons, .))
bysort year prov: egen double c_prov = max(cond(domain == prov & quintile == "All", cons, .))
bysort year: egen double p_pak = max(cond(domain == "Pakistan" & quintile == "All", pci_pub, .))
bysort year prov: egen double p_prov = max(cond(domain == prov & quintile == "All", pci_pub, .))
bysort year: egen double m_pak = max(cond(domain == "Pakistan" & quintile == "All", pci_micro, .))
gen double rel_hies = c_prov / c_pak
gen double rel_nhdr = p_prov / p_pak
gen double rel_pasha = cond(year == "2006-07", rely0607, rely1819)
gen double rel_pasha_alt = cond(year == "2018-19", rely1415, .)
gen double pci_pasha     = cond(prov == "Pakistan", pci_micro, pci_micro * rel_pasha / rel_hies)
gen double pci_pasha_nl  = pci_pasha * p_pak / m_pak
gen double pci_pasha_alt = cond(prov == "Pakistan", pci_micro, pci_micro * rel_pasha_alt / rel_hies) * p_pak / m_pak
nhdr_index, literacy(lit_reproduced) enrolment(ner_reproduced) life(le_pub) income(pci_pasha_nl) prefix(px_)
nhdr_index, literacy(lit_reproduced) enrolment(ner_reproduced) life(le_pub) income(pci_pasha_alt) prefix(pxa_)
nhdr_index, literacy(lit_reproduced) enrolment(ner_reproduced) life(le_pdhs) income(pci_pasha) prefix(pa_)
rename (px_hdi pxa_hdi pa_hdi) (hdi_pasha_nl hdi_pasha_alt hdi_pasha)
replace hdi_pasha_alt = . if year != "2018-19"
keep year domain quintile prov rel_nhdr rel_hies rel_pasha rel_pasha_alt pci_pub pci_micro ///
    pci_pasha pci_pasha_nl pci_pasha_alt p_hdi hdi_e hdi_pasha_nl hdi_pasha_alt hdi_ehi hdi_pasha
order year domain quintile prov rel_nhdr rel_hies rel_pasha rel_pasha_alt pci_pub pci_micro ///
    pci_pasha_nl pci_pasha_alt pci_pasha p_hdi hdi_e hdi_pasha_nl hdi_pasha_alt hdi_ehi hdi_pasha
sort year domain quintile
display as text _n "Step 17: provincial income relative to Pakistan, NHDR against HIES and Pasha"
list year domain rel_nhdr rel_hies rel_pasha rel_pasha_alt if quintile == "All" & domain == prov & prov != "Pakistan", ///
    noobs sepby(year) abbreviate(12)
display as text _n "Step 17: the HDI with Pasha's provincial income, against Table 1"
list year domain p_hdi hdi_e hdi_pasha_nl hdi_pasha_alt hdi_ehi hdi_pasha if quintile == "All", ///
    noobs sepby(year) abbreviate(12)
quietly count if !missing(hdi_pasha_nl)
nhdr_check, label("Step 17 HDI with Pasha's provincial income, cells, 15 domains x 6 rows x 2 years [180]") ///
    got(`=r(N)') want(180) tol(0)
export delimited using "$out/HDI Pasha income.csv", replace



*==============================================================================*
* SECTION 21   MULTIDIMENSIONAL POVERTY INDEX (MPI) 2014-15 AND THE CHANGE TO 2019-20
*==============================================================================*
* The MPI Report 2019-20 compares 2019-20 with 2014-15 on a harmonized
* measure: the 2014-15 indicator set as it can be built on both PSLM rounds,
* on the districts surveyed in both. Chapter 3 of the report publishes the
* harmonized values (Tables 2 to 6) but not district values for 2014-15.
* Here the 2014-15 measure is reproduced from PSLM 2014-15, checked against
* those tables, and set beside the 2019-20 measure of Section 19 on the same
* districts, so that the change can be read at every level including the
* district.
* Source    PBS, PSLM 2014-15 microdata (78,635 households)
*             plist.dta   hhcode, province, region, district, idc, sbq04
*                         sex, age, weight
*             sec_c.dta   scq04 highest class completed, scq05 attending
*                         (1 yes), scq91, scq92 reasons for never attending
*                         or leaving
*             sec_a.dta   int_month, int_year of the interview
*             sec_h.dta   children under five: yr, mon of birth, shq6a to
*                         shq6l vaccinations (1 card, 2 recall, 4 campaign)
*             sec_i.dta   siq01 birth in the last three years, siq02
*                         prenatal consultation, siq09 who assisted delivery
*             sec_g.dta   housing: sgq02 rooms, sgq04 walls, sgq05 water,
*                         sgq06 toilet, sgq07 cooking fuel, sgq08 lighting,
*                         sgq09 telephone, sgq10_11 time to water
*             sec_f2.dta  sf2q11a to sf2q11q household assets (1 owns)
*             sec_f1.dta  land and livestock: itc item, sf1c01 owns, sf1c02
*                         quantity, sf1c04 irrigated
* Indicators as in Section 19, with the report's harmonized definitions:
*   years of schooling  no man OR no woman 10+ has completed class 5
*   attendance          any child 6 to 11 not attending
*   quality             any child 4 to 15 never enrolled or left because too
*                       expensive, too far, poor teaching, or no female or
*                       male teacher (scq91, scq92 codes 1 2 3 7 8). Section J
*                       is dropped, as in the report, because its 2019-20
*                       question changed.
*   immunization        any child 1 to 4 missing BCG, DPT 1-3, OPV 1-3 or
*                       measles, or any child under one missing BCG. Age in
*                       completed years from month and year of birth against
*                       the interview date (a birth month of 0 is taken as
*                       June).
*   antenatal care, assisted delivery, and the living standard indicators
*                       as in Section 19. The health facility access
*                       indicator of the 2016 report is not in the
*                       harmonized measure, and the three health indicators
*                       carry 1/9 each.
* Comparable districts (report, Section 2.3): the merged tribal districts and
* Kech were outside the 2014-15 frame, and Chagai, Jhal Magsi, Musakhel and Zhob
* were not surveyed in 2019-20. The three districts created after 2015 are
* folded back into their 2014-15 parents, and the six Karachi districts of
* 2019-20 into Karachi. The crosswalk is 6. Raw data/Published/
* PSLM district crosswalk 2014-15 2019-20.csv.
* Result    2014-15: national MPI 0.162 against 0.162, H 32.8 against 32.8,
*           every province and area within 0.3 points of H

* ---- 21.1 Households -------------------------------------------------------------------
use hhcode province region district idc sbq04 age weight using "$p14/plist.dta", clear
tempfile p14p
save `p14p'
bysort hhcode: gen int hhsize = _N
by hhcode: keep if _n == 1
keep hhcode province region district hhsize weight
tempfile p14hh
save `p14hh'

* ---- 21.2 Education deprivations -------------------------------------------------------
use `p14p', clear
merge 1:1 hhcode idc using "$p14/sec_c.dta", keepusing(scq04 scq05 scq91 scq92) ///
    keep(master match) nogenerate
gen byte done5 = inrange(scq04, 5, 19)
gen byte m_done = done5 if sbq04 == 1 & age >= 10 & !missing(age)
gen byte f_done = done5 if sbq04 == 2 & age >= 10 & !missing(age)
gen byte att_dep  = (scq05 != 1) if inrange(age, 6, 11)
gen byte qual_dep = inlist(scq91, 1, 2, 3, 7, 8) | inlist(scq92, 1, 2, 3, 7, 8) if inrange(age, 4, 15)
collapse (max) m_done f_done att_dep qual_dep, by(hhcode)
gen byte d_yos  = (m_done != 1) | (f_done != 1)
gen byte d_att  = (att_dep == 1)
gen byte d_qual = (qual_dep == 1)
keep hhcode d_yos d_att d_qual
tempfile d14edu
save `d14edu'

* ---- 21.3 Health deprivations ------------------------------------------------------------
use hhcode int_month int_year using "$p14/sec_a.dta", clear
bysort hhcode: keep if _n == 1
tempfile p14int
save `p14int'
use hhcode yr mon shq6a shq6b shq6c shq6d shq6e shq6f shq6g shq6h shq6i shq6j shq6k ///
    using "$p14/sec_h.dta", clear
merge m:1 hhcode using `p14int', keep(master match) nogenerate
gen int by_ = 2000 + yr
gen int bm_ = cond(mon == 0, 6, mon)
gen double agem = (int_year - by_) * 12 + (int_month - bm_)
gen double agey = floor(agem / 12)
foreach v in a b c d e f g h i j k {
    gen byte got_`v' = inlist(shq6`v', 1, 2, 4)
}
gen byte full = got_a & got_b & got_c & got_d & got_e & got_f & got_g & got_k
gen byte imm_dep = (inrange(agey, 1, 4) & !full) | (agey == 0 & !got_a)
collapse (max) imm_dep, by(hhcode)
rename imm_dep d_imm
tempfile d14imm
save `d14imm'
use hhcode siq01 siq02 siq09 using "$p14/sec_i.dta", clear
keep if siq01 == 1
gen byte d_anc = (siq02 == 2)
gen byte d_del = inlist(siq09, 1, 3, 9)
collapse (max) d_anc d_del, by(hhcode)
tempfile d14mat
save `d14mat'

* ---- 21.4 Living standard deprivations ---------------------------------------------------
use hhcode sgq02 sgq04 sgq05 sgq06 sgq07 sgq08 sgq09 sgq10_11 using "$p14/sec_g.dta", clear
bysort hhcode: keep if _n == 1
tempfile p14g
save `p14g'
use hhcode sf2q11a sf2q11b sf2q11c sf2q11d sf2q11e sf2q11f sf2q11g sf2q11h sf2q11i sf2q11j sf2q11k sf2q11l sf2q11m sf2q11n sf2q11o sf2q11p sf2q11q using "$p14/sec_f2.dta", clear
bysort hhcode: keep if _n == 1
tempfile p14f2
save `p14f2'
use hhcode itc sf1c01 sf1c02 sf1c04 using "$p14/sec_f1.dta", clear
keep if sf1c01 == 1
gen double irr     = sf1c02 if itc == 1 & sf1c04 == 1
gen double rain    = sf1c02 if itc == 1 & sf1c04 != 1
gen double cattle  = sf1c02 if itc == 4
gen double goats   = sf1c02 if itc == 5
gen double draught = sf1c02 if itc == 6
gen double poultry = sf1c02 if itc == 7
collapse (sum) irr rain cattle goats draught poultry, by(hhcode)
tempfile p14ll
save `p14ll'

use `p14hh', clear
foreach f in d14edu d14imm d14mat p14g p14f2 p14ll {
    merge 1:1 hhcode using ``f'', keep(master match) nogenerate
}
foreach v in d_yos d_att d_qual d_imm d_anc d_del irr rain cattle goats draught poultry {
    replace `v' = 0 if missing(`v')
}
* As in Section 19, a missing housing record counts as deprived where the
* indicator is a "not improved" test.
gen byte d_water = !inlist(sgq05, 1, 2, 3, 4, 8, 9) | inlist(sgq10_11, 3, 4, 5)
gen byte d_san   = !inlist(sgq06, 2, 3, 4)
gen byte d_walls = inlist(sgq04, 2, 3, 5)
gen byte d_crowd = (sgq02 == 0) | ((hhsize / sgq02) >= 4 & !missing(sgq02) & sgq02 > 0)
gen byte d_elec  = (sgq08 != 1)
gen byte d_fuel  = inlist(sgq07, 1, 4, 6, 7, 8)
foreach k in a b c d e f g h i j k l m n o p q {
    gen byte y_`k' = (sf2q11`k' == 1)
}
gen byte small = y_d + y_g + y_a + y_b + y_c + y_h + y_e + y_f + y_j + y_m + inlist(sgq09, 2, 4)
gen byte large = y_i | y_k | y_p | y_l | y_n
gen byte d_assets = ((small <= 2) | !large) & !y_o
gen byte d_landlive = (rain < 2.25) & (irr < 1.125) & (cattle < 2) & (goats < 3) & ///
    (poultry < 5) & (draught < 1) & region == 1
gen double c = (1/6) * d_yos + (1/8) * d_att + (1/24) * d_qual ///
    + (1/9) * (d_imm + d_anc + d_del) ///
    + (1/21) * (d_water + d_san + d_elec + d_fuel + d_assets + d_landlive) ///
    + (1/42) * (d_walls + d_crowd)
gen byte poor = (c >= 1/3 - 1e-9)
gen double pop_w = weight * hhsize
gen double c_poor = c if poor
gen str20 province_name = ""
replace province_name = "Khyber Pakhtunkhwa" if province == 1
replace province_name = "Punjab"             if province == 2
replace province_name = "Sindh"              if province == 3
replace province_name = "Balochistan"        if province == 4
replace province_name = "Islamabad"          if province == 6
tempfile mpi14hh
save `mpi14hh'

* ---- 21.5 National, rural-urban and provincial, against Tables 2 to 6 ----------------------
import delimited using "$pub/MPI 2014-15 harmonized published.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 3)
tempfile mpi14pub
save `mpi14pub'
use `mpi14hh', clear
nhdr_mpi_by
gen str30 area = "Pakistan"
tempfile m14
save `m14'
use `mpi14hh', clear
gen str30 area = cond(region == 1, "Rural", "Urban")
nhdr_mpi_by, by(area)
append using `m14'
save `m14', replace
use `mpi14hh', clear
keep if inrange(province, 1, 4)
rename province_name area
nhdr_mpi_by, by(area)
append using `m14'
save `m14', replace
use `mpi14hh', clear
keep if inrange(province, 1, 4)
gen str30 area = province_name + cond(region == 1, "-Rural", "-Urban")
nhdr_mpi_by, by(area)
append using `m14'
gen str7 year = "2014_15"
merge 1:1 area year using `mpi14pub', keepusing(mpi h a) keep(master match) nogenerate
display as text _n "Step 18: MPI 2014-15, harmonized measure, against the MPI Report 2019-20, Tables 2 to 6"
list area MPI mpi H h A a, noobs sep(0) abbreviate(20)
gen double _gm = abs(MPI - mpi)
gen double _gh = abs(H - h)
gen double _ga = abs(A - a)
quietly summarize MPI if area == "Pakistan"
nhdr_check, label("Step 18 MPI 2014-15, Pakistan [published 0.162]") got(`=r(mean)') want(0.162) tol(0.0015)
quietly summarize H if area == "Pakistan"
nhdr_check, label("Step 18 headcount H 2014-15, Pakistan [published 32.8]") got(`=r(mean)') want(32.8) tol(0.15)
quietly summarize _gm if !inlist(area, "Pakistan")
nhdr_check, label("Step 18 MPI 2014-15, worst of 14 areas and provinces, |gap| [published]") ///
    got(`=r(max)') want(0) tol(0.004)
quietly summarize _gh
nhdr_check, label("Step 18 headcount 2014-15, worst of 15, |gap| points [published]") ///
    got(`=r(max)') want(0) tol(0.8)
quietly summarize _ga
nhdr_check, label("Step 18 intensity 2014-15, worst of 15, |gap| points [published]") ///
    got(`=r(max)') want(0) tol(0.8)
drop _gm _gh _ga
tempfile mpi14res
save `mpi14res'
export delimited using "$out/MPI 2014-15 national provincial.csv"

* ---- 21.6 The harmonized 2019-20 measure and the change -------------------------------------
* The 2019-20 households of Section 19, restricted to the districts surveyed
* in both rounds.
import delimited using "$pub/PSLM district crosswalk 2014-15 2019-20.csv", clear varnames(1) ///
    asdouble encoding(utf-8) stringcols(2 4 5)
rename district_2019_20 district
keep district district_2014_15
tempfile xw
save `xw'
use `mpihh2', clear
merge m:1 district using `xw', keep(master match) nogenerate
drop if missing(district_2014_15)
tempfile mpi19h
save `mpi19h'
nhdr_mpi_by
gen str30 area = "Pakistan"
tempfile m19
save `m19'
use `mpi19h', clear
gen str30 area = cond(region == 1, "Rural", "Urban")
nhdr_mpi_by, by(area)
append using `m19'
save `m19', replace
use `mpi19h', clear
rename province_name area
nhdr_mpi_by, by(area)
append using `m19'
save `m19', replace
use `mpi19h', clear
gen str30 area = province_name + cond(region == 1, "-Rural", "-Urban")
nhdr_mpi_by, by(area)
append using `m19'
gen str7 year = "2019_20"
merge 1:1 area year using `mpi14pub', keepusing(mpi h a) keep(master match) nogenerate
display as text _n "Step 18: MPI 2019-20 on the comparable districts, against the report's harmonized values"
list area MPI mpi H h A a, noobs sep(0) abbreviate(20)
quietly summarize MPI if area == "Pakistan"
nhdr_check, label("Step 18 MPI 2019-20 harmonized, Pakistan [published 0.141]") got(`=r(mean)') want(0.141) tol(0.003)
quietly summarize H if area == "Pakistan"
nhdr_check, label("Step 18 headcount 2019-20 harmonized, Pakistan [published 29.6]") got(`=r(mean)') want(29.6) tol(0.6)
gen double _gh = abs(H - h)
quietly summarize _gh
nhdr_check, label("Step 18 headcount 2019-20 harmonized, worst of 15, |gap| points [published]") ///
    got(`=r(max)') want(0) tol(1.2)
drop _gh
rename (MPI H A pop mpi h a) (MPI_19 H_19 A_19 pop_19 pub_mpi_19 pub_h_19 pub_a_19)
drop year
merge 1:1 area using `mpi14res', keepusing(MPI H A pop mpi h a) nogenerate
rename (MPI H A pop mpi h a) (MPI_14 H_14 A_14 pop_14 pub_mpi_14 pub_h_14 pub_a_14)
gen double d_MPI = MPI_19 - MPI_14
gen double d_H   = H_19 - H_14
gen double d_A   = A_19 - A_14
gen double pub_d_mpi = pub_mpi_19 - pub_mpi_14
display as text _n "Step 18: change in the harmonized MPI, 2014-15 to 2019-20"
list area MPI_14 MPI_19 d_MPI pub_d_mpi H_14 H_19 d_H, noobs sep(0) abbreviate(12)
quietly summarize d_MPI if area == "Pakistan"
nhdr_check, label("Step 18 change in MPI, Pakistan, 2014-15 to 2019-20 [published -0.021]") ///
    got(`=r(mean)') want(-0.021) tol(0.004)
export delimited using "$out/MPI change 2014-15 2019-20.csv"

* ---- 21.7 Districts: the change the report does not tabulate --------------------------------
* District values from person-level data in each round, on the 2014-15
* district map.
use `mpi14hh', clear
keep if inrange(province, 1, 4) | province == 6
rename district district_2014_15
nhdr_mpi_by, by(district_2014_15)
rename (MPI H A pop) (MPI_14 H_14 A_14 pop_14)
tempfile d14
save `d14'
use `mpi19h', clear
nhdr_mpi_by, by(district_2014_15)
rename (MPI H A pop) (MPI_19 H_19 A_19 pop_19)
merge 1:1 district_2014_15 using `d14', keep(match) nogenerate
preserve
use "$p14/plist.dta", clear
keep district province
bysort district: keep if _n == 1
decode district, generate(_dn)
gen str40 district_name = proper(_dn)
gen str20 province_name = ""
replace province_name = "Khyber Pakhtunkhwa" if province == 1
replace province_name = "Punjab"             if province == 2
replace province_name = "Sindh"              if province == 3
replace province_name = "Balochistan"        if province == 4
replace province_name = "Islamabad"          if province == 6
rename district district_2014_15
keep district_2014_15 district_name province_name
tempfile dn14
save `dn14'
restore
merge 1:1 district_2014_15 using `dn14', keep(master match) nogenerate
gen double d_MPI = MPI_19 - MPI_14
gen double d_H   = H_19 - H_14
gsort d_MPI
order province_name district_name MPI_14 MPI_19 d_MPI H_14 H_19 d_H A_14 A_19 pop_14 pop_19
display as text _n "Step 18: districts with the largest fall and the largest rise in the MPI"
list province_name district_name MPI_14 MPI_19 d_MPI H_14 H_19 in 1/8, noobs sep(0) abbreviate(12)
gsort -d_MPI
list province_name district_name MPI_14 MPI_19 d_MPI H_14 H_19 in 1/8, noobs sep(0) abbreviate(12)
quietly count
display as text "  districts compared: " as result r(N)
nhdr_check, label("Step 18 districts with both rounds [report: 110 change estimates]") ///
    got(`=r(N)') want(110) tol(2)
quietly count if d_MPI < 0
display as text "  districts where the MPI fell: " as result r(N)
export delimited using "$out/MPI change districts.csv"
save "$out/MPI change districts.dta"


*==============================================================================*
* SECTION 22   THE LABOUR FORCE SURVEY (LFS) ROUNDS, READ ON ONE BASIS
*==============================================================================*
* The CDI, YDI and LDI draw on the Labour Force Survey, and so does the GII.
* Three facts, established below, govern how NHDR used it:
*   1. What NHDR prints as "2018-19" for labor indicators is LFS 2017-18.
*      Section 18 showed this for the GII from PBS's published tables. Here
*      it is shown from the 2017-18 microdata, which PBS released in 2020.
*   2. NHDR's Punjab includes Islamabad Capital Territory. LFS 2017-18 codes
*      Islamabad as province 6, and adding it to Punjab reproduces every Punjab
*      cell of Tables 5A and 7A.
*   3. LFS weights of 2012-13 and 2017-18 do not sum to the population PBS
*      used for its absolute numbers (181.72 and 206.64 million). Quantities
*      that need counts, the labor income of Table 8A, use weights scaled to
*      those totals. Rates are unaffected. The LFS 2024-25 weights already sum
*      to the Census 2023-based population.
* Source    PBS, LFS 2012-13 (Stata), LFS 2017-18 (SPSS, released as
*           "LFS-2017-18-STATA.zip"), LFS 2024-25 (Stata)
* Common variables built for each round
*   prov      1 KP, 2 Punjab (with Islamabad), 3 Sindh, 4 Balochistan
*   sex, age, w (survey weight), ws (weight scaled to PBS population)
*   edu       highest level completed, PBS codes: 1 none, 2 nursery, 3 KG,
*             4 primary, 5 middle, 6 matric, 7 intermediate, 8 and above a
*             degree or higher
*   emp       employed, the PBS 13th ICLS definition of each round
*   act       economically active (employed or unemployed)
*   employee, selfemp, cfw   status in employment: paid employees
*             (including piece-rate, casual and apprentices), employers and
*             own-account workers (including owner cultivators, share
*             croppers and contract cultivators), contributing family workers
*   occ1      ISCO-08 major group of the main job
*   agri      main job in agriculture, forestry or fishing
*   hours     hours worked in the main job last week
*   wage      monthly earnings of paid employees: the monthly amount, or the
*             weekly amount x 52/12
*   formal    main job outside agriculture in government, a public
*             enterprise, a company, or an enterprise with 10 or more workers
*   ownuse    worked last week on own-account production of goods: crop or
*             livestock work, poultry, food processing, house construction,
*             fetching water or collecting firewood
*   mw        the minimum wage in force (Table 2 of Technical Note 8, and
*             the federal notification of July 2024)

import delimited using "$pub/LFS population minimum wage.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 5)
forvalues i = 1/`=_N' {
    local s = survey[`i']
    scalar pop_`s' = pbs_population_mn[`i'] * 1e6
    scalar mw_`s'  = minimum_wage_rs[`i']
}

* ---- 22.1 LFS 2017-18 ---------------------------------------------------------------------
import spss using "$lfs17/LFS 2017-18.sav", clear
keep PrCode S04C05 S04C06 S04C07 S04C09 S04C10 S05C02 S05C03 S05C04 S05C08 S05C09 S05C10 ///
    S05C11 S05C13 S05C171 S06C01 S07C033 S07C043 S09C01 S09C04 S09C06 ///
    S10C101 S10C102 S10C103 S10C104 S10C105 S10C106 S10C107 Weight
capture confirm string variable PrCode
if !_rc destring PrCode, replace force
gen byte prov = floor(PrCode / 1e9)
gen byte ict = (prov == 6)
replace prov = 2 if prov == 6
rename (S04C05 S04C06 S04C07 S04C09 Weight) (sex age marital edu w)
gen byte emp = (S05C02 == 1) | (S05C03 == 1) | inlist(S05C04, 1, 2)
gen byte act = emp | (S09C01 == 1) | inrange(S09C04, 1, 6) | inlist(S09C06, 1, 2, 3, 4)
gen byte employee = inlist(S05C08, 1, 2, 3, 4)
gen byte selfemp  = inrange(S05C08, 5, 10)
gen byte cfw      = inlist(S05C08, 11, 12)
gen byte occ1 = floor(S05C09 / 1000)
gen byte agri = (S05C10 < 400) if !missing(S05C10)
gen double hours = S05C171
gen double wage = cond(S07C043 > 0 & !missing(S07C043), S07C043, ///
    cond(S07C033 > 0 & !missing(S07C033), S07C033 * 52 / 12, .))
gen byte formal = (agri == 0) & (inrange(S05C11, 1, 7) | (S05C13 >= 10 & !missing(S05C13)))
gen byte ownuse = 0
foreach v in S10C101 S10C102 S10C103 S10C104 S10C105 S10C106 S10C107 {
    replace ownuse = 1 if `v' == 1
}
gen double mw = mw_lfs1718
quietly summarize w
gen double ws = w * pop_lfs1718 / r(sum)
keep prov ict sex age marital edu w ws emp act employee selfemp cfw occ1 agri hours wage formal ownuse mw
tempfile lfs1718
save `lfs1718'

* ---- 22.2 LFS 2012-13 ---------------------------------------------------------------------
* The Stata release stores most answers as text. They are converted, and a
* stray non-numeric entry becomes missing.
use Prcode s4_q5 s4_q6 s4_q9 s5_q2 s5_q3 s5_q4 s5_q8 s5_q9 s5_q10 s5_q11 s5_q13 s5_q17_1 ///
    s7_q3 s7_q4 s9_q1 s9_q4 s9_q6 Weights using "$lfs12/LFS-2012-13.dta", clear
foreach v of varlist _all {
    capture confirm string variable `v'
    if !_rc destring `v', replace force
}
gen byte prov = floor(Prcode / 1e8)
rename (s4_q5 s4_q6 s4_q9 Weights) (sex age edu w)
gen byte emp = (s5_q2 == 1) | (s5_q3 == 1) | inlist(s5_q4, 1, 2)
gen byte act = emp | (s9_q1 == 1) | inrange(s9_q4, 1, 6) | inlist(s9_q6, 1, 2, 3, 4)
gen byte employee = inlist(s5_q8, 1, 2, 3, 4)
gen byte selfemp  = inrange(s5_q8, 5, 9)
gen byte cfw      = (s5_q8 == 10)
gen byte occ1 = floor(s5_q9 / 10)
gen byte agri = inrange(s5_q10, 1, 3) if !missing(s5_q10)
gen double hours = s5_q17_1
gen double wage = cond(s7_q4 > 0 & !missing(s7_q4), s7_q4, ///
    cond(s7_q3 > 0 & !missing(s7_q3), s7_q3 * 52 / 12, .))
* s5_q13 records persons engaged in bands: 3 is 10 to 19, 4 is 20 or more.
gen byte formal = (agri == 0) & (inrange(s5_q11, 1, 7) | inlist(s5_q13, 3, 4))
gen double mw = mw_lfs1213
quietly summarize w
gen double ws = w * pop_lfs1213 / r(sum)
keep prov sex age edu w ws emp act employee selfemp cfw occ1 agri hours wage formal mw
tempfile lfs1213
save `lfs1213'
* Marital status for the 2012-13 GII (Section 26A), from the same file.
use s4_q7 using "$lfs12/LFS-2012-13.dta", clear
capture confirm string variable s4_q7
if !_rc destring s4_q7, replace force
rename s4_q7 marital
merge 1:1 _n using `lfs1213', nogenerate
save `lfs1213', replace

* ---- 22.2c LFS 2014-15 ---------------------------------------------------------------------
* NHDR's middle LDI year (Figures 4.4, 4.7, 4.15), and the 2015-16 points of
* Figures 4.9 to 4.11, since PBS ran no Labour Force Survey in 2015-16. The
* SPSS release names its fields by questionnaire section and column, and its
* codes follow the 2017-18 round: status 1-4 paid employees, 5-10 employers,
* own-account workers and cultivators, 11-12 contributing family workers;
* occupation four-digit ISCO-08, industry four-digit ISIC; province the first
* digit of PROCESS_CODE, 6 being Islamabad. SEC7_COL33 and SEC7_COL43 are the
* weekly and monthly totals (cash plus kind). new_weight, released in the
* same file, sums to the 189.19 million PBS used for absolute numbers.
import spss using "$lfs14/LFS-2014-15.sav", clear
keep PROCESS_CODE SEC4_COL5 SEC4_COL6 SEC4_COL7 SEC4_COL9 SEC5_COL2 SEC5_COL3 SEC5_COL4 ///
    SEC5_COL8 SEC5_COL9 SEC5_COL10 SEC5_COL11 SEC5_COL13 SEC5_COL17_1 SEC7_COL33 SEC7_COL43 ///
    SEC9_COL1 SEC9_COL4 SEC9_COL6 SEC10_COL_i11 SEC10_COL_ii11 SEC10_COL_iii11 SEC10_COL_iv11 ///
    SEC10_COL_v11 SEC10_COL_vi11 SEC10_COL_vii11 new_weight
capture confirm string variable PROCESS_CODE
if !_rc gen byte prov = real(substr(strtrim(PROCESS_CODE), 1, 1))
else gen byte prov = floor(PROCESS_CODE / 1e9)
gen byte ict = (prov == 6)
replace prov = 2 if prov == 6
rename (SEC4_COL5 SEC4_COL6 SEC4_COL7 SEC4_COL9 new_weight) (sex age marital edu w)
gen byte emp = (SEC5_COL2 == 1) | (SEC5_COL3 == 1) | inlist(SEC5_COL4, 1, 2)
gen byte act = emp | (SEC9_COL1 == 1) | inrange(SEC9_COL4, 1, 6) | inlist(SEC9_COL6, 1, 2, 3, 4)
gen byte employee = inlist(SEC5_COL8, 1, 2, 3, 4)
gen byte selfemp  = inrange(SEC5_COL8, 5, 10)
gen byte cfw      = inlist(SEC5_COL8, 11, 12)
gen byte occ1 = floor(SEC5_COL9 / 1000)
gen byte agri = (SEC5_COL10 < 400) if !missing(SEC5_COL10)
gen double hours = SEC5_COL17_1
gen double wage = cond(SEC7_COL43 > 0 & !missing(SEC7_COL43), SEC7_COL43, ///
    cond(SEC7_COL33 > 0 & !missing(SEC7_COL33), SEC7_COL33 * 52 / 12, .))
gen byte formal = (agri == 0) & (inrange(SEC5_COL11, 1, 7) | (SEC5_COL13 >= 10 & !missing(SEC5_COL13)))
gen byte ownuse = 0
foreach v in SEC10_COL_i11 SEC10_COL_ii11 SEC10_COL_iii11 SEC10_COL_iv11 SEC10_COL_v11 ///
    SEC10_COL_vi11 SEC10_COL_vii11 {
    replace ownuse = 1 if `v' == 1
}
gen double mw = mw_lfs1415
gen double ws = w
quietly summarize w
nhdr_check, label("Step 19 LFS 2014-15 new_weight sum, million [reference 189.19]") ///
    got(`=r(sum) / 1e6') want(189.19) tol(0.01)
keep prov ict sex age marital edu w ws emp act employee selfemp cfw occ1 agri hours wage formal ownuse mw
tempfile lfs1415
save `lfs1415'

* ---- 22.2d LFS 2006-07 ---------------------------------------------------------------------
* NHDR's source for the 2006-07 participation and early-marriage columns of
* Table 7A, and the round for 2006-07 earned income by sex (Section 26A).
* Stata reads the SPSS field names SECTION_<s>.<s>.<column> as _v1 to _v184,
* in file order: _v4 sex (4.4.5), _v5 age (4.4.6), _v6 marital status
* (4.4.7), _v18 to _v20 the three employment questions (5.5.2 to 5.5.4, as
* in later rounds), _v24 status in employment (5.5.8), _v50 and _v51 the
* weekly and monthly cash earnings of paid employees (7.7.2, 7.7.3), and
* _v113 the unemployment module (10.10.1: 1 to 5 seeking or available, 6
* neither). The employment questions select exactly the 65,111 persons asked
* the status question, and the earnings fields exactly the 25,056 paid
* employees, which fixes the reading. In-kind pay (7.7.4) is zero for 97
* percent of employees and is left out. Used at the national level only.
import spss using "$lfs06/lfs2006-07.sav", clear
keep _v4 _v5 _v6 _v18 _v19 _v20 _v24 _v50 _v51 _v113 weights
rename (_v4 _v5 _v6 _v24 weights) (sex age marital status w)
gen byte emp = (_v18 == 1) | (_v19 == 1) | inlist(_v20, 1, 2)
quietly count if emp == 1
nhdr_check, label("Step 19 LFS 2006-07 employed records, the status universe [65111]") ///
    got(`=r(N)') want(65111) tol(0)
gen byte act = emp | inrange(_v113, 1, 5)
gen byte employee = inlist(status, 1, 2, 3, 4)
gen double earn = .
replace earn = _v51 * 12 if _v51 > 0 & !missing(_v51)
replace earn = _v50 * 52 if missing(earn) & _v50 > 0 & !missing(_v50)
replace earn = . if employee != 1
keep sex age marital w emp act employee earn
tempfile lfs0607
save `lfs0607'

* ---- 22.3 LFS 2024-25 ---------------------------------------------------------------------
* Employment on the 13th ICLS basis, as in Section 17.4, so that it compares
* with the earlier rounds. Status codes of 2024-25: 1 employer, 2 independent
* worker, 3 employee, 4 contributing family worker, 5 paid apprentice,
* 6 dependent contractor. Occupation and industry carry four-digit codes, and
* a three-digit occupation code is an ISCO minor group with its leading zero
* lost, so its major group is the first digit.
use Province S4C5 S4C6 S4C7 S4C9 S5C1 S5C2 S5C3 S5C4 S5C8 S5C11 S5C12 S5C13 S5C15 S5C18 ///
    S5C24 S7C33 S7C43 S9C1 S9C6 S10C10_1a S10C10_2a S10C10_3a S10C10_6a S10C10_7a ///
    S10C10_9a S10C10_10a Weights using "$lfs24/LFS 2024-25.dta", clear
rename (Province S4C5 S4C6 S4C7 S4C9 Weights) (prov sex age marital edu w)
gen byte emp = (S5C1 == 1) | (S5C2 == 1) | (S5C3 == 1) | (S5C4 == 1) | inlist(S5C8, 1, 2, 3)
gen byte act = emp | ((S9C1 == 1) & (S9C6 == 1))
gen byte employee = inlist(S5C11, 3, 5)
gen byte selfemp  = inlist(S5C11, 1, 2, 6)
gen byte cfw      = (S5C11 == 4)
gen byte occ1 = cond(S5C12 >= 1000, floor(S5C12 / 1000), floor(S5C12 / 100)) if !missing(S5C12)
gen byte agri = (S5C13 < 400) if !missing(S5C13)
gen double hours = S5C24
gen double wage = cond(S7C43 > 0 & !missing(S7C43), S7C43, ///
    cond(S7C33 > 0 & !missing(S7C33), S7C33 * 52 / 12, .))
gen byte formal = (agri == 0) & (inrange(S5C15, 1, 8) | (S5C18 >= 10 & !missing(S5C18)))
gen byte ownuse = 0
foreach v in S10C10_1a S10C10_2a S10C10_3a S10C10_6a S10C10_7a S10C10_9a S10C10_10a {
    replace ownuse = 1 if `v' == 1
}
gen double mw = mw_lfs2425
gen double ws = w
keep prov sex age marital edu w ws emp act employee selfemp cfw occ1 agri hours wage formal ownuse mw
tempfile lfs2425
save `lfs2425'

* ---- 22.4 Participation: NHDR's "2018-19" column is LFS 2017-18 ----------------------------
use `lfs1718', clear
keep if age >= 10 & !missing(age)
gen double lf_f = act if sex == 2
gen double lf_m = act if sex == 1
gen double evm = inlist(marital, 2, 3, 4) if sex == 2 & inrange(age, 15, 19) & !missing(marital)
nhdr_by_province, vars(lf_f lf_m evm) wgt(w) province(prov)
gen double lfpr_f_1718 = 100 * lf_f
gen double lfpr_m_1718 = 100 * lf_m
gen double evm1519_f_1718 = 100 * evm
keep domain lfpr_f_1718 lfpr_m_1718 evm1519_f_1718
gen str7 year = "2018_19"
merge 1:1 domain year using `t7', keepusing(lfpr_f lfpr_m evm1519_f) keep(master match) nogenerate
display as text _n "Step 19: participation 10+ from the LFS 2017-18 microdata, against NHDR's 2018-19 column"
list domain lfpr_f_1718 lfpr_f lfpr_m_1718 lfpr_m evm1519_f_1718 evm1519_f, noobs sep(0) abbreviate(16)
gen double _a = max(abs(lfpr_f_1718 - lfpr_f), abs(lfpr_m_1718 - lfpr_m))
quietly summarize _a
nhdr_check, label("Step 19 LFPR, LFS 2017-18 microdata vs NHDR 2018-19, worst of 10 [published]") ///
    got(`=r(max)') want(0) tol(0.06)
drop _a
* Ever married at 15 to 19 on the same file: 12.6 percent, against NHDR's 20.0.
* The ever-married column of Table 7A therefore does not come from the LFS
* in either year (Section 18.2 tested 2018-19).
quietly summarize evm1519_f_1718 if domain == "Pakistan"
nhdr_check, label("Step 19 women 15-19 ever married, LFS 2017-18 [reference 12.61]") ///
    got(`=r(mean)') want(12.61) tol(0.05)
export delimited using "$out/LFS 2017-18 participation.csv"

* ---- 22.2b The 2018-19 GII with every survey input from the microdata -------
* NHDR's year for each input: prenatal and postnatal care (sec_4d s4dq01,
* s4dq2a, s4dq11a) and primary-or-higher schooling (sec_2ab s2bq05, s2bq14)
* from HIES 2018-19 (Section 18.2, raw_*), and participation and early
* marriage from LFS 2017-18 (above), NHDR's labour year. No survey in 6. Raw data
* reproduces NHDR's early-marriage rate of 20.0 percent: LFS 2017-18 gives
* 12.6 and LFS 2018-19 12.3. Parliamentary seats are administrative and stay
* as printed.
keep domain lfpr_f_1718 lfpr_m_1718 evm1519_f_1718
merge 1:1 domain using `gii18', keepusing(raw_no_care_f raw_sec_f raw_sec_m ///
    seats_f seats_m pub_gii no_care_f evm1519_f sec_f sec_m lfpr_f lfpr_m) nogenerate
nhdr_gii, nocare(raw_no_care_f) evmarried(evm1519_f_1718) seatf(seats_f) seatm(seats_m) ///
    secf(raw_sec_f) secm(raw_sec_m) lfprf(lfpr_f_1718) lfprm(lfpr_m_1718) prefix(m_)
display as text _n "Step 19: GII 2018-19, survey inputs from the microdata of NHDR's years, against Table 7"
list domain m_gii pub_gii evm1519_f_1718 evm1519_f lfpr_f_1718 lfpr_f, noobs sep(0) abbreviate(14)
quietly count if !missing(m_gii)
nhdr_check, label("Step 19 GII 2018-19 all-microdata, domains [5]") got(`=r(N)') want(5) tol(0)
export delimited using "$out/GII 2018-19 all microdata.csv", replace


*==============================================================================*
* SECTION 23   CHILD DEVELOPMENT INDEX (CDI), TABLES 4 AND 4A
*==============================================================================*
* Technical Note 6. Three dimensions, each the arithmetic mean of its
* normalized indicators, and the CDI the arithmetic mean of the three:
*   living standard  income per child equivalent YNE (300 to 2,000), share of
*                    children in the two richest quintiles (10 to 50),
*                    children 10 to 14 not working (70 to 100)
*   education        net enrolment, primary 5-9 (0 to 100), middle 10-12
*                    (0 to 75), matric 13-14 (0 to 50), and education
*                    expenditure per child equivalent EEC
*   health           fully immunized at 12 to 23 months (20 to 100), under-five
*                    survival (0.880 to 0.955), not stunted (15 to 100), not
*                    wasted (60 to 100)
*   child equivalents  NE = 2 + 1.4 (NA - 1) + NC, YNE = Y / NE, EEC = EE / NE
* The note prints no goalposts for EEC. Inverting the 30 education indices of
* Table 4 against Table 4A fixes them: every pair from about (3, 78) to
* (7, 81) reproduces all 30 within the rounding of the whole-number
* enrolment rates, and (5, 80) is the round pair inside that set.
* Two quantities the note leaves open were settled on the microdata:
*   "real" rupees     2001-02 prices, the first year of the CDI series. With
*                     the CPI (World Bank WDI, fiscal-year average of calendar
*                     years) the reproduced national YNE sits 3 and 6 percent
*                     under NHDR's in 2007-08 and 2018-19. NHDR's deflator is
*                     not stated.
*   income Y          household consumption, the Section 11 aggregate. HIES
*                     2007-08 in 6. Raw data has no income total, and consumption
*                     reproduces NHDR more closely than income in 2018-19.
*   children          under 18 (NC), adults 18 and over (NA)
*   education spending  2007-08: fees, admission and examination, plus
*                     uniform, books and supplies, from the education roster
*                     (s2bq19c). 2018-19 and 2024-25: the same items from the
*                     consumption module (school, college and university fees,
*                     uniforms, books, copies and stationery), which gives
*                     48.5 rupees against NHDR's 48.3.
*   immunization      BCG, three doses of DPT or pentavalent and three of
*                     polio, by card, recall or campaign. Adding measles
*                     lowers every province by 7 to 9 points below NHDR.
*   child work        LFS 2017-18 (not 2018-19), employed or producing goods
*                     for own use: within 0.3 points in all seven cells.
* Source    HIES 2007-08, 2018-19 and 2024-25, LFS 2017-18 and 2024-25. Stunting,
*           wasting and survival are PDHS values that NHDR prints in Table
*           4A. 23.4 keeps them as printed, and 23.4b reproduces them from
*           the PDHS microdata of Section 8A. NHDR's 2007-08 immunization
*           is from the PSLM 2007-08 district round and its 2007-08 child
*           work from LFS 2007-08, neither of which is in 6. Raw data (PBS's
*           download link for LFS 2007-08 serves the 2006-07 file).

* ---- 23.1 The construction, recovered from Tables 4 and 4A ------------------------------
capture program drop nhdr_cdi
program define nhdr_cdi
    syntax , INCome(varname) TOP2(varname) NOTwork(varname) NERP(varname) NERM(varname) ///
        NERX(varname) EEC(varname) IMMun(varname) SURVival(varname) STUNT(varname) ///
        WAST(varname) [PREfix(string)]
    gen double `prefix'sl  = ((`income' - 300) / 1700 + (`top2' - 10) / 40 + (`notwork' - 70) / 30) / 3
    gen double `prefix'edu = (`nerp' / 100 + `nerm' / 75 + `nerx' / 50 + (`eec' - 5) / 75) / 4
    gen double `prefix'hea = ((`immun' - 20) / 80 + (`survival' - 0.880) / 0.075 + ///
        (`stunt' - 15) / 85 + (`wast' - 60) / 40) / 4
    gen double `prefix'cdi = (`prefix'sl + `prefix'edu + `prefix'hea) / 3
end
import delimited using "$pub/NHDR2020 Table 4.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 3)
nhdr_cdi, income(income_pce) top2(top2) notwork(notwork) nerp(ner_p) nerm(ner_m) nerx(ner_x) ///
    eec(eec) immun(immun) survival(survival) stunt(notstunted) wast(notwasted) prefix(m_)
gen double cdi_from_pub = (pub_sl_idx + pub_edu_idx + pub_health_idx) / 3
foreach p in "sl sl 0.0015" "edu edu 0.006" "hea health 0.0025" {
    local mine : word 1 of `p'
    local pub  : word 2 of `p'
    local tol  : word 3 of `p'
    gen double _g = abs(m_`mine' - pub_`pub'_idx)
    quietly summarize _g
    nhdr_check, label("Step 20 CDI `pub' index from Table 4A inputs, worst of 30 [published]") ///
        got(`=r(max)') want(0) tol(`tol')
    drop _g
}
gen double _g = abs(cdi_from_pub - pub_cdi)
quietly summarize _g
nhdr_check, label("Step 20 CDI as the mean of its three printed indices, worst of 30 [published]") ///
    got(`=r(max)') want(0) tol(0.001)
drop _g
tempfile t4
save `t4'
export delimited using "$out/CDI method Table 4.csv"

* ---- 23.2 Household indicators from the HIES, one program for three rounds ---------------
* In memory: one record per person with hhid, age, prov, weight, cls (class
* attended now, missing if not attending), t_exp (annual household
* consumption) and ee (annual household education spending). Replaces the
* data with five rows, Pakistan and the provinces.
capture program drop nhdr_cdi_hh
program define nhdr_cdi_hh
    syntax , DEFLator(real)
    bysort hhid: gen int _nh = _N
    gen double pce = t_exp / _nh
    * Quintiles of persons on consumption per head, national cut.
    gen byte _ok = !missing(pce, weight)
    gen double _w0 = cond(_ok, weight, 0)
    sort pce hhid idc
    gen double _cum = sum(_w0)
    egen double _tot = total(_w0)
    gen byte Q = ceil(5 * _cum / _tot) if _ok
    replace Q = 1 if Q < 1 & _ok
    replace Q = 5 if Q > 5 & _ok & !missing(Q)
    gen double top2  = (Q >= 4) if age < 18 & !missing(Q)
    gen double ner_p = inrange(cls, 1, 5)  if inrange(age, 5, 9)
    gen double ner_m = inrange(cls, 6, 8)  if inrange(age, 10, 12)
    gen double ner_x = inrange(cls, 9, 10) if inrange(age, 13, 14)
    gen byte _ch = (age < 18)
    bysort hhid: egen double _nc = total(_ch)
    gen double NE = 2 + 1.4 * (_nh - _nc - 1) + _nc
    by hhid: gen byte _first = (_n == 1)
    gen double income_pce = t_exp / 12 / NE / `deflator' if _first
    gen double eec        = ee / 12 / NE / `deflator'    if _first
    nhdr_by_province, vars(income_pce eec top2 ner_p ner_m ner_x) wgt(weight) province(prov)
    foreach v in top2 ner_p ner_m ner_x {
        replace `v' = 100 * `v'
    }
end

import delimited using "$pub/WDI Pakistan CPI.csv", clear varnames(1) asdouble encoding(utf-8)
foreach y in 2001 2002 2007 2008 2018 2019 2024 2025 {
    quietly summarize value if calendar_year == `y'
    scalar cpi_`y' = r(mean)
}
* Fiscal year t-(t+1) as the mean of calendar years t and t+1.
scalar cpi_fy0102 = (cpi_2001 + cpi_2002) / 2
scalar cpi_fy0708 = (cpi_2007 + cpi_2008) / 2
scalar cpi_fy1819 = (cpi_2018 + cpi_2019) / 2
scalar cpi_fy2425 = (cpi_2024 + cpi_2025) / 2

* (a) HIES 2007-08. Provinces and regions are coded as in 2005-06 (Section
*     20) and recoded. Most roster answers are stored as text.
use hhcode itc v1 v2 v3 v4 if inlist(itc, 1000, 2000, 4000, 5000) using "$h07/sec 6abcde.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
gen double a = v * cond(itc == 1000, 26, cond(itc == 5000, 1, 12))
collapse (sum) t_exp=a, by(hhcode)
tempfile c07
save `c07'
use hhcode idc s2bq01 s2bq14 s2bq19c using "$h07/sec2a.dta", clear
foreach v in s2bq01 s2bq14 s2bq19c {
    capture confirm string variable `v'
    if !_rc destring `v', replace force
}
tempfile e07
save `e07'
use hhcode idc age s1aq03 province weight using "$h07/plist.dta", clear
recode province (1 = 2) (2 = 3) (3 = 1) (4 = 4), generate(prov)
merge 1:1 hhcode idc using `e07', keep(master match) nogenerate
merge m:1 hhcode using `c07', keep(master match) nogenerate
gen double cls = s2bq14 if s2bq01 == 3
bysort hhcode: egen double ee = total(s2bq19c)
gen double hhid = hhcode
tempfile h07p
save `h07p'
nhdr_cdi_hh, deflator(`=cpi_fy0708 / cpi_fy0102')
gen str7 year = "2007-08"
tempfile cdih07
save `cdih07'
use hhcode idc s3bq01b s3bq04a s3bq04d s3bq04h using "$h07/sec3b.dta", clear
foreach v in s3bq01b s3bq04a s3bq04d s3bq04h {
    capture confirm string variable `v'
    if !_rc destring `v', replace force
}
merge 1:1 hhcode idc using `h07p', keepusing(prov weight) keep(match) nogenerate
keep if inrange(s3bq01b, 12, 23)
gen double immun = inlist(s3bq04a, 1, 2) & inlist(s3bq04d, 1, 2) & inlist(s3bq04h, 1, 2)
nhdr_by_province, vars(immun) wgt(weight) province(prov)
replace immun = 100 * immun
merge 1:1 domain using `cdih07', nogenerate
save `cdih07', replace

* (b) HIES 2018-19.
use hhcode itc v1 v2 v3 v4 using "$h18/sec_6a.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
gen double a = v * cond(itc == 1000, 26, cond(itc == 5000, 1, 12)) if inlist(itc, 1000, 2000, 4000, 5000)
gen double e = v if inlist(itc, 101001, 101002, 31202, 95101, 95102, 95203)
collapse (sum) t_exp=a ee=e, by(hhcode)
tempfile c18
save `c18'
use hhcode idc age province region weights using "$h18/plist.dta", clear
merge 1:1 hhcode idc province region using "$h18/sec_2ab.dta", keepusing(s2bq01 s2bq14) ///
    keep(master match) nogenerate
rename (province weights) (prov weight)
merge m:1 hhcode using `c18', keep(master match) nogenerate
gen double cls = s2bq14 if s2bq01 == 3
gen double hhid = hhcode
tempfile h18c
save `h18c'
nhdr_cdi_hh, deflator(`=cpi_fy1819 / cpi_fy0102')
gen str7 year = "2018-19"
tempfile cdih18
save `cdih18'
use hhcode idc s3bq1b s3bq4a s3bq4d s3bq4k using "$h18/sec_3b.dta", clear
capture confirm string variable s3bq1b
if !_rc destring s3bq1b, replace force
merge 1:1 hhcode idc using `h18c', keepusing(prov weight) keep(match) nogenerate
keep if inrange(s3bq1b, 12, 23)
gen double immun = inlist(s3bq4a, 1, 2, 4) & inlist(s3bq4d, 1, 2, 4) & inlist(s3bq4k, 1, 2, 4)
nhdr_by_province, vars(immun) wgt(weight) province(prov)
replace immun = 100 * immun
merge 1:1 domain using `cdih18', nogenerate
save `cdih18', replace

* (c) HIES 2024-25. The household is prcode and hhno. The fee items are
*     split by level in 2024-25 (101001 school, 101002 college, 101003
*     university) where 2018-19 split them by sector.
use prcode hhno itc v1 v2 v3 v4 using "$h24/sec_6a_consum_exp.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
gen double a = v * cond(itc == 1000, 26, cond(itc == 5000, 1, 12)) if inlist(itc, 1000, 2000, 4000, 5000)
gen double e = v if inlist(itc, 101001, 101002, 101003, 31202, 95101, 95102, 95203)
collapse (sum) t_exp=a ee=e, by(prcode hhno)
tempfile c24
save `c24'
use prcode hhno idc province s1aq51 using "$h24/plist_roster.dta", clear
rename (province s1aq51) (prov age)
merge m:1 prcode using "$h24/weight.dta", keep(master match) nogenerate
merge 1:1 prcode hhno idc using "$h24/sec_2ab_education.dta", keepusing(s2bq01 s2bq10) ///
    keep(master match) nogenerate
merge m:1 prcode hhno using `c24', keep(master match) nogenerate
gen double cls = s2bq10 if s2bq01 == 3
egen double hhid = group(prcode hhno)
keep if inrange(prov, 1, 4)
tempfile h24c
save `h24c'
nhdr_cdi_hh, deflator(`=cpi_fy2425 / cpi_fy0102')
gen str7 year = "2024-25"
tempfile cdih24
save `cdih24'
use prcode hhno idc s3bq01b s3bq04a s3bq04b3 s3bq04d3 using "$h24/Sec_03b_immunisation.dta", clear
capture confirm string variable s3bq01b
if !_rc destring s3bq01b, replace force
merge 1:1 prcode hhno idc using `h24c', keepusing(prov weight) keep(match) nogenerate
keep if inrange(s3bq01b, 12, 23)
gen double immun = inlist(s3bq04a, 1, 2, 4) & inlist(s3bq04b3, 1, 2, 4) & inlist(s3bq04d3, 1, 2, 4)
nhdr_by_province, vars(immun) wgt(weight) province(prov)
replace immun = 100 * immun
merge 1:1 domain using `cdih24', nogenerate
save `cdih24', replace

* ---- 23.3 Children 10 to 14 not working, LFS ----------------------------------------------
use `lfs1718', clear
keep if inrange(age, 10, 14)
gen double work_wide = emp | ownuse
gen double work_emp  = emp
nhdr_by_province, vars(work_wide work_emp) wgt(w) province(prov)
gen double notwork      = 100 - 100 * work_wide
gen double notwork_emp  = 100 - 100 * work_emp
gen str7 year = "2018-19"
keep domain year notwork notwork_emp
tempfile nw18
save `nw18'
use `lfs2425', clear
keep if inrange(age, 10, 14)
gen double work_wide = emp | ownuse
gen double work_emp  = emp
nhdr_by_province, vars(work_wide work_emp) wgt(w) province(prov)
gen double notwork_wide = 100 - 100 * work_wide
gen double notwork_emp  = 100 - 100 * work_emp
gen str7 year = "2024-25"
keep domain year notwork_wide notwork_emp
tempfile nw24
save `nw24'

* ---- 23.4 The CDI reproduced for 2007-08 and 2018-19, against Table 4 ---------------------------
use `cdih07', clear
append using `cdih18'
merge 1:1 domain year using `nw18', nogenerate
rename domain region
gen str3 sex = "All"
merge 1:1 region sex year using `t4', keep(master match match_update match_conflict) ///
    keepusing(income_pce top2 notwork ner_p ner_m ner_x eec immun survival notstunted notwasted ///
    pub_sl_idx pub_edu_idx pub_health_idx pub_cdi) generate(_m) update
* "update" keeps every reproduced value and fills only what was not reproduced:
* the PDHS health inputs in both years, and child work in 2007-08.
drop _m
preserve
use `t4', clear
keep if sex == "All"
keep region year income_pce top2 notwork ner_p ner_m ner_x eec immun
foreach v in income_pce top2 notwork ner_p ner_m ner_x eec immun {
    rename `v' p_`v'
}
tempfile t4p
save `t4p'
restore
merge 1:1 region year using `t4p', keep(master match) nogenerate
nhdr_cdi, income(income_pce) top2(top2) notwork(notwork) nerp(ner_p) nerm(ner_m) nerx(ner_x) ///
    eec(eec) immun(immun) survival(survival) stunt(notstunted) wast(notwasted) prefix(r_)
display as text _n "Step 20: CDI inputs reproduced from the microdata, against Table 4A"
list region year income_pce p_income_pce top2 p_top2 notwork p_notwork ner_p p_ner_p ///
    ner_m p_ner_m ner_x p_ner_x eec p_eec immun p_immun, noobs sep(5) abbreviate(10)
display as text _n "Step 20: CDI reproduced, against Table 4"
list region year r_sl pub_sl_idx r_edu pub_edu_idx r_hea pub_health_idx r_cdi pub_cdi, ///
    noobs sep(5) abbreviate(12)
* Enrolment: Table 4A prints whole percentages.
gen double _g = max(abs(ner_p - p_ner_p), abs(ner_m - p_ner_m), abs(ner_x - p_ner_x))
quietly summarize _g
nhdr_check, label("Step 20 CDI enrolment, 3 levels x 5 domains x 2 years, worst |gap| [published]") ///
    got(`=r(max)') want(0) tol(0.8)
replace _g = abs(top2 - p_top2)
quietly summarize _g
nhdr_check, label("Step 20 CDI children in the top two quintiles, worst of 10 [published]") ///
    got(`=r(max)') want(0) tol(1.2)
replace _g = abs(notwork - p_notwork) if year == "2018-19"
quietly summarize _g if year == "2018-19"
nhdr_check, label("Step 20 CDI children not working, LFS 2017-18, worst of 5 [published]") ///
    got(`=r(max)') want(0) tol(0.3)
replace _g = abs(income_pce / p_income_pce - 1)
quietly summarize _g if region == "Pakistan"
nhdr_check, label("Step 20 CDI income per child equivalent, Pakistan, worst relative gap [reference 0.056]") ///
    got(`=r(max)') want(0.056) tol(0.01)
replace _g = abs(eec - p_eec) if year == "2018-19" & region == "Pakistan"
quietly summarize _g if year == "2018-19" & region == "Pakistan"
nhdr_check, label("Step 20 CDI education spending per child equivalent, Pakistan 2018-19 [published 48.3]") ///
    got(`=r(max)') want(0) tol(0.5)
replace _g = abs(r_cdi - pub_cdi)
quietly summarize _g
nhdr_check, label("Step 20 CDI reproduced, worst |gap| of 10 domain-years [reference 0.0249]") ///
    got(`=r(max)') want(0.0249) tol(0.004)
quietly summarize _g if region == "Pakistan"
nhdr_check, label("Step 20 CDI reproduced, Pakistan, worst |gap| of 2 years [reference 0.0070]") ///
    got(`=r(max)') want(0.0070) tol(0.003)
drop _g
tempfile cdi_rb
save `cdi_rb'
export delimited using "$out/CDI reproduced 2007-08 2018-19.csv"

* ---- 23.4b The CDI with its PDHS inputs reproduced from the microdata ------------
* 23.4 as it stands, with survival, stunting and wasting from Section 8A in
* place of the printed values. Where PDHS 2006-07 has no anthropometry
* (8A.3), the 2007-08 stunting and wasting stay as NHDR printed them.
use `cdi_rb', clear
merge 1:1 region sex year using `pd_cdi', keep(master match) nogenerate
gen double surv_h = survival_pd
gen double nst_h  = cond(missing(notstunted_pd), notstunted, notstunted_pd)
gen double nwa_h  = cond(missing(notwasted_pd), notwasted, notwasted_pd)
gen byte anthro_from_pdhs = !missing(notstunted_pd)
nhdr_cdi, income(income_pce) top2(top2) notwork(notwork) nerp(ner_p) nerm(ner_m) nerx(ner_x) ///
    eec(eec) immun(immun) survival(surv_h) stunt(nst_h) wast(nwa_h) prefix(h_)
display as text _n "Step 20: CDI with the PDHS inputs reproduced, against 23.4 and Table 4"
list region year survival surv_h notstunted nst_h notwasted nwa_h anthro_from_pdhs, ///
    noobs sep(5) abbreviate(12)
list region year h_hea r_hea pub_health_idx h_cdi r_cdi pub_cdi, noobs sep(5) abbreviate(12)
quietly count if !missing(surv_h)
nhdr_check, label("Step 20 CDI survival from PDHS, 5 domains x 2 years [10]") got(`=r(N)') want(10) tol(0)
gen double _g = abs(h_cdi - r_cdi)
quietly summarize _g
nhdr_check, label("Step 20 CDI with PDHS inputs against printed PDHS inputs, worst of 10 [0]") ///
    got(`=r(max)') want(0) tol(0.005)
replace _g = abs(h_cdi - pub_cdi)
quietly summarize _g
nhdr_check, label("Step 20 CDI with PDHS inputs, worst |gap| of 10 domain-years [published]") ///
    got(`=r(max)') want(0) tol(0.03)
drop _g
tempfile cdi_h
save `cdi_h'
export delimited using "$out/CDI reproduced PDHS.csv"

* ---- 23.5 The CDI for 2024-25 ------------------------------------------------------------
* Inputs as measured on the newest rounds:
*   HIES 2024-25   income per child equivalent, top two quintiles, enrolment,
*                  education spending, immunization
*   LFS 2024-25    children not working. LFS 2024-25 asks the own-use
*                  production questions of every household member, with a
*                  wider list: adding own-use work moves the share of
*                  children 10 to 14 counted as working by 13 points in
*                  2024-25 against 2 points in 2017-18. The two are not
*                  comparable, so both rounds are put on employment alone,
*                  and 2018-19 is recomputed on that basis beside it.
*   health         PDHS 2017-18 values held. No PDHS or comparable national
*                  anthropometric survey has been fielded since.
use `cdih24', clear
merge 1:1 domain year using `nw24', nogenerate
rename (domain notwork_emp) (region notwork)
preserve
use `t4', clear
keep if sex == "All" & year == "2018-19"
keep region survival notstunted notwasted
tempfile hold
save `hold'
restore
merge 1:1 region using `hold', nogenerate
nhdr_cdi, income(income_pce) top2(top2) notwork(notwork) nerp(ner_p) nerm(ner_m) nerx(ner_x) ///
    eec(eec) immun(immun) survival(survival) stunt(notstunted) wast(notwasted) prefix(c24_)
tempfile cdi24
save `cdi24'
use `cdi_rb', clear
keep if year == "2018-19"
drop r_*
replace notwork = notwork_emp
nhdr_cdi, income(income_pce) top2(top2) notwork(notwork) nerp(ner_p) nerm(ner_m) nerx(ner_x) ///
    eec(eec) immun(immun) survival(survival) stunt(notstunted) wast(notwasted) prefix(c18_)
keep region c18_* income_pce top2 notwork ner_p ner_m ner_x eec immun pub_cdi
foreach v in income_pce top2 notwork ner_p ner_m ner_x eec immun {
    rename `v' `v'_1819
}
merge 1:1 region using `cdi24', nogenerate
gen double cdi_change = c24_cdi - c18_cdi
gen str40 status_2024_25 = cond(c24_cdi >= 0.700, "High child development", ///
    cond(c24_cdi >= 0.550, "Medium child development", "Low child development"))
display as text _n "Step 20: THE CDI FOR 2024-25, with 2018-19 reproduced on the same basis"
list region income_pce_1819 income_pce top2_1819 top2 notwork_1819 notwork ner_p_1819 ner_p ///
    eec_1819 eec immun_1819 immun, noobs sep(0) abbreviate(10)
list region pub_cdi c18_cdi c24_sl c24_edu c24_hea c24_cdi cdi_change status_2024_25, ///
    noobs sep(0) abbreviate(12)
quietly summarize c24_cdi if region == "Pakistan"
nhdr_check, label("Step 20 CDI 2024-25, Pakistan [reference 0.5718]") got(`=r(mean)') want(0.5718) tol(0.003)
quietly summarize c18_cdi if region == "Pakistan"
nhdr_check, label("Step 20 CDI 2018-19 on the 2024-25 basis, Pakistan [reference 0.5818]") ///
    got(`=r(mean)') want(0.5818) tol(0.003)
export delimited using "$out/CDI 2024-25.csv"

* ---- 23.5b The 2024-25 CDI with the reproduced PDHS 2017-18 inputs -------------
* 23.5 holds the PDHS 2017-18 values as NHDR printed them. Here the same
* values are taken from the microdata (Section 8A), in 2024-25 and in the
* 2018-19 comparator on the 2024-25 basis.
use `pd_cdi', clear
keep if sex == "All" & year == "2018-19"
keep region survival_pd notstunted_pd notwasted_pd
tempfile pd18
save `pd18'
use `cdi24', clear
merge 1:1 region using `pd18', keep(master match) nogenerate
nhdr_cdi, income(income_pce) top2(top2) notwork(notwork) nerp(ner_p) nerm(ner_m) nerx(ner_x) ///
    eec(eec) immun(immun) survival(survival_pd) stunt(notstunted_pd) wast(notwasted_pd) prefix(c24h_)
keep region c24_cdi c24h_sl c24h_edu c24h_hea c24h_cdi
tempfile c24h
save `c24h'
use `cdi_rb', clear
keep if year == "2018-19"
drop r_*
replace notwork = notwork_emp
merge 1:1 region using `pd18', keep(master match) nogenerate
nhdr_cdi, income(income_pce) top2(top2) notwork(notwork) nerp(ner_p) nerm(ner_m) nerx(ner_x) ///
    eec(eec) immun(immun) survival(survival_pd) stunt(notstunted_pd) wast(notwasted_pd) prefix(c18h_)
keep region c18h_cdi pub_cdi
merge 1:1 region using `c24h', nogenerate
gen double cdi_change_h = c24h_cdi - c18h_cdi
display as text _n "Step 20: THE CDI FOR 2024-25 with the PDHS inputs reproduced, and 2018-19 on the same basis"
list region pub_cdi c18h_cdi c24h_sl c24h_edu c24h_hea c24h_cdi c24_cdi cdi_change_h, noobs sep(0) abbreviate(12)
quietly count if !missing(c24h_cdi)
nhdr_check, label("Step 20 CDI 2024-25 with PDHS inputs reproduced, domains [5]") got(`=r(N)') want(5) tol(0)
gen double _g = abs(c24h_cdi - c24_cdi)
quietly summarize _g
nhdr_check, label("Step 20 CDI 2024-25, reproduced against printed PDHS inputs, worst of 5 [0]") ///
    got(`=r(max)') want(0) tol(0.005)
drop _g
export delimited using "$out/CDI 2024-25 PDHS.csv"


* ---- 23.6 The PSLM district rounds on either side of 2007-08, tested --------
* NHDR names PSLM 2007-08 for the CDI's 2007-08 enrolment and immunization and
* PSLM 2006-07 for the 2006-07 column of Table 1 (Table 1 note). PSLM 2007-08,
* a provincial round, is not in 6. Raw data; HIES 2007-08 stands in (23.2).
* The two district rounds on either side, PSLM 2006-07 and 2008-09, are read
* here on the rules used everywhere else, and set against the printed values:
*   literacy   persons 15+ who read and write with understanding (scq01)
*   enrolment  level matched: ages 5-9 in classes 1-5, 10-12 in 6-8, 13-14 in
*              9-10 (scq05 attending, scq06 class); by level for the CDI
*   immunized  children 12-23 months with BCG, DPT3 and polio 3 (shq5_1,
*              shq5_4, shq5_7) by card, recall or campaign; age from the birth
*              year and month (year_c, month_c; month 0 taken as June) against
*              the interview date
* Neither round reproduces the printed values as closely as HIES 2005-06
* (Table 2A) and HIES 2007-08 (Table 4A) already do, so neither enters an
* index. The results stay in "PSLM district rounds tested.csv".
capture program drop nhdr_pslm_district
program define nhdr_pslm_district
    syntax , ROUND(string) DIR(string) ROSTER(string) EDUC(string) CHILD(string) ///
        WFILE(string) WKEY(string) WVAR(string) DATEMODE(string)
    * Persons: literacy and enrolment
    use hhcode idc age using "`dir'/`roster'", clear
    tempfile ro
    save `ro'
    use hhcode idc psu province region scq01 scq05 scq06 using "`dir'/`educ'", clear
    merge 1:1 hhcode idc using `ro', keep(match) nogenerate
    merge m:1 `wkey' using "`dir'/`wfile'", keepusing(`wvar') keep(master match) nogenerate
    rename `wvar' w
    keep if inrange(province, 1, 4)
    gen double lit   = (scq01 == 1) if inlist(scq01, 1, 2) & age >= 15 & !missing(age)
    gen byte att     = (scq05 == 1)
    gen double ner514 = (att & ((inrange(age, 5, 9) & inrange(scq06, 1, 5)) | ///
        (inrange(age, 10, 12) & inrange(scq06, 6, 8)) | (inrange(age, 13, 14) & inrange(scq06, 9, 10)))) ///
        if inrange(age, 5, 14)
    gen double ner_p = (att & inrange(scq06, 1, 5))  if inrange(age, 5, 9)
    gen double ner_m = (att & inrange(scq06, 6, 8))  if inrange(age, 10, 12)
    gen double ner_x = (att & inrange(scq06, 9, 10)) if inrange(age, 13, 14)
    gen str20 region_n = cond(province == 1, "Punjab", cond(province == 2, "Sindh", ///
        cond(province == 3, "Khyber Pakhtunkhwa", "Balochistan")))
    tempfile pp
    save `pp'
    collapse (mean) lit ner514 ner_p ner_m ner_x [aw=w]
    gen str20 region_n = "Pakistan"
    tempfile pk
    save `pk'
    use `pp', clear
    collapse (mean) lit ner514 ner_p ner_m ner_x [aw=w], by(region_n)
    append using `pk'
    foreach v in lit ner514 ner_p ner_m ner_x {
        replace `v' = 100 * `v'
    }
    tempfile ed
    save `ed'
    * Children: immunization at 12-23 months
    * Interview date, one record per household
    if "`datemode'" == "dmy" use hhcode month year using "`dir'/sec_a.dta", clear
    else use hhcode int_date using "`dir'/sec_a.dta", clear
    bysort hhcode: keep if _n == 1
    tempfile ia
    save `ia'
    use hhcode psu province year_c month_c shq5_1 shq5_4 shq5_7 using "`dir'/`child'", clear
    merge m:1 hhcode using `ia', keep(match) nogenerate
    if "`datemode'" == "dmy" {
        keep if inrange(month, 1, 12) & inrange(year, 6, 7)
        gen int iy = 2000 + year
        gen int im = month
    }
    else {
        gen int iy = 2000 + mod(int_date, 100)
        gen int im = mod(floor(int_date / 100), 100)
        keep if inrange(im, 1, 12) & inrange(iy, 2008, 2009)
    }
    merge m:1 `wkey' using "`dir'/`wfile'", keepusing(`wvar') keep(master match) nogenerate
    rename `wvar' w
    keep if inrange(province, 1, 4)
    gen byte mb = cond(inrange(month_c, 1, 12), month_c, 6)
    gen int agem = (iy * 12 + im) - ((2000 + year_c) * 12 + mb)
    keep if inrange(agem, 12, 23)
    gen double immun = inlist(shq5_1, 1, 2, 4) & inlist(shq5_4, 1, 2, 4) & inlist(shq5_7, 1, 2, 4)
    gen byte one = 1
    gen str20 region_n = cond(province == 1, "Punjab", cond(province == 2, "Sindh", ///
        cond(province == 3, "Khyber Pakhtunkhwa", "Balochistan")))
    tempfile cc
    save `cc'
    collapse (mean) immun (sum) n_child=one [aw=w]
    gen str20 region_n = "Pakistan"
    tempfile ck
    save `ck'
    use `cc', clear
    collapse (mean) immun (sum) n_child=one [aw=w], by(region_n)
    append using `ck'
    replace immun = 100 * immun
    merge 1:1 region_n using `ed', nogenerate
    gen str7 round = "`round'"
    rename region_n region
end
* PSLM 2006-07 weights by household (hhweights.dta), PSLM 2008-09 by PSU.
nhdr_pslm_district, round("2006-07") dir("$p06") roster("section b.dta") educ("section c.dta") ///
    child("section h.dta") wfile("hhweights.dta") wkey("hhcode") wvar("weights") datemode("dmy")
tempfile ps06
save `ps06'
nhdr_pslm_district, round("2008-09") dir("$p08") roster("sec_b.dta") educ("sec_c.dta") ///
    child("section_h.dta") wfile("weights_file.dta") wkey("psu") wvar("weights") datemode("int")
append using `ps06'
tempfile pstest
save `pstest'
* Printed comparators: Table 2A 2006-07 (literacy, enrolment), Table 4A 2007-08.
import delimited using "$pub/NHDR2020 Table 2A.csv", clear varnames(1) asdouble encoding(utf-8) stringcols(1 2)
keep if quintile == "All"
keep region lit_2006_07 ner_2006_07
rename (lit_2006_07 ner_2006_07) (pub_lit_2006_07 pub_ner_2006_07)
tempfile c2a
save `c2a'
import delimited using "$pub/NHDR2020 Table 4.csv", clear varnames(1) asdouble encoding(utf-8) stringcols(1 2 3)
keep if sex == "All" & year == "2007-08"
keep region ner_p ner_m ner_x immun
rename (ner_p ner_m ner_x immun) (pub_ner_p pub_ner_m pub_ner_x pub_immun)
tempfile c4a
save `c4a'
use `pstest', clear
merge m:1 region using `c2a', keep(master match) nogenerate
merge m:1 region using `c4a', keep(master match) nogenerate
order round region lit pub_lit_2006_07 ner514 pub_ner_2006_07 ner_p pub_ner_p ner_m pub_ner_m ///
    ner_x pub_ner_x immun pub_immun n_child
sort round region
display as text _n "Step 20: PSLM district rounds against NHDR's 2006-07 and 2007-08 columns"
list, noobs sepby(round) abbreviate(12)
quietly summarize immun if round == "2006-07" & region == "Pakistan"
nhdr_check, label("Step 20 PSLM 2006-07 full immunization 12-23 months, Pakistan [reference 81.8; NHDR 73]") ///
    got(`=r(mean)') want(81.8) tol(0.15)
quietly summarize lit if round == "2006-07" & region == "Pakistan"
nhdr_check, label("Step 20 PSLM 2006-07 literacy 15+, Pakistan [reference 51.8; NHDR 50.7]") ///
    got(`=r(mean)') want(51.8) tol(0.15)
export delimited using "$out/PSLM district rounds tested.csv", replace


*==============================================================================*
* SECTION 24   YOUTH DEVELOPMENT INDEX (YDI), TABLES 5 AND 5A
*==============================================================================*
* Technical Note 7. Youth are 15 to 29. Five indicators, each normalized,
* and the YDI their arithmetic mean:
*   mean years of schooling  (KG x 1 + primary x 5 + middle x 8 + matric x 11
*                            + intermediate x 14 + degree x 17) / all youth,
*                            goalposts 2 to 10
*   employment to population employed youth / youth, 10 to 80
*   higher education         0 to 30
*   fully employed           100 minus the percent of employed youth who
*                            worked fewer than 35 hours, 20 to 100
*   survival                 PDHS 2006-07 and PMMS 2019, 0.9970 to 0.9999
* What the tables show, beyond the note:
*   1. The survival goalposts are misprinted. The note gives 0.9770. The only
*      pair on a 0.00005 grid that reproduces all 14 survival indices of
*      Table 5 within rounding is 0.9970 to 0.9999.
*   2. Equation (6) divides four indices by four. Table 5 averages all five.
*   3. "Enrolment in higher education" is attainment: the percent of youth
*      whose highest completed level is intermediate or above. The enrolment
*      reading gives 13.2 percent for Pakistan against 16.6, and attainment gives
*      16.6, and every province and sex to the printed decimal.
*   4. The "2017-18" column is LFS 2017-18, with Islamabad in Punjab.
*   5. Zero hours (absent from work last week) is not counted as working
*      under 35 hours.
* Result    schooling within 0.03 years and higher education to the printed
*           decimal in all seven cells. Employment to population is within 2
*           points except Balochistan (38.7 against 32.9), which no tested
*           definition reproduces. Full employment within 1.4 points.

* ---- 24.1 The construction, recovered from Tables 5 and 5A ---------------------------------
capture program drop nhdr_ydi
program define nhdr_ydi
    syntax , MYS(varname) EPR(varname) HIED(varname) FULL(varname) SURVival(varname) [PREfix(string)]
    gen double `prefix'i_mys  = (`mys' - 2) / 8
    gen double `prefix'i_epr  = (`epr' - 10) / 70
    gen double `prefix'i_hied = `hied' / 30
    gen double `prefix'i_full = (`full' - 20) / 80
    gen double `prefix'i_surv = (`survival' - 0.9970) / (0.9999 - 0.9970)
    gen double `prefix'ydi = (`prefix'i_mys + `prefix'i_epr + `prefix'i_hied + `prefix'i_full + ///
        `prefix'i_surv) / 5
end
import delimited using "$pub/NHDR2020 Table 5.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2)
nhdr_ydi, mys(mys) epr(epr) hied(hied) full(fullemp) survival(survival) prefix(m_)
* Survival as printed (4 decimals) moves the index by up to 0.017, so the
* check on the survival index allows that. The others are exact.
foreach p in "mys mys 0.0012" "epr epr 0.0006" "hied hied 0.0006" "full full 0.0006" "surv surv 0.0175" {
    local mine : word 1 of `p'
    local pub  : word 2 of `p'
    local tol  : word 3 of `p'
    gen double _g = abs(m_i_`mine' - pub_`pub'_idx)
    quietly summarize _g
    nhdr_check, label("Step 21 YDI `pub' index from Table 5A, worst of 14 [published]") ///
        got(`=r(max)') want(0) tol(`tol')
    drop _g
}
gen double _g = abs((pub_mys_idx + pub_epr_idx + pub_hied_idx + pub_full_idx + pub_surv_idx) / 5 - pub_ydi)
quietly summarize _g
nhdr_check, label("Step 21 YDI as the mean of five printed indices, worst of 14 [published]") ///
    got(`=r(max)') want(0) tol(0.001)
drop _g
* The goalposts as printed (0.9770) would put Pakistan's 2001-02 survival
* index at 0.917 against the printed 0.351.
gen double surv_idx_as_printed = (survival - 0.9770) / (0.9999 - 0.9770)
list region year survival pub_surv_idx m_i_surv surv_idx_as_printed if region == "Pakistan", noobs
tempfile t5
save `t5'
export delimited using "$out/YDI method Table 5.csv"

* ---- 24.1b Youth survival reproduced from PMMS 2019 -----------------------------
* Table 5 prints youth survival for 2017-18 from PMMS 2019 to four decimals.
* It is one minus the annual death rate at 15 to 29: deaths at those ages
* since January 2016 (household deaths file PKOD7AFL, qh32c date of death,
* qh33u and qh33n age at death) over the person-years lived at those ages
* since January 2016 by the de jure household population (PKPQ7AFL, qh05
* usual resident, qh07 age, ages taken at mid-year) and by the deceased
* before death. Household weights qhweight. Pakistan is the four provinces,
* as Table 5 has it (PMMS regions 1 to 4; Gilgit-Baltistan and AJK apart).
* Result: six of seven cells within 0.00011 of Table 5. Balochistan gives
* 0.9986 against 0.9990 printed, about 0.026 on its 2017-18 YDI.
local pmms "$pdhs/PK_2019_MATERNALMORTALITYSURVEY_09292026_916_170967"
capture confirm file "`pmms'/PKPQ7ADT/PKPQ7AFL.DTA"
local rc1 = _rc
capture confirm file "`pmms'/PKOD7ADT/PKOD7AFL.DTA"
if `rc1' | _rc {
    display as text "  PMMS 2019 household files are not in 6. Raw data/PDHS: youth survival stays as printed"
}
else {
    local s16 = (2016 - 1900) * 12 + 1
    use qhregion qhintc qhweight qh04 qh05 qh07 using "`pmms'/PKPQ7ADT/PKPQ7AFL.DTA", clear
    keep if qh05 == 1 & qh07 < 95 & inrange(qhregion, 1, 4)
    gen double _T  = (qhintc - `s16') / 12
    gen double _a  = qh07 + 0.5
    gen double py  = max(0, min(_a, 30) - max(_a - _T, 15))
    gen double dth = 0
    gen double w   = qhweight / 1000000
    rename qh04 sexc
    keep qhregion sexc w py dth
    tempfile pmpy
    save `pmpy'
    use qhregion qhintc qhweight qh31 qh32c qh33u qh33n using "`pmms'/PKOD7ADT/PKOD7AFL.DTA", clear
    keep if qh32c >= `s16' & qh32c <= qhintc & inrange(qhregion, 1, 4)
    * Age at death in completed years; deaths in days or months are infants.
    gen double _aad = cond(qh33u == 3, qh33n, cond(inlist(qh33u, 1, 2), 0, .))
    gen double dth  = inrange(_aad, 15, 29)
    gen double _T   = (qh32c - `s16') / 12
    gen double _a   = _aad + 0.5
    gen double py   = cond(missing(_aad), 0, max(0, min(_a, 30) - max(_a - _T, 15)))
    gen double w    = qhweight / 1000000
    rename qh31 sexc
    keep qhregion sexc w py dth
    append using `pmpy'
    gen double wd = w * dth
    gen double wp = w * py
    gen long _id = _n
    expand 3
    bysort _id: gen byte _c = _n
    gen str20 region = ""
    replace region = "Pakistan"           if _c == 1
    replace region = "Punjab"             if _c == 2 & qhregion == 1
    replace region = "Sindh"              if _c == 2 & qhregion == 2
    replace region = "Khyber Pakhtunkhwa" if _c == 2 & qhregion == 3
    replace region = "Balochistan"        if _c == 2 & qhregion == 4
    replace region = "Pakistan - Male"    if _c == 3 & sexc == 1
    replace region = "Pakistan - Female"  if _c == 3 & sexc == 2
    drop if region == ""
    collapse (sum) deaths_w=wd py_w=wp, by(region)
    gen double survival_pmms = 1 - deaths_w / py_w
    preserve
    use `t5', clear
    keep if year == "2017-18"
    keep region survival
    tempfile t5s
    save `t5s'
    restore
    merge 1:1 region using `t5s', keep(master match) nogenerate
    gen double _g = abs(survival_pmms - survival)
    display as text _n "Step 21: youth survival from PMMS 2019 against Table 5 (2017-18)"
    list region survival_pmms survival _g, noobs sep(0)
    quietly count
    nhdr_check, label("Step 21 YDI survival reproduced from PMMS 2019, domains [7]") got(`=r(N)') want(7) tol(0)
    quietly summarize _g if region != "Balochistan"
    nhdr_check, label("Step 21 YDI survival from PMMS 2019, worst of 6, Balochistan apart [published Table 5]") ///
        got(`=r(max)') want(0) tol(0.0002)
    drop _g
    export delimited using "$out/YDI survival PMMS 2019.csv", replace
}

* ---- 24.2 The YDI indicators from the LFS, 2017-18 and 2024-25 -----------------------------
capture program drop nhdr_lfs_domains
program define nhdr_lfs_domains
    syntax , PROVince(varname) SEX(varname)
    tempvar pid copy
    gen long `pid' = _n
    expand 3
    bysort `pid': gen byte `copy' = _n
    gen str20 region = ""
    replace region = "Pakistan"           if `copy' == 1
    replace region = "Khyber Pakhtunkhwa" if `copy' == 2 & `province' == 1
    replace region = "Punjab"             if `copy' == 2 & `province' == 2
    replace region = "Sindh"              if `copy' == 2 & `province' == 3
    replace region = "Balochistan"        if `copy' == 2 & `province' == 4
    replace region = "Pakistan - Male"    if `copy' == 3 & `sex' == 1
    replace region = "Pakistan - Female"  if `copy' == 3 & `sex' == 2
    drop if region == ""
end
* 2012-13 is added for Figure 4.1 (Section 26A): four of the five indicators.
foreach r in 1213 1718 2425 {
    use `lfs`r'', clear
    keep if inrange(age, 15, 29)
    gen double ys = cond(missing(edu) | edu <= 1, 0, cond(edu <= 3, 1, cond(edu == 4, 5, ///
        cond(edu == 5, 8, cond(edu == 6, 11, cond(edu == 7, 14, 17))))))
    gen double hi   = (edu >= 7 & !missing(edu))
    gen double part = (hours > 0 & hours < 35 & !missing(hours)) if emp == 1
    gen double e = emp
    nhdr_lfs_domains, province(prov) sex(sex)
    collapse (mean) mys=ys epr=e hied=hi part [aw=w], by(region)
    replace epr  = 100 * epr
    replace hied = 100 * hied
    gen double fullemp = 100 - 100 * part
    drop part
    gen str7 year = cond("`r'" == "1718", "2017-18", cond("`r'" == "2425", "2024-25", "2012-13"))
    tempfile y`r'
    save `y`r''
}
use `y1718', clear
append using `y2425'
append using `y1213'
* Survival: PMMS 2019 as printed for 2017-18, held for 2024-25. No survey
* since PMMS 2019 reports adult mortality by province.
preserve
use `t5', clear
keep if year == "2017-18"
keep region survival
tempfile surv
save `surv'
restore
merge m:1 region using `surv', nogenerate
* No survey on disk measures youth mortality around 2012-13 (PDHS 2012-13
* carries no sibling or household-death module), so its survival and YDI
* stay missing; the other four indicators are reproduced.
replace survival = . if year == "2012-13"
nhdr_ydi, mys(mys) epr(epr) hied(hied) full(fullemp) survival(survival) prefix(r_)
preserve
use `t5', clear
keep region year mys epr hied fullemp pub_ydi
rename (mys epr hied fullemp) (p_mys p_epr p_hied p_fullemp)
tempfile t5p
save `t5p'
restore
merge 1:1 region year using `t5p', keep(master match) nogenerate
display as text _n "Step 21: YDI indicators from the LFS microdata, against Table 5A"
list region year mys p_mys epr p_epr hied p_hied fullemp p_fullemp r_ydi pub_ydi, ///
    noobs sep(7) abbreviate(10)
gen double _g = abs(mys - p_mys)
quietly summarize _g if year == "2017-18"
nhdr_check, label("Step 21 YDI mean years of schooling, LFS 2017-18, worst of 7 [published]") ///
    got(`=r(max)') want(0) tol(0.03)
replace _g = abs(hied - p_hied)
quietly summarize _g if year == "2017-18"
nhdr_check, label("Step 21 YDI higher education (attainment), worst of 7 [published]") ///
    got(`=r(max)') want(0) tol(0.06)
replace _g = abs(epr - p_epr)
quietly summarize _g if year == "2017-18" & region != "Balochistan"
nhdr_check, label("Step 21 YDI employment to population, worst of 6, Balochistan apart [published]") ///
    got(`=r(max)') want(0) tol(2.1)
replace _g = abs(fullemp - p_fullemp)
quietly summarize _g if year == "2017-18"
nhdr_check, label("Step 21 YDI fully employed, worst of 7 [published]") ///
    got(`=r(max)') want(0) tol(1.45)
replace _g = abs(r_ydi - pub_ydi)
quietly summarize _g if year == "2017-18" & region == "Pakistan"
nhdr_check, label("Step 21 YDI 2017-18 reproduced, Pakistan [published 0.605]") ///
    got(`=r(max)') want(0) tol(0.004)
quietly summarize _g if year == "2017-18"
nhdr_check, label("Step 21 YDI 2017-18 reproduced, worst of 7 [reference 0.0172]") ///
    got(`=r(max)') want(0.0172) tol(0.003)
drop _g
quietly summarize r_ydi if year == "2024-25" & region == "Pakistan"
nhdr_check, label("Step 21 YDI 2024-25, Pakistan [reference 0.681]") got(`=r(mean)') want(0.6808) tol(0.003)
gen str40 status = cond(r_ydi >= 0.700, "High youth development", ///
    cond(r_ydi >= 0.550, "Medium youth development", "Low youth development"))
sort year region
export delimited using "$out/YDI 2017-18 2024-25.csv"


*==============================================================================*
* SECTION 25   LABOUR DEVELOPMENT INDEX (LDI), TABLES 8 AND 8A
*==============================================================================*
* Technical Note 8. Population aged 10 and over. Five dimensions, normalized
* on the goalposts of the note's Table 3, and the LDI their geometric mean:
*   EP    employment to population ratio                    0.092 to 0.978
*   SLI   labor share, LI / (LI + CI), with
*         LI = 12 x W x (NLE + 0.8 NLSE), CI = 0.7 (GDP - LI),
*         W the mean monthly wage of paid employees, NLE paid employees,
*         NLSE the self-employed                            0.060 to 0.723
*   SP    mean wage of managers and professionals (ISCO 1, 2) over that of
*         plant operators and elementary workers (ISCO 8, 9) 0.937 to 5.657
*   HC    mean years of schooling of the labor force, weights 0 (none),
*         8 (below matric), 10 (matric), 12 (intermediate), 17 (degree)
*                                                           1.637 to 9.809
*   DW    geometric mean of: percent of paid employees above the minimum
*         wage, percent of the employed at more than 10 and under 48 hours,
*         percent employed in the formal sector, percent of the employed who
*         are not contributing family workers, and the female to male wage
*         ratio (a ratio, not a percent)                    6.0 to 32.7
* The note's introduction says arithmetic mean, and its Step 3 says geometric.
* Table 8 is the geometric mean: the arithmetic mean misses Pakistan-Female
* 2012-13 by 0.047.
* Reproduced from LFS 2012-13, 2014-15 and 2017-18. GDP is the WDI current-price
* series (2015-16 base). Provincial product uses Pasha's shares, interpolated
* (2007-08 and 2014-15 for 2012-13, 2014-15 and 2018-19 for 2017-18). Those two
* Pasha estimates differ in basis (constant 2005-06 prices against current
* factor cost), so a fixed-share version (lshare_fs, ldidw_fs) holds the 2018-19
* shares in every year. ptop and pbot give the occupation mix of paid employees
* behind the skill premium. For the
* two sexes, GDP is split by each sex's share of employment, which is the
* reading that brings NHDR's female share (0.12) within reach. The labour
* share is the one input that does not reproduce: NHDR's 0.32 for 2012-13
* implies GDP of about Rs 22.4 trillion, the pre-2017 (2005-06 base) level,
* against Rs 25.0 trillion on the current series. With NHDR's own labour
* shares swapped in, every reproduced LDI is within 0.01 of Table 8.

* ---- 25.1 The construction, recovered from Tables 8 and 8A ----------------------------------
capture program drop nhdr_ldi
program define nhdr_ldi
    syntax , EPR(varname) LSHare(varname) SKILL(varname) HUMcap(varname) DECent(varname) [PREfix(string)]
    gen double `prefix'i_ep = (`epr' - 0.092) / (0.978 - 0.092)
    gen double `prefix'i_ls = (`lshare' - 0.060) / (0.723 - 0.060)
    gen double `prefix'i_sp = (`skill' - 0.937) / (5.657 - 0.937)
    gen double `prefix'i_hc = (`humcap' - 1.637) / (9.809 - 1.637)
    gen double `prefix'i_dw = (`decent' - 6.0) / (32.7 - 6.0)
    gen double `prefix'ldidw = exp((ln(`prefix'i_ep) + ln(`prefix'i_ls) + ln(`prefix'i_sp) + ///
        ln(`prefix'i_hc) + ln(`prefix'i_dw)) / 5)
    gen double `prefix'ldin = exp((ln(`prefix'i_ep) + ln(`prefix'i_ls) + ln(`prefix'i_sp) + ///
        ln(`prefix'i_hc)) / 4)
end
import delimited using "$pub/NHDR2020 Table 8.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2)
nhdr_ldi, epr(epr) lshare(lshare) skill(skillprem) humcap(humcap) decent(decentwork) prefix(m_)
* Tolerances follow the printed precision of each input: the labor share
* has two decimals, which moves its index by up to 0.0076.
foreach p in "ep epr 0.001" "ls lshare 0.008" "sp sp 0.0015" "hc hc 0.001" "dw dw 0.0015" {
    local mine : word 1 of `p'
    local pub  : word 2 of `p'
    local tol  : word 3 of `p'
    gen double _g = abs(m_i_`mine' - pub_`pub'_idx)
    quietly summarize _g
    nhdr_check, label("Step 22 LDI `pub' index from Table 8A, worst of 14 [published]") ///
        got(`=r(max)') want(0) tol(`tol')
    drop _g
}
gen double gm5 = exp((ln(pub_epr_idx) + ln(pub_lshare_idx) + ln(pub_sp_idx) + ln(pub_hc_idx) + ln(pub_dw_idx)) / 5)
gen double am5 = (pub_epr_idx + pub_lshare_idx + pub_sp_idx + pub_hc_idx + pub_dw_idx) / 5
gen double _g = abs(gm5 - pub_ldidw)
quietly summarize _g
nhdr_check, label("Step 22 LDI as the geometric mean of five printed indices, worst of 14 [published]") ///
    got(`=r(max)') want(0) tol(0.001)
replace _g = abs(am5 - pub_ldidw)
quietly summarize _g
display as text "  the arithmetic mean instead misses by up to " as result %6.4f r(max)
drop _g
tempfile t8
save `t8'
export delimited using "$out/LDI method Table 8.csv"

* ---- 25.2 The LDI indicators from the LFS: 2012-13, 2017-18 and 2024-25 ---------------------
import delimited using "$pub/WDI Pakistan GDP current LCU.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(4)
foreach fy in 2012-13 2014-15 2017-18 2024-25 {
    quietly summarize value_rs if fiscal_year == "`fy'"
    scalar gdp_`=subinstr("`fy'", "-", "_", .)' = r(mean)
}
import delimited using "$pub/GRP published estimates.csv", clear varnames(1) asdouble ///
    encoding(utf-8) stringcols(1 2 3 4)
keep if inlist(source, "Pasha IPR 2015", "Pasha BR 2021") & province != "Pakistan"
keep province year share_pct
replace year = subinstr(year, "-", "_", .)
reshape wide share_pct, i(province) j(year) string
gen double sh_2012_13 = (share_pct2007_08 + (5/7) * (share_pct2014_15 - share_pct2007_08)) / 100
gen double sh_2017_18 = (share_pct2014_15 + (3/4) * (share_pct2018_19 - share_pct2014_15)) / 100
* 2014-15 is a year Pasha (2015) estimates directly.
gen double sh_2014_15 = share_pct2014_15 / 100
gen double sh_2024_25 = share_pct2018_19 / 100
* Sensitivity: one source and one basis for every year (Pasha BR 2021, 2018-19
* current factor cost). The interpolated shares mix IPR 2015 (constant 2005-06
* prices) with BR 2021, and Balochistan moves from 2.9 to 4.8 percent between
* them, which moves its labor share with it.
gen double shf = share_pct2018_19 / 100
rename province region
keep region sh_* shf
tempfile grpsh
save `grpsh'

* 2014-15 is added for Figures 4.4, 4.7 and 4.15 (Section 26A).
foreach r in 1213 1415 1718 2425 {
    local fy = cond("`r'" == "1213", "2012_13", cond("`r'" == "1718", "2017_18", cond("`r'" == "1415", "2014_15", "2024_25")))
    use `lfs`r'', clear
    keep if age >= 10 & !missing(age)
    gen double yrs = cond(missing(edu) | edu <= 1, 0, cond(edu <= 5, 8, cond(edu == 6, 10, ///
        cond(edu == 7, 12, 17))))
    gen double hc   = yrs if act == 1
    gen double e    = emp
    gen double wage_e = wage if emp == 1 & employee == 1 & wage > 0 & !missing(wage)
    gen double wtop = wage_e if inlist(occ1, 1, 2)
    gen double wbot = wage_e if inlist(occ1, 8, 9)
    * Occupation mix of paid employees, to read movements in the skill premium
    gen double ptop = inlist(occ1, 1, 2) if !missing(wage_e)
    gen double pbot = inlist(occ1, 8, 9) if !missing(wage_e)
    gen double wf   = wage_e if sex == 2
    gen double wm   = wage_e if sex == 1
    gen double mwok = (wage_e > mw) if !missing(wage_e)
    gen double dh   = (hours > 10 & hours < 48) if emp == 1 & hours > 0 & !missing(hours)
    gen double fe   = formal if emp == 1
    gen double cf   = cfw if emp == 1
    gen double n_ee  = ws * (emp == 1 & employee == 1)
    gen double n_se  = ws * (emp == 1 & selfemp == 1)
    gen double n_emp = ws * (emp == 1)
    nhdr_lfs_domains, province(prov) sex(sex)
    collapse (mean) epr=e humcap=hc wbar=wage_e wtop wbot ptop pbot wf wm mwok dh fe cf ///
        (rawsum) n_ee n_se n_emp [aw=w], by(region)
    gen double skillprem = wtop / wbot
    * Wage ratio: each province its own, and the two sexes take the national one.
    gen double wr = wf / wm
    quietly summarize wr if region == "Pakistan"
    replace wr = r(mean) if inlist(region, "Pakistan - Male", "Pakistan - Female")
    gen double decentwork = exp((ln(100 * mwok) + ln(100 * dh) + ln(100 * fe) + ln(100 - 100 * cf) + ln(wr)) / 5)
    gen double LI = 12 * wbar * (n_ee + 0.8 * n_se)
    merge 1:1 region using `grpsh', keepusing(sh_`fy' shf) nogenerate
    quietly summarize n_emp if region == "Pakistan"
    local nemp = r(mean)
    gen double G = gdp_`fy'
    replace G = gdp_`fy' * sh_`fy' if !missing(sh_`fy')
    replace G = gdp_`fy' * n_emp / `nemp' if inlist(region, "Pakistan - Male", "Pakistan - Female")
    gen double lshare = LI / (LI + 0.7 * (G - LI))
    gen double Gf = cond(missing(shf), G, gdp_`fy' * shf)
    gen double lshare_fs = LI / (LI + 0.7 * (Gf - LI))
    gen str7 year = subinstr("`fy'", "_", "-", .)
    drop sh_* shf
    tempfile l`r'
    save `l`r''
}
use `l1213', clear
append using `l1415'
append using `l1718'
append using `l2425'
nhdr_ldi, epr(epr) lshare(lshare) skill(skillprem) humcap(humcap) decent(decentwork) prefix(r_)
gen double i_ls_fs  = (lshare_fs - 0.060) / (0.723 - 0.060)
gen double ldidw_fs = exp((ln(r_i_ep) + ln(i_ls_fs) + ln(r_i_sp) + ln(r_i_hc) + ln(r_i_dw)) / 5)
display as text _n "Step 22: what moves the LDI between rounds: occupation mix, skill premium, labor share"
list region year ptop pbot wtop wbot skillprem lshare lshare_fs r_ldidw ldidw_fs ///
    if !strpos(region, " - "), noobs sepby(region) abbreviate(10)
preserve
use `t8', clear
keep region year epr lshare skillprem humcap decentwork pub_ldidw
rename (epr lshare skillprem humcap decentwork) (p_epr p_lshare p_skillprem p_humcap p_decentwork)
tempfile t8p
save `t8p'
restore
merge 1:1 region year using `t8p', keep(master match) nogenerate
* NHDR's labor share swapped in, to isolate the national accounts basis.
gen double i_ls_pub = (p_lshare - 0.060) / (0.723 - 0.060)
gen double ldidw_nhdr_ls = exp((ln(r_i_ep) + ln(i_ls_pub) + ln(r_i_sp) + ln(r_i_hc) + ln(r_i_dw)) / 5)
display as text _n "Step 22: LDI indicators from the LFS microdata, against Table 8A"
list region year epr p_epr humcap p_humcap skillprem p_skillprem decentwork p_decentwork ///
    lshare p_lshare, noobs sep(7) abbreviate(10)
display as text _n "Step 22: LDI reproduced, and with NHDR's labor share, against Table 8"
list region year r_ldidw ldidw_nhdr_ls pub_ldidw r_ldin, noobs sep(7) abbreviate(12)
gen double _g = abs(epr - p_epr)
quietly summarize _g if year != "2024-25"
nhdr_check, label("Step 22 LDI employment to population, worst of 14 [published]") ///
    got(`=r(max)') want(0) tol(0.0012)
replace _g = abs(humcap - p_humcap)
quietly summarize _g if year != "2024-25"
nhdr_check, label("Step 22 LDI human capital, worst of 14 [reference 0.185]") ///
    got(`=r(max)') want(0.185) tol(0.02)
replace _g = abs(skillprem - p_skillprem)
quietly summarize _g if year != "2024-25"
nhdr_check, label("Step 22 LDI skill premium, worst of 14 [reference 0.203]") ///
    got(`=r(max)') want(0.203) tol(0.02)
replace _g = abs(decentwork - p_decentwork)
quietly summarize _g if year == "2012-13"
nhdr_check, label("Step 22 LDI decent work 2012-13, worst of 7 [reference 0.99]") ///
    got(`=r(max)') want(0.99) tol(0.1)
replace _g = abs(ldidw_nhdr_ls - pub_ldidw)
quietly summarize _g if year != "2024-25"
nhdr_check, label("Step 22 LDI reproduced with NHDR's labor share, worst of 14 [reference 0.0098]") ///
    got(`=r(max)') want(0.0098) tol(0.002)
replace _g = abs(r_ldidw - pub_ldidw)
quietly summarize _g if year != "2024-25"
nhdr_check, label("Step 22 LDI reproduced on WDI GDP, worst of 14 [reference 0.0345]") ///
    got(`=r(max)') want(0.0345) tol(0.003)
drop _g
quietly summarize r_ldidw if year == "2024-25" & region == "Pakistan"
nhdr_check, label("Step 22 LDI 2024-25, Pakistan [reference 0.422]") got(`=r(mean)') want(0.4220) tol(0.003)
gen str40 status = cond(r_ldidw >= 0.700, "High labour development", ///
    cond(r_ldidw >= 0.550, "Medium labour development", "Low labour development"))
sort year region
export delimited using "$out/LDI 2012-13 2017-18 2024-25.csv"


*==============================================================================*
* SECTION 26A   THE FOUR-YEAR SERIES BEHIND THE REPORT FIGURES (HDI, IHDI, GDI, GII)
*==============================================================================*
* Figures 2.18, 2.20, 4.9, 4.10 and 4.11 plot four years: 2006-07, 2012-13,
* 2015-16 and 2018-19. NHDR names the rounds in its source notes: HIES
* 2005-06, 2011-12, 2015-16 and 2018-19 (Figure 4.9), PDHS for mortality,
* the LFS for earnings, PSLM and the LFS for the GII (Table 7A). This section
* builds the national series on those rounds with the rules of Sections 17,
* 20.6 and 22.2b, so that every point of those figures has a counterpart.
*   education  literacy 15+ (reads and writes) and level-matched net
*              enrolment 5-14, HIES 2005-06, 2011-12, 2015-16 and 2018-19
*   health     PDHS under-five mortality over ten years, West family: PDHS
*              2006-07, 2012-13 and 2017-18. For 2015-16, the PDHS 2017-18
*              birth histories over the ten years ending two years before
*              that survey (DHS "2 to 11 years before"), the measured period
*              nearest HIES 2015-16. Quintile rows use the PDHS wealth
*              quintile v190.
*   income     HIES consumption per head, scaled to the WDI GNI per head in
*              PPP dollars, fiscal-year average (Section 20.6)
*   GDI        education by sex from HIES; earned income by sex by the UNDP
*              split on LFS 2006-07, 2012-13, 2014-15 (PBS ran no LFS in
*              2015-16) and 2018-19, with the Census 2017 female share NHDR
*              names; life expectancy by sex from WDI (SP.DYN.LE00.FE.IN and
*              .MA.IN) for the first calendar year of the fiscal year, in all
*              four years, because NHDR's UNDP values exist for two years only
*   GII        care and schooling: HIES 2005-06, HIES 2011-12, PSLM 2014-15
*              (HIES 2015-16 has no maternity module) and HIES 2018-19;
*              participation and early marriage: LFS 2006-07, 2012-13,
*              2014-15 and 2017-18; seats: WDI SG.GEN.PARL.ZS, which equals
*              NHDR's 21.3 (2006) and 20.2 (2018)
* HIES 2011-12 numbers provinces and regions as HIES 2005-06 does; only the
* national level is used here, so no recode is needed.

* ---- 26A.1 Person files, four HIES rounds ---------------------------------------
* "Primary or higher" (GII schooling) is class 5 passed or class 6 or above
* attended now, the 2005-06 rule of Section 20.4. The 2018-19 file keeps the
* Section 18.2 rule (class 5 or above attended now), which reproduces Table
* 7A for that year.
use `h05p', clear
gen double prim = inrange(s2bq05, 5, 24) | (s2bq01 == 3 & inrange(s2bq14, 6, 24)) if age >= 10 & !missing(age)
gen byte sex = s1aq03
gen double w = weight
keep hhcode sex age w pc_exp lit15 ner prim
tempfile s05
save `s05'

use hhcode itc v1 v2 v3 v4 if inlist(itc, 1000, 2000, 4000, 5000) using "$h11/sec_6abcde.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
gen double a = v * cond(itc == 1000, 26, cond(itc == 5000, 1, 12))
collapse (sum) t_exp=a, by(hhcode)
tempfile c11
save `c11'
use hhcode idc s2aq01 s2aq02 s2bq01 s2bq05 s2bq14 using "$h11/sec_2a.dta", clear
duplicates drop hhcode idc, force
tempfile e11
save `e11'
use hhcode idc age s1aq03 weight using "$h11/plist.dta", clear
bysort hhcode: gen int hhsize = _N
merge 1:1 hhcode idc using `e11', keep(master match) nogenerate
merge m:1 hhcode using `c11', keep(master match) nogenerate
gen double pc_exp = t_exp / hhsize
gen double lit15 = (s2aq01 == 1 & s2aq02 == 1) if age >= 15 & !missing(age) & !missing(s2aq01)
gen double cls = s2bq14 if s2bq01 == 3
gen double ner = ((inrange(age, 5, 9)   & inrange(cls, 1, 5))  | ///
                  (inrange(age, 10, 12) & inrange(cls, 6, 8))  | ///
                  (inrange(age, 13, 14) & inrange(cls, 9, 10))) if inrange(age, 5, 14)
gen double prim = inrange(s2bq05, 5, 24) | (s2bq01 == 3 & inrange(s2bq14, 6, 24)) if age >= 10 & !missing(age)
gen byte sex = s1aq03
gen double w = weight
keep hhcode sex age w pc_exp lit15 ner prim
tempfile s11
save `s11'

use hhcode itc v1 v2 v3 v4 if inlist(itc, 1000, 2000, 4000, 5000) using "$h15/sec_4abcde.dta", clear
egen double v = rowtotal(v1 v2 v3 v4)
gen double a = v * cond(itc == 1000, 26, cond(itc == 5000, 1, 12))
collapse (sum) t_exp=a, by(hhcode)
tempfile c15
save `c15'
use hhcode idc s2ac01 s2ac02 s2ac05 s2ac06 s2ac07 using "$h15/sec_2a.dta", clear
duplicates drop hhcode idc, force
tempfile e15
save `e15'
use hhcode idc age s1aq04 weights using "$h15/plist.dta", clear
bysort hhcode: gen int hhsize = _N
merge 1:1 hhcode idc using `e15', keep(master match) nogenerate
merge m:1 hhcode using `c15', keep(master match) nogenerate
gen double pc_exp = t_exp / hhsize
gen double lit15 = (s2ac01 == 1 & s2ac02 == 1) if age >= 15 & !missing(age) & !missing(s2ac01)
gen double cls = s2ac07 if s2ac06 == 1
gen double ner = ((inrange(age, 5, 9)   & inrange(cls, 1, 5))  | ///
                  (inrange(age, 10, 12) & inrange(cls, 6, 8))  | ///
                  (inrange(age, 13, 14) & inrange(cls, 9, 10))) if inrange(age, 5, 14)
gen double prim = inrange(s2ac05, 5, 24) | (s2ac06 == 1 & inrange(s2ac07, 6, 24)) if age >= 10 & !missing(age)
gen byte sex = s1aq04
gen double w = weights
keep hhcode sex age w pc_exp lit15 ner prim
tempfile s15
save `s15'

use `h18p', clear
gen double prim = inrange(s2bq05, 5, 24) | (s2bq01 == 3 & inrange(s2bq14, 5, 24)) if age >= 10 & !missing(age)
gen byte sex = s1aq04
gen double w = weights
keep hhcode sex age w pc_exp lit15 ner prim
tempfile s18
save `s18'

* ---- 26A.2 Under-five mortality and life expectancy, Pakistan and wealth quintiles ----
tempfile mort
local first = 1
foreach spec in "2006-07|$pd06/PKBR53DT/PKBR53FL.DTA|0" "2012-13|$pd12/PKBR61DT/PKBR61FL.DTA|0" ///
    "2015-16|$pd17/PKBR71DT/PKBR71FL.DTA|24" "2018-19|$pd17/PKBR71DT/PKBR71FL.DTA|0" {
    tokenize "`spec'", parse("|")
    local yr `1'
    local fl `3'
    local off `5'
    use v005 v008 v024 v190 b3 b4 b5 b7 using "`fl'", clear
    nhdr_pdhs_region v024, generate(prov)
    drop if inlist(prov, "Gilgit-Baltistan", "AJK", "")
    tempfile bb m0
    save `bb'
    nhdr_q5_dhs, months(120) offset(`off')
    gen byte q = 0
    save `m0'
    use `bb', clear
    drop if missing(v190)
    nhdr_q5_dhs, months(120) offset(`off') by(v190)
    rename v190 q
    append using `m0'
    gen str7 year = "`yr'"
    if `first' == 0 append using `mort'
    save `mort', replace
    local first = 0
}
use `mort', clear
nhdr_le_from_q5 u5mr_per_1000, generate(le) family(west)
gen str3 quintile = cond(q == 0, "All", "Q" + string(q))
keep year quintile u5mr_per_1000 le births
save `mort', replace
display as text _n "Step 23A: PDHS under-five mortality and life expectancy, ten years, Pakistan"
list if quintile == "All", noobs sep(0)

* ---- 26A.3 The HDI, its quintiles and the IHDI, four years -----------------------------
tempfile hser
local first = 1
foreach spec in "2006-07|s05|2006_07" "2012-13|s11|2012_13" "2015-16|s15|2015_16" "2018-19|s18|2018_19" {
    tokenize "`spec'", parse("|")
    local yr `1'
    local pf `3'
    local g `5'
    use ``pf'', clear
    gen str8 domain = "Pakistan"
    nhdr_quintile, welfare(pc_exp) wtvar(w) by(domain) generate(q)
    tempfile pp a0
    save `pp'
    collapse (mean) lit15 ner cons=pc_exp [aw=w]
    gen str3 quintile = "All"
    save `a0'
    use `pp', clear
    drop if missing(q)
    collapse (mean) lit15 ner cons=pc_exp [aw=w], by(q)
    gen str3 quintile = "Q" + string(q)
    drop q
    append using `a0'
    replace lit15 = 100 * lit15
    replace ner   = 100 * ner
    quietly summarize cons if quintile == "All"
    gen double pci = cons * gnify_`g' / r(mean)
    gen str7 year = "`yr'"
    merge 1:1 year quintile using `mort', keep(master match) nogenerate
    if `first' == 0 append using `hser'
    save `hser', replace
    local first = 0
}
use `hser', clear
nhdr_index, literacy(lit15) enrolment(ner) life(le) income(pci) prefix(s_)
preserve
keep if quintile != "All"
nhdr_atkinson s_education_index le pci, by(year) prefix(a_)
collapse (first) a_s_education_index a_le a_pci, by(year)
rename (a_s_education_index a_le a_pci) (a_edu a_health a_inc)
tempfile atk
save `atk'
restore
merge m:1 year using `atk', nogenerate
foreach k in 1 2 3 4 5 {
    bysort year: egen double _h`k' = max(cond(quintile == "Q`k'", s_hdi, .))
}
gen double ihdi   = s_hdi * ((1 - a_edu) * (1 - a_health) * (1 - a_inc))^(1/3) if quintile == "All"
gen double loss   = 100 * (1 - ihdi / s_hdi) if quintile == "All"
gen double palma  = _h5 / _h1 if quintile == "All"
gen double pashum = (_h2 / _h1 + _h3 / _h2 + _h4 / _h3 + _h5 / _h4) / 4 - 1 if quintile == "All"
drop _h*
sort year quintile
display as text _n "Step 23A: HDI, IHDI, modified Palma and Pashum, Pakistan, four years"
list year quintile s_hdi ihdi loss palma pashum lit15 ner le pci if quintile == "All", noobs sep(0) abbreviate(8)
* The 2006-07 and 2018-19 rows must equal Section 20.6, which uses the same inputs.
preserve
use `hdiall', clear
keep if domain == "Pakistan"
keep year quintile hdi_ehi
tempfile h206
save `h206'
restore
merge 1:1 year quintile using `h206', keep(master match) nogenerate
gen double _g = abs(s_hdi - hdi_ehi)
quietly summarize _g
nhdr_check, label("Step 23A HDI series against Section 20.6, 2006-07 and 2018-19, worst of 12 [0]") ///
    got(`=r(max)') want(0) tol(0.0005)
drop _g hdi_ehi
quietly count if !missing(s_hdi)
nhdr_check, label("Step 23A HDI series cells, 4 years x 6 rows [24]") got(`=r(N)') want(24) tol(0)
export delimited using "$out/Series HDI Pakistan.csv", replace

* ---- 26A.4 Earned income by sex and the GDI, four years --------------------------------
use `lfs0607', clear
gen str1 dom = ""
nhdr_earned_income, sex(sex) active(act) earn(earn) age(age) wgt(w) domain(dom)
gen str7 year = "2006-07"
tempfile eis
save `eis'
foreach spec in "1213|2012-13" "1415|2015-16" {
    tokenize "`spec'", parse("|")
    use `lfs`1'', clear
    gen double earn = 12 * wage if employee == 1 & wage > 0 & !missing(wage)
    gen str1 dom = ""
    nhdr_earned_income, sex(sex) active(act) earn(earn) age(age) wgt(w) domain(dom)
    gen str7 year = "`3'"
    append using `eis'
    save `eis', replace
}
use `lfs18', clear
gen str1 dom = ""
nhdr_earned_income, sex(sex) active(active) earn(earn) age(age) wgt(weight) domain(dom)
gen str7 year = "2018-19"
append using `eis'
keep year ea_f wage_ratio s_f
save `eis', replace
display as text _n "Step 23A: female share of earned income, LFS, four rounds"
list, noobs sep(0)

tempfile gser
local first = 1
foreach spec in "2006-07|s05" "2012-13|s11" "2015-16|s15" "2018-19|s18" {
    tokenize "`spec'", parse("|")
    use ``3'', clear
    keep if inlist(sex, 1, 2)
    collapse (mean) lit15 ner [aw=w], by(sex)
    replace lit15 = 100 * lit15
    replace ner   = 100 * ner
    gen str7 year = "`1'"
    if `first' == 0 append using `gser'
    save `gser', replace
    local first = 0
}
import delimited using "$pub/WDI Pakistan by sex.csv", clear varnames(1) asdouble encoding(utf-8)
keep if inlist(indicator_code, "SP.DYN.LE00.FE.IN", "SP.DYN.LE00.MA.IN") & inlist(year, 2005, 2011, 2015, 2018)
gen byte sex = cond(indicator_code == "SP.DYN.LE00.FE.IN", 2, 1)
gen str7 year_s = cond(year == 2005, "2006-07", cond(year == 2011, "2012-13", cond(year == 2015, "2015-16", "2018-19")))
keep sex year_s value
rename (year_s value) (year le_sex)
tempfile lesx
save `lesx'
import delimited using "$pub/Census female share.csv", clear varnames(1) asdouble encoding(utf-8)
quietly summarize female_share if year == 2017 & region == "Pakistan"
scalar pf2017 = r(mean)
use `gser', clear
merge m:1 year using `eis', nogenerate
merge 1:1 year sex using `lesx', nogenerate
gen double pci_all = cond(year == "2006-07", gnify_2006_07, cond(year == "2012-13", gnify_2012_13, ///
    cond(year == "2015-16", gnify_2015_16, gnify_2018_19)))
gen double pci_sex = cond(sex == 2, pci_all * s_f / pf2017, pci_all * (1 - s_f) / (1 - pf2017))
nhdr_gdi_hdi, literacy(lit15) enrolment(ner) life(le_sex) income(pci_sex) prefix(g_)
bysort year (sex): gen double gdi = g_hdi[2] / g_hdi[1]
gen str6 sexname = cond(sex == 2, "Female", "Male")
sort year sex
display as text _n "Step 23A: GDI, Pakistan, four years"
list year sexname lit15 ner le_sex pci_sex g_hdi gdi, noobs sepby(year) abbreviate(8)
quietly count if !missing(gdi)
nhdr_check, label("Step 23A GDI series cells, 4 years x 2 sexes [8]") got(`=r(N)') want(8) tol(0)
export delimited using "$out/Series GDI Pakistan.csv", replace

* ---- 26A.5 The GII, four years -----------------------------------------------------------
* Care. 2006-07 and 2018-19 are Sections 20.4 and 18.2.
use `nc05', clear
keep if domain == "Pakistan"
gen str7 year = "2006-07"
keep year raw_no_care_f
rename raw_no_care_f no_care
tempfile care
save `care'
use `r_nc18', clear
keep if domain == "Pakistan"
gen str7 year_s = "2018-19"
keep year_s no_care_f
rename (year_s no_care_f) (year no_care)
append using `care'
save `care', replace
* HIES 2011-12, section 4D: s4dq01 birth since the reference date, s4dq02
* prenatal care, s4dq11 postnatal check-up (1 yes, 2 no). Household weights.
use hhcode weight using "$h11/hh_weight.dta", clear
bysort hhcode: keep if _n == 1
tempfile hw11
save `hw11'
use hhcode idc s4dq01 s4dq02 s4dq11 using "$h11/sec_4d.dta", clear
merge m:1 hhcode using `hw11', keep(master match) nogenerate
keep if s4dq01 == 1
gen double nopre  = (s4dq02 == 2) if !missing(s4dq02)
gen double nopost = (s4dq11 == 2) if !missing(s4dq11)
collapse (mean) nopre nopost [aw=weight]
gen double no_care = 100 * (nopre + nopost) / 2
gen str7 year = "2012-13"
keep year no_care
append using `care'
save `care', replace
* PSLM 2014-15, section I: siq01 birth in the last three years, siq02
* prenatal care, siq10 postnatal care within six weeks (1 yes, 2 no).
use hhcode weight using "$p14/plist.dta", clear
bysort hhcode: keep if _n == 1
tempfile hw14
save `hw14'
use hhcode idc siq01 siq02 siq10 using "$p14/sec_i.dta", clear
merge m:1 hhcode using `hw14', keep(master match) nogenerate
keep if siq01 == 1
gen double nopre  = (siq02 == 2) if !missing(siq02)
gen double nopost = (siq10 == 2) if !missing(siq10)
collapse (mean) nopre nopost [aw=weight]
gen double no_care = 100 * (nopre + nopost) / 2
gen str7 year = "2015-16"
keep year no_care
append using `care'
save `care', replace
* Schooling, primary or higher, 10 and over.
tempfile scho
local first = 1
foreach spec in "2006-07|s05" "2012-13|s11" "2018-19|s18" {
    tokenize "`spec'", parse("|")
    use ``3'', clear
    gen double prim_f = prim if sex == 2
    gen double prim_m = prim if sex == 1
    collapse (mean) prim_f prim_m [aw=w]
    gen str7 year = "`1'"
    if `first' == 0 append using `scho'
    save `scho', replace
    local first = 0
}
use hhcode idc scq04 scq05 scq06 using "$p14/sec_c.dta", clear
duplicates drop hhcode idc, force
tempfile c14
save `c14'
use hhcode idc sbq04 age weight using "$p14/plist.dta", clear
merge 1:1 hhcode idc using `c14', keep(master match) nogenerate
keep if age >= 10 & !missing(age)
gen double prim = inrange(scq04, 5, 24) | (scq05 == 1 & inrange(scq06, 6, 24))
gen double prim_f = prim if sbq04 == 2
gen double prim_m = prim if sbq04 == 1
collapse (mean) prim_f prim_m [aw=weight]
gen str7 year = "2015-16"
append using `scho'
gen double sec_f = 100 * prim_f
gen double sec_m = 100 * prim_m
keep year sec_f sec_m
save `scho', replace
* Participation 10+ and early marriage (women 15-19), LFS.
tempfile lfsg
local first = 1
foreach spec in "0607|2006-07" "1213|2012-13" "1415|2015-16" "1718|2018-19" {
    tokenize "`spec'", parse("|")
    use `lfs`1'', clear
    gen double lf_f = act if sex == 2 & age >= 10 & !missing(age)
    gen double lf_m = act if sex == 1 & age >= 10 & !missing(age)
    gen double evm  = inlist(marital, 2, 3, 4) if sex == 2 & inrange(age, 15, 19) & !missing(marital)
    collapse (mean) lf_f lf_m evm [aw=w]
    gen double lfpr_f = 100 * lf_f
    gen double lfpr_m = 100 * lf_m
    gen double evm1519 = 100 * evm
    gen str7 year = "`3'"
    keep year lfpr_f lfpr_m evm1519
    if `first' == 0 append using `lfsg'
    save `lfsg', replace
    local first = 0
}
* Seats, WDI.
import delimited using "$pub/WDI Pakistan parliament.csv", clear varnames(1) asdouble encoding(utf-8) ///
    stringcols(1 2)
keep if inlist(year, 2006, 2012, 2015, 2018)
gen str7 year_s = cond(year == 2006, "2006-07", cond(year == 2012, "2012-13", cond(year == 2015, "2015-16", "2018-19")))
gen double seats_f = value
gen double seats_m = 100 - value
keep year_s seats_f seats_m
rename year_s year
merge 1:1 year using `care', nogenerate
merge 1:1 year using `scho', nogenerate
merge 1:1 year using `lfsg', nogenerate
nhdr_gii, nocare(no_care) evmarried(evm1519) seatf(seats_f) seatm(seats_m) secf(sec_f) secm(sec_m) ///
    lfprf(lfpr_f) lfprm(lfpr_m) prefix(s_)
sort year
display as text _n "Step 23A: GII, Pakistan, four years"
list year s_gii no_care evm1519 seats_f sec_f sec_m lfpr_f lfpr_m, noobs sep(0) abbreviate(8)
quietly count if !missing(s_gii)
nhdr_check, label("Step 23A GII series, 4 years [4]") got(`=r(N)') want(4) tol(0)
export delimited using "$out/Series GII Pakistan.csv", replace

* ---- 26A.6 The WEF Global Gender Gap Index, for Figure 4.8 -------------------------------
* Not survey data: the scores as printed in each WEF edition, in 6. Raw data/Published
* with their pages (see provenance/wef_gggi_pakistan.txt).
copy "$pub/WEF GGGI Pakistan.csv" "$out/WEF GGGI Pakistan.csv", replace


*==============================================================================*
* SECTION 26   THE REPORT FIGURES AND MAPS FOR THE INDICES
*==============================================================================*
* NHDR 2020 presents its indices in Chapters 2 to 4 through figures and
* maps. Each one that rests on an index this do file reproduces is redrawn
* here from the results written above, so that the published picture and
* the reproduced picture can be read side by side.
*   Chapter 2   Figure 2.18  HDI, IHDI and the loss due to inequality
*               Figure 2.19  contribution of each dimension to inequality
*               Figure 2.20  HDI by quintile and the modified Palma ratio
*   Chapter 3   Figure 3.6   provincial HDI and its dimension indices
*               Figures 3.10, 3.13, 3.16, 3.19  HDI by quintile, provinces
*               Figure 3.22  ratio of top to bottom quintile, by dimension
*               Figure 3.23  loss due to inequality by province
*               Figure 3.28  rural and urban HDI by province
*   Chapter 4   Maps 4.1 to 4.4  CDI, YDI, LDI and GII by province, for the
*               NHDR year and for 2024-25
*               Figures 4.1, 4.4 to 4.13 and 4.15  the trend, gender and
*               dimension figures of the CDI, YDI, LDI, GDI and GII
*   Chapter 5   Figure 5.19  access to health services by wealth quintile,
*               PDHS 2017-18, is drawn in Section 8A, where the data are read
* Conventions
*   Published values are drawn as NHDR printed them. Reproduced values are
*   those of the sections above. Where a figure carries both, published
*   points are joined by solid lines and reproduced points by dashed lines, so
*   that no series mixes the two bases.
*   NHDR also plots 2012-13 and 2015-16 points from HIES 2011-12 and
*   2015-16. Those rounds are not in 6. Raw data, and those points are not drawn.
*   The maps are drawn with twoway area, part of official Stata, from the
*   geoBoundaries province polygons in 6. Raw data/Geo. No user-written package is
*   needed. Bands are those of the report: high 0.700 and above, medium
*   0.550 to 0.699, low below 0.550, on the value printed to three decimals.
*   Colors follow the ADB palette used in Section 27.1. Every figure writes
*   its data as .csv and .dta beside the .png, so that each plotted value
*   can be traced to its section.
*   Each figure is drawn inside capture noisily, so that a graphics problem
*   on a given machine cannot stop the run. Every figure is counted, and the
*   checks at the end of the section report any figure not written.

* ---- 26.0 Style, counters and helper programs --------------------------------
capture graph set window fontface "Arial"
global C1 "0 125 183"         // ADB blue
global C2 "32 181 228"        // light blue
global C3 "141 198 63"        // green
global C4 "233 83 43"         // orange
global C5 "31 45 61"          // navy
global C6 "253 184 19"        // yellow
global CG "200 200 200"       // grey, areas the indices do not cover
global GR "graphregion(color(white)) plotregion(color(white))"
* Figures are counted by nhdr_fig_done (Section 1.15). Figure 5.19 was
* counted in Section 8A.

* nhdr_map: a choropleth of the four provinces.
* Expects in memory one row per province: domain (the province name as in
* the tables), the value to shade and a label string. geo() is the polygon
* file prepared in 26.1. Gilgit-Baltistan, Azad Jammu and Kashmir and
* Islamabad Capital Territory are drawn in grey, because the provincial
* indices do not cover them.
capture program drop nhdr_map
program define nhdr_map
    syntax , VALue(varname) LABel(varname) TITle(string) FILE(string) GEO(string) [NOTE(string)]
    keep domain `value' `label'
    rename (`value' `label') (_v _lbl)
    tempfile vals
    save `vals'
    use "`geo'", clear
    merge m:1 domain using `vals', keep(master match) nogenerate
    * Bands on the value as printed, to three decimals.
    gen byte _band = 4
    replace _band = 1 if !missing(_v) & round(_v, 0.001) >= 0.700
    replace _band = 2 if !missing(_v) & round(_v, 0.001) >= 0.550 & round(_v, 0.001) < 0.700
    replace _band = 3 if !missing(_v) & round(_v, 0.001) < 0.550
    sort shape_id seq
    by shape_id: gen byte _first = (_n == 1)
    gen double _ly1 = ly + 0.30
    gen double _ly2 = ly - 0.30
    gen str40 _nm = ""
    replace _nm = upper(domain) if !missing(_v)
    gen str40 _grey = ""
    replace _grey = "Gilgit-Baltistan" if domain == "Gilgit-Baltistan"
    replace _grey = "AJK"              if domain == "Azad Kashmir"
    local cols `" "0 125 183" "32 181 228" "198 219 239" "$CG" "'
    local lb1 "High (0.700 and above)"
    local lb2 "Medium (0.550 to 0.699)"
    local lb3 "Low (below 0.550)"
    local lb4 "Not covered by the index"
    forvalues b = 1/4 {
        local first`b'
    }
    local g
    local np = 0
    levelsof shape_id, local(ids)
    foreach k of local ids {
        quietly summarize _band if shape_id == `k', meanonly
        local b = r(min)
        local c : word `b' of `cols'
        local ++np
        local g `g' (area y x if shape_id == `k', nodropbase fcolor("`c'") lcolor(white) lwidth(thin))
        if "`first`b''" == "" local first`b' `np'
    }
    local lo
    forvalues b = 1/4 {
        if "`first`b''" != "" local lo `lo' `first`b'' "`lb`b''"
    }
    quietly summarize x
    local x0 = r(min)
    local x1 = r(max)
    quietly summarize y
    local y0 = r(min)
    local y1 = r(max)
    * Equirectangular projection: a degree of longitude is cos(latitude) of
    * a degree of latitude.
    local ar = (`y1' - `y0') / ((`x1' - `x0') * cos(((`y0' + `y1') / 2) * _pi / 180))
    twoway `g' ///
        (scatter _ly1 lx if _first & _nm != "", msymbol(none) mlabel(_nm) mlabposition(0) ///
            mlabsize(small) mlabcolor(black)) ///
        (scatter _ly2 lx if _first & _nm != "", msymbol(none) mlabel(_lbl) mlabposition(0) ///
            mlabsize(small) mlabcolor(black)) ///
        (scatter ly lx if _first & _grey != "", msymbol(none) mlabel(_grey) mlabposition(0) ///
            mlabsize(vsmall) mlabcolor(gs7)), ///
        aspectratio(`ar') xscale(off range(`x0' `x1')) yscale(off range(`y0' `y1')) ///
        xlabel(none) ylabel(none) ///
        legend(order(`lo') cols(1) position(5) ring(0) size(small) region(lcolor(white))) ///
        title("`title'", size(medium) color(black)) ///
        note("`note'" "Boundaries: geoBoundaries, PAK ADM1 (public domain), for illustration only. They imply no judgment on the status of any territory.", ///
            size(vsmall)) ///
        graphregion(color(white)) plotregion(color(white))
    graph export "`file'", width(2000) replace
end

* nhdr_map_index: one map from the map data of 26.10.
* data() holds index, domain, v_nhdr (reproduced, NHDR year), p_nhdr (NHDR
* printed) and v_2425 (reproduced, 2024-25). year() is nhdr or 2425.
capture program drop nhdr_map_index
program define nhdr_map_index
    syntax , DATA(string) INDex(string) YEAR(string) TITle(string) SOURce(string) ///
        FILE(string) GEO(string)
    use "`data'", clear
    keep if index == "`index'"
    quietly summarize v_`year' if domain == "Pakistan"
    local pak = string(r(mean), "%5.3f")
    keep if domain != "Pakistan"
    gen double v = v_`year'
    gen str40 lbl = string(v, "%5.3f")
    if "`year'" == "nhdr" replace lbl = lbl + " (NHDR " + string(p_nhdr, "%5.3f") + ")" if !missing(p_nhdr)
    nhdr_map, value(v) label(lbl) geo(`geo') file(`file') title(`title') ///
        note(Pakistan `pak'. Shading and first value: this reproduction. Sources: `source'.)
end

* ---- 26.1 The province polygons -----------------------------------------------
* 6. Raw data/Geo/Pak ADM1 geoBoundaries coordinates.csv is the geoBoundaries gbOpen
* PAK ADM1 file (build of 12 December 2023) written out as one row per
* vertex: shape_id, shape_name, shape_iso, seq, lon, lat. Each polygon is a
* single closed ring. Label positions are the representative points of the
* same polygons, fixed here so that no label falls outside its province.
tempfile geo
local nvert = -1
local nnolab = -1
capture noisily {
    import delimited using "$geo/Pak ADM1 geoBoundaries coordinates.csv", clear varnames(1) ///
        asdouble encoding(utf-8) case(preserve) stringcols(2 3)
    rename (lon lat) (x y)
    gen str30 domain = shape_name
    gen double lx = .
    gen double ly = .
    replace lx = 72.32 if shape_name == "Punjab"
    replace ly = 30.89 if shape_name == "Punjab"
    replace lx = 68.74 if shape_name == "Sindh"
    replace ly = 26.12 if shape_name == "Sindh"
    replace lx = 71.65 if shape_name == "Khyber Pakhtunkhwa"
    replace ly = 34.20 if shape_name == "Khyber Pakhtunkhwa"
    replace lx = 65.83 if shape_name == "Balochistan"
    replace ly = 28.46 if shape_name == "Balochistan"
    replace lx = 74.95 if shape_name == "Gilgit-Baltistan"
    replace ly = 35.78 if shape_name == "Gilgit-Baltistan"
    replace lx = 74.00 if shape_name == "Azad Kashmir"
    replace ly = 33.30 if shape_name == "Azad Kashmir"
    replace lx = 73.01 if shape_name == "Islamabad Capital Territory"
    replace ly = 33.65 if shape_name == "Islamabad Capital Territory"
    sort shape_id seq
    save `geo'
    quietly count
    local nvert = r(N)
    quietly count if missing(lx) | missing(ly)
    local nnolab = r(N)
}
nhdr_check, label("Step 23 province polygons, vertices read [6. Raw data/Geo, 4,208]") got(`nvert') want(4208) tol(0)
nhdr_check, label("Step 23 province polygons without a label position [0]") got(`nnolab') want(0) tol(0)

* ---- 26.2 Figure 2.18: HDI, IHDI and the loss due to inequality, Pakistan ------
capture noisily {
    import delimited using "$out/IHDI 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if domain == "Pakistan"
    keep domain hdi_2024_25 ihdi_2024_25 loss_2024_25
    tempfile i24
    save `i24'
    import delimited using "$out/IHDI 2006-07 microdata.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if domain == "Pakistan"
    keep domain ihdi_raw_2006_07 loss_raw_2006_07
    tempfile i06
    save `i06'
    use `ihdi_raw', clear
    keep domain ihdi_raw loss_raw
    merge 1:1 domain using `ihdi_pub', keepusing(hdi_2006_07 hdi_2018_19 pub_hdi_2006_07 ///
        pub_hdi_2018_19 pub_ihdi_2006_07 pub_ihdi_2018_19 pub_loss_2006_07 pub_loss_2018_19) nogenerate
    merge 1:1 domain using `i06', nogenerate
    merge 1:1 domain using `i24', nogenerate
    keep if domain == "Pakistan"
    tempname fh
    tempfile f218
    postfile `fh' byte x str24 series double(hdi ihdi loss) using `f218'
    post `fh' (1) ("2006-07 NHDR")    (pub_hdi_2006_07[1]) (pub_ihdi_2006_07[1]) (pub_loss_2006_07[1])
    post `fh' (2) ("2006-07 reproduced") (hdi_2006_07[1])     (ihdi_raw_2006_07[1]) (loss_raw_2006_07[1])
    post `fh' (3) ("2018-19 NHDR")    (pub_hdi_2018_19[1]) (pub_ihdi_2018_19[1]) (pub_loss_2018_19[1])
    post `fh' (4) ("2018-19 reproduced") (hdi_2018_19[1])     (ihdi_raw[1])         (loss_raw[1])
    post `fh' (5) ("2024-25 reproduced") (hdi_2024_25[1])     (ihdi_2024_25[1])     (loss_2024_25[1])
    postclose `fh'
    use `f218', clear
    gen double xh = x - 0.18
    gen double xi = x + 0.18
    gen double ytop = 0.75
    gen str8 lh = string(hdi, "%5.3f")
    gen str8 li = string(ihdi, "%5.3f")
    gen str16 ll = "loss " + string(loss, "%4.1f") + "%"
    save "$out/Figure 2.18 data.dta", replace
    export delimited using "$out/Figure 2.18 data.csv", replace
    twoway (bar hdi xh, barwidth(0.34) color("$C1")) ///
        (bar ihdi xi, barwidth(0.34) color("$C2")) ///
        (scatter hdi xh, msymbol(none) mlabel(lh) mlabposition(12) mlabsize(vsmall) mlabcolor(black)) ///
        (scatter ihdi xi, msymbol(none) mlabel(li) mlabposition(12) mlabsize(vsmall) mlabcolor(black)) ///
        (scatter ytop x, msymbol(none) mlabel(ll) mlabposition(0) mlabsize(small) mlabcolor("$C4")), ///
        xlabel(1 "2006-07 NHDR" 2 "2006-07 reproduced" 3 "2018-19 NHDR" 4 "2018-19 reproduced" ///
            5 "2024-25 reproduced", labsize(small) noticks) xtitle("") xscale(range(0.5 5.5)) ///
        ylabel(0(0.1)0.8, angle(0) format(%3.1f) labsize(small)) yscale(range(0 0.8)) ///
        ytitle("HDI and IHDI", size(small)) ///
        legend(order(1 "HDI" 2 "IHDI") rows(1) position(6) size(small)) ///
        title("Figure 2.18  Loss in human development due to inequality, Pakistan", size(medium)) ///
        note("Orange: loss due to inequality, percent. NHDR: Table 3 as printed. Reproduced: Sections 16.2, 16.3" ///
            "and 20.5, inequality across the five consumption quintiles. The report's 2012-13 and 2015-16" ///
            "points rest on HIES rounds not in 6. Raw data.", size(vsmall)) $GR
    graph export "$out/Figure 2.18 IHDI loss.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 2.18 IHDI loss.png"

* ---- 26.3 Figure 2.19: the contribution of each dimension to inequality --------
* Pakistan 2018-19. Each dimension's Atkinson value as a share of their sum.
capture noisily {
    use `ihdi_raw', clear
    keep if domain == "Pakistan"
    local t  = a_inc_raw[1] + a_edu_raw[1] + a_le_mics[1]
    local mi = 100 * a_inc_raw[1] / `t'
    local me = 100 * a_edu_raw[1] / `t'
    local mh = 100 * a_le_mics[1] / `t'
    use `ihdi_pd', clear
    keep if domain == "Pakistan"
    local t  = a_inc_raw[1] + a_edu_raw[1] + a_le_pdhs[1]
    local pi = 100 * a_inc_raw[1] / `t'
    local pe = 100 * a_edu_raw[1] / `t'
    local ph = 100 * a_le_pdhs[1] / `t'
    use `ihdi_pub', clear
    keep if domain == "Pakistan"
    local ti = share_inc_2018_19[1]
    local te = share_edu_2018_19[1]
    local th = share_health_2018_19[1]
    clear
    set obs 4
    gen byte order = _n
    gen str44 basis = ""
    replace basis = "NHDR 2020, Figure 2.19"              in 1
    replace basis = "NHDR method, Table 2A quintiles"     in 2
    replace basis = "Microdata, MICS6 health"             in 3
    replace basis = "Microdata, PDHS 2017-18 health"      in 4
    gen double income    = .
    gen double education = .
    gen double health    = .
    replace income    = bm_ihdi_contrib_income_1819 in 1
    replace education = bm_ihdi_contrib_edu_1819    in 1
    replace health    = bm_ihdi_contrib_health_1819 in 1
    replace income    = `ti' in 2
    replace education = `te' in 2
    replace health    = `th' in 2
    replace income    = `mi' in 3
    replace education = `me' in 3
    replace health    = `mh' in 3
    replace income    = `pi' in 4
    replace education = `pe' in 4
    replace health    = `ph' in 4
    save "$out/Figure 2.19 data.dta", replace
    export delimited using "$out/Figure 2.19 data.csv", replace
    graph hbar (asis) income education health, over(basis, sort(order) label(labsize(small))) stack ///
        bar(1, color("$C1")) bar(2, color("$C3")) bar(3, color("$C4")) ///
        blabel(bar, position(center) format(%3.0f) size(small) color(white)) ///
        ylabel(0(20)100, labsize(small)) ytitle("Percent of the summed inequality", size(small)) ///
        legend(order(1 "Income" 2 "Education" 3 "Health") rows(1) position(6) size(small)) ///
        title("Figure 2.19  Income inequality is the main source of the loss, Pakistan 2018-19", ///
            size(medium)) ///
        note("Shares of the three Atkinson values (aversion 1) across the consumption quintiles. Microdata" ///
            "health: under-five mortality by wealth quintile, MICS6 (Section 16.2) and PDHS 2017-18 (16.2b).", ///
            size(vsmall)) $GR
    graph export "$out/Figure 2.19 IHDI components.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 2.19 IHDI components.png"

* ---- 26.4 Figure 2.20: HDI by quintile, Pakistan, and the modified Palma ratio -
capture noisily {
    use `q5pub', clear
    keep if domain == "Pakistan"
    keep quintile q2006_07_hdi q2018_19_hdi
    sort quintile
    local p06 = string(palma_2006_07, "%4.2f")
    local p18 = string(palma_2018_19, "%4.2f")
    save "$out/Figure 2.20 data.dta", replace
    export delimited using "$out/Figure 2.20 data.csv", replace
    graph bar (asis) q2006_07_hdi q2018_19_hdi, over(quintile, label(labsize(small))) ///
        bar(1, color("$C2")) bar(2, color("$C1")) ///
        blabel(bar, format(%5.3f) size(vsmall)) ///
        ylabel(0(0.1)0.8, angle(0) format(%3.1f) labsize(small)) ytitle("HDI", size(small)) ///
        legend(order(1 "2006-07" 2 "2018-19") rows(1) position(6) size(small)) ///
        title("Figure 2.20  HDI by consumption quintile, Pakistan", size(medium)) ///
        note("Quintile HDI from the Table 2A quintile inputs on the recovered construction (Section 5)." ///
            "Modified Palma ratio, HDI of Q5 over Q1: `p06' in 2006-07 and `p18' in 2018-19 (NHDR 1.73, 1.67).", ///
            size(vsmall)) $GR
    graph export "$out/Figure 2.20 HDI quintiles.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 2.20 HDI quintiles.png"

* ---- 26.5 Figure 3.6: provincial HDI and its dimension indices, 2018-19 -------
capture noisily {
    use `t1', clear
    keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    gen byte order = 1
    replace order = 2 if domain == "Punjab"
    replace order = 3 if domain == "Sindh"
    replace order = 4 if domain == "Khyber Pakhtunkhwa"
    replace order = 5 if domain == "Balochistan"
    keep domain order edu_idx_2018_19 health_idx_2018_19 income_idx_2018_19 hdi_2018_19
    save "$out/Figure 3.6 data.dta", replace
    export delimited using "$out/Figure 3.6 data.csv", replace
    graph bar (asis) edu_idx_2018_19 health_idx_2018_19 income_idx_2018_19 hdi_2018_19, ///
        over(domain, sort(order) label(labsize(small))) ///
        bar(1, color("$C3")) bar(2, color("$C4")) bar(3, color("$C2")) bar(4, color("$C1")) ///
        blabel(bar, format(%4.3f) size(tiny)) ///
        ylabel(0(0.2)1, angle(0) format(%3.1f) labsize(small)) ytitle("Index", size(small)) ///
        legend(order(1 "Education" 2 "Health" 3 "Income" 4 "HDI") rows(1) position(6) size(small)) ///
        title("Figure 3.6  Provincial human development index, 2018-19", size(medium)) ///
        note("NHDR 2020 Table 1 as printed. Section 5 reproduces all 120 values to within 0.0011.", ///
            size(vsmall)) $GR
    graph export "$out/Figure 3.6 provincial HDI.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 3.6 provincial HDI.png"

* ---- 26.6 Figures 3.10, 3.13, 3.16, 3.19: HDI by quintile within each province -
capture noisily {
    use `q5pub', clear
    keep if inlist(domain, "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    gen byte order = 1
    replace order = 2 if domain == "Sindh"
    replace order = 3 if domain == "Khyber Pakhtunkhwa"
    replace order = 4 if domain == "Balochistan"
    keep domain order quintile q2018_19_hdi
    save "$out/Figure 3.10 data.dta", replace
    export delimited using "$out/Figure 3.10 data.csv", replace
    graph bar (asis) q2018_19_hdi, over(quintile) over(domain, sort(order) label(labsize(small))) ///
        asyvars bar(1, color("198 219 239")) bar(2, color("133 185 225")) bar(3, color("$C2")) ///
        bar(4, color("$C1")) bar(5, color("$C5")) ///
        blabel(bar, format(%4.3f) size(tiny)) ///
        ylabel(0(0.2)0.8, angle(0) format(%3.1f) labsize(small)) ytitle("HDI", size(small)) ///
        legend(order(1 "Q1 poorest" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 richest") rows(1) position(6) size(small)) ///
        title("Figures 3.10 to 3.19  The richest quintiles enjoy higher human development, 2018-19", ///
            size(medium)) ///
        note("Quintiles of consumption per head cut within each province. Inputs: NHDR 2020 Table 2A.", ///
            size(vsmall)) $GR
    graph export "$out/Figure 3.10 quintile HDI provinces.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 3.10 quintile HDI provinces.png"

* ---- 26.7 Figure 3.22: ratio of the top to the bottom quintile, by dimension ---
capture noisily {
    use `q5pub', clear
    keep if inlist(quintile, "Q1", "Q5")
    keep domain quintile q2018_19_education_index q2018_19_health_index q2018_19_income_index q2018_19_hdi
    rename (q2018_19_education_index q2018_19_health_index q2018_19_income_index q2018_19_hdi) (e h i d)
    reshape wide e h i d, i(domain) j(quintile) string
    gen double education = eQ5 / eQ1
    gen double health    = hQ5 / hQ1
    gen double income    = iQ5 / iQ1
    gen double hdi       = dQ5 / dQ1
    gen byte order = 1
    replace order = 2 if domain == "Punjab"
    replace order = 3 if domain == "Sindh"
    replace order = 4 if domain == "Khyber Pakhtunkhwa"
    replace order = 5 if domain == "Balochistan"
    keep domain order education health income hdi
    save "$out/Figure 3.22 data.dta", replace
    export delimited using "$out/Figure 3.22 data.csv", replace
    graph bar (asis) education health income hdi, over(domain, sort(order) label(labsize(small))) ///
        bar(1, color("$C3")) bar(2, color("$C4")) bar(3, color("$C2")) bar(4, color("$C1")) ///
        blabel(bar, format(%4.2f) size(tiny)) yline(1, lcolor(gs8) lpattern(dash)) ///
        ylabel(0(0.5)3.5, angle(0) format(%3.1f) labsize(small)) ///
        ytitle("Index of Q5 over index of Q1", size(small)) ///
        legend(order(1 "Education" 2 "Health" 3 "Income" 4 "HDI") rows(1) position(6) size(small)) ///
        title("Figure 3.22  Education drives the gap between the richest and poorest quintiles, 2018-19", ///
            size(medium)) ///
        note("Dimension indices of the richest and poorest consumption quintiles, NHDR 2020 Table 2A.", ///
            size(vsmall)) $GR
    graph export "$out/Figure 3.22 top bottom ratio.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 3.22 top bottom ratio.png"

* ---- 26.8 Figure 3.23: loss due to inequality by province ----------------------
capture noisily {
    import delimited using "$out/IHDI 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep domain loss_2024_25
    tempfile l24
    save `l24'
    use `ihdi_raw', clear
    keep domain loss_raw
    merge 1:1 domain using `ihdi_pub', keepusing(pub_loss_2018_19) nogenerate
    merge 1:1 domain using `l24', nogenerate
    gen byte order = 1
    replace order = 2 if domain == "Punjab"
    replace order = 3 if domain == "Sindh"
    replace order = 4 if domain == "Khyber Pakhtunkhwa"
    replace order = 5 if domain == "Balochistan"
    keep domain order pub_loss_2018_19 loss_raw loss_2024_25
    save "$out/Figure 3.23 data.dta", replace
    export delimited using "$out/Figure 3.23 data.csv", replace
    graph hbar (asis) pub_loss_2018_19 loss_raw loss_2024_25, over(domain, sort(order) label(labsize(small))) ///
        bar(1, color("$C1")) bar(2, color("$C2")) bar(3, color("$C4")) ///
        blabel(bar, format(%4.1f) size(vsmall)) ///
        ylabel(0(2)12, labsize(small)) ytitle("Loss due to inequality, percent", size(small)) ///
        legend(order(1 "2018-19, NHDR Table 3" 2 "2018-19, reproduced" 3 "2024-25, reproduced") rows(1) ///
            position(6) size(small)) ///
        title("Figure 3.23  The loss of human development due to inequality, by province", size(medium)) ///
        note("Reproduced: Section 16.2 (2018-19) and Section 16.3 (2024-25).", size(vsmall)) $GR
    graph export "$out/Figure 3.23 loss provinces.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 3.23 loss provinces.png"

* ---- 26.9 Figure 3.28: rural and urban HDI by province -------------------------
capture noisily {
    use "$out/Provincial index 2024-25 final.dta", clear
    keep domain hdi hdi_2018_19
    rename hdi hdi_2024_25
    keep if strpos(domain, "-Urban") > 0 | strpos(domain, "-Rural") > 0
    gen str20 province = substr(domain, 1, strpos(domain, "-") - 1)
    gen str5 area = substr(domain, strpos(domain, "-") + 1, .)
    gen byte order = 1
    replace order = 2 if province == "Punjab"
    replace order = 3 if province == "Sindh"
    replace order = 4 if province == "Khyber Pakhtunkhwa"
    replace order = 5 if province == "Balochistan"
    keep province area order hdi_2018_19 hdi_2024_25
    save "$out/Figure 3.28 data.dta", replace
    export delimited using "$out/Figure 3.28 data.csv", replace
    graph bar (asis) hdi_2018_19 hdi_2024_25, over(area, label(labsize(vsmall))) ///
        over(province, sort(order) label(labsize(small))) ///
        bar(1, color("$C1")) bar(2, color("$C4")) ///
        blabel(bar, format(%4.3f) size(tiny)) ///
        ylabel(0(0.2)0.8, angle(0) format(%3.1f) labsize(small)) ytitle("HDI", size(small)) ///
        legend(order(1 "2018-19, NHDR Table 1" 2 "2024-25, reproduced (Section 13)") rows(1) ///
            position(6) size(small)) ///
        title("Figure 3.28  Rural and urban human development, by province", size(medium)) ///
        note("The first pair is Pakistan's urban and rural areas.", size(vsmall)) $GR
    graph export "$out/Figure 3.28 rural urban HDI.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 3.28 rural urban HDI.png"

* ---- 26.10 Maps 4.1 to 4.4: CDI, YDI, LDI and GII by province ------------------
* For each index, the NHDR year and 2024-25. The map shades the reproduced
* value and prints NHDR's own value beside it for the NHDR year.
tempfile mapd
local nmap = -1
capture noisily {
    * CDI, 2018-19 and 2024-25.
    * The CDI with its PDHS inputs reproduced (Sections 23.4b and 23.5b).
    import delimited using "$out/CDI reproduced PDHS.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if year == "2018-19"
    keep region h_cdi pub_cdi
    rename (region h_cdi pub_cdi) (domain v_nhdr p_nhdr)
    tempfile m1
    save `m1'
    import delimited using "$out/CDI 2024-25 PDHS.csv", clear varnames(1) asdouble encoding(utf-8) case(preserve)
    keep region c24h_cdi
    rename (region c24h_cdi) (domain v_2425)
    merge 1:1 domain using `m1', nogenerate
    gen str4 index = "cdi"
    save `mapd'
    * YDI, 2017-18 and 2024-25.
    import delimited using "$out/YDI 2017-18 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if inlist(region, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    keep if inlist(year, "2017-18", "2024-25")
    gen str4 yy = cond(year == "2017-18", "nhdr", "2425")
    keep region yy r_ydi pub_ydi
    reshape wide r_ydi pub_ydi, i(region) j(yy) string
    rename (region r_ydinhdr pub_ydinhdr r_ydi2425) (domain v_nhdr p_nhdr v_2425)
    keep domain v_nhdr p_nhdr v_2425
    gen str4 index = "ydi"
    append using `mapd'
    save `mapd', replace
    * LDI, 2017-18 and 2024-25.
    import delimited using "$out/LDI 2012-13 2017-18 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if inlist(year, "2017-18", "2024-25")
    keep if inlist(region, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    gen str4 yy = cond(year == "2017-18", "nhdr", "2425")
    keep region yy r_ldidw pub_ldidw
    reshape wide r_ldidw pub_ldidw, i(region) j(yy) string
    rename (region r_ldidwnhdr pub_ldidwnhdr r_ldidw2425) (domain v_nhdr p_nhdr v_2425)
    keep domain v_nhdr p_nhdr v_2425
    gen str4 index = "ldi"
    append using `mapd'
    save `mapd', replace
    * GII, 2018-19 and 2024-25.
    import delimited using "$out/GII 2024-25.csv", clear varnames(1) asdouble encoding(utf-8) case(preserve)
    keep domain g24_gii raw_gii pub_gii
    rename (g24_gii raw_gii pub_gii) (v_2425 v_nhdr p_nhdr)
    gen str4 index = "gii"
    append using `mapd'
    save `mapd', replace
    save "$out/Figure maps data.dta", replace
    export delimited using "$out/Figure maps data.csv", replace
    quietly count if !missing(v_nhdr) & !missing(v_2425)
    local nmap = r(N)
}
nhdr_check, label("Step 23 map values present, 4 indices x 5 domains x 2 years [20]") got(`nmap') want(20) tol(0)

capture noisily nhdr_map_index, data(`mapd') index(cdi) year(nhdr) geo(`geo') ///
    title(Map 4.1  Pakistan Child Development Index, 2018-19) ///
    source(HIES 2018-19, LFS 2017-18, PDHS 2017-18 microdata, Sections 8A and 23.4b) ///
    file("$out/Map 4.1 CDI 2018-19.png")
nhdr_fig_done "$out/Map 4.1 CDI 2018-19.png"
capture noisily nhdr_map_index, data(`mapd') index(cdi) year(2425) geo(`geo') ///
    title(Map 4.1 extended  Child Development Index, 2024-25) ///
    source(HIES 2024-25, LFS 2024-25, PDHS 2017-18 microdata held, Section 23.5b) ///
    file("$out/Map 4.1 CDI 2024-25.png")
nhdr_fig_done "$out/Map 4.1 CDI 2024-25.png"
capture noisily nhdr_map_index, data(`mapd') index(ydi) year(nhdr) geo(`geo') ///
    title(Map 4.2  Pakistan Youth Development Index, 2017-18) ///
    source(LFS 2017-18 with Islamabad in Punjab, survival as printed, Section 24) ///
    file("$out/Map 4.2 YDI 2017-18.png")
nhdr_fig_done "$out/Map 4.2 YDI 2017-18.png"
capture noisily nhdr_map_index, data(`mapd') index(ydi) year(2425) geo(`geo') ///
    title(Map 4.2 extended  Youth Development Index, 2024-25) ///
    source(LFS 2024-25, Section 24.2) ///
    file("$out/Map 4.2 YDI 2024-25.png")
nhdr_fig_done "$out/Map 4.2 YDI 2024-25.png"
capture noisily nhdr_map_index, data(`mapd') index(ldi) year(nhdr) geo(`geo') ///
    title(Map 4.3  Pakistan Labour Development Index, 2017-18) ///
    source(LFS 2017-18 and WDI GDP with Pasha shares, Section 25) ///
    file("$out/Map 4.3 LDI 2017-18.png")
nhdr_fig_done "$out/Map 4.3 LDI 2017-18.png"
capture noisily nhdr_map_index, data(`mapd') index(ldi) year(2425) geo(`geo') ///
    title(Map 4.3 extended  Labour Development Index, 2024-25) ///
    source(LFS 2024-25, Section 25.2) ///
    file("$out/Map 4.3 LDI 2024-25.png")
nhdr_fig_done "$out/Map 4.3 LDI 2024-25.png"
capture noisily nhdr_map_index, data(`mapd') index(gii) year(nhdr) geo(`geo') ///
    title(Map 4.4  Pakistan Gender Inequality Index, 2018-19) ///
    source(HIES 2018-19 and LFS 2018-19 with seats as printed, Section 18.2) ///
    file("$out/Map 4.4 GII 2018-19.png")
nhdr_fig_done "$out/Map 4.4 GII 2018-19.png"
capture noisily nhdr_map_index, data(`mapd') index(gii) year(2425) geo(`geo') ///
    title(Map 4.4 extended  Gender Inequality Index, 2024-25) ///
    source(HIES 2024-25 and LFS 2024-25 with the 2018 seats held, Section 18.3) ///
    file("$out/Map 4.4 GII 2024-25.png")
nhdr_fig_done "$out/Map 4.4 GII 2024-25.png"

* ---- 26.11 Figure 4.1: the national YDI and its sub-indices --------------------
* Published: Table 5, 2001-02 and 2017-18. Reproduced: Section 24, 2017-18 and
* 2024-25. Series: 1 YDI, 2 schooling, 3 employment to population, 4 higher
* education, 5 full employment, 6 survival.
capture noisily {
    tempname fh
    tempfile f41
    postfile `fh' byte(s basis) double(yr val) using `f41'
    use `t5', clear
    keep if region == "Pakistan"
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2001-02", 2001.5, 2017.5)
        local j = 0
        foreach v in pub_ydi pub_mys_idx pub_epr_idx pub_hied_idx pub_full_idx pub_surv_idx {
            local ++j
            post `fh' (`j') (1) (`y') (`v'[`i'])
        }
    }
    import delimited using "$out/YDI 2017-18 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if region == "Pakistan"
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2017-18", 2017.5, 2024.5)
        local j = 0
        foreach v in r_ydi r_i_mys r_i_epr r_i_hied r_i_full r_i_surv {
            local ++j
            post `fh' (`j') (2) (`y') (`v'[`i'])
        }
    }
    postclose `fh'
    use `f41', clear
    save "$out/Figure 4.1 data.dta", replace
    export delimited using "$out/Figure 4.1 data.csv", replace
    local cols `" "$C5" "$C1" "$C2" "$C3" "$C4" "$C6" "'
    local g
    forvalues k = 1/6 {
        local c : word `k' of `cols'
        local w = cond(`k' == 1, "thick", "medthin")
        local g `g' (connected val yr if s == `k' & basis == 1, sort lcolor("`c'") mcolor("`c'") lwidth(`w') msymbol(O))
        local g `g' (connected val yr if s == `k' & basis == 2, sort lcolor("`c'") mcolor("`c'") lwidth(`w') lpattern(dash) msymbol(Oh))
    }
    twoway `g', ///
        xlabel(2001.5 "2001-02" 2017.5 "2017-18" 2024.5 "2024-25", labsize(small)) xtitle("") ///
        xscale(range(2000 2026)) ylabel(0(0.2)1, angle(0) format(%3.1f) labsize(small)) ///
        ytitle("Index", size(small)) ///
        legend(order(1 "YDI" 3 "Years of schooling" 5 "Employment to population" ///
            7 "Higher education" 9 "Fully employed" 11 "Youth survival") rows(2) position(6) size(small)) ///
        title("Figure 4.1  The national Youth Development Index and its sub-indices", size(medium)) ///
        note("Solid: NHDR 2020 Table 5. Dashed: reproduced from LFS 2017-18 and 2024-25 (Section 24). Survival" ///
            "is PMMS 2019 in both reproduced years. LFS 2001-02 microdata are not in 6. Raw data.", size(vsmall)) $GR
    graph export "$out/Figure 4.1 YDI trend.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.1 YDI trend.png"

* ---- 26.12 Figure 4.4: the LDI with and without decent work --------------------
* Published: Table 8 (LDI with decent work) and the geometric mean of the
* four other printed indices (LDI normal), 2012-13 and 2017-18. Reproduced:
* Section 25, 2012-13, 2017-18 and 2024-25.
capture noisily {
    tempname fh
    tempfile f44
    postfile `fh' byte(s basis) double(yr val) using `f44'
    use `t8', clear
    keep if region == "Pakistan"
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2012-13", 2012.5, 2017.5)
        post `fh' (1) (1) (`y') (pub_ldidw[`i'])
        post `fh' (2) (1) (`y') (m_ldin[`i'])
    }
    import delimited using "$out/LDI 2012-13 2017-18 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if region == "Pakistan"
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2012-13", 2012.5, cond(year[`i'] == "2017-18", 2017.5, 2024.5))
        post `fh' (1) (2) (`y') (r_ldidw[`i'])
        post `fh' (2) (2) (`y') (r_ldin[`i'])
    }
    postclose `fh'
    use `f44', clear
    gen str8 lb = string(val, "%5.3f")
    save "$out/Figure 4.4 data.dta", replace
    export delimited using "$out/Figure 4.4 data.csv", replace
    twoway (connected val yr if s == 1 & basis == 1, sort lcolor("$C1") mcolor("$C1") msymbol(O) ///
            mlabel(lb) mlabposition(12) mlabsize(vsmall) mlabcolor("$C1")) ///
        (connected val yr if s == 2 & basis == 1, sort lcolor("$C4") mcolor("$C4") msymbol(O) ///
            mlabel(lb) mlabposition(6) mlabsize(vsmall) mlabcolor("$C4")) ///
        (connected val yr if s == 1 & basis == 2, sort lcolor("$C1") mcolor("$C1") lpattern(dash) msymbol(Oh)) ///
        (connected val yr if s == 2 & basis == 2, sort lcolor("$C4") mcolor("$C4") lpattern(dash) msymbol(Oh)), ///
        xlabel(2012.5 "2012-13" 2017.5 "2017-18" 2024.5 "2024-25", labsize(small)) xtitle("") ///
        xscale(range(2011 2026)) ylabel(0.30(0.05)0.50, angle(0) format(%4.2f) labsize(small)) ///
        ytitle("Index", size(small)) ///
        legend(order(1 "LDI with decent work, NHDR" 2 "LDI normal, NHDR inputs" 3 "LDI with decent work, reproduced" ///
            4 "LDI normal, reproduced") rows(2) position(6) size(small)) ///
        title("Figure 4.4  Labour development with and without decent work, Pakistan", size(medium)) ///
        note("Reproduced: LFS 2012-13, 2017-18 and 2024-25 with WDI GDP (Section 25). The reproduced labour share sits below" ///
            "NHDR's because NHDR used the pre-2017 national accounts (see Section 25).", size(vsmall)) $GR
    graph export "$out/Figure 4.4 LDI trend.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.4 LDI trend.png"

* ---- 26.13 Figure 4.5: change in the dimensions of the national LDI ------------
capture noisily {
    use `t8', clear
    keep if region == "Pakistan"
    sort year
    local j = 0
    foreach v in pub_epr_idx pub_lshare_idx pub_sp_idx pub_hc_idx pub_dw_idx {
        local ++j
        local p`j' = 100 * (`v'[2] / `v'[1] - 1)
    }
    import delimited using "$out/LDI 2012-13 2017-18 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if region == "Pakistan"
    sort year
    local j = 0
    foreach v in r_i_ep r_i_ls r_i_sp r_i_hc r_i_dw {
        local ++j
        local a`j' = 100 * (`v'[2] / `v'[1] - 1)
        local b`j' = 100 * (`v'[3] / `v'[2] - 1)
    }
    clear
    set obs 5
    gen byte order = _n
    gen str30 dimension = ""
    replace dimension = "Employment to population" in 1
    replace dimension = "Share of labour income"   in 2
    replace dimension = "Skill premium"            in 3
    replace dimension = "Human capital"            in 4
    replace dimension = "Incidence of decent work" in 5
    gen double nhdr_1213_1718 = .
    gen double reproduced_1213_1718 = .
    gen double reproduced_1718_2425 = .
    forvalues k = 1/5 {
        replace nhdr_1213_1718    = `p`k'' in `k'
        replace reproduced_1213_1718 = `a`k'' in `k'
        replace reproduced_1718_2425 = `b`k'' in `k'
    }
    save "$out/Figure 4.5 data.dta", replace
    export delimited using "$out/Figure 4.5 data.csv", replace
    graph hbar (asis) nhdr_1213_1718 reproduced_1213_1718 reproduced_1718_2425, ///
        over(dimension, sort(order) label(labsize(small))) ///
        bar(1, color("$C1")) bar(2, color("$C2")) bar(3, color("$C4")) ///
        blabel(bar, format(%4.1f) size(vsmall)) yline(0, lcolor(gs8)) ///
        ylabel(, labsize(small)) ytitle("Change in the dimension index, percent", size(small)) ///
        legend(order(1 "2012-13 to 2017-18, NHDR" 2 "2012-13 to 2017-18, reproduced" ///
            3 "2017-18 to 2024-25, reproduced") rows(1) position(6) size(small)) ///
        title("Figure 4.5  Changes in the dimensions of the national Labour Development Index", size(medium)) ///
        note("Dimension indices of Table 8 (NHDR) and Section 25 (reproduced).", size(vsmall)) $GR
    graph export "$out/Figure 4.5 LDI dimension change.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.5 LDI dimension change.png"

* ---- 26.14 Figure 4.6: provincial LDI and its dimensions, 2017-18 --------------
capture noisily {
    use `t8', clear
    keep if year == "2017-18" & inlist(region, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    gen byte order = 1
    replace order = 2 if region == "Punjab"
    replace order = 3 if region == "Sindh"
    replace order = 4 if region == "Khyber Pakhtunkhwa"
    replace order = 5 if region == "Balochistan"
    keep region order pub_epr_idx pub_lshare_idx pub_sp_idx pub_hc_idx pub_dw_idx pub_ldidw
    save "$out/Figure 4.6 data.dta", replace
    export delimited using "$out/Figure 4.6 data.csv", replace
    graph bar (asis) pub_epr_idx pub_lshare_idx pub_sp_idx pub_hc_idx pub_dw_idx pub_ldidw, ///
        over(region, sort(order) label(labsize(small))) ///
        bar(1, color("$C2")) bar(2, color("$C3")) bar(3, color("$C6")) bar(4, color("$C4")) ///
        bar(5, color("$C5")) bar(6, color("$C1")) ///
        blabel(bar, format(%4.2f) size(tiny)) ///
        ylabel(0(0.2)1, angle(0) format(%3.1f) labsize(small)) ytitle("Index", size(small)) ///
        legend(order(1 "Employment to population" 2 "Labour share" 3 "Skill premium" 4 "Human capital" ///
            5 "Decent work" 6 "LDI") rows(2) position(6) size(small)) ///
        title("Figure 4.6  Provincial Labour Development Index by dimension, 2017-18", size(medium)) ///
        note("NHDR 2020 Table 8 as printed. Section 25.1 reproduces every dimension index from Table 8A.", ///
            size(vsmall)) $GR
    graph export "$out/Figure 4.6 LDI provinces.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.6 LDI provinces.png"

* ---- 26.15 Figure 4.7: the gender-based CDI over time --------------------------
* Published: Table 4, Pakistan, all children, boys and girls, 2007-08 and
* 2018-19. Reproduced with the PDHS inputs from the microdata: all children,
* Section 23.4b (2007-08 and 2018-19), and the 2024-25 basis of Section
* 23.5b (2018-19 recomputed and 2024-25).
capture noisily {
    tempname fh
    tempfile f47
    postfile `fh' byte s double(yr val) using `f47'
    use `t4', clear
    keep if region == "Pakistan"
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2007-08", 2007.5, 2018.5)
        local k = cond(sex[`i'] == "All", 1, cond(sex[`i'] == "Male", 2, 3))
        post `fh' (`k') (`y') (pub_cdi[`i'])
    }
    import delimited using "$out/CDI reproduced PDHS.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if region == "Pakistan"
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2007-08", 2007.5, 2018.5)
        post `fh' (4) (`y') (h_cdi[`i'])
    }
    import delimited using "$out/CDI 2024-25 PDHS.csv", clear varnames(1) asdouble encoding(utf-8) case(preserve)
    keep if region == "Pakistan"
    post `fh' (5) (2018.5) (c18h_cdi[1])
    post `fh' (5) (2024.5) (c24h_cdi[1])
    postclose `fh'
    use `f47', clear
    gen str8 lb = string(val, "%5.3f")
    save "$out/Figure 4.7 data.dta", replace
    export delimited using "$out/Figure 4.7 data.csv", replace
    twoway (connected val yr if s == 1, sort lcolor("$C1") mcolor("$C1") msymbol(O) lwidth(thick)) ///
        (connected val yr if s == 2, sort lcolor("$C2") mcolor("$C2") msymbol(O)) ///
        (connected val yr if s == 3, sort lcolor("$C4") mcolor("$C4") msymbol(O)) ///
        (connected val yr if s == 4, sort lcolor("$C1") mcolor("$C1") lpattern(dash) msymbol(Oh)) ///
        (connected val yr if s == 5, sort lcolor("$C5") mcolor("$C5") lpattern(shortdash) msymbol(Dh) ///
            mlabel(lb) mlabposition(12) mlabsize(vsmall) mlabcolor("$C5")), ///
        xlabel(2007.5 "2007-08" 2018.5 "2018-19" 2024.5 "2024-25", labsize(small)) xtitle("") ///
        xscale(range(2006 2026)) ylabel(0.40(0.05)0.65, angle(0) format(%4.2f) labsize(small)) ///
        ytitle("Child Development Index", size(small)) ///
        legend(order(1 "All children, NHDR" 2 "Boys, NHDR" 3 "Girls, NHDR" 4 "All children, reproduced" ///
            5 "All children, 2024-25 basis") rows(2) position(6) size(small)) ///
        title("Figure 4.7  Trends in the gender-based Child Development Index, Pakistan", size(medium)) ///
        note("The 2024-25 basis counts child work as employment only (Section 23.5), so it is drawn apart." ///
            "The report's 2001-02 point rests on rounds not in 6. Raw data.", size(vsmall)) $GR
    graph export "$out/Figure 4.7 CDI gender trend.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.7 CDI gender trend.png"

* ---- 26.16 Figure 4.8: the gender-based YDI over time --------------------------
capture noisily {
    tempname fh
    tempfile f48
    postfile `fh' byte(s basis) double(yr val) using `f48'
    use `t5', clear
    keep if inlist(region, "Pakistan - Male", "Pakistan - Female")
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2001-02", 2001.5, 2017.5)
        local k = cond(region[`i'] == "Pakistan - Male", 1, 2)
        post `fh' (`k') (1) (`y') (pub_ydi[`i'])
    }
    import delimited using "$out/YDI 2017-18 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if inlist(region, "Pakistan - Male", "Pakistan - Female")
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2017-18", 2017.5, 2024.5)
        local k = cond(region[`i'] == "Pakistan - Male", 1, 2)
        post `fh' (`k') (2) (`y') (r_ydi[`i'])
    }
    postclose `fh'
    use `f48', clear
    gen str8 lb = string(val, "%5.3f")
    save "$out/Figure 4.8 data.dta", replace
    export delimited using "$out/Figure 4.8 data.csv", replace
    twoway (connected val yr if s == 1 & basis == 1, sort lcolor("$C1") mcolor("$C1") msymbol(O) ///
            mlabel(lb) mlabposition(12) mlabsize(vsmall) mlabcolor("$C1")) ///
        (connected val yr if s == 2 & basis == 1, sort lcolor("$C4") mcolor("$C4") msymbol(O) ///
            mlabel(lb) mlabposition(6) mlabsize(vsmall) mlabcolor("$C4")) ///
        (connected val yr if s == 1 & basis == 2, sort lcolor("$C1") mcolor("$C1") lpattern(dash) msymbol(Oh) ///
            mlabel(lb) mlabposition(12) mlabsize(vsmall) mlabcolor("$C1")) ///
        (connected val yr if s == 2 & basis == 2, sort lcolor("$C4") mcolor("$C4") lpattern(dash) msymbol(Oh) ///
            mlabel(lb) mlabposition(6) mlabsize(vsmall) mlabcolor("$C4")), ///
        xlabel(2001.5 "2001-02" 2017.5 "2017-18" 2024.5 "2024-25", labsize(small)) xtitle("") ///
        xscale(range(2000 2026)) ylabel(0.2(0.1)0.9, angle(0) format(%3.1f) labsize(small)) ///
        ytitle("Youth Development Index", size(small)) ///
        legend(order(1 "Young men, NHDR" 2 "Young women, NHDR" 3 "Young men, reproduced" 4 "Young women, reproduced") ///
            rows(2) position(6) size(small)) ///
        title("Figure 4.8  Gender-based Youth Development Index, Pakistan", size(medium)) ///
        note("Solid: NHDR 2020 Table 5. Dashed: LFS 2017-18 and 2024-25 (Section 24).", size(vsmall)) $GR
    graph export "$out/Figure 4.8 YDI gender trend.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.8 YDI gender trend.png"

* ---- 26.17 Figure 4.9: the Gender Development Index ----------------------------
* Series: 1 female HDI, 2 male HDI, 3 GDI. Published: Table 6, 2006-07 and
* 2018-19. Reproduced: Section 17.4, Pakistan, 2018-19 and 2024-25.
capture noisily {
    tempname fh
    tempfile f49
    postfile `fh' byte(s basis) double(yr val) using `f49'
    use `t6', clear
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2006_07", 2006.5, 2018.5)
        local k = cond(sex[`i'] == "Female", 1, 2)
        post `fh' (`k') (1) (`y') (pub_hdi[`i'])
        if sex[`i'] == "Female" post `fh' (3) (1) (`y') (pub_gdi[`i'])
    }
    import delimited using "$out/GDI reproduced 2018-19 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if domain == "Pakistan"
    forvalues i = 1/`=_N' {
        local y = cond(survey[`i'] == "2018_19", 2018.5, 2024.5)
        local k = cond(sex[`i'] == "Female", 1, 2)
        post `fh' (`k') (2) (`y') (gdi_hdi[`i'])
        if sex[`i'] == "Female" post `fh' (3) (2) (`y') (gdi[`i'])
    }
    postclose `fh'
    use `f49', clear
    gen str8 lb = string(val, "%5.3f")
    save "$out/Figure 4.9 data.dta", replace
    export delimited using "$out/Figure 4.9 data.csv", replace
    twoway (connected val yr if s == 1 & basis == 1, sort lcolor("$C4") mcolor("$C4") msymbol(O)) ///
        (connected val yr if s == 2 & basis == 1, sort lcolor("$C2") mcolor("$C2") msymbol(O)) ///
        (connected val yr if s == 3 & basis == 1, sort lcolor("$C1") mcolor("$C1") msymbol(D) lwidth(thick) ///
            mlabel(lb) mlabposition(12) mlabsize(vsmall) mlabcolor("$C1")) ///
        (connected val yr if s == 1 & basis == 2, sort lcolor("$C4") mcolor("$C4") lpattern(dash) msymbol(Oh)) ///
        (connected val yr if s == 2 & basis == 2, sort lcolor("$C2") mcolor("$C2") lpattern(dash) msymbol(Oh)) ///
        (connected val yr if s == 3 & basis == 2, sort lcolor("$C1") mcolor("$C1") lpattern(dash) msymbol(Dh) ///
            mlabel(lb) mlabposition(12) mlabsize(vsmall) mlabcolor("$C1")), ///
        xlabel(2006.5 "2006-07" 2018.5 "2018-19" 2024.5 "2024-25", labsize(small)) xtitle("") ///
        xscale(range(2005 2026)) ylabel(0.4(0.1)0.9, angle(0) format(%3.1f) labsize(small)) ///
        ytitle("Index", size(small)) ///
        legend(order(1 "Female HDI" 2 "Male HDI" 3 "GDI") rows(1) position(6) size(small)) ///
        title("Figure 4.9  Pakistan Gender Development Index", size(medium)) ///
        note("Solid: NHDR 2020 Table 6. Dashed: reproduced (Section 17.4), income split by sex with the UNDP method" ///
            "on the LFS, which NHDR's printed incomes do not follow.", size(vsmall)) $GR
    graph export "$out/Figure 4.9 GDI trend.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.9 GDI trend.png"

* ---- 26.18 Figure 4.10: female and male earned income --------------------------
capture noisily {
    tempname fh
    tempfile f410
    postfile `fh' byte order str24 series double(female male) using `f410'
    use `t6', clear
    sort year sex
    * Rows: 2006_07 Female, 2006_07 Male, 2018_19 Female, 2018_19 Male.
    assert _N == 4 & sex[1] == "Female" & sex[2] == "Male" & year[1] == "2006_07" & year[3] == "2018_19"
    post `fh' (1) ("2006-07 NHDR") (pci[1]) (pci[2])
    post `fh' (2) ("2018-19 NHDR") (pci[3]) (pci[4])
    import delimited using "$out/GDI reproduced 2018-19 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if domain == "Pakistan"
    sort survey sex
    assert _N == 4 & sex[1] == "Female" & sex[2] == "Male" & survey[1] == "2018_19" & survey[3] == "2024_25"
    post `fh' (3) ("2018-19 reproduced") (pci[1]) (pci[2])
    post `fh' (4) ("2024-25 reproduced") (pci[3]) (pci[4])
    postclose `fh'
    use `f410', clear
    save "$out/Figure 4.10 data.dta", replace
    export delimited using "$out/Figure 4.10 data.csv", replace
    graph bar (asis) female male, over(series, sort(order) label(labsize(small))) ///
        bar(1, color("$C4")) bar(2, color("$C1")) ///
        blabel(bar, format(%9.0fc) size(vsmall)) ///
        ylabel(0(2000)12000, angle(0) format(%9.0fc) labsize(small)) ///
        ytitle("Earned income per head, PPP dollars", size(small)) ///
        legend(order(1 "Women" 2 "Men") rows(1) position(6) size(small)) ///
        title("Figure 4.10  The gap between female and male earnings", size(medium)) ///
        note("NHDR: Table 6A. Reproduced: UNDP split of the income control on LFS 2018-19 and 2024-25 (Section 17.4).", ///
            size(vsmall)) $GR
    graph export "$out/Figure 4.10 earnings by sex.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.10 earnings by sex.png"

* ---- 26.19 Figure 4.11: the Gender Inequality Index over time ------------------
capture noisily {
    tempname fh
    tempfile f411
    postfile `fh' byte basis double(yr val) using `f411'
    use `t7', clear
    keep if domain == "Pakistan"
    forvalues i = 1/`=_N' {
        local y = cond(year[`i'] == "2006_07", 2006.5, 2018.5)
        post `fh' (1) (`y') (pub_gii[`i'])
    }
    import delimited using "$out/GII 2006-07 reproduced.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if domain == "Pakistan"
    post `fh' (3) (2006.5) (r_gii[1])
    import delimited using "$out/GII 2024-25.csv", clear varnames(1) asdouble encoding(utf-8) case(preserve)
    keep if domain == "Pakistan"
    post `fh' (2) (2018.5) (raw_gii[1])
    post `fh' (2) (2024.5) (g24_gii[1])
    postclose `fh'
    use `f411', clear
    gen str8 lb = string(val, "%5.3f")
    save "$out/Figure 4.11 data.dta", replace
    export delimited using "$out/Figure 4.11 data.csv", replace
    twoway (connected val yr if basis == 1, sort lcolor("$C1") mcolor("$C1") msymbol(O) ///
            mlabel(lb) mlabposition(12) mlabsize(small) mlabcolor("$C1")) ///
        (connected val yr if basis == 2, sort lcolor("$C4") mcolor("$C4") lpattern(dash) msymbol(Oh) ///
            mlabel(lb) mlabposition(6) mlabsize(small) mlabcolor("$C4")) ///
        (scatter val yr if basis == 3, mcolor("$C2") msymbol(Dh) ///
            mlabel(lb) mlabposition(6) mlabsize(small) mlabcolor("$C2")), ///
        xlabel(2006.5 "2006-07" 2018.5 "2018-19" 2024.5 "2024-25", labsize(small)) xtitle("") ///
        xscale(range(2005 2026)) ylabel(0.40(0.05)0.65, angle(0) format(%4.2f) labsize(small)) ///
        ytitle("Gender Inequality Index", size(small)) ///
        legend(order(1 "NHDR 2020, Table 7" 2 "Reproduced, every input from the microdata" ///
            3 "2006-07, care and schooling reproduced") rows(1) position(6) size(small)) ///
        title("Figure 4.11  Pakistan's Gender Inequality Index over time", size(medium)) ///
        note("Reproduced: Sections 20.4 (2006-07), 18.2 (2018-19) and 18.3 (2024-25). Seats are held at 2018." ///
            "Lower is better. NHDR's 2011-12 and 2015-16 points rest on rounds not in 6. Raw data.", size(vsmall)) $GR
    graph export "$out/Figure 4.11 GII trend.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.11 GII trend.png"

* ---- 26.20 Figure 4.12: the gender-based CDI by dimension, 2018-19 --------------
capture noisily {
    clear
    set obs 4
    gen byte order = _n
    gen str24 dimension = ""
    replace dimension = "Standard of living" in 1
    replace dimension = "Education"          in 2
    replace dimension = "Health and nutrition" in 3
    replace dimension = "CDI"                in 4
    gen double girls = .
    gen double boys  = .
    tempfile dims
    save `dims'
    use `t4', clear
    keep if region == "Pakistan" & year == "2018-19"
    foreach s in Female Male {
        quietly summarize pub_sl_idx if sex == "`s'"
        local sl_`s' = r(mean)
        quietly summarize pub_edu_idx if sex == "`s'"
        local ed_`s' = r(mean)
        quietly summarize pub_health_idx if sex == "`s'"
        local he_`s' = r(mean)
        quietly summarize pub_cdi if sex == "`s'"
        local cd_`s' = r(mean)
    }
    use `dims', clear
    replace girls = `sl_Female' in 1
    replace girls = `ed_Female' in 2
    replace girls = `he_Female' in 3
    replace girls = `cd_Female' in 4
    replace boys  = `sl_Male'   in 1
    replace boys  = `ed_Male'   in 2
    replace boys  = `he_Male'   in 3
    replace boys  = `cd_Male'   in 4
    save "$out/Figure 4.12 data.dta", replace
    export delimited using "$out/Figure 4.12 data.csv", replace
    graph bar (asis) boys girls, over(dimension, sort(order) label(labsize(small))) ///
        bar(1, color("$C1")) bar(2, color("$C4")) ///
        blabel(bar, format(%5.3f) size(vsmall)) ///
        ylabel(0(0.2)0.8, angle(0) format(%3.1f) labsize(small)) ytitle("Index", size(small)) ///
        legend(order(1 "Boys" 2 "Girls") rows(1) position(6) size(small)) ///
        title("Figure 4.12  Gender-based Child Development Index, 2018-19", size(medium)) ///
        note("NHDR 2020 Table 4 as printed. Section 8A reproduces its PDHS inputs from the microdata.", ///
            size(vsmall)) $GR
    graph export "$out/Figure 4.12 CDI gender.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.12 CDI gender.png"

* ---- 26.21 Figure 4.13: the male YDI is well above the female YDI ---------------
capture noisily {
    use `t5', clear
    keep if year == "2017-18" & inlist(region, "Pakistan - Male", "Pakistan - Female")
    tempfile y5
    save `y5'
    import delimited using "$out/YDI 2017-18 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if year == "2024-25" & inlist(region, "Pakistan - Male", "Pakistan - Female")
    tempfile y24
    save `y24'
    clear
    set obs 6
    gen byte order = _n
    gen str26 dimension = ""
    replace dimension = "Years of schooling"       in 1
    replace dimension = "Employment to population" in 2
    replace dimension = "Higher education"         in 3
    replace dimension = "Fully employed"           in 4
    replace dimension = "Youth survival"           in 5
    replace dimension = "YDI"                      in 6
    foreach v in men_nhdr women_nhdr men_2425 women_2425 {
        gen double `v' = .
    }
    tempfile dims
    save `dims'
    local pub pub_mys_idx pub_epr_idx pub_hied_idx pub_full_idx pub_surv_idx pub_ydi
    local reb r_i_mys r_i_epr r_i_hied r_i_full r_i_surv r_ydi
    forvalues k = 1/6 {
        local pv : word `k' of `pub'
        local rv : word `k' of `reb'
        use `y5', clear
        quietly summarize `pv' if region == "Pakistan - Male"
        local mn`k' = r(mean)
        quietly summarize `pv' if region == "Pakistan - Female"
        local wn`k' = r(mean)
        use `y24', clear
        quietly summarize `rv' if region == "Pakistan - Male"
        local m2`k' = r(mean)
        quietly summarize `rv' if region == "Pakistan - Female"
        local w2`k' = r(mean)
    }
    use `dims', clear
    forvalues k = 1/6 {
        replace men_nhdr   = `mn`k'' in `k'
        replace women_nhdr = `wn`k'' in `k'
        replace men_2425   = `m2`k'' in `k'
        replace women_2425 = `w2`k'' in `k'
    }
    save "$out/Figure 4.13 data.dta", replace
    export delimited using "$out/Figure 4.13 data.csv", replace
    graph hbar (asis) men_nhdr women_nhdr men_2425 women_2425, ///
        over(dimension, sort(order) label(labsize(small))) ///
        bar(1, color("$C1")) bar(2, color("$C4")) bar(3, color("$C2")) bar(4, color("$C6")) ///
        blabel(bar, format(%4.2f) size(tiny)) ///
        ylabel(0(0.2)1, format(%3.1f) labsize(small)) ytitle("Index", size(small)) ///
        legend(order(1 "Young men 2017-18, NHDR" 2 "Young women 2017-18, NHDR" 3 "Young men 2024-25, reproduced" ///
            4 "Young women 2024-25, reproduced") rows(2) position(6) size(small)) ///
        title("Figure 4.13  The male YDI is well above the female YDI", size(medium)) ///
        note("NHDR 2020 Table 5 as printed, and LFS 2024-25 (Section 24).", size(vsmall)) $GR
    graph export "$out/Figure 4.13 YDI gender.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.13 YDI gender.png"

* ---- 26.22 Figure 4.15: LDI dimensions by sex --------------------------------------
capture noisily {
    use `t8', clear
    keep if year == "2017-18" & inlist(region, "Pakistan - Male", "Pakistan - Female")
    tempfile l5
    save `l5'
    import delimited using "$out/LDI 2012-13 2017-18 2024-25.csv", clear varnames(1) asdouble ///
        encoding(utf-8) case(preserve)
    keep if year == "2024-25" & inlist(region, "Pakistan - Male", "Pakistan - Female")
    tempfile l24
    save `l24'
    clear
    set obs 6
    gen byte order = _n
    gen str26 dimension = ""
    replace dimension = "Employment to population" in 1
    replace dimension = "Share of labour income"   in 2
    replace dimension = "Skill premium"            in 3
    replace dimension = "Human capital"            in 4
    replace dimension = "Incidence of decent work" in 5
    replace dimension = "LDI with decent work"     in 6
    foreach v in men_nhdr women_nhdr men_2425 women_2425 {
        gen double `v' = .
    }
    tempfile dims
    save `dims'
    local pub pub_epr_idx pub_lshare_idx pub_sp_idx pub_hc_idx pub_dw_idx pub_ldidw
    local reb r_i_ep r_i_ls r_i_sp r_i_hc r_i_dw r_ldidw
    forvalues k = 1/6 {
        local pv : word `k' of `pub'
        local rv : word `k' of `reb'
        use `l5', clear
        quietly summarize `pv' if region == "Pakistan - Male"
        local mn`k' = r(mean)
        quietly summarize `pv' if region == "Pakistan - Female"
        local wn`k' = r(mean)
        use `l24', clear
        quietly summarize `rv' if region == "Pakistan - Male"
        local m2`k' = r(mean)
        quietly summarize `rv' if region == "Pakistan - Female"
        local w2`k' = r(mean)
    }
    use `dims', clear
    forvalues k = 1/6 {
        replace men_nhdr   = `mn`k'' in `k'
        replace women_nhdr = `wn`k'' in `k'
        replace men_2425   = `m2`k'' in `k'
        replace women_2425 = `w2`k'' in `k'
    }
    save "$out/Figure 4.15 data.dta", replace
    export delimited using "$out/Figure 4.15 data.csv", replace
    graph hbar (asis) men_nhdr women_nhdr men_2425 women_2425, ///
        over(dimension, sort(order) label(labsize(small))) ///
        bar(1, color("$C1")) bar(2, color("$C4")) bar(3, color("$C2")) bar(4, color("$C6")) ///
        blabel(bar, format(%4.2f) size(tiny)) ///
        ylabel(0(0.2)1, format(%3.1f) labsize(small)) ytitle("Index", size(small)) ///
        legend(order(1 "Men 2017-18, NHDR" 2 "Women 2017-18, NHDR" 3 "Men 2024-25, reproduced" ///
            4 "Women 2024-25, reproduced") rows(2) position(6) size(small)) ///
        title("Figure 4.15  Dimensions of the LDI reveal gender discrimination in the labour market", ///
            size(medium)) ///
        note("NHDR 2020 Table 8 as printed, and LFS 2024-25 (Section 25). The sexes take the national wage ratio.", ///
            size(vsmall)) $GR
    graph export "$out/Figure 4.15 LDI gender.png", width(2400) replace
}
nhdr_fig_done "$out/Figure 4.15 LDI gender.png"

* ---- 26.23 Checks on the figures ---------------------------------------------------
display as text _n "Step 23: report figures and maps written: " as result $NFIGOK as text " of " as result $NFIG
nhdr_check, label("Step 23 report figures and maps attempted, with Figure 5.19 [29]") got($NFIG) want(29) tol(0)
nhdr_check, label("Step 23 report figures and maps written, of those attempted") got($NFIGOK) want($NFIG) tol(0)


*==============================================================================*
* SECTION 27   SUMMARY OF CHECKS, FIGURES AND THE RESULTS WORKBOOK
*==============================================================================*

file close chk

* ---- 27.1 Further charts: provincial HDI trend and district scatter plots ----
* Wrapped in capture so that a graphics problem on a given machine cannot stop
* the run after every result has been written.
capture noisily {
    use `fin24', clear
    keep if inlist(domain, "Pakistan", "Punjab", "Sindh", "Khyber Pakhtunkhwa", "Balochistan")
    keep domain hdi_2006_07 hdi_2018_19 hdi
    rename hdi hdi_2024_25
    reshape long hdi_, i(domain) j(period) string
    gen double year = real(substr(period, 1, 4)) + 0.5
    local g
    local lg
    local k = 0
    local colors `" "0 125 183" "32 181 228" "141 198 63" "233 83 43" "31 45 61" "'
    levelsof domain, local(doms)
    foreach d of local doms {
        local ++k
        local c : word `k' of `colors'
        local g `g' (connected hdi_ year if domain == "`d'", sort lcolor("`c'") mcolor("`c'"))
        local lg `lg' `k' "`d'"
    }
    twoway `g', legend(order(`lg') rows(2) size(small) position(6)) ///
        xlabel(2006.5 "2006-07" 2018.5 "2018-19" 2024.5 "2024-25") xtitle("") ///
        ytitle("Human development index, NHDR 2020 construction") ///
        title("The provincial series, 2006-07 to 2024-25", size(medium)) ///
        graphregion(color(white)) plotregion(color(white))
    graph export "$out/Figure provincial trend.png", width(2400)

    use `dindex', clear
    twoway (scatter hdi literacy_15plus, mcolor("0 125 183%60") msize(small)), ///
        xtitle("Adult literacy, 15 and over, percent") ///
        ytitle("District human development index") ///
        title("Education is the binding constraint almost everywhere", size(medium)) ///
        graphregion(color(white)) plotregion(color(white))
    graph export "$out/Figure district literacy HDI.png", width(2400)

    use "$out/MPI 2019-20 districts.dta", clear
    twoway (scatter MPI hdi, mcolor("233 83 43%60") msize(small)), ///
        xtitle("District human development index, NHDR 2020 construction") ///
        ytitle("District multidimensional poverty index, 2019-20") ///
        title("Human development and multidimensional poverty, 126 districts", size(medium)) ///
        graphregion(color(white)) plotregion(color(white))
    graph export "$out/Figure district HDI MPI.png", width(2400)

    use "$out/MPI change districts.dta", clear
    twoway (scatter MPI_19 MPI_14, mcolor("0 125 183%60") msize(small)) ///
        (function y = x, range(0 0.7) lcolor("31 45 61") lpattern(dash)), ///
        legend(off) xtitle("District MPI 2014-15, harmonized") ytitle("District MPI 2019-20, harmonized") ///
        title("Multidimensional poverty by district, 2014-15 and 2019-20", size(medium)) ///
        graphregion(color(white)) plotregion(color(white))
    graph export "$out/Figure district MPI change.png", width(2400)
}

* ---- 27.2 The results workbook ---------------------------------------------------------
* One worksheet per results table, in the order of "Output descriptions.csv"
* (folder 1. Dos). Row 1 of each sheet is its headline, row 2 names the CSV it
* comes from, and the table starts on row 4 with the descriptive column names
* of "Variable dictionary.csv". The CSV files keep the short variable names.
local xlsx "$out/NHDR replication results.xlsx"
local runname = substr("$out", strrpos("$out", "/") + 1, .)
capture frame drop vdict
frame create vdict
frame vdict: import delimited using "$root/1. Dos/Variable dictionary.csv", clear ///
    varnames(1) encoding(utf-8) stringcols(_all) bindquote(strict)
import delimited using "$root/1. Dos/Output descriptions.csv", clear varnames(1) ///
    encoding(utf-8) stringcols(_all) bindquote(strict)
local nsheet = _N
forvalues k = 1/`nsheet' {
    local f`k' = file[`k']
    local s`k' = sheet[`k']
    local h`k' = description[`k']
}
local first = 1
forvalues k = 1/`nsheet' {
    capture confirm file "$out/`f`k''.csv"
    if _rc {
        display as error "Workbook: `f`k''.csv not found, its sheet is skipped"
        continue
    }
    import delimited using "$out/`f`k''.csv", clear varnames(1) asdouble encoding(utf-8) case(preserve)
    foreach v of varlist _all {
        frame vdict: quietly levelsof label if file == "`f`k''" & lower(variable) == lower("`v'"), ///
            local(lab) clean
        if `"`lab'"' != "" label variable `v' `"`lab'"'
    }
    local opt = cond(`first', "replace", "sheetreplace")
    export excel using "`xlsx'", sheet("`s`k''") `opt' cell(A4) firstrow(varlabels)
    putexcel set "`xlsx'", sheet("`s`k''") modify
    putexcel A1 = `"`h`k''"', bold
    putexcel A2 = `"Source: 8. Stata runs/`runname'/`f`k''.csv"', italic
    putexcel clear
    local first = 0
}
frame drop vdict
import delimited using "$out/Checks.txt", clear varnames(1) delimiters("\t") asdouble encoding(utf-8)
label variable status    "Result (PASS or FAIL)"
label variable check     "Check: step, quantity and the source of the target"
label variable computed  "Value computed by this run"
label variable target    "Target value (published figure or reference result)"
label variable tolerance "Largest absolute difference accepted as a match"
export excel using "`xlsx'", sheet("Checks") sheetreplace cell(A4) firstrow(varlabels)
putexcel set "`xlsx'", sheet("Checks") modify
putexcel A1 = "Every validation check of this run, with the value computed, the target and the tolerance.", bold
putexcel A2 = `"Source: 8. Stata runs/`runname'/Checks.txt"', italic
putexcel clear

* ---- 27.3 Summary ------------------------------------------------------------------------
display as text _n "{hline 100}"
display as text "Checks run    : " as result $NCHK
display as text "Checks passed : " as result $NCHK - $NFAIL
display as text "Checks failed : " as result $NFAIL
if $NFAIL > 0 {
    display as error "Some checks failed. Every check is listed in Checks.txt and on the Checks sheet."
    list if status == "FAIL", noobs sep(0) abbreviate(32)
}
display as text "Results written to $out"
display as text "Run finished `c(current_date)' `c(current_time)'"
display as text "{hline 100}"
log close main

*==============================================================================*
* END OF FILE
*==============================================================================*
