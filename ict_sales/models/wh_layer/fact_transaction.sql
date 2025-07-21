{{ config(
    materialized='incremental',
    indexes=[
        {'columns': ['tgl_referensi'], 'type': 'btree'}
    ],
    incremental_strategy='merge',
    unique_key='unique_key',
    enabled=true
) }}

{% if is_incremental() %}
with max_tgl_ref as (
  select max(tgl_referensi) as tgl_referensi from {{ this }}
)
{% endif %}

SELECT
    unique_key,
    -- no_urut,
    tgl_referensi,
    no_referensi,
    no_dokumen_referensi,
    "ref",
    kode_konsumen,
    kode_panel,
    kode_sales,
    keterangan,
    pajak,
    kode_barang,
    keterangan_referensi,
    quantity,
    satuan,
    quantity_standart,
    satuan_standart,
    harga,
    harga_sebelum,
    harga_unit,
    total,
    diskon_1_persen,
    diskon_1_amount,
    diskon_2_persen,
    diskon_2_amount,
    diskon_3_persen,
    diskon_3_amount,
    diskon_4_amount,
    diskon_5_persen,
    diskon_5_amount,
    diskon_6_amount,
    sub_total_diskon_amount,
    sub_total_amount,
    harga_unit_rill_amount,
    total_riil_amount,
    sub_total_diskon_riil_amount,
    sub_total_riil_amount,
    diskon_akhir_amount,
    sub_total_net_amount,
    pajak_amount,
    sub_total_net_pajak_amount,
    kode_kota
FROM {{source('stg_layer','stg_sales')}}
{% if is_incremental() %}
    WHERE tgl_referensi > (select tgl_referensi from max_tgl_ref)
{% endif %}