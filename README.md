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
   S3 (curated/)                ← Final Parquet ready for warehouse load
        │
        ▼
   Redshift Serverless          ← Analytical warehouse (staging + mart tables)
        │
        ▼
   dbt Core                     ← Mart models, data tests, documentation
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
│   └── transform_vacancy_metrics.ipynb  # Schema work + vacancy rate computation (To be added)
│
├── redshift/
│   └── ddl/
│       ├── staging_vacancies.sql    # Staging table DDL (To be added)
│       └── copy_commands.sql        # COPY from S3 commands (To be added)
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
- AWS account with S3, Glue, and Redshift Serverless access
- Databricks Community Edition account
- Python 3.10+
- dbt Core installed (`pip install dbt-redshift`)

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
> Redshift, dbt, and Dashboard to be added later on

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
Glue was used for the ingestion layer, column selection, type casting, string normalization, date filtering, and writing partitioned Parquet to S3. It runs close to the data source and the partitioning by Year and GEO makes downstream reads significantly faster.
Databricks handled the transformation layer: joining datasets, computing vacancy rates, and building the regional aggregations that feed the warehouse. A notebook environment suited this stage better because the logic required iterative exploration before it stabilized into repeatable code.

---

## Skills Demonstrated
- Cloud data engineering (AWS S3, Glue, Redshift Serverless)
- Distributed processing (PySpark on Glue, Databricks)
- Analytics engineering (dbt models, tests, documentation)
- Infrastructure basics (IAM roles, Secrets Manager for credentials)
- CI/CD (GitHub Actions running dbt tests on PR)
- Dashboard development (Streamlit / Power BI)

---

## Security
See [SECURITY.md](./SECURITY.md) for credential handling and IAM role configuration.
