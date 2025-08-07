#!/bin/zsh
# Smart Execute Configuration Wizard
# Bu dosya kurulum sihirbazını içerir

_create_config_wizard() {
    clear
    echo "╔════════════════════════════════════════════╗"
    echo "║         Smart Execute Kurulum Sihirbazı    ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    
    # Güvenlik uyarısı
    echo "⚠️  ÖNEMLI GÜVENLİK UYARISI:"
    echo "Smart Execute bir LLM kullanarak komutlar üretir."
    echo "Bu potansiyel olarak tehlikeli olabilir."
    echo ""
    read -p "Devam etmek istiyor musunuz? [y/N]: " continue_setup
    [[ ! "$continue_setup" =~ ^[Yy]$ ]] && {
        echo "Kurulum iptal edildi."
        return 1
    }
    
    echo ""
    echo "═══════════════════════════════════════════"
    echo "1. LLM Provider Seçimi"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "Hangi LLM sağlayıcısını kullanmak istersiniz?"
    echo "1) Ollama (Yerel, ücretsiz)"
    echo "2) OpenAI API (Ücretli, güçlü)"
    echo "3) Anthropic Claude (Ücretli, en güvenli)"
    echo ""
    read -p "Seçiminiz [1-3]: " provider_choice
    
    case "$provider_choice" in
        1) 
            LLM_PROVIDER="ollama"
            echo "✓ Ollama seçildi"
            ;;
        2)
            LLM_PROVIDER="openai"
            echo "✓ OpenAI seçildi"
            _setup_openai_api
            ;;
        3)
            LLM_PROVIDER="anthropic"
            echo "✓ Anthropic seçildi"
            _setup_anthropic_api
            ;;
        *)
            echo "Geçersiz seçim, Ollama varsayılan olarak seçildi"
            LLM_PROVIDER="ollama"
            ;;
    esac
    
    echo ""
    echo "═══════════════════════════════════════════"
    echo "2. Güvenlik Seviyesi"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "Güvenlik seviyenizi seçin:"
    echo "1) Paranoid (Maksimum güvenlik, her komut için onay)"
    echo "2) Dengeli (Önerilen, orta risk komutlar için onay)"
    echo "3) Rahat (Minimum kontrol, sadece yüksek risk için onay)"
    echo ""
    read -p "Seçiminiz [1-3]: " security_choice
    
    case "$security_choice" in
        1)
            SECURITY_LEVEL=1
            MAX_RISK_SCORE=1
            echo "✓ Paranoid güvenlik seviyesi seçildi"
            ;;
        2)
            SECURITY_LEVEL=2
            MAX_RISK_SCORE=3
            echo "✓ Dengeli güvenlik seviyesi seçildi"
            ;;
        3)
            SECURITY_LEVEL=3
            MAX_RISK_SCORE=5
            echo "✓ Rahat güvenlik seviyesi seçildi"
            ;;
        *)
            echo "Geçersiz seçim, dengeli seviye seçildi"
            SECURITY_LEVEL=2
            MAX_RISK_SCORE=3
            ;;
    esac
    
    echo ""
    echo "═══════════════════════════════════════════"
    echo "3. Ek Özellikler"
    echo "═══════════════════════════════════════════"
    echo ""
    
    # Cache ayarı
    read -p "Cache özelliğini etkinleştir? [Y/n]: " enable_cache
    [[ "$enable_cache" =~ ^[Nn]$ ]] && ENABLE_CACHE=false || ENABLE_CACHE=true
    
    # Audit log ayarı
    read -p "Detaylı audit loglamasını etkinleştir? [Y/n]: " enable_audit
    [[ "$enable_audit" =~ ^[Nn]$ ]] && ENABLE_AUDIT_LOG=false || ENABLE_AUDIT_LOG=true
    
    # Anomali tespiti
    read -p "Anomali tespitini etkinleştir? [Y/n]: " enable_anomaly
    [[ "$enable_anomaly" =~ ^[Nn]$ ]] && ENABLE_ANOMALY_DETECTION=false || ENABLE_ANOMALY_DETECTION=true
    
    echo ""
    echo "═══════════════════════════════════════════"
    echo "4. Yapılandırma Özeti"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "LLM Provider: $LLM_PROVIDER"
    echo "Güvenlik Seviyesi: $SECURITY_LEVEL"
    echo "Cache: $ENABLE_CACHE"
    echo "Audit Log: $ENABLE_AUDIT_LOG"
    echo "Anomali Tespiti: $ENABLE_ANOMALY_DETECTION"
    echo ""
    
    read -p "Bu ayarlarla devam etmek istiyor musunuz? [Y/n]: " confirm_config
    [[ "$confirm_config" =~ ^[Nn]$ ]] && {
        echo "Kurulum iptal edildi."
        return 1
    }
    
    # Yapılandırmayı kaydet
    _save_configuration
    
    echo ""
    echo "✅ Kurulum tamamlandı!"
    echo "Smart Execute artık kullanıma hazır."
    echo ""
    echo "Kullanım örnekleri:"
    echo "  @ masaüstündeki txt dosyalarını listele"
    echo "  @? ls -la"
    echo "  /ls (doğrudan çalıştır)"
    echo ""
}

