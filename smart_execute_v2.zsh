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
SMART_EXECUTE_CONFIG_DIR="$HOME/.config/smart_execute"
SMART_EXECUTE_DIR="$(dirname "${(%):-%x}")"

# Audit log dosyası
AUDIT_LOG="$SMART_EXECUTE_CONFIG_DIR/audit.log"
LOG_FILE="$SMART_EXECUTE_CONFIG_DIR/log.txt"

# Global değişkenler
typeset -g BLACKLIST_PATTERNS=()
typeset -g WHITELIST_PATTERNS=()

# =================== MODÜL YÜKLEME =====================

# Güvenlik modülü
if [[ -f "$SMART_EXECUTE_DIR/.smart_execute_security.zsh" ]]; then
    source "$SMART_EXECUTE_DIR/.smart_execute_security.zsh"
fi

# Cache modülü
if [[ -f "$SMART_EXECUTE_DIR/.smart_execute_cache.zsh" ]]; then
    source "$SMART_EXECUTE_DIR/.smart_execute_cache.zsh"
fi

# Provider modülü
if [[ -f "$SMART_EXECUTE_DIR/.smart_execute_providers.zsh" ]]; then
    source "$SMART_EXECUTE_DIR/.smart_execute_providers.zsh"
fi

# Cross-shell desteği
if [[ -f "$SMART_EXECUTE_DIR/.smart_execute_cross_shell.zsh" ]]; then
    source "$SMART_EXECUTE_DIR/.smart_execute_cross_shell.zsh"
fi

# Wizard modülü
if [[ -f "$SMART_EXECUTE_DIR/.smart_execute_wizard.zsh" ]]; then
    source "$SMART_EXECUTE_DIR/.smart_execute_wizard.zsh"
fi

# =================== ANA KONFIGÜRASYON =====================

# Varsayılan ayarlar
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

# Dosya yolları
BLACKLIST_FILE="$SMART_EXECUTE_CONFIG_DIR/blacklist.txt"
WHITELIST_FILE="$SMART_EXECUTE_CONFIG_DIR/whitelist.txt"

# Gelişmiş sistem mesajı
SYSTEM_MESSAGE="Sen Linux/macOS terminal uzmanısın. Kullanıcı isteklerini analiz edip SADECE JSON formatında yanıt veriyorsun.

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

HATIRLA: Tek JSON objesi, tek satır, başka hiçbir şey yazma!"

# =================== TEMEL FONKSİYONLAR =====================

# Basit loglama fonksiyonu (backwards compatibility)
_smart_log() {
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1 | $2" >> "$LOG_FILE"
    
    # Audit log varsa oraya da kaydet
    [[ "$(type -t _audit_log)" == "function" ]] && _audit_log "$1" "$1" "$2"
}

