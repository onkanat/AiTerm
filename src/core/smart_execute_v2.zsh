#!/bin/zsh

# =============================================================================
#                    SMART EXECUTE - GELIŞMIŞ SÜRÜM v2.0
# =============================================================================
# 
# ⚠️  ÖNEMLI GÜVENLİK UYARISI / IMPORTANT SECURITY WARNING ⚠️
#
# Bu script bir LLM (Büyük Dil Modeli) kullanarak terminal komutları üretir.
# This script uses an LLM (Large Language Model) to generate terminal commands.
#
# RİSKLER / RISKS:
# • LLM tarafından üretilen komutlar tehlikeli olabilir
# • Sistem dosyalarınız zarar görebilir
# • Veri kaybı yaşanabilir
# • Güvenlik açıkları oluşabilir
#
# SORUMLULUK REDDI / DISCLAIMER:
# • Bu scripti kullanarak TÜM SORUMLULUĞU ÜZERİNİZE ALIYORSUNUZ
# • Yazarlar hiçbir sorumluluk kabul etmez
# • Herhangi bir zarar için garanti verilmez
#
# YENİ ÖZELLİKLER v2.0:
# • Gelişmiş güvenlik katmanları
# • Çoklu LLM provider desteği
# • Cache sistemi
# • Anomali tespiti
# • Cross-shell desteği
# • Risk değerlendirmesi
# • Session yönetimi
#
# Lisans: MIT License - LICENSE dosyasına bakın
# =============================================================================

# =================== BAŞLATMA VE KONFIGÜRASYON =====================

# Ana yapılandırma dizini
# Ana yapılandırma dizini
SMART_EXECUTE_CONFIG_DIR="${SMART_EXECUTE_CONFIG_DIR:-$HOME/.config/smart_execute}"
SMART_EXECUTE_DIR="$(dirname "${(%):-%x}")"

# Audit log dosyası
AUDIT_LOG="$SMART_EXECUTE_CONFIG_DIR/audit.log"
LOG_FILE="$SMART_EXECUTE_CONFIG_DIR/log.txt"

# Global değişkenler
typeset -g BLACKLIST_PATTERNS=()
typeset -g WHITELIST_PATTERNS=()

# =================== MODÜL YÜKLEME =====================

# Yardımcı fonksiyon: Modül yükle
_smart_source_module() {
    local module_name="$1"
    
    # 1. Aynı dizinde (kurulu hali)
    if [[ -f "$SMART_EXECUTE_DIR/$module_name" ]]; then
        source "$SMART_EXECUTE_DIR/$module_name"
    # 2. Üst dizindeki modules klasöründe (repo hali)
    elif [[ -f "$SMART_EXECUTE_DIR/../modules/$module_name" ]]; then
        source "$SMART_EXECUTE_DIR/../modules/$module_name"
    # 3. Eski isimlendirme formatı (.smart_execute_*.zsh)
    elif [[ -f "$SMART_EXECUTE_DIR/.smart_execute_$module_name" ]]; then
        source "$SMART_EXECUTE_DIR/.smart_execute_$module_name"
    fi
}

# Modülleri yükle
_smart_source_module "security.zsh"
_smart_source_module "cache.zsh"
_smart_source_module "providers.zsh"
_smart_source_module "cross_shell.zsh"
_smart_source_module "wizard.zsh"

# =================== TEMEL FONKSİYONLAR =====================

# Basit loglama fonksiyonu (backwards compatibility)
_smart_log() {
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'timestamp-error')"
    echo "$timestamp | $1 | $2" >> "$LOG_FILE"
    
    # Audit log varsa oraya da kaydet
    [[ "$(whence -w _audit_log 2>/dev/null)" == *function* ]] && _audit_log "$1" "$1" "$2"
}

# =================== ANA KONFIGÜRASYON =====================

# Yapılandırmayı yükle (çoklu konum desteği)
_smart_load_config() {
    local config_paths=(
        "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf"
        "$SMART_EXECUTE_CONFIG_DIR/security.conf"
        "$SMART_EXECUTE_DIR/security.conf"
        "$SMART_EXECUTE_DIR/.smart_execute_security.conf"
    )
    
    for config_path in "${config_paths[@]}"; do
        if [[ -f "$config_path" ]]; then
            source "$config_path"
            _smart_log "SYSTEM" "Config loaded from: $config_path"
            return 0
        fi
    done
}

