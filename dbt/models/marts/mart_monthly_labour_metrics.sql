{{ config(materialized='table') }}

with monthly as (
    select
        date_parsed,
        geo,
        year,
        job_vacancies,
        job_vacancy_rate,
        payroll_employees,
        total_employment,
        vacancies_per_1000
    from {{ ref('stg_monthly_vacancies') }}
),

monthly_yoy as (
    select
        date_parsed,
        geo,
        year,
        job_vacancies,
        job_vacancy_rate,
        payroll_employees,
        total_employment,
        vacancies_per_1000,
        lag(vacancies_per_1000, 12) over (
            partition by geo
            order by date_parsed
        ) as prev_year_vacancies_per_1000
    from monthly
),

monthly_yoy_pct as (
    select
        *,
        round(
            (vacancies_per_1000 - prev_year_vacancies_per_1000)
            / nullif(prev_year_vacancies_per_1000, 0) * 100, 2
        ) as yoy_change_pct
    from monthly_yoy
),

annual_avg as (
    select
        geo,
        year,
        round(avg(vacancies_per_1000), 2) as avg_vacancies_per_1000,
        round(avg(job_vacancy_rate), 2) as avg_job_vacancy_rate,
        sum(job_vacancies) as total_job_vacancies
    from monthly
    group by geo, year
)

select
    m.*,
    a.avg_vacancies_per_1000,
    a.avg_job_vacancy_rate,
    a.total_job_vacancies
from monthly_yoy_pct m
left join annual_avg a
    on m.geo = a.geo
    and m.year = a.year