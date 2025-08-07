# Smart Execute

## ⚠️ ÖNEMLI GÜVENLİK UYARISI / IMPORTANT SECURITY WARNING

**Bu yazılım bir LLM (Büyük Dil Modeli) kullanarak terminal komutları üretir ve çalıştırır. Bu, potansiyel olarak TEHLİKELİ bir işlemdir.**

### RİSKLER:
- ❌ LLM tarafından üretilen komutlar sisteminize zarar verebilir
- ❌ Veri kaybı yaşanabilir 
- ❌ Güvenlik açıkları oluşabilir
- ❌ Sistem dosyaları bozulabilir

### SORUMLULUK REDDİ:
- ⚠️ Bu yazılımı kullanarak **TÜM SORUMLULUĞU ÜZERİNİZE ALIYORSUNUZ**
- ⚠️ Yazarlar hiçbir sorumluluk kabul etmez
- ⚠️ Herhangi bir garanti verilmez
- ⚠️ Kendi riskinizle kullanın

### KULLANIM KOŞULLARI:
- ✅ Komutları çalıştırmadan önce mutlaka kontrol edin
- ✅ Test ortamında deneme yapın
- ✅ Yedeklerinizi alın
- ✅ Bu uyarıları kabul ettiğinizi onaylayın

---

Smart Execute, çoklu shell desteği olan gelişmiş bir akıllı komut yorumlayıcısıdır. Doğal dil girdilerini veya hatalı komutları alır, LLM (Büyük Dil Modeli) aracılığıyla işler ve çalıştırılabilir komutlara dönüştürür. Kapsamlı güvenlik katmanları ve gelişmiş özelliklerle donatılmıştır.

## 🚀 Yeni Özellikler v2.0

### 🔒 Gelişmiş Güvenlik

- **Çok Katmanlı Güvenlik:** Kara liste, beyaz liste, risk değerlendirmesi ve anomali tespiti
- **Risk Skorlaması:** Komutlar tehlike seviyelerine göre kategorize edilir
- **Session Yönetimi:** Oturum zaman aşımı ve güvenlik kontrolleri
- **Rate Limiting:** API çağrılarını sınırlayarak kötüye kullanımı önler
- **Audit Loglama:** Detaylı güvenlik ve kullanım logları

### 🤖 Çoklu LLM Desteği

- **Ollama:** Yerel, ücretsiz LLM desteği
- **OpenAI:** GPT-3.5/GPT-4 API entegrasyonu
- **Anthropic:** Claude API desteği
- **Akıllı Provider Seçimi:** Sorgu karmaşıklığına göre otomatik provider seçimi
- **Fallback Mekanizması:** Bir provider başarısız olursa diğerine geçiş

### ⚡ Performans İyileştirmeleri

- **Akıllı Cache Sistemi:** Sık kullanılan sorguları önbelleğe alır
- **Asenkron İşlemler:** Arka plan görevleri için async desteği
- **Optimized Parsing:** Gelişmiş JSON işleme ve hata yönetimi

### 🔧 Cross-Shell Desteği

- **Zsh:** Tam destek (varsayılan)
- **Bash:** Uyumlu key binding'ler
- **Fish:** Özel fonksiyon desteği
- **Universal Logic:** Shell'den bağımsız çekirdek mantık

### 🎯 Kullanıcı Deneyimi

- **İnteraktif Kurulum:** Adım adım yapılandırma sihirbazı
- **Yapılandırma Yönetimi:** Güvenlik seviyeleri ve özellik bayrakları
- **Status Dashboard:** Sistem durumu ve istatistikler
- **Gelişmiş Hata Mesajları:** Daha açıklayıcı hata raporları

## Temel Özellikler

- **Doğal Dil Komut Anlama:** "Masaüstümdeki tüm metin dosyalarını bul" gibi doğal dil ifadelerini komutlara çevirir
- **Hata Düzeltme:** Yazım hataları olan veya yanlış komutları düzelterek doğru komutu önerir
- **Güvenlik Filtreleri:** Çok katmanlı güvenlik sistemi ile tehlikeli komutları engeller
- **Kullanıcı Onayı:** Risk seviyesine göre kullanıcı onayı ister
- **Özelleştirilebilir:** Tüm ayarlar kullanıcı tarafından yapılandırılabilir
- **Gelişmiş İndikatör Desteği:**
  - `@istek`: Standart modda doğal dil isteği gönderir
  - `@?istek`: Bir komutun ne işe yaradığına dair LLM'den açıklama ister
  - `/komut`: Komutu LLM'e göndermeden doğrudan çalıştırır