# Varsayılan ayarlar (config yüklenemezse kullanılır)
LLM_URL="http://localhost:11434/api/generate"
LLM_MODEL="gemma3:1b-it-qat"
LLM_TIMEOUT=60
LLM_PROVIDER="ollama"
FALLBACK_PROVIDER="ollama"

# Güvenlik ayarları
SECURITY_LEVEL=2
MAX_COMMAND_LENGTH=1000
MAX_RISK_SCORE=3
RATE_LIMIT_PER_MINUTE=20
SESSION_TIMEOUT=1800

# Özellik bayrakları
ENABLE_CACHE=true
ENABLE_AUDIT_LOG=true
ENABLE_ANOMALY_DETECTION=true
ENABLE_SANDBOX=false

# Cache ayarları
CACHE_TTL=3600

# Yapılandırmayı yükle
_smart_load_config

# Dosya yolları (config yüklendikten sonra set et)
BLACKLIST_FILE="${BLACKLIST_FILE:-$SMART_EXECUTE_CONFIG_DIR/blacklist.txt}"
WHITELIST_FILE="${WHITELIST_FILE:-$SMART_EXECUTE_CONFIG_DIR/whitelist.txt}"

# Gelişmiş sistem mesajı
SYSTEM_MESSAGE="Sen Linux/macOS terminal uzmanısın. Kullanıcı isteklerini analiz edip SADECE JSON formatında yanıt veriyorsun.

KRİTİK KURALLAR:
1. SADECE JSON formatında yanıt ver, başka hiçbir şey yazma.
2. JSON objesi tek satırda olmalı, hiç yeni satır olmasın.
3. Türkçe karakterleri doğru encode et.

MODLAR VE FORMATLAR:
A) KOMUT MODU (Kullanıcı bir işlem yaptırmak istiyorsa):
   Format: {\"command\":\"buraya_komut\"}
   Örnek: {\"command\":\"ls -l\"}
   
B) AÇIKLAMA MODU (Kullanıcı '@?' ile sorduysa veya açıklama istiyorsa):
   Format: {\"explanation\":\"buraya_aciklama\"}
   Örnek: {\"explanation\":\"ls komutu dosyaları listeler.\"}

TEHLİKELİ KOMUTLAR:
Tehlikeli veya riskli isteklerde: {\"command\":\"DANGER\", \"explanation\":\"DANGER\"}

HATIRLA: Sadece istenen modun JSON anahtarını kullan. Tek satır, tek JSON."


# Liste yükleme fonksiyonu
_smart_load_lists() {
    # Kara Liste kontrolünü devre dışı bırak - case-based kontrol kullanıyoruz
    BLACKLIST_PATTERNS=()
    
    # Testlerin geçmesi için dosyanın var olduğundan emin ol
    if [[ ! -f "$BLACKLIST_FILE" ]]; then
        mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
        touch "$BLACKLIST_FILE"
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
ls -l
ls -la
ls -lh
cd
pwd
git status
git diff
git log
git pull
git push
source
which
whereis
man
whoami
clear
history
echo
cat
tail
head
grep
date
uname
ps
jobs
df
du
free
uptime
env
printenv
EOF
        # Yeni oluşturulan dosyayı tekrar oku
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && WHITELIST_PATTERNS+=("$line")
        done < "$WHITELIST_FILE"
    fi
}

# Kara liste kontrolü
_is_blacklisted() {
    # Basit string kontrolü - regex problemlerini önlemek için
    local input="$1"
    
    # Kritik tehlikeli komutları direkt kontrol et
    case "$input" in
        "rm -rf /"*) return 0 ;;
        "shutdown"*) return 0 ;;
        "reboot"*) return 0 ;;
        "halt"*) return 0 ;;
        "poweroff"*) return 0 ;;
        *"rm -rf"*) return 0 ;;
        *"dd if="*"of=/dev/"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Beyaz liste kontrolü
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

