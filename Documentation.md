# Dokumentasi Proyek Data OLAP Transaksi Penjualan

## 1. Overview

Project ini bertujuan untuk membangun data warehouse dengan pendekatan **Star Schema** dan **Medalion** dari data transaksi penjualan (raw) manjadi data yang mudah diolah, dianalisis, dan diintegrasikan dengan kebutuhan Business Intelligence (BI).

---

## 2. Data Pipeline dan Lapisan
1. **Source layer** : Layer untuk menyimapan data dari data source
2. **Raw Layer**: Menyimpan data transaksi mentah dari sumber ini (raw_sales).
3. **Staging Layer**: Layer untuk membersihkan dan menormalkan, merename nama kolom, data (stg_sales)
4. **Warehouse Layer (OLAP Star Schema)**: Adalah Layer Data dalam bentuk tabel fakta dan dimensi (dim_barang, dim_customer, dst) atau layer data yang sudha siap untuk digunakan BI Tools
    

---

## 3. Deskripsi Tiap Layer 
### 1. RAW LAYER
#### Tabel: `raw_layer.raw_sales`
Tabel ini menyimpan data mentah hasil extract dari layer source yang bersumber dari penarisumber transaksi.

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|unique_key|uuid|Unique identifier per record|
|No. Urut|float4|Nomor urut transaksi (biasanya running number di sumber)|
|Ref|varchar(50)|Referensi transaksi|
|Tgl Ref|varchar(50)|Tanggal referensi transaksi (format string)|
|No. Ref|varchar(50)|Nomor referensi transaksi|
|No. Dok Ref|varchar(50)|Nomor dokumen referensi|
|Kode Cust|varchar(50)|Kode pelanggan|
|Nama Cust|varchar(50)|Nama pelanggan|
|Alamat Cust|varchar(128)|Alamat pelanggan|
|Kode Panel|varchar(50)|Kode panel penjualan (opsional, tergantung bisnis)|
|Nama Panel|varchar(50)|Nama panel|
|Kode Sales|varchar(50)|Kode sales/marketing|
|Nama Sales|varchar(50)|Nama sales|
|Keterangan|varchar(50)|Keterangan tambahan pada transaksi|
|Pajak|varchar(50)|Jenis pajak transaksi|
|Kategori Pjk|varchar(50)|Kategori pajak|
|Kode Barang|varchar(50)|Kode barang|
|Nama Jns Brg|varchar(50)|Nama jenis barang|
|Ket Ref|varchar(50)|Keterangan referensi|
|Qty|float4|Jumlah barang terjual|
|Sat|varchar(50)|Satuan barang|
|Qty Std|float4|Jumlah standar (jika ada konversi satuan)|
|Sat Std|varchar(50)|Satuan standar|
|Harga (+)|float4|Harga per unit|
|Harga Sbl (+)|varchar(50)|Harga sebelumnya|
|Harga Unit(Mu)|varchar(50)|Harga unit dalam mata uang|
|Total(MU)|varchar(50)|Total penjualan (dalam mata uang)|
|Disc. 1 (%)|float4|Diskon 1 dalam persen|
|Disc. 1 (MU)|varchar(50)|Diskon 1 dalam nilai uang|
|Disc. 2 (%)|float4|Diskon 2 dalam persen|
|Disc. 2 (MU)|varchar(50)|Diskon 2 dalam nilai uang|
|Disc. 3 (%)|float4|Diskon 3 dalam persen|
|Disc. 3 (MU)|float4|Diskon 3 dalam nilai uang|
|Disc. 4 (MU)|float4|Diskon 4 dalam nilai uang|
|Disc. 5 (%)|float4|Diskon 5 dalam persen|
|Disc. 5 (MU)|float4|Diskon 5 dalam nilai uang|
|Disc. 6 (MU)|float4|Diskon 6 dalam nilai uang|
|Subtot Disc(Mu)|varchar(50)|Subtotal diskon (dalam mata uang)|
|Subtot(Mu)|varchar(50)|Subtotal (dalam mata uang)|
|Hrg Unit Riil(Mu)|varchar(50)|Harga unit riil (setelah diskon, dalam mata uang)|
|Total Riil(Mu)|varchar(50)|Total riil setelah diskon|
|Subtot Disc Riil(Mu)|varchar(50)|Subtotal diskon riil|
|Subtot Riil(Mu)|varchar(50)|Subtotal riil|
|Disc Akh(Mu)|float4|Diskon akhir dalam nilai uang|
|Subtot Net(Mu)|varchar(50)|Subtotal net (setelah diskon dan pajak)|
|Pjk(Mu)|varchar(50)|Pajak dalam nilai uang|
|Subtot Net Pjk(Mu)|varchar(50)|Subtotal net pajak|
|Kode Kota|varchar(50)|Kode kota pelanggan|
|Nama Kota|varchar(50)|Nama kota pelanggan|
|load_at|timestamptz|Tanggal dan jam data dimuat ke raw layer|

