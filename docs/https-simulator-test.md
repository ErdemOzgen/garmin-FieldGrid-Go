# Geçici HTTPS simülatör deneyi

Bu adım kullanıcı onayıyla çalıştırılır. Normal `make api` ve `make sim` hiçbir
tünel açmaz. Fiziksel saat/iPhone kabulü bu deneyin kapsamına girmez.

## Gereken erişim

`makeWebRequest` localhost üzerinde metadata alabiliyor. Ancak Garmin'in görüntü
dönüştürme servisi görüntü URL'sini dışarıdan almalıdır. SDK 9.2.0/fr165 deneyinde
localhost `makeImageRequest` sonucu HTTP 200 + null oldu; uygulama bunu -903
olarak işledi ve GPS devam etti. [Garmin ekibinin açıklaması](https://forums.garmin.com/developer/connect-iq/f/discussion/256721/connect-mobile-4-40-makeimagerequest-localhost-error/1226813)
bu ayrı görüntü işleme yolunu doğrular.

Önerilen deney: resmî Cloudflare `cloudflared` aracıyla yalnızca
`http://127.0.0.1:8765` servisine yönlenen, rastgele `*.trycloudflare.com` HTTPS
adresi. API kod/dosya sunmaz. Render oluşturmak rastgele cihaz tokenı ister;
PNG erişimi 120 saniyelik HMAC imzası kullanır. Sağlık ve API şeması herkese
açıktır. IP ve istek trafiği Cloudflare üzerinden geçer; Garmin dönüştürücüsü
sentetik PNG'leri ve kısa ömürlü görüntü URL'lerini görür.

Yalnızca etiketli sentetik koordinatlar/haritalar kullanılacak. Test süresi en
fazla 30 dakika; ardından tünel durdurulacak ve yerel URL ayarları geri yüklenecek.
Hesap, DNS veya ücretli kaynak oluşturulmayacak. Araç `/tmp` içinde tutulacak;
sistem paketi/servisi kurulmayacak. Anahtar ve tünel günlükleri Git'e alınmayacak.

## Uygulama sırası

1. Kullanıcının bu somut erişime onayını al.
2. `.env` ve `.local/watch.json` dosyalarını Git dışına 0600 izinle yedekle.
3. `cloudflared tunnel --url http://127.0.0.1:8765 --no-autoupdate` çalıştır.
4. Oluşan HTTPS origin'i iki yerel yapılandırmaya işle; servis/simülatörü yeniden başlat.
5. Sentetik GPS ile 195/256/390 px, iki tema, üç zoom ve ağ kesilmesini dene.
6. Ölçümleri/screenshotları kaydet; tüneli kapat; yerel yapılandırmayı geri yükle.
7. Fiziksel PRG'yi yerel HTTP/token olmadan tekrar derle ve kaynak paketini yenile.

Bu deneme üretim barındırması değildir. [Cloudflare Quick Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/)
belgesi ücretsiz, geçici adresin herkese açık olduğunu ve SLA sağlamadığını
belirtir; aynı sayfada hizmet koşulları ve gizlilik bağlantıları bulunur.

## Gerçekleşen deney

Kullanıcı 14 Eylül 2026'da bu deneyi açıkça onayladı. 18:49:58–19:12:03 UTC
arasında 1324,5 saniye çalıştı; tünel süreci çıkış kodu 0 ile kapandı. API de
durduruldu, `.env` ve `.local/watch.json` özgün içerikleriyle 0600 izinle geri
yüklendi; simülatörün cihaz HTTPS gerekliliği yeniden etkinleştirildi. Hesap/DNS
veya kalıcı servis oluşturulmadı. Ayrıntılı sonuç [simulator.json](evidence/simulator.json).
Tekrar çalıştırma yeni, süreli yayın izni gerektirir.
