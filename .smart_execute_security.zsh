#!/bin/zsh
# Smart Execute Security Module
# Bu dosya gelişmiş güvenlik fonksiyonlarını içerir

# Güvenlik yapılandırmasını yükle
_load_security_config() {
    local config_file="$SMART_EXECUTE_CONFIG_DIR/.smart_execute_security.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        # Varsayılan değerler
        SECURITY_LEVEL=2
        MAX_COMMAND_LENGTH=1000
        RATE_LIMIT_PER_MINUTE=20
        SESSION_TIMEOUT=1800
        ENABLE_AUDIT_LOG=true
        ENABLE_ANOMALY_DETECTION=true
    fi
}

# Gelişmiş audit loglama
_audit_log() {
    [[ "$ENABLE_AUDIT_LOG" != "true" ]] && return 0
    
    local level="$1"
    local action="$2" 
    local details="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user=$(whoami)
    local pid=$$
    local tty=$(tty 2>/dev/null || echo "unknown")
    local pwd="$PWD"
    
    echo "$timestamp|$level|$user|$pid|$tty|$pwd|$action|$details" >> "$AUDIT_LOG"
}

# Risk değerlendirmesi
_assess_risk() {
    local command="$1"
    local risk_score=0
    
    # Risk faktörleri
    [[ "$command" =~ sudo ]] && ((risk_score += 3))
    [[ "$command" =~ rm.*-r ]] && ((risk_score += 2))
    [[ "$command" =~ \> ]] && ((risk_score += 1))
    [[ "$command" =~ chmod.*777 ]] && ((risk_score += 4))
    [[ "$command" =~ wget.*sh|curl.*sh ]] && ((risk_score += 5))
    [[ "$command" =~ eval|exec ]] && ((risk_score += 3))
    [[ "$command" =~ \&\&|\|\| ]] && ((risk_score += 1))
    [[ "$command" =~ /dev/sd|/dev/nvme ]] && ((risk_score += 5))
    [[ "$command" =~ mkfs|dd ]] && ((risk_score += 5))
    
    echo $risk_score
}

