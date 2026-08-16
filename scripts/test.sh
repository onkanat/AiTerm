#!/bin/zsh
# Smart Execute v2.0 Test Suite

# Test sonuçları
declare -i TESTS_TOTAL=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0

# Test helper fonksiyonları
test_assert() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -n "Test ${TESTS_TOTAL}: $description... "
    
    local result
    result=$(eval "$command" 2>/dev/null)
    
    if [[ "$result" == "$expected" ]]; then
        echo -e "\e[32mPASS\e[0m"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "\e[31mFAIL\e[0m"
        echo "  Expected: $expected"
        echo "  Got: $result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_function_exists() {
    local function_name="$1"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -n "Test ${TESTS_TOTAL}: Function $function_name exists... "
    
    if [[ "$(whence -w "$function_name" 2>/dev/null)" == *function* ]]; then
        echo -e "\e[32mPASS\e[0m"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "\e[31mFAIL\e[0m"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_file_exists() {
    local file_path="$1"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -n "Test ${TESTS_TOTAL}: File $file_path exists... "
    
    if [[ -f "$file_path" ]]; then
        echo -e "\e[32mPASS\e[0m"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "\e[31mFAIL\e[0m"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Ana test fonksiyonu
run_tests() {
    echo "🧪 Smart Execute v2.0 Test Suite"
    echo "================================"
    echo ""
    
    # Gerekli komutları test et
    echo "📋 Dependency Tests"
    echo "-------------------"
    
    test_assert "curl command exists" "command -v curl >/dev/null && echo 'exists'" "exists"
    test_assert "jq command exists" "command -v jq >/dev/null && echo 'exists'" "exists"
    
    echo ""
    
    # Dosya varlığı testleri
    echo "📁 File Existence Tests"
    echo "----------------------"
    
    test_file_exists "src/core/smart_execute_v2.zsh"
    test_file_exists "src/modules/security.zsh"
    test_file_exists "src/modules/cache.zsh"
    test_file_exists "src/modules/providers.zsh"
    test_file_exists "src/modules/wizard.zsh"
    test_file_exists "config/blacklist.txt"
    
    echo ""
    
    # Smart Execute'u yükle
    echo "🔧 Loading Smart Execute"
    echo "----------------------"
    
    # Test ortamı için geçici değişkenler
    export SMART_EXECUTE_CONFIG_DIR="$(pwd)/test_tmp"
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR"
    mkdir -p "$SMART_EXECUTE_CONFIG_DIR/zsh_tmp"
    export TMPPREFIX="$SMART_EXECUTE_CONFIG_DIR/zsh_tmp/zsh"
    
    # Ana dosyayı yükle
    if [[ -f "src/core/smart_execute_v2.zsh" ]]; then
        source "src/core/smart_execute_v2.zsh" 2>/dev/null
        echo "✓ Smart Execute loaded"
    else
        echo "❌ Failed to load Smart Execute"
        return 1
    fi
    
    echo ""
    
    # Fonksiyon testleri
    echo "🔧 Function Tests"
    echo "----------------"
    
    test_function_exists "_smart_log"
    test_function_exists "_smart_load_lists" 
    test_function_exists "_is_blacklisted"
    test_function_exists "_is_whitelisted"
    test_function_exists "smart_accept_line"
    test_function_exists "smart_execute_command"
    
    # Güvenlik modülü fonksiyonları
    test_function_exists "_assess_risk"
    test_function_exists "_sanitize_input"
    test_function_exists "_audit_log"
    
    # Cache modülü fonksiyonları
    test_function_exists "_get_cached_response"
    test_function_exists "_cache_response"
    
    echo ""
    
    # Güvenlik testleri
    echo "🔒 Security Tests"
    echo "----------------"
    
    # Kara liste testlerini çalıştır
    if [[ "$(whence -w _is_blacklisted 2>/dev/null)" == *function* ]]; then
        _smart_load_lists
        
        test_assert "Blacklist detects rm -rf /" "_is_blacklisted 'rm -rf /' && echo 'blocked'" "blocked"
        test_assert "Blacklist detects dd command" "_is_blacklisted 'dd if=/dev/zero of=/dev/sda' && echo 'blocked'" "blocked"
        test_assert "Blacklist allows safe command" "_is_blacklisted 'ls -la' || echo 'allowed'" "allowed"
    fi
    
    # Risk değerlendirme testleri
    if [[ "$(whence -w _assess_risk 2>/dev/null)" == *function* ]]; then
        test_assert "Risk assessment for safe command" "_assess_risk 'ls -la'" "0"
        # Risk skorları değişebilir, bu yüzden sayısal karşılaştırma yapmıyoruz
    fi
    
    echo ""
    
    # Yapılandırma testleri
    echo "⚙️  Configuration Tests"
    echo "----------------------"
    
    test_assert "Config directory exists" "[[ -d '$SMART_EXECUTE_CONFIG_DIR' ]] && echo 'exists'" "exists"
    
    # Liste dosyalarının oluşturulmasını test et
    _smart_load_lists
    test_file_exists "$SMART_EXECUTE_CONFIG_DIR/blacklist.txt"
    test_file_exists "$SMART_EXECUTE_CONFIG_DIR/whitelist.txt"
    
    echo ""
    
    # Cache testleri
    echo "💾 Cache Tests"
    echo "--------------"
    echo ""
    
    if [[ "$(whence -w _init_cache 2>/dev/null)" == *function* ]]; then
        ENABLE_CACHE=true
        _init_cache
        
        test_assert "Cache directory created" "[[ -d '$SMART_EXECUTE_CONFIG_DIR/cache' ]] && echo 'exists'" "exists"
        
        # Cache işlevselliğini test et
        if [[ "$(whence -w _cache_response 2>/dev/null)" == *function* ]] && [[ "$(whence -w _get_cached_response 2>/dev/null)" == *function* ]]; then
            _cache_response "test_query" "test_response"
            test_assert "Cache stores and retrieves data" "_get_cached_response 'test_query'" "test_response"
        fi
    fi
    
    echo ""
    
    # JSON parsing testleri
    echo "📝 JSON Parsing Tests"
    echo "--------------------"
    
    if [[ "$(whence -w _parse_json_safely 2>/dev/null)" == *function* ]]; then
        local test_json='{"command": "ls -la"}'
        test_assert "JSON parsing extracts command" "_parse_json_safely '$test_json' 'command'" "ls -la"
        
        local invalid_json='invalid json'
        test_assert "JSON parsing handles invalid input" "_parse_json_safely '$invalid_json' 'command' || echo 'failed'" "failed"
    fi
    
    echo ""
    
    # AiTerm CLI Tests
    echo "🤖 AiTerm CLI Tests"
    echo "-----------------"
    
    # Mock test files for cleaning & truncation
    local test_out="$(pwd)/test_tmp/sample_output"
    echo -e "Line 1\nLine 2\nProgress bar \rOverwritten line\nLine 5\nAn Error occurred here\nLine 7\nLine 8" > "$test_out"
    
    # Verify clean carriage return logic
    test_assert "Carriage returns cleaned" "source src/core/aiterm; _aiterm_clean_file '$test_out' '${test_out}.clean' 'false'; cat '${test_out}.clean' | grep -q 'Progress bar' && echo 'failed' || echo 'passed'" "passed"
    
    # Verify ANSI escape sequence removal
    local color_out="$(pwd)/test_tmp/color_output"
    echo -e "\e[31mRed text\e[0m and \e[32mGreen text\e[0m" > "$color_out"
    test_assert "ANSI escape codes stripped" "source src/core/aiterm; _aiterm_clean_file '$color_out' '${color_out}.clean' 'true'; cat '${color_out}.clean'" "Red text and Green text"

    # Verify should_bypass command classification
    test_assert "Bypasses git status" "source src/core/aiterm; _aiterm_should_bypass 'git status' && echo 'bypass' || echo 'run'" "bypass"
    test_assert "Runs npm install" "source src/core/aiterm; _aiterm_should_bypass 'npm install' && echo 'bypass' || echo 'run'" "run"
    
    echo ""
    
    # Sonuçları göster
    echo "📊 Test Results"
    echo "==============="
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "Passed: \e[32m$TESTS_PASSED\e[0m"
    echo -e "Failed: \e[31m$TESTS_FAILED\e[0m"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n🎉 \e[32mAll tests passed!\e[0m"
        echo "Smart Execute v2.0 is ready to use."
    else
        echo -e "\n⚠️  \e[33mSome tests failed.\e[0m"
        echo "Please check the issues above."
    fi
    
    # Test ortamını temizle
    rm -rf "$(pwd)/test_tmp"
    
    echo ""
    echo "Test completed."
    
    return $TESTS_FAILED
}

# Performance tests
run_performance_tests() {
    echo ""
    echo "⚡ Performance Tests"
    echo "==================="
    
    # OS uyumlu nanosaniye alma fonksiyonu
    _get_nanoseconds() {
        if [[ "$(uname)" == "Darwin" ]]; then # macOS
            if command -v python3 &>/dev/null; then
                python3 -c 'import time; print(time.time_ns())'
            else
                echo "$(date +%s)000000000" # Sadece saniye ile yetin
            fi
        else # Linux/GNU
            date +%s%N
        fi
    }

    # Liste yükleme performansı
    echo -n "List loading performance... "
    local start_time=$(_get_nanoseconds)
    _smart_load_lists >/dev/null 2>&1
    local end_time=$(_get_nanoseconds)
    local duration=$(( (end_time - start_time) / 1000000 ))
    echo "${duration}ms"
    
    # Kara liste kontrol performansı
    if [[ ${#BLACKLIST_PATTERNS[@]} -gt 0 ]]; then
        echo -n "Blacklist check performance... "
        local start_time=$(_get_nanoseconds)
        for i in {1..100}; do
            _is_blacklisted "ls -la" >/dev/null 2>&1
        done
        local end_time=$(_get_nanoseconds)
        local duration=$(( (end_time - start_time) / 1000000 ))
        echo "${duration}ms (100 checks)"
    fi
    
    echo "Performance tests completed."
}

# İnteraktif test modu
interactive_test() {
    echo "🎮 Interactive Test Mode"
    echo "========================"
    echo ""
    echo "Bu mod Smart Execute'un gerçek kullanım senaryolarını test eder."
    echo "Test komutları çalıştırılmayacak, sadece işleme süreçleri test edilecek."
    echo ""
    
    # Mock LLM response
    mock_llm_response='{"command": "ls -la"}'
    
    echo "Test scenarios:"
    echo "1. Whitelist command (should execute directly)"
    echo "2. Blacklist command (should be blocked)"
    echo "3. Normal command (should go through LLM)"
    echo "4. Explanation request"
    echo ""
    
    read -p "Devam etmek istiyor musunuz? [y/N]: " -r
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
    
    # Test senaryoları burada implement edilebilir
    echo "Interactive tests would run here..."
}

# Ana test runner
main() {
    case "${1:-full}" in
        "full")
            run_tests
            run_performance_tests
            ;;
        "basic")
            run_tests
            ;;
        "performance")
            run_performance_tests
            ;;
        "interactive")
            interactive_test
            ;;
        "help")
            echo "Smart Execute Test Suite"
            echo "Usage: $0 [full|basic|performance|interactive|help]"
            echo ""
            echo "  full         - Run all tests (default)"
            echo "  basic        - Run basic functionality tests only"
            echo "  performance  - Run performance tests only"
            echo "  interactive  - Run interactive test mode"
            echo "  help         - Show this help"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
}

# Script'i çalıştır
main "$@"