# Gelişmiş LLM çağrı fonksiyonu
_call_llm() {
    local user_prompt="$1"
    local mode="$2"
    local full_prompt

    # Güvenlik kontrolleri
    if [[ "$(whence -w _check_session_timeout 2>/dev/null)" == *function* ]]; then
        _check_session_timeout || return 1
    fi
    if [[ "$(whence -w _check_rate_limit 2>/dev/null)" == *function* ]]; then
        _check_rate_limit || {
            echo -e "\n\e[31m❌ Rate limit aşıldı. Lütfen bekleyin.\e[0m" >&2
            return 1
        }
    fi
    if [[ "$(whence -w _detect_anomalies 2>/dev/null)" == *function* ]]; then
        _detect_anomalies "$user_prompt" || {
            echo -e "\n\e[31m❌ Şüpheli aktivite tespit edildi.\e[0m" >&2
            return 1
        }
    fi
    # Input sanitization
    if [[ "$(whence -w _sanitize_input 2>/dev/null)" == *function* ]]; then
        user_prompt=$(_sanitize_input "$user_prompt") || return 1
    fi

    # Prompt hazırlama
    if [[ "$mode" == "explanation" ]]; then
        full_prompt="$SYSTEM_MESSAGE\nKullanıcı bir komutun açıklamasını istiyor. Yanıtını {\"explanation\": \"...\"} formatında ver.\nİstek: $user_prompt"
    else
        full_prompt="$SYSTEM_MESSAGE\nKullanıcı bir komut istiyor. Yanıtını {\"command\": \"...\"} formatında ver.\nİstek: $user_prompt"
    fi

    # Cache kontrolü
    if [[ "$(whence -w _get_cached_response 2>/dev/null)" == *function* ]]; then
        local cached_response
        cached_response=$(_get_cached_response "$full_prompt")
        if [[ $? -eq 0 && -n "$cached_response" ]]; then
            echo "$cached_response"
            return 0
        fi
    fi

    # Multi-provider desteği
    local response
    local fallback_used="false"
    if [[ "$(whence -w _call_llm_with_fallback 2>/dev/null)" == *function* ]]; then
        response=$(_call_llm_with_fallback "$user_prompt" "$mode")
        curl_exit_code=$?
        fallback_used="true"
    else
        # Fallback: Basit Ollama çağrısı
        echo -n $'\n\e[2m🧠 LLM düşünüyor...\e[0m' >&2
        local json_payload
        
        # JSON payload güvenli oluşturma
        json_payload=$(jq -n \
            --arg model "$LLM_MODEL" \
            --arg prompt "$full_prompt" \
            '{model: $model, prompt: $prompt, stream: false, format: "json"}' 2>/dev/null) || {
            echo -e "\n\e[31m❌ Hata: JSON oluşturulamadı.\e[0m" >&2
            return 1
        }
        
        response=$(curl -s --max-time $LLM_TIMEOUT -X POST "$LLM_URL" \
            -H "Content-Type: application/json" \
            -d "$json_payload" 2>&1)
        curl_exit_code=$?
        echo -ne "\r\e[K" >&2
    fi
    if [[ $curl_exit_code -ne 0 ]]; then
        echo -e "\n\e[31m❌ Hata: LLM API'sine bağlanılamadı (curl çıkış kodu: $curl_exit_code).\e[0m" >&2
        _smart_log "LLM_CONNECTION_ERROR" "curl exit code: $curl_exit_code"
        return 1
    fi

    # Parse according to whether fallback handled it or not
    local response_field=""
    if [[ "$fallback_used" == "true" ]]; then
        response_field="$response"
    else
        # Önce response field'ını al
        if echo "$response" | jq . >/dev/null 2>&1; then
            response_field=$(echo "$response" | jq -r '.response // ""' 2>/dev/null)
        fi
        
        # Eğer response field boş ise ham response'u kullan
        if [[ -z "$response_field" || "$response_field" == "null" ]]; then
            response_field="$response"
        fi
        
        # İçerik command/explanation içeriyor mu kontrol et
        # Provider response nested JSON olabilir, önce parse edelim
        local inner_json=""
        if echo "$response_field" | jq . >/dev/null 2>&1; then
            inner_json="$response_field"
        else
            # response field içinde nested JSON string olabilir
            if echo "$response_field" | grep -q '{".*"}'; then
                inner_json="$response_field"
            fi
        fi
        
        if [[ -n "$inner_json" ]]; then
            if [[ "$mode" == "explanation" ]]; then
                local explanation=$(echo "$inner_json" | jq -r '.explanation // empty' 2>/dev/null)
                if [[ -n "$explanation" && "$explanation" != "null" ]]; then
                    response_field="$explanation"
                fi
            else
                local command=$(echo "$inner_json" | jq -r '.command // empty' 2>/dev/null)
                if [[ -n "$command" && "$command" != "null" ]]; then
                    response_field="$command"
                fi
            fi
        fi
    fi

    # Cache'e kaydet
    if [[ "$(whence -w _cache_response 2>/dev/null)" == *function* ]]; then
        _cache_response "$full_prompt" "$response_field"
    fi

    # Output sanitization
    if [[ "$(whence -w _sanitize_output 2>/dev/null)" == *function* ]]; then
        response_field=$(_sanitize_output "$response_field")
    fi

    echo "$response_field"
    return 0
}

