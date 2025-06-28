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

Smart Execute, Zsh kabuğu için akıllı bir komut yorumlayıcısıdır. Doğal dil girdilerini veya hatalı komutları alır, bir LLM (Büyük Dil Modeli) aracılığıyla işler ve çalıştırılabilir bir Zsh komutuna dönüştürür. Ayrıca, tehlikeli komutların çalıştırılmasını önlemek için bir kara liste ve beyaz liste mekanizması içerir.

## Özellikler

- **Doğal Dil Komut Anlama:** "Masaüstümdeki tüm metin dosyalarını bul" gibi doğal dil ifadelerini Zsh komutlarına çevirir.
- **Hata Düzeltme:** Yazım hataları olan veya yanlış komutları düzelterek doğru komutu önerir.
- **Güvenlik Filtreleri:**
    - **Kara Liste:** Tehlikeli olduğu bilinen komut kalıplarını engelleyerek sistem güvenliğini artırır.
    - **Beyaz Liste:** Sık kullanılan ve güvenli olduğu bilinen komutların LLM'e gönderilmeden doğrudan çalıştırılmasını sağlar, performansı artırır.
    - **LLM Tehlike Kontrolü:** LLM tarafından üretilen potansiyel olarak tehlikeli komutları algılar ve engeller.
- **Kullanıcı Onayı:** LLM tarafından önerilen komutları çalıştırmadan önce kullanıcıdan onay alır.
- **Özelleştirilebilir:** Kara liste, beyaz liste ve LLM ayarları kullanıcı tarafından kolayca yapılandırılabilir.
- **Loglama:** Yapılan işlemleri ve karşılaşılan hataları bir log dosyasına kaydeder.
- **Gelişmiş İndikatör Desteği:** Komutun davranışını özel öneklerle kontrol edin:
    - `@istek`: Standart modda doğal dil isteği gönderir.
    - `@?istek`: Bir komutun ne işe yaradığına dair LLM'den açıklama ister.
    - `/komut`: Komutu LLM'e göndermeden doğrudan çalıştırır.

## Kurulum

1.  **`.smart_execute.zsh` Dosyasını Edinin:**
    *   Bu repoyu klonlayın veya `.smart_execute.zsh` dosyasını doğrudan indirin.
    *   Dosyayı ev dizininize (`$HOME`) kopyalayın. Örneğin: `cp path/to/.smart_execute.zsh ~/.smart_execute.zsh`

2.  **`~/.zshrc` Dosyanızı Düzenleyin:**
    `~/.zshrc` dosyanızın sonuna aşağıdaki satırı ekleyin:

    ```zsh
    # Akıllı komut yorumlayıcısını etkinleştir
    source "$HOME/.smart_execute.zsh"
    ```

3.  **Gerekli Araçları Yükleyin:**
    Smart Execute'un çalışması için `curl`, `jq` ve `perl` komut satırı araçlarının sisteminizde kurulu olması gerekir. Çoğu Linux dağıtımında ve macOS'ta paket yöneticinizle kurabilirsiniz.
    *   Debian/Ubuntu: `sudo apt update && sudo apt install curl jq perl`
    *   Fedora: `sudo dnf install curl jq perl`
    *   macOS (Homebrew ile): `brew install curl jq perl`

4.  **Terminalinizi Yeniden Başlatın:**
    `~/.zshrc` dosyasındaki değişikliklerin etkili olması için terminalinizi yeniden başlatın veya `source ~/.zshrc` komutunu çalıştırın.

5.  **İlk Yapılandırma:**
    *   İlk başlatmada, eğer `~/.config/smart_execute/blacklist.txt` dosyası yoksa, betik onu otomatik olarak varsayılan tehlikeli komut kalıplarıyla birlikte oluşturacaktır. Bu dizin ve dosya `$SMART_EXECUTE_CONFIG_DIR` değişkeni ile tanımlanır (varsayılan: `~/.config/smart_execute`).
    *   (İsteğe Bağlı) `~/.config/smart_execute/whitelist.txt` dosyasını oluşturup LLM'e sormak istemediğiniz basit komutları (örneğin `ls`, `cd`, `pwd`) her satıra bir tane gelecek şekilde ekleyebilirsiniz. Bu, performansı artırır ve LLM sorgularını azaltır.

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
