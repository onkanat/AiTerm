#!/bin/zsh
# Smart Execute Multi-LLM Provider Module
# Bu dosya çoklu LLM sağlayıcı desteğini içerir

# LLM Provider yapılandırması
declare -A LLM_PROVIDERS=(
    ["ollama"]="http://localhost:11434/api/generate"
    ["openai"]="https://api.openai.com/v1/completions"
    ["anthropic"]="https://api.anthropic.com/v1/messages"
)

declare -A LLM_MODELS=(
    ["ollama"]="${LLM_MODEL:-gemma3:1b-it-qat}"
    ["openai"]="gpt-3.5-turbo"
    ["anthropic"]="claude-3-sonnet-20240229"
)

# Sorgu karmaşıklığını değerlendirme
_assess_query_complexity() {
    local query="$1"
    local complexity="simple"
    
    # Karmaşıklık faktörleri
    local word_count=$(echo "$query" | wc -w)
    [[ $word_count -gt 10 ]] && complexity="medium"
    [[ $word_count -gt 20 ]] && complexity="complex"
    
    # Özel karakterler ve komutlar (zsh uyumlu regex)
    if [[ "$query" =~ '(\||\&\&|\;|grep|awk|sed|find)' ]]; then
        complexity="medium"
    fi
    if [[ "$query" =~ '(while|for|if|case|function|\$\()' ]]; then
        complexity="complex"
    fi
    
    echo "$complexity"
}

# En uygun provider seçimi
_select_best_provider() {
    local query="$1"
    local complexity=$(_assess_query_complexity "$query")
    
    # Varsayılan olarak mevcut provider'ı kullan
    local selected_provider="${LLM_PROVIDER:-ollama}"
    
    case "$complexity" in
        "simple")
            selected_provider="${LLM_PROVIDER:-ollama}"
            ;;
        "medium")
            if [[ -n "${OPENAI_API_KEY:-}" && "${LLM_PROVIDER:-}" != "ollama" ]]; then
                selected_provider="openai"
            else
                selected_provider="${LLM_PROVIDER:-ollama}"
            fi
            ;;
        "complex")
            if [[ -n "${ANTHROPIC_API_KEY:-}" && "${LLM_PROVIDER:-}" != "ollama" ]]; then
                selected_provider="anthropic"
            elif [[ -n "${OPENAI_API_KEY:-}" && "${LLM_PROVIDER:-}" != "ollama" ]]; then
                selected_provider="openai"
            else
                selected_provider="${LLM_PROVIDER:-ollama}"
            fi
            ;;
    esac
    
    echo "$selected_provider"
}

# Provider'a özel API çağrısı
_call_llm_provider() {
    local provider="$1"
    local prompt="$2"
    local mode="$3"
    
    case "$provider" in
        "ollama")
            _call_ollama "$prompt" "$mode"
            ;;
        "openai")
            _call_openai "$prompt" "$mode"
            ;;
        "anthropic")
            _call_anthropic "$prompt" "$mode"
            ;;
        *)
            _audit_log "ERROR" "UNKNOWN_PROVIDER" "Provider: $provider"
            return 1
            ;;
    esac
}

