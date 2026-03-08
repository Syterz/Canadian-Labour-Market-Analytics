# Canadian Labour Market Data Pipeline
> End-to-end data engineering pipeline processing Statistics Canada job vacancy data — from raw CSV ingestion to analytical dashboards.

## Pipeline Architecture

```
Statistics Canada CSVs
        │
        ▼
   S3 (raw/)                    ← Raw CSV storage
        │
        ▼
   AWS Glue (PySpark)           ← Ingestion, type casting, null handling
        │
        ▼
   S3 (processed/)              ← Intermediate clean Parquet
        │
        ▼
   Databricks                   ← Schema normalization, business metric computation (vacancy rate per 1000 employed)
        │  
        ▼
   S3 (curated/)                ← Final Parquet ready for dbt
        │
        ▼
   dbt Core(dbt-databricks)     ← Mart models, data tests, documentation
        │
        ▼
   Streamlit / Power BI         ← Dashboard layer
```

## Key Metrics Produced
- **Vacancy Rate**: Job vacancies per 1,000 employed workers by province and sector
- **Tech Job Concentration**: Share of tech-sector vacancies by region
- **YoY Trends**: Year-over-year change in vacancy rates by NOC category

---

## Repository Structure

```
├── glue/
│   └── glue_ETL_job.py       # PySpark job: raw CSV → cleaned Parquet
│
├── databricks/
│   └── transform_vacancy_metrics.ipynb  # Schema work + vacancy rate computation + output to S3
│
├── dbt/
│   ├── models/
│   │   ├── staging/
│   │   │   └── stg_vacancies.sql (To be added)
│   │   ├── intermediate/
│   │   │   └── int_vacancies_by_region.sql (To be added)
│   │   └── marts/
│   │       └── mart_vacancy_rates.sql (To be added)
│   ├── tests/
│   └── dbt_project.yml (To be added)
│
├── dashboard/
│   └── app.py                       # Streamlit app (or link to .pbix) (To be added)
│
├── data/
│   └── sample/
│       ├── raw_sample.csv           # 100-row sample of raw input (To be added)
│       └── processed_sample.parquet # Sample of curated output (To be added)
│
├── .github/
│   └── workflows/
│       └── dbt_test.yml             # CI: runs dbt test on PR (To be added)
│
├── .gitignore
├── requirements.txt (To be added)
├── SECURITY.md (To be added)
└── README.md
```

---

## Reproducing This Pipeline

### Prerequisites
- AWS account with S3 and Glue access
- Databricks account (Community Edition works)
- Python 3.10+
- dbt Core installed (`pip install dbt-databricks`)

### 1. Set Up S3 Buckets
```bash
aws s3 mb s3://your-bucket-name
aws s3 cp data/raw/ s3://your-bucket-name/raw/ --recursive
```

### 2. Run the Glue Job
Deploy `glue/glue_etl_job.py` via the AWS Glue console or CLI.
Set the following job parameters:
- `--NAICS_PATH`: `s3://your-bucket/raw/NAICS.csv`
- `--MONTHLY_PATH`: `s3://your-bucket/raw/Monthly.csv`
- `--QUARTERLY_PATH`: `s3://your-bucket/raw/Quarterly/`
- `--OUTPUT_PATH`: `s3://your-bucket/processed/`

### 3. Run the Databricks Notebook
Import `databricks/transform_vacancy_metrics.ipynb` into Databricks.
Update the S3 paths in cell 2 and run all cells.
Output is written to `s3://your-bucket/processed/`.

> [!NOTE]
> Dbt, and Dashboard to be added later on

---

## Data Source
Statistics Canada
<br>[NAICS Employed Data](https://www150.statcan.gc.ca/n1/tbl/csv/14100201-eng.zip)             -This directly downloads the file, this table may have been updated on February 2026 into a different format/table as
                                  the previous website link containing the table no longer works, will be looked into later on)
<br>[Quarterly NAICS Job Vacancies](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410044201&pickMembers%5B0%5D=1.1&cubeTimeFrame.startMonth=01&cubeTimeFrame.startYear=2015&cubeTimeFrame.endMonth=10&cubeTimeFrame.endYear=2025&referencePeriods=20150101%2C20251001)
<br>[Monthly Job Vacancies](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410037101&cubeTimeFrame.startMonth=01&cubeTimeFrame.startYear=2025&cubeTimeFrame.endMonth=11&cubeTimeFrame.endYear=2025&referencePeriods=20250101%2C20251101)  - Contains no NAICS

Data is publicly available under the Statistics Canada Open Licence.

---

## Design Decisions

**Why Glue for ingestion and Databricks for transformation?**
Glue handled the ingestion layer: column selection, type casting, string normalization, date filtering, and writing partitioned Parquet to S3. Partitioning by Year and GEO at this stage makes downstream reads faster by pruning irrelevant partitions before any transformation begins.

Databricks handled the heavier transformation work: normalizing NAICS industry codes across datasets, resolving date granularity mismatches between monthly and quarterly sources, joining employment figures to vacancy data, and computing vacancies per 1,000 employed as a normalized rate comparable across provinces and industries. The notebook environment suited this stage because the join logic and NAICS name standardization required iterative validation: null checks, duplicate detection, and left-anti joins, to identify unmatched industries before the transformations were stable enough to be committed as repeatable code.

**Why dbt on Databricks instead of a separate warehouse?**
Running dbt directly on Databricks avoids an unnecessary data movement step into a separate warehouse. The curated Delta tables are already query-ready, and dbt-databricks connects natively to the cluster, keeping the stack unified and reducing infrastructure overhead.

---

## Skills Demonstrated
- Cloud data engineering (AWS S3, Glue)
- Distributed processing (PySpark on Glue, Databricks)
- Analytics engineering (dbt-databricks, models, tests, documentation)
- Infrastructure basics (IAM roles, Secrets Manager for credentials)
- CI/CD (GitHub Actions running dbt tests on PR)
- Dashboard development (Streamlit / Power BI)

---

## Security
See [SECURITY.md](./SECURITY.md) for credential handling and IAM role configuration.
