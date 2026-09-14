# Forerunner 165 Harita Uygulaması

## Sistem gereksinimleri ve AI ajanı geliştirme planı

**Sürüm:** 1.0 · **Tarih:** 14 Eylül 2026 · **Durum:** Uygulamaya başlamaya hazır teknik taslak

**Proje sahibi:** Mahmut Erdem Özgen

**Hedef:** Garmin Forerunner 165 üzerinde sokak ve patika haritası, güncel GPS konumu ve hareket izi gösteren bağımsız bir Connect IQ uygulaması geliştirmek. Geliştirme kullanıcının MacBook’unda macOS ile yapılacak; telefon iPhone olacak. Uygulamayı geliştirecek taraf bir AI kodlama ajanıdır.

Önerilen ilk ürün, telefondan internet bağlantısı alan ve saatin GPS’iyle çalışan bir harita görüntüleyicisidir. Kullanıcı rota seçmeden uygulamayı açıp çevresini ve kendi konumunu görebilmelidir. Haritanın çizimi uygulamaya ait olacaktır. Fēnix Pro’nun yerleşik navigasyon motorunu açmak veya firmware değiştirmek bu projenin yöntemi değildir.

Bu belge ürün kapsamını, platform gerçeklerini, yazılım mimarisini, ölçülebilir gereksinimleri, testleri ve AI ajanının görev sırasını tanımlar. **Kod yazılmış, kullanıcının MacBook’una yazılım kurulmuş veya fiziksel saat üzerinde test yapılmış değildir.** Belgede belirtilen performans değerleri tasarım hedefidir; mevcut cihazda ölçülmüş sonuç olarak okunmamalıdır.

| Kesinleşen bilgi | Bu projedeki karşılığı |
|---|---|
| Saat | Garmin Forerunner 165 standart model; Music zorunlu değil |
| Geliştirme bilgisayarı | Kullanıcının MacBook’u ve macOS |
| Telefon | iPhone ve Garmin Connect |
| Geliştirme uygulayıcısı | AI kodlama ajanı; fiziksel testleri kullanıcı destekler |
| Temel kullanıcı ihtiyacı | Çizgiye ek olarak gerçek harita ve hareket eden konum |
| İlk teslimat | Gerçek saatte çalışan serbest keşif MVP’si |

**Başarı ölçütü:** Kullanıcı dışarıda iPhone’u cebindeyken uygulamayı açar, konumunu harita üzerinde görür ve yürüdükçe konum işareti doğru yerde güncellenir. Bağlantı kesilirse mevcut GPS verisi ile yeni harita verisinin durumu birbirinden açıkça ayrılır.

<!-- pagebreak -->

## 1 Belgenin kullanımı ve ürün kararları

Bu şartname AI ajanına ana gereksinim belgesi olarak verilmelidir. Word ve Markdown sürümleri aynı kapsamı taşır; ajan için Markdown esas çalışma girdisidir. İlerleme ve kanıtlar ileride oluşturulacak Git deposunda tutulur. Bu dosyanın varlığı dağıtım, ücretli servis satın alma veya hesap erişimi anlamına gelmez.

### Gereksinim seviyeleri

**M** ilk MVP için zorunlu, **R1** sonraki ürün sürümü için planlanan, **O** ayrı fizibilite gerektiren opsiyon anlamına gelir. Sayısal kabul hedefleri G0 teknik değerlendirmesinde gerçek cihaz sonuçlarıyla kesinleştirilir. Ajan hedefi karşılayamıyorsa sonucu belgelemeli; hedefi sessizce düşürmemelidir.

| Karar | Varsayılan kapsam | Gerekçe |
|---|---|---|
| Uygulama tipi | Connect IQ Watch App | Serbest harita ekranı ve bağımsız GPS yaşam döngüsü |
| Saat dili | Monkey C | Garmin’in resmî geliştirme yolu |
| İlk yönlendirme | North up | Harita kuzeyi üstte; döndürme maliyeti başlangıçta azaltılır |
| Veri kaynağı | Saatin GPS’i | Telefon GPS’ine bağımlı olmayan konum |
| Harita erişimi | Garmin Connect üzerinden HTTPS | İlk sürümde özel iOS uygulaması gerektirmez |
| Harita görüntüsü | Sunucuda hazırlanan raster görünüm | Saatte kapsamlı vektör motoru gerektirmez |
| Başlangıç coğrafyası | Hollanda ve Belçika saha doğrulaması | Kullanım örneklerine uygun ilk test alanı; algoritmalar genel |
| Arayüz dili | İngilizce varsayılan, Türkçe kaynak dosyası | Küçük ekran ve sürdürülebilir yerelleştirme |

### Kapsam dışında kalanlar

Fēnix firmware’i, Garmin TopoActive dosyalarını yerleşik harita gibi yükleme, root erişimi, otomobil navigasyonu, dünya çapında çevrimdışı harita, saatte yol ağı üzerinde otomatik yeniden rota hesaplama, üçüncü kişilere canlı konum paylaşımı ve Garmin antrenman algoritmalarını yeniden üretme başlangıç kapsamına dahil değildir.

**Aktif takip**, bu belgede kullanıcının kendi saatinde konumunu görmesidir. Başka kişilerin web üzerinden kullanıcıyı izlemesi ayrı bir üründür. Garmin LiveTrack entegrasyonu varsayılmamıştır.

<!-- pagebreak -->

## 2 Doğrulanmış platform ve belirsizlikler

Kaynaklar 14 Eylül 2026 tarihinde kontrol edilmiştir. Kaynak kimlikleri son bölümdeki bağlantılara karşılık gelir. Bir API’nin katalogda bulunması, kullanıcının mevcut firmware’inde bütün seçeneklerinin çalıştığını kanıtlamaz.

| Alan | Doğrulanan bilgi | Tasarıma etkisi |
|---|---|---|
| Ekran | 390 × 390 yuvarlak AMOLED [S1] | Yuvarlak kırpma ve güvenli metin alanı |
| API seviyesi | Uyumluluk kataloğunda 165 için 5.2 [S1] | SDK sürümünden ayrı değerlendirilir |
| Geliştirme SDK’sı | İndirme sayfasında 9.2.0; Mac SDK Manager mevcut [S2] | Başlangıçta sürüm ve cihaz paketi yeniden doğrulanır |
| GPS | Position ile sürekli konum olayları [S3] | Uygulama aktifken konum güncellenir |
| Konum alanları | Bazı alanlar null olabilir; heading radyan; accuracy kalite kategorisi [S4] | Null kontrolü, birim dönüşümü, sahte metre hassasiyeti yok |
| Yerleşik harita | 165 MapView destek listesinde yok [S5] | Kendi harita çizicimiz gereklidir |
| Görüntü indirme | Communications ve makeImageRequest [S6] | Telefon köprüsü ve görüntü dönüşümü test edilir |
| Depolama | Object Store toplamı cihaza bağlı; tek değer için 32 KB sınırı belgelenmiş [S7] | Büyük harita arşivi varsayılmaz |
| Aktivite kaydı | ActivityRecording ile FIT oturumu [S8] | R1’de ayrı kullanıcı isteğiyle kayıt |

### G0 aşamasında ölçülecek bilgiler

Uygulama heap limiti, grafik kaynaklarının gerçek maliyeti, Object Store toplam kapasitesi, bitmap saklama ve yeniden açma davranışı, iletişim yanıt sınırları, kabul edilen görüntü boyutları, saatteki firmware/API seviyesi ve iPhone bağlantı davranışı ayrı bir yetenek raporuna yazılmalıdır.

Saatin ürün sayfasındaki toplam depolama kapasitesi Connect IQ uygulamasının kullanabildiği alanla aynı kabul edilmemelidir. Evrensel bir “uygulamanın X MB belleği var” sayısı bu raporda ileri sürülmemiştir.

**Sürüm kuralı:** SDK 9.2.0 kullanılması API 6.0 fonksiyonlarını 165’e getirmez. Örneğin Communications.transmit için ByteArray desteği API 6.0 olarak belgelenmiştir; temel tasarım bunun üzerine kurulmayacaktır. [S6]

<!-- pagebreak -->

## 3 macOS geliştirme ortamı

AI ajanı gerçek MacBook’ta işe bir ortam envanteriyle başlamalıdır. Bilgisayarın işlemci mimarisi, macOS sürümü, mevcut Java ve geliştirme araçları okunmalı; kullanıcıya ait dizinler veya mevcut projeler değiştirilmemelidir. Aşağıdaki dizin örnektir: `~/Projects/fr165-maps`.

