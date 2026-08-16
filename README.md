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
- **API Anahtarı Güvenliği:** Google Gemini ve diğer API anahtarları asla kodun içinde saklanmaz, çevre değişkenlerinden okunur.

### 🤖 Çoklu LLM Desteği

- **Google Gemini (Yeni!):** Google One Pro aboneliği ile **Gemini 3.1 Pro Preview** desteği. En güçlü "Complex" provider.
- **Ollama:** Yerel, ücretsiz LLM desteği (Local ve Remote/Network desteği).
- **OpenAI:** GPT-3.5/GPT-4 API entegrasyonu.
- **Anthropic:** Claude API desteği.
- **Akıllı Provider Seçimi:** Sorgu karmaşıklığına göre otomatik provider seçimi. Basit işler için Ollama, karmaşık işler için Gemini kullanılır.
- **Fallback Mekanizması:** Bir provider başarısız olursa otomatik olarak yerel veya ağdaki Ollama'ya geçiş.

### ⚡ Performans İyileştirmeleri

- **Optimized Parsing:** Gelişmiş JSON işleme (Gemini v1beta desteği dahil) ve hata yönetimi.
- **Smart Network Support:** Yerel ağdaki (LAN) Ollama sunucularını fallback olarak kullanabilme.
- **Provider Optimizasyonu:** Akıllı provider seçimi ve fallback.

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
  - `@istek`: Standart modda doğal dil isteği gönderir (Basit işlerde Ollama, karmaşık işlerde Gemini kullanılır).
  - `@?istek`: Bir komutun ne işe yaradığına dair LLM'den açıklama ister
  - `/komut`: Komutu LLM'e göndermeden doğrudan çalıştırır

## Kurulum

### Hızlı Kurulum (Önerilen)

1. **Depoyu Klonlayın:**
   ```bash
   git clone https://github.com/user/AiTerm.git
   cd AiTerm
   ```

2. **Otomatik Kurulum Script'ini Çalıştırın:**
   ```bash
   ./scripts/install.sh
   ```

3. **Terminali Yeniden Başlatın:**
   ```bash
   source ~/.zshrc  # veya ~/.bashrc
   ```

4. **Kurulum Sihirbazını Çalıştırın:**
   ```bash
   smart-execute setup
   ```

### Manuel Kurulum

1. **Gerekli Araçları Yükleyin:**
   - Debian/Ubuntu: `sudo apt update && sudo apt install curl jq`
   - Fedora: `sudo dnf install curl jq`
   - macOS (Homebrew): `brew install curl jq`

2. **Ana Dosyayı Yükleyin:**
   ```bash
   source src/core/smart_execute_v2.zsh
   ```

3. **Shell Konfigürasyonunu Güncelleyin:**
   ```bash
   echo "source $(pwd)/src/core/smart_execute_v2.zsh" >> ~/.zshrc
   ```

### Proje Yapısı

```
AiTerm/
├── src/                          # Ana kaynak kodları
│   ├── core/                     # Çekirdek modüller
│   │   └── smart_execute_v2.zsh  # Ana uygulama
│   ├── modules/                  # Alt modüller
│   │   ├── security.zsh          # Güvenlik modülü
│   │   ├── providers.zsh         # LLM provider'ları
│   │   ├── cache.zsh             # Cache sistemi
│   │   ├── cross_shell.zsh       # Cross-shell desteği
│   │   └── wizard.zsh            # Kurulum sihirbazı
│   └── experimental/             # Deneysel özellikler
├── config/                       # Konfigürasyon dosyaları
│   ├── security.conf            # Güvenlik ayarları
│   └── blacklist.txt            # Kara liste
├── scripts/                      # Script'ler
│   ├── install.sh               # Kurulum script'i
│   └── test.sh                  # Test suite
├── docs/                         # Dokümantasyon
└── data/                         # Veri dosyaları
```

### Gereklilikler
- Zsh 5.0+ (Bash ve Fish için kısmi destek)
- curl
- jq
- Ollama (yerel LLM için)
- **Gemini API Key:** `$GEMINI_API_KEY` çevre değişkeni üzerinden Google One AI Pro desteği.

### İlk Yapılandırma
- İlk çalıştırmada yapılandırma dosyaları otomatik oluşturulur
- Gelişmiş kara liste otomatik yüklenir
- Varsayılan güvenlik ayarları uygulanır

## Kullanım

Normalde Zsh'e komut girer gibi komutlarınızı yazın. Ek olarak, Smart Execute aşağıdaki özel sembolleri destekler:

- **`/komut`** : Komut başında `/` varsa, komut LLM'e gönderilmeden doğrudan çalıştırılır.
- **`@istek`** : Komut başında `@` varsa, bu bir doğal dil isteği olarak değerlendirilir ve LLM'e gönderilir.
- **`@?istek`**: Komutun başına `@?` koyarak, LLM'den komut hakkında açıklama talep edebilirsiniz.

