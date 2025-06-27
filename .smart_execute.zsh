#!/bin/zsh

# =================== AYARLAR VE GLOBAL DEĞİŞKENLER =====================

# Dosya yolları ve ayarlar
SMART_EXECUTE_CONFIG_DIR="$HOME/.config/smart_execute"
BLACKLIST_FILE="$SMART_EXECUTE_CONFIG_DIR/blacklist.txt"
WHITELIST_FILE="$SMART_EXECUTE_CONFIG_DIR/whitelist.txt"
LOG_FILE="$SMART_EXECUTE_CONFIG_DIR/log.txt"

LLM_URL="http://localhost:11434/api/generate"
LLM_MODEL="llama3"
LLM_TIMEOUT=5

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
_is_blacklisted() { [[ $1 =~ (${(j:|:)BLACKLIST_PATTERNS}) ]] }
_is_whitelisted() { [[ -n "$WHITELIST_PATTERNS" ]] && [[ $1 =~ (${(j:|:)WHITELIST_PATTERNS}) ]] }

# =================== ANA ZLE WIDGET'I =====================

smart_accept_line() {
    local original_command="$BUFFER"
    local suggestion

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

    # LLM Prompt'u
    PROMPT="Sen uzman bir Linux kabuk yardımcısısın. Aşağıdaki doğal dil isteğini veya hatalı komutu, tek satırlık, çalıştırılabilir bir bash komutuna çevir. SADECE komutun kendisini yaz, başka hiçbir açıklama ekleme.
    TEHLİKELİ komutlar ('rm -rf /', 'dd', fork bombası vb.) üretme. Eğer istek tehlikeli ise, cevap olarak sadece 'DANGER' kelimesini yaz.
    İşte girdi: '$original_command'"

    # LLM'den öneri al (stderr'i gizle)
    suggestion=$(timeout ${LLM_TIMEOUT}s curl -s "$LLM_URL" -d '{
      "model": "'"$LLM_MODEL"'", "prompt": "'"$PROMPT"'", "stream": false
    }' 2>/dev/null | jq -r .response | tr -d '`' | sed 's/bash//g' | xargs)
    
    # "Düşünüyor..." mesajını sil
    echo -ne "\r\033[K"

    # Öneri yoksa, hatalıysa veya orijinal komutla aynıysa, orijinali çalıştır
    if [[ -z "$suggestion" || "$suggestion" == "$original_command" || "$suggestion" == "null" ]]; then
        zle .accept-line
        return
    fi

    # LLM tehlike bildirdiyse veya öneri kara listedeyse engelle
    if [[ "$suggestion" == "DANGER" ]] || _is_blacklisted "$suggestion"; then
        echo -e "\e[1;31mGÜVENLİK UYARISI: LLM potansiyel olarak tehlikeli bir komut önerdi ve engellendi.\e[0m"
        _smart_log "LLM_TEHLİKE_ENGELLEDİ" "Girdi: $original_command | Öneri: $suggestion"
        BUFFER=""
        zle redisplay
        return
    fi

    # Kullanıcıya onayı sun
    echo -e "🤔 Şunu mu demek istediniz? (\e[94m$original_command\e[0m)"
    echo -e "\e[1;32m$ $suggestion\e[0m"
    read -k1 -r "?Çalıştır [E], Düzenle [D], İptal [herhangi bir tuş]? "
    echo

    if [[ $REPLY =~ ^[Ee]$ ]]; then
        _smart_log "ÇALIŞTIRILDI" "Girdi: $original_command | Komut: $suggestion"
        BUFFER=$suggestion
        zle .accept-line
    elif [[ $REPLY =~ ^[Dd]$ ]]; then
        BUFFER=$suggestion
        zle redisplay
    else
        _smart_log "İPTAL_EDİLDİ" "$original_command"
        BUFFER=""
        zle redisplay
    fi
}

# =================== KURULUM =====================

# Gerekli komutların varlığını kontrol et
for cmd in curl jq; do
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
bindkey '^J' smart_accept_line  # ^J de Enter tuşudur (genellikle line feed)

_smart_log "BAŞLATILDI" "Smart Execute başarıyla yüklendi."
