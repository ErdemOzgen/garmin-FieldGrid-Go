# Güvenlik ve veri sınırları

Bu sürüm kişisel **G0 testi** içindir. İnternete açık çok kullanıcılı hizmet veya
üretim kimlik sistemi değildir. Sağlayıcı seçimi ve servis yayını henüz yapılmadı.

Konum kullanımı saatte START / Open map ile başlar; oturum sonunda GPS aboneliği,
zamanlayıcı ve ağ işleri kapatılır. Çevrimiçi modda istenen alan Garmin Connect ve
API üzerinden geçer. Tam hareket izi sunucuya gönderilmez; iz saatin RAM’inde kalır.
Konum/URL/token erişim logları devre dışıdır. API validation yanıtları kullanıcı
girdilerini geri yansıtmaz. Harita sağlayıcısı henüz yoktur; yalnız sentetik raster
üretilir. Hesap e-postası, aktivite kaydı veya kişisel rota tutulmaz.

Fiziksel saatte yalnız geçerli HTTPS origin kabul edilir. HTTP sadece açıkça
seçilmiş `127.0.0.1:8765` simülatör derlemesinde kullanılır. Sertifika doğrulaması
kapatılmaz. Uygulama bir rastgele URL proxy’si değildir. JSON ek alanları reddeder.

G0 özel cihaz tokenı `.env` ve `.local/watch.json` içinde, imzalama anahtarı
`.local/keys` içinde saklanır. Dosyalar Git dışında ve 0600 iznindedir. Token
üretim hesabına erişim vermez; servis sadece test rasterlarını sunar. İptal etmek
için bu tokenı iki uçta değiştirin ve servisi yeniden başlatın. G2’de kısa erişim
tokenı, yenileme ve cihaz kaldırma ayrıca geliştirilecektir.

Görüntü URL’si 120 s boyunca yalnız belirtilen render’a erişim sağlar. Ağ tekrarları
için bu süre içinde yeniden alınabilir. Eski URL veya farklı render kimliği reddedilir.
Reverse proxy kurulursa query string, gövde ve Authorization loglanmamalı;
kamusal analitik eklenmemeli. Cache kalıcı değil, kapasite sınırına sahiptir.

`make check-secrets` bilinen sır biçimlerini, mevcut yerel tokenı ve Git’e girmemesi
gereken dosyaları kontrol eder. Tüm olası sırları bulan bir DLP sistemi değildir.
`make audit` sabitlenmiş çalışma zamanı bağımlılıklarını kontrol eder. GitHub’da
secret scanning etkinleştirilebilir; özel saha verisini `docs/evidence/private/`
altında tutun ve paylaşmadan önce kendiniz gözden geçirin.

Sorun raporuna token, görüntü URL’si veya gerçek koordinat eklemeyin. Proje henüz
kamuya yayınlanmadığı için güvenlik iletişim kanalı repo sahibi tarafından yayın
sırasında belirlenecektir.
