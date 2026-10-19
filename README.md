# Windows Sorun Giderme

Windows sistemleri ve sunucuları için Türkçe PowerShell teşhis betikleri. CPU, RAM, disk, ağ, RDP, güncelleme, AD ve olay günlüklerini incelemeye yardımcı olur. Kapsamlı güvenlik denetimi veya otomatik kök neden analizi yapmaz.

## Gereksinimler

- Windows PowerShell 5.1 hedeflenir. PowerShell 7 ve farklı Windows sürümlerinde komutların kullanılabilirliği ayrıca doğrulanmalıdır.
- Servis, güvenlik günlüğü ve güncelleme işlemleri için yönetici yetkisi gerekebilir.
- AD kontrolleri uygun etki alanı ortamı, yetkiler ve AD DS / RSAT araçları gerektirir.
- Güncelleme betiği **PSWindowsUpdate** modülünü gerektirir. Modül kendiliğinden kurulmaz. Kaynağını inceleyerek ayrı kurabilirsiniz:

    Install-Module -Name PSWindowsUpdate -Scope CurrentUser

Betikler her Windows sürümü ve sunucu rolünde doğrulanmış değildir. Bakım işlemlerini önce test ortamında deneyin.

## Betikler

| Dosya | Varsayılan davranış | Müdahale seçeneği |
|---|---|---|
| [CPU](windows_high_cpu_script.ps1) | İki örnekten işlem başına CPU yüzdesi, toplam mantıksal işlemci kapasitesine göre | -StopTopProcess |
| [RAM](windows_high_ram_script.ps1) | Çalışma kümesine göre süreçleri listeler | -StopTopProcess |
| [Disk](windows_disk_cleanup_script.ps1) | Sürücülerin doluluk oranını gösterir | -CleanTemp |
| [Ağ](windows_network_diagnosis_script.ps1) | ICMP, DNS, ağ geçidi ve IPv4 bilgilerini inceler | -ClearDnsCache |
| [RDP](windows_rdp_fix_script.ps1) | Yapılandırılmış portu, yerel dinleyiciyi, servisi ve yerel kullanıcı grubunu inceler | -StartService |
| [Güncellemeler](windows_security_update_script.ps1) | Güncellemeleri sorgular, mevcut AD/Defender bilgilerini gösterir | -InstallUpdates |
| [BSOD](windows_bsod_check_script.ps1) | Son 30 gündeki aday olayları ve döküm dosyalarının varlığını gösterir | Yok |
| [Active Directory](windows_ad_check_script.ps1) | Replikasyon raporu, son 7 gündeki başarısız oturumlar, GPO ve SRV sorgusu | Yok |
| [Yerel rapor](log.ps1) | CPU, RAM, disk ve servis durumunu dosyaya yazar | Yok |

Varsayılan çalıştırmalar servis başlatmaz, süreç sonlandırmaz, dosya silmez ve güncelleme yüklemez. Güncelleme taraması Windows Update altyapısını kullanır; tamamen çevrimdışı veya hiçbir sistem izi bırakmayan bir işlem değildir. Rapor betiği dosya oluşturur. Hiçbir betik e-posta göndermez.

## Kullanım

Dosyaları inceleyin ve PowerShell'i depo dizininde açın. Kurumunuzun yürütme ilkelerine uyun. Gerekiyorsa yalnızca mevcut oturum için:

    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    Unblock-File -Path .\windows_high_cpu_script.ps1
    .\windows_high_cpu_script.ps1
    .\windows_high_ram_script.ps1 -ThresholdMB 1024
    .\windows_disk_cleanup_script.ps1
    .\windows_bsod_check_script.ps1 -Days 14

CPU varsayılan olarak iki saniyelik örnekleme kullanır. Örnekler arasında başlayan veya kapanan süreçler ve erişilemeyen süreçler ölçüme dahil edilmez. RAM eşiği aşımı tek başına bellek sorunu kanıtı değildir.

Müdahale seçenekleri PowerShell ShouldProcess mekanizmasını kullanır. Önce -WhatIf ile hedefi görün:

    .\windows_high_cpu_script.ps1 -StopTopProcess -WhatIf
    .\windows_high_ram_script.ps1 -StopTopProcess -WhatIf
    .\windows_disk_cleanup_script.ps1 -CleanTemp -WhatIf
    .\windows_network_diagnosis_script.ps1 -ClearDnsCache -WhatIf
    .\windows_rdp_fix_script.ps1 -StartService -WhatIf
    .\windows_security_update_script.ps1 -InstallUpdates -WhatIf

-WhatIf teşhis sorgularını çalıştırır; müdahale komutunu çalıştırmaz. Gerçek işlem için -WhatIf kaldırılır. Süreç sonlandırma, temizlik ve güncelleme yükleme ayrıca onay ister. Süreç sonlandırma kaydedilmemiş veriyi kaybettirebilir; eşik aşımı tek başına sonlandırma gerekçesi değildir.

### Disk temizliği

-CleanTemp yalnızca mevcut kullanıcının profilinin altındaki TEMP dizininin içeriğini siler. Farklı konumdaki TEMP dizinlerinde durur; diğer kullanıcıların ve Windows'un geçici dizinlerine dokunmaz. Bağlantı olan veya bağlantı içeren hedefler atlanır. Silinemeyen dosyalar uyarıyla bildirilir. Temizlik geri alınamaz.

-ListLargeFiles eşik üzerindeki sürücülerin her birini tarar; büyük disklerde uzun sürebilir ve erişim uyarıları verebilir:

    .\windows_disk_cleanup_script.ps1 -Threshold 90 -ListLargeFiles

### RDP ve güncellemeler

RDP betiği güvenlik duvarı kuralı oluşturmaz ve RDP'yi kayıt defterinden etkinleştirmez. Yerel dinleyici bulunması uzak erişimin açık olduğunu kanıtlamaz. Yerel grup SID ile sorgulanır; etki alanı denetleyicilerinde bu grup bulunmayabilir.

Güncellemeler yalnızca -InstallUpdates ile yüklenir; otomatik yeniden başlatma istenmez. Sonuçları inceleyip gerekli yeniden başlatmayı bakım zamanında planlayın. Güncelleme bulunamaması kapsamlı güvenlik açığı taraması sonucu değildir.

### Yerel rapor

    .\log.ps1
    .\log.ps1 -LogDirectory .\logs

Varsayılan konum mevcut kullanıcının LOCALAPPDATA dizini altındaki Windows-Sorun-Giderme\logs klasörüdür. Her çalıştırmada ayrı dosya üretilir. Eski SMTP yer tutucuları ve otomatik güncelleme/e-posta davranışı kaldırılmıştır.

AD ve olay günlükleri kullanıcı, makine ve etki alanı bilgileri içerebilir. Raporları veya döküm dosyalarını herkese açık issue ve depolara eklemeden önce inceleyin.

## Doğrulama

    powershell.exe -NoProfile -File .\tests\smoke.ps1

Bu kontrol sözdizimini ve taklit komutlarla varsayılan / -WhatIf davranışını sınar. Gerçek AD, RDP erişimi, güncelleme yüklemesi ve farklı Windows sürümlerinde çalışma garantisi vermez.

## Katkı ve lisans

Issue veya pull request açabilirsiniz. Bildirimlere Windows/PowerShell sürümünü ve kişisel bilgilerden arındırılmış hata çıktısını ekleyin.

Hazırlayan: **[netopsiyon] Ali Osman KAHRAMAN**  
İletişim: [ben@aliosman.com.tr](mailto:ben@aliosman.com.tr)  
Lisans: [MIT](LICENSE)