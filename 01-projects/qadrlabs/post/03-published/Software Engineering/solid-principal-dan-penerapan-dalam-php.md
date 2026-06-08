---
title: "SOLID Principles dan Penerapan dalam PHP"
slug: "solid-principal-dan-penerapan-dalam-php"
category: "Software Engineering"
date: "2017-05-26"
status: "published"
---

Hi, there! Selamat berakhir pekan! Bagaimana akhir pekanmu? Akhir pekanku di rumah dan masih punya banyak deadline. Tapi, di tengah tumpukkan deadline itu, saya tiba-tiba ingin menulis sesuatu tentang menulis dan menambah edisi serial Code-writerTalk ini. Setelah beberapa bulan hiatus dari dunia blogging, akhirnya saya bisa menulis edisi terbaru untuk serial Code-writerTalk, yeay! Dan pada edisi kali ini saya akan menuliskan kembali hasil diskusi beberapa waktu lalu dengan kang Arie Deha tentang dasar-dasar **SOLID Principles** dan penerapan dalam PHP. Wah, apa itu SOLID Principles? Yuk, kita bahas!

## Writing code is easy, writing GOOD code is hard!{#writing-code-is-easy}
Kenapa sih sampai perlu ada "metode" dalam cara menulis sebuah program?

Dulu, duluuu banget.. membuat program itu susah, ga gampang untuk membuat sebuah program. Apalagi kalau sudah masuk ke urusan logic, bahkan banyak teman-teman saya yang kuliah di bidang IT menyerah.

Tapi sekarang?

Banyak sekali bertebaran buku-buku ataupun ebooks soal pemrograman. Misalnya, buku "Belajar xxxx dalam n jam". Buku-buku seperti itu banyak dijual di mana-mana or bisa didonlot, kalau ketemu keywordnya di google.

Jadi, sekarang membuat program itu gampang. Semua orang dapat membuat program, tinggal baca buku sedikit, bisa langsung membuat program dan menjalankan programnya. Ada error, googling dan langsung ketemu jawabannya. Banyak pertanyaan-pertanyaan atau masalah-masalah yang kita hadapi yang sudah ditanyakan oleh orang lain, dan kita bisa lihat pemecahan masalahnya. Situs-situs seperti stackoverflow itu sangat membangtu dalam hal ini.

Sekarang paradigma sudah agak berubah, dengan adanya banyak source dimana-mana. "Menulis program itu mudah, tapi menulis program YANG BAIK itu susah....".

Seperti apa sih menulis program yang baik itu?

Berdasarkan berbagai sumber, kira-kira program yang baik itu:

1. **Testable**, program dapat ditest / melalui proses test, dan bisa melalui postive/negative test dengan baik,
2. **Refactorable**, mudah kalau ada kebutuhan untuk refactor / memperbaiki flow, menyelipkan fitur baru atau tambahan, dan lain-lain,
3. **Easy to work with**, Kalau ada masalah, dapat dengan mudah pin-point masalahnya di mana, kalau ingin menambahkan fitur kita ga ngerombak yang sudah ada,
4. **Easy to maintain**, mudah untuk proses maintain

Nah, sekarang.. kapan kita membutuhkan untuk dapat membuat program yang baik?

Pada saat program kita kecil, user yang pakai juga sedikit, developernya sedikit, bisa saja kita membuat program seenaknya, entar kalau ada apa-apa yaa tinggal tanya yang buat. Tapi pada saat program kita mulai berkembang, fitur-fitur baru mulai ditambahkan, user yang pakai semakin banyak, perlu efisiensi dalam mengorganisis program, developer semakin banyak, apakah kita bisa membuat program seenaknya lagi?

Di sini **S.O.L.I.D** berperan sebagai landasan dalam proses development program yang lebih baik. Kalau sebelumnya seenaknya dalam membuat program, sekarang sesuai dengan kebutuhan, kita harus mulai mendisiplinkan diri dalam membuat program.

Oiya, kalau kamu bertanya, kenapa programming menggunakan bahasa pemrograman PHP pun sebaiknya perlu menerapkan **SOLID Principle** ini? Soalnya, karena PHP itu mudah dipelajari, lebih gampang untuk kita "salah" dalam cara membuat program daripada "benar" nya. Sekali lagi, salah dan benar itu bukan hakiki yaa. Itu kebenaran dari cara pandang masing-masing individu.

## Apa itu S.O.L.I.D ?{#apa-itu-solid}
Well, S.O.L.I.D adalah singkatan. Tepatnya adalah singkatan dari beberapa principle yang membuat cara kita membuat program itu menjadi lebih baik, yaitu:

- (S)ingle Responsibility Principle,
- (O)pen Close Principle,
- (L)iskov Substitution Principle,
- (I)nterface Segregation Principle,
- (D)ependency Inversion Principle

Nah, kita akan membahas satu per satu mengenai principles ini. Tidak terlalu mendalam, tapi sebagai pengetahuan saja.

## Single Responsibility Principle{#srp}
Apa sih maksudnya? Intinya, setiap objek harus punya dan hanya punya SATU tujuan aja.

Untuk programmer yang masih baru, kadang prinsip ini dilanggar dengan mudah. Di sebuah literatur online pernah menyebutkan, cara untuk mengetahui bahwa sebuah function atau method itu tidak efisien adalah dengan cara, Buka di IDE, lalu buat bagian pertama function atau method ada di baris pertama di layar, dan lihat. Apabila kita perlu "page down" untuk melihat bagian bawah atau penutup function atau method tadi, itu tandanya function sudah terlalu panjang. Pastinya bisa dibuat lebih simpel atau dipecah menjadi beberapa function yang lebih kecil. Ini belum tentu benar, tapi di satu sisi, ini *make sense* banget, soalnya banyak function yang sangat panjang ternyata bisa dipecah sampai tinggal beberapa baris saja.

Apa sih gunanya kalau function atau method dipecah-pecah?
1. Test nya gampang
2. Kalau terjadi error, gampang nemunya
3. mau ada ganti proses gampang
4. mau ada fitur sama tapi beda (misalnya) engine, gampang juga update nya...

Selama parameter input dan result output nya sama...

Responsibility, di dalam deskripsinya Robert Martin, adalah "Alasan untuk berubah"... kalau kita melihat sebuah class dan kepikiran beberapa cara utk mengubahnya, ada kemungkinan class itu punya lebih dari 1 responsibility.

contoh:
```php
class User {  

    public function getName() {}   

    public function getEmail() {}   

    public function find($id) {}  

    public function save() {}   

}  

```

Class User ini bisa memiliki 2 responsibility, yaitu mengurus soal bagaimana "user" ini menampilkan data, dan mengurus data berinteraksi dengan database.

Ini bisa dipecah menjadi:

```php  
class User {  
   public function getName() {}   
   public function getEmail() {}   
}  

class UserRepository {  
    public function find($id) {}  
    public function save() {}   
}  

```

Jadi untuk urusan ke db nya ada di ```UserRepository``` dan untuk ditampilkan sebagai result ada di class ```User```.

kalau dipecah-pecah sesuai kebutuhannya, boleh jadi diakhir nanti kita punya banyak class untuk 1 entity user.

Lalu, kenapa sih lebih baik dipecah-dipecah? Kenapa harus single responsibility?

Karena semakin banyak responsibility dalam suatu object/class, maka akan membuat responsibility-responsibility tadi menjadi *closed/tightly coupled*. Akhirnya kalau ada update atau penambahan fitur or lainnya, maka akan semakin sulit dan dependency terhadap responsibility tersebut jadi semakin tinggi.

## Open/Close Principle{#ocp}
Artinya, sebuah class harus terbuka (open) untuk di extends, tapi tertutup (close) untuk modifikasi.

Kalau diterjemahkan secara harafiah, developer yang akan melanjutkan development dikemudian hari, harus tidak dapat mengubah system / class yang sudah ada atau berjalan, tapi juga, dia harus dapat dengan mudah meng-extend class itu.

Keuntungannya dari **Open Close Principle** ini adalah semakin sedikit kemungkinan modifikasi yang dilakukan terhadap source utama, sehingga kemungkinan terjadinya "Dulu parameternya A aja sudah jalan, sekarang harus A dan B" dan "Karena ada fitur X ditambahkan, jadi hasil nya berubah dari {"a":[1,2,3]} jadi {"ax":{"data":[1,2,3], "name":"abc"}} "

Kalau mau ubah, yaa extend dari yg awal, sehingga tidak break yang sebelumnya. Jadi class/fungsi yang dependency kesana, tidak break karena perubahan di source yg awalnya.

## Liskov Substitution Principle{#lsp}
**Liskov Substitution Principle** (LSP, biar gampang), berkata, "Object yg memiliki interface yang sama, harus dapat di-"pertukar"-kan (interchangeable), tanpa mempengaruhi cara / behaviour sebuah program berjalan".