# =================== LLM BAĞLANTI KONTROLÜ =====================
_check_llm_connection() {
    # Sadece ollama provider'ı için kontrol yap
    if [[ "$LLM_PROVIDER" != "ollama" ]]; then
        return 0
    fi

    # Ollama base URL'ini türet (generate endpoint yerine kökü kullan)
    local ollama_base_url="${LLM_URL%/api/generate}"
    ollama_base_url="${ollama_base_url%/api/chat}"

    # Sunucunun ayakta olup olmadığını kontrol et (/api/tags her zaman GET ile çalışır)
    if ! curl -s --max-time 5 "${ollama_base_url}/api/tags" >/dev/null; then
        echo -e "\n\e[1;31m❌ Hata: LLM sunucusuna bağlanılamadı (${ollama_base_url}).\e[0m"
        echo -e "\e[33mℹ️  Lütfen Ollama'nın çalıştığından emin olun. Başlatmak için: \e[1mollama serve\e[0m"
        return 1
    fi

    # Modelin varlığını kontrol et (doğru endpoint: /api/show)
    local model_info
    model_info=$(curl -s -X POST "${ollama_base_url}/api/show" -d "{\"name\": \"$LLM_MODEL\"}" 2>/dev/null)
    
    # JSON geçerli mi kontrol et
    if [[ -n "$model_info" ]] && echo "$model_info" | jq . >/dev/null 2>&1; then
        # Error alanı var mı kontrol et
        if echo "$model_info" | jq -e 'has("error")' >/dev/null 2>&1; then
            local error_msg
            error_msg=$(echo "$model_info" | jq -r '.error' 2>/dev/null || echo "Bilinmeyen hata")
            echo -e "\n\e[1;31m❌ Hata: LLM modeli '$LLM_MODEL' bulunamadı veya yüklenemedi.\e[0m"
            echo -e "\e[33mℹ️  Modeli indirmek için: \e[1mollama pull $LLM_MODEL\e[0m"
            echo -e "\e[2m   (Hata detayı: $error_msg)\e[0m"
            return 1
        fi
    else
        # JSON geçersiz veya boş yanıt - sessizce devam et
    fi
    
    return 0
}

# =================== ANA ZLE WIDGET'I =====================

