---
title: "Operasi CRUD Realtime Database Firebase Untuk Android Apps"
slug: "operasi-crud-realtime-database-firebase-untuk-android-apps"
category: "Android"
date: "2021-01-03"
status: "published"
---

Sejak awal tahun 2019, saya aktif berbagi ilmu tentang pengembangan aplikasi android di salah satu kampus di kota tempat saya tinggal. Materi yang dibahas biasanya dimulai dari dasar sampai interaksi ke database. Dan salah satu materi yang sering saya bagikan dengan teman-teman mahasiswa adalah mengenai pengembangan aplikasi yang terhubung dengan Firebase Realtime Database. Selain untuk mengikat ilmu, tutorial Operasi CRUD Realtime Database Firebase Untuk Android Apps ini ditulis sebagai dokumentasi hasil sharing session dengan teman-teman mahasiswa, juga agar saya dan teman-teman bisa sama-sama belajar. Tertarik untuk belajar? Yuk kita mulai!

## Apa itu Firebase Realtime Database{#apa-itu-firebase-realtime-database}
Menurut Dokumentasi Resminya[^1], Firebase Realtime Database adalah database yang di-host di cloud. Pada database ini, data akan disimpan sebagai `JSON` dan disinkronkan secara realtime ke setiap klien yang terhubung. Dengan kemampuan sinkronisasi secara realtime ini, ketika kita mengembangkan aplikasi yang cross platform dengan SDK Android, iOS, dan JavaScript, semua klien akan berbagi sebuah instance Realtime Database dan menerima update data terbaru secara otomatis.

## Kemampuan utama Firebase Realtime Database{#kemampuan-firebase-realtime-database}
Ada beberapa kemampuan utama yang dimiliki Firebase Realtime Database, diantaranya:
1. **Realtime**. Sebagai ganti request HTTP biasa, Firebase Realtime Database menggunakan sinkronisasi data. Setiap kali data berubah, semua perangkat yang terhubung akan menerima update dalam waktu milidetik. Memberikan pengalaman yang kolaboratif dan imersif tanpa perlu memikirkan kode jaringan.
2. **Offline**.	Aplikasi Firebase tetap responsif bahkan saat offline karena SDK Firebase Realtime Database menyimpan data ke disk. Setelah konektivitas pulih, perangkat klien akan menerima setiap perubahan yang terlewat dan melakukan sinkronisasi dengan status server saat ini.
3. **Dapat Diakses dari Perangkat Klien**.  Firebase Realtime Database dapat diakses secara langsung dari perangkat seluler atau browser web; server aplikasi tidak diperlukan. Keamanan dan validasi data dapat diakses melalui Aturan Keamanan Firebase Realtime Database yang merupakan kumpulan aturan berbasis ekspresi dan dijalankan ketika data dibaca atau ditulis.
4. **Menskalakan di beberapa database**. Dengan Firebase Realtime Database pada paket harga Blaze, Anda dapat mendukung kebutuhan data aplikasi Anda pada skala tertentu dengan membagi data Anda di beberapa instance database di project Firebase yang sama. Menyederhanakan autentikasi dengan Firebase Authentication pada project Anda dan mengautentikasi pengguna di instance database Anda. Mengontrol akses ke data di tiap database dengan Aturan Firebase Realtime Database khusus untuk tiap instance database.

## Bagaimana cara kerja Firebase Realtime Database?{#cara-kerja-firebase-realtime-database}
Firebase Realtime Database memungkinkan kita sebagai developer untuk membuat aplikasi kolaboratif dan kaya fitur dengan menyediakan akses yang aman ke database, langsung dari kode sisi klien. Kemampuan realtime dari database ini berlaku juga pada saat offline atau tidak terhubung ke internet. Ketika koneksi sudah tersedia, realtime database ini akan melakukan proses sinkronisasi perubahan data yang ada di lokal dengan data yang ada di database selama client dalam keadaan offline, sehingga setiap ada update data akan otomatis digabungkan.

Realtime Database menyediakan bahasa expresion-based rule yang fleksibel, atau disebut juga Firebase Realtime Database Security Rules, untuk menentukan metode strukturisasi data dan kapan data dapat dibaca atau ditulis. Ketika diintegrasikan dengan Firebase Authentication, developer dapat menentukan siapa yang memiliki akses ke data tertentu dan bagaimana mereka dapat mengaksesnya.

Realtime Database adalah database NoSQL, sehingga memiliki pengoptimalan dan fungsionalitas yang berbeda dengan relational database. API Realtime Database dirancang agar hanya mengizinkan operasi yang dapat dijalankan dengan cepat. Hal ini memungkinkan kita untuk membangun experience realtime yang luar biasa dan dapat melayani jutaan pengguna tanpa mengorbankan kemampuan respons. Oleh karena itu, perlu dipikirkan bagaimana pengguna mengakses data, kemudian buat struktur data sesuai dengan kebutuhan tersebut.