---

### 2. STAGING LAYER

#### Tabel: `stg_layer.stg_sales` (View)
Di tahap ini, dilakukan **normalasisi** data kosong **penyesuaian tipe data**, serta **normalisasi nama kolom** agar konsisten dan siap digunakan transformasi pada layer WH.

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|unique_key|uuid|Unique identifier per record|
|no_urut|bigint|Nomor urut transaksi|
|ref|varchar|Referensi transaksi|
|tgl_referensi|date|Tanggal referensi transaksi (hasil konversi string ke tanggal)|
|no_referensi|varchar|Nomor referensi transaksi|
|no_dokumen_referensi|varchar|Nomor dokumen referensi|
|kode_konsumen|varchar|Kode pelanggan (sudah dinormalisasi)|
|nama_konsumen|varchar|Nama pelanggan (huruf besar, tidak kosong)|
|alamat_konsumen|varchar|Alamat pelanggan (huruf besar, tidak kosong)|
|kode_panel|varchar|Kode panel (default: 'OTHER' jika kosong)|
|nama_panel|varchar|Nama panel (default: 'OTHER' jika kosong)|
|kode_sales|varchar|Kode sales|
|nama_sales|varchar|Nama sales (huruf besar)|
|keterangan|varchar|Keterangan tambahan (default: 'N/A' jika kosong)|
|pajak|varchar|Jenis pajak transaksi|
|kategori_pajak|varchar|Kategori pajak|
|kode_barang|varchar|Kode barang|
|nama_jenis_barang|varchar|Nama jenis barang (huruf besar, default: 'N/A')|
|keterangan_referensi|varchar|Keterangan referensi (huruf besar)|
|quantity|integer|Jumlah barang terjual (sudah dibersihkan dari koma, desimal ke integer)|
|satuan|varchar|Satuan barang|
|quantity_standart|integer|Jumlah dalam satuan standar|
|satuan_standart|varchar|Satuan standar|
|harga|numeric(20,4)|Harga per unit (sudah dibersihkan, tipe numerik)|
|harga_sebelum|numeric(20,4)|Harga sebelumnya|
|harga_unit|numeric(20,4)|Harga unit dalam mata uang|
|total|numeric(20,4)|Total penjualan|
|diskon_1_persen|numeric(8,4)|Diskon 1 (%)|
|diskon_1_amount|numeric(20,4)|Diskon 1 (nilai)|
|diskon_2_persen|numeric(8,4)|Diskon 2 (%)|
|diskon_2_amount|numeric(20,4)|Diskon 2 (nilai)|
|diskon_3_persen|numeric(8,4)|Diskon 3 (%)|
|diskon_3_amount|numeric(20,4)|Diskon 3 (nilai)|
|diskon_4_amount|numeric(20,4)|Diskon 4 (nilai)|
|diskon_5_persen|numeric(8,4)|Diskon 5 (%)|
|diskon_5_amount|numeric(20,4)|Diskon 5 (nilai)|
|diskon_6_amount|numeric(20,4)|Diskon 6 (nilai)|
|sub_total_diskon_amount|numeric(20,4)|Subtotal diskon|
|sub_total_amount|numeric(20,4)|Subtotal penjualan|
|harga_unit_rill_amount|numeric(20,4)|Harga unit riil (setelah diskon)|
|total_riil_amount|numeric(20,4)|Total penjualan riil|
|sub_total_diskon_riil_amount|numeric(20,4)|Subtotal diskon riil|
|sub_total_riil_amount|numeric(20,4)|Subtotal riil|
|diskon_akhir_amount|numeric(20,4)|Diskon akhir (nilai)|
|sub_total_net_amount|numeric(20,4)|Subtotal setelah diskon & pajak|
|pajak_amount|numeric(20,4)|Pajak (nilai)|
|sub_total_net_pajak_amount|numeric(20,4)|Subtotal net pajak|
|kode_kota|varchar|Kode kota (default: 'OTHER' jika kosong)|
|nama_kota|varchar|Nama kota (default: 'OTHER' jika kosong)|
|load_at|timestamptz|Timestamp saat data dimuat ke staging layer|

