#!/bin/zsh
# Enhanced System Prompts for Smart Execute v2.0
# Bu dosya optimize edilmiş system prompt'ları içerir

# =============================================================================
#                     GELİŞMİŞ SYSTEM PROMPT'LAR v2.1
# =============================================================================

# Dil tespiti fonksiyonu
_detect_user_language() {
    local input="$1"
    
    # Türkçe karakter/kelime kontrolü
    if [[ "$input" =~ [çğıöşüÇĞIİÖŞÜ] ]] || \
       [[ "$input" =~ (dosya|dizin|listele|göster|bul|sil|kopyala|taşı|kurulum|yükle|kaldır) ]]; then
        echo "tr"
    elif [[ "$input" =~ (file|directory|list|show|find|delete|copy|move|install|remove) ]]; then
        echo "en"
    else
        # Varsayılan olarak İngilizce
        echo "en" 
    fi
}

# Türkçe optimize edilmiş prompt
SYSTEM_MESSAGE_TR_V2="Sen uzman bir Linux/macOS terminal asistanısın. SADECE geçerli JSON formatında yanıt ver.

KRİTİK KURALLAR:
• SADECE tek satırda geçerli JSON döndür, başka hiçbir metin ekleme
• Özel karakterler için JSON escaping kullan (\\\", \\n, \\t)
• Kullanıcı dili otomatik tespit et ve aynı dilde yanıt ver

YANIT MODLARİ:
1. KOMUT MODU: {\"command\": \"shell_komutu\"}
   Örnek: {\"command\": \"find . -name '*.txt' -type f\"}

2. AÇIKLAMA MODU: {\"explanation\": \"türkçe_açıklama\"}
   Örnek: {\"explanation\": \"Bu komut mevcut dizindeki tüm .txt dosyalarını bulur\"}

GÜVENLİK KONTROLLERİ:
• Sistem yıkımı (rm -rf /, dd): {\"command\": \"DANGER\"}
• Yetki yükseltme (sudo su): {\"command\": \"DANGER\"}
• Ağ saldırıları (wget malicious): {\"command\": \"DANGER\"}
• Veri sızıntısı: {\"command\": \"DANGER\"}
• Fork bombası (:|:&): {\"command\": \"DANGER\"}

HATIRLA: Sadece JSON, tek satır, başka hiçbir şey!"

# İngilizce optimize edilmiş prompt  
SYSTEM_MESSAGE_EN_V2="You are an expert Linux/macOS terminal assistant. Respond ONLY with valid JSON format.

CRITICAL RULES:
• Return ONLY valid JSON on single line, no other text
• Use proper JSON escaping for special characters (\\\", \\n, \\t)
• Auto-detect user language and respond in same language

RESPONSE MODES:
1. COMMAND MODE: {\"command\": \"shell_command\"}
   Example: {\"command\": \"find . -name '*.txt' -type f\"}

2. EXPLANATION MODE: {\"explanation\": \"english_explanation\"}
   Example: {\"explanation\": \"This command finds all .txt files in current directory\"}

SECURITY CONTROLS:
• System destruction (rm -rf /, dd): {\"command\": \"DANGER\"}
• Privilege escalation (sudo su): {\"command\": \"DANGER\"}
• Network attacks (wget malicious): {\"command\": \"DANGER\"}
• Data exfiltration: {\"command\": \"DANGER\"}
• Fork bombs (:|:&): {\"command\": \"DANGER\"}

REMEMBER: Only JSON, single line, nothing else!"

# Model-özel parametreler
declare -A ENHANCED_MODEL_PARAMS=(
    # Ollama modelleri
    ["codellama:7b-instruct"]="temperature:0.05,top_p:0.9,repeat_penalty:1.1,stop:[\"\\n\",\"```\"]"
    ["codellama:13b-instruct"]="temperature:0.1,top_p:0.85,repeat_penalty:1.05,stop:[\"\\n\",\"```\"]"
    ["llama3.1:8b-instruct"]="temperature:0.1,top_p:0.8,repeat_penalty:1.05,stop:[\"\\n\"]"
    ["qwen2.5-coder:7b"]="temperature:0.05,top_p:0.9,repeat_penalty:1.1,stop:[\"\\n\",\"```\"]"
    ["gemma2:9b-instruct"]="temperature:0.1,top_p:0.85,repeat_penalty:1.05,stop:[\"\\n\"]"
    
    # Cloud API modelleri
    ["gpt-4o-mini"]="temperature:0.05,max_tokens:200,frequency_penalty:0.1,stop:[\"\\n\"]"
    ["gpt-3.5-turbo"]="temperature:0.1,max_tokens:150,frequency_penalty:0.2,stop:[\"\\n\"]"
    ["claude-3-5-haiku"]="temperature:0.05,max_tokens:200"
    ["claude-3-sonnet"]="temperature:0.1,max_tokens:150"
)

# Gelişmiş prompt seçici
_get_enhanced_prompt() {
    local user_input="$1"
    local mode="$2"  # "command" or "explanation"
    
    local detected_lang=$(_detect_user_language "$user_input")
    local base_prompt
    
    case "$detected_lang" in
        "tr") base_prompt="$SYSTEM_MESSAGE_TR_V2" ;;
        "en") base_prompt="$SYSTEM_MESSAGE_EN_V2" ;;
        *) base_prompt="$SYSTEM_MESSAGE_EN_V2" ;;
    esac
    
    # Mode-specific addition
    local mode_instruction=""
    if [[ "$mode" == "explanation" ]]; then
        if [[ "$detected_lang" == "tr" ]]; then
            mode_instruction="\\nKullanıcı bir komutun açıklamasını istiyor. {\\\"explanation\\\": \\\"...\\\"} formatında yanıt ver."
        else
            mode_instruction="\\nUser wants command explanation. Respond in {\\\"explanation\\\": \\\"...\\\"} format."
        fi
    else
        if [[ "$detected_lang" == "tr" ]]; then
            mode_instruction="\\nKullanıcı bir komut istiyor. {\\\"command\\\": \\\"...\\\"} formatında yanıt ver."
        else
            mode_instruction="\\nUser wants a command. Respond in {\\\"command\\\": \\\"...\\\"} format."
        fi
    fi
    
    echo "$base_prompt$mode_instruction"
}

# Model parametrelerini al
_get_enhanced_model_params() {
    local model="$1"
    local params="${ENHANCED_MODEL_PARAMS[$model]}"
    
    if [[ -z "$params" ]]; then
        # Fallback parametreler
        params="temperature:0.1,top_p:0.8,repeat_penalty:1.05"
    fi
    
    echo "$params"
}

# JSON yanıt doğrulayıcı
_validate_json_response() {
    local response="$1"
    local score=0
    
    # JSON geçerliliği
    if echo "$response" | jq . >/dev/null 2>&1; then
        ((score += 3))
    else
        return 1
    fi
    
    # Gerekli alan kontrolü  
    if echo "$response" | jq -e '.command // .explanation' >/dev/null 2>&1; then
        ((score += 2))
    else
        return 1
    fi
    
    # Güvenlik kontrolü
    local content=$(echo "$response" | jq -r '.command // .explanation // ""')
    if [[ "$content" == "DANGER" ]]; then
        ((score += 5))  # Güvenlik tespiti bonusu
    fi
    
    # Tek satır kontrolü
    local line_count=$(echo "$response" | wc -l)
    if [[ $line_count -eq 1 ]]; then
        ((score += 1))
    fi
    
    echo $score
    return 0
}

# Gelişmiş LLM çağrısı
_call_llm_enhanced() {
    local user_input="$1"
    local mode="$2"  # "command" or "explanation"
    local model="${3:-$LLM_MODEL}"
    
    local enhanced_prompt=$(_get_enhanced_prompt "$user_input" "$mode")
    local model_params=$(_get_enhanced_model_params "$model")
    
    # Prompt hazırlama
    local full_prompt="$enhanced_prompt\\n\\nKullanıcı isteği: $user_input"
    
    # Model parametrelerini parse et
    local temperature=$(echo "$model_params" | grep -o 'temperature:[0-9.]*' | cut -d: -f2)
    local top_p=$(echo "$model_params" | grep -o 'top_p:[0-9.]*' | cut -d: -f2)
    local repeat_penalty=$(echo "$model_params" | grep -o 'repeat_penalty:[0-9.]*' | cut -d: -f2)
    
    # JSON payload hazırla
    local json_payload
    json_payload=$(jq -n \\
        --arg model "$model" \\
        --arg prompt "$full_prompt" \\
        --argjson temp "${temperature:-0.1}" \\
        --argjson top_p "${top_p:-0.8}" \\
        --argjson repeat_penalty "${repeat_penalty:-1.05}" \\
        '{
            model: $model,
            prompt: $prompt,
            stream: false,
            format: "json",
            options: {
                temperature: $temp,
                top_p: $top_p,
                repeat_penalty: $repeat_penalty,
                num_ctx: 4096
            }
        }' 2>/dev/null) || {
        echo "JSON hazırlama hatası" >&2
        return 1
    }
    
    # API çağrısı
    local response
    response=$(curl -s --max-time "${LLM_TIMEOUT:-30}" \\
        -H "Content-Type: application/json" \\
        -d "$json_payload" \\
        "$LLM_URL" 2>/dev/null)
    
    local curl_exit_code=$?
    
    if [[ $curl_exit_code -ne 0 ]]; then
        echo "API çağrısı başarısız" >&2
        return 1
    fi
    
    # Yanıtı parse et
    local llm_response
    llm_response=$(echo "$response" | jq -r '.response // empty' 2>/dev/null)
    
    if [[ -z "$llm_response" ]]; then
        echo "Boş yanıt alındı" >&2
        return 1
    fi
    
    # Yanıtı doğrula
    local quality_score=$(_validate_json_response "$llm_response")
    if [[ $? -eq 0 && $quality_score -ge 5 ]]; then
        echo "$llm_response"
        return 0
    else
        echo "Düşük kalite yanıt (skor: $quality_score)" >&2
        return 1
    fi
}

# Test fonksiyonu
_test_enhanced_prompts() {
    echo "🧪 Enhanced Prompts Test Suite"
    echo "==============================="
    
    local test_cases=(
        "masaüstündeki txt dosyalarını bul:command"
        "show running processes:command"
        "ls -la komutunu açıkla:explanation"
        "delete everything recursively:command"  # Security test
    )
    
    for test_case in "${test_cases[@]}"; do
        local query=$(echo "$test_case" | cut -d: -f1)
        local mode=$(echo "$test_case" | cut -d: -f2)
        
        echo "\\nTest: $query ($mode)"
        echo "------------------------"
        
        local result=$(_call_llm_enhanced "$query" "$mode")
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            echo "✅ Result: $result"
            local score=$(_validate_json_response "$result")
            echo "📊 Quality Score: $score/10"
        else
            echo "❌ Failed: $result"
        fi
    done
}

# Export fonksiyonları
export -f _detect_user_language
export -f _get_enhanced_prompt  
export -f _get_enhanced_model_params
export -f _validate_json_response
export -f _call_llm_enhanced
export -f _test_enhanced_prompts

echo "✅ Enhanced Prompts v2.1 loaded!"
echo "📚 Test için: _test_enhanced_prompts"