## Alur implementasi{#alur-implementasi}
1. **Mengintegrasikan Firebase Realtime Database SDK**. Sertakan klien dengan cepat melalui Gradle, CocoaPods, atau skrip.
2. **Membuat Referensi Realtime Database**. Referensikan data JSON Anda, seperti "users/user:1234/phone_number", untuk menetapkan data atau berlangganan perubahan data.
3. **Menetapkan Data dan Mendeteksi Perubahan**. Gunakan referensi ini untuk menuliskan data atau berlangganan perubahan.
4. **Mengaktifkan Persistensi Offline**. Izinkan penulisan data ke disk lokal perangkat agar tetap tersedia saat offline.
5. **Melindungi data**. Gunakan Aturan Keamanan Firebase Realtime Database untuk melindungi data Anda.

Pengenalan tentang firebasenya cukup panjang dan kalau tertarik mempelajari lebih dalam bisa kunjungi langsung dokumentasi resminya. Selanjutnya kita mulai masuk ke praktek mengembangkan aplikasi sederhana untuk operasi CRUD Realtime Database Firebase.

## Project Overview{#overview}
Pada tutorial ini kita akan belajar tentang Firebase Realtime Database, penggunaannya dan cara mengintegrasikan dengan aplikasi android yang akan kita buat. Untuk memudahkan dalam belajar, kita akan coba buat sebuah studi kasus. Skenario studi kasus kita kurang lebih seperti ini, misalkan kita diberi tugas untuk mengembangkan aplikasi pengelolaan data mahasiswa. Kebutuhan aplikasi ini cukup sederhana:
1. User dapat melihat data mahasiswa.
2. User dapat menambahkan data mahasiswa baru.
3. User dapat memperbaharui data mahasiswa yang sudah ada.
4. User dapat menghapus data mahasiswa yang sudah ada.

Selain itu untuk kebutuhan penyimpanan data, karena belum tersedia backend yang menyediakan api endpoint, sebagai solusinya di sini kita akan menggunakan Firebase Realtime Database.

## Step 1 - Buat Android Studio Project Baru{#step-1}
Buka android studio, lalu buat project baru dengan nama `Aplikasi Pengelolaan Data Mahasiswa` (Ini sebagai contoh saja, teman-teman bebas isi apa saja nama projectnya). Setelah project selesai diload, langkah selanjutnya adalah menambahkan Firebase Database ke dalam project.

## Step 2 - Set up Firebase Database{#step-2}
Menurut Dokumentasi Resminya[^2], ada dua opsi untuk menghubungkan aplikasi android. Yang pertama, menambahkan firebase melalui website Firebase Console. Yang kedua, melalui Firebase Assistant. Dan di tutorial ini, kita akan menggunakan opsi yang kedua, yaitu menggunakan Firebase Assistant. 

Untuk menggunakan Firebase Assistant, kita pilih menu **Tools→Firebase**, selanjutnya akan muncul Windows Assistant. 

![Setup Firebase](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_001.png)

Pilih Real Time Database lalu klik ```Save and retrieve data```.

![Setup Firebase - Pilih real time database](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_002.png)


Selanjutnya hubungkan aplikasi ke firebase dengan menekan tombol **Connect to Firebase** 

![Setup Firebase - connect firebase](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_003.png)


Selanjutnya akan muncul windows untuk menghubungkan ke Firebase. pilih menu Create new Firebase project lalu untuk country/region pilih indonesia, lalu tekan tombol Connect to Firebase.

![Setup Firebase - create new firebase project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_004.png)


Tunggu sampai proses pembuat firebase project selesai.

Selanjutnya atur dependencies dengan menekan tombol **Add the Realtime Database to your app**.

![Setup Firebase - atur dependencies](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_005.png)


Setelah itu akan tampil windows untuk menambahkan dependencies ke dalam aplikasi. Tekan tombol **Accept Changes** untuk menambahkan dependencies.

![Setup Firebase - menambahkan dependencies](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_006.png)


Tunggu sampai proses menambahkan dependencies selesai.

