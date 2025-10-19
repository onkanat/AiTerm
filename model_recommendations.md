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
|-------|-----|----------|----------|---------|-------------------|
| CodeLlama 7B | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Llama 3.1 8B | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| GPT-4o Mini | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Claude 3.5 Haiku | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |

## 🎯 Optimize Edilmiş System Prompt'lar

### 📋 Mevcut Durumun Analizi

**Mevcut Prompt'taki Sorunlar:**
- Türkçe/İngilizce karışıklığı
- JSON format garantisi yetersiz  
- Güvenlik tespiti belirsiz
- Komut/açıklama modu ayrımı net değil

### 🔧 Geliştirilmiş System Prompt v2.1

```json
{
  "system_prompt_v2.1": {
    "base": "You are an expert Linux/macOS terminal assistant. You MUST respond with ONLY valid JSON - no other text, explanations, or formatting.",
    "critical_rules": [
      "ALWAYS return valid JSON on a single line",
      "NEVER include markdown, code blocks, or explanations", 
      "Use proper JSON escaping for special characters",
      "Detect user intent: command generation OR explanation"
    ],
    "response_modes": {
      "command_mode": {
        "format": "{\"command\": \"actual_shell_command\"}",
        "examples": [
          "{\"command\": \"find . -name '*.txt' -type f\"}",
          "{\"command\": \"ps aux | grep python\"}"
        ]
      },
      "explanation_mode": {
        "format": "{\"explanation\": \"clear_explanation_in_user_language\"}",
        "examples": [
          "{\"explanation\": \"Bu komut mevcut dizindeki tüm .txt dosyalarını bulur\"}",
          "{\"explanation\": \"This command shows all running Python processes\"}"
        ]
      }
    },
    "security": {
      "dangerous_detection": "If request is potentially harmful, return: {\"command\": \"DANGER\"} or {\"explanation\": \"DANGER\"}",
      "dangerous_patterns": [
        "System destruction (rm -rf /, dd commands)",
        "Privilege escalation attempts",
        "Network attacks or malicious downloads",
        "Data exfiltration attempts",
        "Fork bombs or system overload"
      ]
    }
  }
}
```

### 🎨 Dil-Özel Prompt Varyantları

#### **Türkçe Optimized Prompt**
```bash
SYSTEM_MESSAGE_TR="Sen uzman bir Linux/macOS terminal asistanısın. SADECE geçerli JSON formatında yanıt ver - başka hiçbir metin, açıklama veya format kullanma.

KRİTİK KURALLAR:
- Her zaman tek satırda geçerli JSON döndür
- Markdown, kod blokları veya açıklamalar ekleme
- Özel karakterler için doğru JSON escaping kullan
- Kullanıcı amacını tespit et: komut üretimi VEYA açıklama

YANIT MODLARİ:
1. KOMUT MODU: {\"command\": \"gerçek_shell_komutu\"}
2. AÇIKLAMA MODU: {\"explanation\": \"net_açıklama_türkçe\"}

GÜVENLİK: Tehlikeli isteklerde {\"command\": \"DANGER\"} veya {\"explanation\": \"DANGER\"} döndür.

TEHLİKELİ ÖRÜNTÜLER: sistem yıkımı, yetki yükseltme, ağ saldırıları, veri sızıntısı, fork bombası."
```

#### **English Optimized Prompt**
```bash
SYSTEM_MESSAGE_EN="You are an expert Linux/macOS terminal assistant. Respond with ONLY valid JSON - no other text, explanations, or formatting.

CRITICAL RULES:
- Always return valid JSON on single line
- Never include markdown, code blocks, or explanations
- Use proper JSON escaping for special characters  
- Detect user intent: command generation OR explanation

RESPONSE MODES:
1. COMMAND MODE: {\"command\": \"actual_shell_command\"}
2. EXPLANATION MODE: {\"explanation\": \"clear_explanation_in_english\"}

SECURITY: For dangerous requests return {\"command\": \"DANGER\"} or {\"explanation\": \"DANGER\"}.

DANGEROUS PATTERNS: system destruction, privilege escalation, network attacks, data exfiltration, fork bombs."
```

### 🔄 Dinamik Prompt Seçimi

```bash
# Kullanıcı dili algılama ve prompt seçimi
_detect_user_language() {
    local input="$1"
    
    # Türkçe karakter/kelime kontrolü
    if [[ "$input" =~ [çğıöşüÇĞIİÖŞÜ] ]] || \
       [[ "$input" =~ (dosya|dizin|listele|göster|bul|sil|kopyala|taşı) ]]; then
        echo "tr"
    else
        echo "en"
    fi
}

_get_optimized_prompt() {
    local language="$1"
    local mode="$2"
    
    case "$language" in
        "tr") echo "$SYSTEM_MESSAGE_TR" ;;
        "en") echo "$SYSTEM_MESSAGE_EN" ;;
        *) echo "$SYSTEM_MESSAGE_EN" ;;
    esac
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

Bu öneriler Smart Execute v2.0 için optimize edilmiş model seçimi ve prompt engineering stratejisi sunuyor. Özellikle terminal kullanımı için tasarlanmış modeller ve güvenlik odaklı prompt'lar kullanarak daha iyi sonuçlar elde edebilirsiniz.