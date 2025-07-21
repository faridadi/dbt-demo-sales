{{ config(
    materialized='incremental',
    indexes=[
        {'columns': ['kode_sales'], 'type': 'hash'}
    ],
    incremental_strategy='merge',
    unique_key='sgt_key'
) }}

WITH source_data AS (
    SELECT 
        -- ROW_NUMBER() OVER (PARTITION BY kode_sales ORDER BY tgl_referensi DESC, no_urut DESC) as rn,
        -- no_urut,
        ROW_NUMBER() OVER (PARTITION BY kode_sales ORDER BY tgl_referensi DESC) as rn,
        kode_sales,
        nama_sales,
        tgl_referensi
    FROM {{source('stg_layer','stg_sales')}}
    WHERE kode_sales IS NOT NULL
),

{% if is_incremental() %}
--* Nilai no urutan tertinggi pada tabel dim
    max_ts as (
        select max(cast(valid_start as date)) as tgl_referensi from {{ this }}
    ),
{% endif %}

new_unique_data AS (
--* Data terbaru pada tabel fact
    SELECT
        -- no_urut,
        kode_sales,
        nama_sales,
        tgl_referensi
    FROM source_data s
    where s.rn = 1
    {% if is_incremental() %}
        and tgl_referensi > (select tgl_referensi from max_ts)
    {% endif %}
)


{% if is_incremental() %}
--* Proses incremental
,
current_active AS (
    SELECT *
    FROM {{ this }}
    WHERE is_active = true
),

--* data dim baru dan data update dari fact
new_or_update_records as (
    select
        gen_random_uuid() as sgt_key,
        -- new.no_urut,
        new.kode_sales,
        new.nama_sales,
        tgl_referensi as valid_start,
        null::timestamptz as valid_end,
        true as is_active
    from new_unique_data new
    left join current_active current
        on current.kode_sales = new.kode_sales
    WHERE current.kode_sales IS NULL OR ((
                current.nama_sales <> new.nama_sales
            )
        )
),

--* data yang tidak berubah
remaining_record as (
    select
        current.sgt_key,
        -- current.no_urut,
        current.kode_sales,
        current.nama_sales,
        current.valid_start,
        new_update.valid_start as valid_end,
        false as is_active
    from current_active current
    left join new_unique_data new
        on current.kode_sales = new.kode_sales
    left join new_or_update_records new_update
        on current.kode_sales = new_update.kode_sales
    WHERE current.kode_sales IS NULL OR ( (
                current.nama_sales <> new.nama_sales
            )
        )
)

--* Gabung data remaining dan data new/update
SELECT *
FROM remaining_record
UNION ALL
SELECT *
FROM new_or_update_records

{% else %}
--* handling data full refresh
    select
        gen_random_uuid() as sgt_key,
        -- no_urut,
        kode_sales,
        nama_sales,
        tgl_referensi::timestamptz as valid_start,
        null::timestamptz as valid_end,
        true as is_active
    from new_unique_data
{% endif %}
