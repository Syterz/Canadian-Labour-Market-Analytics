with source as (
    select * from {{ source('canada_labour_market', 'quarterly_vacancies_curated') }}
),

renamed as (
    select
        date_parsed,
        geo,
        year,
        naics,
        job_vacancies,
        job_vacancy_rate,
        avg_offered_hourly_wage,
        total_employment,
        (job_vacancies / nullif(total_employment, 0)) * 1000 as vacancies_per_1000
    from source
    where date_parsed is not null
)

select * from renamed