| Gereken araç | Kullanım | Kurulum kararı |
|---|---|---|
| Git | Kod ve karar geçmişi | Mevcut kurulum kullanılır |
| VS Code ve Garmin Monkey C uzantısı | Saat geliştirme ve hata ayıklama | Resmî uzantı doğrulanır [S2] |
| Connect IQ SDK Manager | SDK ve forerunner165 cihaz paketi | Kararlı sürüm sabitlenir |
| Java çalışma ortamı | SDK araçlarının gereksinimleri | İlgili SDK’nın istediği sürüm belirlenir |
| Connect IQ Simulator | GPS tekrar oynatma ve UI testleri | Simulator başarısı fiziksel test yerine geçmez |
| Python ve proje sanal ortamı | Önerilen API, raster üretimi ve testler | FastAPI ve görüntü bağımlılıkları kilitlenir |
| USB veri kablosu ve MTP istemcisi | Gerçek saate PRG kurulumu | OpenMTP kullanılabilir [S11] |
| iPhone üzerinde Garmin Connect | Saatin HTTPS iletişim köprüsü | Bluetooth izinleri ve bağlantı kontrol edilir |

**Apple Silicon yaklaşımı:** Ajan `uname -m` ile mimariyi belirlemeli, önce uyumlu yerel araçları denemelidir. Simulator veya SDK Manager için Rosetta gereksinimi varsa bunu gerçek hata ve resmî yönergeyle doğrulamalıdır. Rosetta veya sistem güvenlik ayarları varsayımla değiştirilmemelidir.

### Çalıştırma sözleşmesi

Ajan proje içinde aşağıdaki komutları sağlamalıdır. Bunlar mevcut Garmin komutları değil, oluşturulacak proje görevleridir: `make doctor`, `make test`, `make build-watch`, `make sim`, `make api`, `make evidence`.

`make doctor` eksik araçları ve sürümleri raporlar; gizli değerleri yazdırmaz. Build görevi forerunner165 hedefli PRG üretir. SDK yolları kullanıcının makinesinden bulunur veya açık yapılandırmayla verilir; belirli bir `/Users/...` yolu kaynak koda gömülmez.

Başlangıçta Xcode ve Apple Developer üyeliği zorunlu değildir; özel iOS uygulaması kapsam dışıdır. iOS yardımcı uygulaması seçilirse SwiftUI, Xcode, Garmin Mobile SDK ve cihazda imzalama ayrı iş paketi olarak değerlendirilir.

<!-- pagebreak -->

## 4 Sistem mimarisi

İlk sürüm üç bizim bileşenimizden ve iki dış bağımlılıktan oluşur. Telefon ekranında sürekli açık kalması gereken özel bir web sayfası tasarlanmamalıdır. Web arayüzü yalnızca eşleştirme, tercih ve R1 rota yükleme içindir; saatin Bluetooth köprüsü değildir.

| Bileşen | Sorumluluk | Sınır |
|---|---|---|
| Saat uygulaması | GPS, kamera, işaretçi, harita görüntüsü, durum yönetimi | Büyük harita veritabanı veya web motoru yok |
| Python API ve renderer | Kimlik, harita görünümü hazırlama, kota, R1 rota işleme | Konum geçmişi varsayılan olarak tutulmaz |
| Hafif web arayüzü | Cihaz eşleme, ayarlar, R1 GPX yükleme | Safari ve masaüstü tarayıcı; sürekli çalışma gerektirmez |
| Garmin Connect | Saat ile internet arasında platform bağlantısı | İşletim sistemi ve Garmin davranışına bağımlı |
| Lisanslı harita kaynağı | Sokak/patika verisi veya raster görüntüler | Sağlayıcı lisansı ve kapsama bağımlı |

### Bir harita güncellemesinin akışı

1. Saat GPS olayını alır; kaliteyi ve veri yaşını kontrol eder.
2. Kamera mevcut harita alanı içindeyse yalnızca konum işareti ve iz güncellenir.
3. Yeni alan gerekiyorsa saat HTTPS üzerinden render tanımı ister. Sunucu boyut, coğrafi sınır, kaynak bilgisi ve kısa ömürlü görüntü erişimi döndürür.
4. Saat görüntüyü makeImageRequest ile alır. İstek sırasında konum güncellenmeye devam eder.
5. Gelen görüntü ile coğrafi metaveri aynı render kimliğiyle atomik olarak etkinleştirilir. Eski kamera isteğinin cevabı yeni ekranı geri alamaz.

**Geliştirme ve çalışma ayrımı:** Kodun MacBook’ta geliştirilmesi uygundur. Dışarıda canlı harita için API’nin Garmin iletişim yolundan erişilebilen, geçerli sertifikalı bir HTTPS adresi olmalıdır. Telefon veya Garmin köprüsü açısından `localhost` MacBook demek değildir. Yerel ağ IP’sine erişim garanti kabul edilmez.

G0’da yerel sahte servis ve lisans gerektirmeyen test görselleri kullanılır. Gerçek saatte internet testi için küçük bir geliştirme sunucusu veya açıkça yapılandırılmış HTTPS tüneli gerekir. MacBook’a bağlı tünel yalnızca geliştirme içindir; bilgisayar uyuduğunda veya ağdan ayrıldığında saha çözümü olarak çalışmaz.

<!-- pagebreak -->

## 5 Teknik doğrulama aşaması G0

G0’ın çıktısı çalışan küçük bir prototip ve kanıt raporudur. G0 tamamlanmadan büyük bir harita motoru, kapsamlı portal veya çevrimdışı şehir paketleri geliştirilmemelidir.

| Deney | Yapılacak iş | Çıkış kanıtı |
|---|---|---|
| POC01 Araç zinciri | Temiz build ve simulator açılışı | Sürümler, komut, PRG özeti, build logu |
| POC02 GPS | Gerçek saatte konum, kalite, zaman, yön | Açık hava kaydı ve cihaz ekranı |
| POC03 Raster | 195, 256 ve 390 piksel test görselleri | Aktarım, çizim, boyut ve bellek ölçümü |
| POC04 Telefon | Ekran açık, kilitli, GCM arka planda | En az 30 dakikalık bağlantı testi |
| POC05 Yaşam döngüsü | Ekran sönmesi, uygulamadan çıkış, geri dönüş | GPS ve ağ davranışı tablosu |
| POC06 Depolama | Küçük değer, parça, bitmap, yeniden başlatma | Boyut sınırları ve hata davranışı |
| POC07 Hata koşulları | Bluetooth ve internet ayrı ayrı kesilir | Donmadan GPS devamı ve açık durum mesajı |
| POC08 Güç | Eşleştirilmiş GPS referansına karşı deneme | Başlangıç/bitiş pil, süre ve ayarlar |

### Kabul ve karar

G0 geçişi için GPS işareti ve coğrafi olarak eşlenmiş test haritası fiziksel 165 üzerinde çalışmalı; iPhone kilitliyken normal GCM koşulunda ardışık haritalar alınabilmelidir. UI ağ beklerken yanıt vermeli, RAM sınırsız büyümemelidir. Ölçülen API/firmware sürümleri kanıt dosyasında bulunmalıdır.

Görüntü aktarımı yavaşsa önce palet, boyut, mevcut görüntü üzerinde kaydırma ve istek sıklığı optimize edilir. Sorun çözülmezse sadeleştirilmiş vektör verisiyle farklı renderer denenmesi ayrı karar olarak açılır. Fiziksel bağlantı başarısızken yalnızca simulator ekranı “G0 geçti” sayılmaz.

**Yetenek tablosu alanları:** SDK ve cihaz paketi sürümü, model, firmware, iOS ve GCM sürümü, heap limiti ve tepe kullanımı, görüntü dönüşümü, Object Store testi, desteklenmeyen API’ler, ölçüm tarihi ve test yöntemi. Kaynakta yazan limit ile deneyde görülen limit ayrı sütunlarda tutulur.

<!-- pagebreak -->

## 6 Konum ve oturum gereksinimleri

Bu bölümdeki tüm gereksinimler **M** seviyesindedir. Konum kullanımı uygulama açılır açılmaz gizlice başlamaz; kullanıcının Haritayı Aç eylemi ve izin açıklamasıyla başlar. GPS olaylarının uygulama pasifken durabildiği dikkate alınır. [S3]

**FR01 Serbest keşif:** Kullanıcı herhangi bir GPX veya hedef seçmeden haritayı açabilmelidir. İlk kurulum sonrası en fazla iki uygulama içi eylemle GPS bekleme ekranına ulaşılmalıdır.

**FR02 Konum aboneliği:** Positioning izniyle sürekli konum olaylarına abone olunmalıdır. Tekrarlanan ekran geçişleri birden fazla abonelik veya paralel oturum üretmemelidir.

**FR03 Geçerli veri:** Null koordinat, geçersiz enlem/boylam, eksik zaman, NaN ve sonsuz değerler işlenmelidir. Hatalı veri asla varsayılan 0,0 noktasına dönüştürülmemelidir. Kalite etiketi Garmin kategorilerinden türetilmelidir.

**FR04 Tazelik:** Son kullanılabilir konumun yaşı gösterilmelidir. Başlangıç hedefi olarak beş saniyeden eski konum Eski Konum durumuna geçer. Kalite kaybında nokta güncel fix gibi sunulmaz; uygulama kendi tahmini konumunu gerçek GPS diye üretmez.