## Kurulum

### Hızlı Kurulum (Önerilen)

1. **Smart Execute v2.0 Dosyasını İndirin:**
   - Bu repoyu klonlayın: `git clone https://github.com/user/AiTerm.git`
   - Veya `smart_execute_v2.zsh` dosyasını doğrudan indirin

2. **Dosyayı Home Dizininize Kopyalayın:**
   ```bash
   cp smart_execute_v2.zsh ~/.smart_execute_v2.zsh
   ```

3. **~/.zshrc Dosyanızı Düzenleyin:**
   ```bash
   echo "source ~/.smart_execute_v2.zsh" >> ~/.zshrc
   ```

4. **Gerekli Araçları Yükleyin:**
   - Debian/Ubuntu: `sudo apt update && sudo apt install curl jq`
   - Fedora: `sudo dnf install curl jq`
   - macOS (Homebrew): `brew install curl jq`

5. **Terminali Yeniden Başlatın:**
   ```bash
   source ~/.zshrc
   ```

6. **Kurulum Sihirbazını Çalıştırın:**
   ```bash
   smart-execute setup
   ```

### Manuel Kurulum

1. **Gereklilikler:**
   - Zsh 5.0+ (Bash ve Fish için kısmi destek)
   - curl
   - jq
   - Ollama (yerel LLM için) veya API anahtarları (OpenAI/Anthropic için)

2. **İlk Yapılandırma:**
   - İlk çalıştırmada yapılandırma dosyaları otomatik oluşturulur
   - Gelişmiş kara liste otomatik yüklenir
   - Varsayılan güvenlik ayarları uygulanır

## Kullanım

Normalde Zsh'e komut girer gibi komutlarınızı yazın. Ek olarak, Smart Execute aşağıdaki özel ayrımları destekler:

- `/komut` : Komut başında `/` varsa, komut LLM'e gönderilmeden doğrudan çalıştırılır.
- `@istek` : Komut başında `@` varsa, bu bir doğal dil isteği olarak değerlendirilir ve standart JSON formatında bir yanıt beklenerek LLM'e gönderilir.
- `@?istek`: Komutun başına `@?` koyarak, komutun kendisi yerine ne işe yaradığına dair LLM'den bir açıklama talep edebilirsiniz. (Örn: `@?ls -l | grep .txt`)
- Diğer tüm komutlar için:
    - Komut boşsa veya beyaz listede ise, doğrudan çalıştırılır.
    - Kara listedeyse, engellenir ve güvenlik uyarısı gösterilir.
    - Diğer durumlarda LLM'e gönderilir:
        - LLM bir öneri sunarsa, bu öneri size gösterilir:
            - `E` tuşuna basarak önerilen komutu çalıştırabilirsiniz.
            - `D` tuşuna basarak önerilen komutu düzenleyebilirsiniz (komut satırınıza yazılır).
            - Başka bir tuşa basarak işlemi iptal edebilirsiniz.
        - LLM "DANGER" yanıtını verirse veya önerisi kara listede ise komut engellenir.
        - LLM yanıt vermezse veya önerisi orijinal komutla aynıysa, orijinal komut çalıştırılır.

## Güvenlik Tedbirleri

Smart Execute, kullanıcıların sistemlerini yanlışlıkla veya kötü niyetli komutlarla tehlikeye atmalarını önlemek için çeşitli güvenlik katmanları içerir:

1.  **Kara Liste (`blacklist.txt`):** Bu dosya, tehlikeli olduğu bilinen komut kalıplarını (regex olarak) içerir. Bir komut bu kalıplardan biriyle eşleşirse, çalıştırılması derhal engellenir. Varsayılan kara liste, `rm -rf /`, `dd` komutları gibi yaygın tehlikeli işlemleri içerir. Kullanıcılar bu listeyi kendi ihtiyaçlarına göre düzenleyebilirler.

2.  **Beyaz Liste (`whitelist.txt`):** Bu dosya, her zaman güvenli kabul edilen ve LLM'e gönderilmesine gerek olmayan komutları içerir. Bu, `ls`, `cd`, `pwd` gibi sık kullanılan basit komutlar için kullanışlıdır. Beyaz listedeki komutlar doğrudan çalıştırılır.

