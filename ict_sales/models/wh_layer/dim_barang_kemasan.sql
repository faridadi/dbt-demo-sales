{{ config(
    materialized = 'table',
    incremental_strategy = 'merge',
    unique_key = 'sgt_key',
    enabled = false
) }}

with source_data as (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY kode_barang, satuan, nama_jenis_barang ORDER BY no_urut DESC) as rn,
        no_urut,
        kode_barang,
        nama_jenis_barang,
        satuan,
        satuan_standart,
        (quantity_standart/quantity) as quantity_standart,
        harga_unit
    FROM {{ source('stg_layer','stg_sales') }}
    WHERE kode_barang IS NOT NULL
)

select
    gen_random_uuid() as sgt_key,
    {{ dbt_utils.generate_surrogate_key(['kode_barang','satuan','satuan_standart']) }} as id,
    no_urut,
    kode_barang,
    nama_jenis_barang,
    satuan,
    satuan_standart,
    quantity_standart,
    harga_unit
from source_data
where rn = 1