**FR05 Hareket işareti:** Koordinat, haritanın coğrafi dönüşümüyle ekrana yerleştirilmelidir. Kullanılabilir GPS olayından sonra işaretçi gecikmesi NFR01’e uymalıdır. Gösterilen konum ağ cevabını beklememelidir.

**FR06 Hareket izi:** Oturum boyunca son konumlar çizgi olarak gösterilmelidir. Görüntüleme izi sınırlı bir halka tampon ve sadeleştirme kullanmalı; belleği süreyle sınırsız büyütmemelidir. GPS kesintilerinin üzerinden yanıltıcı düz çizgi çizilmemelidir.

**FR07 Yaşam döngüsü:** Aktif, pasif ve yeniden aktif durumları yönetilmelidir. Pasiflikten dönüşte eski verinin yaşı korunur ve ilk taze konum beklenir. Tüm gün arka planda takip vaat edilmez.

**FR08 Durdurma:** Kullanıcı harita oturumunu kapattığında uygulamaya ait GPS aboneliği, yeniden deneme zamanlayıcıları ve bekleyen ağ işi temizlenmelidir. Eski callback kapatılmış ekranı güncellememelidir.

**FR09 Son oturum tercihi:** Son zoom, tema ve seçilen harita stili saklanabilir. Hassas konum geçmişi MVP’de kalıcı saklanmaz. Ayarların bozulması halinde güvenli varsayılanlarla açılış sağlanmalıdır.

<!-- pagebreak -->

## 7 Harita ve kamera gereksinimleri

Bu bölüm **M** kapsamındadır. Tasarım normal kuzey yukarı görünümle başlar. GPS işaretini oynatmak, her saniye yeni harita resmi indirmek anlamına gelmez.

**FR10 Harita içeriği:** Görüntüde mevcut veri kapsamında yollar, sokaklar, patikalar, su ve park alanları ayırt edilebilmelidir. En az bir sade gündüz ve bir gece stili bulunmalıdır. Kaynakta bulunmayan yol veya isimler üretilmemelidir.

**FR11 Coğrafi eşleme:** Her görüntü kesin coğrafi sınırlar, projeksiyon, piksel boyutları ve render kimliğiyle kullanılmalıdır. Görüntü ile metaverisi ayrı isteklerden gelse bile eşleşme doğrulanmalıdır.

**FR12 Kamera takibi:** Takip modunda konum, görünümün merkezi çevresindeki güvenli bölgede tutulmalıdır. İlk eşik merkezden görünür yarıçapın yüzde 25’idir; bu aşıldığında yeni kamera alanı istenir. Ağ gecikmesinde konum eski harita üzerinde ilerleyebilir.

**FR13 Yakınlaştırma:** Başlangıçta z14, z15 ve z16 eşdeğeri üç ölçek sunulmalıdır; saha okunabilirliğiyle kesinleştirilir. Yakınlaştırma, konum işaretini aynı coğrafi noktada tutmalıdır. Ölçek çubuğu enleme göre hesaplanmalıdır.

**FR14 Kaydırma ve geri dönme:** Kullanıcı haritayı göz atma modunda kaydırabilmeli; tek eylemle konum takibine dönebilmelidir. Göz atarken yeni GPS olayı kamerayı zorla merkeze çekmemelidir.

**FR15 Çizim sırası:** Harita zemini, R1 rota, hareket izi, konum işareti, durum ve kontroller belirlenmiş sırayla çizilir. İşaretçi yol adlarıyla karışmamalı, hatalar yalnızca renk değişikliğiyle anlatılmamalıdır.

**FR16 Önbellek:** Güncel görüntü ve bütçe varsa bir komşu/önceki görüntü tutulmalıdır. Kamera aynı alanı yeniden istediğinde lisansın izin verdiği önbellek kullanılmalıdır. Kullanıcıya ait rota katmanı paylaşılan harita önbelleğine karıştırılmaz.

**FR17 Güncelleme bütünlüğü:** Geciken cevap yeni görüntünün üzerine yazılamaz. Zoom ve stil değişiminde nesil numarası artırılır. Geçerli eski harita yeni görüntü tamamlanana kadar korunur.

**FR18 Harita yokluğu:** Bağlantı yok ve mevcut alan kapsanmıyorsa GPS işareti/iz sade zeminde gösterilebilir; Harita Kullanılamıyor mesajı bulunmalıdır. Önceki resmi yeni coğrafyaya aitmiş gibi germek yasaktır.

<!-- pagebreak -->

## 8 Bağlantı ve yapılandırma gereksinimleri

Bu bölüm **M** kapsamındadır. Normal iPhone senaryosu Garmin Connect’in kurulu, eşleşmiş ve işletim sisteminin gerekli Bluetooth izinlerine sahip olduğu durumdur. Kullanıcının uygulamayı zorla kapatması ayrıca test edilir; bu durumda kesintisiz aktarım garanti edilmez.

**FR19 Telefon köprüsü:** Saat ağ taleplerini Garmin’in desteklenen Communications yolu üzerinden yapmalıdır. Proje özel bir iOS uygulamasına, Safari Web Bluetooth’a veya sürekli açık portal sekmesine bağımlı olmamalıdır.

**FR20 Durum ayrımı:** GPS hazır, telefon erişilebilir, servis erişilebilir, harita güncel ve kayıt açık durumları ayrı tutulmalıdır. İnternet yokluğu GPS kapalı olarak gösterilmemelidir. Kesin nedeni bilinmeyen hata “bağlantı sorunu” olarak sunulur.

**FR21 İstek yönetimi:** Aynı anda en fazla bir mantıksal harita işi yürütülür; metaveri ve görüntü aşamaları sırayla işlenir. Kamera değişimleri birleştirilir. İlk hedef harita işi başlangıçları arasında en az beş saniyedir.

**FR22 Yeniden deneme:** Geçici hatada 2, 4, 8, 16 ve en fazla 30 saniye gecikmeli, küçük rastgelelik içeren geri çekilme uygulanır. 401, 403, 413 ve kalıcı şema hataları körlemesine tekrar edilmez. 429 için bekleme talimatı uygulanır.

**FR23 Cihaz eşleme:** Web hesabına giriş yapan kullanıcı saatin gösterdiği kısa ömürlü kodla cihazı bağlar. Kod tek kullanımlı, deneme limiti olan ve beş dakikada sona eren bir tanımlayıcıdır. Saat üzerinde parola yazılması gerekmez.

**FR24 Token yönetimi:** Uygulama yalnızca kendi servisi için cihaz kapsamlı erişim kullanır. Token yenileme, cihazı kaldırma ve yeniden eşleme akışları vardır. Saat kaynak koduna ortak servis sırrı veya sağlayıcı anahtarı gömülmez.

**FR25 Portal:** Mobil Safari ve macOS tarayıcısında eşleştirme, cihaz kaldırma, harita stili ve veri kullanım tercihi çalışmalıdır. Basit sunucu tarafı HTML yeterlidir; kapsamlı SPA veya native mobil uygulama zorunlu değildir.

**FR26 Tanılama:** Kullanıcı sürüm, bağlantı durumu ve son hata kodunu görebilmelidir. Tanılama çıktısı varsayılan olarak koordinat, token, hesap e-postası ve özel URL içermez.

<!-- pagebreak -->

## 9 Kullanıcı arayüzü gereksinimleri

Bu bölüm **M** kapsamındadır. Temel akış, koşarken veya yürürken saatin kısa süreli kontrol edilmesine uygun olmalıdır. Teknik API isimleri ürün ekranında gösterilmez.

**FR27 Fiziksel düğmeler:** Harita açma, zoom, menü, takip moduna dönme ve çıkış temel düğmelerle yapılmalıdır. Dokunmatik kaydırma ek kolaylıktır. LIGHT gibi sistem düğmeleri ve sistemin uzun basma davranışları zorla yeniden atanmaz.

**FR28 Yuvarlak ekran:** Kritik metin, işaret ve kontrol alanları yuvarlak ekranın kırptığı köşelere taşmamalıdır. Tasarım 390 × 390 gerçek boyutta incelenir. Bildirim ve menüler konumun uzun süre görünmesini engellemez.

**FR29 Okunabilirlik:** Büyük konum simgesi, en az 18 piksel eşdeğer ana durum yazısı ve kontrastlı rota çizgisi hedeflenir. Sistem font seçiminin gerçek görüntüsü ölçülür; bu değer her Garmin fontunda doğrudan API font boyutu değildir.

**FR30 Kaynak bilgisi:** Sağlayıcının gerektirdiği atıf harita üzerinde okunabilir ve görünür olmalıdır. Küçük ekran için kullanılabilecek atıf düzeni lisansa göre doğrulanır; yalnızca gizli Hakkında ekranına taşınmaz. OSM standart servis politikası görünür atıf ister. [S10]