# Input sanitization
_sanitize_input() {
    local input="$1"
    local sanitized
    
    # Uzunluk kontrolü
    if [[ ${#input} -gt $MAX_COMMAND_LENGTH ]]; then
        _audit_log "SECURITY" "INPUT_TOO_LONG" "Length: ${#input}, Max: $MAX_COMMAND_LENGTH"
        return 1
    fi
    
    # Zararlı karakterleri kontrol et (ancak kaldırma, sadece uyar)
    if [[ "$input" =~ [\`\$\(\)\{\}] ]]; then
        _audit_log "WARNING" "SUSPICIOUS_CHARS" "Input: $input"
    fi
    
    echo "$input"
}

# Rate limiting kontrolü
_check_rate_limit() {
    local current_minute=$(date '+%Y-%m-%d %H:%M')
    local rate_file="$SMART_EXECUTE_CONFIG_DIR/.rate_limit"
    local count=0
    
    if [[ -f "$rate_file" ]]; then
        local last_minute=$(head -1 "$rate_file" 2>/dev/null)
        if [[ "$last_minute" == "$current_minute" ]]; then
            count=$(tail -1 "$rate_file" 2>/dev/null || echo 0)
        fi
    fi
    
    ((count++))
    
    if [[ $count -gt $RATE_LIMIT_PER_MINUTE ]]; then
        _audit_log "SECURITY" "RATE_LIMIT_EXCEEDED" "Count: $count, Limit: $RATE_LIMIT_PER_MINUTE"
        return 1
    fi
    
    # Rate limit dosyasını güncelle
    echo "$current_minute" > "$rate_file"
    echo "$count" >> "$rate_file"
    
    return 0
}

# Anomali tespiti
_detect_anomalies() {
    [[ "$ENABLE_ANOMALY_DETECTION" != "true" ]] && return 0
    
    local command="$1"
    local anomaly_score=0
    
    # Son 5 dakikada çok fazla komut
    local recent_commands=$(grep "$(date '+%Y-%m-%d %H:%M' -d '5 minutes ago')" "$LOG_FILE" 2>/dev/null | wc -l)
    [[ $recent_commands -gt 50 ]] && ((anomaly_score += 2))
    
    # Şüpheli komut kalıpları
    [[ "$command" =~ (curl.*sh|wget.*sh|base64.*exec|python.*-c|perl.*-e) ]] && ((anomaly_score += 3))
    
    # Gece saatlerinde yoğun aktivite (00:00-06:00)
    local hour=$(date '+%H')
    [[ $hour -ge 0 && $hour -le 6 ]] && [[ $recent_commands -gt 10 ]] && ((anomaly_score += 1))
    
    if [[ $anomaly_score -ge 3 ]]; then
        _audit_log "ANOMALY" "SUSPICIOUS_BEHAVIOR" "Score: $anomaly_score, Command: $command"
        return 1
    fi
    
    return 0
}

# Session timeout kontrolü
_check_session_timeout() {
    local session_file="$SMART_EXECUTE_CONFIG_DIR/.session"
    local current_time=$(date +%s)
    
    if [[ -f "$session_file" ]]; then
        local last_activity=$(cat "$session_file" 2>/dev/null || echo 0)
        local time_diff=$((current_time - last_activity))
        
        if [[ $time_diff -gt $SESSION_TIMEOUT ]]; then
            _audit_log "SESSION" "TIMEOUT" "Inactive for ${time_diff}s"
            echo "⚠️  Oturum zaman aşımına uğradı. Yeniden kimlik doğrulama gerekli."
            return 1
        fi
    fi
    
    # Session dosyasını güncelle
    echo "$current_time" > "$session_file"
    return 0
}

# Risk seviyesine göre onay
_confirm_execution() {
    local command="$1"
    local risk_score=$(_assess_risk "$command")
    
    if [[ $risk_score -gt $MAX_RISK_SCORE ]]; then
        echo -e "\n🚨 YÜKSEK RİSK KOMUTU TESPİT EDİLDİ!"
        echo -e "Risk Seviyesi: $risk_score/$MAX_RISK_SCORE"
        echo -e "Komut: \e[31m$command\e[0m"
        echo ""
        read -p "Devam etmek için 'CONFIRM' yazın (büyük harf): " confirmation
        
        if [[ "$confirmation" != "CONFIRM" ]]; then
            _audit_log "SECURITY" "HIGH_RISK_REJECTED" "Risk: $risk_score, Command: $command"
            return 1
        else
            _audit_log "SECURITY" "HIGH_RISK_CONFIRMED" "Risk: $risk_score, Command: $command"
        fi
    elif [[ $risk_score -gt 2 ]]; then
        echo -e "\n⚠️  Orta risk komutu (Risk: $risk_score)"
        read -k1 -r "?Devam et? [y/N]: "
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || return 1
    fi
    
    return 0
}

# Güvenli JSON parsing
_parse_json_safely() {
    local json="$1"
    local field="$2"
    
    # JSON geçerliliğini kontrol et
    if ! echo "$json" | jq -e . >/dev/null 2>&1; then
        _audit_log "ERROR" "INVALID_JSON" "Input: $json"
        return 1
    fi
    
    # Alanı güvenli şekilde çıkar
    local result
    result=$(echo "$json" | jq -r ".$field // empty" 2>/dev/null)
    
    if [[ -z "$result" || "$result" == "null" ]]; then
        return 1
    fi
    
    echo "$result"
    return 0
}

# Output sanitization
_sanitize_output() {
    local output="$1"
    
    # Tehlikeli karakterleri temizle
    output=$(echo "$output" | sed 's/[`$()]//g; s/&&\|;;\||//g')
    
    # Uzunluk kontrolü
    if [[ ${#output} -gt $MAX_COMMAND_LENGTH ]]; then
        output="${output:0:$MAX_COMMAND_LENGTH}"
        _audit_log "WARNING" "OUTPUT_TRUNCATED" "Original length: ${#1}"
    fi
    
    echo "$output"
}

# Başlangıçta güvenlik konfigürasyonunu yükle
_load_security_config
