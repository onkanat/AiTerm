# Smart Execute v2.0 - Model ve Prompt Önerileri

## 🤖 Model Önerileri

### 🏆 Optimal Model Seçimleri

#### **Yerel Modeller (Ollama)**

1. **🥇 CodeLlama 7B/13B** - `codellama:7b-instruct` / `codellama:13b-instruct`
   - **Avantajlar**: Terminal/kod komutları için özel eğitilmiş
   - **Performans**: Yüksek doğruluk, hızlı yanıt
   - **RAM**: 8GB (7B) / 16GB (13B)
   - **Önerilen Ayar**: `temperature: 0.1, top_p: 0.9`

2. **🥈 Llama 3.1 8B Instruct** - `llama3.1:8b-instruct-q4_0`
   - **Avantajlar**: En güncel, güçlü reasoning
   - **Performans**: Çok iyi komut anlama
   - **RAM**: 8GB
   - **Önerilen Ayar**: `temperature: 0.2, top_p: 0.8`

3. **🥉 Qwen2.5-Coder 7B** - `qwen2.5-coder:7b-instruct`
   - **Avantajlar**: Kod ve terminal komutları için optimize
   - **Performans**: Hızlı, doğru JSON çıktısı
   - **RAM**: 8GB
   - **Önerilen Ayar**: `temperature: 0.1, top_p: 0.9`

4. **💫 Gemma 2 9B** - `gemma2:9b-instruct-q4_0`
   - **Avantajlar**: Google tarafından geliştirilmiş, güvenlik odaklı
   - **Performans**: İyi güvenlik algısı
   - **RAM**: 10GB
   - **Önerilen Ayar**: `temperature: 0.15, top_p: 0.85`

#### **Cloud API Modelleri**

1. **🚀 GPT-4o Mini** - `gpt-4o-mini`
   - **Avantajlar**: Hızlı, ucuz, yüksek doğruluk
   - **Maliyet**: ~$0.15/1M token
   - **Performans**: Excellent JSON formatting
   - **Best for**: Production kullanım

2. **🧠 Claude 3.5 Haiku** - `claude-3-5-haiku-20241022`
   - **Avantajlar**: En hızlı Claude, güvenlik odaklı
   - **Maliyet**: ~$0.25/1M token  
   - **Performans**: Superior safety detection
   - **Best for**: Güvenlik kritik uygulamalar

3. **⚡ Gemini Flash** - `gemini-1.5-flash`
   - **Avantajlar**: Çok hızlı, ücretsiz quota
   - **Maliyet**: Free tier mevcut
   - **Performans**: Excellent multimodal
   - **Best for**: Başlangıç kullanıcıları

### 📊 Model Karşılaştırma Tablosu

| Model | Hız | Doğruluk | Güvenlik | Maliyet | Terminal Uygunluğu |
| --- | --- | --- | --- | --- | --- |
| CodeLlama 7B | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Llama 3.1 8B | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| GPT-4o Mini | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Claude 3.5 Haiku | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |

## 🎯 Optimize Edilmiş Dinamik ve Bağlamsal Prompt Yapısı

### 📋 Çevre Bağlamı Entegrasyonu (Context Collector)

Gelişmiş Prompt mimarisi, LLM'e sadece ham kullanıcı girdisini göndermek yerine, terminalin o anki durumu hakkında çok kritik çalışma ortamı bağlamlarını otomatik olarak toplar ve iletir:
1. **İşletim Sistemi Bağlamı:** Sistem `macOS (Darwin)` veya `Linux` olarak dinamik tespit edilir. Böylece LLM, sistemde BSD (macOS varsayılanı) veya GNU (Linux varsayılanı) komut parametrelerinden hangisini kullanması gerektiğini bilerek komut önerir (örn: `sed`, `awk`, `find` parametreleri).
2. **Kabuk (Shell) Bağlamı:** Etkin kabuk (`zsh`) belirtilir.
3. **Çalışma Dizini (`$PWD`):** Mevcut çalışma klasörü dinamik olarak prompt'a enjekte edilir.
4. **Güvenli Terminal Geçmişi (Sanitized History):** Son 15 komut içerisindeki şifreler, anahtarlar, API token'ları, gizli veriler veya smart-execute çağrıları (`@` karakteri) filtrelerden geçirilerek en son 3 meşru komut LLM'e bağlam olarak aktarılır.

---

### 🔧 Geliştirilmiş Sistem Mesajı Şablonları

#### **Türkçe Dinamik Prompt Şablonu (`SYSTEM_MESSAGE_TR`)**