**FR31 Açıklamalar:** İlk kullanımda konumun harita istemek için servis üzerinden işleneceği ve telefon/internet gereksinimi kısa şekilde açıklanmalıdır. Ağ hatası sırasında kullanıcının yapacağı eylem belirtilir; sürekli tekrarlanan açılır pencere kullanılmaz.

### Önerilen ekranlar

| Ekran | Gösterilen bilgi | Ana eylem |
|---|---|---|
| Başlangıç | Haritayı Aç, bağlantı, ayarlar | Haritaya geç |
| GPS bekleniyor | Kalite, bekleme durumu, bağlantı | Bekle veya çık |
| Harita | Konum, ölçek, yön, veri durumu | Zoom, kaydır, menü |
| Menü | Tema, takip, tanılama, oturumu bitir | Seç ve geri dön |
| Eşleme | Kısa kod ve web adresi | Telefonda bağla |
| R1 kayıt | Süre, kayıt durumu, duraklat, kaydet | Kontrollü bitir |

Düğme eşlemesi önce küçük etkileşim prototipinde denenir. START seçim/menü, UP ve DOWN ölçek veya liste gezme, BACK geri/çıkış için adaydır. Kesin eşleme SDK olayları ve cihaz davranışıyla doğrulanır.

<!-- pagebreak -->

## 10 R1 rota ve kayıt kapsamı

Bu bölüm serbest keşif MVP’si kabul edildikten sonra geliştirilir. R1 işlerinin tamamlanması MVP’nin çalıştığını iddia etmek için ön şart değildir; R1 tamamlandı demek için aşağıdaki bütün maddeler gerekir.

**FR32 GPX içe aktarma:** Kullanıcı portaldan GPX 1.1 dosyası yükleyebilmelidir. Başlangıç sunucu limiti 5 MB ve 100 bin giriş noktasıdır. XML harici varlıklar kapalı olmalı; hatalı koordinatlar ve aşırı kaynak tüketen içerik reddedilmeli, geçerli segment ayrımları korunmalıdır.

**FR33 Rota hazırlama:** Sunucu rotayı segmentleri koruyarak sadeleştirir. Hedef profil 50 km’ye kadar rota ve en fazla 2.000 görüntüleme noktasıdır. G0 bellek bütçesi bunu doğrulamalıdır. Limit aşılırsa sessiz kesme yerine kullanıcıya açık hata veya kontrollü sadeleştirme sunulur.

**FR34 Rota aktarımı:** Rota numaralı küçük parçalarla indirilir. Manifest, parça sayısı, bütünlük kontrolü ve şema sürümü doğrulanmadan yeni rota etkinleşmez. Eski rota eksik indirmeyle bozulmamalıdır.

**FR35 Rota takibi:** Rota ve hareket izi farklı görünmelidir. İlerleme, kalan rota uzunluğu ve rota dışı durum yalnızca yeterli GPS kalitesinde hesaplanır. İlk rota dışı eşiği 40 metre ve 10 saniye, dönüş eşiği 25 metredir; saha testiyle doğrulanır.

**FR36 Kayıt kontrolü:** Kullanıcı açıkça seçerse ActivityRecording oturumu başlatılır. Duraklat, devam et, durdur, kaydet ve sil akışları ayrı olmalıdır. Silme kullanıcı onayı gerektirir. Sadece haritaya bakmak otomatik FIT kaydı başlatmaz. [S8]

**FR37 FIT doğrulaması:** Kaydedilen aktivite Garmin’in normal senkronizasyon akışında görünmeli; konum, zaman ve spor tipi test edilmelidir. Özel uygulamanın tüm yerleşik koşu özelliklerini veya antrenman metriklerini sağladığı iddia edilmemelidir.

**FR38 Yeniden açılış:** Saklanan rota ve ayarlar sürümlü biçimde geri yüklenir. Kesilen FIT kaydının otomatik kurtarılması platformda doğrulanmadan vaat edilmez. Uygulama kapanırsa durum dürüstçe açıklanır; yeni oturum eski kayıt diye sunulmaz.

Dönüş komutları ve otomatik yol ağı yönlendirmesi R1 kapsamında zorunlu değildir. GPX çizgisinden güvenilir sokak manevrası çıkarmak ayrıca rota topolojisi veya yönlendirme servisi gerektirir.

<!-- pagebreak -->

## 11 Çevrimdışı kullanım ve opsiyonlar

Çevrimdışı kavramı üç ayrı durum olarak ele alınır. Kullanıcıya “haritalar çevrimdışı çalışır” ifadesi hangi alan ve zoom seviyelerinde geçerli olduğu belirtilmeden gösterilmemelidir.

| Durum | MVP ve R1 davranışı | Sınır |
|---|---|---|
| Internet kesildi, mevcut harita RAM’de | GPS ve görüntü sınırları içindeki harita devam eder | Yeni alan indirilmez |
| Uygulama kapandı ve yeniden açıldı | Ayarlar; R1’de kayıtlı rota geri gelir | Kalıcı harita paketi garantisi yok |
| Önceden indirilen bölge ve telefonsuz kullanım | O kapsamındaki çevrimdışı paket özelliği | Kapasite ve lisans doğrulaması gerekir |

**OF01 Sınırlı paket:** G0 sonrası deneysel olarak tek zoom düzeyinde yaklaşık 2 × 2 km veya belirli bir rota koridoru seçilebilir. Bu bir taahhüt değil, ilk fizibilite örneğidir. Kaynak veri lisansı, belleğe açılan görüntü maliyeti ve kalıcı alan birlikte ölçülür.

**OF02 Paket bütünlüğü:** Paket manifesti alan sınırlarını, zoom listesini, stil ve veri sürümünü, parça sayısını, gereken alanı ve atfı içerir. Kapsama dışına çıkış görünür olmalıdır. Yeni paket doğrulanmadan eski paket silinmez.

**OF03 Yöne göre harita:** Track up görünüm, yerel dönüşüm maliyeti ve yazı okunabilirliği ölçülürse eklenebilir. Düşük hızda veya yön verisi yokken sabit kuzey yukarı görünüm kullanılabilir; her yön değişiminde sunucudan yeni resim istenmez.

**OF04 iOS yardımcı uygulaması:** Telefonda harita paketi saklama ve yerel aktarım ancak Garmin Mobile SDK ile gerçek iPhone testleri başarılı olursa seçilir. “Telefon indirdi, saat otomatik kullanır” varsayımı yapılmaz. Bu yol MVP’ye zorunlu bağımlılık eklemez.

### Teknik uyarının anlamı

Object Store bitmap türlerini desteklese de bu, büyük çevrimdışı harita alanı garantisi değildir. 32 KB tek değer sınırı ve cihaza bağlı toplam sınır nedeniyle saklanacak biçim, parça büyüklüğü ve yeniden yükleme test edilmelidir. [S7]

Garmin cihazına USB ile dosya kopyalanabilmesi, Connect IQ uygulamasının rastgele dosya yolundan okuyabildiğini göstermez. MBTiles, PMTiles veya özel harita arşivini saate kopyalayıp doğrudan açma mimarisi desteklenen dosya erişimi kanıtlanmadan kullanılmamalıdır.

<!-- pagebreak -->

## 12 Harita servisinin tasarımı

Önerilen uygulama, sunucuda oluşturulmuş, kuzey yukarı bir raster harita görünümü alır. Sunucu lisanslı veri veya izinli bir sağlayıcıdan harita üretir; konum işareti ve özel rota sunucu görüntüsüne gömülmez. Böylece aynı bölge görüntüsü kullanıcılar arasında yeniden kullanılabilir.

### Görünüm üretimi

Başlangıç deneyi 390 × 390 görüntüdür. G0’da 195 ve 256 piksel alternatifleri hız ve okunabilirlik açısından karşılaştırılır. Renk paleti sadeleştirilir; küçük patikalar ile yazılar birbirini bastırmamalıdır. Çok düşük çözünürlüğün büyütülmesi kabul için yalnızca aktarım hızına göre seçilmez.

Sunucu görüntüyü piksel sınırları ve EPSG 3857 coğrafi alan metaverisiyle eşler. Garmin görüntü aktarımı ölçek veya palet dönüşümü yapabileceği için son gelen genişlik/yükseklik doğrulanır. Beklenmeyen en boy oranı görüntünün reddedilmesine yol açar. [S6]

### Servis sınırları

Kullanıcıdan gelen keyfî URL’ye proxy olunmaz. Stil, zoom, boyut ve veri sağlayıcısı izinli listeden seçilir. Her istek için oluşturulan piksel sayısı ve upstream çağrı sayısı sınırlanır. Boş veya desteklenmeyen bölge açıkça raporlanır. Sağlayıcı kotası aşılırsa mevcut haritayı koruyarak kontrollü hata döndürülür.

### Sağlayıcı seçimi

