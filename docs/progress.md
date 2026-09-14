# İlerleme — 14 Eylül 2026

**G0 prototipinin yerel geliştirme ve simülatör teslimi hazır. Fiziksel G0 geçişi bekliyor.**
Kullanıcının “şimdilik yalnızca simülatörle ilerle” seçimi uygulandı. Gerçek
Forerunner 165 ve iPhone kanıtı olmadan G0/G3 PASS değildir.

## Tamamlanan işler

- Monkey C Watch App, `fr165` hedefi, START ile GPS, kalite/yaş/yön ve 180 noktalı iz.
- Zoom z14/15/16, iki eksende kaydırma, BACK ile takip, gündüz/gece ve EN/TR arayüz.
- Atomik raster/metaveri, eski callback reddi, tek ağ işi, timeout ve sınırlı retry.
- FastAPI sentetik raster servisi, 195/256/390 px, HMAC yetkisi, kota/gövde/cache sınırları.
- `.venv`, sürüm kilitleri, CI, sır taraması, kaynak ZIP'i ve kurulum yönergeleri.
- **56 Python testi PASS; API satır kapsamı %100 (182 satır).**
- **17 Monkey C testi EN ve TR dillerinde PASS.** Kesin kaynak/artefakt özetleri
  [otomatik kanıtta](evidence/automated.json) ve dil test kayıtlarında tutulur.

## Simülatörde gözlenenler

Kullanıcı onaylı Cloudflare HTTPS deneyi 18:49:58–19:12:03 UTC arasında yaklaşık
22 dakika sürdü. Yalnız sentetik konum/PNG kullanıldı. Tünel durduruldu, API
kapatıldı, `.env` ve saat yapılandırması geri yüklendi; kalıcı yayın yapılmadı.

195/256/390 px boyutların gündüz/gece kombinasyonları, zoom, kaydırma/merkezleme,
Türkçe ekranlar, GPS kalite kaybı ve toparlanması ekran görüntüleriyle doğrulandı.
API kapatılınca raster korundu, GPS sayacı 360'tan 485'e ilerledi; API açılınca
manuel tekrar olmadan görüntü sayacı 12'den 13'e çıktı. İz 180 noktada kaldı.
Depolama menüsünde 1024 karakter yaz/oku/karşılaştır/sil PASS.

[Simülatör kaydı](evidence/simulator.json), [görüntüler](evidence/screenshots),
[bulgu kararları](decisions/003-simulator-findings.md) ve [G0 matrisi](evidence/g0.md)
ölçümleri ve sınırlarını açıklar. HTTPS deneyinden sonra yalnız İngilizce BACK
etiketi kısaltıldı; bu değişiklik ayrı görsel ve iki dil testleriyle doğrulandı.

## Bulunan ve düzeltilen hatalar

CIQ JSON sayılarının koordinat hassasiyeti kaybı sekiz ondalıklı metin aktarımıyla
çözüldü; coğrafi sınır toleransı gevşetilmedi. Eski Properties yapılandırması yeni
build'i gölgelediği için derleme kaynaklarına geçildi. Büyük Storage deneyi OOM
ile çöktü; canlı menü güvenli 1K deneyiyle sınırlandı. Türkçe kırpılma, İngilizce
BACK genişliği, tema geçişi kontrastı ve hatalı başarılı-görüntü sayacı düzeltildi.
Yerel PNG, Garmin dönüştürücüsünden alınamadı; `make sim-offline` açık ağsız deneme
sunar. İnteraktif simülatör artık 90 saniyede kesilmez.

## Doğrulama ve kalan sınırlar

`make test`, `make build-watch`, `make test-watch`, `make contracts`, `make evidence`,
`make package` çalıştırıldı. Bağımlılıklar değişmedi; önceki `make audit` 14 çalışma
zamanı bağımlılığında bilinen açık bildirmedi. Test araçlarından gelen iki upstream
Python deprecation uyarısı sürüyor. Çevrimdışı fiziksel/simülatör derlemesindeki iki
uyarı boş Türkçe ConfigBaseUrl/ConfigDevToken kaynakları içindir; bu değerler ağ
servisi kapalı olduğu için bilerek boştur. HTTPS/test PRG derlemesi uyarısızdır.

Son kaynak ZIP'i ayrı bir geçici klasöre açıldı: özgün `.local` ve anahtarlar
olmadan 56 test ve `fr165` derlemesi PASS. Bu kontrol mevcut izole `.venv`
bağımlılıklarını kullandı; sıfırdan bağımlılık kurulumunun tekrarı değildir. Önceki
kurulum deneyinde yeni Python 3.14 `.venv` ile 49 test ve hedef derleme geçmişti.
SDK `/tmp` altındadır; temizlenirse yeniden edinilmelidir. Global Python paketi
kurulmadı; shell profili değiştirilmedi.

Fiziksel GPS, iPhone/GCM kilitli ekran ve 30 dakika bağlantı, BT/internet ayrımı,
ekran yaşam döngüsü, gerçek heap/grafik maliyeti, depolama sınırı/bitmap/reboot,
iki saat dayanıklılık ve pil **NOT RUN**. Saat bağlanması bu teslim için istenmiyor.

Sonraki aşama: kullanıcı fiziksel denemeyi istediğinde [saha listesi](field-test.md).
G0 kabulünden sonra lisanslı sokak/patika sağlayıcısı, kalıcı HTTPS ve G2 eşleme
kararları gerekir. Bu teslim gerçek sokak haritası MVP'si veya R1 GPX/FIT/offline
şehir paketi değildir.