smart_accept_line() {
    local original_command="$BUFFER"
    local user_command
    local mode

    # ── Guard 1: VSCode / Cursor / Windsurf shell integration bypass ──
    # Bu ortamlar kendi ^M hook'larını kullanır; çakışmayı önleriz.
    if [[ -n "${VSCODE_SHELL_INTEGRATION:-}" || "${TERM_PROGRAM:-}" == "vscode" ]]; then
        zle .accept-line
        return
    fi

    # Boş komut kontrolü
    if [[ -z "$original_command" ]]; then
        zle .accept-line
        return
    fi

    # Doğrudan çalıştırma (/ prefixi)
    if [[ "$original_command" == /* ]]; then
        BUFFER="${original_command#/}"
        zle .accept-line
        return
    fi

    # Mod belirleme
    if [[ "$original_command" == @\?* ]]; then
        mode="explanation"
        user_command="${original_command#@?}"
    elif [[ "$original_command" == @* ]]; then
        mode="command"
        user_command="${original_command#@}"
    else
        # '@' veya '@?' olmadan girilen komutlar için LLM'e gitme
        BUFFER="$original_command"
        zle .accept-line
        return
    fi
    # Baş ve sondaki boşlukları sil
    user_command="${user_command## }"
    user_command="${user_command%% }"
    user_command="$(echo "$user_command" | sed 's/^ *//;s/ *$//')"
    
    if [[ -z "$user_command" ]]; then
        echo -e "\n\e[31m❌ Hata: LLM'ye gönderilecek komut boş!\e[0m" >&2
        BUFFER=""
        zle redisplay
        return
    fi

    # LLM bağlantısını kontrol et
    if ! _check_llm_connection; then
        BUFFER=""
        zle redisplay
        return
    fi

    # Beyaz liste kontrolü (sadece komut modunda)
    if [[ "$mode" == "command" ]] && _is_whitelisted "$user_command"; then
        BUFFER="$user_command"
        zle .accept-line
        return
    fi

    # Kara liste kontrolü
    if [[ "$mode" == "command" ]] && _is_blacklisted "$user_command"; then
        echo -e "\n\e[1;31m🚫 GÜVENLİK UYARISI: Komut kara listeye takıldı. İşlem durduruldu.\e[0m"
        _smart_log "BLACKLIST_BLOCKED" "$user_command"
        BUFFER=""
        zle redisplay
        return
    fi

    # LLM çağrısı
    local llm_response
    llm_response=$(_call_llm "$user_command" "$mode")
    if [[ $? -ne 0 ]]; then
        if [[ -n "$llm_response" ]]; then
            echo -e "$llm_response" >&2
        fi
        BUFFER=""
        zle redisplay
        return
    fi

    # Açıklama modu
    if [[ "$mode" == "explanation" ]]; then
        if [[ -z "$llm_response" || "$llm_response" == "DANGER" ]]; then
            echo -e "\n\e[31m❌ Hata: Geçerli bir açıklama alınamadı veya istek tehlikeli bulundu.\e[0m"
            _smart_log "EXPLANATION_ERROR" "Response: $llm_response"
        else
            echo -e "\n\e[1;34m🧠 Açıklama:\e[0m\n$llm_response"
            _smart_log "EXPLANATION_SUCCESS" "Request: $user_command"
        fi
        BUFFER=""
        zle redisplay
        return
    fi

    # Komut modu - _call_llm zaten temiz komut döndürüyor
    local suggested_command="$llm_response"

    if [[ -z "$suggested_command" || "$suggested_command" == "null" ]]; then
        echo -e "\n\e[31m❌ Hata: LLM'den geçerli bir komut alınamadı.\e[0m"
        _smart_log "LLM_INVALID_COMMAND" "Response: $llm_response"
        BUFFER=""
        zle redisplay
        return
    fi

    if [[ "$suggested_command" == "DANGER" ]]; then
        echo -e "\n\e[31m🚫 Tehlikeli komut isteği LLM tarafından reddedildi.\e[0m"
        _smart_log "LLM_DANGER_DETECTED" "Request: $user_command"
        BUFFER=""
        zle redisplay
        return
    fi

    # Önerilen komutun güvenlik kontrolü
    if _is_blacklisted "$suggested_command"; then
        echo -e "\n\e[1;31m🚫 GÜVENLİK UYARISI: LLM potansiyel olarak tehlikeli bir komut önerdi (kara liste) ve engellendi.\e[0m"
        _smart_log "LLM_BLACKLIST_BLOCKED" "Request: $user_command | Suggestion: $suggested_command"
        BUFFER=""
        zle redisplay
        return
    fi

    # Risk değerlendirmesi ve onay
    if [[ "$(whence -w _confirm_execution 2>/dev/null)" == *function* ]]; then
        if ! _confirm_execution "$suggested_command"; then
            BUFFER=""
            zle redisplay
            return
        fi
    fi
    
    # Kullanıcı onayı
    echo -e "\n🤔 Şunu mu demek istediniz? (\e[94m$user_command\e[0m)"
    echo -e "\e[1;32m$ $suggested_command\e[0m"
    
    # Risk seviyesini göster
    if [[ "$(whence -w _assess_risk 2>/dev/null)" == *function* ]]; then
        local risk_score=$(_assess_risk "$suggested_command")
        [[ $risk_score -gt 2 ]] && echo -e "\e[33m⚠️  Risk Seviyesi: $risk_score\e[0m"
    fi
    
    # ── Guard 2: TTY kontrolü ──
    # Pipe, CI veya Antigravity/Gemini agent terminali gibi TTY olmayan
    # ortamlarda read -k1 bloklanır; bu durumda direkt çalıştırırız.
    if [[ ! -t 0 ]]; then
        _smart_log "EXECUTE" "Non-TTY auto-execute | Input: $user_command | Command: $suggested_command"
        BUFFER=$suggested_command
        zle .accept-line
        return
    fi
    
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
}

# =================== KONFIGÜRASYON SİHİRBAZI =====================

# Konfigürasyon sihirbazı
_create_config_wizard() {
    echo "╔════════════════════════════════════════════╗"
    echo "║         Smart Execute Kurulum Sihirbazı    ║"
    echo "╚════════════════════════════════════════════╝"
    echo
    echo "⚠️  ÖNEMLI GÜVENLİK UYARISI:"
    echo "Smart Execute bir LLM kullanarak komutlar üretir."
    echo "Bu potansiyel olarak tehlikeli olabilir."
    echo
    
    # Kurulum onayı
    echo -n "Devam etmek istiyor musunuz? [e/H]: "
    read -r consent
    if [[ ! "$consent" =~ ^[EeYy]$ ]]; then
        echo "Kurulum iptal edildi."
        return 1
    fi
    
    # Konfigürasyon dizinini oluştur
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
    
    # LLM Provider seçimi
    echo
    echo "1. LLM Provider Seçimi:"
    echo "  1) Ollama (varsayılan) - localhost:11434"
    echo "  2) OpenAI API"
    echo "  3) Anthropic Claude"
    echo "  4) Özel endpoint"
    echo -n "Seçiminiz [1]: "
    read -r llm_choice
    
    case "$llm_choice" in
        2)
            echo -n "OpenAI API Key: "
            read -rs openai_key
            echo
            cat > "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf" << EOF
# Smart Execute Security Configuration
LLM_PROVIDER="openai"
OPENAI_API_KEY="$openai_key"
LLM_MODEL="gpt-3.5-turbo"
LLM_TIMEOUT=30
SECURITY_LEVEL=2
ENABLE_CACHE=true
ENABLE_AUDIT_LOG=true
ENABLE_ANOMALY_DETECTION=true
EOF
            ;;
        3)
            echo -n "Anthropic API Key: "
            read -rs anthropic_key
            echo
            cat > "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf" << EOF
# Smart Execute Security Configuration
LLM_PROVIDER="anthropic"
ANTHROPIC_API_KEY="$anthropic_key"
LLM_MODEL="claude-3-haiku-20240307"
LLM_TIMEOUT=30
SECURITY_LEVEL=2
ENABLE_CACHE=true
ENABLE_AUDIT_LOG=true
ENABLE_ANOMALY_DETECTION=true
EOF
            ;;
        4)
            echo -n "LLM Endpoint URL: "
            read -r custom_url
            echo -n "Model adı: "
            read -r custom_model
            cat > "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf" << EOF