Tercih, saat için yeniden boyutlandırma, sunucu tarafı işleme, önbellek ve ileride sınırlı çevrimdışı pakete açıkça izin veren bir kaynaktır. Bu haklar, maliyet ve atıf koşulları sağlayıcı karar kaydında tutulur. Standart `tile.openstreetmap.org` servisi önceden toplu indirme ve çevrimdışı paket dağıtımı için kullanılmaz. [S10]

Bu rapor belirli ücretli sağlayıcıyı veya fiyatı seçmez. AI ajanı ilk prototipte sentetik harita kullanır; gerçek sağlayıcı entegrasyonu için kullanıcının mevcut hesabını veya seçilecek servisi yapılandırılabilir adaptörle ekler. Harita verisi açık olsa bile sunucu hizmeti ücretsiz veya sınırsız kabul edilmez.

### Çalışma ortamı

MVP için tek API süreci, küçük hesap/ayar veritabanı ve sınırlı disk önbelleği yeterli başlangıç tasarımıdır. Kubernetes, mikroservisler ve kapsamlı mesaj kuyruğu başlangıç gereksinimi değildir. Gerekirse renderer bağımsız çalışan işçiye ayrılır; bunun nedeni ölçülmüş yük olmalıdır.

<!-- pagebreak -->

## 13 API ve veri sözleşmesi

Aşağıdaki uçlar **önerilen uygulama protokolüdür**; Garmin’in API uçları değildir. Ajan bunları OpenAPI ve test örnekleriyle somutlaştırmalıdır. API `/v1` ile sürümlenir; bilinmeyen zorunlu şema sürümü reddedilir.

| Uç | İşlev | Erişim |
|---|---|---|
| POST /v1/pairings | Kısa eşleme oturumu oluştur | Hız sınırlı başlangıç |
| POST /v1/pairings/claim | Kodu hesaba bağla | Web oturumu |
| POST /v1/device/token | Eşleme sonucu veya token yenile | Cihaz kanıtı |
| POST /v1/map-renders | Görünüm tanımı ve görüntü erişimi al | Cihaz tokenı |
| GET /v1/images/{renderId} | Sabit harita görüntüsünü getir | Kısa ömürlü render yetkisi |
| GET /v1/config | Kullanıcı tercihi ve profil | Cihaz tokenı |
| POST /v1/routes | R1 GPX içe aktar | Web oturumu |
| GET /v1/routes/{id}/chunks/{n} | R1 rota parçası al | Kullanıcıya bağlı cihaz tokenı |
| DELETE /v1/devices/{id} | Cihaz bağını kaldır | Web oturumu |

### Harita tanımı alanları

`schemaVersion`, `requestGeneration`, `renderId`, `projection`, `bounds3857`, `imageWidth`, `imageHeight`, `zoom`, `styleVersion`, `mapDataVersion`, `imageUrl`, `expiresAt`, `attribution` alanları döndürülür. `bounds3857` sırası minX, minY, maxX, maxY; birim metredir. Görüntü boyutları yeniden örnekleme sonrası kullanılacak koordinat dönüşümüyle tutarlı olmalıdır.

Saat metaveriyi yetkilendirilmiş makeWebRequest ile alabilir. makeImageRequest imzasında özel HTTP başlığı seçeneği belgelenmediği için görüntü erişimi kısa ömürlü ve yalnızca bir render’a yetkili URL ile tasarlanır. Normal hesap tokenı URL’ye konulmaz. G0’da gerçek iPhone üzerinden bu iki aşama birlikte denenir. [S6]

### Konum ve rota alanları

Konumlarda adlandırılmış `latDeg`, `lonDeg`, `fixTimeUtc`, `receivedMonotonicMs`, `quality`, `headingRad` ve `speedMps` kullanılır. Generic bir `accuracyMeters` alanı uydurulmaz. Rota dizisi gerekiyorsa sözleşme açıkça `[lon, lat]` der; Garmin `toDegrees()` dönüşündeki sıralama adaptörde çevrilir. [S3], [S4]

Hatalar `code`, `retryable`, `retryAfterSec`, `requestId` taşır. Token ve tam konum hata mesajında yansıtılmaz. İstek/yanıt örnekleri yapay verilerden oluşturulur.

<!-- pagebreak -->

## 14 Koordinat dönüşümü ve veri bütçesi

Bu bölüm uygulama tasarımıdır. Amaç harita ile GPS işaretinin farklı koordinat sistemlerinden dolayı kaymasını önlemektir. Ajan aşağıdaki matematiksel davranışı test koduyla tanımlamalıdır; yalnızca ekran görüntüsüne bakarak doğruluğa karar verilmez.

### Koordinat işleme

WGS84 enlem/boylamı Web Mercator koordinatına dönüştürülür. Görüntünün sol üst noktası minX ve maxY ile ilişkilendirilir; yatay konum X aralığından, dikey konum ters Y aralığından hesaplanır. Sınırlar piksel kenarlarını ifade eder; örnekleme için piksel merkezleri yarım piksel içeridedir. Görüntü küçültülürse aynı coğrafi sınır korunur.

Uzunluklar enlem/boylam farkını doğrudan metre sayarak hesaplanmaz. Ekran dönüşümünde yeterli kayan nokta hassasiyeti kullanılır. Hollanda ve Belçika testlerine ek olarak sıfır meridyeni, güney yarımküre ve boylam sarma testleri gerekir. Mercator’ın kutup sınırı dışındaki enlemler reddedilir veya desteklenen aralığa açıkça sınırlandırılır; sessiz bozuk çizim yapılmaz.

R1 rota ilerlemesinde en yakın nokta yerine yakın segment hesabı kullanılır. Kesişen rotalarda önceki ilerleme ve arama penceresi dikkate alınır; kullanıcı karşı yola yakınlaştığında kalan mesafe aniden sıfırlanmamalıdır. GPX segment boşlukları korunur.

### Bellek ve ağ hesabı

390 × 390 bir görüntü 152.100 pikseldir. Varsayımsal 8 bit/piksel ham tampon yaklaşık 149 KiB, 16 bit yaklaşık 297 KiB olur. İki 16 bit tampon yaklaşık 594 KiB tutar. **Bunlar Garmin heap ölçümü değildir**; çözülmüş görüntü, sıkıştırılmış dosya ve grafik kaynak maliyetinin ayrı ölçülmesi gerektiğini gösterir.

Başlangıç ağ modeli: 30 KiB görüntü ve dakikada iki yeni görüntü, saatte yaklaşık 3,5 MiB görüntü verisidir. Dakikada on görüntü yaklaşık 17,6 MiB olur. HTTP, token ve metaveri ek yükleri hariçtir. Aynı yeri gezen kullanıcılar, çok zoom yapan kullanıcılar ve hızlı hareket ayrı ölçülür.

Rota JSON’u saat üzerinde ayrıştırılırken nesne ek yükü oluşur. 2.000 noktanın dosyada küçük olması heap içinde küçük olduğunu kanıtlamaz. Parça boyutu başlangıçta en fazla 16 KiB serileştirilmiş uygulama verisi hedeflenir; gerçek iletişim ve depolama limitleri G0’da ölçülür.

<!-- pagebreak -->

## 15 Performans ve kalite gereksinimleri

Aşağıdaki değerler **önerilen kabul hedefleridir**. G0’da ölçülür ve G1 başlangıcında kayıt altına alınır. AI ajanı daha hızlı test geçsin diye bunları tek taraflı değiştiremez. Donanımın desteklediği GPS sıklığı ile uygulamanın veriyi ekrana aktarma gecikmesi ayrı ölçülür.

| Kimlik | Hedef | Ölçüm koşulu |
|---|---|---|
| NFR01 | GPS olayından işaretçiye p95 ≤ 500 ms | Kullanılabilir olay; en az 300 örnek |
| NFR02 | Düğme eylemine ilk UI yanıtı p95 ≤ 250 ms | 100 eylem; ağ devam ederken de |
| NFR03 | İlk kullanılabilir harita p95 ≤ 15 s | GPS hazır ve token geçerli; 20 başlangıç |
| NFR04 | Yeni alan haritası p95 ≤ 8 s | Sağlıklı bağlantıda 100 görünüm değişimi |
| NFR05 | 2 saat oturumda sıfır çökme ve OOM | Serbest keşif, pan ve zoom karma senaryosu |
| NFR06 | Tepe heap ölçülen limitin ≤ yüzde 80’i | Ayrıştırma ve görüntü geçişleri dahil |
| NFR07 | Tek mantıksal harita işi; kontrolsüz kuyruk yok | Hızlı pan, yavaş ağ ve geciken cevap |
| NFR08 | Varsayılan profilde ≤ 20 MiB/saat görüntü bütçesi | 60 dakika yürüyüş; yoğun manuel pan ayrı |
| NFR09 | Referansa göre ek pil kaybı ≤ 5 yüzde puan/saat | Aynı GPS/ekran koşullarında en az 3 çift test |
| NFR10 | İki saat sonunda büyüyen bellek eğilimi yok | Isınma sonrası en az 30 örnek ve kaynak sayımı |
| NFR11 | Konumun haritaya yazılımsal yerleşim hatası ≤ 2 px | Bilinen sentetik koordinat testleri |
| NFR12 | Servis tek başına p95 ≤ 1 s sıcak önbellek | 10 eşzamanlı kullanıcı; 500 istek |

