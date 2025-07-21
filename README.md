dbt command dependensi: pip install dbt-core==1.9.0 pip install dbt-postgres==1.9.0

Tambah file profile.yml di folder ict_sales/profile.yml

Install dependensi dbt deps
Proses raw layer dbt run --model raw_layer --target raw_layer
Proses Staging layer dbt run --model stg_layer --target stg_layer
Proses Warehouse/Olap Layer dbt run --model wh_layer --target wh_layer
