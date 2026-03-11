# Canadian Labour Market Analytics — dbt Project

This dbt project transforms curated Delta tables in Databricks into business-ready mart models for analysing Canadian labour market trends.

## Connection
- **Adapter**: dbt-databricks
- **Catalog**: workspace
- **Schema**: canada_labour_market

## Models
- **Staging**: Clean views on top of curated Delta tables
- **Marts**: Business metrics including vacancy rates, YoY trends, and sector breakdowns (in progress)

## Running the project
```bash
dbt run        # build all models
dbt test       # run all tests
dbt docs serve # view documentation
```

## Tests
All staging models are tested for null values on critical columns.