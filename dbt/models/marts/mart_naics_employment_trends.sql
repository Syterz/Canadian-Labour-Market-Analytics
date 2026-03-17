{{ config(materialized='table') }}

with naics as (
    select
        date_parsed,
        geo,
        year,
        naics,
        total_employment
    from {{ ref('stg_naics_employed') }}
),

-- YoY employment growth (lag 12 months since data is monthly)
employment_subsector_yoy as (
    select
        *,
        lag(total_employment, 12) over (
            partition by geo, naics
            order by date_parsed
        ) as prev_year_employment
    from naics
),

employment_yoy_pct as (
    select
        *,
        round(
            (total_employment - prev_year_employment)
            / nullif(prev_year_employment, 0) * 100, 2
        ) as employment_yoy_growth_pct
    from employment_subsector_yoy
),

-- Data employment concentration by province and month
-- Data sub-sectors: Software publishers, Computer systems design,
-- Data processing and hosting, Scientific R&D and consulting services
data_digital_employment as (
    select
        date_parsed,
        geo,
        year,
        sum(case 
            when naics = 'Computer systems design and related services [5415]'
            or naics = 'Scientific research and development services [5417]'
            or naics = 'Data processing, hosting, and related services [5182]'
            or naics = 'Software publishers [5112]'
            then total_employment else 0 
        end) as total_data_digital_employment,
        sum(case
            when naics = 'Industrial aggregate including unclassified businesses [00-91N]' then total_employment else 0
        end) as total_provincial_employment
    from naics
    group by date_parsed, geo, year
),

data_digital_concentration as (
    select
        date_parsed,
        geo,
        year,
        total_data_digital_employment,
        total_provincial_employment,
        round(
            total_data_digital_employment / nullif(total_provincial_employment, 0) * 100, 2
        ) as data_digital_employment_concentration_pct
    from data_digital_employment
),

-- Rank sub-sectors by YoY growth within each province and year
growth_ranked as (
    select
        *,
        rank() over (
            partition by geo, year
            order by employment_yoy_growth_pct desc
        ) as growth_rank
    from employment_yoy_pct
)

select
    g.*,
    t.total_data_digital_employment,
    t.total_provincial_employment,
    t.data_digital_employment_concentration_pct
from growth_ranked g
left join data_digital_concentration t
    on g.geo = t.geo
    and g.date_parsed = t.date_parsed