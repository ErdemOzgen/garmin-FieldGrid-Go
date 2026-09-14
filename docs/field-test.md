# Tek seferlik G0 saha kontrol listesi

Simülatör gözlemleri `docs/evidence/simulator.json` içinde ayrı kaydedilir.
Fiziksel sonuçlar gelmeden G0 geçmez.

## 1. Mac’te görsel kontrol

1. Ağsız ekran/GPS kontrolü için `make sim-offline` kullanın. Tam PNG aktarımı
   için kullanıcı onaylı [HTTPS test planını](https-simulator-test.md) uygulayın;
   localhost metadata döndürse de Garmin dönüştürücüsü PNG'ye erişemez.
2. İlk ekran açıklamasını okuyun; START öncesi GPS başlamamalı. START ile haritayı açın.
3. Simulation → Activity Data → FIT/GPX Playable File → Load File ile
   `tests/fixtures/synthetic-walk.gpx` seçin. Alttaki üçgen oynatma düğmesini
   kullanın; Data Field Timer Start ayrı bir kontroldür. Settings → Set GPS
   Quality → Good seçin. Bu kayıt tamamen yapaydır. Daha uzun deney için
   `.venv/bin/python scripts/synthetic_walk.py` komutunun ürettiği
   `build/synthetic-20min.gpx` dosyasını seçebilirsiniz.
4. Konum işareti, iz, GPS yaşı, görünür sentetik etiketi ve yuvarlak kenarlarda
   kırpılma olmadığını kontrol edin. UP/DOWN ile üç zoom; menü ile iki tema ve
   195/256/390 boyutlarını deneyin. Kaydırma modunda START yön eksenini değiştirir,
   BACK tek adımda konuma döner.
5. API’yi Ctrl+C ile durdurun. GPS/iz devam etmeli; harita/bağlantı hatası ayrı
   görünmeli. Tekrar `make api` ile geri gelmelidir. Menüden oturumu bitirin.

Yerel HTTP metadata deneyi, simülatörün Use Device HTTPS Requirements seçeneğiyle
engellenebilir (-1001). Yalnızca localhost deneyi için bu simülasyon seçeneği
kapatılabilir; HTTPS testi ve normal kullanımda açık tutulmalıdır. Fiziksel PRG
HTTP kabul etmez. SDK 9.2.0 GPS oynatımı sırasında yeniden yüklemede takılırsa
simülatörü tamamen kapatın, yeniden başlatın ve fixture'ı tekrar yükleyin.

## 2. Fiziksel saate yükleme

1. `make build-watch` çalıştırın. Çıktı `build/FieldMap.prg`; debug eşlikçisi
   `build/FieldMap.prg.debug.xml`. `FieldMap-simulator.prg` saate kopyalanmaz.
2. Saati veri destekli USB kablosuyla bağlayın. Gerekirse saat USB/MTP modunu kendi
   menüsünden seçin. macOS için [OpenMTP](https://github.com/ganeshrvel/openmtp)
   kullanılabilir; bu projede sistem MTP istemcisi kurulmadı.
3. PRG’yi saatin `GARMIN/APPS` klasörüne kopyalayın. Mevcut dosyaları silmeyin.
   Saati güvenli ayırın; uygulama listesinde FieldMap G0’ı açın.
4. START’a basın, açık alanda GPS’i bekleyin. **HTTPS ayarı olmadan sadece yerel
   sentetik ızgara beklenir. Gerçek sokak haritası bu sürümde yoktur.**

## 3. Fiziksel kanıt formu

| Alan | Doldurulacak değer |
|---|---|
| Tarih, saat, kaynak commit / SHA256 | |
| Saat model / firmware / Connect IQ API | |
| iPhone model / iOS / Garmin Connect sürümü | |
| PRG SHA256 (`shasum -a 256 build/FieldMap.prg`) | |
| Ekran parlaklığı / always-on / GPS modu / sıcaklık | |
| Başlangıç-bitiş pil / test süresi | |
| Heap boş / tepe / görüntü boyutu | |
| Gözlenen hata kodu / tekrar toparlanma | |

İlk 20–30 dakikalık yürüyüşte z14/z15/z16, kaydırma/merkezleme, GPS zayıflaması ve
oturumdan çıkış denenir. Tanılama ekranındaki en yüksek heap, başarılı harita sayısı ve son
süreyi not edin. Sadece ana ekranı açabilmek GPS/raster kabulü değildir.

## 4. iPhone / HTTPS deneyi

Önce özel HTTPS origin hazırlığı [setup.md](setup.md) uyarınca yapılmalı. Telefon
köprüsünün erişemeyeceği localhost ile bu test geçerli olmaz.

| Profil | En az yapılacak gözlem |
|---|---|
| H01 iPhone kilitli, GCM arka planda | En az 30 dakika ardışık raster; 195/256/390 aktarım süreleri |
| H02 Telefon başka uygulamada | Raster yenileme ve kontrol yanıtı |
| H03 GCM zorla kapalı | Başarı garantisi yok; gözlenen bağlantı sonucu |
| H04 İnternet kapalı, Bluetooth açık | GPS açık kalır; harita durumu ayrı; geri bağlantı toparlar |
| H05 Bluetooth menzili dışı | Eski harita kapsamı / GPS / geri bağlantı |
| H06 GPS zayıf | Kalite, 5 s yaş eşiği, kesintide çizilmeyen iz segmenti |
| H07 Bilek indirme, ekran sönme, çıkış | Abonelik yaşam döngüsü ve taze fix bekleme |
| H08 Saat/telefon yeniden başlatma | Ayarlar ve yeni oturum; eski iz kalıcı olmamalı |

Sonra iki saat dayanıklılık yapılır. Pil için aynı koşullardaki referans GPS
oturumuyla en az üç eşleştirilmiş deney gerekir. Tek pil yüzdesi NFR09’u kanıtlamaz.
GPS → çizim gecikmesi en az 300 örnek, düğme gecikmesi 100 eylem, soğuk harita 20,
alan yenileme 100 örnekle ölçülmelidir. Hedefler gereksinim belgesindeki gibidir.

Storage probe menüsü 1024 karakterlik ASCII metni yazıp okur ve siler (`1K OK`).
Önceki büyük değer denemesi SDK'da yakalanamayan Out Of Memory hatası verdiği için
canlı uygulamadan kaldırıldı. Bu sonuç toplam kapasite ölçümü değildir.
Bitmap kalıcılığı, yeniden başlatma sonrası geri okuma ve toplam Object Store limiti
ayrıca POC06’da ölçülmelidir; bu testler tamamlandı sayılmaz.

Gerçek ekran/iz paylaşımı isteğe bağlıdır. Paylaşmadan önce konum, özel URL veya
kimlik bilgisi bulunmadığını kontrol edin; yalnız sürüm, sayaç, hata kodu ve
PASS/FAIL gözlemi yeterli başlangıç geri bildirimidir.