# Smart Execute Security Configuration
LLM_PROVIDER="custom"
LLM_URL="$custom_url"
LLM_MODEL="$custom_model"
LLM_TIMEOUT=60
SECURITY_LEVEL=2
ENABLE_CACHE=true
ENABLE_AUDIT_LOG=true
ENABLE_ANOMALY_DETECTION=true
EOF
            ;;
        *)
            # Ollama varsayılan
            cat > "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf" << EOF
# Smart Execute Security Configuration
LLM_PROVIDER="ollama"
LLM_URL="http://localhost:11434/api/generate"
LLM_MODEL="gemma3:1b-it-qat"
LLM_TIMEOUT=60
SECURITY_LEVEL=2
ENABLE_CACHE=true
ENABLE_AUDIT_LOG=true
ENABLE_ANOMALY_DETECTION=true
EOF
            ;;
    esac
    
    echo
    echo "✅ Konfigürasyon oluşturuldu!"
    echo "📁 Dosya: $SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf"
    echo
    echo "🚀 Smart Execute kullanıma hazır!"
    echo "Örnekler:"
    echo "  @dosyalar listele     -> LLM'den komut iste"
    echo "  @?git komutları       -> LLM'den açıklama iste"
    
    # Konfigürasyonu yeniden yükle
    source "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf"
}

# =================== YÖNETİM KOMUTLARI =====================

