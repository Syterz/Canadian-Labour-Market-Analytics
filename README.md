# Canadian Labour Market Data Pipeline
> End-to-end data engineering pipeline processing Statistics Canada job vacancy data - from raw CSV ingestion to analytical dashboards.

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
   Databricks                   ← Schema normalization, null and dupe checks, NAICS code standardization, 
        │                          date granularity resolution, employment/vacancy join
        │  
        ▼
   S3 (curated/)                ← Final Parquet ready for dbt transformation
        │
        ▼
   Databricks (Delta Tables)    ← Curated Parquet registered as managed Delta tables via Hive Metastore
        │
        ▼
   dbt Core(dbt-databricks)     ← Mart models, data tests, documentation                                            ← Currently here
        │
        ▼
   Databricks ML (XGBoost)      ← Time series forecasting of vacancy rates, experiment tracking,                    ← ⏳ (planned)
   + MLflow                        model versioning
        │
        ▼
   Predictions Delta Table      ← Forecasted rates stored for querying                                              ← ⏳ 
        │
        ▼
   Streamlit / Power BI         ← Dashboard layer                                                                   ← ⏳ 
        │
        ▼
   Apache Airflow (Astro CLI)   ← End-to-end orchestration, monthly scheduling,                                     ← ⏳ 
                                   pipeline dependency management
```

## Key Metrics Produced (Planned)
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
│   ├── transform_vacancy_metrics.ipynb  <- Schema work + null/dupe check + standardization + joins + output to S3 (curated)
│   ├── register_curated_tables.ipynb    <- Registers curated Parquet as Delta
│   └── ml_vacancy_forecast.ipynb        <- XGBoost forecasting + MLflow tracking (To be added)
|
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
├── airflow/
│   └── dags/
│       └── canada_labour_pipeline.py       # End-to-end DAG: ingest → Glue → Databricks → dbt → ML (To be added)
│
├── dashboard/
│   └── app.py                       # Streamlit app (or link to .pbix) (To be added)
│
├── data/
│   └── sample/
│       ├── raw/          # 100-row sample of raw data
│       │   ├── naics_employed_sample.csv        
│       │   ├── monthly_vacancies_sample.csv     
│       │   └── quarterly_vacancies_sample.csv  
│       │
│       └── curated/      # 100-row samples of curated data
│       │    ├── monthly_curated_sample.csv       
│       │    ├── naics_curated_sample.csv         
│       │    └── quarterly_curated_sample.csv     
│       │
│       └── predicted/    # 100-row samples of predicted data
│            └── prediction_sample.csv (To be added)
│
├── .github/
│   └── workflows/
│       └── dbt_test.yml             # CI: runs dbt test on PR (To be added)
│
├── .gitignore
├── requirements.txt
├── SECURITY.md
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
- `--NAICS_PATH`: `s3://your-bucket-name/raw/NAICS.csv`
- `--MONTHLY_PATH`: `s3://your-bucket-name/raw/Monthly.csv`
- `--QUARTERLY_PATH`: `s3://your-bucket-name/raw/Quarterly/`
- `--OUTPUT_PATH`: `s3://your-bucket-name/processed/`

### 3. Run the Databricks Notebooks
#### transform_vacancy_metrics.ipynb
Import `databricks/transform_vacancy_metrics.ipynb` into Databricks.
Update the S3 paths in cell 2 and run all cells.
Output is written to `s3://your-bucket-name/curated/`.

#### register_curated_tables.ipynb
Import `databricks/register_curated_tables.ipynb` into Databricks.
Update the S3 paths in cell 1 and run it.
Output are saved to the Hive Metastore of Databricks.

### 4. Run dbt Models
⏳ Coming soon - see Pipeline Architecture for current progress


---

## Data Layers (Medallion Architecture)

|   Layer   |      Location                       |             Description                                        |
|-----------|-------------------------------------|----------------------------------------------------------------| 
| 🥉 Bronze | `s3://bucket/raw/`                  | Raw CSV files as ingested from Statistics Canada              |
| 🥈 Silver | `s3://bucket/processed/ & /curated/`| Cleaned, typed, joined Parquet, output of Glue and Databricks |
| 🥇 Gold   | Databricks Delta Tables + dbt       | Business metrics, mart models, tested and documented          |

---

## Data Source
Statistics Canada
- [NAICS Employed Data](https://www150.statcan.gc.ca/n1/tbl/csv/14100201-eng.zip)             -Link directly downloads the file, this table may have been updated on February 2026 into a different format/table as original website URL may have changed as of February 2026, under investigation)
- [Quarterly NAICS Job Vacancies](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410044201&pickMembers%5B0%5D=1.1&cubeTimeFrame.startMonth=01&cubeTimeFrame.startYear=2015&cubeTimeFrame.endMonth=10&cubeTimeFrame.endYear=2025&referencePeriods=20150101%2C20251001)
- [Monthly Job Vacancies](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410037101&cubeTimeFrame.startMonth=01&cubeTimeFrame.startYear=2025&cubeTimeFrame.endMonth=11&cubeTimeFrame.endYear=2025&referencePeriods=20250101%2C20251101)  - Contains no NAICS breakdown

Data is publicly available under the Statistics Canada Open Licence.

---

## Design Decisions

**Why Glue for ingestion and Databricks for transformation?**
Glue handled the ingestion layer: column selection, type casting, string normalization, date filtering, and writing partitioned Parquet to S3. Partitioning by Year and GEO at this stage makes downstream reads faster by pruning irrelevant partitions before any transformation begins.

Databricks handled the heavier transformation work: normalizing NAICS industry codes across datasets, resolving date granularity mismatches between monthly and quarterly sources, and joining employment figures to vacancy data. The notebook environment suited this stage because the join logic and NAICS name standardization required iterative validation: null checks, duplicate detection, and left-anti joins, to identify unmatched industries before the transformations were stable enough to be committed as repeatable code.

**Why dbt on Databricks instead of a separate warehouse?**
Running dbt directly on Databricks avoids an unnecessary data movement step into a separate warehouse. The curated Delta tables are already query-ready, and dbt-databricks connects natively to the cluster, keeping the stack unified and reducing infrastructure overhead.

---

## Skills Demonstrated
**Implemented**
- Cloud data engineering (AWS S3, Glue)
- Distributed processing (PySpark on Glue, Databricks)
- Data modelling (Medallion architecture: Bronze → Silver → Gold)
- Infrastructure basics (IAM roles, Secrets Manager for credentials)
- Data quality & validation (null checks, deduplication, schema assertions, pre-export validation)

**In Progress**
- Analytics engineering (dbt-databricks, staging models, mart models, data tests)

**Planned**
- Machine learning (XGBoost time series forecasting, MLflow experiment tracking)
- Orchestration (Apache Airflow end-to-end pipeline scheduling)
- CI/CD (GitHub Actions running dbt tests on PR)
- Dashboard development (Streamlit)

---

## Security
See [SECURITY.md](./SECURITY.md) for credential handling and IAM role configuration.
