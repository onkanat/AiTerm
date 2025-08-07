#!/bin/bash
# Smart Execute Cross-Shell Support
# Bu dosya farklı shell'ler için destek sağlar

# Shell tipini tespit et
detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    elif [[ -n "$FISH_VERSION" ]]; then
        echo "fish"
    else
        echo "unknown"
    fi
}

# Bash desteği
setup_bash_support() {
    if [[ -n "$BASH_VERSION" ]]; then
        # Bash için key binding
        bind -x '"\C-m": smart_accept_line_bash'
        
        # Bash uyumlu accept line fonksiyonu
        smart_accept_line_bash() {
            local original_command="$READLINE_LINE"
            
            # Ana logic'i çağır
            local result=$(smart_execute_logic "$original_command")
            
            if [[ -n "$result" ]]; then
                READLINE_LINE="$result"
            fi
        }
        
        echo "✓ Bash desteği etkinleştirildi"
    fi
}

# Fish shell desteği
setup_fish_support() {
    if [[ -n "$FISH_VERSION" ]]; then
        # Fish için yapılandırma dosyası oluştur
        local fish_config="$HOME/.config/fish/functions/smart_execute.fish"
        mkdir -p "$(dirname "$fish_config")"
        
        cat > "$fish_config" << 'EOF'
function smart_execute_fish
    set original_command (commandline)
    
    if test -n "$original_command"
        # Smart execute logic'ini çağır
        set result (smart_execute_logic "$original_command")
        
        if test -n "$result"
            commandline -r "$result"
            commandline -f execute
        end
    end
end

function fish_user_key_bindings
    bind \r smart_execute_fish
end
EOF
        
        echo "✓ Fish shell desteği eklendi: $fish_config"
    fi
}

# Universal smart execute logic
smart_execute_logic() {
    local original_command="$1"
    local shell_type=$(detect_shell)
    
    # Boş komut kontrolü
    [[ -z "$original_command" ]] && return 0
    
    # / ile başlayan komutlar için doğrudan çalıştırma
    if [[ "$original_command" == /* ]]; then
        echo "${original_command#/}"
        return 0
    fi
    
    # @ ile başlayan komutlar için LLM çağrısı
    if [[ "$original_command" == @* ]]; then
        local mode="command"
        local user_command="${original_command#@}"
        
        # @? için açıklama modu
        if [[ "$original_command" == @\?* ]]; then
            mode="explanation"
            user_command="${original_command#@?}"
            
            # Açıklama modunda sadece açıklamayı göster
            local explanation=$(call_llm_for_explanation "$user_command")
            echo "$explanation" >&2
            return 0
        fi
        
        # Komut modu için LLM çağrısı
        local suggested_command=$(call_llm_for_command "$user_command")
        
        if [[ -n "$suggested_command" && "$suggested_command" != "DANGER" ]]; then
            # Güvenlik kontrolü
            if ! is_command_safe "$suggested_command"; then
                echo "⚠️  Tehlikeli komut engellendi: $suggested_command" >&2
                return 1
            fi
            
            # Kullanıcı onayı (shell'e uygun)
            if confirm_command_execution "$suggested_command" "$shell_type"; then
                echo "$suggested_command"
                return 0
            fi
        fi
        
        return 1
    fi
    
    # Normal komutlar için güvenlik kontrolü
    if ! is_command_safe "$original_command"; then
        echo "⚠️  Tehlikeli komut engellendi: $original_command" >&2
        return 1
    fi
    
    # Beyaz liste kontrolü
    if is_whitelisted "$original_command"; then
        echo "$original_command"
        return 0
    fi
    
    # LLM'e gönder ve sonucu dön
    local suggested_command=$(call_llm_for_command "$original_command")
    
    if [[ -n "$suggested_command" && "$suggested_command" != "DANGER" ]]; then
        if confirm_command_execution "$suggested_command" "$shell_type"; then
            echo "$suggested_command"
            return 0
        fi
    fi
    
    # Hiçbir şey bulunamadıysa orijinal komutu dön
    echo "$original_command"
}

# Shell'e uygun onay fonksiyonu
confirm_command_execution() {
    local command="$1"
    local shell_type="$2"
    
    case "$shell_type" in
        "bash")
            echo -n "Komutu çalıştır? $command [y/N]: " >&2
            read -n 1 reply
            echo >&2
            [[ "$reply" =~ ^[Yy]$ ]]
            ;;
        "fish")
            echo "Komutu çalıştır? $command [y/N]: " >&2
            read reply
            test "$reply" = "y" -o "$reply" = "Y"
            ;;
        "zsh"|*)
            echo -n "Komutu çalıştır? $command [y/N]: " >&2
            read -k1 reply
            echo >&2
            [[ "$reply" =~ ^[Yy]$ ]]
            ;;
    esac
}

# Basitleştirilmiş güvenlik kontrolü
is_command_safe() {
    local command="$1"
    
    # Temel tehlikeli kalıplar
    [[ "$command" =~ rm.*-rf.*/ ]] && return 1
    [[ "$command" =~ sudo.*rm ]] && return 1
    [[ "$command" =~ dd.*of=/dev ]] && return 1
    [[ "$command" =~ chmod.*777.*/ ]] && return 1
    [[ "$command" =~ shutdown|reboot|halt ]] && return 1
    
    return 0
}

# Basitleştirilmiş beyaz liste
is_whitelisted() {
    local command="$1"
    
    case "$command" in
        "ls"|"pwd"|"cd"|"cd ~"|"cd ..")
            return 0
            ;;
        "git status"|"git diff"|"git log")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Basitleştirilmiş LLM çağrısı
call_llm_for_command() {
    local user_input="$1"
    
    # Burada gerçek LLM çağrısı yapılacak
    # Şimdilik basit bir dönüşüm
    case "$user_input" in
        *"list files"*|*"dosyaları listele"*)
            echo "ls -la"
            ;;
        *"show directory"*|*"dizini göster"*)
            echo "pwd"
            ;;
        *"git commit"*|*"git kaydet"*)
            echo "git add . && git commit -m 'Update'"
            ;;
        *)
            echo "$user_input"
            ;;
    esac
}

call_llm_for_explanation() {
    local command="$1"
    echo "Bu komut hakkında açıklama: $command"
}

# Ana kurulum fonksiyonu
setup_cross_shell_support() {
    local current_shell=$(detect_shell)
    
    echo "Mevcut shell: $current_shell"
    
    case "$current_shell" in
        "bash")
            setup_bash_support
            ;;
        "fish")
            setup_fish_support
            ;;
        "zsh")
            echo "✓ Zsh desteği varsayılan olarak mevcuttur"
            ;;
        *)
            echo "⚠️  Bilinmeyen shell tipi: $current_shell"
            echo "Yalnızca temel fonksiyonlar çalışabilir"
            ;;
    esac
}
