# G0 protokolü

`openapi.json`, `make contracts` ile çalışan Pydantic modellerinden üretilir.
Örnekler yapay 52°N / 5°E kontrol noktasıdır; kullanıcıdan alınmış konum değildir.

`POST /v1/map-renders` gövdesinde şema sürümü, istek nesli, koordinat, zoom, boyut
ve stil vardır. Görsel, konum işareti ve iz içermez. Coğrafi sınırlar piksel
**kenarlarını** belirtir: `[minX, minY, maxX, maxY]`, EPSG:3857, metre.
Üç raster boyutu aynı 390 ekran pikseline karşılık gelen coğrafi alanı kapsar.
Üst-sol piksel sınırı `(minX,maxY)`; piksel merkezleri yarım piksel içeridedir.

Harita tanımı `renderId` ve iki dakika geçerli `imageUrl` döndürür. `GET` görüntü
ucunda başka render kimliğine ait imza çalışmaz. Yanıttaki `X-Render-Id` HTTP testinde
kontrol edilir; Garmin görüntü callback’i başlık sağlamadığı için saat kimliği
doğrulanmış URL + nesil + bekleyen metaveri + boyut kontrolüyle atomik geçiş yapar.

400 ailesi / 429 hataları `code`, `retryable`, `retryAfterSec`, `requestId` taşır;
validation girdi değerlerini yansıtmaz. Varsayılan loopback servisinde token
zorunlu değildir; `make dev-config` bunu yerelde de etkinleştirir. Uzak HTTPS
origin ayarlanırsa token olmadan servis açılmaz. Hesap tokenı URL’ye konmaz.

Eşleme, config, rota ve cihaz kaldırma uçları G2/R1’e aittir; sahte başarılı
yanıtlar veren stub uçlar eklenmedi.
