{{ config(
    materialized='incremental',
    indexes=[
        {'columns': ['kode_barang'], 'type': 'hash'}
    ],
    incremental_strategy='merge',
    unique_key='sgt_key',
    enabled=true
) }}

WITH source_data AS (
    SELECT 
        -- ROW_NUMBER() OVER (PARTITION BY kode_barang, satuan, satuan_standart  ORDER BY tgl_referensi DESC, no_urut DESC) as rn,
        -- no_urut,
        ROW_NUMBER() OVER (PARTITION BY kode_barang, satuan, satuan_standart  ORDER BY tgl_referensi DESC) as rn,
        kode_barang,
        nama_jenis_barang,
        satuan,
        satuan_standart,
        (quantity_standart/quantity) as quantity_standart,
        tgl_referensi
    FROM stg_layer.stg_sales
    WHERE kode_barang IS NOT NULL
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
        kode_barang,
        nama_jenis_barang,
        satuan,
        satuan_standart,
        quantity_standart,
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
        {{ dbt_utils.generate_surrogate_key(['new.kode_barang','new.satuan','new.satuan_standart']) }} as natural_id,
        -- new.no_urut,
        new.kode_barang,
        new.nama_jenis_barang,
        new.satuan,
        new.satuan_standart,
        new.quantity_standart,
        new.tgl_referensi as valid_start,
        null::timestamptz as valid_end,
        true as is_active
    from new_unique_data new
    left join current_active current
        on current.kode_barang = new.kode_barang and new.satuan = current.satuan and new.satuan_standart = current.satuan_standart
    WHERE current.kode_barang IS NULL OR ((
                current.nama_jenis_barang <> new.nama_jenis_barang
            )
        )
),

--* data yang tidak berubah
remaining_record as (
    select
        current.sgt_key,
        current.natural_id,
        -- current.no_urut,
        current.kode_barang,
        current.nama_jenis_barang,
        current.satuan,
        current.satuan_standart,
        current.quantity_standart,
        current.valid_start,
        update_data.valid_start as valid_end,
        false as is_active
    from current_active current
    left join new_unique_data new
        on current.kode_barang = new.kode_barang and new.satuan = current.satuan and new.satuan_standart = current.satuan_standart
    left join new_or_update_records update_data
        on current.kode_barang = update_data.kode_barang and update_data.satuan = current.satuan and update_data.satuan_standart = current.satuan_standart
    WHERE current.kode_barang IS NULL OR ( (
                current.nama_jenis_barang <> new.nama_jenis_barang
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
        {{ dbt_utils.generate_surrogate_key(['kode_barang','satuan','satuan_standart']) }} as natural_id,
        -- no_urut,
        kode_barang,
        nama_jenis_barang,
        satuan,
        satuan_standart,
        quantity_standart,
        tgl_referensi::timestamptz as valid_start,
        null::timestamptz as valid_end,
        true as is_active
    from new_unique_data
{% endif %}