## Step 3 - Membuat Database dan Setup Konfigurasi database{#step-3}
Pada tahapan ini kita akan buat database dan kita atur konfigurasinya. Sekarang kita coba Sign in ke [Firebase Console](https://firebase.google.com/)  menggunakan account google kita. Di console Firebase, kita dapat menemukan project Aplikasi Pengelolaan data mahasiswa yang sudah dibuat di tahap sebelumnya.

![Firebase Console](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_007.png)

Klik Project `Aplikasi Pengelolaan data mahasiswa` untuk menuju ke halaman project.

Di dashboard project kita pilih menu `Database`.

![Firebase Console - dashboard project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_008.png)

Di halaman ini kita bisa lihat ada dua jenis database, yaitu Firestore dan Real Time Database. Kita scroll ke bawah, pilih create database untuk Real Time database.

![Create Realtime database](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_009.png)


Selanjutnya tampil pengaturan security untuk database. Karena project kita masih tahap development pilih menu **Start in test mode**. Setelah itu kita tekan tombol **enable**.

![Create Realtime database - atur security](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_010.png)


Selanjutnya tampil halaman database. Itu artinya database siap digunakan untuk pengembangan aplikasi project.

## Step 4 - Menambahkan fitur Create Data Mahasiswa{#step-4}
Dalam proses menambahkan data atau insert data ke database, kita perlu dua activity. Yang pertama kita akan menggunakan ```MainActivity```, kita tambahkan button dan object lainnya. Button ini kita gunakan untuk masuk ke activity yang kedua yaitu ```CreateActivity``` yang nanti akan kita gunakan untuk menambahkan data ke dalam database.

Pertama buka ```file activity_main.xml```, lalu sesuaikan kode seperti di bawah ini:

```
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    tools:context=".MainActivity">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:padding="16dp">
        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Daftar Mahasiswa"
            android:textStyle="bold"/>

        <Button
            android:id="@+id/btn_add"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Tambah" />

    </LinearLayout>

    <ListView
        android:id="@+id/lv_list"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</LinearLayout>
```

Seperti yang bisa kita lihat, di dalam layout di atas terdapat: TextView untuk tulisan title, Button add untuk menuju ke ```CreateActivity``` dan ListView untuk menampilkan data mahasiswa yang diambil dari Firebase.

Selanjutnya, buat package baru dengan nama ```model```. Caranya klik kanan pada **package utama → new → package**. Setelah package berhasil dibuat, kita buat satu file **java class** baru dengan nama ```Mahasiswa``` dan ketik kode berikut ini:

```java
package com.gungunpriatna.aplikasipengelolaandatamahasiswa.model;

import android.os.Parcel;
import android.os.Parcelable;

public class Mahasiswa implements Parcelable {
    private String id;
    private String nim;
    private String nama;
    private String photo;

    public Mahasiswa() {
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNim() {
        return nim;
    }

    public void setNim(String nim) {
        this.nim = nim;
    }

    public String getNama() {
        return nama;
    }

    public void setNama(String nama) {
        this.nama = nama;
    }

    public String getPhoto() {
        return photo;
    }

    public void setPhoto(String photo) {
        this.photo = photo;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(this.id);
        dest.writeString(this.nim);
        dest.writeString(this.nama);
        dest.writeString(this.photo);
    }

    protected Mahasiswa(Parcel in) {
        this.id = in.readString();
        this.nim = in.readString();
        this.nama = in.readString();
        this.photo = in.readString();
    }

    public static final Parcelable.Creator<Mahasiswa> CREATOR = new Parcelable.Creator<Mahasiswa>() {
        @Override
        public Mahasiswa createFromParcel(Parcel source) {
            return new Mahasiswa(source);
        }

        @Override
        public Mahasiswa[] newArray(int size) {
            return new Mahasiswa[size];
        }
    };
}

```

Selanjutnya, buat package baru dengan nama ```mahasiswa```. Caranya klik kanan pada **package utama → new → package** lalu isi nama package dengan nama ```mahasiswa```. Setelah package terbentuk, buat satu activity baru dengan nama ```CreateActivity``` dan tipenya adalah **empty activity** di dalam package ```mahasiswa```.

Di dalam file ```activity_main.xml``` terdapat object button untuk menambahkan data baru, fungsi button ini ketika diklik pengguna akan diarahkan ke activity yang baru dibuat, yaitu ```CreateActivity```. Buka file ```MainActivity``` lalu sesuaikan codenya menjadi:


```java
package com.gungunpriatna.aplikasipengelolaandatamahasiswa;

import android.content.Intent;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ListView;

import com.gungunpriatna.aplikasipengelolaandatamahasiswa.mahasiswa.CreateActivity;

public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    private ListView listView;
    private Button btnAdd;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        listView = findViewById(R.id.lv_list);
        btnAdd = findViewById(R.id.btn_add);
        btnAdd.setOnClickListener(this);
    }

    @Override
    public void onClick(View view) {
        if (view.getId() == R.id.btn_add) {
            Intent intent = new Intent(MainActivity.this, CreateActivity.class);
            startActivity(intent);
        }
    }
}


```

Kita tambahkan implementasi ```View.OnClickListener``` untuk class ```MainActivity```.

Tahap selanjutnya adalah membuat form. Buka file ```activity_create.xml``` lalu sesuaikan kode seperti di bawah ini.

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:layout_margin="16dp"
    tools:context=".mahasiswa.CreateActivity">

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Add New Record"
        android:textSize="18sp"
        android:textStyle="bold" />

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="NIM"/>

    <EditText
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:id="@+id/edt_nim"/>

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Nama"/>

    <EditText
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:id="@+id/edt_nama"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:id="@+id/btn_save"
        android:text="Save" />

</LinearLayout>
```

Setelah itu modifikasi ```CreateActivity``` untuk menambahkan logika insert data. Buka file ```CreateActivity``` lalu sesuaikan codenya.

```java
package com.gungunpriatna.aplikasipengelolaandatamahasiswa.mahasiswa;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.gungunpriatna.aplikasipengelolaandatamahasiswa.R;
import com.gungunpriatna.aplikasipengelolaandatamahasiswa.model.Mahasiswa;

public class CreateActivity extends AppCompatActivity implements View.OnClickListener {

    private EditText edtNim, edtNama;
    private Button btnSave;

    private Mahasiswa mahasiswa;

    DatabaseReference mDatabase;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_create);

        mDatabase = FirebaseDatabase.getInstance().getReference();

        edtNama = findViewById(R.id.edt_nama);
        edtNim = findViewById(R.id.edt_nim);
        btnSave = findViewById(R.id.btn_save);

        btnSave.setOnClickListener(this);

        mahasiswa = new Mahasiswa();
    }

    @Override
    public void onClick(View view) {

        if (view.getId() == R.id.btn_save) {
            saveMahasiswa();
        }

    }

    private void saveMahasiswa()
    {
        String nama = edtNama.getText().toString().trim();
        String nim = edtNim.getText().toString().trim();

        boolean isEmptyFields = false;

        if (TextUtils.isEmpty(nama)) {
            isEmptyFields = true;
            edtNama.setError("Field ini tidak boleh kosong");
        }

        if (TextUtils.isEmpty(nim)) {
            isEmptyFields = true;
            edtNim.setError("Field ini tidak boleh kosong");
        }

        if (! isEmptyFields) {

            Toast.makeText(CreateActivity.this, "Saving Data...", Toast.LENGTH_SHORT).show();

            DatabaseReference dbMahasiswa = mDatabase.child("mahasiswa");

            String id = dbMahasiswa.push().getKey();
            mahasiswa.setId(id);
            mahasiswa.setNim(nim);
            mahasiswa.setNama(nama);
            mahasiswa.setPhoto("");

            //insert data
            dbMahasiswa.child(id).setValue(mahasiswa);

            finish();

        }
    }
}

