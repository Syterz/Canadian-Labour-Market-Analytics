with source as (
    select * from {{ source('canada_labour_market', 'monthly_vacancies_curated') }}
),

renamed as (
    select
        date_parsed,
        geo,
        year,
        job_vacancies,
        job_vacancy_rate,
        payroll_employees,
        (job_vacancies / nullif(payroll_employees, 0)) * 1000 as vacancies_per_1000
    from source
    where date_parsed is not null
)

select * from renamed