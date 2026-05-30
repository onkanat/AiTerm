#!/bin/zsh

# =============================================================================
#                               UYARI / WARNING
# =============================================================================
# 
# ⚠️  ÖNEMLI GÜVENLİK UYARISI / IMPORTANT SECURITY WARNING ⚠️
#
# Bu script bir LLM (Büyük Dil Modeli) kullanarak terminal komutları üretir.
# This script uses an LLM (Large Language Model) to generate terminal commands.
#
# RİSKLER / RISKS:
# • LLM tarafından üretilen komutlar tehlikeli olabilir
# • LLM models may generate dangerous commands
# • Sistem dosyalarınız zarar görebilir
# • Your system files may be damaged
# • Veri kaybı yaşanabilir
# • Data loss may occur
# • Güvenlik açıkları oluşabilir
# • Security vulnerabilities may be created
#
# SORUMLULUK REDDI / DISCLAIMER:
# • Bu scripti kullanarak TÜM SORUMLULUĞU ÜZERİNİZE ALIYORSUNUZ
# • By using this script, you accept ALL RESPONSIBILITY
# • Yazarlar hiçbir sorumluluk kabul etmez
# • Authors accept no responsibility whatsoever
# • Herhangi bir zarar için garanti verilmez
# • No warranty is provided for any damage
#
# KULLANIM KOŞULLARI / TERMS OF USE:
# • Kendi riskinizle kullanın
# • Use at your own risk
# • Komutları çalıştırmadan önce mutlaka kontrol edin
# • Always review commands before executing
# • Test ortamında deneme yapın
# • Test in a safe environment first
#
# DEVAM ETMEK İSTİYORSANIZ / IF YOU WISH TO CONTINUE:
# Bu uyarıları okuduğunuzu ve kabul ettiğinizi onaylıyorsunuz
# You confirm that you have read and accept these warnings
#
# Lisans: MIT License - LICENSE dosyasına bakın
# License: MIT License - see LICENSE file
# =============================================================================

# =================== AYARLAR VE GLOBAL DEĞİŞKENLER =====================

# Geliştirilmiş ve optimize edilmiş sistem mesajı
SYSTEM_MESSAGE="Sen Linux/macOS terminal uzmanısın. Kullanıcı isteklerini analiz edip SADECE JSON formatında yanıt veriyorsun.

KRİTİK KURALLAR:
1. SADECE JSON formatında yanıt ver, başka hiçbir şey yazma
2. JSON objesi tek satırda olmalı, hiç yeni satır olmasın  
3. Türkçe karakterleri doğru encode et

