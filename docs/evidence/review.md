# Teslim öncesi karşı inceleme

İncelenen kapsam: G0 kaynakları, çalıştırma komutları ve tamamlanma iddiaları.
Güven sınırları, doğruluk/kanıt ve işletim/toparlanma ayrı açılardan incelendi.

## Critical findings

None. Mevcut G0 kapsamı için açık, doğrulanmış kritik kusur kalmadı.

## Important findings

- **Kabul sınırı:** `docs/evidence/g0.md` POC02/04/08 NOT RUN. Fiziksel GPS,
  Garmin/iPhone aktarımı ve pil sonucunu yerel testlerden çıkarmak yanlış olur.
  Etki: G0/G3 kabulü. Düzeltme: fiziksel test listesini tamamlamadan aşama geçilmemesi.
- **Ürün kapsamı:** `services/api/renderer.py` sadece sentetik raster üretir.
  Etki: gerçek sokak/patika talebi henüz karşılanmaz. Düzeltme: G0 sonrası
  lisanslı sağlayıcı kararı ve G2 adaptörü; README bu sınırı açıkça belirtiyor.

## Minor findings

- SDK geçici dizinde; temizlenince `make doctor` eksik aracı gösterir. Kalıcı SDK
  yolu `docs/setup.md` ile yeniden verilebilir. Otomatik sistem kurulumu eklenmedi.
- Python test bağımlılıklarının iki deprecation uyarısı var. Uygulama çalışma
  zamanına ait hata değil; kilit güncellemesinde yeniden değerlendirilmeli.

## Open questions

Gerçek firmware/iOS/GCM sürümleri, cihaz heap/grafik maliyeti, H01 bağlantı sonucu,
bitmap kalıcılığı ve barındırma/sağlayıcı kararı fiziksel kullanıcı kanıtı bekliyor.
Bunlar doğrulanmış kod hatası olarak sınıflandırılmadı.

## Recommended corrections

Uygulandı ve geri dönüş testi eklendi: kalıcı 401’in pan ile tekrar başlatılmaması;
non-ASCII Authorization/signature girdisinin kontrollü 401/403 olması; aşırı
gövdenin ilave tampon kopyasından önce reddi; stale callback’in yeni işi
serbest bırakmaması; derleme raporunun kaynak/artefakt SHA256 eşleştirmesi.

İkinci inceleme: String içerik eşitliği, modelde desteklenmeyen grafik çağrısı,
coğrafi resim eşleşmesi, kamuya yayın ve anahtar sızıntısı tekrar kontrol edildi.
G0 tek geliştirme tokenının üretim kimlik sistemine eşdeğer olduğu iddiası yoktur;
G2 eşleme eksikliği bu aşamada gizlenmiş bir auth özelliği olarak sunulmaz.
