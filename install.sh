#!/bin/bash
# Smart Execute v2.0 Hızlı Kurulum Scripti

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << 'EOF'
 ____                       _     _____                     _       
/ ___| _ __ ___   __ _ _ __| |_  | ____|_  _____  ___ _   _| |_ ___ 
\___ \| '_ ` _ \ / _` | '__| __| |  _| \ \/ / _ \/ __| | | | __/ _ \
 ___) | | | | | | (_| | |  | |_  | |___ >  <  __/ (__| |_| | ||  __/
|____/|_| |_| |_|\__,_|_|   \__| |_____/_/\_\___|\___|\__,_|\__\___|
                                                                    
                    v2.0 - Gelişmiş Sürüm                          
EOF
echo -e "${NC}"

echo -e "${YELLOW}⚠️  GÜVENLIK UYARISI:${NC}"
echo "Bu yazılım LLM kullanarak terminal komutları üretir."
echo "Potansiyel olarak tehlikeli olabilir. Kendi riskinizle kullanın."
echo ""
read -p "Devam etmek istiyor musunuz? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Kurulum iptal edildi."
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Smart Execute v2.0 Kurulumu Başlıyor...${NC}"
echo ""

# Shell kontrolü
if [[ -n "$ZSH_VERSION" ]]; then
    SHELL_TYPE="zsh"
    SHELL_RC="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" ]]; then
    SHELL_TYPE="bash"
    SHELL_RC="$HOME/.bashrc"
else
    echo -e "${YELLOW}⚠️  Desteklenmeyen shell. Zsh önerilir.${NC}"
    SHELL_TYPE="unknown"
    SHELL_RC="$HOME/.profile"
fi

echo -e "${GREEN}✓${NC} Shell tipi: $SHELL_TYPE"

# Gerekli araçları kontrol et
echo ""
echo "Gerekli araçlar kontrol ediliyor..."

missing_tools=()
for tool in curl jq; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    else
        echo -e "${GREEN}✓${NC} $tool mevcut"
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo -e "${RED}❌ Eksik araçlar: ${missing_tools[*]}${NC}"
    echo ""
    echo "Lütfen eksik araçları kurun:"
    
    if command -v apt &> /dev/null; then
        echo "sudo apt update && sudo apt install ${missing_tools[*]}"
    elif command -v dnf &> /dev/null; then
        echo "sudo dnf install ${missing_tools[*]}"
    elif command -v brew &> /dev/null; then
        echo "brew install ${missing_tools[*]}"
    else
        echo "Paket yöneticinizi kullanarak: ${missing_tools[*]}"
    fi
    
    echo ""
    read -p "Devam etmek istiyor musunuz? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Kurulum iptal edildi."
        exit 1
    fi
fi

# Dosyaları kopyala
echo ""
echo "Dosyalar kopyalanıyor..."

INSTALL_DIR="$HOME/.smart_execute"
mkdir -p "$INSTALL_DIR"

# Ana dosyaları kopyala
if [[ -f "smart_execute_v2.zsh" ]]; then
    cp smart_execute_v2.zsh "$INSTALL_DIR/"
    echo -e "${GREEN}✓${NC} Ana dosya kopyalandı"
else
    echo -e "${RED}❌ smart_execute_v2.zsh bulunamadı${NC}"
    exit 1
fi

# Modül dosyalarını kopyala
modules=(
    ".smart_execute_security.zsh"
    ".smart_execute_providers.zsh"
    ".smart_execute_cross_shell.zsh"
    ".smart_execute_wizard.zsh"
    ".smart_execute_security.conf"
    ".smart_execute_advanced_blacklist.txt"
)

for module in "${modules[@]}"; do
    if [[ -f "$module" ]]; then
        cp "$module" "$INSTALL_DIR/"
        echo -e "${GREEN}✓${NC} $module kopyalandı"
    fi
done

# Shell konfigürasyonunu güncelle
echo ""
echo "Shell konfigürasyonu güncelleniyor..."

SOURCE_LINE="source $INSTALL_DIR/smart_execute_v2.zsh"

if grep -q "smart_execute" "$SHELL_RC" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Smart Execute zaten $SHELL_RC dosyasında mevcut${NC}"
else
    echo "" >> "$SHELL_RC"
    echo "# Smart Execute v2.0" >> "$SHELL_RC"
    echo "$SOURCE_LINE" >> "$SHELL_RC"
    echo -e "${GREEN}✓${NC} $SHELL_RC güncellendi"
fi

# Yapılandırma dizinini oluştur
CONFIG_DIR="$HOME/.config/smart_execute"
mkdir -p "$CONFIG_DIR"
echo -e "${GREEN}✓${NC} Yapılandırma dizini oluşturuldu: $CONFIG_DIR"

# Kurulum tamamlandı
echo ""
echo -e "${GREEN}🎉 Kurulum tamamlandı!${NC}"
echo ""
echo "Sonraki adımlar:"
echo "1. Terminali yeniden başlatın veya şunu çalıştırın:"
echo "   ${BLUE}source $SHELL_RC${NC}"
echo ""
echo "2. Kurulum sihirbazını çalıştırın:"
echo "   ${BLUE}smart-execute setup${NC}"
echo ""
echo "3. Kullanım örnekleri:"
echo "   ${BLUE}@ masaüstündeki txt dosyalarını listele${NC}"
echo "   ${BLUE}@? ls -la${NC}"
echo "   ${BLUE}/ls${NC}"
echo ""

# Ollama kontrolü
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓${NC} Ollama mevcut - yerel LLM kullanılabilir"
else
    echo -e "${YELLOW}⚠️  Ollama bulunamadı${NC}"
    echo "Yerel LLM kullanmak için Ollama'yı kurun:"
    echo "https://ollama.ai/"
fi

echo ""
echo -e "${BLUE}📚 Dokümantasyon: README.md${NC}"
echo -e "${BLUE}🔧 Sorun giderme: smart-execute help${NC}"
echo ""
echo -e "${YELLOW}⚠️  Güvenlik hatırlatması: Komutları çalıştırmadan önce her zaman kontrol edin!${NC}"
