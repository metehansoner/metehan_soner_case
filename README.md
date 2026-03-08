# Test Otomasyon Projesi

Bu projede üç farklı test türü bir araya getirildi: UI testleri, API testleri ve performans testleri. Her biri farklı bir teknoloji kullanıyor ve birlikte kapsamlı bir test çözümü sunuyor.

## 📁 Proje Yapısı

Projede üç ana klasör bulunuyor:

```
.
├── ui_test_automation/      # Web arayüzü testleri (Selenium ile)
├── api_test_automation/     # API testleri (REST Assured ile)
└── load_test/              # Yük testleri (Locust ile)
```

---

## 🖥️ UI Testleri

Web sitelerinin arayüzünü test eden otomatik testler. Selenium kullanarak gerçek bir tarayıcıda sayfalar açılıp, tıklanıp, form doldurulup sonuçlar kontrol ediliyor.

### Kullanılan Teknolojiler
- Java 11
- Selenium WebDriver 4.18.1 (tarayıcı otomasyonu için)
- TestNG 7.9.0 (testleri organize etmek için)
- Maven (bağımlılıkları yönetmek için)
- Page Object Model deseni (kodun daha temiz olması için)

### Test Senaryoları
Insider kariyer sayfası testleri:
- Ana sayfanın düzgün açılması kontrolü
- Kariyer sayfasına navigasyon ve QA pozisyonlarını filtreleme
- İş ilanlarının doğru şekilde listelenmesi doğrulaması
- Ekran görüntüsü alma

### Nasıl Çalıştırılır?

Gereksinimler: Java 11, Maven ve Chrome/Firefox tarayıcı.

```bash
# Önce klasöre gir
cd ui_test_automation

# Gerekli paketleri indir
mvn clean install

# Testleri çalıştır (Chrome'da açılacak)
mvn test

# Firefox'ta çalıştırmak istersen
mvn test -Dbrowser=firefox
```

Ayarlar `src/test/resources/config.properties` dosyasından değiştirilebilir (base URL, timeout süreleri, vb.).

---

## 🔌 API Testleri

Backend API testleri. Petstore API'sine istek atılıp dönen cevaplar kontrol ediliyor. Hem başarılı senaryolar hem de hata durumları test ediliyor.

### Kullanılan Teknolojiler
- Java 21
- REST Assured 5.4.0 (API testleri için)
- TestNG 7.9.0 (test yönetimi için)
- Jackson 2.16.1 (JSON verilerle çalışmak için)
- ExtentReports 5.1.1 (güzel raporlar oluşturmak için)

### Test Senaryoları

**Temel CRUD İşlemleri (PetCrudTest)**
- Yeni evcil hayvan kaydı oluşturma
- ID ile bilgileri getirme
- Bilgileri güncelleme
- Kayıt silme

**Resim Yükleme Testleri (PetImageUploadTest)**
- Resim yükleme
- Metadata ile resim yükleme
- Metadata olmadan resim yükleme

**Hata Durumu Testleri (PetNegativeTest)**
- Geçersiz JSON ile 400 hatası kontrolü
- Olmayan ID ile 404 hatası kontrolü
- Negatif ID ile hata kontrolü
- Boş body ile güncelleme testi

**Performans Testleri (PetPerformanceTest)**
- Create işlemi < 3 saniye
- Get işlemi < 2 saniye
- Update işlemi < 3 saniye
- Delete işlemi < 2 saniye

### Nasıl Çalıştırılır?

Gereksinimler: Java 21 ve Maven.

```bash
# API testleri klasörüne gir
cd api_test_automation

# Paketleri indir
mvn clean install

# Tüm testleri çalıştır
mvn test

# Sadece CRUD testlerini çalıştırmak istersen
mvn test -Dtest=PetCrudTest
```

Test raporları `test-reports` klasöründe HTML formatında oluşur. Detaylı loglar `test-execution.log` dosyasında bulunur.

---

## ⚡ Performans Testleri

N11 arama özelliğinin yük testi. Locust ile birçok kullanıcının aynı anda arama yaptığı simüle ediliyor.

### Kullanılan Teknolojiler
- Python 3
- Locust 2.20.0 (yük testi için)
- Requests 2.31.0 (HTTP istekleri için)

### Test Senaryoları
- Farklı kelimelerle ürün arama (laptop, telefon, kulaklık, ayakkabı, kitap)
- Arama sonuçlarının düzgün yüklenip yüklenmediğini kontrol etme

### Nasıl Çalıştırılır?

Gereksinimler: Python 3.7 veya üzeri.

```bash
# Load test klasörüne gir
cd load_test

# Virtual environment oluştur (temiz bir ortam için)
python -m venv venv
source venv/bin/activate  # Windows'taysan: venv\Scripts\activate

# Gerekli paketleri yükle
pip install -r requirements.txt

# Web arayüzü ile çalıştır
locust
```

Tarayıcıda `http://localhost:8089` adresini açarak kullanıcı sayısı ve spawn rate ayarlanabilir.

Komut satırından çalıştırma:

```bash
# 10 kullanıcı, saniyede 2 kullanıcı ekle, 1 dakika çalıştır
locust --headless --users 10 --spawn-rate 2 --run-time 1m

# HTML rapor oluştur
locust --headless --users 50 --spawn-rate 5 --run-time 2m --html report.html
```

---

## 🚀 Hızlı Başlangıç

Tüm testleri sırayla çalıştırma:

```bash
# UI testlerini çalıştır
cd ui_test_automation && mvn clean test && cd ..

# API testlerini çalıştır
cd api_test_automation && mvn clean test && cd ..

# Performans testlerini çalıştır
cd load_test && locust --headless --users 10 --spawn-rate 2 --run-time 1m
```

---

## 📊 Test Raporları

- **UI testleri**: `ui_test_automation/test-output/` klasöründe TestNG raporları
- **API testleri**: `api_test_automation/test-reports/` klasöründe ExtentReports raporları
- **Performans testleri**: `load_test/report.html` dosyasında Locust raporu

---

## �️ Yeni Test Eklemek İstersen

### UI testi eklemek için:
### UI Testi
1. `ui_test_automation/src/test/java/pages/` klasörüne yeni sayfa sınıfı ekle
2. `ui_test_automation/src/test/java/tests/` klasörüne test sınıfı ekle
3. `testng.xml` dosyasını güncelle

### API Testi
1. `api_test_automation/src/main/java/models/` klasörüne veri modeli ekle
2. `api_test_automation/src/test/java/tests/` klasörüne test sınıfı ekle
3. `testng.xml` dosyasını güncelle

### Performans Testi
1. `locustfile.py` dosyasına yeni `@task` fonksiyonu ekle
2. Parantez içindeki sayı ile öncelik belirle

---

## 💡 Notlar

- UI testlerinde tarayıcı sürücüleri otomatik olarak yönetilir
- API testleri Petstore resmi API'sini kullanır: https://petstore.swagger.io
- Performans testlerinde rate limiting'e dikkat edilmeli
- Projeler CI/CD pipeline'larına entegre edilebilir

---

## 📄 Lisans

Bu proje test amaçlı geliştirilmiştir.
