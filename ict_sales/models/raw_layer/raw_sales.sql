{{ config(
    materialized='incremental',
    incremental_strategy='append',
    unique_key='No. Urut'
) }}

{% if is_incremental() %}
    with max_no_urut as (
        SELECT MAX(TO_DATE(trim("Tgl Ref"), 'DD/MM/YYYY')) as tgl_referensi FROM {{this}}
    )
{% endif %}
SELECT 
    gen_random_uuid () as unique_key,
    *,
    CURRENT_TIMESTAMP AS load_at
FROM {{ source('src_layer', 'src_sales')}}
{% if is_incremental() %}
    WHERE TO_DATE(trim("Tgl Ref"), 'DD/MM/YYYY') > (SELECT tgl_referensi FROM max_no_urut)
{% else %}
    WHERE TO_DATE(trim("Tgl Ref"), 'DD/MM/YYYY') <= date'2025-05-08' --*untuk init awal, percobaan incremental
{% endif %}