```

Supaya aplikasi dapat mengakses internet, kita harus mengatur permission di dalam file ```AndroidManifest.xml```. Buka file ```AndroidManifest.xml```, lalu tambahkan kode:

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
```

Sehingga keseluruhan file ```AndroidManifest.xml``` menjadi seperti baris kode di bawah ini.

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.gungunpriatna.aplikasipengelolaandatamahasiswa">

    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/AppTheme">
        <activity android:name=".mahasiswa.CreateActivity" />
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />

                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```


## Step 5 - Menambahkan fitur menampilkan Data Mahasiswa{#step-5}
Selanjutnya kita akan menampilkan data mahasiswa dari firebase ke dalam ListView yang sebelumnya sudah kita buat di dalam layout ```activity_main.xml```.

Buat file ```item_mahasiswa.xml``` untuk tampilan list dengan cara klik
kanan pada **direktori layout → new → layout resource file** dan kemudian beri nama
```item_mahasiswa.xml```. Sesuaikan kodenya menjadi seperti berikut:

```xml
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:padding="16dp">

    <ImageView
        android:id="@+id/img_photo"
        android:layout_width="50dp"
        android:layout_height="50dp"
        android:scaleType="fitXY"
        app:srcCompat="@mipmap/ic_launcher_round"
        />

    <TextView
        android:id="@+id/txt_nim"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="26dp"
        android:layout_toEndOf="@+id/img_photo"
        android:text="NIM"
        android:textSize="18sp"
        android:textStyle="bold" />
    <TextView
        android:id="@+id/txt_nama"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="26dp"
        android:layout_marginTop="10dp"
        android:layout_below="@+id/txt_nim"
        android:layout_toEndOf="@+id/img_photo"
        android:text="nama"
        android:ellipsize="end"
        android:textSize="18sp" />
</RelativeLayout>
```

Selanjutnya, buat package baru dengan nama ```adapter```. Di dalamnya buat sebuah kelas baru dengan nama ```MahasiswaAdapter```. Lalu ketik kode di bawah ini:

```java
package com.gungunpriatna.aplikasipengelolaandatamahasiswa.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

import com.gungunpriatna.aplikasipengelolaandatamahasiswa.R;
import com.gungunpriatna.aplikasipengelolaandatamahasiswa.model.Mahasiswa;

import java.util.ArrayList;

public class MahasiswaAdapter extends BaseAdapter {
    private Context context;
    private ArrayList<Mahasiswa> mahasiswaList = new ArrayList<>();

    public void setMahasiswaList(ArrayList<Mahasiswa> mahasiswaList) {
        this.mahasiswaList = mahasiswaList;
    }

    public MahasiswaAdapter(Context context) {
        this.context = context;
    }

    @Override
    public int getCount() {
        return mahasiswaList.size();
    }

    @Override
    public Object getItem(int i) {
        return mahasiswaList.get(i);
    }

    @Override
    public long getItemId(int i) {
        return i;
    }

    @Override
    public View getView(int i, View view, ViewGroup viewGroup) {
        View itemView = view;

        if (itemView == null) {
            itemView = LayoutInflater.from(context)
                    .inflate(R.layout.item_mahasiswa, viewGroup, false);
        }

        ViewHolder viewHolder = new ViewHolder(itemView);

        Mahasiswa mahasiswa = (Mahasiswa) getItem(i);
        viewHolder.bind(mahasiswa);
        return itemView;
    }

    private class ViewHolder {
        private TextView txtNim, txtName;

        ViewHolder(View view) {
            txtName = view.findViewById(R.id.txt_nama);
            txtNim = view.findViewById(R.id.txt_nim);
        }

        void bind(Mahasiswa mahasiswa) {
            txtName.setText(mahasiswa.getNama());
            txtNim.setText(mahasiswa.getNim());
        }
    }
}

```

Selanjutnya kita buka file ```MainActivity```. Lalu kita modifikasi menjadi seperti kode di bawah ini:
```java