_setup_openai_api() {
    echo ""
    echo "OpenAI API Key kurulumu:"
    echo "1. https://platform.openai.com/api-keys adresinden API key alın"
    echo "2. API key'inizi girin (görünmeyecektir)"
    echo ""
    read -s -p "OpenAI API Key: " openai_api_key
    echo ""
    
    if [[ -n "$openai_api_key" ]]; then
        echo "$openai_api_key" > "$SMART_EXECUTE_CONFIG_DIR/openai_api_key"
        chmod 600 "$SMART_EXECUTE_CONFIG_DIR/openai_api_key"
        echo "✓ OpenAI API key kaydedildi"
    else
        echo "⚠️  API key girilmedi, Ollama'ya geri dönülüyor"
        LLM_PROVIDER="ollama"
    fi
}

_setup_anthropic_api() {
    echo ""
    echo "Anthropic API Key kurulumu:"
    echo "1. https://console.anthropic.com/ adresinden API key alın"
    echo "2. API key'inizi girin (görünmeyecektir)"
    echo ""
    read -s -p "Anthropic API Key: " anthropic_api_key
    echo ""
    
    if [[ -n "$anthropic_api_key" ]]; then
        echo "$anthropic_api_key" > "$SMART_EXECUTE_CONFIG_DIR/anthropic_api_key"
        chmod 600 "$SMART_EXECUTE_CONFIG_DIR/anthropic_api_key"
        echo "✓ Anthropic API key kaydedildi"
    else
        echo "⚠️  API key girilmedi, Ollama'ya geri dönülüyor"
        LLM_PROVIDER="ollama"
    fi
}

_save_configuration() {
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
    
    cat > "$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf" << EOF
# Smart Execute Security Configuration
# Bu dosya kurulum sihirbazı tarafından oluşturulmuştur

# LLM Provider Settings
LLM_PROVIDER="$LLM_PROVIDER"
FALLBACK_PROVIDER="ollama"
LLM_TIMEOUT=60

# Security Settings
SECURITY_LEVEL=$SECURITY_LEVEL
MAX_COMMAND_LENGTH=1000
MAX_RISK_SCORE=$MAX_RISK_SCORE
RATE_LIMIT_PER_MINUTE=20
SESSION_TIMEOUT=1800

# Feature Flags
ENABLE_CACHE=$ENABLE_CACHE
ENABLE_AUDIT_LOG=$ENABLE_AUDIT_LOG
ENABLE_ANOMALY_DETECTION=$ENABLE_ANOMALY_DETECTION
ENABLE_SANDBOX=false

# Cache Settings
CACHE_TTL=3600

# Log Retention
LOG_RETENTION_DAYS=30
EOF
    
    echo "✓ Yapılandırma dosyası kaydedildi: $SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf"
}

# Test kurulumu
_test_installation() {
    echo ""
    echo "═══════════════════════════════════════════"
    echo "Kurulum Testi"
    echo "═══════════════════════════════════════════"
    echo ""
    
    # Gerekli komutları kontrol et
    local missing_tools=()
    for tool in curl jq; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "❌ Eksik araçlar: ${missing_tools[*]}"
        echo "Lütfen bu araçları kurun ve tekrar deneyin."
        return 1
    fi
    
    echo "✓ Gerekli araçlar mevcut"
    
    # LLM provider bağlantısını test et
    if [[ "$LLM_PROVIDER" == "ollama" ]]; then
        if curl -s --max-time 5 "http://localhost:11434/api/tags" &>/dev/null; then
            echo "✓ Ollama bağlantısı başarılı"
        else
            echo "⚠️  Ollama bağlantısı başarısız - Ollama çalışıyor mu?"
        fi
    fi
    
    echo "✓ Kurulum testi tamamlandı"
}
