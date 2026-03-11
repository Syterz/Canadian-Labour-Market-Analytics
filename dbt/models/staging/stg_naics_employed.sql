with source as (
    select * from {{ source('canada_labour_market', 'naics_employed_curated') }}
),

renamed as (
    select
        date_parsed,
        geo,
        year,
        naics,
        total_employment
    from source
    where date_parsed is not null
)

select * from renamed