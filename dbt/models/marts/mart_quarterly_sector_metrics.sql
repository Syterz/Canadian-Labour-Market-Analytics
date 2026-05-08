{{ config(materialized='table') }}

with quarterly as (
    select
        date_parsed,
        geo,
        year,
        naics,
        job_vacancies,
        job_vacancy_rate,
        avg_offered_hourly_wage,
        payroll_employees,
        vacancies_per_1000
    from {{ ref('stg_quarterly_vacancies') }}
),

quarterly_yoy as (
    select
        *,
        lag(vacancies_per_1000, 4) over (
            partition by geo, naics
            order by date_parsed
        ) as prev_year_vacancies_per_1000,
        lag(job_vacancy_rate, 4) over (
            partition by geo, naics
            order by date_parsed
        ) as prev_year_vacancy_rate,
        lag(avg_offered_hourly_wage, 4) over (
            partition by geo, naics
            order by date_parsed
        ) as prev_year_wage
    from quarterly
),

quarterly_yoy_pct as (
    select
        *,
        case
            when vacancies_per_1000 is not null
            and prev_year_vacancies_per_1000 is not null
            then round(
                (vacancies_per_1000 - prev_year_vacancies_per_1000)
                / nullif(prev_year_vacancies_per_1000, 0) * 100, 2
            )
            else null
        end as vacancy_rate_yoy_change_pct,
        case
            when avg_offered_hourly_wage is not null
            and prev_year_wage is not null
            then round(
                (avg_offered_hourly_wage - prev_year_wage)
                / nullif(prev_year_wage, 0) * 100, 2
            )
            else null
        end as wage_yoy_change_pct
    from quarterly_yoy
),

demand_ranked as (
    select
        *,
        case
            when job_vacancy_rate is not null
            then rank() over (
                partition by geo, date_parsed
                order by job_vacancy_rate desc
            )
            else null
        end as demand_rank
    from quarterly_yoy_pct
),

provincial_yearly_percentiles as (
    select
        geo,
        year,
        percentile_cont(0.5) within group (order by job_vacancy_rate) as p50_vacancy_rate,
        percentile_cont(0.75) within group (order by job_vacancy_rate) as p75_vacancy_rate
    from quarterly
    where job_vacancy_rate is not null
    group by geo, year
),

sustained_demand as (
    select
        d.*,
        p.p75_vacancy_rate,
        p.p50_vacancy_rate,
        round(
            sum(case when d.job_vacancy_rate >= p.p75_vacancy_rate 
                    and d.date_parsed >= add_months(current_date(), -24)
                    then 1 else 0 end) over (
                partition by d.geo, d.naics
            ) / nullif(count(case when d.date_parsed >= add_months(current_date(), -24) 
                                then 1 end) over (
                partition by d.geo, d.naics
            ), 0) * 100, 1
        ) as pct_quarters_above_threshold_2yr
    from demand_ranked d
    left join provincial_yearly_percentiles p
        on d.geo = p.geo
        and d.year = p.year
),

lmia_thresholds as (
    select * from {{ ref('provincial_lmia_wage_thresholds') }}
),

final as (
    select
        s.*,
        t.lmia_high_wage_threshold,
        case
            when s.avg_offered_hourly_wage is null 
            and s.job_vacancy_rate is null
                then 'Insufficient Data'
            when s.avg_offered_hourly_wage is null
            and s.job_vacancy_rate >= s.p75_vacancy_rate
            and s.pct_quarters_above_threshold_2yr >= 75
                then 'High Demand and Sustained, No Wage Data'
            when s.avg_offered_hourly_wage is null
            and s.job_vacancy_rate >= s.p50_vacancy_rate
                then 'Above Average Demand, No Wage Data'
            when s.job_vacancy_rate is null
            and s.avg_offered_hourly_wage >= t.lmia_high_wage_threshold
                then 'Wage Eligible, No Vacancy Data'
            when s.avg_offered_hourly_wage >= t.lmia_high_wage_threshold
            and s.job_vacancy_rate >= s.p75_vacancy_rate
            and s.pct_quarters_above_threshold_2yr >= 75
                then 'HIGH, Wage Eligible, High Demand and Sustain'
            when s.avg_offered_hourly_wage >= t.lmia_high_wage_threshold
            and s.job_vacancy_rate >= s.p50_vacancy_rate
                then 'Wage Eligible, High Demand'
            when s.avg_offered_hourly_wage >= t.lmia_high_wage_threshold
                then 'Wage Eligible'
            when s.job_vacancy_rate >= s.p75_vacancy_rate
            and s.pct_quarters_above_threshold_2yr >= 75
                then 'High Demand and Sustained, Below Wage Threshold'
            when s.job_vacancy_rate >= s.p50_vacancy_rate
                then 'Above Average Demand, Below Wage Threshold'
            else 'Low'
        end as foreign_accessibility_tier
    from sustained_demand s
    left join lmia_thresholds t
        on s.geo = t.geo
)

select * from final