---

### 3. WAREHOUSE LAYER (STAR SCHEMA)
Data sudah dinormalisasi menjadi **tabel dimensi** dan **tabel fakta** untuk mendukung query OLAP.
#### 1.1. Tabel Dimensi
Pada Tabel dimenasi untuk semua dimenasi sudah dijadikan SCD Type 2
##### a. `wh_layer.dim_barang`

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|sgt_key|uuid|Surrogate key, unique identifier|
|natural_id|text|Natural key (kode unik dari sumber data, bisa kombinasi kode barang, satuan, dll)|
|kode_barang|varchar|Kode barang|
|nama_jenis_barang|varchar|Nama jenis barang|
|satuan|varchar|Satuan barang|
|satuan_standart|varchar|Satuan standar|
|quantity_standart|int4|Jumlah dalam satuan standar|
|valid_start|timestamptz|Mulai berlaku (valid from)|
|valid_end|timestamptz|Berakhir berlaku (valid to)|
|is_active|bool|Apakah masih aktif (SCD)|

##### b. `wh_layer.dim_customer`

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|sgt_key|uuid|Surrogate key, unique identifier|
|kode_konsumen|varchar|Kode pelanggan|
|nama_konsumen|varchar|Nama pelanggan|
|alamat_konsumen|varchar|Alamat pelanggan|
|valid_start|timestamptz|Mulai berlaku (valid from)|
|valid_end|timestamptz|Berakhir berlaku (valid to)|
|is_active|bool|Apakah masih aktif (SCD)|

##### c. `wh_layer.dim_employee_sales`

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|sgt_key|uuid|Surrogate key, unique identifier|
|kode_sales|varchar|Kode sales/marketing|
|nama_sales|varchar|Nama sales|
|valid_start|timestamptz|Mulai berlaku (valid from)|
|valid_end|timestamptz|Berakhir berlaku (valid to)|
|is_active|bool|Apakah masih aktif (SCD)|

##### d. `wh_layer.dim_kota`

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|sgt_key|uuid|Surrogate key, unique identifier|
|kode_kota|varchar|Kode kota|
|nama_kota|varchar|Nama kota|
|valid_start|timestamptz|Mulai berlaku (valid from)|
|valid_end|timestamptz|Berakhir berlaku (valid to)|
|is_active|bool|Apakah masih aktif (SCD)|

##### e. `wh_layer.dim_pajak`

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|sgt_key|uuid|Surrogate key, unique identifier|
|pajak|varchar|Jenis pajak|
|kategori_pajak|varchar|Kategori pajak|
|persen|int4|Persentase pajak (jika ada)|
|valid_start|timestamptz|Mulai berlaku (valid from)|
|valid_end|timestamptz|Berakhir berlaku (valid to)|
|is_active|bool|Apakah masih aktif (SCD)|

##### f. `wh_layer.dim_panel`

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|sgt_key|uuid|Surrogate key, unique identifier|
|kode_panel|varchar|Kode panel|
|nama_panel|varchar|Nama panel|
|valid_start|timestamptz|Mulai berlaku (valid from)|
|valid_end|timestamptz|Berakhir berlaku (valid to)|
|is_active|bool|Apakah masih aktif (SCD)|

---

#### 1.2. Tabel Fakta

##### Tabel: `wh_layer.fact_transaction`
Tabel ini menyimpan data transaksi penjualan yang menjadi pusat analisis (tabel fact). Setiap record mengacu ke tabel dimensi melalui kode/foreign key.