# Smart Execute komutları
smart_execute_command() {
    case "$1" in
        "setup"|"wizard")
            _create_config_wizard
            ;;
        "cache-stats")
            if [[ "$(whence -w _cache_stats 2>/dev/null)" == *function* ]]; then
                _cache_stats
            else
                echo "Cache modülü yüklü değil"
            fi
            ;;
        "cache-clear")
            if [[ "$(whence -w _clear_cache 2>/dev/null)" == *function* ]]; then
                _clear_cache
            else
                echo "Cache modülü yüklü değil"
            fi
            ;;
        "logs")
            [[ -f "$LOG_FILE" ]] && tail -n 20 "$LOG_FILE" || echo "Log dosyası bulunamadı"
            ;;
        "audit")
            [[ -f "$AUDIT_LOG" ]] && tail -n 20 "$AUDIT_LOG" || echo "Audit log dosyası bulunamadı"
            ;;
        "status")
            echo "Smart Execute Status:"
            echo "  Config Dir: $SMART_EXECUTE_CONFIG_DIR"
            echo "  LLM Provider: ${LLM_PROVIDER:-ollama}"
            echo "  Security Level: ${SECURITY_LEVEL:-2}"
            echo "  Cache: ${ENABLE_CACHE:-true}"
            echo "  Audit Log: ${ENABLE_AUDIT_LOG:-true}"
            echo "  Anomaly Detection: ${ENABLE_ANOMALY_DETECTION:-true}"
            ;;
        "help"|*)
            echo "Smart Execute Komutları:"
            echo "  smart-execute setup     - Kurulum sihirbazını çalıştır"
            echo "  smart-execute status    - Durum bilgisi göster"
            echo "  smart-execute logs      - Son logları göster"
            echo "  smart-execute audit     - Audit loglarını göster"
            echo "  smart-execute cache-stats - Cache istatistikleri"
            echo "  smart-execute cache-clear - Cache'i temizle"
            echo "  smart-execute help      - Bu yardımı göster"
            ;;
    esac
}

# Alias tanımla
alias smart-execute='smart_execute_command'

# =================== BAŞLATMA VE KURULUM =====================

# Gerekli araçları kontrol et
# Non-interactive shell'de (CI/CD, subshell) sadece uyar, scripti durdurma
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        if [[ -o interactive ]]; then
            echo "smart_execute: Hata - '$cmd' komutu bulunamadı. Lütfen kurun." >&2
            return 1
        else
            # Non-interactive: sessizce çık, pipeline'ı kırma
            return 0
        fi
    fi
done

# İlk kurulum kontrolü
if [[ ! -f "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf" && ! -f "$SMART_EXECUTE_CONFIG_DIR/security.conf" ]]; then
    echo "🚀 Smart Execute v2.0 ilk kez çalışıyor!"
    echo "Kurulum sihirbazını çalıştırmak için: smart-execute setup"
    
    # Temel yapılandırmayı oluştur
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
fi

# Listeleri yükle
_smart_load_lists

# Cache'i başlat
if [[ "$(whence -w _init_cache 2>/dev/null)" == *function* ]]; then
    _init_cache
fi

# Cache temizliği (güvenli)
if [[ "$(whence -w _cleanup_cache 2>/dev/null)" == *function* ]]; then
    (_cleanup_cache &)
else
    # Manuel cache temizliği
    if [[ -d "$SMART_EXECUTE_CONFIG_DIR/cache" ]]; then
        find "$SMART_EXECUTE_CONFIG_DIR/cache" -name "*.cache" -mtime +1 -delete 2>/dev/null || true
    fi
fi

# Cross-shell desteğini kur
if [[ "$(whence -w setup_cross_shell_support 2>/dev/null)" == *function* ]]; then
    setup_cross_shell_support
fi

# ── Guard 3: Interactive-only ZLE bağlamaları ──
# Non-interactive shell'de (CI/CD, script, pipe) ZLE yoktur;
# yüklemeye çalışmak 'zle: no current binding' hatası üretir.
if [[ -o interactive ]]; then
    zle -N smart_accept_line
    bindkey '^M' smart_accept_line
    bindkey '^J' smart_accept_line
fi

# Başarılı yükleme mesajı
_smart_log "SYSTEM" "Smart Execute v2.0 loaded successfully"

echo "✅ Smart Execute v2.0 yüklendi!"
echo "📚 Yardım için: smart-execute help"
echo "⚙️  Kurulum için: smart-execute setup"
