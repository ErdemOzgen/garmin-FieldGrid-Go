# İlerleme — 14 Eylül 2026

## Mevcut sonuç

**Çalıştırılabilir G0 prototipi hazır; G0 saha geçişi henüz kabul edilmedi.**
Kullanıcı şartnamesi korunarak Monkey C saat uygulaması, Python test servisi,
otomatik testler, sürüm kilitleri ve GitHub kaynak teslim düzeni oluşturuldu.

Tamamlanan yerel işler:

- Gerçek **Forerunner 165 / fr165** hedefinde uyarısız PRG derlemesi.
- START ile başlayan gerçek GPS adaptörü, kalite/yaş/yön, sınırlı ve segmentli iz.
- Kuzey yukarı sentetik alan, zoom, pan, takip, tema, profil ve tanılama ekranları.
- Nesil/oturum koruması, tek harita işi, atomik raster, timeout ve geri çekilme.
- Üç PNG boyutu, sürümlü OpenAPI, HMAC görüntü yetkisi, gövde/kota/cache sınırları.
- İzole `.venv`, özel dosyalar için Git dışlama, CI ve kaynak paketleme.
- Hedef simülatörde **15 Monkey C testi**: koordinatlar, yaş/kalite, halka tampon,
  stale callback, invalid metadata, backoff, düğmeler, raster/ekran çizimi ve metin sınırları.
- **49 Python API/geometri testi**, %100 API satır kapsamı ve gerçek yerel HTTP deneyi. Kesin son sayılar
  `docs/evidence/automated.json` içindedir.

## Çalıştırılan doğrulamalar

`make doctor`, `make test`, `make build-watch`, `make test-watch`, `make contracts`,
`make audit`, `scripts/http_smoke.py`, `make evidence`, `make package`.
Güvenlik taraması çalışma zamanı bağımlılıklarında bilinen açık bildirmedi.
Python test araçlarında iki upstream deprecation uyarısı var; test başarısı
bundan etkilenmiyor. Simulator PRG ve fiziksel PRG farklı dosyalardır.

Kaynak ZIP’i başka bir geçici klasöre açılıp yeni Python 3.14 `.venv` ile kilitli
bağımlılıklar sıfırdan kuruldu. Bu kopyada 49 test ve `fr165` derlemesi de geçti;
orijinal `.local` dosyaları kullanılmadı. İlk denemede macOS Python 3.9 seçildiği
için kurulum başarısız oldu; setup’a hem Python hem mevcut venv sürüm kontrolü
eklendi. Yeni temiz ortamda mevcut Python 3.14 açıkça seçilerek kurulum doğrulandı.

## Açık işler / kısıtlar

1. Mac kilidi açılınca görsel kontrol; özellikle Türkçe metinler ve gerçek saat düğmeleri.
2. Fiziksel GPS, ekran yaşam döngüsü, bitmap/Object Store davranışı, iPhone/GCM
   köprüsü, 30 dakikalık normal bağlantı ve iki saat dayanıklılık.
3. Saha için kullanıcının seçeceği özel HTTPS sunucu. Yerel servis dışarıdan erişilebilir değildir.
4. G0 geçince G1/G2: lisanslı gerçek sokak/patika sağlayıcısı, hesap eşleme,
   token yenileme/iptal, tercihler portalı ve sağlayıcı atfı. Bu sürüm gerçek harita değildir.
5. GPX içe aktarma / FIT / offline şehir paketi R1 veya opsiyon; uygulanmadı.

SDK bu çalışma için `/tmp` altında tutulur; geçici dizin temizlenirse SDK yeniden
edinilip yerel yol güncellenmelidir. Garmin cihaz/font verileri SDK Manager’ın
standart kullanıcı cache’indedir. Global Python paketleri veya shell profili değişmedi.

## Sonraki görev

Kullanıcı eve dönüp Mac’i açtıktan sonra `docs/field-test.md` listesinin 1. bölümünü
uygula. Ardından uygun HTTPS deneyi ve fiziksel saat kanıtlarını topla. Fiziksel
kanıt olmadan G0/G3’ü PASS işaretleme veya gerçek sokak haritası MVP’si diye sunma.