### Kullanım Örnekleri

```bash
# Doğal dil komut istekleri
@dosyaları listele (Ollama ile hızlı yanıt)
@masaüstündeki txt dosyalarını bul ve hepsini tek bir pdf yap (Gemini 3.1 Pro ile karmaşık işlem)
@sistem bilgilerini göster

# Komut açıklamaları
@?ls -la
@?git status
@?find . -name "*.txt"

# Doğrudan çalıştırma
/ls -la
/pwd
```

### 🤖 AI Agent ve CLI Kullanımı (`aiterm`)

Interactive shell veya Zsh ZLE widget'larını kullanamayan **AI Agent'lar** ve **otomasyon senaryoları** için `aiterm` (veya `se` kısayolu) komut satırı aracı geliştirilmiştir.

`aiterm` CLI aracı, agent'ların terminal kullanımlarındaki çıktılarını optimize eder, ANSI renk ve kontrol karakterlerini ayıklar ve çıktıları akıllıca kırparak **yoğun context tüketimini ve API maliyetlerini engeller.**

#### Komut Yapısı:
```bash
aiterm <subcommand> [options] [arguments]
```

#### CLI Komutları:
1. **`aiterm run [options] "<command>"`**: Belirtilen terminal komutunu çalıştırır ve çıktısını agent dostu bir biçime getirir.
   - `-l, --max-lines <n>`: Maksimum satır sayısı (Varsayılan: `200`).
   - `-b, --max-bytes <n>`: Maksimum byte sınırı (Varsayılan: `10000`).
   - `-f, --format <raw|markdown|json>`: Çıktı formatı (Varsayılan: `markdown`).
   - `-s, --summary`: Komut çıktısını LLM kullanarak özetler.
   - `-n, --no-strip`: ANSI renk kodlarının temizlenmesini kapatır.
2. **`aiterm run "npm install"`**: Örnek wrapper kullanımı.
3. **`aiterm ask "<prompt>"`** (veya `aiterm "<prompt>"`): Doğal dil ile komut önerisi ister.
4. **`aiterm explain "<command>"`**: Belirtilen komutun ne işe yaradığını açıklar.
5. **`aiterm status` / `setup` / `logs` / `audit`**: Yapılandırma ve yönetim araçları.

#### Akıllı Çıktı Kırpma (Context Saving):
Eğer bir komutun çıktısı limitleri aşarsa, `aiterm run` çıktıyı ortasından kırpar. Ancak kırpılan kısımda hata (`Error`, `Exception`, `Failed` vb.) olup olmadığını kontrol eder. Eğer hata satırları bulunursa bunları özel bir başlık altında (`⚠️ Omitted Output Error Highlights:`) koruyarak çıktıya ekler. Böylece agent hem çıktının başlangıç/bitiş bağlamını görür hem de hata detayını kaçırmaz.

#### Otomatik Sarma (Auto-Wrap):
`AITERM_AUTO_WRAP=true` çevre değişkeni tanımlandığında, yüksek çıktı üreten komutlar (`npm`, `cargo`, `pip`, `git`, `make` vb.) otomatik olarak `aiterm run` filtresinden geçirilerek çalıştırılır. `git status`, `pwd`, `ls` gibi doğrudan parse edilmesi gereken bilgi komutları ise bypass listesi ile ham olarak çalıştırılmaya devam edilir.

---

Diğer tüm komutlar normal şekilde çalıştırılır. LLM'e göndermek için `@` veya `@?` öneklerini kullanın.

## Güvenlik Tedbirleri

Smart Execute, kullanıcıların sistemlerini yanlışlıkla veya kötü niyetli komutlarla tehlikeye atmalarını önlemek için çeşitli güvenlik katmanları içerir:

1.  **Kara Liste (`blacklist.txt`):** Bu dosya, tehlikeli olduğu bilinen komut kalıplarını (regex olarak) içerir. Bir komut bu kalıplardan biriyle eşleşirse, çalıştırılması derhal engellenir. Varsayılan kara liste, `rm -rf /`, `dd` komutları gibi yaygın tehlikeli işlemleri içerir. Kullanıcılar bu listeyi kendi ihtiyaçlarına göre düzenleyebilirler.

2.  **Beyaz Liste (`whitelist.txt`):** Bu dosya, her zaman güvenli kabul edilen ve LLM'e gönderilmesine gerek olmayan komutları içerir. Bu, `ls`, `cd`, `pwd` gibi sık kullanılan basit komutlar için kullanışlıdır. Beyaz listedeki komutlar doğrudan çalıştırılır.