# Ollama API çağrısı
_call_ollama() {
    local user_prompt="$1"
    local mode="$2"
    local model="${LLM_MODELS[ollama]}"
    
    # Prompt hazırlama
    local full_prompt
    if [[ "$mode" == "explanation" ]]; then
        full_prompt="Sen Linux/macOS terminal uzmanısın. Kullanıcı isteklerini analiz edip SADECE JSON formatında yanıt veriyorsun.

KRİTİK KURALLAR:
1. SADECE JSON formatında yanıt ver, başka hiçbir şey yazma
2. JSON objesi tek satırda olmalı, hiç yeni satır olmasın  
3. Türkçe karakterleri doğru encode et

İKİ MOD VAR:
A) KOMUT MODU: Kullanıcı bir işlem yaptırmak istiyorsa
   Örnek: {\"command\":\"ls -l > dosya.txt\"}
   
B) AÇIKLAMA MODU: Kullanıcı bir şeyin nasıl yapıldığını öğrenmek istiyorsa  
   Örnek: {\"explanation\":\"Komut çıktısını dosyaya yazmak için '>' operatörü kullanılır.\"}

TEHLİKELİ KOMUTLAR:
Tehlikeli isteklerde: {\"command\":\"DANGER\"} veya {\"explanation\":\"DANGER\"}

HATIRLA: Tek JSON objesi, tek satır, başka hiçbir şey yazma!
Kullanıcı bir komutun açıklamasını istiyor. Yanıtını {\"explanation\": \"...\"} formatında ver.
İstek: $user_prompt"
    else
        full_prompt="Sen Linux/macOS terminal uzmanısın. Kullanıcı isteklerini analiz edip SADECE JSON formatında yanıt veriyorsun.

KRİTİK KURALLAR:
1. SADECE JSON formatında yanıt ver, başka hiçbir şey yazma
2. JSON objesi tek satırda olmalı, hiç yeni satır olmasın  
3. Türkçe karakterleri doğru encode et

İKİ MOD VAR:
A) KOMUT MODU: Kullanıcı bir işlem yaptırmak istiyorsa
   Örnek: {\"command\":\"ls -l > dosya.txt\"}
   
B) AÇIKLAMA MODU: Kullanıcı bir şeyin nasıl yapıldığını öğrenmek istiyorsa  
   Örnek: {\"explanation\":\"Komut çıktısını dosyaya yazmak için '>' operatörü kullanılır.\"}

TEHLİKELİ KOMUTLAR:
Tehlikeli isteklerde: {\"command\":\"DANGER\"} veya {\"explanation\":\"DANGER\"}

HATIRLA: Tek JSON objesi, tek satır, başka hiçbir şey yazma!
Kullanıcı bir komut istiyor. Yanıtını {\"command\": \"...\"} formatında ver.
İstek: $user_prompt"
    fi
    
    local json_payload
    json_payload=$(jq -n \
                   --arg model "$model" \
                   --arg prompt "$full_prompt" \
                   '{model: $model, prompt: $prompt, stream: false, format: "json"}')
    
    curl -s --max-time $LLM_TIMEOUT \
         -X POST "${LLM_PROVIDERS[ollama]}" \
         -H "Content-Type: application/json" \
         -d "$json_payload"
}

# OpenAI API çağrısı
_call_openai() {
    local prompt="$1"
    local mode="$2"
    local model="${LLM_MODELS[openai]}"
    local api_key_file="$SMART_EXECUTE_CONFIG_DIR/openai_api_key"
    
    if [[ ! -f "$api_key_file" ]]; then
        _audit_log "ERROR" "OPENAI_NO_API_KEY" "Key file not found: $api_key_file"
        return 1
    fi
    
    local api_key=$(cat "$api_key_file")
    
    local json_payload
    json_payload=$(jq -n \
                   --arg model "$model" \
                   --arg prompt "$prompt" \
                   '{
                     model: $model,
                     messages: [{"role": "user", "content": $prompt}],
                     max_tokens: 150,
                     temperature: 0.1
                   }')
    
    curl -s --max-time $LLM_TIMEOUT \
         -X POST "https://api.openai.com/v1/chat/completions" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $api_key" \
         -d "$json_payload"
}

# Anthropic API çağrısı
_call_anthropic() {
    local prompt="$1"
    local mode="$2"
    local model="${LLM_MODELS[anthropic]}"
    local api_key_file="$SMART_EXECUTE_CONFIG_DIR/anthropic_api_key"
    
    if [[ ! -f "$api_key_file" ]]; then
        _audit_log "ERROR" "ANTHROPIC_NO_API_KEY" "Key file not found: $api_key_file"
        return 1
    fi
    
    local api_key=$(cat "$api_key_file")
    
    local json_payload
    json_payload=$(jq -n \
                   --arg model "$model" \
                   --arg prompt "$prompt" \
                   '{
                     model: $model,
                     max_tokens: 150,
                     messages: [{"role": "user", "content": $prompt}]
                   }')
    
    curl -s --max-time $LLM_TIMEOUT \
         -X POST "${LLM_PROVIDERS[anthropic]}" \
         -H "Content-Type: application/json" \
         -H "x-api-key: $api_key" \
         -H "anthropic-version: 2023-06-01" \
         -d "$json_payload"
}

# Fallback mekanizması ile LLM çağrısı
_call_llm_with_fallback() {
    local prompt="$1"
    local mode="$2"
    local primary_provider=$(_select_best_provider "$prompt")
    local response
    
    # Önce cache'e bak (eğer cache fonksiyonu varsa)
    if [[ "$(whence -w _get_cached_response 2>/dev/null)" == *function* ]]; then
        response=$(_get_cached_response "$prompt")
        if [[ $? -eq 0 && -n "$response" ]]; then
            echo "$response"
            return 0
        fi
    fi
    
    # Primary provider'ı dene
    if [[ "$(whence -w _audit_log 2>/dev/null)" == *function* ]]; then
        _audit_log "LLM" "TRYING_PRIMARY" "Provider: $primary_provider"
    fi
    
    local raw_response
    raw_response=$(_call_llm_provider "$primary_provider" "$prompt" "$mode")
    local exit_code=$?
    
    if [[ $exit_code -eq 0 && -n "$raw_response" ]]; then
        # Response'u provider'a göre parse et
        response=$(_parse_provider_response "$primary_provider" "$raw_response" "$mode")
        
        if [[ -n "$response" && "$response" != "null" ]]; then
            # Cache'e kaydet (eğer cache fonksiyonu varsa)
            if [[ "$(whence -w _cache_response 2>/dev/null)" == *function* ]]; then
                _cache_response "$prompt" "$response"
            fi
            echo "$response"
            return 0
        fi
    fi
    
    # Fallback provider'ı dene (eğer tanımlıysa ve farklıysa)
    if [[ -n "$FALLBACK_PROVIDER" && "$FALLBACK_PROVIDER" != "$primary_provider" ]]; then
        if [[ "$(whence -w _audit_log 2>/dev/null)" == *function* ]]; then
            _audit_log "LLM" "TRYING_FALLBACK" "Provider: $FALLBACK_PROVIDER"
        fi
        
        raw_response=$(_call_llm_provider "$FALLBACK_PROVIDER" "$prompt" "$mode")
        exit_code=$?
        
        if [[ $exit_code -eq 0 && -n "$raw_response" ]]; then
            response=$(_parse_provider_response "$FALLBACK_PROVIDER" "$raw_response" "$mode")
            
            if [[ -n "$response" && "$response" != "null" ]]; then
                if [[ "$(whence -w _cache_response 2>/dev/null)" == *function* ]]; then
                    _cache_response "$prompt" "$response"
                fi
                echo "$response"
                return 0
            fi
        fi
    fi
    
    if [[ "$(whence -w _audit_log 2>/dev/null)" == *function* ]]; then
        _audit_log "ERROR" "ALL_PROVIDERS_FAILED" "Primary: $primary_provider, Fallback: $FALLBACK_PROVIDER"
    fi
    return 1
}

# Provider yanıtını parse etme
_parse_provider_response() {
    local provider="$1"
    local raw_response="$2"
    local mode="$3"
    local parsed_response
    
    # İlk olarak provider'a göre temel response'u çıkart
    case "$provider" in
        "ollama")
            parsed_response=$(echo "$raw_response" | jq -r '.response // ""' 2>/dev/null)
            ;;
        "openai")
            parsed_response=$(echo "$raw_response" | jq -r '.choices[0].message.content // ""' 2>/dev/null)
            ;;
        "anthropic")
            parsed_response=$(echo "$raw_response" | jq -r '.content[0].text // ""' 2>/dev/null)
            ;;
        *)
            parsed_response="$raw_response"
            ;;
    esac
    
    # Eğer parsed_response boş ise ham response'u kullan
    if [[ -z "$parsed_response" || "$parsed_response" == "null" ]]; then
        parsed_response="$raw_response"
    fi
    
    # Şimdi mode'a göre command/explanation çıkart
    if echo "$parsed_response" | jq . >/dev/null 2>&1; then
        # JSON ise içinden field çıkart
        if [[ "$mode" == "explanation" ]]; then
            local explanation=$(echo "$parsed_response" | jq -r '.explanation // empty' 2>/dev/null)
            if [[ -n "$explanation" && "$explanation" != "null" ]]; then
                echo "$explanation"
                return 0
            fi
        else
            local command=$(echo "$parsed_response" | jq -r '.command // empty' 2>/dev/null)
            if [[ -n "$command" && "$command" != "null" ]]; then
                echo "$command"
                return 0
            fi
        fi
    fi
    
    # JSON değilse veya field bulunamadıysa, raw response'u döndür
    echo "$parsed_response"
}
