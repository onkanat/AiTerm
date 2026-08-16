import json

system_prompt = "Sen bir uzman Linux/macOS terminal asistanısın. SADECE tek satırda geçerli JSON döndür, başka hiçbir metin ekleme."

data = []

# --- 1. Temel Dosya İşlemleri (20) ---
basic_file_commands = [
    ("tüm pdf dosyalarını bul", "find . -name '*.pdf'"),
    ("boş dosyaları sil", "find . -type f -empty -delete"),
    ("yeni bir klasör oluştur adı test", "mkdir test"),
    ("test klasörüne gir", "cd test"),
    ("ana dizine dön", "cd ~"),
    ("tüm txt dosyalarını listele", "ls -l *.txt"),
    ("deneme.txt dosyasının içeriğini göster", "cat deneme.txt"),
    ("klasördeki dosyaları boyuta göre sırala", "ls -lS"),
    ("gizli dosyaları göster", "ls -la"),
    ("bir üst klasöre çık", "cd .."),
    ("su anki dizini kopyala", "pwd | pbcopy"),
    ("dosya.txt dosyasını sil", "rm dosya.txt"),
    ("klasörü içindekilerle birlikte sil", "rm -rf klasor_adi"),
    ("dosyayı kopyala", "cp kaynak.txt hedef.txt"),
    ("klasörü kopyala", "cp -r kaynak_klasor hedef_klasor"),
    ("dosyanın adını değiştir", "mv eski_ad.txt yeni_ad.txt"),
    ("dosyayı taşı", "mv dosya.txt /hedef/klasor/"),
    ("dosyanın son 10 satırını göster", "tail -n 10 dosya.txt"),
    ("dosyanın ilk 10 satırını göster", "head -n 10 dosya.txt"),
    ("yeni bir boş dosya oluştur", "touch yeni_dosya.txt")
]

for req, cmd in basic_file_commands:
    data.append([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": req},
        {"role": "assistant", "content": json.dumps({"command": cmd}, ensure_ascii=False)}
    ])

# --- 2. Ağ ve Sistem (20) ---
sys_commands = [
    ("ip adresimi göster", "curl ifconfig.me"),
    ("yerel ip adresim nedir", "ipconfig getifaddr en0"),
    ("açık portları listele", "lsof -i -P -n | grep LISTEN"),
    ("sistem çalışma süresi", "uptime"),
    ("boş disk alanını göster", "df -h"),
    ("bellek kullanımını göster", "top -l 1 | head -n 10"),
    ("en çok cpu kullanan 5 işlem", "ps aux | sort -nrk 3,3 | head -n 5"),
    ("8080 portunu kullanan işlemi bul", "lsof -i :8080"),
    ("ping at google.com", "ping -c 4 google.com"),
    ("dns önbelleğini temizle (mac)", "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"),
    ("kullanıcıları listele", "dscl . list /Users | grep -v '^_'"),
    ("ağ arayüzlerini göster", "ifconfig"),
    ("route tablosunu göster", "netstat -nr"),
    ("mac adresini öğren", "ifconfig en0 | grep ether"),
    ("sistem bilgilerini göster", "system_profiler SPSoftwareDataType"),
    ("aktif ssh bağlantılarını göster", "who"),
    ("kapat komutu", "sudo shutdown -h now"),
    ("yeniden başlat", "sudo shutdown -r now"),
    ("tarihi göster", "date"),
    ("takvimi göster", "cal")
]

for req, cmd in sys_commands:
    data.append([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": req},
        {"role": "assistant", "content": json.dumps({"command": cmd}, ensure_ascii=False)}
    ])

# --- 3. Açıklama (Explanation) Modu (20) ---
explanation_data = [
    ("ls -la komutu ne işe yarar?", "Bulunduğunuz dizindeki tüm dosyaları (gizli dosyalar dahil) detaylı bir liste halinde gösterir."),
    ("chmod +x script.sh nedir?", "script.sh dosyasına çalıştırma (execute) izni verir."),
    ("tar -czvf arsiv.tar.gz klasor/", "klasor/ adlı dizini sıkıştırarak arsiv.tar.gz adlı bir arşiv dosyası oluşturur."),
    ("grep -r 'hata' /var/log", "/var/log dizininde ve alt dizinlerindeki tüm dosyalarda 'hata' kelimesini arar."),
    ("kill -9 1234", "PID (İşlem Kimliği) 1234 olan işlemi zorla (SIGKILL) sonlandırır."),
    ("df -h", "Sistemdeki disk bölümlerinin toplam, kullanılan ve boş alanlarını okunabilir (insan dostu) formatta gösterir."),
    ("chown root:admin dosya.txt", "dosya.txt dosyasının sahibini 'root', grubunu ise 'admin' olarak değiştirir."),
    ("ln -s kaynak.txt hedef_link", "kaynak.txt dosyası için hedef_link adında sembolik bir bağlantı (kısayol) oluşturur."),
    ("find . -mtime -7", "Son 7 gün içinde değiştirilmiş olan dosyaları bulur."),
    ("awk '{print $1}' dosya.txt", "dosya.txt içindeki her satırın ilk sütununu (boşluklarla ayrılmış) ekrana yazdırır."),
    ("sed -i '' 's/eski/yeni/g' dosya.txt", "dosya.txt içerisindeki tüm 'eski' kelimelerini 'yeni' ile değiştirir (macOS formatında)."),
    ("history | grep curl", "Daha önce yazdığınız komut geçmişinde 'curl' kelimesini arar."),
    ("du -sh *", "Bulunduğunuz dizindeki her bir dosya ve klasörün toplam boyutunu özet (insan dostu) olarak gösterir."),
    ("ps aux", "Sistemde çalışan tüm işlemleri (process) kullanıcı, CPU, RAM kullanımı gibi detaylarıyla listeler."),
    ("top", "Sistem kaynaklarının kullanımını ve çalışan işlemleri gerçek zamanlı olarak gösterir."),
    ("wget http://ornek.com/dosya.zip", "Belirtilen URL'den dosya.zip dosyasını indirir."),
    ("curl -O http://ornek.com/dosya.zip", "Belirtilen URL'deki dosyayı aynı isimle yerel diske kaydeder."),
    ("chmod 755 dosya.sh", "Dosya sahibine okuma/yazma/çalıştırma, diğer kullanıcılara ise okuma ve çalıştırma izni verir."),
    ("tail -f /var/log/system.log", "system.log dosyasının sonunu gösterir ve dosyaya yeni satırlar eklendikçe canlı olarak ekrana basar."),
    ("mkdir -p klasor1/klasor2", "İç içe klasör1 ve klasor2'yi tek seferde oluşturur, eğer klasör1 zaten varsa hata vermez.")
]