3.  **LLM Tehlike Algılaması:** LLM'e, tehlikeli bir komut üretmesi istendiğinde "DANGER" kelimesini döndürmesi talimatı verilmiştir. Eğer LLM bu yanıtı verirse veya LLM'in ürettiği komut kara listeyle eşleşirse, komut engellenir.

4.  **Kullanıcı Onayı:** LLM tarafından bir komut değişikliği önerildiğinde, bu komut otomatik olarak çalıştırılmaz. Bunun yerine, kullanıcıya önerilen komut gösterilir ve çalıştırmak, düzenlemek veya iptal etmek için bir seçenek sunulur. Bu, kullanıcının her zaman son sözü söylemesini sağlar.

5.  **ZLE Widget Kullanımı:** Kod, komutları doğrudan `exec` veya `eval` ile çalıştırmak yerine Zsh Line Editor (ZLE) widget'larını kullanır. `smart_accept_line` widget'ı, Enter tuşunun varsayılan davranışını üzerine yazar. Komutlar, `zle .accept-line` aracılığıyla Zsh tarafından güvenli bir şekilde işlenir. Bu, tırnaklama ve özel karakterlerle ilgili many potansiyel sorunu önler ve `exec` kullanımının getirdiği terminalin kapanması gibi sorunları ortadan kaldırır.

6. **İndikatörlerin Etkisi:** Kullanıcı, komutun başına özel semboller ekleyerek (örneğin `@` veya `/`), komutun nasıl işlendiğini doğrudan kontrol edebilir. Bu özellik, hem esneklik hem de öngörülebilirlik sağlar.

7. **API Anahtarı Güvenliği:** Google Gemini ve diğer API anahtarları asla kodun içinde saklanmaz. Sadece çevre değişkenleri (`$GEMINI_API_KEY`) üzerinden okunur, bu da projenin GitHub'da güvenle paylaşılmasını sağlar.

**Önemli Güvenlik Notları:**

*   **LLM Güvenilirliği:** LLM'ler güçlü araçlar olsalar da, her zaman mükemmel veya tamamen güvenli çıktılar üretmeyebilirler. Smart Execute, LLM çıktılarını filtrelemek için mekanizmalar içerse de, kullanıcıların özellikle karmaşık veya sistem düzeyinde değişiklik yapan komut önerilerini dikkatlice incelemesi önerilir.
*   **Kara Liste Bakımı:** Kara listenin etkinliği, içerdiği kalıpların güncelliğine ve kapsamlılığına bağlıdır. Kullanıcıların, kendi kullanım senaryolarına göre bu listeyi gözden geçirmeleri ve gerekirse güncellemeleri önemlidir.
*   **Yapılandırma Dosyaları:** `~/.config/smart_execute/` dizinindeki yapılandırma dosyalarının (özellikle `blacklist.txt`) yetkisiz erişime karşı korunması önemlidir.
*   **Sorumluluk:** Bu araç, komut satırı deneyimini geliştirmek ve bazı riskleri azaltmak için tasarlanmıştır, ancak nihai olarak çalıştırılan komutların sorumluluğu kullanıcıya aittir.

Projenin geliştirilmesi sırasında güvenlik her zaman öncelikli bir konu olmuştur ve kullanıcıların da bu araçları dikkatli ve bilinçli bir şekilde kullanmaları teşvik edilir.

## Test Etme

```bash
# Tüm testleri çalıştır
./scripts/test.sh

# Sadece temel testler
./scripts/test.sh basic

# Performans testleri
./scripts/test.sh performance
```

## Geliştirme

### Geliştirici Modu
```bash
# Geliştirme için doğrudan yükle
source src/core/smart_execute_v2.zsh

# Deneysel özellikleri test et
source src/experimental/enhanced_prompts.zsh
```

### Modüler Yapı
- **src/core/**: Ana uygulama mantığı
- **src/modules/**: Ayrıştırılmış modüller
- **src/experimental/**: Deneysel özellikler
- **config/**: Konfigürasyon dosyaları
- **scripts/**: Yardımcı script'ler

Daha fazla bilgi için [docs/AGENTS.md](docs/AGENTS.md) dosyasına bakın.

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

## 🚧 TODO ve Gelecek Geliştirmeler

### Yüksek Öncelik
- **Cache Sistemi Optimizasyonu**: 
  - Boş response döndürme sorunu çözümü
  - Async cache işlemleri iyileştirmesi  
  - Cache invalidation mekanizması
  - Performance testleri

### Orta Öncelik
- **UI/UX İyileştirmeleri**:
  - Interactive komut önizleme
  - Renkli çıktı desteği genişletme
  - Progress indicator'ler

### Düşük Öncelik  
- **Ek Provider Desteği**:
  - Azure OpenAI desteği
  - Lokal model alternatifleri

### Araştırma Aşamasında
- **Gelişmiş Güvenlik**:
  - ML-based anomaly detection
  - Behavioral analysis
  - Smart sandboxing

## Lisans
