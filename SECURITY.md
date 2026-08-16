# AiTerm Güvenlik Politikası

AiTerm, sisteminizde doğrudan shell komutları çalıştıran bir yapay zeka asistanı olduğu için güvenlik en büyük önceliğimizdir.

## Çok Katmanlı Güvenlik Mimarisi

### 1. Komut Analizi ve Risk Skorlaması
AiTerm, kullanıcının girdiği istemleri ve LLM'den gelen komutları çalıştırmadan önce analiz eder.
- **Whitelist (Beyaz Liste):** Zararsız komutlar (`ls`, `echo`, `pwd`) doğrudan çalıştırılabilir.
- **Blacklist (Kara Liste):** Sistem için tehlikeli olan komutlar (`rm -rf /`, `dd`, `mkfs`) engellenir veya çok sıkı uyarı mekanizmalarına tabi tutulur.
- **Anomaly Detection:** Anormal veya olağandışı komut zincirleri, potansiyel tehlike olarak işaretlenir.

### 2. Akıllı LLM Yanıt Doğrulama (Foolproof JSON Parser)
LLM (Büyük Dil Modeli) çıktıları doğası gereği manipüle edilebilir veya hatalı olabilir (Halüsinasyon).
AiTerm v2.0 ile birlikte:
- LLM'den gelen JSON yanıtları, **Perl tabanlı gelişmiş bir Regex katmanından** geçirilir.
- Model, kötü niyetli komutları veya bozuk JSON dizilerini "thinking" (düşünme) bloklarının arasına saklamaya çalışsa veya token limiti nedeniyle yanıt yarım kalsa bile; sistem **hedef komutu güvenli bir şekilde ayrıştırır**.
- Bu sayede Terminal ekranına asla ham ve tehlikeli olabilecek ayrıştırılamamış çıktılar basılmaz.

### 3. Kullanıcı Onayı
AiTerm hiçbir komutu **kullanıcı onayı olmadan** otomatik çalıştırmaz.
- LLM'in önerdiği komutlar terminalinize sadece *yazılır*.
- Çalıştırmak (Enter) kullanıcının sorumluluğundadır.

## Güvenlik Zafiyeti Bildirimi
Eğer AiTerm'in güvenlik modelini aşan bir zafiyet bulursanız (örneğin kara listedeki bir komutun LLM manipülasyonu ile çalıştırılması) lütfen sorunu doğrudan GitHub "Issues" bölümünden **[SECURITY]** etiketi ile bildirin. Zafiyetler öncelikli olarak değerlendirilip yamalanacaktır.

## Desteklenen Sürümler

| Versiyon | Güvenlik Güncellemesi |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: (Aktif Geliştirme) |
| 1.0.x   | :x: (Desteklenmiyor) |