**Sağlıklı bağlantı profili:** Telefon saate yakın, Bluetooth açık, telefon interneti çalışıyor, GCM normal arka plan koşulunda, servis sağlıklı. iOS/GCM sürümü ve saat firmware’i raporlanır. Uçtan uca p95 platform köprüsünü de içerir; telefon hız testi tek başına bu koşulu kanıtlamaz.

Pil testi mutlak “X saat çalışır” iddiasına çevrilmez. Parlaklık, always on durumu, sıcaklık, GPS modu, rota ve süre kaydedilir. Ölçüm hassasiyeti düşükse daha uzun eşleştirilmiş oturum gerekir. Pil veya aktarım hedefi kaçarsa kalite ve kapsam seçenekleri kullanıcıya sunulur.

<!-- pagebreak -->

## 16 Güvenlik ve kişisel veri gereksinimleri

Bu bölüm ürün mühendisliği kararlarıdır. Çevrimiçi harita sunucusu talep edilen bölgeyi görebilir; “hiç konum paylaşılmıyor” ifadesi kullanılmamalıdır. Garmin ve harita sağlayıcısı üzerinden geçen veri yolu da kullanıcı açıklamasında yer almalıdır.

**SEC01 İzin ve amaç:** Konum yalnızca kullanıcının başlattığı harita/kayıt oturumunda işlenir. Hesap eşlemesi, konum kullanımı ve R1 kalıcı kayıt ayrı tercihlerdir. Garmin geliştirici koşullarındaki konum bildirimi ve katılım gereksinimi dikkate alınır. [S2]

**SEC02 Taşıma ve sırlar:** Gerçek cihaz için geçerli sertifikalı HTTPS gerekir. TLS doğrulaması kapatılmaz. Harita sağlayıcısı anahtarları sunucuda; geliştirici imzalama anahtarı Mac’te Git dışında saklanır. Anahtar veya token AI sohbetine ve loglara yazılmaz.

**SEC03 Cihaz tokenı:** Erişim tokenı cihaz ve izin kapsamına bağlı olur; örnek erişim süresi 15 dakika, döndürülen yenileme yetkisi en fazla 30 gün olarak yapılandırılır. Fiziksel saatten sır çıkarılamayacağı varsayılmaz; iptal ve kota tasarlanır.

**SEC04 Görüntü yetkisi:** İmzalı görüntü URL’si yalnızca belirli render kimliğini ve örnek olarak iki dakikalık süreyi kapsar. Köprü tekrarları nedeniyle zorunlu tek kullanım yerine süre ve erişim sayısı limiti uygulanabilir. Bu URL hesap yönetimi veya özel rota okuma yetkisi taşımaz.

**SEC05 Erişim kontrolü:** Başka hesabın cihazı, rotası veya ayarı okunamaz. Her uç nesne bazında yetkilendirilir. GPX dosyası, stil ve URL alanları güvenilmeyen girdi sayılır. Görüntü sunucusu SSRF ve kontrolsüz kaynak tüketimine açık bırakılmaz.

**SEC06 Veri tutma:** Varsayılan olarak tam GPS geçmişi sunucuya gönderilmez. Harita isteği işlem belleğinde kullanılır; koordinat, query string ve yetkili görüntü URL’si erişim loglarından çıkarılır. Genel harita önbelleği kullanıcı kimliğiyle bağlanmaz. R1 yüklenen rota kullanıcı silene kadar saklanır; silme ana depoda 24 saat, yedeklerde en fazla 30 gün hedefiyle belgelenir.

**SEC07 Kanıt ve telemetri:** Otomatik testler yapay rotalar kullanır. Hata telemetrisi isteğe bağlı, koordinatsız ve token içermeyen biçimde tasarlanır. Gerçek saha izi AI ajanına gönderilecekse kullanıcı bunu açıkça seçer; ekran kayıtları ve dosyalar önce gözden geçirilir.

**SEC08 Güncelleme:** Bağımlılıklar sabitlenir, güvenlik taraması ve gizli veri kontrolü yapılır. Dağıtılacak sürüm kaynak commit’i ve dosya özetiyle tanımlanır. Ürün Garmin tarafından onaylanmış gibi adlandırılmaz.

<!-- pagebreak -->

## 17 Kabul testleri ve izlenebilirlik

Aşağıdaki gruplar gereksinim kapsamını verir. Ajan her grubun alt senaryolarını uygulamalı ve sonuçları PASS, FAIL veya NOT RUN olarak işaretlemelidir. NOT RUN başarılı sayılmaz. Otomasyon ile fiziksel cihaz kanıtı birbirinden ayrılır.

| Test | Gereksinimler | Temel kabul |
|---|---|---|
| AT01 Başlangıç | FR01–FR03 | Rotasız açılış, izin, geçersiz veri |
| AT02 GPS durumu | FR04–FR08 | Yaş, iz kesintisi, pasiflik, temiz kapanış |
| AT03 Tercihler | FR09, FR25 | Saklama, bozuk veri, portal tercihi |
| AT04 Harita | FR10–FR13 | İçerik, dönüşüm, takip, üç ölçek |
| AT05 Etkileşim | FR14–FR15, FR27–FR29 | Pan, geri merkezle, düğme, kırpma |
| AT06 Ağ ve önbellek | FR16–FR22 | Gecikme, eski cevap, hata, geri çekilme |
| AT07 Kimlik | FR23–FR24, SEC02–SEC05 | Kod süresi, token, hesap izolasyonu |
| AT08 Açıklamalar | FR26, FR30–FR31, SEC01, SEC06–SEC07 | Atıf, izin, log ve tanılama |
| AT09 Rota | FR32–FR35 | GPX, limit, parça kaybı, rota dışı |
| AT10 FIT ve dönüş | FR36–FR38 | Kaydet/sil, senkronizasyon, yeniden açılış |
| AT11 Kaynak kullanımı | NFR01–NFR12 | Zaman, RAM, ağ, pil ve servis ölçümleri |
| AT12 Dağıtım | SEC08 ve geliştirme teslimatı | Temiz checkout, build, artefakt eşleşmesi |

### Zorunlu hata senaryoları

Harita isteği sürerken üç kez zoom değiştirilir; cevaplar ters sırayla döndürülür. Ekran son seçilen ölçeği korumalıdır. GPS kaybolurken internet açık kalır; GPS mesajı değişmeli ve harita servis hatası gösterilmemelidir. Bluetooth kesilirken GPS çalışır; konum ve varsa geçerli görüntü korunmalıdır.

Token süresi geçer, sunucu 429 ve 503 döndürür, görüntü boş gelir, metaveri yanlış boyut taşır, depolama dolar. Her durumda uygulama çökmeden kontrollü duruma geçmelidir. Token veya rota kimliği değiştirilerek başka hesabın verisi alınamamalıdır.

Fiziksel test raporu cihaz ve telefon sürümlerini, komutları, kaynak commit’ini, test süresini, beklenen/gözlenen sonucu ve kanıt yolunu içerir. Sahte veriyle alınan simulator görüntüsü açıkça Simulator olarak etiketlenir.

<!-- pagebreak -->

## 18 Gerçek cihaz ve iPhone test planı

Fiziksel saatin düğmelerine basmak, dışarıda yürümek ve iPhone durumlarını değiştirmek kullanıcı tarafından yapılır. AI ajanı kullanıcıya tek seferde uygulanabilir kısa bir saha kontrol listesi verir, teknik olarak yapabildiği diğer işleri ilerletir. Kullanıcı geri dönüşü olmadan donanım testini tamamlandı olarak işaretlemez.

| Profil | Kurulum | Beklenen davranış |
|---|---|---|
| H01 Normal | iPhone kilitli, GCM arka planda, internet açık | Harita yenilemeleri devam eder |
| H02 Telefon kullanımda | Safari/başka uygulama açık | Harita bağlantısı korunur |
| H03 GCM zorla kapalı | Kullanıcı GCM’yi kapatır | Gerçek sonuç kaydedilir; başarısızlıkta açık yönlendirme |
| H04 Internet yok | Telefonun interneti kesilir, Bluetooth açık | GPS çalışır; önbellek kapsamı dışında mesaj |
| H05 Telefon uzakta | Bluetooth menzili dışı | GPS ile takip; tekrar bağlanınca toparlanma |
| H06 GPS zayıf | Bina arası veya kapalı alan | Kalite ve yaş doğru; sahte hassasiyet yok |
| H07 Ekran yaşam döngüsü | Bilek indirme, ekran sönmesi, uygulamadan çıkma | Ölçülen platform davranışıyla tutarlı durum |
| H08 Soğuk açılış | Saat/telefon yeniden başlatılır | Eşleme/ayarlar bozulmaz; taze konum beklenir |

