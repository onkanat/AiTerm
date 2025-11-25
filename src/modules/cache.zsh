#!/bin/zsh
# Smart Execute Cache Module
# Bu dosya cache işlevlerini içerir
#
# TODO: Cache sistemi optimize edilecek
# - Boş response döndürme sorunu çözülecek
# - Async cache işlemleri iyileştirilecek
# - Cache invalidation mekanizması eklenecek
# 
# Şu anda cache sistemi devre dışı (ENABLE_CACHE=false)

# Cache yapılandırması
CACHE_DIR="$SMART_EXECUTE_CONFIG_DIR/cache"
CACHE_TTL=${CACHE_TTL:-3600}  # 1 saat varsayılan

# Cache dizinini oluştur
_init_cache() {
    [[ "$ENABLE_CACHE" != "true" ]] && return 0
    mkdir -p "$CACHE_DIR"
}

# Hash hesaplama
_calculate_hash() {
    local input="$1"
    echo -n "$input" | sha256sum | cut -d' ' -f1 2>/dev/null || \
    echo -n "$input" | shasum -a 256 | cut -d' ' -f1 2>/dev/null || \
    echo -n "$input" | md5sum | cut -d' ' -f1 2>/dev/null || \
    echo -n "$input" | md5 | cut -d' ' -f1 2>/dev/null
}

# Cache'den yanıt al
_get_cached_response() {
    [[ "$ENABLE_CACHE" != "true" ]] && return 1
    
    local query="$1"
    local query_hash=$(_calculate_hash "$query")
    local cache_file="$CACHE_DIR/$query_hash"
    
    if [[ -f "$cache_file" ]]; then
        local cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
        local current_time=$(date +%s)
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -lt $CACHE_TTL ]]; then
            _audit_log "CACHE" "HIT" "Query hash: $query_hash, Age: ${cache_age}s"
            cat "$cache_file"
            return 0
        else
            _audit_log "CACHE" "EXPIRED" "Query hash: $query_hash, Age: ${cache_age}s"
            rm -f "$cache_file"
        fi
    fi
    
    _audit_log "CACHE" "MISS" "Query hash: $query_hash"
    return 1
}

# Cache'e yanıt kaydet
_cache_response() {
    [[ "$ENABLE_CACHE" != "true" ]] && return 0
    
    local query="$1"
    local response="$2"
    local query_hash=$(_calculate_hash "$query")
    local cache_file="$CACHE_DIR/$query_hash"
    
    # Cache'e kaydet
    echo "$response" > "$cache_file"
    _audit_log "CACHE" "STORE" "Query hash: $query_hash"
}

# Cache temizleme
_cleanup_cache() {
    [[ "$ENABLE_CACHE" != "true" ]] && return 0
    [[ ! -d "$CACHE_DIR" ]] && return 0
    
    local current_time=$(date +%s)
    local cleaned_count=0
    
    # Zsh nomatch hatası için güvenli glob kullanımı
    setopt NULL_GLOB
    for cache_file in "$CACHE_DIR"/*; do
        [[ -f "$cache_file" ]] || continue
        
        local cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -gt $CACHE_TTL ]]; then
            rm -f "$cache_file"
            ((cleaned_count++))
        fi
    done
    unsetopt NULL_GLOB
    
    [[ $cleaned_count -gt 0 ]] && _audit_log "CACHE" "CLEANUP" "Removed $cleaned_count expired entries"
}

# Cache istatistikleri
_cache_stats() {
    [[ "$ENABLE_CACHE" != "true" ]] && {
        echo "Cache devre dışı"
        return 0
    }
    
    [[ ! -d "$CACHE_DIR" ]] && {
        echo "Cache dizini bulunamadı"
        return 0
    }
    
    local total_files=$(find "$CACHE_DIR" -type f | wc -l)
    local total_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
    
    echo "Cache İstatistikleri:"
    echo "  Toplam girdi: $total_files"
    echo "  Toplam boyut: $total_size"
    echo "  TTL: ${CACHE_TTL}s ($(($CACHE_TTL / 60)) dakika)"
    echo "  Dizin: $CACHE_DIR"
}

# Cache'i tamamen temizle
_clear_cache() {
    [[ "$ENABLE_CACHE" != "true" ]] && return 0
    
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"/*
        _audit_log "CACHE" "CLEAR_ALL" "All cache entries removed"
        echo "Cache temizlendi"
    fi
}

# Cache başlatma
_init_cache