```bash
SYSTEM_MESSAGE_TR='Sen yetenekli bir Linux ve macOS terminal uzmanısın. Kullanıcıların girdiği doğal dil isteklerini analiz edip, çalıştırılabilir terminal komutları üretir veya komutları açıklarsın.

KRİTİK FORMAT KURALLARI:
1. SADECE geçerli bir JSON objesi döndür. JSON objesi dışında hiçbir giriş/geliş cümlesi (örn: "İşte komutunuz:", "```json", vb.) yazma.
2. JSON objesi tek satırda olmalı, hiç yeni satır (newline) içermemelidir.
3. JSON içerisindeki tırnak işaretleri, kaçış karakterleri (escape) vb. geçerli JSON standartlarına (örn: \", \n, \t) uygun olmalıdır.
4. Asla kullanıcının girdisini doğrudan kopyalama. Eğer eksik bir komut girilmişse, onu çalışabilir en mantıklı tam komuta dönüştür.

MODLAR VE FORMATLAR:
A) KOMUT MODU (Kullanıcı bir komut/işlem istiyor):
   Format: {"command":"eksiksiz_tam_komut"}
   Örnek: {"command":"find . -name \"*.pdf\""}
   
B) AÇIKLAMA MODU (Kullanıcı açıklama veya yardım istiyor):
   Format: {"explanation":"detaylı_aciklama_metni"}
   Örnek: {"explanation":"find komutu dosya aramak için kullanılır. -name parametresi dosya adını eşleştirir."}

GÜVENLİK VE TEHLİKELİ İSTEKLER:
Aşağıdaki durumlarda mutlaka {"command":"DANGER"} yanıtı vermelisin:
- Sistem dosyalarını silmeye veya bozmaya yönelik yıkıcı komutlar (örn: rm -rf /, dd, vb.)
- Güvenli olmayan yetki yükseltmeleri (örn: sudo su)
- Fork bombaları (:|:& vb.)
- Ağdan zararlı betik indirip doğrudan çalıştırma (örn: curl ... | sh)
- Kimlik bilgilerini (credentials) sızdırmaya yönelik şüpheli aktiviteler

ÇALIŞMA ORTAMI BAĞLAMI:
Bu komutlar şu anki sistem bağlamında çalıştırılacaktır:
- İşletim Sistemi: __OS_INFO__ (Buna göre doğru BSD/GNU parametrelerini seç!)
- Etkin Kabuk (Shell): __SHELL_INFO__
- Mevcut Çalışma Dizini (PWD): __PWD_INFO__
- Son Çalıştırılan Komutlar (History):
__HISTORY_INFO__'
```

#### **English Dynamic Prompt Template (`SYSTEM_MESSAGE_EN`)**

```bash
SYSTEM_MESSAGE_EN='You are a highly skilled Linux and macOS terminal expert. You analyze natural language requests and either generate executable terminal commands or explain them.

CRITICAL FORMAT RULES:
1. Respond ONLY with a valid JSON object. Do not write any conversational intro/outro text (e.g. "Here is your command:", "```json", etc.).
2. The JSON object must be on a single line with no newlines.
3. Ensure proper JSON escaping for special characters (e.g., \", \n, \t).
4. Never copy the user''s input as-is. If an incomplete command is requested, convert it into the most logical, fully functioning command.

RESPONSE MODES AND FORMATS:
A) COMMAND MODE (User wants a command/action):
   Format: {"command":"complete_working_command"}
   Example: {"command":"find . -name \"*.pdf\""}
   
B) EXPLANATION MODE (User wants explanation or help):
   Format: {"explanation":"detailed_explanation_text"}
   Example: {"explanation":"The find command is used to search for files. The -name parameter matches the filename pattern."}

SECURITY AND DANGEROUS REQUESTS:
You must respond with {"command":"DANGER"} under the following conditions:
- Destructive commands aiming to delete or damage system files (e.g., rm -rf /, dd, etc.)
- Insecure privilege escalations (e.g., sudo su)
- Fork bombs (:|:& etc.)
- Downloading and directly executing untrusted scripts (e.g., curl ... | sh)
- Suspicious activity trying to exfiltrate credentials

ENVIRONMENT CONTEXT:
The commands will run in the following environment context:
- Operating System: __OS_INFO__ (Choose correct BSD/GNU flags accordingly!)
- Active Shell: __SHELL_INFO__
- Current Directory (PWD): __PWD_INFO__
- Recent Command History:
__HISTORY_INFO__'
```

---

### 🔄 Dinamik Dil ve Bağlam Yönetimi

Kullanıcı dili `SMART_EXECUTE_LANG` konfigürasyon parametresi (örn: `auto`, `tr`, `en`) ile yönetilir.

```bash
# Dil Tespiti Fonksiyonu
_detect_user_language() {
    local input="$1"
    # Türkçe tespiti için karakter/kelime kontrolü
    if [[ "$input" =~ [çğıöşüÇĞIİÖŞÜ] ]] || \
       [[ "$input" =~ (dosya|dizin|listele|göster|bul|sil|kopyala|taşı|kurulum|yükle|kaldır|nedir|nasıl|açıkla) ]]; then
        echo "tr"
    else
        echo "en"
    fi
}

