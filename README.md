# MSHDS Repository

This repository collects my work for the **Master of Science in Health Data Science (MSHDS)** program.  
It serves as a centralized home for coursework, applied analyses, reproducible workflows, and technical demonstrations completed throughout the degree.  

The focus is on developing clear, well-documented computational work that reflects the core skills of the program:  
data wrangling, statistical programming, reproducible research, modeling, and communication.

Projects in this repository span exploratory analyses, methodological walk-throughs, small research tools, and structured assignments that illustrate the progression of skills gained during the program.

---

## Repository Structure

```text
.
├── rna-seq/
│   ├── rna-seq.Rmd
│   ├── rna-seq.html
│   ├── figures/
│   └── README.md
└── README.md
```

---

## rna-seq/

This directory contains a complete RNA-seq analysis workflow developed as part of coursework.

### rna-seq notebook

A compact RNA-seq workflow demonstrating:

- data import and preprocessing  
- summarizing gene metadata  
- exploratory visualization  
- gene-level comparisons across biological groups  
- heatmaps and formatted tables  

Contents include:

- `rna-seq.Rmd` — source notebook  
- `rna-seq.html` — knitted, viewable analysis  
- `data/` — input CSVs (not included in repo)  
- `figures/` — exported plots  
- `README.md` — instructions and description

---

## Data Policy

Raw datasets used in coursework are **not included** in the repository.  
Users must provide their own `data/` directory when running analyses locally.

Each project folder contains instructions for where data originates and how to structure the local directory.

---

## Reproducibility

Every analysis project includes:

- a reproducible `.Rmd` or `.qmd` notebook  
- a knitted HTML file for immediate viewing  
- consistent directory structure  
- session information  
- exported figures  
- clear instructions for re-running the workflow  

This ensures that each assignment, analysis, or demonstration is transparent, reproducible, and self-contained.