# Liste yükleme fonksiyonu
_smart_load_lists() {
    # Kara Liste - Gelişmiş versiyonu varsa onu kullan
    local advanced_blacklist="$SMART_EXECUTE_DIR/.smart_execute_advanced_blacklist.txt"
    local blacklist_source="$BLACKLIST_FILE"
    
    if [[ -f "$advanced_blacklist" ]]; then
        blacklist_source="$advanced_blacklist"
    fi
    
    if [[ -f "$blacklist_source" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && BLACKLIST_PATTERNS+=("$line")
        done < "$blacklist_source"
    else
        mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
        # Gelişmiş kara listeyi kopyala
        if [[ -f "$advanced_blacklist" ]]; then
            cp "$advanced_blacklist" "$BLACKLIST_FILE"
        else
            # Varsayılan kara liste
            cat <<EOF > "$BLACKLIST_FILE"
# Tehlikeli Komutlar İçin Regex Kara Listesi
rm\s+-rf\s+/
rm\s+-rf\s+\.\.?/
:\(\)\s*{\s*:|:&;\s*};
dd\s+.*of=/dev/(sd|nvme).*
mkfs.* /dev/(sd|nvme).*
chmod\s+-R\s+777\s+/
mv\s+.*\s+/dev/null
shutdown\b
reboot\b
halt\b
poweroff\b
sudo\s+rm.*-rf
eval\s+\$\(
exec\s+\$\(
EOF
        fi
        
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
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && WHITELIST_PATTERNS+=("$line")
        done < "$WHITELIST_FILE"
    fi
}

# Kara liste kontrolü
_is_blacklisted() {
    for pattern in "${BLACKLIST_PATTERNS[@]}"; do
        if [[ "$1" =~ $pattern ]]; then
            _smart_log "BLACKLIST_MATCH" "Input: '$1' | Pattern: '$pattern'"
            return 0
        fi
    done
    return 1
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
    if [[ "$(type -t _check_session_timeout)" == "function" ]]; then
        _check_session_timeout || return 1
    fi
    
    if [[ "$(type -t _check_rate_limit)" == "function" ]]; then
        _check_rate_limit || {
            echo -e "\n\e[31m❌ Rate limit aşıldı. Lütfen bekleyin.\e[0m" >&2
            return 1
        }
    fi
    
    if [[ "$(type -t _detect_anomalies)" == "function" ]]; then
        _detect_anomalies "$user_prompt" || {
            echo -e "\n\e[31m❌ Şüpheli aktivite tespit edildi.\e[0m" >&2
            return 1
        }
    fi
    
    # Input sanitization
    if [[ "$(type -t _sanitize_input)" == "function" ]]; then
        user_prompt=$(_sanitize_input "$user_prompt") || return 1
    fi
    
    # Prompt hazırlama
    if [[ "$mode" == "explanation" ]]; then
        full_prompt="$SYSTEM_MESSAGE\nKullanıcı bir komutun açıklamasını istiyor. Yanıtını {\"explanation\": \"...\"} formatında ver.\nİstek: $user_prompt"
    else
        full_prompt="$SYSTEM_MESSAGE\nKullanıcı bir komut istiyor. Yanıtını {\"command\": \"...\"} formatında ver.\nİstek: $user_prompt"
    fi
    
    # Cache kontrolü
    if [[ "$(type -t _get_cached_response)" == "function" ]]; then
        local cached_response=$(_get_cached_response "$full_prompt")
        if [[ $? -eq 0 ]]; then
            echo "$cached_response"
            return 0
        fi
    fi
    
    # Multi-provider desteği
    local response
    if [[ "$(type -t _call_llm_with_fallback)" == "function" ]]; then
        response=$(_call_llm_with_fallback "$full_prompt" "$mode")
    else
        # Fallback: Basit Ollama çağrısı
        echo -n $'\n\e[2m🧠 LLM düşünüyor...\e[0m' >&2
        
        local json_payload
        json_payload=$(jq -n \
                       --arg model "$LLM_MODEL" \
                       --arg prompt "$full_prompt" \
                       '{model: $model, prompt: $prompt, stream: false, format: "json"}')
        
        response=$(curl -s --max-time $LLM_TIMEOUT -X POST "$LLM_URL" \
          -H "Content-Type: application/json" \
          -d "$json_payload")
        
        echo -ne "\r\e[K" >&2
    fi
    
    local curl_exit_code=$?
    
    if [[ $curl_exit_code -ne 0 ]]; then
        echo -e "\n\e[31m❌ Hata: LLM API'sine bağlanılamadı (curl çıkış kodu: $curl_exit_code).\e[0m" >&2
        _smart_log "LLM_CONNECTION_ERROR" "curl exit code: $curl_exit_code"
        return 1
    fi
    
    if ! echo "$response" | jq -e . >/dev/null 2>&1; then
        echo -e "\n\e[31m❌ Hata: LLM'den geçersiz JSON yanıtı alındı.\e[0m" >&2
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
    
    # Cache'e kaydet
    if [[ "$(type -t _cache_response)" == "function" ]]; then
        _cache_response "$full_prompt" "$response_field"
    fi
    
    # Output sanitization
    if [[ "$(type -t _sanitize_output)" == "function" ]]; then
        response_field=$(_sanitize_output "$response_field")
    fi
    
    echo "$response_field"
    return 0
}

# =================== ANA ZLE WIDGET'I =====================

smart_accept_line() {
    local original_command="$BUFFER"
    local user_command
    local mode

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
        mode="command"
        user_command="$original_command"
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
    local llm_json_response
    llm_json_response=$(_call_llm "$user_command" "$mode")
    if [[ $? -ne 0 ]]; then
        BUFFER=""
        zle redisplay
        return
    fi

    # Açıklama modu
    if [[ "$mode" == "explanation" ]]; then
        local explanation
        if [[ "$(type -t _parse_json_safely)" == "function" ]]; then
            explanation=$(_parse_json_safely "$llm_json_response" "explanation")
        else
            explanation=$(echo "$llm_json_response" | jq -r '.explanation // ""' 2>/dev/null)
        fi

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
        return
    fi

    # Komut modu
    local suggested_command
    if [[ "$(type -t _parse_json_safely)" == "function" ]]; then
        suggested_command=$(_parse_json_safely "$llm_json_response" "command")
    else
        suggested_command=$(echo "$llm_json_response" | jq -r '.command // ""' 2>/dev/null)
    fi

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
    if [[ "$(type -t _confirm_execution)" == "function" ]]; then
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
    if [[ "$(type -t _assess_risk)" == "function" ]]; then
        local risk_score=$(_assess_risk "$suggested_command")
        [[ $risk_score -gt 2 ]] && echo -e "\e[33m⚠️  Risk Seviyesi: $risk_score\e[0m"
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

# =================== YÖNETİM KOMUTLARI =====================

# Smart Execute komutları
smart_execute_command() {
    case "$1" in
        "setup"|"wizard")
            if [[ "$(type -t _create_config_wizard)" == "function" ]]; then
                _create_config_wizard
            else
                echo "Kurulum sihirbazı mevcut değil"
            fi
            ;;
        "cache-stats")
            if [[ "$(type -t _cache_stats)" == "function" ]]; then
                _cache_stats
            else
                echo "Cache modülü yüklü değil"
            fi
            ;;
        "cache-clear")
            if [[ "$(type -t _clear_cache)" == "function" ]]; then
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
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "smart_execute: Hata - '$cmd' komutu bulunamadı. Lütfen kurun." >&2
        return 1
    fi
done

# İlk kurulum kontrolü
if [[ ! -f "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf" ]]; then
    echo "🚀 Smart Execute v2.0 ilk kez çalışıyor!"
    echo "Kurulum sihirbazını çalıştırmak için: smart-execute setup"
    
    # Temel yapılandırmayı oluştur
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
    
    # Güvenlik yapılandırmasını kopyala
    if [[ -f "$SMART_EXECUTE_DIR/.smart_execute_security.conf" ]]; then
        cp "$SMART_EXECUTE_DIR/.smart_execute_security.conf" "$SMART_EXECUTE_CONFIG_DIR/"
    fi
fi

# Yapılandırmayı yükle
if [[ -f "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf" ]]; then
    source "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf"
fi

# Listeleri yükle
_smart_load_lists

# Cache'i başlat
if [[ "$(type -t _init_cache)" == "function" ]]; then
    _init_cache
fi

# Cache temizliği (arka planda)
if [[ "$(type -t _cleanup_cache)" == "function" ]]; then
    (_cleanup_cache &)
fi

# Cross-shell desteğini kur
if [[ "$(type -t setup_cross_shell_support)" == "function" ]]; then
    setup_cross_shell_support
fi

# ZLE widget'ını kaydet
zle -N smart_accept_line
bindkey '^M' smart_accept_line
bindkey '^J' smart_accept_line

# Başarılı yükleme mesajı
_smart_log "SYSTEM" "Smart Execute v2.0 loaded successfully"

echo "✅ Smart Execute v2.0 yüklendi!"
echo "📚 Yardım için: smart-execute help"
echo "⚙️  Kurulum için: smart-execute setup"