for req, exp in explanation_data:
    data.append([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": req},
        {"role": "assistant", "content": json.dumps({"explanation": exp}, ensure_ascii=False)}
    ])

# --- 4. Geliştirici ve Git Komutları (20) ---
dev_commands = [
    ("yeni git deposu başlat", "git init"),
    ("tüm dosyaları git e ekle", "git add ."),
    ("commit at mesaj ilk commit", "git commit -m 'ilk commit'"),
    ("git statüsünü göster", "git status"),
    ("uzak sunucuya gönder", "git push origin main"),
    ("yeni dal oluştur ve geçiş yap", "git checkout -b yeni_dal"),
    ("logları tek satırda göster", "git log --oneline"),
    ("son commit'i geri al (dosyalar kalsın)", "git reset HEAD~1"),
    ("değişiklikleri zulala (stash)", "git stash"),
    ("zulalanmış değişiklikleri geri al", "git stash pop"),
    ("npm projesi başlat", "npm init -y"),
    ("react paketi kur", "npm install react"),
    ("python sanal ortam oluştur", "python3 -m venv .venv"),
    ("sanal ortamı aktif et", "source .venv/bin/activate"),
    ("gereksinimleri yükle", "pip install -r requirements.txt"),
    ("docker containerları listele", "docker ps"),
    ("tüm docker imajlarını göster", "docker images"),
    ("docker compose ile ayağa kaldır", "docker-compose up -d"),
    ("şu anki dizini vscode ile aç", "code ."),
    ("vim ile dosyayı düzenle", "vim dosya.txt")
]

for req, cmd in dev_commands:
    data.append([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": req},
        {"role": "assistant", "content": json.dumps({"command": cmd}, ensure_ascii=False)}
    ])

# --- 5. İleri Düzey Terminal Komutları (20) ---
adv_commands = [
    ("klasördeki tüm mp4 dosyalarını gif e çevir", "for i in *.mp4; do ffmpeg -i \"$i\" -vf scale=320:-1 \"${i%.mp4}.gif\"; done"),
    ("log dosyasındaki ip adreslerini sayıp en çoktan aza doğru sırala", "awk '{print $1}' access.log | sort | uniq -c | sort -nr"),
    ("içinde password kelimesi geçen tüm dosyaları bul", "grep -rnw '/yol/' -e 'password'"),
    ("boyutu 50mb dan büyük dosyaları bul", "find . -type f -size +50M"),
    ("son 30 dakikada değiştirilmiş dosyaları tarayıp yedekle", "find . -type f -mmin -30 -exec cp {} /yedek/klasoru/ \\;"),
    ("açık portları dinleyen processleri PID ile birlikte göster", "lsof -i -P -n | grep LISTEN"),
    ("tüm docker containerları durdur ve sil", "docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)"),
    ("dizin içindeki boş dizinleri sil", "find . -type d -empty -delete"),
    ("iki dizini birbiriyle senkronize et", "rsync -avz /kaynak/ /hedef/"),
    ("belleği en çok kullanan 10 işlemi listele", "ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 11"),
    ("belirli bir aralıktaki portların açık olup olmadığını kontrol et", "nc -zv 127.0.0.1 8000-8080"),
    ("bir dosyanın boyutunu sıfırla (içeriğini sil)", "> dosya.txt"),
    ("bir metin dosyasının satırlarını rastgele karıştır", "sort -R dosya.txt"),
    ("bir dizindeki dosyaların md5 özetlerini oluştur", "find . -type f -exec md5 {} +"),
    ("bir ssl sertifikasının bitiş tarihini kontrol et", "echo | openssl s_client -servername ornek.com -connect ornek.com:443 2>/dev/null | openssl x509 -noout -dates"),
    ("dosya adlarındaki boşlukları alt çizgi ile değiştir", "rename 's/ /_/g' *"),
    ("bash geçmişini kalıcı olarak sil", "history -c && rm ~/.bash_history"),
    ("ssh anahtarı oluştur", "ssh-keygen -t ed25519 -C \"email@ornek.com\""),
    ("bir web sitesinin başlık (header) bilgilerini getir", "curl -I https://ornek.com"),
    ("mysql veritabanını dışa aktar", "mysqldump -u kullanici -p veritabani_adi > yedek.sql")
]

for req, cmd in adv_commands:
    data.append([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": req},
        {"role": "assistant", "content": json.dumps({"command": cmd}, ensure_ascii=False)}
    ])

# Yazdır
with open("data/smart_use_data.jsonl", "w", encoding="utf-8") as f:
    for item in data:
        f.write(json.dumps({"messages": item}, ensure_ascii=False) + "\n")

print(f"Toplam {len(data)} örnek oluşturuldu.")