3.  **LLM Tehlike Algılaması:** LLM'e, tehlikeli bir komut üretmesi istendiğinde "DANGER" kelimesini döndürmesi talimatı verilmiştir. Eğer LLM bu yanıtı verirse veya LLM'in ürettiği komut kara listeyle eşleşirse, komut engellenir.

4.  **Kullanıcı Onayı:** LLM tarafından bir komut değişikliği önerildiğinde, bu komut otomatik olarak çalıştırılmaz. Bunun yerine, kullanıcıya önerilen komut gösterilir ve çalıştırmak, düzenlemek veya iptal etmek için bir seçenek sunulur. Bu, kullanıcının her zaman son sözü söylemesini sağlar.

5.  **ZLE Widget Kullanımı:** Kod, komutları doğrudan `exec` veya `eval` ile çalıştırmak yerine Zsh Line Editor (ZLE) widget'larını kullanır. `smart_accept_line` widget'ı, Enter tuşunun varsayılan davranışını üzerine yazar. Komutlar, `zle .accept-line` aracılığıyla Zsh tarafından güvenli bir şekilde işlenir. Bu, tırnaklama ve özel karakterlerle ilgili birçok potansiyel sorunu önler ve `exec` kullanımının getirdiği terminalin kapanması gibi sorunları ortadan kaldırır.

6. **İndikatörlerin Etkisi:** Kullanıcı, komutun başına özel semboller ekleyerek (örneğin `@` veya `/`), komutun nasıl işlendiğini doğrudan kontrol edebilir. Bu özellik, hem esneklik hem de öngörülebilirlik sağlar.

**Önemli Güvenlik Notları:**

*   **LLM Güvenilirliği:** LLM'ler güçlü araçlar olsalar da, her zaman mükemmel veya tamamen güvenli çıktılar üretmeyebilirler. Smart Execute, LLM çıktılarını filtrelemek için mekanizmalar içerse de, kullanıcıların özellikle karmaşık veya sistem düzeyinde değişiklik yapan komut önerilerini dikkatlice incelemesi önerilir.
*   **Kara Liste Bakımı:** Kara listenin etkinliği, içerdiği kalıpların güncelliğine ve kapsamlılığına bağlıdır. Kullanıcıların, kendi kullanım senaryolarına göre bu listeyi gözden geçirmeleri ve gerekirse güncellemeleri önemlidir.
*   **Yapılandırma Dosyaları:** `~/.config/smart_execute/` dizinindeki yapılandırma dosyalarının (özellikle `blacklist.txt`) yetkisiz erişime karşı korunması önemlidir.
*   **Sorumluluk:** Bu araç, komut satırı deneyimini geliştirmek ve bazı riskleri azaltmak için tasarlanmıştır, ancak nihai olarak çalıştırılan komutların sorumluluğu kullanıcıya aittir.

Projenin geliştirilmesi sırasında güvenlik her zaman öncelikli bir konu olmuştur ve kullanıcıların da bu araçları dikkatli ve bilinçli bir şekilde kullanmaları teşvik edilir.

## Lisans ve Sorumluluk Reddi

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

### MIT License Özeti:
- ✅ Ticari kullanım izni
- ✅ Değiştirme izni  
- ✅ Dağıtım izni
- ✅ Özel kullanım izni
- ❌ Garanti yok
- ❌ Sorumluluk yok

**ÖNEMLI:** Bu yazılım "OLDUĞU GİBİ" sağlanır ve yazarlar hiçbir garanti vermez. Yazarlar, bu yazılımın kullanımından doğabilecek hiçbir zarar için sorumlu tutulamaz.

### Katkı ve Destek

Bu açık kaynak bir projedir. Katkılarınızı memnuniyetle karşılarız, ancak:
- Hiçbir garanti verilmez
- Teknik destek zorunluluğu yoktur  
- Yazarlar hiçbir sorumluluk kabul etmez
- Kullanım tamamen kendi riskinizedir

**Son Uyarı:** Bu araç güçlü ve potansiyel olarak tehlikelidir. Sadece deneyimli kullanıcılar tarafından, dikkatli bir şekilde kullanılmalıdır.
