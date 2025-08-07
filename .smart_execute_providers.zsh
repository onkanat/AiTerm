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
    ["ollama"]="gemma3:1b-it-qat"
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
    
    # Özel karakterler ve komutlar
    [[ "$query" =~ (\||\&\&|\;|grep|awk|sed|find) ]] && complexity="medium"
    [[ "$query" =~ (while|for|if|case|function|\$\() ]] && complexity="complex"
    
    echo "$complexity"
}

# En uygun provider seçimi
_select_best_provider() {
    local query="$1"
    local complexity=$(_assess_query_complexity "$query")
    
    case "$complexity" in
        "simple")
            echo "${LLM_PROVIDER:-ollama}"
            ;;
        "medium")
            if [[ -n "${LLM_PROVIDERS[openai]}" && "$LLM_PROVIDER" != "ollama" ]]; then
                echo "openai"
            else
                echo "${LLM_PROVIDER:-ollama}"
            fi
            ;;
        "complex")
            if [[ -n "${LLM_PROVIDERS[anthropic]}" && "$LLM_PROVIDER" != "ollama" ]]; then
                echo "anthropic"
            elif [[ -n "${LLM_PROVIDERS[openai]}" && "$LLM_PROVIDER" != "ollama" ]]; then
                echo "openai"
            else
                echo "${LLM_PROVIDER:-ollama}"
            fi
            ;;
    esac
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
    local prompt="$1"
    local mode="$2"
    local model="${LLM_MODELS[ollama]}"
    
    local json_payload
    json_payload=$(jq -n \
                   --arg model "$model" \
                   --arg prompt "$prompt" \
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
    
    # Önce cache'e bak
    response=$(_get_cached_response "$prompt")
    if [[ $? -eq 0 ]]; then
        echo "$response"
        return 0
    fi
    
    # Primary provider'ı dene
    _audit_log "LLM" "TRYING_PRIMARY" "Provider: $primary_provider"
    response=$(_call_llm_provider "$primary_provider" "$prompt" "$mode")
    local exit_code=$?
    
    if [[ $exit_code -eq 0 && -n "$response" ]]; then
        _cache_response "$prompt" "$response"
        echo "$response"
        return 0
    fi
    
    # Fallback provider'ı dene
    if [[ "$FALLBACK_PROVIDER" != "$primary_provider" ]]; then
        _audit_log "LLM" "TRYING_FALLBACK" "Provider: $FALLBACK_PROVIDER"
        response=$(_call_llm_provider "$FALLBACK_PROVIDER" "$prompt" "$mode")
        exit_code=$?
        
        if [[ $exit_code -eq 0 && -n "$response" ]]; then
            _cache_response "$prompt" "$response"
            echo "$response"
            return 0
        fi
    fi
    
    _audit_log "ERROR" "ALL_PROVIDERS_FAILED" "Primary: $primary_provider, Fallback: $FALLBACK_PROVIDER"
    return 1
}

# Provider yanıtını parse etme
_parse_provider_response() {
    local provider="$1"
    local response="$2"
    local field="$3"
    
    case "$provider" in
        "ollama")
            echo "$response" | jq -r '.response // ""' 2>/dev/null
            ;;
        "openai")
            echo "$response" | jq -r '.choices[0].message.content // ""' 2>/dev/null
            ;;
        "anthropic")
            echo "$response" | jq -r '.content[0].text // ""' 2>/dev/null
            ;;
        *)
            echo "$response"
            ;;
    esac
}
