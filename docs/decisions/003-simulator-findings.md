# ADR 003 — Simülatörde doğrulanan aktarım ve depolama sınırları

14 Eylül 2026. Yerel uygulama kararı; fiziksel G0 kabulü değildir.

- CIQ JSON sözlüğündeki ondalıklı koordinatlarla 3,609287 m sınır sapması görüldü.
  `Geo.coordinateText` koordinatları sekiz ondalıklı metin olarak gönderir; API
  sabit ondalık metni veya JSON sayısını doğrulayarak float'a çevirir. NaN,
  Infinity, boolean, metin üstel gösterimi ve aralık dışı değer reddedilir.
  İki metre raster sınır kontrolü gevşetilmedi. Sonraki HTTPS rasterları bu
  kontrolü geçerek ekrana yerleşti; hassasiyet regresyonu iki tarafta test edilir.
- Garmin dönüştürücüsü localhost PNG'sini alamadı: HTTP 200 + null, uygulama -903.
  Kullanıcı onayıyla geçici Cloudflare HTTPS adresi kullanıldı. Gerçek GPS veya
  gerçek harita sağlayıcısı kullanılmadı. Tünel 22 dakika sonra, 19:12:03 UTC'de kapatıldı; yerel ayarlar geri alındı.
  [Garmin ekip açıklaması](https://forums.garmin.com/developer/connect-iq/f/discussion/256721/connect-mobile-4-40-makeimagerequest-localhost-error/1226813)
  görüntü dönüştürmenin harici servisten geçtiğini doğrular.
- SDK macOS Anahtar Zinciri yanıtını beklerken ana UI iş parçacığı bloke oldu;
  kullanıcı izin penceresini tamamladı. Parola okunmadı veya kaydedilmedi.
- Eski Application.Properties değerleri yeni derlemenin varsayılanını
  gölgeleyebildi. Yerel servis yapılandırması artık Git dışındaki derleme kaynak
  dizisinde; dil kaynaklarında da aynı değerler derlenir. Çevrimdışı simülatör
  ayrı dosya üretir ve ağ servisi kullanmaz.
- Büyük Object Store sınır denemesi `Storage.setValue` içinde yakalanamayan OOM
  ile çöktü. Hangi büyük değerde oluştuğu ölçülmedi; 32 KB kapasite PASS değildir.
  Canlı menüde yalnız 1024 ASCII karakter yaz/oku/içerik karşılaştır/sil testi
  kalır. Büyük kapasite/bitmap/reboot ayrı ve henüz yapılmamış deneylerdir.
- Türkçe BACK metni yuvarlak alanda kırpılıyordu. Kısaltıldı; uzun menü öğeleri
  küçük fonta geçer. Tema değişiminde eski raster korunurken etiket/ölçek
  kontrastı kendi arka planıyla korunur. Başarılı görüntü sayısı deneme sayısından
  ayrıldı; henüz raster yokken yüklenmiş gibi boyut etiketi gösterilmez.

Etkileşimli simülatör 90 saniyede kesilmez. İlk bağlantı için en fazla üç deneme
vardır. Otomatik test 90 saniye sınırını korur; başarısız yeni test eski PASS
sonucunu kullanamaz. Bu değişiklikler sistem Python'una veya shell ayarlarına
kurulum yapmaz.

Son İngilizce kontrolde BACK açıklaması 171 px ile 168 px güvenli alanı aştı.
“BACK to map” 154 px oldu; iki dil testi ve İngilizce menü görüntüsüyle doğrulandı.
Ağ deneyi bu tek metin değişikliğinden önceydi; kaynak kimlikleri kanıtta ayrı tutulur.