### Saha rotası

İlk örnek, bilinen açık alan ve birkaç kavşak içeren 20–30 dakikalık yürüyüştür. En az üç zoom seviyesi, manuel pan, bağlantı kesme ve geri dönme denenir. Ardından iki saatlik dayanıklılık oturumu yapılır. Uzun testte bütün güncel kaynaklar ve pil koşulları kaydedilir.

Konum doğruluğu değerlendirilirken GPS sensör hatası ile yazılımın haritaya yerleştirme hatası ayrılır. Başka bir telefonun GPS noktası mutlak doğru kabul edilmez. Harita dönüşümü sentetik kontrol noktalarıyla; saha kullanımı gerçek yol, kavşak ve iz tutarlılığıyla değerlendirilir.

### R1 ek senaryoları

Kesişen veya kendine dönen GPX rotası, birbirine yakın paralel yollar, çok kısa rota, çok parçalı rota, eksik son parça ve 50 km sınırındaki rota test edilir. FIT oturumu durdurulup kaydedilir, sonra Garmin Connect senkronizasyonunda incelenir. Harita uygulamasının ayrıca açılmış yerleşik Run aktivitesiyle eşzamanlı çalışması başlangıç varsayımı değildir.

<!-- pagebreak -->

## 19 AI ajanı için kod yapısı ve çalışma kuralları

Tek bir Git deposu önerilir. Ajanın devam edebilmesi için kararlar ve kalan işler sohbet belleğine bağımlı olmamalıdır. Aşağıdakiler oluşturulacak dosya ve klasörlerdir; bu raporla birlikte henüz bir uygulama deposu oluşturulmamıştır.

| Yol | İçerik |
|---|---|
| AGENTS.md | Ajanın proje içi çalışma kuralları |
| requirements.md | Bu şartnamenin sürümlü kopyası |
| apps/watch | Monkey C kaynakları, manifest, resources, testler |
| services/api | Python API, raster adaptörü, kimlik ve rota işleri |
| web | Basit portal şablonları ve statik dosyalar |
| contracts | OpenAPI, şemalar, yapay örnekler |
| tests/fixtures | Sentetik GPS, harita ve GPX örnekleri |
| docs/decisions | Mimari karar kayıtları |
| docs/evidence | Simulator ve fiziksel test raporları |
| docs/progress.md | Tamamlanan işler, sonraki adım, bilinen eksikler |
| scripts ve Makefile | Build, test, doctor, simulator ve paketleme |

### Ajan kuralları

Ajan önce mevcut projeyi ve yerel yönergeleri okumalı, sonra küçük çalışabilir adımlarla ilerlemelidir. API isimlerini belleğinden varsaymak yerine kurulu SDK belgelerinde doğrulamalıdır. forerunner165 hedefinde derlenmeyen özellik tamamlandı kabul edilmez. Sadece arayüz maketi gerçek GPS entegrasyonu yerine geçmez.

Sahte renderer ve GPS kaynakları test adaptörü olarak açıkça ayrılmalıdır. Gerçek modda sahte koordinata sessiz geçiş yapılmaz. Ajan gerçek cihaz testi yapamadığında kullanıcıdan kanıt gerektiren işi işaretler; bağımsız olarak tamamlayabileceği test, dokümantasyon ve hata düzeltmelerini sürdürür.

Her görev sonunda değişen dosyalar, çalıştırılan komutlar, geçen/kalan testler, hangi gereksinimlerin karşılandığı ve sonraki görev yazılmalıdır. Rastgele bağımlılık ekleme, SDK’yı depoya kopyalama ve firmware müdahalesi yapılmaz. SDK, geliştirici anahtarı, token ve gerçek konum logları Git dışında kalır.

Kullanıcı hedefi değiştirmedikçe yerel, geri alınabilir kod ve test işleri için her adımda yeniden onay istenmez. Hesap girişleri, fiziksel işlemler ve sağlayıcı seçimi gerektiğinde ajan somut ihtiyacı açıklar. Ücretli kaynak ve kamuya yayın bu şartnameyle önceden yetkilendirilmiş sayılmaz.

<!-- pagebreak -->

## 20 Aşamalı görev listesi ve teslimatlar

AI üretim hızı, platform sorunları ve kullanıcı saha testi süreleri bilinmediği için takvim garantisi verilmez. İlerleme tamamlanmış kanıtlı aşamalarla ölçülür. Bir sonraki aşama öncekinin kabulüne bağlıdır; yalnızca G0 araştırması sırasında bağımsız kurulum ve test altyapısı işleri beraber ilerleyebilir.

| Aşama | Görevler | Tamamlanma koşulu |
|---|---|---|
| G0 Fizibilite | Ortam, gerçek hedef build, GPS, raster, iPhone, kaynak ölçümü | POC01–POC08 sonuçları ve devam kararı |
| G1 Yerel çekirdek | Durum makinesi, sentetik harita, dönüşüm, düğmeler | AT01–AT05 simulator ve hedef build |
| G2 Çevrimiçi MVP | Harita servisi, eşleme, kaynak adaptörü, hata yönetimi | FR01–FR31 ve ilgili SEC maddeleri |
| G3 Saha kabulü | iPhone profilleri, pil, RAM, gecikme, düzeltmeler | M kapsamı fiziksel kanıtla kabul |
| G4 R1 | GPX, rota parçaları, rota dışı, FIT kaydı | FR32–FR38 ve AT09–AT10 |
| G5 Opsiyon | Offline paket, track up veya iOS yardımcı uygulama | Seçilen OF maddesi için ayrı kabul |

### Her aşamadaki zorunlu dosyalar

Kaynak kodu, bağımlılık kilitleri, çalıştırma yönergesi, test sonuçları, bilinen kısıtlar ve karar kayıtları teslim edilir. Saat derlemesi PRG, ilgili debug dosyaları ve kaynak commit referansıyla üretilir. Dağıtım aşamasında gerekiyorsa IQ paketi ayrıca hazırlanır; mağaza yayınlanması otomatik yapılmaz.

**G3 bitiş paketi:** Mac’te temiz checkout’tan çalışan build; desteklenen firmware/iOS/GCM matrisi; gerçek saat kurulum adımları; web/API başlatma ve HTTPS yapılandırması; veri akışı ve sağlayıcı koşulları; en az iki saat saha raporu; açık hata listesi; FR ve NFR izlenebilirliği.

### Hazır tanımı

İlgili gereksinimin davranışı, hata durumu, test yöntemi ve veri sözleşmesi açıklanmışsa görev başlamaya hazırdır. Kullanıcı hesabı gerektiren kısım yoksa ajan kendisi ilerler.

### Bitti tanımı

Kod derlenmiş, ilgili testler çalıştırılmış, regresyon görülmemiş, gerçek/sahte kanıt ayrılmış ve bilinen kısıtlar yazılmış olmalıdır. “Çalışması gerekir”, “simulator yok ama kod doğru görünüyor” veya yalnızca README hazırlanması tamamlanma sayılmaz.

<!-- pagebreak -->

## 21 Riskler ve bekleyen kararlar

| Risk | Etki | Çözüm ve karar noktası |
|---|---|---|
| iPhone arka plan aktarımı | Cepte harita yenilenmeyebilir | G0 ve H01; gerçek cihazda erken doğrulama |
| Grafik ve heap maliyeti | OOM veya takılma | G0 raster profili; palet, tek görüntü, bütçeli cache |
| API sürüm karışıklığı | Derleme veya cihaz hatası | SDK ve API ayrı sabitlenir; API 6.0 bağımlılığı yok |
| GNSS kalite kaybı | Yanlış konum algısı | Yaş ve kalite durumu; veri uydurmama |
| Harita lisansı veya kota | Kesinti veya ek masraf | Adaptör, açık haklar, günlük kota ve sağlayıcı kararı |
| Fazla istek ve pil tüketimi | Kısa kullanım süresi | Kamera eşiği, istek birleştirme, karşılaştırmalı test |
| MacBook’a bağlı servis | Dışarıda erişim kaybı | Geliştirme tüneli ile kalıcı servis ayrımı |
| AI ajanının yanlış tamamlandı beyanı | Gerçekte çalışmayan teslimat | PASS/FAIL/NOT RUN ve fiziksel kanıt zorunluluğu |
| Kalıcı harita alanının azlığı | Offline hedefinin karşılanmaması | OF01 fizibilitesi; çevrimiçi MVP korunur |

### Kullanıcıdan daha sonra alınacak bilgiler

İşe başlamadan önce macOS, iOS, GCM ve saat firmware sürümleri gerçek cihazlardan okunur. Harita sağlayıcısı hesabı ve servis barındırma seçimi G2’den önce gerekir. Telefon olmadan kullanım zorunlu hale gelirse G0 kapsamı genişletilmelidir; aksi halde offline özellik opsiyon olarak kalır.

