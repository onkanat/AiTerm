#!/bin/zsh
# Smart Execute Multi-LLM Provider Module
# Bu dosya çoklu LLM sağlayıcı desteğini içerir

# LLM Provider yapılandırması
declare -A LLM_PROVIDERS=(
    ["ollama"]="http://localhost:11434/api/generate"
    ["ollama_remote"]="http://192.168.1.14:11434/api/generate"
    ["openai"]="https://api.openai.com/v1/chat/completions"
    ["anthropic"]="https://api.anthropic.com/v1/messages"
    ["gemini"]="https://generativelanguage.googleapis.com/v1beta/models"
)

declare -A LLM_MODELS=(
    ["ollama"]="${LLM_MODEL:-gemma3:1b-it-qat}"
    ["ollama_remote"]="devstral-small-2:latest"
    ["openai"]="gpt-3.5-turbo"
    ["anthropic"]="claude-3-sonnet-20240229"
    ["gemini"]="gemini-3.1-pro-preview"
)

# Sorgu karmaşıklığını değerlendirme
_assess_query_complexity() {
    local query="$1"
    local complexity="simple"
    
    # Karmaşıklık faktörleri
    local word_count=$(echo "$query" | wc -w)
    [[ $word_count -gt 10 ]] && complexity="medium"
    [[ $word_count -gt 20 ]] && complexity="complex"
    
    # Özel karakterler ve komutlar
    if [[ "$query" =~ '(\||\&\&|\;|grep|awk|sed|find)' ]]; then
        complexity="medium"
    fi
    if [[ "$query" =~ '(while|for|if|case|function|\$\(|\{\})' ]]; then
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
    
    # Eğer Gemini API key varsa ve karmaşıklık yüksekse Gemini'yi seç
    if [[ -n "${GEMINI_API_KEY:-}" ]]; then
        if [[ "$complexity" == "complex" || "$complexity" == "medium" ]]; then
            selected_provider="gemini"
            return 0
        fi
    fi

    # Fallback mantığı
    case "$complexity" in
        "simple")
            selected_provider="ollama"
            ;;
        "medium"|"complex")
            if [[ -n "${OPENAI_API_KEY:-}" ]]; then
                selected_provider="openai"
            else
                selected_provider="ollama"
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
        "ollama")     _call_ollama "$prompt" "$mode" "localhost" ;;
        "ollama_remote") _call_ollama "$prompt" "$mode" "192.168.1.14" ;;
        "openai")     _call_openai "$prompt" "$mode" ;;
        "anthropic")  _call_anthropic "$prompt" "$mode" ;;
        "gemini")     _call_gemini "$prompt" "$mode" ;;
        *)
            _audit_log "ERROR" "UNKNOWN_PROVIDER" "Provider: $provider"
            return 1
            ;;
    esac
}

# Gemini API çağrısı (Google One Pro / AI Studio)
_call_gemini() {
    local user_prompt="$1"
    local mode="$2"
    local model="${LLM_MODELS[gemini]}"
    local api_key="${GEMINI_API_KEY:-}"

    if [[ -z "$api_key" ]]; then
        _audit_log "ERROR" "GEMINI_NO_API_KEY" "API Key not found in environment"
        return 1
    fi

    # System prompt'u Gemini formatına uyarla
    local system_instr="Sen Linux/macOS terminal uzmanısın. Kullanıcı isteklerini analiz edip SADECE JSON formatında yanıt veriyorsun. JSON objesi tek satırda olmalı. Türkçe karakterleri doğru encode et. MODLAR: A) KOMUT MODU: {\"command\":\"ls -l\"} B) AÇIKLAMA MODU: {\"explanation\":\"Açıklama...\"}"
    
    local json_payload
    json_payload=$(jq -n \
        --arg sys "$system_instr" \
        --arg prompt "$user_prompt" \
        '{
            contents: [{ parts: [{ text: ($sys + "\n\nİstek: " + $prompt) }] }],
            generationConfig: { response_mime_type: "application/json", temperature: 0.1 }
        }')

    curl -s --max-time $LLM_TIMEOUT \
         -X POST "${LLM_PROVIDERS[gemini]}/${model}:generateContent?key=${api_key}" \
         -H "Content-Type: application/json" \
         -d "$json_payload"
}

# Ollama API çağrısı (Local ve Remote destekli)
_call_ollama() {
    local user_prompt="$1"
    local mode="$2"
    local host="${3:-localhost}"
    local url="http://${host}:11434/api/generate"
    local model
    
    if [[ "$host" == "localhost" ]]; then
        model="${LLM_MODELS[ollama]}"
    else
        model="${LLM_MODELS[ollama_remote]}"
    fi
    
    local full_prompt="$SYSTEM_MESSAGE\nİstek: $user_prompt"
    
    local json_payload
    json_payload=$(jq -n \
                   --arg model "$model" \
                   --arg prompt "$full_prompt" \
                   '{model: $model, prompt: $prompt, stream: false, format: "json"}')
    
    curl -s --max-time $LLM_TIMEOUT \
         -X POST "$url" \
         -H "Content-Type: application/json" \
         -d "$json_payload"
}

# Fallback mekanizması ile LLM çağrısı
_call_llm_with_fallback() {
    local prompt="$1"
    local mode="$2"
    local primary_provider=$(_select_best_provider "$prompt")
    
    # Sırasıyla dene: Primary -> Local Ollama -> Remote Ollama
    local providers_to_try=("$primary_provider" "ollama" "ollama_remote")
    
    for provider in "${providers_to_try[@]}"; do
        [[ -z "$provider" ]] && continue
        
        _audit_log "LLM" "TRYING_PROVIDER" "Provider: $provider"
        
        local raw_response
        raw_response=$(_call_llm_provider "$provider" "$prompt" "$mode")
        
        if [[ $? -eq 0 && -n "$raw_response" ]]; then
            local response=$(_parse_provider_response "$provider" "$raw_response" "$mode")
            if [[ -n "$response" && "$response" != "null" && "$response" != "" ]]; then
                echo "$response"
                return 0
            fi
        fi
    done
    
    return 1
}

# Provider yanıtını parse etme
_parse_provider_response() {
    local provider="$1"
    local raw_response="$2"
    local mode="$3"
    local parsed_text
    
    case "$provider" in
        "gemini")
            parsed_text=$(echo "$raw_response" | jq -r '.candidates[0].content.parts[0].text // ""' 2>/dev/null)
            ;;
        "ollama"|"ollama_remote")
            parsed_text=$(echo "$raw_response" | jq -r '.response // ""' 2>/dev/null)
            ;;
        "openai")
            parsed_text=$(echo "$raw_response" | jq -r '.choices[0].message.content // ""' 2>/dev/null)
            ;;
        "anthropic")
            parsed_text=$(echo "$raw_response" | jq -r '.content[0].text // ""' 2>/dev/null)
            ;;
    esac
    
    # JSON içinden asıl veriyi çek
    if echo "$parsed_text" | jq . >/dev/null 2>&1; then
        if [[ "$mode" == "explanation" ]]; then
            echo "$parsed_text" | jq -r '.explanation // empty'
        else
            echo "$parsed_text" | jq -r '.command // empty'
        fi
    else
        echo "$parsed_text"
    fi
}
