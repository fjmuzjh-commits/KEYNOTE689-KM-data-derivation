# KEYNOTE-689 Kaplan–Meier data derivation

This repository provides digitized published Kaplan–Meier (KM) coordinates, numbers at risk, and reproducible pseudo-individual patient data (pseudo-IPD) reconstruction for the three populations analyzed in the KEYNOTE-689 cost–utility study. It does **not** contain individual participant data from the trial.

## Published source

Uppaluri R, et al. *Neoadjuvant and Adjuvant Pembrolizumab in Locally Advanced Head and Neck Cancer.* N Engl J Med. 2025;393:37–50. DOI: [10.1056/NEJMoa2415434](https://doi.org/10.1056/NEJMoa2415434). The source figures are cited rather than redistributed here.

| Population | EFS source | OS source | Pembrolizumab plus standard care | Standard care |
|---|---|---|---:|---:|
| PD-L1 CPS ≥10 | Figure 1A | Figure 2A | 234 | 231 |
| PD-L1 CPS ≥1 | Figure 1B | Figure 2B | 347 | 335 |
| All participants | Figure 1C | Figure 2C | 363 | 351 |

Each population folder contains `km.xlsx`, the archived digitized coordinates and numbers at risk, and `km_adj.xlsx`, the archived coordinates after time sorting and non-increasing survival adjustment. Each workbook has four sheets: `PFS_TG`, `PFS_CG`, `OS_TG`, and `OS_CG`. Here **`PFS` is a legacy filename label for the trial's EFS endpoint**, `TG` represents pembrolizumab plus standard care, and `CG` represents standard care. `time` and `trisk` are measured in months; `surv` is a proportion between 0 and 1.

## Rebuild the pseudo-IPD

Install R packages `openxlsx`, `IPDfromKM`, `survival`, and `ggplot2`, then run:

```sh
Rscript rebuild_pseudo_ipd.R
```

The script reads the archived adjusted KM coordinates and their risk tables, uses `IPDfromKM::preprocess(..., maxy = 1)` and `getIPD()`, and writes:

- `derived/digitized_km_coordinates.csv`: all 12 digitized curves and risk tables in long format;
- `derived/reconstructed_pseudo_ipd.csv`: independently regenerated pseudo-IPD for EFS and OS, two arms, three populations;
- `derived/reconstruction_check.csv`: sample sizes, reconstructed event counts, and pointwise KM differences;
- `derived/KM_reconstruction_validation.png` and `.pdf`: digitized points overlaid with KM curves estimated from the reconstructed pseudo-IPD.

The regenerated pseudo-IPD was checked row by row against all 12 archived `IPD_*.xlsx` files outside this repository. All 12 matched at a numerical tolerance of `1e-8`. The reconstructed sample sizes equal the published baseline numbers at risk. Reconstructed event counts are approximate: for example, EFS events in the CPS ≥1 population are 129 and 157 versus 128 and 156 reported in the article. The largest pointwise discrepancies occur near 60 months, when very few participants remain at risk; consult the validation figure and `reconstruction_check.csv` before interpreting the tail.

## Scope of reproducibility

The `archived_model_inputs/` folder also preserves, for each population, the selected survival-model distributions (`最佳分布.xlsx`), fitted survival tables (`surv_*.xlsx`), and transition tables used by the economic model (`TG_prob1.xlsx` and `CG_prob1.xlsx`). `get_prob1_archived.R` is the original probability-generation function. Its output tables were independently checked against the archived selected curves and 2021 U.S. both-sex Human Mortality Database life table, using 21-day cycles, ages 60/61 years, and a 30-year probability-generation horizon. The economic base case used the first 346 cycles.

In that function, EFS retention is derived from consecutive fitted EFS survival probabilities, `S_EFS(t)/S_EFS(t−1)`. EFS-to-death uses the age-specific background probability `1−(1−qx)^(21/365.24)`, and EFS-to-PD is the remaining row probability. Consecutive OS survival probabilities and a 1,000-person accounting cohort are used to infer PD-to-death; PD-to-PD is its complement. The code clips invalid probabilities to the `[0,1]` interval. The resulting time-varying transition matrix is used in a three-state cohort Markov model. These are **model-derived** transitions, not transition counts directly observed in KEYNOTE-689.

The archived function uses external life-table paths and global distribution selectors, so it is supplied to document the historical formula rather than as a standalone executable. The life-table source itself is not redistributed here.

**Provenance boundary:** this release independently reproduces the **published KM figure → digitized coordinates and risk table → pseudo-IPD** portion. It does not independently regenerate the archived parametric survival fits from those pseudo-IPD files. In particular, the stored CPS ≥1 pre-fit life tables match a separate archived TXT pseudo-IPD branch whose baseline numbers at risk differ from CPS ≥1; they do not match the population-specific XLSX pseudo-IPD reproduced here. The archived survival and transition files are therefore identified as historical model inputs, not outputs of `rebuild_pseudo_ipd.R`. The package does not establish that the original economic base case follows from the newly reconstructed pseudo-IPD.
