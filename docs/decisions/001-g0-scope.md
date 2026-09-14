# ADR 001 — G0 sınırı ve araç hedefi

Durum: kabul edilen yerel uygulama kararı, 14 Eylül 2026.

Gereksinim bölümleri 5, 20 ve 22, fiziksel GPS/raster/iPhone doğrulaması olmadan
sonraki aşamaya geçilmemesini ister. Bu nedenle ürün G0 prototipi olarak teslim
edilir. Geniş portal, hesap eşleme, gerçek harita sağlayıcısı, GPX işleme, FIT kaydı
ve offline paket yapılmadı. Bunların yerine geçiyormuş gibi demo ekranı sunulmaz.

Tek Monkey C Watch App + tek FastAPI süreci seçildi. Alternatif, daha ilk günden
vektör renderer/özel iOS uygulaması kurmaktı; cihaz yeteneği henüz fiziksel olarak
ölçülmediğinden bunun ek maliyeti ve riski gerekçelendirilemiyor. Raster adaptörü
küçük ve değiştirilebilir tutuldu. Python yalnız `.venv` içinde.

Garmin SDK Manager’ın **Forerunner 165** paketi `deviceId=fr165`, ekran
390×390, API 5.2, Watch App limiti 786432 bayt bildiriyor. Gereksinimde kullanılan
`forerunner165` adı gerçek CLI kimliği olmadığı için `make build-watch` **fr165**
hedefini kullanır. Başka modele düşülmez. `compiler.json` içindeki firmwareVersion
cihaz paketinin bilgisi olup kullanıcının saatinden okunmuş sürüm değildir.

SDK sürümü 9.2.0 ve cihaz paketinin kimliği `toolchain.lock.json` içinde sabittir.
SDK indirme sayfasındaki yayın tarihi ile arşiv kataloğunun tarihi farklı olabilir;
kanıt, indirilen `2026-06-09-92a1605b2` arşivinin SHA256’sı ve gerçek araç çıktısıdır.

Simülatör testi `drawScaledBitmap` fonksiyonunun bu modelde bulunmadığını gösterdi.
Yerine cihazı destekleyen `drawBitmap2` + `AffineTransform` kullanıldı. Minimum
uygulama API’si bu fonksiyon için **4.2.1** seçildi; cihazın API 5.2 desteğiyle
karıştırılmaz. Görüntü dönüşümleri ve font boyutları simülatörde çalıştırıldı.

G0 sonrasında gerçek raster sağlayıcısı seçilirken sunucuda işleme, yeniden
boyutlandırma, cache, atıf ve maliyet hakları ayrıca doğrulanacak. Standart OSM tile
sunucusuna otomatik istek veya toplu indirme yapılmadı.

Kaynaklar: [Garmin SDK](https://developer.garmin.com/connect-iq/sdk/),
[Graphics Dc](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html),
[Communications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html).
API isimleri ayrıca indirilen SDK’nın yerel belgeleri ve cihaz simülatörüyle doğrulandı.
