# Gereksinim izlenebilirliği — G0 teslimi

“Uygulandı”, fiziksel kabul anlamına gelmez. Saha testleri NOT RUN.
Kaynak şartname [requirements.md](../requirements.md) değiştirilmeden korunmuştur.

| Gereksinim | G0 karşılığı / kaynak | Kanıt ve kalan sınır |
|---|---|---|
| FR01–FR03 | FieldMapApp, GpsState; açık onayla GPS, geçersiz fix reddi | Monkey C geçerli/geçersiz/zaman testleri; fiziksel ilk fix NOT RUN |
| FR04–FR06 | 5 s yaş, kalite kategorisi, 180 noktalı halka, kesinti segmentleri | GpsState testleri; gerçek hareket ve gecikme NOT RUN |
| FR07–FR08 | pause/resume/stop; abonelik/timer/ağ temizliği, callback epoch | Eski callback testi; saat lifecycle NOT RUN |
| FR09 | Sürümlü zoom/tema tercihleri, iz RAM’de | Hata yakalama mevcut; reboot ve dolu store NOT RUN |
| FR10 | Gündüz/gece sentetik ızgara | **Gerçek sokak/patika içeriği yok; G2 bekler** |
| FR11–FR13 | EPSG:3857, double dönüşüm, %25 yarıçap eşiği, z14–16, ölçek | Python + Monkey C kontrol noktaları ve tarih çizgisi; alan kabulü NOT RUN |
| FR14–FR15 | Düğmeyle kaydırma/merkezleme, katman sırası, yön/konum/iz | Delegate ve 390px çizim testleri; görsel ekran incelemesi NOT RUN |
| FR16 | Tek etkin RAM rasterı; sunucuda 24 girdilik test cache’i | Limit/boşaltma testi; komşu cache ve lisanslı tekrar kullanım G1/G2 |
| FR17–FR18 | Nesil/iş kimliği; görüntü+metaveri atomik; kendi sınırlarında çizim | Eski/bozuk yanıt testleri; gerçek köprü NOT RUN |
| FR19–FR22 | makeWebRequest → makeImageRequest, bağımsız GPS, 5 s/timeout/backoff | Mantıksal iş ve retry testleri; Garmin/iPhone aktarımı NOT RUN |
| FR23–FR25 | G2 eşleme/token yaşam döngüsü/portal | **Uygulanmadı**; G0 rastgele test tokenı yalnız özel deney için |
| FR26 | Sürüm/hata/heap/sayaç tanılama | Ekran render testi; koordinat ve token basılmaz |
| FR27–FR29 | START/UP/DOWN/BACK; round 390; font ölçümü | 15 saat testi içinde kontroller/çizim/etiket sınırları; görsel ve Türkçe saha kontrolü NOT RUN |
| FR30–FR31 | Görünür sentetik etiket, ilk konum/ağ açıklaması | Kaynak etiketleri ve çizim testi; gerçek sağlayıcı atfı G2 |
| FR32–FR38 | GPX, rota, FIT | **R1, uygulanmadı**; GPX fixture yalnız simülatör girdisi |
| OF01–OF04 | Offline paket, track-up, iOS uygulaması | **Opsiyon, uygulanmadı** |
| SEC01–SEC02 | Açık başlatma, HTTPS saha modu, özel anahtar dosyaları | Kaynak + konfigürasyon ayrımı; TLS/iPhone saha testi NOT RUN |
| SEC03/SEC05 | G2 hesap/cihaz kapsamları ve iptal | **Üretim auth yok**; G0 test tokenı, input sınırları mevcut |
| SEC04 | Render’a özel 120 s HMAC, token URL dışında | Yanlış imza/ID/süre/non-ASCII testleri PASS |
| SEC06–SEC07 | RAM, koordinatsız hatalar/loglar, yapay fixture | Sanitization testleri; paylaşılacak saha kanıtı kullanıcı kontrolünde |
| SEC08 | Sürüm kilitleri, audit, publishing check, CI, SHA256 | Yerel komut sonuçları; mağaza/GitHub yayını yapılmadı |

NFR01–NFR10 ve NFR12 kabul ölçümleri NOT RUN. NFR07’nin tek iş/bounded queue
invariantı test edilmiştir; uçtan uca zaman, iki saat heap eğilimi ve pil kanıtı
yerine geçmez. NFR11 sentetik projeksiyon kontrol noktalarıyla doğrulanır; fiziksel
GPS doğruluğu için sonuç çıkarılmaz. 768 KiB cihaz paketindeki limittir; 80% heap
kabul hedefi fiziksel saat üzerinde henüz ölçülmedi.