Maksudnya, interface di PHP membuat struktur sebuah class sehingga bisa diimplementasi dengan mudah di class/program lain yang membutuhkan.

Supaya mudah dipahami, kita pakai contoh saja:

```php

interface DatamineInterface {  
    public function save($table, $data) {}  
    public function retrieve($params) {}  
}  

class DatabaseMine implements DatamineInterface {  

    public function save($table, $data) {  
        $this->db->table($field)->save($data);  
    }  
		
    public function retrieve($params) {  
        return $this->db->where($params)->get();  
    }  
}  

class MongoMine implements DatamineInterface {  

    public function save($table, $data) {  
        $this->mongodb->document($table)->save($data);  
    }  
		
    public function retrieve($params) {  
        return $this->mongodb->key($params)->get();  
    }  
}  

class MemcacheMine implements DatamineInterface {  

    public function save($table, $data) {  
        $this->memcache->set($table, $data);  
    }  
		
    public function retrieve($params) {  
        return $this->memcache->get($params);  
    }  
}  

class FileMine implements DatamineInterface {  

    public function save($table, $data) {  
        file_put_contents(md5($table), $data);  
    }  
		
    public function retrieve($params) {  
        return file_get_contents(md5(serialize($params));  
    }  
}  
```

=> **Catatan**, ini cuma contoh yaa... saya ga sempet bikin dan cari source yang "paten".

Sorry kalau panjang, yang ada di otak langsung ditulis...

Implementasi nya bisa:
```php
 class accessData {  
 
   public function doSave(DatamineInterface $miner) {  
     $miner->save('blabla', ['abc'=>123]);  
   }  
	 
   public function getData(DatamineInterface $miner) {  
     return $miner->retrieve('blabla', ['abc'=>123]);  
   }  
 }  

```

bisa digunakan dengan:
```php

$dt = new accessData;  
$dt->doSave(new DatabaseMine);  
$dt->doSave(new MemcacheMine);  
$resultMemcache = $dt->getData(new MemcacheMine);  
$resultMongo = $dt->getData(new MongoMine);  

```

Sekarang, kenapa pakai LSP? Soalnya dengan menggunakan LSP, kita lebih mudah untuk melalukan *refactoring* code kita. Misalnya kita mau ganti data source, kita ga perlu kuatir dengan parameter atau dengan nama method yg berbeda yang bisa mengubah source code kita ....

## Interface Segregation Principle{#isp}
Interface itu akan men-dikte object yang kita buat, "harus punya method-method ini".

Tapi kadang kita maksain semua method yg kepikiran sama kita dimasukin semua ke interface, atau (kalau anda cukup males untuk membuat interface diawal) interface dibuat sesudah method-method di dalam class yg implemen interface nya ada.

Nahhh ISP (interface segregation principle) itu gunanya adalah utk "memecah" interface tadi menjadi beberapa interface lagi, jadi yang dibutuhkan saja yg akan kita pakai.

Misalnya:

(sekali lagi, ini code yg muncul dipikiran saya saat ini yaa.. code nya di tulis "as is" sama isi otak saya)

```php

interface ScopeInterface {  
    public function readScope($key) {};  
    public function setScope($key, $val) {};  
}  

interface ClientInterface {  
    public function readClient($key) {};  
    public function setClient($key, $val) {};  
}  

interface TokenInterface {  
    public function readToken($key) {};  
    public function setToken($key) {};  
}  

interface OauthAccessInterface extends ScopeInterface, ClientInterface, TokenInterface {}  

```

Code di atas pernah saya implementasi di access token library, tp sudah rada lama ga disentuh, moga-moga ga typo...

Jadi dari contoh di atas, kalau saya mau buat class Client, saya ga usah implement yang diluar dari entity Client, tapi klo di OauthAccess, saya akan ambil (implemen) dari semua entity-entity yang dibutuhkan utk membuat access token.

## Dependency Inversion Principle{#dip}
DIP (Dependency Inversion Principle) menyatakan bahwa:
1. High Level Module, harus tidak boleh bergantung ke Low Level Module, kedua nya harus bergantung kepada Object Abstract
2. Object Abstract harus tidak bergantung pada Detail, tapi Detail harus bergantung pada Object Abstract

.....

rada susah dimengerti yaa....

misalnya:

(yang ini saya translate dari "source" saya yaa....)

```php

class GameManager {  

    protected $input;   

    protected $video;   

    public function __construct() {   

        $this->input = new KeyboardInput();   

        $this->video = new ScreenOutput();   

    }   
    
    public function run() {   
            
            // accept user input from $this->input   
                
            // draw the game state on $this->video   

    }   

}  

```

