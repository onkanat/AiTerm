#!/bin/zsh

# =================== AYARLAR VE GLOBAL DEĞİŞKENLER =====================

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
    # Önce config dizininin var olduğundan emin ol
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
        # Eğer dosya yoksa, güvenli varsayılanları oluştur
        mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
        cat <<EOF > "$BLACKLIST_FILE"
# Tehlikeli Komutlar İçin Regex Kara Listesi
# Boş satırlar ve # ile başlayan satırlar yoksayılır.
rm\s+-rf\s+/
rm\s+-rf\s+\.\.?/
:(){:|:&};
dd\s+.*of=/dev/(sd|nvme).*
mkfs.* /dev/(sd|nvme).*
chmod\s+-R\s+777\s+/
mv\s+.*\s+/dev/null
EOF
        # Dosyayı yeniden oku
        # _smart_load_lists # Bu satır sonsuz döngüye neden olabilir, kaldırıldı.
                          # Dosya oluşturulduktan sonra, bir sonraki _smart_load_lists çağrısında zaten okunacak.
                          # Veya hemen yüklemek için BLACKLIST_PATTERNS'ı burada doldurabilirsiniz.
        # Geçici çözüm: Dosyayı oluşturduktan sonra desenleri hemen yükle
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && BLACKLIST_PATTERNS+=("$line")
        done < "$BLACKLIST_FILE"
    fi

    # Beyaz Liste (isteğe bağlı)
    if [[ -f "$WHITELIST_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" && "$line" != \#* ]] && WHITELIST_PATTERNS+=("$line")
        done < "$WHITELIST_FILE"
    fi
}

# Regex tabanlı kontrol fonksiyonları
_is_blacklisted() {
    for pattern in "${BLACKLIST_PATTERNS[@]}"; do
        if [[ "$1" =~ $pattern ]]; then
            _smart_log "BLACKLIST_MATCH" "Input: '$1' | Pattern: '$pattern'"
            return 0 # Eşleşme bulundu
        fi
    done
    return 1 # Eşleşme bulunamadı
}

# Beyaz liste: Yalnızca beyaz listedeki bir kalıpla tam olarak eşleşen komutları kontrol eder.
# Bu, 'ls -l' gibi argümanlı komutların yanlışlıkla 'ls -l; rm -rf /' gibi tehlikeli
# komutları atlamasını önlemek için daha güvenli bir yaklaşımdır.
# Beyaz listenize 'ls', 'ls -l', 'git status' gibi tam komutları ekleyin.
_is_whitelisted() {
    local input_command="$1"
    # Beyaz liste boşsa, hiçbir şey beyaz listede değildir.
    if [[ ${#WHITELIST_PATTERNS[@]} -eq 0 ]]; then
        return 1
    fi

    for pattern in "${WHITELIST_PATTERNS[@]}"; do
        # Sadece tam eşleşmeyi kontrol et
        if [[ "$input_command" == "$pattern" ]]; then
            _smart_log "WHITELIST_MATCH" "Input: '$input_command' | Pattern: '$pattern'"
            return 0 # Tam eşleşme bulundu
        fi
    done

    return 1 # Eşleşme bulunamadı
}

# =================== ANA ZLE WIDGET'I =====================

smart_accept_line() {
    local original_command="$BUFFER"

    # Boş komutları veya beyaz listedeki komutları direkt çalıştır
    if [[ -z "$original_command" ]] || _is_whitelisted "$original_command"; then
        zle .accept-line
        return
    fi

    # Kara listedeki komutları anında engelle
    if _is_blacklisted "$original_command"; then
        echo -e "\n\e[1;31mGÜVENLİK UYARISI: Komut kara listeye takıldı. İşlem durduruldu.\e[0m"
        _smart_log "KARA_LİSTE_ENGELLEDİ" "$original_command"
        BUFFER="" # Komut satırını temizle
        zle redisplay
        return
    fi

    # Kullanıcıya LLM'in çalıştığını bildir
    echo -n $'\n\e[2m🧠 LLM düşünüyor...\e[0m'

    # LLM Prompt metni. Modelin JSON formatında cevap vermesini istiyoruz.
    PROMPT_TEXT="Sen uzman bir Linux kabuk yardımcısısın. Aşağıdaki doğal dil isteğini veya hatalı komutu analiz et ve bir JSON nesnesi döndür. Bu JSON nesnesi, 'command' adında tek bir anahtar içermelidir. Bu anahtarın değeri, çalıştırılabilir bash komutu olmalıdır. Eğer istek tehlikeli ise (\'rm -rf /\', \'dd\', fork bombası vb.), 'command' anahtarının değeri olarak 'DANGER' kelimesini ata. İşte girdi: "

    # JSON'u güvenli bir şekilde oluşturmak için jq kullan.
    # 'format: "json"' parametresi ile modelin her zaman geçerli bir JSON yanıtı vermesini sağla.
    json_payload=$(jq -n \
                   --arg model "$LLM_MODEL" \
                   --arg prompt_text "$PROMPT_TEXT" \
                   --arg user_command "$original_command" \
                   '{model: $model, prompt: ($prompt_text + $user_command), stream: false, format: "json"}')

    # LLM API'sine isteği gönder ve cevabı al.
    llm_response=$(curl -s --max-time $LLM_TIMEOUT -X POST "$LLM_URL" \
      -H "Content-Type: application/json" \
      -d "$json_payload")
    local curl_exit_code=$?

    # Önceki komut satırını temizle (LLM düşünüyor... mesajı)
    echo -ne "\r\e[K"

    # curl'un başarılı olup olmadığını kontrol et
    if [ $curl_exit_code -ne 0 ]; then
        echo -e "\n\e[31m❌ Hata: LLM API'sine bağlanılamadı (curl çıkış kodu: $curl_exit_code).\e[0m"
        _smart_log "LLM_CONNECTION_ERROR" "curl exit code: $curl_exit_code"
        BUFFER=""
        zle redisplay
        return
    fi

    # LLM cevabının geçerli bir JSON olup olmadığını kontrol et
    if ! echo "$llm_response" | jq -e . >/dev/null 2>&1; then
        echo -e "\n\e[31m❌ Hata: LLM'den geçersiz JSON yanıtı alındı. Yanıt:\e[0m"
        cat <<< "$llm_response"
        _smart_log "INVALID_JSON" "Response: $llm_response"
        BUFFER=""
        zle redisplay
        return
    fi

    # LLM'den gelen response alanının boş olup olmadığını kontrol et
    local response_field=$(echo "$llm_response" | jq -r '.response // ""')
    if [ -z "$response_field" ]; then
        echo -e "\n\e[31m❌ Hata: LLM boş bir 'response' alanı döndürdü.\e[0m"
        _smart_log "LLM_EMPTY_RESPONSE_FIELD" "Ham Cevap: $llm_response"
        BUFFER=""
        zle redisplay
        return
    fi

    # Response alanından command'ı çıkar
    # Response alanı zaten bir JSON string olduğu için doğrudan parse edebiliriz
    local suggested_command
    suggested_command=$(echo "$response_field" | jq -r '.command // ""' 2>/dev/null)
    
    # Eğer bu başarısız olursa, belki response alanı düz text'tir, tekrar deneyelim
    if [ -z "$suggested_command" ] || [ "$suggested_command" = "null" ]; then
        # Debug için response_field'ı logla
        _smart_log "DEBUG_RESPONSE_FIELD" "Content: $response_field"
        # fromjson ile dene (eğer response alanı quoted JSON string ise)
        suggested_command=$(echo "$llm_response" | jq -r '.response | fromjson | .command // ""' 2>/dev/null)
    fi

    # LLM'den gelen komutun boş olup olmadığını kontrol et
    if [ -z "$suggested_command" ]; then
        echo -e "\n\e[31m❌ Hata: LLM boş bir komut döndürdü ('command' alanı boş veya yok).\e[0m"
        _smart_log "LLM_EMPTY_COMMAND_FIELD" "Response field: $response_field"
        BUFFER=""
        zle redisplay
        return
    fi

    # Tehlike kontrolü
    if [[ "$suggested_command" == "DANGER" ]]; then
        echo -e "\n\e[31m❌ Tehlikeli komut isteği LLM tarafından reddedildi.\e[0m"
        _smart_log "LLM_DANGER_DETECTED" "Komut: $suggested_command"
        BUFFER=""
        zle redisplay
        return
    fi

    # Komut artık JSON'dan geldiği için temizlenmiş kabul ediliyor.
    local cleaned_command="$suggested_command"

    # Yine de son bir güvenlik kontrolü olarak öneriyi kara listeye göre kontrol et
    if _is_blacklisted "$cleaned_command"; then
        echo -e "\n\e[1;31mGÜVENLİK UYARISI: LLM potansiyel olarak tehlikeli bir komut önerdi (kara liste) ve engellendi.\e[0m"
        _smart_log "LLM_BLACKLIST_BLOCKED" "Girdi: $original_command | Öneri: $cleaned_command"
        BUFFER=""
        zle redisplay
        return
    fi

    # Önerilen komutu kullanıcıya göster
    echo -e "🤔 Şunu mu demek istediniz? (\e[94m$original_command\e[0m)"
    echo -e "\e[1;32m$ $cleaned_command\e[0m"
    read -k1 -r "?Çalıştır [E], Düzenle [D], İptal [herhangi bir tuş]? "
    echo

    if [[ $REPLY =~ ^[Ee]$ ]]; then
        _smart_log "ÇALIŞTIRILDI" "Girdi: $original_command | Komut: $cleaned_command"
        BUFFER=$cleaned_command
        zle .accept-line
    elif [[ $REPLY =~ ^[Dd]$ ]]; then
        BUFFER=$cleaned_command
        zle redisplay
    else
        _smart_log "İPTAL_EDİLDİ" "$original_command"
        BUFFER=""
        zle redisplay
    fi
}

# =================== KURULUM =====================

# Gerekli komutların varlığını kontrol et
for cmd in curl jq perl; do
    if ! command -v $cmd &> /dev/null; then
        echo "smart_execute: Hata - '$cmd' komutu bulunamadı. Lütfen kurun." >&2 # Hata mesajını stderr'e yönlendir
        return 1
    fi
done

# Listeleri belleğe yükle
_smart_load_lists

# Widget'ı oluştur ve Enter tuşuna bağla
zle -N smart_accept_line
bindkey '^M' smart_accept_line  # ^M Enter tuşudur
bindkey '^J' smart_accept_line  # ^J de Enter tuşudur