Varsayılan kararlar bu raporda verilmiştir; ajanın her biri için tekrar soru sorması gerekmez. Kullanıcı tercih değiştirdiğinde karar kaydı ve etkilenen gereksinimler birlikte güncellenir. Mevcut belleğe veya depolamaya sığmayan bir gereksinim rastgele kaldırılmaz.

### Maliyet planlama modeli

Yerel geliştirme için mevcut MacBook, iPhone ve saat kullanılır. Olası yeni giderler harita sağlayıcısı, küçük HTTPS servis barındırma, alan adı ve AI ajanı kullanım ücretidir. Ayrı iOS uygulaması seçilirse Apple geliştirme/dağıtım ihtiyaçları yeniden incelenir.

Ajan tahmini maliyeti kullanım modelinden üretmelidir: aktif saat sayısı × saat başına yeni harita görünümü × görüntü boyutu; ardından sağlayıcı çağrı birimi ve önbellek oranı uygulanır. Rakamlar gerçek servis fiyatları doğrulanmadan para tutarı olarak sunulmamalıdır. Tek kullanıcılı kişisel MVP için kurumsal ölçek altyapı kurulması gerekli değildir.

<!-- pagebreak -->

## 22 AI ajanına verilecek başlangıç görevi

Aşağıdaki metin, bu Markdown dosyasıyla birlikte uygulamayı geliştirecek AI ajanına verilebilir. Talimat yalnızca ilk aşamayı başlatır; sonraki işler bölüm 20’deki sıralamayla yürür.

> Garmin Forerunner 165 için bu şartnameye göre harita uygulaması geliştir. Kullanıcının geliştirme ortamı kendi MacBook’unda macOS; telefonu iPhone. İlk ürün bağımsız bir Connect IQ Watch App olacak. Saatin GPS’ini kullanacak, gerçek harita üzerinde konum gösterecek ve rota yüklenmeden çalışacak. İlk sürümde iPhone üzerindeki Garmin Connect internet köprüsü kullanılacak.
>
> Önce şartnameyi ve varsa mevcut AGENTS.md yönergelerini oku. Mevcut çalışma dizinini, Git durumunu, macOS/CPU mimarisini, Java’yı ve Garmin SDK kurulumunu incele. Kullanıcının mevcut dosyalarını koru. SDK, firmware ve API seviyesini birbirine karıştırma. Desteklenmeyen API’yi tahmin ederek ekleme.
>
> İlk görevin G0 fizibilitesidir. Çalışma deposunu ve küçük bir Monkey C uygulamasını oluştur. forerunner165 hedefinde derle; simulator ve gerçek cihaz kurulum yönergelerini hazırla. GPS konumu, kalite ve veri yaşını göster. Sentetik harita üzerinde koordinat dönüşümünü uygula. Ardından küçük HTTPS test servisi üzerinden raster indirme deneyi ekle. Özel iOS uygulaması, geniş portal, GPX işleyicisi veya offline şehir haritasıyla başlama.
>
> make doctor, make test, make build-watch, make sim ve make api görevlerini oluştur. Sürüm ve ortam raporunu docs/evidence içine yaz. Anahtarları ve tokenları Git dışında tut; çıktılarda gizle. Harita servisi gerçek cihaz için erişilebilir HTTPS gerektiriyorsa somut seçenekleri ve gereken hesap bilgisini açıkla; localhost’u iPhone açısından MacBook gibi kabul etme.
>
> POC01–POC08’i sırayla çalıştır. Yapabildiğin yerel testleri tamamla. Fiziksel saat ve iPhone denemeleri için kullanıcıya kısa adımlar ver. Kullanıcı kanıtı bulunmayan testleri NOT RUN işaretle. Simulator başarısını gerçek saat başarısı diye sunma. Başarısız hedefleri değiştirmek yerine nedeni, ölçüm ve seçenekleri yaz.
>
> Görev sonunda kaynak dosyalarını, build çıktısını, test sonuçlarını, G0 yetenek matrisini, bilinen kısıtları ve sonraki görevi teslim et. İlerlemeni docs/progress.md dosyasına işle. Ücretli hesap açma veya kamuya yayın bu görevle yetkilendirilmiş değildir. Yerel kodlama ve geri alınabilir test işlerini her adımda yeniden izin istemeden tamamla.

**İlk beklenen somut sonuç:** 165 üzerinde GPS verisi ile coğrafi olarak eşlenmiş sentetik/gerçek bir raster görünümün çalıştığını gösteren küçük prototip. Bu sonuç, sonraki geliştirme kapsamını gerçek platform ölçümleriyle temellendirir.

<!-- pagebreak -->

## 23 Kaynaklar

Aşağıdaki kaynaklar platformla ilgili olguları destekler. Ürün kapsamı, endpoint isimleri, kabul eşikleri ve görev planı bu proje için önerilen mühendislik kararlarıdır; Garmin tarafından verilmiş garantiler değildir. Erişim tarihi 14 Eylül 2026’dır.

- **S1** [Garmin Connect IQ uyumlu cihazlar](https://developer.garmin.com/connect-iq/compatible-devices/) — Forerunner 165 ekranı ve katalogdaki API seviyesi.
- **S2** [Garmin SDK indirme ve geliştirici koşulları](https://developer.garmin.com/connect-iq/sdk/) — Mac SDK Manager, Monkey C uzantısı, SDK sürümü ve konum verisi koşulları.
- **S3** [Toybox Position](https://developer.garmin.com/connect-iq/api-docs/Toybox/Position.html) — GPS olayları, izin, aktif/pasif davranış ve koordinat örnekleri.
- **S4** [Position Info](https://developer.garmin.com/connect-iq/api-docs/Toybox/Position/Info.html) — Kalite kategorisi, null alanlar, zaman, yön ve hız birimleri.
- **S5** [WatchUi MapView](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/MapView.html) — Yerleşik harita arayüzü ve desteklenen cihazlar.
- **S6** [Toybox Communications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html) — Telefon köprüsü, makeWebRequest, makeImageRequest, görüntü seçenekleri ve sürüm sınırlamaları.
- **S7** [Application Storage](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html) — Saklanabilen türler, tek değer limiti ve toplam alanın cihaza bağlı olması.
- **S8** [ActivityRecording](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html) ve [Session](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording/Session.html) — FIT oturumu, kayıt ve kaydetme yaşam döngüsü.
- **S9** [Graphics Dc](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html) — Saat çizim yüzeyi için teknik başvuru.
- **S10** [OpenStreetMap standart tile kullanım politikası](https://operations.osmfoundation.org/policies/tiles/) — Standart servisin atıf, önbellek, toplu indirme ve offline kullanım sınırları. Başka sağlayıcıların sözleşmesi ayrıca incelenir.
- **S11** [OpenMTP resmî kaynak deposu](https://github.com/ganeshrvel/openmtp) — macOS MTP istemcisi, Apple Silicon dağıtımı ve Garmin desteği.
- **S12** [Forerunner 165 sistem ayarları](https://www8.garmin.com/manuals/webhelp/GUID-607F08F6-33FC-40BF-9727-84E54043D82D/EN-US/GUID-AF421384-7597-4D79-9D4B-AD4AEB53A2E2.html) — MTP/Garmin USB modları ve sistem yapılandırması.
- **S13** [dwMap arka plan haritaları](https://dynamicwatch.zendesk.com/hc/en-us/articles/360007147952-dwMap-Background-Maps) — 165 üzerinde harita gösterimi için mevcut ürün örneği; bu projenin performans garantisi olarak kullanılmaz.

**Kanıt sınırı:** Bu rapor resmî dokümantasyon ve ürün hedeflerinden hazırlanmıştır. Kullanıcının saatine, iPhone’una veya MacBook’una doğrudan erişilmemiştir. G0 sırasında gerçek cihaz bulguları bu belgenin ölçüm gerektiren alanlarını tamamlayacaktır.

[S1]: https://developer.garmin.com/connect-iq/compatible-devices/
[S2]: https://developer.garmin.com/connect-iq/sdk/
[S3]: https://developer.garmin.com/connect-iq/api-docs/Toybox/Position.html
[S4]: https://developer.garmin.com/connect-iq/api-docs/Toybox/Position/Info.html
[S5]: https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/MapView.html
[S6]: https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html
[S7]: https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html
[S8]: https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html
[S9]: https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html
[S10]: https://operations.osmfoundation.org/policies/tiles/
[S11]: https://github.com/ganeshrvel/openmtp
[S12]: https://www8.garmin.com/manuals/webhelp/GUID-607F08F6-33FC-40BF-9727-84E54043D82D/EN-US/GUID-AF421384-7597-4D79-9D4B-AD4AEB53A2E2.html
[S13]: https://dynamicwatch.zendesk.com/hc/en-us/articles/360007147952-dwMap-Background-Maps
