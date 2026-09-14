# ADR 002 — Konum, kamera ve ağ işlerinin ayrımı

`GpsState` kullanılabilir GPS verisinin kalite, UTC zaman ve monoton alım yaşını
doğrular. Null/bozuk/kutup dışı veri reddedilir; 0,0’a varsayılan dönüşüm yoktur.
Garmin’in son bilinen veya kötü kaliteli konumu güncel fix sayılmaz. Hareket izi
180 noktalı halkadır; 3 m hareket veya 5 s geçişinde nokta ekler ve kesintide segmenti
ayırır. UTC saati geri giderse daha eski fix kullanılmaz. Monoton sayacın taşması
taze konum gibi değerlendirilmez.

`MapState` kamera, zoom, stil ve nesil numarasını yönetir. Tek mantıksal iş vardır.
Yeni kamera hareketleri kuyruk oluşturmaz; istenen son alan tutulur. `MapJob`
metaveri ve görüntüyü sırayla indirir, her callback’te oturum/iş kimliği ve nesil
kontrol edilir. Kimliği/dönüşümü/boyutu doğrulanmayan görüntü etkinleşmez.

Mevcut raster, kendi coğrafi sınırlarında çizilir. Pan/zoom sırasında uygun
coğrafi dönüşüm uygulanır; eski resim yeni alana aitmiş gibi yeniden etiketlenmez.
G0 yerel ızgara, gerçek raster sağlayıcısı sayılmaz ve daima sentetik olarak görünür.
İkinci bitmap cache’i eklenmedi; canlı görselin yanına gelen resim atomik geçiş için
kısa süreli bulunur. Gerçek grafik maliyeti saha ölçümü bekler.

İş başlangıçları arasında en az 5 s vardır. 25 s zaman aşımı ve 2/4/8/16/30 s +
0–500 ms jitter geri çekilmesi uygulanır. 429 gövdesindeki `retryAfterSec` kullanılır.
401/403/413/422 veya bozuk şema otomatik tekrar edilmez; hareket etmek bu hataları
sıfırlamaz. Kullanıcı Retry service seçerek açıkça tekrar deneyebilir.

API, 2 KiB istek gövdesi, izinli üç zoom/üç boyut/iki stil ve 30 render/dakika ile
sınırlıdır. G0 için tek geliştirme cihazı tokenı yeterlidir; G2 cihaz eşleme/yenileme
ve iptal akışları henüz uygulanmamıştır. Görüntü erişimi ayrı, belirli render kimliğine
bağlı HMAC ve 120 s süre içerir. Cihaz tokenı URL’ye konmaz. Cache en fazla 24 raster
tutar, yalnız RAM’dedir; süre dolan girdiler yeni render sırasında temizlenir.
Sunucu yeniden başlatılırsa URL’ler ve cache geçersiz olur; yeni render istenir.

G0 tek süreci bilinçli seçer. Birden fazla worker, bellekteki imza/cache durumunu
paylaşmayacağı için desteklenmez. G2’de gerekirse paylaşılan depoya geçilir.