Disini object GameManager bergantung sekali pada low level class yaitu: ```KeyboardInput``` dan ```ScreenOutput```. Masalah timbul saat kita mau mengganti input, atau output. Untuk melepas "dependency" atau kebergantungan dari kedua low level class tadi, kita memakai principle yg ke 3 tadi: **Liskov Substitution Principle**, dimana kita akan pakai interface-interface sebagai dependency nya:

```php
class GameManager {  
    protected $input;  
    protected $video;
     
    public function __construct(  
        InputInterface $input;  
        OutputInterface $output  
    ) {  
        $this->input = $input;  
        $this->video = $output;  
    }  
    public function run() {  
        // accept user input from $this->input  
        // draw the game state on $this->video  
    }  
}  
```

Disini kita lihat bahwa di method ``` __construct()``` kita menambahkan 2 parameter, yang keduanya dependency terhadap 2 buah interface yaitu: ```InputInterface``` dan ```OutputInterface``` ....

Sekarang kita bisa define input dan output terserah dari mana, dimana class-class nya adalah implemen dari interface tadi:

```php

class KeyboardInput implements InputInterface {  
    public function getInputEvent() { }  
}  

class JoystickInput implements InputInterface {  
    public function getInputEvent() { }  
}  

class MouseInput implements InputInterface {  
    public function getInputEvent() { }  
}  

class ScreenOutput implements OutputInterface {   
    public function render() { }  
}  

class TerminalOutput implements OutputInterface {  
    public function render() { }  
}  
```

sekarang kita bisa jalan program dengan:

```php
$keyboardgame = new GameManager(new KeyboardInput, new TerminalOutput);  
$onlinegame = new GameManager(new MouseInput, new ScreenOutput);  
$simulatogame = new GameManager(new JoystickInput, new ScreenOutput);  
```

## Penutup{#penutup}
Artikel ini membahas pentingnya menerapkan **SOLID Principles** dalam pengembangan perangkat lunak, khususnya menggunakan PHP, untuk menciptakan kode yang baik, mudah diuji, dirawat, dan dikembangkan. Berikut poin utamanya:

1. **Tantangan Menulis Kode Berkualitas**  
   Meski menulis kode dasar tergolong mudah berkat sumber daya belajar yang melimpah, menulis kode yang *testable*, *refactorable*, dan *maintainable* tetap menantang. SOLID Principles menjadi fondasi untuk mengatasi masalah ini, terutama ketika proyek berkembang kompleks dengan banyak fitur dan pengguna.

2. **Prinsip SOLID dan Penerapannya**  
   - **Single Responsibility Principle (SRP):** Memastikan setiap kelas/fungsi memiliki satu tanggung jawab, memudahkan manajemen kode dan mengurangi ketergantungan.  
   - **Open/Closed Principle (OCP):** Memungkinkan ekstensi fungsionalitas tanpa mengubah kode yang sudah ada, mengurangi risiko *breaking changes*.  
   - **Liskov Substitution Principle (LSP):** Menjamin substitusi subclass ke superclass tanpa mengganggu logika program, mendukung fleksibilitas desain.  
   - **Interface Segregation Principle (ISP):** Menghindari ketergantungan pada interface yang tidak relevan dengan memecahnya menjadi bagian yang spesifik.  
   - **Dependency Inversion Principle (DIP):** Mengurangi keterkaitan antar komponen dengan mengandalkan abstraksi, bukan implementasi langsung.  

3. **Konteks PHP dan Manfaat SOLID**  
   PHP, meski mudah dipelajari, rentan menimbulkan kode yang "berantakan" (*spaghetti code*) jika tidak diimbangi disiplin. Penerapan SOLID membantu menghindari hal ini dengan:  
   - Meningkatkan skalabilitas proyek.  
   - Memudahkan kolaborasi tim dan pemeliharaan jangka panjang.  
   - Mengurangi risiko *bug* akibat perubahan yang tidak terkontrol.  
 
SOLID Principles bukan sekadar teori, tetapi pedoman praktis untuk menghasilkan kode yang bersih dan berkelanjutan. Dengan menerapkannya, pengembang PHP dapat membangun sistem yang adaptif terhadap perubahan kebutuhan, mudah di-debug, serta siap menghadapi kompleksitas proyek skala besar. Artikel ini mengajak pembaca untuk mulai mendisiplinkan diri dalam menulis kode, menjadikan SOLID sebagai bagian dari budaya pengembangan yang profesional.