İKİ MOD VAR:
A) KOMUT MODU: Kullanıcı bir işlem yaptırmak istiyorsa
   Örnek: {\"command\":\"ls -l > dosya.txt\"}
   
B) AÇIKLAMA MODU: Kullanıcı bir şeyin nasıl yapıldığını öğrenmek istiyorsa  
   Örnek: {\"explanation\":\"Komut çıktısını dosyaya yazmak için '>' operatörü kullanılır. 'ls -l > liste.txt' komutu ile ls -l çıktısını liste.txt dosyasına yazar.\"}

TEHLİKELİ KOMUTLAR:
Tehlikeli isteklerde: {\"command\":\"DANGER\"} veya {\"explanation\":\"DANGER\"}

HATIRLA: Tek JSON objesi, tek satır, başka hiçbir şey yazma!"

# Dosya yolları ve ayarlar
SMART_EXECUTE_CONFIG_DIR="$HOME/.config/smart_execute"
BLACKLIST_FILE="$SMART_EXECUTE_CONFIG_DIR/blacklist.txt"
WHITELIST_FILE="$SMART_EXECUTE_CONFIG_DIR/whitelist.txt"
LOG_FILE="$SMART_EXECUTE_CONFIG_DIR/log.txt"

# OLLAMA API ayarları
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

# AI Agent tespiti
_smart_is_ai_agent() {
    [[ -n "${VSCODE_SHELL_INTEGRATION:-}" ]] && return 0
    [[ "${TERM_PROGRAM:-}" == "vscode" ]] && return 0
    [[ "${TERM_PROGRAM:-}" == "cursor" ]] && return 0
    [[ "${TERM_PROGRAM:-}" == "windsurf" ]] && return 0
    [[ -n "${GEMINI_CLI:-}" ]] && return 0
    [[ -n "${ANTIGRAVITY:-}" ]] && return 0
    [[ -n "${ANTIGARVTY:-}" ]] && return 0
    [[ -n "${AI_TERMINAL:-}" ]] && return 0
    [[ -n "${INSIDE_EMACS:-}" ]] && return 0
    [[ "${TERM:-}" == "dumb" ]] && return 0
    return 1
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
rm\s+-rf\s+/  # Kök dizini silme
rm\s+-rf\s+\.\.?/  # Üst dizinleri silme
rm\s+-rf\s+--no-preserve-root\s+/  # Kökü korumasız silme
:\(\)\s*{\s*:|:&;\s*};  # Fork bombası
shutdown\b
reboot\b
halt\b
poweroff\b
chown\s+-R\s+/  # Kökün sahipliğini değiştirme
chmod\s+-R\s+777\s+/  # Kök dizine tam yetki verme
mv\s+.*\s+/dev/null  # Dosyaları /dev/null'a taşıma
cp\s+/dev/zero  # /dev/zero'dan kopyalama
cp\s+/dev/random  # /dev/random'dan kopyalama
yes\s+>|yes\s+>>  # yes ile dosya doldurma
>\s*/dev/sd[a-z]  # Disk üzerine yazma
>\s*/dev/nvme[0-9]  # NVMe disk üzerine yazma
dd\s+.*of=/dev/(sd|nvme).*  # dd ile disk üzerine yazma
dd\s+if=/dev/zero  # dd ile sıfır yazma
dd\s+if=/dev/random  # dd ile rastgele veri yazma
mkfs.* /dev/(sd|nvme).*  # Disk biçimlendirme
kill\s+-9\s+-1  # Tüm işlemleri öldürme
killall\s+-9  # Tüm işlemleri öldürme
ln\s+-sf\s+/dev/null  # Sembolik link ile dosya yok etme
echo\s+>\s+/etc/passwd  # Parola dosyasını bozma
echo\s+>\s+/etc/shadow  # Gölge parola dosyasını bozma
userdel\b
groupdel\b
passwd\s+-d\b
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
ls -l
ls -la
cd
pwd
git status
git diff
git log
git pull
git push
git add
git commit
git checkout
git branch
git merge
git stash
cat
tail
head
grep
echo
whoami
clear
history
source
which
whereis
man
uname
ps
kill
jobs
bg
fg
export
set
alias
unalias
mkdir
rmdir
touch
cp
mv
stat
chmod
chown
find
df
du
free
uptime
ping
curl
wget
ssh
scp
rsync
less
more
date
diff
sort
uniq
wc
cut
tr
awk
sed
sleep
true
false
printenv
env
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

# Merkezi LLM API Çağrı Fonksiyonu - Optimize edilmiş
_call_llm() {
    local user_prompt="$1"
    local mode="$2"
    local full_prompt

    if [[ "$mode" == "explanation" ]]; then
        full_prompt="$SYSTEM_MESSAGE

MOD: AÇIKLAMA MODU
Kullanıcı bir konuyu öğrenmek istiyor. Sadece şu JSON formatında yanıt ver:
{\"explanation\":\"Türkçe detaylı açıklama buraya\"}

Kullanıcı sorusu: $user_prompt"
    else
        full_prompt="$SYSTEM_MESSAGE

MOD: KOMUT MODU  
Kullanıcı bir işlem yaptırmak istiyor. Sadece şu JSON formatında yanıt ver:
{\"command\":\"uygun_komut_buraya\"}

Kullanıcı isteği: $user_prompt"
    fi

    # Bilgilendirme mesajlarını stderr'e (> &2) göndererek yakalanmalarını önle
    echo -n $'\n\e[2m🧠 LLM düşünüyor...\e[0m' >&2

    local json_payload
    json_payload=$(jq -n \
                   --arg model "$LLM_MODEL" \
                   --arg prompt "$full_prompt" \
                   --argjson temperature 0.1 \
                   --argjson top_p 0.9 \
                   '{model: $model, prompt: $prompt, stream: false, format: "json", options: {temperature: $temperature, top_p: $top_p}}')

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

    # JSON geçerliliğini kontrol et
    if ! echo "$response_field" | jq -e . >/dev/null 2>&1; then
        echo -e "\n\e[31m❌ Hata: LLM geçersiz JSON döndürdü.\e[0m Yanıt: $response_field" >&2
        _smart_log "LLM_INVALID_JSON_RESPONSE" "Response: $response_field"
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
        explanation=$(echo "$llm_json_response" | jq -r '.explanation // empty' 2>/dev/null)

        if [[ -z "$explanation" ]]; then
            # Fallback: tüm yanıtı açıklama olarak kullan
            explanation="$llm_json_response"
            echo -e "\n\e[33m⚠️  Uyarı: LLM beklenen JSON formatında yanıt vermedi.\e[0m" >&2
        fi

        if [[ "$explanation" == "DANGER" ]]; then
            echo -e "\n\e[31m❌ Güvenlik: İstek tehlikeli bulundu ve reddedildi.\e[0m"
            _smart_log "EXPLANATION_DANGER" "Request: $user_command"
        else
            echo -e "\n\e[1;34m🧠 Açıklama:\e[0m\n$explanation"
            _smart_log "EXPLANATION_SUCCESS" "Request: $user_command"
        fi
        BUFFER=""
        zle redisplay
    else # command modu
        local suggested_command
        suggested_command=$(echo "$llm_json_response" | jq -r '.command // empty' 2>/dev/null)

        if [[ -z "$suggested_command" ]]; then
            # Fallback: tüm yanıtı komut olarak kullan (temizleyerek)
            suggested_command=$(echo "$llm_json_response" | sed 's/^[{"]*//; s/["}]*$//; s/.*command[": ]*//; s/[",}].*$//')
            if [[ -z "$suggested_command" ]]; then
                echo -e "\n\e[31m❌ Hata: LLM geçerli bir komut döndürmedi.\e[0m" >&2
                echo -e "\e[33mLLM Yanıtı:\e[0m $llm_json_response" >&2
                _smart_log "LLM_EMPTY_COMMAND" "Response: $llm_json_response"
                BUFFER=""
                zle redisplay
                return
            fi
            echo -e "\n\e[33m⚠️  Uyarı: LLM beklenen JSON formatında yanıt vermedi, otomatik düzeltildi.\e[0m" >&2
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

if [[ -o interactive ]] && ! _smart_is_ai_agent; then
    zle -N smart_accept_line
    bindkey '^M' smart_accept_line
    bindkey '^J' smart_accept_line
fi
