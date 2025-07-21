{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='sgt_key',
    sort_by='valid_start'
) }}

WITH source_data AS (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY kode_panel ORDER BY tgl_referensi DESC) as rn,
        kode_panel,
        nama_panel,
        tgl_referensi
    FROM {{source('stg_layer','stg_sales')}}
    WHERE kode_panel IS NOT NULL
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
        kode_panel,
        nama_panel,
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
        new.kode_panel,
        new.nama_panel,
        tgl_referensi as valid_start,
        null::timestamptz as valid_end,
        true as is_active
    from new_unique_data new
    left join current_active current
        on current.kode_panel = new.kode_panel
    WHERE current.kode_panel IS NULL OR ((
                current.nama_panel <> new.nama_panel
            )
        )
),

--* data yang tidak berubah
remaining_record as (
    select
        current.sgt_key,
        -- current.no_urut,
        current.kode_panel,
        current.nama_panel,
        current.valid_start,
        new_update.valid_start as valid_end,
        false as is_active
    from current_active current
    left join new_unique_data new
        on current.kode_panel = new.kode_panel
    left join new_or_update_records new_update
        on current.kode_panel = new_update.kode_panel
    WHERE current.kode_panel IS NULL OR ( (
                current.nama_panel <> new.nama_panel
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
        kode_panel,
        nama_panel,
        tgl_referensi::timestamptz as valid_start,
        null::timestamptz as valid_end,
        true as is_active
    from new_unique_data
{% endif %}
