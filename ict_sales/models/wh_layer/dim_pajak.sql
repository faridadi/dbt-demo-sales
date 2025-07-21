{{ config(
    materialized='incremental',
    indexes=[
        {'columns': ['pajak'], 'type': 'hash'}
    ],
    incremental_strategy='merge',
    unique_key='sgt_key'
) }}

WITH source_data AS (
    SELECT 
        -- ROW_NUMBER() OVER (PARTITION BY pajak ORDER BY tgl_referensi DESC, no_urut DESC) as rn,
        -- no_urut,
        ROW_NUMBER() OVER (PARTITION BY pajak ORDER BY tgl_referensi DESC) as rn,
        pajak,
        kategori_pajak,
        cast(pajak_amount*100/sub_total_net_amount as int4) as persen,
        tgl_referensi
    FROM {{source('stg_layer','stg_sales')}}
    WHERE pajak IS NOT NULL
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
        pajak,
        kategori_pajak,
        persen,
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
        new.pajak,
        new.kategori_pajak,
        new.persen,
        tgl_referensi as valid_start,
        null::timestamptz as valid_end,
        true as is_active
    from new_unique_data new
    left join current_active current
        on current.pajak = new.pajak
    WHERE current.pajak IS NULL OR ((
                current.kategori_pajak <> new.kategori_pajak
            )
        )
),

--* data yang tidak berubah
remaining_record as (
    select
        current.sgt_key,
        -- current.no_urut,
        current.pajak,
        current.kategori_pajak,
        current.persen,
        current.valid_start,
        new_update.valid_start as valid_end,
        false as is_active
    from current_active current
    left join new_unique_data new
        on current.pajak = new.pajak
    left join new_or_update_records new_update
        on current.pajak = new_update.pajak
    WHERE current.pajak IS NULL OR ( (
                current.kategori_pajak <> new.kategori_pajak
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
        pajak,
        kategori_pajak,
        persen,
        tgl_referensi::timestamptz as valid_start,
        null::timestamptz as valid_end,
        true as is_active
    from new_unique_data
{% endif %}
