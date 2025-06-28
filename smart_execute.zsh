#!/bin/zsh

# =================== AYARLAR VE GLOBAL DEĞİŞKENLER =====================

# Birleşik ve geliştirilmiş sistem mesajı
SYSTEM_MESSAGE="Sen uzman bir Linux/macOS kabuk yardımcısısın. Kullanıcıdan gelen isteği analiz edip, isteğin türüne göre JSON formatında bir yanıt üreteceksin. Yanıtların daima tek bir JSON objesi olmalıdır.
- Eğer kullanıcı bir komut istiyorsa, yanıtın {\"command\": \"üretilen_komut\"} şeklinde olmalıdır.
- Eğer kullanıcı bir açıklama istiyorsa, yanıtın {\"explanation\": \"detaylı_açıklama\"} şeklinde olmalıdır.
- Eğer kullanıcı isteği tehlikeli veya yıkıcı ise (rm -rf /, dd, vb.), yanıtın {\"command\": \"DANGER\"} veya {\"explanation\": \"DANGER\"} olmalıdır.
Asla düz metin veya JSON dışında bir formatta cevap verme."

# Dosya yolları ve ayarlar
SMART_EXECUTE_CONFIG_DIR="$HOME/.config/smart_execute"
BLACKLIST_FILE="$SMART_EXECUTE_CONFIG_DIR/blacklist.txt"
WHITELIST_FILE="$SMART_EXECUTE_CONFIG_DIR/whitelist.txt"
LOG_FILE="$SMART_EXECUTE_CONFIG_DIR/log.txt"

LLM_URL="http://localhost:11434/api/generate"
LLM_MODEL="gemma3:1b-it-qat"
LLM_TIMEOUT=60

# Global diziler (performans için bir kez yüklenir)
typeset -g BLACKLIST_PATTERNS=()
typeset -g WHITELIST_PATTERNS=()

# =================== YARDIMCI FONKSİYONLAR =====================

# Loglama fonksiyonu
_smart_log() {
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1 | $2" >> "$LOG_FILE"
}

# Listeleri diskten global dizilere yükleyen fonksiyon
_smart_load_lists() {
    # Kara Liste
    if [[ -f "$BLACKLIST_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && BLACKLIST_PATTERNS+=("$line")
        done < "$BLACKLIST_FILE"
    else
        mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
        cat <<EOF > "$BLACKLIST_FILE"
# Tehlikeli Komutlar İçin Regex Kara Listesi
rm\s+-rf\s+/
rm\s+-rf\s+\.\.?/
:(){:|:&};
dd\s+.*of=/dev/(sd|nvme).*
mkfs.* /dev/(sd|nvme).*
chmod\s+-R\s+777\s+/
mv\s+.*\s+/dev/null
EOF
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && BLACKLIST_PATTERNS+=("$line")
        done < "$BLACKLIST_FILE"
    fi

    # Beyaz Liste
    if [[ -f "$WHITELIST_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && WHITELIST_PATTERNS+=("$line")
        done < "$WHITELIST_FILE"
    else
        mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
        cat <<EOF > "$WHITELIST_FILE"
# Güvenli ve sık kullanılan komutlar
ls
cd
pwd
git status
git diff
source
EOF
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && WHITELIST_PATTERNS+=("$line")
        done < "$WHITELIST_FILE"
    fi
}

# Regex tabanlı kara liste kontrolü
_is_blacklisted() {
    for pattern in "${BLACKLIST_PATTERNS[@]}"; do
        if [[ "$1" =~ $pattern ]]; then
            _smart_log "BLACKLIST_MATCH" "Input: '$1' | Pattern: '$pattern'"
            return 0
        fi
    done
    return 1
}

# Tam eşleşme tabanlı beyaz liste kontrolü
_is_whitelisted() {
    local input_command="$1"
    if [[ ${#WHITELIST_PATTERNS[@]} -eq 0 ]]; then return 1; fi
    for pattern in "${WHITELIST_PATTERNS[@]}"; do
        if [[ "$input_command" == "$pattern" ]]; then
            _smart_log "WHITELIST_MATCH" "Input: '$input_command' | Pattern: '$pattern'"
            return 0
        fi
    done
    return 1
}

# Merkezi LLM API Çağrı Fonksiyonu
_call_llm() {
    local user_prompt="$1"
    local mode="$2"
    local full_prompt

    if [[ "$mode" == "explanation" ]]; then
        full_prompt="$SYSTEM_MESSAGE\nKullanıcı bir komutun açıklamasını istiyor. Yanıtını {\"explanation\": \"...\"} formatında ver.\nİstek: $user_prompt"
    else
        full_prompt="$SYSTEM_MESSAGE\nKullanıcı bir komut istiyor. Yanıtını {\"command\": \"...\"} formatında ver.\nİstek: $user_prompt"
    fi

    # Bilgilendirme mesajlarını stderr'e (> &2) göndererek yakalanmalarını önle
    echo -n $'\n\e[2m🧠 LLM düşünüyor...\e[0m' >&2

    local json_payload
    json_payload=$(jq -n \
                   --arg model "$LLM_MODEL" \
                   --arg prompt "$full_prompt" \
                   '{model: $model, prompt: $prompt, stream: false, format: "json"}')

    local response
    response=$(curl -s --max-time $LLM_TIMEOUT -X POST "$LLM_URL" \
      -H "Content-Type: application/json" \
      -d "$json_payload")
    local curl_exit_code=$?

    # Mesajı temizle (yine stderr'e)
    echo -ne "\r\e[K" >&2

    if [[ $curl_exit_code -ne 0 ]]; then
        echo -e "\n\e[31m❌ Hata: LLM API'sine bağlanılamadı (curl çıkış kodu: $curl_exit_code).\e[0m" >&2
        _smart_log "LLM_CONNECTION_ERROR" "curl exit code: $curl_exit_code"
        return 1
    fi

    if ! echo "$response" | jq -e . >/dev/null 2>&1; then
        echo -e "\n\e[31m❌ Hata: LLM'den geçersiz JSON yanıtı alındı.\e[0m Yanıt: $response" >&2
        _smart_log "INVALID_JSON" "Response: $response"
        return 1
    fi

    local response_field
    response_field=$(echo "$response" | jq -r '.response // ""')

    if [[ -z "$response_field" ]]; then
        echo -e "\n\e[31m❌ Hata: LLM boş bir 'response' alanı döndürdü.\e[0m" >&2
        _smart_log "LLM_EMPTY_RESPONSE_FIELD" "Ham Cevap: $response"
        return 1
    fi

    # Sadece temiz yanıtı stdout'a gönder
    echo "$response_field"
    return 0
}

# =================== ANA ZLE WIDGET'I =====================

smart_accept_line() {
    local original_command="$BUFFER"
    local user_command
    local mode

    if [[ "$original_command" == /* ]]; then
        BUFFER="${original_command#/}"
        zle .accept-line
        return
    fi

    if [[ -z "$original_command" ]]; then
        zle .accept-line
        return
    fi

    if [[ "$original_command" == @\?* ]]; then
        mode="explanation"
        user_command="${original_command#@?}"
    elif [[ "$original_command" == @* ]]; then
        mode="command"
        user_command="${original_command#@}"
    else
        mode="command"
        user_command="$original_command"
    fi

    if [[ "$mode" == "command" ]] && _is_whitelisted "$user_command"; then
        BUFFER="$user_command"
        zle .accept-line
        return
    fi

    if [[ "$mode" == "command" ]] && _is_blacklisted "$user_command"; then
        echo -e "\n\e[1;31mGÜVENLİK UYARISI: Komut kara listeye takıldı. İşlem durduruldu.\e[0m"
        _smart_log "BLACKLIST_BLOCKED" "$user_command"
        BUFFER=""
        zle redisplay
        return
    fi

    local llm_json_response
    llm_json_response=$(_call_llm "$user_command" "$mode")
    if [[ $? -ne 0 ]]; then
        BUFFER=""
        zle redisplay
        return
    fi

    if [[ "$mode" == "explanation" ]]; then
        local explanation
        explanation=$(echo "$llm_json_response" | jq -r '.explanation' 2>/dev/null)

        if [[ -z "$explanation" || "$explanation" == "null" ]]; then
            explanation="$llm_json_response"
        fi

        if [[ "$explanation" == "DANGER" ]]; then
            echo -e "\n\e[31m❌ Hata: Geçerli bir açıklama alınamadı veya istek tehlikeli bulundu.\e[0m"
            _smart_log "EXPLANATION_ERROR" "Response: $llm_json_response"
        else
            echo -e "\n\e[1;34m🧠 Açıklama:\e[0m\n$explanation"
            _smart_log "EXPLANATION_SUCCESS" "Request: $user_command"
        fi
        BUFFER=""
        zle redisplay
    else # command modu
        local suggested_command
        suggested_command=$(echo "$llm_json_response" | jq -r '.command' 2>/dev/null)

        if [[ -z "$suggested_command" || "$suggested_command" == "null" ]]; then
            suggested_command="$llm_json_response"
        fi

        if [[ -z "$suggested_command" ]]; then
            echo -e "\n\e[31m❌ Hata: LLM boş bir komut döndürdü.\e[0m"
            _smart_log "LLM_EMPTY_COMMAND" "Response: $llm_json_response"
            BUFFER=""
            zle redisplay
            return
        fi

        if [[ "$suggested_command" == "DANGER" ]]; then
            echo -e "\n\e[31m❌ Tehlikeli komut isteği LLM tarafından reddedildi.\e[0m"
            _smart_log "LLM_DANGER_DETECTED" "Request: $user_command"
            BUFFER=""
            zle redisplay
            return
        fi

        if _is_blacklisted "$suggested_command"; then
            echo -e "\n\e[1;31mGÜVENLİK UYARISI: LLM potansiyel olarak tehlikeli bir komut önerdi (kara liste) ve engellendi.\e[0m"
            _smart_log "LLM_BLACKLIST_BLOCKED" "Request: $user_command | Suggestion: $suggested_command"
            BUFFER=""
            zle redisplay
            return
        fi

        echo -e "🤔 Şunu mu demek istediniz? (\e[94m$user_command\e[0m)"
        echo -e "\e[1;32m$ $suggested_command\e[0m"
        read -k1 -r '?Çalıştır [E], Düzenle [D], İptal [herhangi bir tuş]? '
        echo

        if [[ $REPLY =~ ^[Ee]$ ]]; then
            _smart_log "EXECUTE" "Input: $user_command | Command: $suggested_command"
            BUFFER=$suggested_command
            zle .accept-line
        elif [[ $REPLY =~ ^[Dd]$ ]]; then
            BUFFER=$suggested_command
            zle redisplay
        else
            _smart_log "CANCEL" "Input: $user_command"
            BUFFER=""
            zle redisplay
        fi
    fi
}

# =================== KURULUM =====================

for cmd in curl jq perl; do
    if ! command -v $cmd &> /dev/null; then
        echo "smart_execute: Hata - '$cmd' komutu bulunamadı. Lütfen kurun." >&2
        return 1
    fi
done

_smart_load_lists

zle -N smart_accept_line
bindkey '^M' smart_accept_line
bindkey '^J' smart_accept_line
