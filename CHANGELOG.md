# Changelog - Smart Execute v2.0

## v2.0.0 - Kapsamlı Güvenlik ve Özellik Güncellemesi

### 🚀 Yeni Özellikler

#### Güvenlik İyileştirmeleri
- **Çoklu Güvenlik Katmanları**: Kara liste, beyaz liste, risk değerlendirmesi
- **Anomali Tespiti**: Şüpheli davranış kalıplarını tespit eder
- **Session Yönetimi**: Zaman aşımı ve güvenlik kontrolleri
- **Rate Limiting**: API çağrısı sınırlamaları
- **Audit Loglama**: Detaylı güvenlik logları
- **Risk Skorlaması**: Komutlar tehlike seviyelerine göre kategorize edilir

#### LLM Provider Desteği
- **Ollama**: Yerel LLM desteği (varsayılan)
- **OpenAI**: GPT-3.5/GPT-4 API entegrasyonu
- **Anthropic**: Claude API desteği
- **Akıllı Provider Seçimi**: Sorgu karmaşıklığına göre otomatik seçim
- **Fallback Mekanizması**: Provider hatalarında otomatik geçiş

#### Performans İyileştirmeleri
- **Akıllı Cache Sistemi**: Sık kullanılan sorguların önbelleğe alınması
- **Asenkron İşlemler**: Arka plan görevleri
- **Optimize JSON Parsing**: Daha hızlı ve güvenli JSON işleme
- **Lazy Loading**: Modüllerin ihtiyaç halinde yüklenmesi

#### Cross-Shell Desteği
- **Zsh**: Tam destek (varsayılan)
- **Bash**: Uyumlu key binding'ler
- **Fish**: Özel fonksiyon desteği
- **Universal Logic**: Shell'den bağımsız çekirdek mantık

#### Kullanıcı Deneyimi
- **İnteraktif Kurulum Sihirbazı**: Adım adım yapılandırma
- **Yapılandırma Yönetimi**: Güvenlik seviyeleri ve özellik bayrakları
- **Status Dashboard**: Sistem durumu ve istatistikler
- **Gelişmiş Hata Mesajları**: Daha açıklayıcı hata raporları
- **Komut Yardımları**: `smart-execute help` komutu

### 📁 Yeni Dosyalar

- `smart_execute_v2.zsh` - Ana gelişmiş dosya
- `.smart_execute_security.zsh` - Güvenlik modülü
- `.smart_execute_cache.zsh` - Cache sistemi
- `.smart_execute_providers.zsh` - Çoklu LLM provider desteği
- `.smart_execute_cross_shell.zsh` - Cross-shell desteği
- `.smart_execute_wizard.zsh` - Kurulum sihirbazı
- `.smart_execute_security.conf` - Güvenlik yapılandırması
- `.smart_execute_advanced_blacklist.txt` - Gelişmiş kara liste
- `install.sh` - Otomatik kurulum scripti
- `test.sh` - Test suite
- `CHANGELOG.md` - Bu dosya

### 🔧 Teknik İyileştirmeler

#### Güvenlik
- 100+ yeni tehlikeli komut kalıbı eklendi
- Input/Output sanitization
- JSON validation ve güvenli parsing
- Memory ve disk kullanımı sınırlamaları
- Session timeout mekanizması

#### Modüler Yapı
- Fonksiyonel modüller ayrıldı
- Lazy loading sistemi
- Plugin mimarisi hazırlığı
- Backwards compatibility

#### Error Handling
- Kapsamlı hata yönetimi
- Graceful degradation
- Retry mekanizmaları
- Detailed logging

### 📊 İstatistikler

- **Kod Satırı**: ~2000 satır (v1.0'dan %300 artış)
- **Güvenlik Kontrolü**: 100+ kara liste kalıbı
- **Test Coverage**: 50+ test case
- **Desteklenen Shell**: 3 (Zsh, Bash, Fish)
- **LLM Provider**: 3 (Ollama, OpenAI, Anthropic)

### 🚀 Kurulum

```bash
# Hızlı kurulum
curl -fsSL https://raw.githubusercontent.com/user/AiTerm/master/install.sh | bash

# Manuel kurulum
git clone https://github.com/user/AiTerm.git
cd AiTerm
./install.sh
```

### 🧪 Test

```bash
# Tüm testleri çalıştır
./test.sh

# Sadece temel testler
./test.sh basic

# Performans testleri
./test.sh performance
```

### ⚙️ Yapılandırma

```bash
# Kurulum sihirbazı
smart-execute setup

# Durum kontrolü
smart-execute status

# Cache istatistikleri
smart-execute cache-stats
```

### 📝 Kullanım Örnekleri

```bash
# Doğal dil komutları
@ masaüstündeki tüm pdf dosyalarını bul
@ git'teki son 5 commit'i göster
@ sistem bellek kullanımını kontrol et

# Açıklama modu
@? ls -la
@? git rebase -i HEAD~3
@? find . -name "*.txt" -exec grep "pattern" {} \;

# Doğrudan çalıştırma
/ls -la
/git status
/pwd
```

### 🔒 Güvenlik Notları

- **Paranoid Mod**: Her komut için onay ister
- **Dengeli Mod**: Orta risk komutlar için onay (varsayılan)
- **Rahat Mod**: Sadece yüksek risk komutlar için onay

### 🚨 Breaking Changes

- Eski `smart_execute.zsh` dosyası `smart_execute_v2.zsh` oldu
- Yapılandırma dosyaları `.config/smart_execute/` dizinine taşındı
- Bazı environment variable'lar değişti
- API timeout varsayılanı 30s'den 60s'ye çıkarıldı

### 🎯 Gelecek Planları (v2.1)

- Docker/Podman sandbox desteği
- Git hooks entegrasyonu
- VS Code extension
- Web dashboard
- Machine learning tabanlı risk analizi
- Collaborative command sharing

### 🤝 Katkıda Bulunanlar

- Güvenlik analizi ve iyileştirmeler
- Çoklu shell desteği
- Test suite geliştirme
- Dokümantasyon güncellemeleri

### 📞 Destek

- GitHub Issues: https://github.com/user/AiTerm/issues
- Wiki: https://github.com/user/AiTerm/wiki
- Discussions: https://github.com/user/AiTerm/discussions

---

**Not**: Bu major release'dir ve önceki versiyonlarla tam uyumlu olmayabilir. Lütfen UPGRADE.md dosyasına bakın.
