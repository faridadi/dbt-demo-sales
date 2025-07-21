# dbt command 

## Dependensi: 
- pip install dbt-core==1.9.0 
- pip install dbt-postgres==1.9.0

1. Edit dan Tambah file profile.yml di folder ict_sales/profile.yml
2. Install dependensi ```dbt deps```
3. Proses raw layer ```dbt run --model raw_layer --target raw_layer```
4. Proses Staging layer ```dbt run --model stg_layer --target stg_layer```
5. Proses Warehouse/Olap Layer ```dbt run --model wh_layer --target wh_layer```
