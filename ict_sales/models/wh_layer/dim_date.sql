{{ config(
    materialized='table',
    enabled=true
) }}


WITH raw_generated_data AS (
    {{ dbt_date.get_date_dimension("2020-01-01", "2030-12-31") }}
),

hari_renamed AS (
    SELECT 
        *,
        CASE
            WHEN month_of_year = 1 THEN 'Januari'
            WHEN month_of_year = 2 THEN 'Februari'
            WHEN month_of_year = 3 THEN 'Maret'
            WHEN month_of_year = 4 THEN 'April'
            WHEN month_of_year = 5 THEN 'Mei'
            WHEN month_of_year = 6 THEN 'Juni'
            WHEN month_of_year = 7 THEN 'Juli'
            WHEN month_of_year = 8 THEN 'Agustus'
            WHEN month_of_year = 9 THEN 'September'
            WHEN month_of_year = 10 THEN 'Oktober'
            WHEN month_of_year = 11 THEN 'November'
            WHEN month_of_year = 12 THEN 'Desember'
        END AS month_name_id,
        
        CASE
            WHEN day_of_week = 1 THEN 'Minggu'
            WHEN day_of_week = 2 THEN 'Senin'
            WHEN day_of_week = 3 THEN 'Selasa'
            WHEN day_of_week = 4 THEN 'Rabu'
            WHEN day_of_week = 5 THEN 'Kamis'
            WHEN day_of_week = 6 THEN 'Jumat'
            WHEN day_of_week = 7 THEN 'Sabtu'
        END AS day_of_week_name_id,

        CASE
            WHEN day_of_week = 1 THEN FALSE  -- Minggu
            ELSE TRUE
        END AS is_workday

    FROM raw_generated_data
)

SELECT *
FROM hari_renamed
order by date_day