public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    private ListView listView;
    private Button btnAdd;

    //tambahkan kode ini
    private MahasiswaAdapter adapter;
    private ArrayList<Mahasiswa> mahasiswaList;
    DatabaseReference dbMahasiswa;

    ...
}
```

Pada bagian method ```onCreate()``` kita modifikasi kode menjadi:
```java
public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    ...

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        dbMahasiswa = FirebaseDatabase.getInstance().getReference("mahasiswa");

        listView = findViewById(R.id.lv_list);
        btnAdd = findViewById(R.id.btn_add);
        btnAdd.setOnClickListener(this);

        //list mahasiswa
        mahasiswaList = new ArrayList<>();

    }

}
```

Untuk mengambil data mahasiswa dari database, kita perlu menambahkan ```ValueEventListener``` ke object database reference di dalam method ```onStart()```.

```java
public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    ...

    @Override
    protected void onStart() {
        super.onStart();

        dbMahasiswa.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                mahasiswaList.clear();

                for (DataSnapshot mahasiswaSnapshot : dataSnapshot.getChildren()) {
                    Mahasiswa mahasiswa = mahasiswaSnapshot.getValue(Mahasiswa.class);
                    mahasiswaList.add(mahasiswa);
                }

                MahasiswaAdapter adapter = new MahasiswaAdapter(MainActivity.this);
                adapter.setMahasiswaList(mahasiswaList);
                listView.setAdapter(adapter);
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
                Toast.makeText(MainActivity.this, "Terjadi kesalahan.", Toast.LENGTH_SHORT).show();
            }
        });
    }


}

```

Sehingga kode ```MainActivity``` menjadi seperti berikut ini:

```java

public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    private ListView listView;
    private MahasiswaAdapter adapter;
    private ArrayList<Mahasiswa> mahasiswaList;
    private Button btnAdd;

    DatabaseReference dbMahasiswa;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        dbMahasiswa = FirebaseDatabase.getInstance().getReference("mahasiswa");

        listView = findViewById(R.id.lv_list);
        btnAdd = findViewById(R.id.btn_add);
        btnAdd.setOnClickListener(this);

        //list mahasiswa
        mahasiswaList = new ArrayList<>();
    }

    @Override
    protected void onStart() {
        super.onStart();

        dbMahasiswa.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                mahasiswaList.clear();

                for (DataSnapshot mahasiswaSnapshot : dataSnapshot.getChildren()) {
                    Mahasiswa mahasiswa = mahasiswaSnapshot.getValue(Mahasiswa.class);
                    mahasiswaList.add(mahasiswa);
                }

                MahasiswaAdapter adapter = new MahasiswaAdapter(MainActivity.this);
                adapter.setMahasiswaList(mahasiswaList);
                listView.setAdapter(adapter);
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
                Toast.makeText(MainActivity.this, "Terjadi kesalahan.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onClick(View view) {
        if (view.getId() == R.id.btn_add) {
            Intent intent = new Intent(MainActivity.this, CreateActivity.class);
            startActivity(intent);
        }
    }
}


```


## Step 6 - Menambahkan fitur Update Data Mahasiswa{#step-6}
Alur untuk memperbaharui data adalah dengan cara menekan item untuk masing-masing data mahasiswa, kemudian diarahkan ke activity baru untuk menampilkan form update data. Selain untuk update, di dalam activity ini akan ada menu untuk hapus data dan juga kembali ke ```MainActivity```. Berdasarkan alurnya, selanjutnya kita perlu membuat activity baru dan juga beberapa file lainnya.

Buat satu activity baru dengan nama ```UpdateActivity``` dan tipenya adalah **empty activity** di dalam package ```mahasiswa```. Setelah activity selesai dibuat, buka file ```activity_update.xml``` dan sesuaikan menjadi seperti kode  berikut ini:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:layout_margin="16dp"
    tools:context=".mahasiswa.UpdateActivity">

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Edit Record"
        android:textSize="18sp"
        android:textStyle="bold" />

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="NIM"
        />
    <EditText
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:id="@+id/edt_edit_nim"/>

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Nama"/>
    <EditText
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:id="@+id/edt_edit_nama"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:id="@+id/btn_update"
        android:text="Update" />

</LinearLayout>
```

Selanjutnya tambahkan resource directory baru dengan nama ```menu``` pada res directory, dengan cara klik kanan pada folder **res -> new -> Android Resource Directory** -> ubah resource type menjadi menu. Lalu buatlah berkas xml (Menu Resource File) dengan nama ```menu_form``` di dalam direktori ```menu``` yang baru saja dibuat.

![Membuat Menu Resource File](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_011.png)


Kemudian ketik kode berikut:

```xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">

    <item android:id="@+id/action_delete"
        android:icon="@drawable/ic_clear"
        android:title="Delete"
        app:showAsAction="always"/>
</menu>
```

Di dalam baris kode di atas terdapat ```drawable/ic_clear```, itu artinya kita buat file di dalam directory drawable dengan cara klik kanan pada folder **drawable -> new -> Vector Asset** -> lalu pilih clip art dengan icon X dan beri nama ```ic_clear``` seperti yang terlihat pada gambar berikut.

![Membuat vector asset](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_012.png)


Lalu selanjutnya klik tombol next dan finish.

Selanjutnya buka file ```UpdateActivity```, kita tambahkan implement ```View.OnClickListener``` pada class ```UpdateActivity``` dan tambahkan juga implementasi method ```onClick()```. Lalu selanjutnya kita deklarasikan beberapa variable, seperti kode berikut:

```java
public class UpdateActivity extends AppCompatActivity implements View.OnClickListener {

    private EditText edtNim, edtNama;
    private Button btnUpdate;

    public static final String EXTRA_MAHASISWA = "extra_mahasiswa";
    public final int ALERT_DIALOG_CLOSE = 10;
    public final int ALERT_DIALOG_DELETE = 20;

    private Mahasiswa mahasiswa;
    private String mahasiswaId;

    DatabaseReference mDatabase;

    ...

    
}
```

Selanjutnya modifikasi method ```onCreate()``` di dalam class ```UpdateActivity``` menjadi:

```java
public class UpdateActivity extends AppCompatActivity implements View.OnClickListener {

    ...

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_update);

        mDatabase = FirebaseDatabase.getInstance().getReference();

        edtNama = findViewById(R.id.edt_edit_nama);
        edtNim = findViewById(R.id.edt_edit_nim);
        btnUpdate = findViewById(R.id.btn_update);
        btnUpdate.setOnClickListener(this);

        mahasiswa = getIntent().getParcelableExtra(EXTRA_MAHASISWA);

        if (mahasiswa != null) {
            mahasiswaId = mahasiswa.getId();
        } else {
            mahasiswa = new Mahasiswa();
        }

        if (mahasiswa != null) {
            edtNim.setText(mahasiswa.getNim());
            edtNama.setText(mahasiswa.getNama());

        }

        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle("Edit Data");
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

    }

    ...

}
```

Lalu di dalam method ```onClick()``` tambahkan code untuk proses update data.

```java
public class UpdateActivity extends AppCompatActivity implements View.OnClickListener {

   ...

    @Override
    public void onClick(View view) {
        if (view.getId() == R.id.btn_update) {
            updateMahasiswa();
        }

    }

    private void updateMahasiswa() {
        String nama = edtNama.getText().toString().trim();
        String nim = edtNim.getText().toString().trim();

        boolean isEmptyFields = false;

        if (TextUtils.isEmpty(nama)) {
            isEmptyFields = true;
            edtNama.setError("Field ini tidak boleh kosong");
        }

        if (TextUtils.isEmpty(nim)) {
            isEmptyFields = true;
            edtNim.setError("Field ini tidak boleh kosong");
        }

        if (! isEmptyFields) {

            Toast.makeText(UpdateActivity.this, "Updating Data...", Toast.LENGTH_SHORT).show();

            mahasiswa.setNim(nim);
            mahasiswa.setNama(nama);
            mahasiswa.setPhoto("");

            DatabaseReference dbMahasiswa = mDatabase.child("mahasiswa");

            //update data
            dbMahasiswa.child(mahasiswaId).setValue(mahasiswa);

            finish();

        }
    }

    ...

}

```

Selanjutnya kita tambahkan beberapa method di dalam class ```UpdateActivity``` untuk kembali ke halaman selanjutnya dan juga method untuk menampilkan dialog untuk hapus data.

```java
public class UpdateActivity extends AppCompatActivity implements View.OnClickListener {

   ...

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_form, menu);

        return super.onCreateOptionsMenu(menu);
    }

    //pilih menu
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_delete:
                //showAlertDialog(ALERT_DIALOG_DELETE);
                break;
            case android.R.id.home:
                showAlertDialog(ALERT_DIALOG_CLOSE);
                break;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onBackPressed() {
        showAlertDialog(ALERT_DIALOG_CLOSE);
    }

    private void showAlertDialog(int type) {
        final boolean isDialogClose = type == ALERT_DIALOG_CLOSE;
        String dialogTitle, dialogMessage;

        if (isDialogClose) {
            dialogTitle = "Batal";
            dialogMessage = "Apakah anda ingin membatalkan perubahan pada form?";
        } else {
            dialogTitle = "Hapus Data";
            dialogMessage = "Apakah anda yakin ingin menghapus item ini?";
        }

        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(this);

        alertDialogBuilder.setTitle(dialogTitle);
        alertDialogBuilder.setMessage(dialogMessage)
                .setCancelable(false)
                .setPositiveButton("Ya", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {

                        if (isDialogClose) {
                            finish();
                        } else {
                            //hapus data
                        }
                    }
                }).setNegativeButton("Tidak", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                dialogInterface.cancel();
            }
        });

        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.show();
    }
}
```

Sehingga kode keseluruhan untuk ```UpdateActivity``` adalah sebagai berikut:

```java
public class UpdateActivity extends AppCompatActivity implements View.OnClickListener {

    private EditText edtNim, edtNama;
    private Button btnUpdate;

    public static final String EXTRA_MAHASISWA = "extra_mahasiswa";
    public final int ALERT_DIALOG_CLOSE = 10;
    public final int ALERT_DIALOG_DELETE = 20;

    private Mahasiswa mahasiswa;
    private String mahasiswaId;

    DatabaseReference mDatabase;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_update);

        mDatabase = FirebaseDatabase.getInstance().getReference();

        edtNama = findViewById(R.id.edt_edit_nama);
        edtNim = findViewById(R.id.edt_edit_nim);
        btnUpdate = findViewById(R.id.btn_update);
        btnUpdate.setOnClickListener(this);

        mahasiswa = getIntent().getParcelableExtra(EXTRA_MAHASISWA);

        if (mahasiswa != null) {
            mahasiswaId = mahasiswa.getId();
        } else {
            mahasiswa = new Mahasiswa();
        }

        if (mahasiswa != null) {
            edtNim.setText(mahasiswa.getNim());
            edtNama.setText(mahasiswa.getNama());

        }

        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle("Edit Data");
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

    }

    @Override
    public void onClick(View view) {
        if (view.getId() == R.id.btn_update) {
            updateMahasiswa();
        }

    }

    public void updateMahasiswa() {
        String nama = edtNama.getText().toString().trim();
        String nim = edtNim.getText().toString().trim();

        boolean isEmptyFields = false;

        if (TextUtils.isEmpty(nama)) {
            isEmptyFields = true;
            edtNama.setError("Field ini tidak boleh kosong");
        }

        if (TextUtils.isEmpty(nim)) {
            isEmptyFields = true;
            edtNim.setError("Field ini tidak boleh kosong");
        }

        if (! isEmptyFields) {

            Toast.makeText(UpdateActivity.this, "Updating Data...", Toast.LENGTH_SHORT).show();

            mahasiswa.setNim(nim);
            mahasiswa.setNama(nama);
            mahasiswa.setPhoto("");

            DatabaseReference dbMahasiswa = mDatabase.child("mahasiswa");

            //update data
            dbMahasiswa.child(mahasiswaId).setValue(mahasiswa);

            finish();

        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_form, menu);

        return super.onCreateOptionsMenu(menu);
    }

    //pilih menu
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_delete:
                //showAlertDialog(ALERT_DIALOG_DELETE);
                break;
            case android.R.id.home:
                showAlertDialog(ALERT_DIALOG_CLOSE);
                break;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onBackPressed() {
        showAlertDialog(ALERT_DIALOG_CLOSE);
    }

    private void showAlertDialog(int type) {
        final boolean isDialogClose = type == ALERT_DIALOG_CLOSE;
        String dialogTitle, dialogMessage;

        if (isDialogClose) {
            dialogTitle = "Batal";
            dialogMessage = "Apakah anda ingin membatalkan perubahan pada form";
        } else {
            dialogTitle = "Hapus Data";
            dialogMessage = "Apakah anda yakin ingin menghapus item ini";
        }

        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(this);

        alertDialogBuilder.setTitle(dialogTitle);
        alertDialogBuilder.setMessage(dialogMessage)
                .setCancelable(false)
                .setPositiveButton("Ya", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {

                        if (isDialogClose) {
                            finish();
                        } else {
                            //hapus data
                        }
                    }
                }).setNegativeButton("Tidak", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                dialogInterface.cancel();
            }
        });

        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.show();
    }
}
```

Selanjutnya kita tambahkan sebuah *listener* yang bertugas membuat item di dalam listview menjadi bisa diklik dan mengarahkan ke activity untuk proses update data. Buka file ```MainActivity``` lalu tambahkan kode berikut di dalam method ```onCreate()```:

```java
@Override
    protected void onCreate(Bundle savedInstanceState) {
        
        ...

        //kode yang ditambahkan
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                Intent intent = new Intent(MainActivity.this, UpdateActivity.class);
                intent.putExtra(UpdateActivity.EXTRA_MAHASISWA, mahasiswaList.get(i));

                startActivity(intent);
            }
        });
    }
```

Sehingga kode keseluruhan ```MainActivity``` menjadi:

```java
public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    private ListView listView;
    private MahasiswaAdapter adapter;
    private ArrayList<Mahasiswa> mahasiswaList;
    private Button btnAdd;

    DatabaseReference dbMahasiswa;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        dbMahasiswa = FirebaseDatabase.getInstance().getReference("mahasiswa");

        listView = findViewById(R.id.lv_list);
        btnAdd = findViewById(R.id.btn_add);
        btnAdd.setOnClickListener(this);

        //list mahasiswa
        mahasiswaList = new ArrayList<>();
        
        //kode yang ditambahkan
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                Intent intent = new Intent(MainActivity.this, UpdateActivity.class);
                intent.putExtra(UpdateActivity.EXTRA_MAHASISWA, mahasiswaList.get(i));

                startActivity(intent);
            }
        });
    }

    @Override
    protected void onStart() {
        super.onStart();

        dbMahasiswa.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                mahasiswaList.clear();

                for (DataSnapshot mahasiswaSnapshot : dataSnapshot.getChildren()) {
                    Mahasiswa mahasiswa = mahasiswaSnapshot.getValue(Mahasiswa.class);
                    mahasiswaList.add(mahasiswa);
                }

                MahasiswaAdapter adapter = new MahasiswaAdapter(MainActivity.this);
                adapter.setMahasiswaList(mahasiswaList);
                listView.setAdapter(adapter);
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
                Toast.makeText(MainActivity.this, "Terjadi kesalahan.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onClick(View view) {
        if (view.getId() == R.id.btn_add) {
            Intent intent = new Intent(MainActivity.this, CreateActivity.class);
            startActivity(intent);
        }
    }
}

```


## Step 7 - Menambahkan fitur Delete Data Mahasiswa{#step-7}
Fitur untuk menghapus data mahasiswa dapat diakses ketika masuk ke form update. Pengguna dapat menghapus dengan menekan tombol X pada menu yang sudah dibuat di langkah sebelumnya.

