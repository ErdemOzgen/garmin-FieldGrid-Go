# İzole geliştirme ortamı

## Python

`make setup`, mevcut Python’dan `.venv` oluşturur ve `requirements-dev.lock`
içindeki tam sürümleri kurar. Sistem Python’una, Homebrew’e, shell başlangıç
dosyalarına veya global Node paketlerine yazmaz. `requirements.lock` yalnızca
çalışma zamanı bağımlılıklarını içerir. Kilit güncellenirse güvenlik taraması ve
testler yeniden çalıştırılmalıdır. `pyproject.toml` doğrudan bağımlılıkları açıklar.

macOS’un `/usr/bin/python3` komutu 3.9’a işaret edebilir. Setup bunu kontrol eder
ve paket kurmadan durur. Mevcut modern Python’u açıkça seçebilirsiniz:

```sh
make setup PYTHON=/opt/homebrew/bin/python3
```

Bu örnek Apple Silicon Homebrew yoludur; yeni Python kurulumu yapmaz.
Önceden farklı Python ile açılmış `.venv` varsa setup onu sessizce kullanmaz.
O sanal ortamı kaynak ağacının dışına taşıyıp doğru Python ile yeniden oluşturun.

## Garmin SDK

Resmî [SDK Manager](https://developer.garmin.com/connect-iq/sdk/) ile **SDK 9.2.0**
ve Devices → API level 5.2 → **Forerunner 165** paketini edinin. Gerekirse Garmin
girişini kendiniz tamamlayın. Tüm cihazları indirmek gerekmez. SDK’yı Git’e eklemeyin.

Bu Mac’te SDK, sistem kurulumuna dokunmadan `/tmp/fr165-tools/sdk` altında
hazırlandı. Geçici dizin macOS tarafından temizlenebilir. `.local/toolchain.json`
bu yerel yolu tutar; kaynak depoya girmez. SDK Manager’ın cihaz ve font paketleri
kendi standart kullanıcı dizinindedir: `~/Library/Application Support/Garmin/ConnectIQ`.
Bu araç verileri Python base ortamının parçası değildir.

Kalıcı, kullanıcı tarafından seçilen başka bir SDK dizini için:

```sh
export CIQ_SDK_HOME="/path/to/connectiq-sdk"
make doctor
```

Komut yalnızca bu terminalin ortamını değiştirir. Alternatif olarak
`.local/toolchain.json` içindeki `sdk` yolunu güncelleyin. `watch.py` ayrıca
SDK Manager’ın etkin SDK dosyasını ve `Sdks` klasörünü bulur.

Derleyici Java ile çalışır. Bu Mac’te mevcut Temurin 11 kullanıldı. Gerektiğinde
`CIQ_JAVA_HOME` verilebilir; Java, Rosetta veya sistem güvenliği için otomatik
kurulum/değişiklik yapılmaz. SDK 9.2.0 simülatör paketi arm64 ve x86_64 içerir.

`make build-watch` yerel `.local/keys/developer.der` anahtarını bir kez üretir
(4096-bit RSA, PKCS#8 DER, dosya izni 0600). Var olan anahtar korunur.
`CIQ_DEVELOPER_KEY` ile kendi anahtarınızı gösterebilirsiniz. Anahtarı yedeklemek
size aittir; Git’e veya sohbete koymayın.

## Simülatör

`make sim` simülatörü açar ve uygulamayı gönderir. Masaüstü oturumu açık olmalıdır.
İlk açılışta bağlantı hazır değilse görev kısa aralıklarla en fazla üç kez dener.
Etkileşimli `make sim` uygulama kapanana kadar çalışır; 90 saniyede sonlandırılmaz.
`make test-watch`
derlenmiş Monkey C testlerini aynı `fr165` hedefinde çalıştırır. SDK 9.2.0 komut
satırı aracı başarı özetine rağmen çıkış kodu 1 döndürebildiği için görev, eksiksiz
`PASSED (passed=N, failed=0, errors=0)` özetini doğrular; boş/başarısız sonuç geçmez.

Testlerde GPS koordinatları yapaydır. `make sim` normal uygulamayı başlatır;
otomatik olarak GPS izni vermez veya sentetik GPS enjekte etmez. START sonrası
simülatör GPS oynatma menüsünde sentetik fixture seçilebilir. Görsel kontrol
listesi [field-test.md](field-test.md) içindedir.

GPS kalite ayarı `Good` olmalıdır; `Poor` ve `Last Known` kullanılabilir fix değildir.
SDK 9.2.0, oynatım sürerken yeniden uygulama yüklenirse Activity Data penceresini
kilitli durumda bırakabildi. Bu durumda simülatörü kapatıp `make sim` ile yeniden
açın; fixture'ı tekrar seçin. Anahtar Zinciri penceresi açılırsa kullanıcı tamamlar;
parola depoya veya sohbet kaydına yazılmaz.

`make sim-offline` ayrı bir `FieldMap-offline-simulator.prg` üretir ve ağ çağrısını
kapatır. Bu mod, canlı GPS yerine sentetik veri enjekte etmez. Normal `make sim`
ise yapılandırılan servisi kullanır. Derleme yapılandırması Git dışındaki kaynak
dizisinden okunur; eski `Application.Properties` değerleri yeni build'i gölgelemez.

Yerel API metadata için çalışır; Garmin'in görüntü dönüştürücüsü PNG URL'sine
dışarıdan erişmelidir. Dolayısıyla localhost ile tam raster aktarımı beklenmez.
Onaylı, geçici deney [HTTPS planında](https-simulator-test.md) tanımlıdır.

## Özel HTTPS G0 deneyi

Mac’in `localhost` adresi iPhone’dan bu Mac’e erişim sağlamaz. Gerçek saat için
sertifikası geçerli, Garmin iletişim yolundan erişilebilen bir HTTPS servis gerekir.
Bu depoda barındırma veya tünel otomatik olarak yayınlanmaz.

Özel bir test sunucusu seçildikten sonra şu komut yeni bir yapılandırma oluşturur:

```sh
.venv/bin/python scripts/dev_config.py --url https://your-test-origin.example
make api
make build-watch
```

Mevcut `.env` ve `.local/watch.json` varsa komut onları korur. Önce bu iki dosyayı
özel bir yedeğe taşıyın veya URL’yi iki dosyada aynı tutarak düzenleyin. Anahtarları
terminal çıktısına yazmayın. HTTPS modunda yalnız bu G0 cihazına ait rastgele bir
geliştirme tokenı kullanılır. Bu, G2 eşleme/yenileme/iptal sisteminin yerine geçmez.

Kalıcı sunucuda TLS sonlandırma, tek API worker, istek gövdesi limiti, disk/log
politikası ve süreç yeniden başlatma yapılandırılmalıdır. Uvicorn ve reverse proxy
erişim loglarında Authorization, query string ve tam görüntü URL’si bulunmamalı.
Servis yalnız loopback’e bağlanır; TLS reverse proxy ona yönlenir. Test tüneli
Mac uyuyunca durur; saha ürünü olarak kabul edilmez. Sağlayıcı/lisans kararı G2’de.