# Son Terminal Geçmişini Güvenle Çekme
_get_recent_history() {
    local hist_lines=""
    if [[ -f "$HOME/.zsh_history" ]]; then
        # Son 15 satırı çek, temizle, hassas veya smart-execute komutlarını filtrele
        hist_lines=$(tail -n 15 "$HOME/.zsh_history" 2>/dev/null | cut -d';' -f2- | grep -vE '(KEY|PASS|TOKEN|SECRET|@|smart-execute)' | tail -n 3)
    fi
    if [[ -z "$hist_lines" ]]; then
        hist_lines="(Terminal geçmişi bulunmuyor veya temiz)"
    fi
    echo "$hist_lines"
}
```

### 🎛️ Model-Özel Parametreler

```bash
# Model-specific optimizations
declare -A MODEL_PARAMS=(
    ["codellama:7b-instruct"]="temperature:0.1,top_p:0.9,repeat_penalty:1.1"
    ["llama3.1:8b-instruct"]="temperature:0.2,top_p:0.8,repeat_penalty:1.05"
    ["qwen2.5-coder:7b"]="temperature:0.1,top_p:0.9,repeat_penalty:1.1"
    ["gpt-4o-mini"]="temperature:0.1,max_tokens:150,frequency_penalty:0.1"
    ["claude-3-5-haiku"]="temperature:0.1,max_tokens:150"
)

_get_model_params() {
    local model="$1"
    echo "${MODEL_PARAMS[$model]:-temperature:0.2,top_p:0.8}"
}
```

### 🧪 A/B Testing Setup

```bash
# Prompt effectiveness testing
_test_prompt_effectiveness() {
    local test_queries=(
        "masaüstündeki txt dosyalarını bul"
        "show running processes"
        "git reposunun durumunu kontrol et"
        "delete all files recursively"  # Security test
    )
    
    for query in "${test_queries[@]}"; do
        echo "Testing: $query"
        # Test with different prompts and measure:
        # - JSON validity
        # - Response accuracy  
        # - Security detection
        # - Response time
    done
}
```

## 📈 Performance Tuning

### 🎯 Model-Specific Optimizations

```bash
# Ollama için optimize edilmiş ayarlar
_configure_ollama_params() {
    local model="$1"
    
    case "$model" in
        "codellama"*)
            export OLLAMA_NUM_CTX=4096
            export OLLAMA_TEMPERATURE=0.1
            export OLLAMA_TOP_P=0.9
            ;;
        "llama3.1"*)
            export OLLAMA_NUM_CTX=8192
            export OLLAMA_TEMPERATURE=0.2
            export OLLAMA_TOP_P=0.8
            ;;
        "qwen2.5-coder"*)
            export OLLAMA_NUM_CTX=4096
            export OLLAMA_TEMPERATURE=0.1
            export OLLAMA_TOP_P=0.9
            ;;
    esac
}
```

### 🚀 Response Quality Metrics

```bash
# Response quality assessment
_assess_response_quality() {
    local response="$1"
    local score=0
    
    # JSON validity check
    if echo "$response" | jq . >/dev/null 2>&1; then
        ((score += 3))
    fi
    
    # Required field check
    if echo "$response" | jq -e '.command or .explanation' >/dev/null 2>&1; then
        ((score += 2))
    fi
    
    # Security check
    if [[ "$response" =~ "DANGER" ]]; then
        ((score += 5))  # Bonus for security detection
    fi
    
    echo $score
}
```

## 🛠️ Troubleshooting

### Yaygın Sorunlar

#### JSON Parse Hatası

```bash
# Çözüm: Enhanced prompts kullan
source ./enhanced_prompts.zsh
response=$(_call_llm_enhanced "query" "command")
```

#### Yavaş Yanıt

```bash
# Çözüm: Daha hızlı model kullan
export LLM_MODEL="codellama:7b-instruct"
export LLM_TIMEOUT=15
```

#### Güvenlik False Positive

```bash
# Çözüm: Security threshold ayarla
export SECURITY_THRESHOLD=0.8
```

Bu öneriler Smart Execute v2.0 için optimize edilmiş model seçimi ve prompt engineering stratejisi sunuyor. Özellikle terminal kullanımı için tasarlanmış modeller ve güvenlik odaklı prompt'lar kullanarak daha iyi sonuçlar elde edebilirsiniz.