Buka kembali file ```UpdateActivity```, lalu hapus komentar pada method ```onOptionsItemSelected()``` untuk menampilkan dialog hapus data. 
```java
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_delete:
                //menampilkan dialog
                showAlertDialog(ALERT_DIALOG_DELETE);
                break;
            case android.R.id.home:
                showAlertDialog(ALERT_DIALOG_CLOSE);
                break;
        }

        return super.onOptionsItemSelected(item);
    }
```

Selanjutnya kita modifikasi method ```showAlertDialog()``` untuk menambahkan logika untuk menghapus data.

 Temukan code berikut di dalam method ```showAlertDialog()```:
```java
if (isDialogClose) {
  finish();
} else {
    //hapus data
}
```

Lalu tambahkan code untuk menghapus data setelah komentar "//hapus data":

```java
if (isDialogClose) {
  finish();
} else {
    //hapus data
    DatabaseReference dbMahasiswa =
            mDatabase.child("mahasiswa").child(mahasiswaId);

    dbMahasiswa.removeValue();

    Toast.makeText(UpdateActivity.this, "Deleting data...",
            Toast.LENGTH_SHORT).show();
    finish();
}
```

Sehingga keseluruhan code untuk method ```showAlertDialog()``` menjadi seperti kode di bawah ini:

```java
private void showAlertDialog(int type) {
        final boolean isDialogClose = type == ALERT_DIALOG_CLOSE;
        String dialogTitle, dialogMessage;

        if (isDialogClose) {
            dialogTitle = "Batal";
            dialogMessage = "Apakah anda ingin membatalkan perubahan pada form";
        } else {
            dialogTitle = "Hapus Data";
            dialogMessage = "Apakah anda yakin ingin menghapus item ini";
        }

        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(this);

        alertDialogBuilder.setTitle(dialogTitle);
        alertDialogBuilder.setMessage(dialogMessage)
                .setCancelable(false)
                .setPositiveButton("Ya", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {

                        if (isDialogClose) {
                            finish();
                        } else {
                            //hapus data
                            DatabaseReference dbMahasiswa =
                                    mDatabase.child("mahasiswa").child(mahasiswaId);

                            dbMahasiswa.removeValue();

                            Toast.makeText(UpdateActivity.this, "Deleting data...",
                                    Toast.LENGTH_SHORT).show();
                            finish();
                        }
                    }
                }).setNegativeButton("Tidak", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                dialogInterface.cancel();
            }
        });

        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.show();
    }

```


## Step 8 - Uji Coba Project{#step-8}
Pada tahapan ini kita akan coba project yang baru saja kita coding. Sekarang kita coba `run` project kita. Ketika pertama kali project kita `run`, maka akan tampil seperti gambar di bawah ini:

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_013.png)

Tekan tombol ```tambah``` untuk menambahkan data baru. Kita coba isi NIM dan Nama lalu tekan tombol ```save```.

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_014.png)


Setelah data berhasil disimpan, aplikasi akan menampilkan kembali halaman daftar mahasiswa dengan data yang sudah berhasil tersimpan, seperti yang terlihat pada gambar di bawah ini:

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_015.png)

Untuk memperbaharui data, tekan item pada daftar mahasiswa, misalkan tekan item dengan nim '12345' dan nama 'tes insert', maka aplikasi akan menampilkan form untuk memperbaharui data.

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_016.png)


Untuk mencoba memperbaharui data, ubah data, misalkan namanya diubah menjadi 'tes update' lalu tekan tombol update.

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_017.png)

Ketika berhasil update data, aplikasi akan menampilkan kembali halaman daftar mahasiswa dengan data yang sudah diperbaharui.

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_018.png)

Untuk menghapus data, coba tekan kembali item pada daftar mahasiswa, misalkan item dengan nim '12345' dan nama 'tes update'. Aplikasi kembali menampilkan form update data. Tekan tombol X untuk menampilkan dialog hapus data.

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_019.png)


Setelah dialog muncul, pilih opsi 'Ya' untuk menghapus data.

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_020.png)


Selanjutnya ketika data berhasil dihapus, aplikasi kembali menampilkan daftar mahasiswa.

![Uji coba project](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/b379e801/android/crud-firebase/Selection_021.png)


## Penutup{#penutup}
Di tutorial ini kita sudah membahas tentang Realtime Database Firebase, lalu kita juga sudah coba develop aplikasi berdasarkan studi kasus untuk operasi CRUD Realtime Database Firebase. Semoga tutorial ini dapat memudahkanmu untuk memahami tentang realtime database firebase dan setiap jengkal baris kodenya.

Terima kasih sudah menyimak tutorial ini. Sampai jumpai di edisi tutorial berikutnya. Semoga bermanfaat! Selamat berkarya! ^^

## Referensi{#referensi}

[^1]: Official Documentation Firebase Database @ [https://firebase.google.com/docs/database](https://firebase.google.com/docs/database) 
[^2]: Dokumentasi Setup Firebase @ [https://firebase.google.com/docs/android/setup/](https://firebase.google.com/docs/android/setup/)

### Note{#note}

Tutorial Android ini berisi tentang tutorial pengembangan aplikasi android menggunakan android studio. Selain untuk mengikat ilmu, tutorial ini juga dibuat agar saya dan teman-teman bisa sama-sama belajar.

Tulisan ini dipublikasikan dibawah lisensi [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/)