|Nama Kolom|Tipe Data|Deskripsi|
|---|---|---|
|unique_key|uuid|Unique identifier transaksi|
|tgl_referensi|date|Tanggal transaksi|
|no_referensi|varchar|Nomor referensi transaksi|
|no_dokumen_referensi|varchar|Nomor dokumen referensi|
|ref|varchar|Referensi transaksi|
|kode_konsumen|varchar|Kode pelanggan (foreign key ke dim_customer)|
|kode_panel|varchar|Kode panel (foreign key ke dim_panel)|
|kode_sales|varchar|Kode sales (foreign key ke dim_employee_sales)|
|keterangan|varchar|Keterangan transaksi|
|pajak|varchar|Jenis pajak (foreign key ke dim_pajak)|
|kode_barang|varchar|Kode barang (foreign key ke dim_barang)|
|keterangan_referensi|varchar|Keterangan referensi|
|quantity|int4|Jumlah barang terjual|
|satuan|varchar|Satuan barang|
|quantity_standart|int4|Jumlah dalam satuan standar|
|satuan_standart|varchar|Satuan standar|
|harga|numeric(20,4)|Harga per unit|
|harga_sebelum|numeric(20,4)|Harga sebelum diskon|
|harga_unit|numeric(20,4)|Harga unit dalam mata uang|
|total|numeric(20,4)|Total penjualan|
|diskon_1_persen|numeric(8,4)|Diskon 1 dalam persen|
|diskon_1_amount|numeric(20,4)|Diskon 1 dalam nilai uang|
|diskon_2_persen|numeric(8,4)|Diskon 2 dalam persen|
|diskon_2_amount|numeric(20,4)|Diskon 2 dalam nilai uang|
|diskon_3_persen|numeric(8,4)|Diskon 3 dalam persen|
|diskon_3_amount|numeric(20,4)|Diskon 3 dalam nilai uang|
|diskon_4_amount|numeric(20,4)|Diskon 4 dalam nilai uang|
|diskon_5_persen|numeric(8,4)|Diskon 5 dalam persen|
|diskon_5_amount|||

| numeric(20,4) | Diskon 5 dalam nilai uang |  
| diskon_6_amount | numeric(20,4) | Diskon 6 dalam nilai uang |  
| sub_total_diskon_amount | numeric(20,4) | Subtotal diskon |  
| sub_total_amount | numeric(20,4) | Subtotal penjualan |  
| harga_unit_rill_amount | numeric(20,4) | Harga unit riil (setelah diskon) |  
| total_riil_amount | numeric(20,4) | Total riil penjualan |  
| sub_total_diskon_riil_amount | numeric(20,4) | Subtotal diskon riil |  
| sub_total_riil_amount | numeric(20,4) | Subtotal riil |  
| diskon_akhir_amount | numeric(20,4) | Diskon akhir |  
| sub_total_net_amount | numeric(20,4) | Subtotal net (setelah pajak & diskon) |  
| pajak_amount | numeric(20,4) | Pajak (nilai) |  
| sub_total_net_pajak_amount | numeric(20,4) | Subtotal net setelah pajak |  
| kode_kota | varchar | Kode kota (foreign key ke dim_kota) |

### 5. Data Visualiasasi
Setelah data diolah dan distukturkan dalam bentuk star schema pada warehouse, langkah berikutnya adalah menyediakan **dashboard interaktif** untuk analisis bisnis menggunakan **Apache Superset**.
Dashboard ini mencakup beberapa visualisasi utama, antara lain:

1. **Daily Sales Trend**  
    Menampilkan grafik tren penjualan harian (line chart) untuk memantau perkembangan total penjualan setiap hari.
2. **Monthly Target Sales**  
    Visualisasi berbentuk gauge/meters yang menunjukkan pencapaian target penjualan bulanan secara real-time.
3. **Top Customers by Sales**  
    Tabel interaktif dengan bar chart horizontal yang menunjukkan konsumen dengan nilai penjualan terbesar, total net, serta diskon yang diberikan, lengkap dengan persentase diskon.
4. **Monthly Sales Performance by Person**
   Menampilkan Bar chart, performa penjualan sales perbulan.
5. **FIlter** 
   Dasoard ini mempuinya 2 filter:
   - filter date range untuk kurun waktu yang ingin dilihat
   - FIlter Kota filter untuk melihat chart untuk tiap Kota

	
Dashboard ini sepenuhnya terhubung dengan tabel-tabel OLAP di warehouse, sehingga analitik data bisa dilakukan secara cepat, interaktif, dan akurat.
### 4. Penutup

Dengan struktur seperti ini, data transaksi siap dianalisis menggunakan OLAP tools atau BI tools (mis: Superset, Power BI, Tableau) karena sudah terstruktur secara normalized dan memudahkan pembuatan agregasi, laporan penjualan, analisis pelanggan, produk, wilayah, hingga analisis diskon dan pajak.
