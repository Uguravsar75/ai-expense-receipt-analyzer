from model import ExpenseClassifier
import os, joblib

data = {
    "Market": [
        # Mağaza isimleri
        "Migros alisverisi", "Migros sepeti", "Migros market", "MIGROS",
        "A101 market", "A101 alisveris", "A101 gida", "A101",
        "BIM market", "BIM alisveris", "BIM gida market", "BIM MARKET",
        "Sok market", "Sok alisveris", "SOK MARKET",
        "CarrefourSA market", "CarrefourSA alisveris", "CARREFOUR",
        "Hakmar market", "File market", "Makro market",
        "Metro market", "Kiler market", "Onur market",
        "Nazar market", "Ozdilek market", "Migros sanal market",
        # Ürünler
        "ekmek aldim", "ekmek firini", "sut yogurt peynir",
        "meyve sebze aldim", "manav alisverisi", "manav meyve",
        "kasap et aldim", "kasap tavuk", "et market",
        "balik aldim", "balikci", "deniz urunleri",
        "bakkal alisveris", "mahalle bakkal",
        "kuruyemis badem findik", "kuruyemis market",
        "organik market", "organik urunler",
        "makarna pirinc bakliyat", "yag seker un",
        "deterjan sabun temizlik urunleri",
        "sampuan dis macunu kisisel bakim",
        "bebek bezi bebek mamasi",
        "su bidonu su market", "maden suyu gazli icecek",
        "dondurulmus gida", "hazir yemek market",
        "market haftalik alisveris", "supermarket harcamasi",
        "Getir market", "Yemeksepeti market", "Trendyol market",
        "haftalik pazar alisverisi", "Carrefour haftalik alisveris",
        # OCR fiş formatları
        "TOPLAM MIGROS", "TOPLAM ODEME MIGROS",
        "TOPLAM TUTAR A101", "FATURA TUTARI BIM",
        "MARKET ALISVERIS TUTARI", "SUPERMARKET TOPLAM",
        "GIDA ALISVERIS TOPLAM", "KASADA ODEME MARKET",
        "POS BELGESI MARKET", "ODEME BILGISI MARKET",
        "KDV DAHIL MARKET GIDA", "FATURA NO MIGROS",
        "MARKET SEPETI ODEME", "ONLINE MARKET SIPARIS",
        "TOPLAM TUTAR 1 EKMEK 2 SUT",
        "URUN ADI FIYAT TUTAR MARKET",
        "MARKET MAKBUZU ALISVERIS",
        "GIDA MARKET ODEME BELGESI",
    ],

    "Yeme ve Icme": [
        # Fast food
        "Burger King hamburger", "Burger King menu", "BURGER KING",
        "McDonalds siparis", "McDonalds burger", "MCDONALDS",
        "KFC tavuk", "KFC siparis", "KFC",
        "Popeyes tavuk burger", "pizza siparisi",
        "Dominos pizza", "Pizza Hut siparis", "DOMINOS PIZZA",
        "Subway sandvic", "SUBWAY",
        # Kahve zincirleri
        "Starbucks kahve", "Starbucks latte", "STARBUCKS",
        "Kahve Dunyasi", "KAHVE DUNYASI",
        "Gloria Jeans kahve", "GLORIA JEANS",
        "Nero kahve", "Costa Coffee",
        "kafe kahve", "kahvalti kafe", "cafe latte kapucino",
        "cay kahve ictim", "cay ocagi", "cay bahcesi",
        # Restoran
        "restoran aksam yemegi", "restoran ogle yemegi",
        "lokanta yemek", "kebap salonu", "kebap durum",
        "lahmacun pide", "doner dukkan", "doner kebap",
        "pide firini", "balik restoran", "sushi restoran",
        "cigkoftedurum", "dondurma aldim", "simit pogaca",
        "Simit Sarayi", "borekci borek",
        # Sipariş uygulamaları
        "Yemeksepeti siparis", "Yemeksepeti pizza", "YEMEKSEPETI",
        "Getir yemek", "Getir siparis", "GETIR YEMEK",
        "Trendyol Yemek siparis", "TRENDYOL YEMEK",
        "yemek siparis uygulamasi", "online yemek siparis",
        # OCR fiş formatları
        "TOPLAM STARBUCKS", "TOPLAM BURGER KING",
        "RESTORAN FATURA TUTARI", "LOKANTA ODEME",
        "CAFE FATURA TOPLAM", "YEMEK FATURASI TOPLAM",
        "POS FISI RESTORAN", "ODEME RESTORAN",
        "RESTORAN SIPARIS TUTARI", "YEMEK SIPARIS ODEME",
        "KDV DAHIL RESTORAN", "FATURA NO CAFE",
        "TOPLAM TUTAR YEMEK", "FAST FOOD ODEME",
        "KAHVE SIPARIS TOPLAM", "MAKBUZ LOKANTA",
        "HAMBURGER MENU TUTAR", "PIZZA SIPARIS TOPLAM",
    ],

    "Faturalar": [
        # Elektrik
        "elektrik faturasi", "BEDAS elektrik", "elektrik odeme",
        "elektrik abonelik", "CK Bogazici elektrik",
        "AYDAS elektrik", "Toroslar elektrik", "EDAS elektrik",
        # Su
        "su faturasi", "ISKI su fatura", "ASKI su",
        "SASKI su fatura", "su odeme", "su aboneligi",
        # Doğalgaz
        "dogal gaz faturasi", "IGDAS gaz fatura",
        "BASKENTGAZ fatura", "GAZDAS fatura", "gaz odeme",
        # İnternet
        "internet faturasi", "TURKNET internet",
        "Turk Telekom internet", "Superonline internet",
        "Vodafone net internet", "Turkcell internet ev",
        "fiber internet fatura", "ADSL fatura",
        # Telefon
        "telefon faturasi", "cep telefonu fatura",
        "Turkcell fatura", "Vodafone fatura",
        "Turk Telekom hat fatura", "GSM fatura",
        # Dijital abonelikler
        "Netflix abonelik", "Spotify premium", "YouTube Premium",
        "Amazon Prime", "Disney Plus abonelik", "BluTV abonelik",
        "TOD abonelik", "Exxen abonelik", "Apple TV abonelik",
        "iCloud depolama", "Google One depolama",
        "Microsoft 365", "Adobe abonelik", "antivirus abonelik",
        "abonelik ucreti aylik", "streaming platform aylik",
        # OCR fiş formatları
        "ELEKTRIK FATURASI TOPLAM", "SU FATURASI ODEME",
        "DOGALGAZ FATURASI TUTAR", "INTERNET FATURA TOPLAM",
        "TELEFON FATURASI ODEME", "FATURA BEDELI TOPLAM",
        "ABONELIK UCRETI ODEME", "FATURA TUTARI",
        "ODEME BILGISI FATURA", "BORC TUTARI FATURA",
        "FATURA NO ELEKTRIK", "SON ODEME TARIHI FATURA",
        "TURKCELL FATURA ODEME", "VODAFONE FATURA",
        "INTERNET ABONELIK FATURA", "NETFLIX AYLIK",
        "SPOTIFY PREMIUM ODEME", "GOOGLE ONE ODEME",
    ],

    "Ulasim": [
        # Toplu taşıma
        "otobus bileti", "otobus karti doldurma",
        "metro bileti", "metro kart yukleme",
        "metrobus", "tramvay bileti",
        "Istanbulkart yukleme", "akbil yukleme",
        "Ankarakart yukleme", "EGO otobus",
        "Izmirim kart", "ESHOT otobus",
        "dolmus ucreti", "vapur bileti",
        "IDO vapur", "sehir hatlari",
        # Taksi/Rideshare
        "taksi ucreti", "taksi yolculuk",
        "Uber yolculuk", "Uber uygulama", "UBER",
        "BiTaksi", "iTaksi", "Bolt taksi", "FreeNow taksi",
        # Araç
        "arac kiralama", "rent a car", "Sixt arac kiralama",
        "benzin akaryakit", "Shell benzin", "BP akaryakit",
        "Opet benzin", "Total benzin", "Petrol Ofisi",
        "motorin dizel", "LPG gaz yakit", "yakit masrafi",
        "otopark ucreti", "park yeri ucreti",
        "HGS OGS", "otoyol gecis", "bogaz koprusu",
        "arac muayene", "lastik degisim", "arac yikama",
        "arac bakim servis", "motor yag degisim", "arac tamiri",
        # Seyahat
        "tren bileti", "TCDD bilet",
        "ucak bileti", "THY bilet", "Pegasus bilet",
        "SunExpress bilet", "otobus sehirlerarasi",
        "Marti scooter", "e-scooter kiralama",
        # OCR fiş formatları
        "TOPLAM SHELL AKARYAKIT", "BENZIN ODEME TUTARI",
        "AKARYAKIT FISI TOPLAM", "YAKIT MAKBUZU TUTAR",
        "OTOPARK MAKBUZU TOPLAM", "PARK UCRETI ODEME",
        "TAKSI UCRETI TOPLAM", "UBER YOLCULUK ODEME",
        "UCAK BILETI TUTARI", "TREN BILETI ODEME",
        "HGS GECIS UCRETI", "KOPRU GECIS ODEME",
        "SERVIS UCRETI ULASIM", "KART YUKLEME TOPLAM",
        "METRO KART BAKIYE", "OTOBUS KARTI YUKLEME",
        "AKARYAKIT ISTASYON TOPLAM", "BP PETROL ODEME",
        "SHELL BENZIN TOPLAM", "OPET AKARYAKIT",
    ],

    "Kira ve Ev": [
        # Kira
        "kira odemesi", "ev kirasi", "konut kirasi aylik",
        "ofis kirasi", "daire kira", "apart kira",
        "site aidati", "apartman aidati", "yonetici ucreti",
        # Tadilat
        "ev tamirati", "boya badana", "boyaci ustasi",
        "elektrikci tamiri", "tesisatci su tamiri",
        "cam degisimi", "kapi tamiri", "tadilat masrafi",
        # Mobilya/Eşya
        "mobilya aldim", "koltuk kanepe", "yatak baza",
        "gardirop dolap", "masa sandalye",
        "buzdolabi satin alma", "camasir makinesi",
        "bulasik makinesi", "firin ocak",
        "klima satin alma", "klima montaj",
        "IKEA alisveris", "IKEA MOBILYA",
        "Kelebek mobilya", "Bellona mobilya", "Istikbal mobilya",
        "ev dekorasyon", "perde tul aldim",
        "hali kilim aldim", "aydinlatma lamba",
        # Sigorta/Diğer
        "ev sigortasi", "konut sigortasi", "DASK deprem sigortasi",
        "temizlik hizmeti", "ev temizlikci",
        "hasere ilaclama", "bocek ilaclama",
        "kombi bakimi", "petek temizlik",
        "kira kontrat yenileme", "depozito ev kirasi",
        # OCR fiş formatları
        "KIRA ODEME MAKBUZU", "EV KIRASI TOPLAM",
        "AIDAT ODEME TUTARI", "SITE AIDATI MAKBUZ",
        "IKEA ALISVERIS TOPLAM", "MOBILYA SATIN ALMA",
        "TADILAT MASRAFI TOPLAM", "EV TAMIRI ODEME",
        "KIRALAMA SOZLESMESI ODEME", "KIRA BEDELI",
        "APARTMAN AIDATI ODEME", "YONETICI UCRETI",
        "KONUT SIGORTASI ODEME", "DASK ODEME",
        "KOMBI BAKIM UCRETI", "TEMIZLIK HIZMET",
        "BEYAZ ESYA SATIN ALMA", "EV ESYASI TOPLAM",
    ],

    "Saglik": [
        # İlaç/Eczane
        "eczane ilac", "ilac recete", "antibiyotik ilac",
        "agri kesici ilac", "vitamin takviye", "vitamin D omega 3",
        "eczaneden krem losyon", "eczane bandaj",
        "receteli ilac eczane", "ECZANE",
        # Doktor
        "doktor muayene", "aile hekimi",
        "uzman doktor muayene", "ozel muayene",
        "dahiliye muayene", "KBB kulak burun bogaz",
        "ortopedi doktor muayene", "dermatoloji cilt",
        "psikolog terapist", "psikiyatrist muayene",
        "fizyoterapist seans", "fizik tedavi",
        # Diş
        "dis hekimi", "dis tedavisi", "dis dolgusu",
        "ortodonti", "dis klinigi odeme",
        # Göz
        "goz hekimi", "goz muayene", "gozluk aldim",
        "lens aldim", "optik gozlukcu",
        # Hastane
        "ozel hastane", "hastane tedavi",
        "acil servis", "radyoloji MR cekim",
        "kan tahlili analiz", "laboratuvar tahlil",
        "saglik sigortasi", "ozel saglik sigortasi",
        "saglik kontrolu check-up", "asi yaptirdim",
        # Spor/Fitness (sağlık amaçlı)
        "spor salonu uyelik", "gym uyelik", "fitness center",
        "yuzme havuzu uyelik", "pilates ders",
        "yoga ders", "spor salonu aylik abonelik",
        "fitness abonelik", "egzersiz merkezi",
        # OCR fiş formatları
        "ECZANE FATURASI TOPLAM", "ILAC BEDELI ODEME",
        "RECETE UCRETI TOPLAM", "ECZANE MAKBUZU",
        "DOKTOR MUAYENE UCRETI", "HASTANE FATURASI",
        "KLINIK ODEME TUTARI", "SAGLIK HIZMET BEDELI",
        "TAHLIL UCRETI TOPLAM", "LAB ANALIZ ODEME",
        "GYM UYELIK UCRETI", "SPOR MERKEZI ODEME",
        "FITNESS SALON UYELIK", "HAVUZ UYELIK ODEME",
        "PILATES DERS UCRETI", "YOGA MERKEZI ODEME",
        "SAGLIK SIGORTASI PRIM", "CHECK-UP UCRETI",
    ],

    "Eglence": [
        # Sinema/Tiyatro
        "sinema bileti", "Cinemaximum sinema", "CGV sinema",
        "tiyatro bileti", "opera bale", "muzikal gosteri",
        # Konser/Etkinlik
        "konser bileti", "muzik festivali", "rock konseri",
        "biletix konser", "stand-up gosteri",
        "etkinlik bilet", "festival bilet",
        # Spor etkinlikleri
        "futbol maci bileti", "tribun bileti",
        "spor maci seyirci",
        # Eğlence mekanları
        "bowling oynadim", "bowling salonu",
        "tema parki giris", "lunapark", "aquapark",
        "kacis odasi escape room", "lazer tag paintball",
        "go-kart surusu", "zipline macera parki",
        "tekne turu gezi",
        # Müze/Kültür
        "muze giris ucreti", "sergi ziyaret",
        "sanat galerisi", "tarihi yer giris",
        # Oyun/Dijital
        "video oyun satin alma", "Steam oyun",
        "PlayStation Store", "Xbox Game Pass",
        "mobil oyun ici satin alma", "gaming abonelik",
        # Kitap/Hobi
        "kitap satin alma", "roman aldim",
        "DR kitap", "Kitapyurdu",
        "hobi malzeme", "boyama seti", "puzzle aldim",
        "masa oyunu", "satranc takimi",
        # Evcil hayvan
        "veteriner muayene evcil",
        "evcil hayvan malzeme",
        # OCR fiş formatları
        "SINEMA BILETI TOPLAM", "TIYATRO BILETI ODEME",
        "KONSER BILET TUTARI", "ETKINLIK GIRIS UCRETI",
        "MUZE GIRIS TOPLAM", "BOWLING SALON ODEME",
        "AQUAPARK GIRIS UCRETI", "TEMA PARK ODEME",
        "OYUN SATIN ALMA TOPLAM", "STEAM ODEME",
        "BILETIX KONSER ODEME", "FESTIVAL BILET",
        "GO-KART UCRETI", "LAZER TAG ODEME",
        "KITAP SATIN ALMA TOPLAM", "KITAPYURDU ODEME",
    ],

    "Giyim": [
        # Mağaza isimleri
        "LC Waikiki giysi", "LC WAIKIKI", "LCW alisveris",
        "HM alisveris", "HM giysi", "H&M",
        "Zara elbise", "Zara giyim", "ZARA",
        "Bershka kiyafet", "PullBear giysi",
        "Mango giyim", "Reserved giysi",
        "Koton giysi", "DeFacto giysi", "DEFACTO",
        "Trendyol giysi", "Trendyol kiyafet", "TRENDYOL GIYIM",
        "Hepsiburada giysi", "Modanisa giyim",
        "Mavi Jeans", "Lee pantolon", "Levi's jean",
        "Nike ayakkabi", "Adidas sneaker", "NIKE",
        "Derimod ayakkabi", "Hotic ayakkabi",
        "Sephora alisveris", "Gratis kozmetik", "Watsons kozmetik",
        # Kıyafet türleri
        "pantolon aldim", "jean pantolon",
        "elbise aldim", "etek aldim",
        "gomlek aldim", "tisort aldim",
        "kazak sweatshirt aldim", "mont kaban aldim",
        "sort aldim", "tayt aldim", "spor kiyafet aldim",
        "ic camasir aldim", "corap aldim",
        "ayakkabi aldim", "spor ayakkabi",
        "bot cizme aldim", "sandalet aldim",
        "canta aldim", "el cantasi", "sirt cantasi aldim",
        "saat aldim", "akilli saat", "Apple Watch",
        "taki bileklik", "kolye kupe",
        "gunes gozlugu", "sapka bere", "atki eldiven",
        "parfum aldim", "kozmetik makyaj", "ruj fondoten",
        "cocuk giyim", "bebek kiyafet", "kuru temizleme",
        # OCR fiş formatları
        "LC WAIKIKI ALISVERIS TOPLAM", "ZARA ODEME",
        "HM GIYIM TUTARI", "DEFACTO SIPARIS TOPLAM",
        "TRENDYOL GIYIM ODEME", "AYAKKABI ALISVERIS",
        "KIYAFET SATIN ALMA TOPLAM", "GIYIM TUTARI",
        "KOZMETIK ALISVERIS TOPLAM", "SEPHORA ODEME",
        "GRATIS KOZMETIK TUTARI", "PARFUM SATIN ALMA",
        "AKSESUAR ALISVERIS TOPLAM", "CANTA AYAKKABI ODEME",
        "ONLINE GIYIM SIPARIS TUTARI", "TEKSTIL ALISVERIS",
        "MAVI JEANS ODEME", "ADIDAS SATIN ALMA",
        "NIKE AYAKKABI TUTARI", "SPOR GIYIM ODEME",
    ],

    "Egitim": [
        # Okul/Üniversite
        "universite harc ucreti", "okul kayit ucreti",
        "okul servis ucreti", "universite yurt ucreti",
        # Kurs/Dershane
        "kurs odeme", "dershane aylik",
        "TYT AYT kursu", "YKS hazirlik",
        "ozel ders ucreti", "matematik ozel ders",
        "Ingilizce ozel ders",
        # Online kurslar
        "online kurs satin alma", "Udemy kurs", "UDEMY",
        "Coursera kurs", "LinkedIn Learning abonelik",
        "Babbel dil ogrenme", "Duolingo premium",
        "dil kursu Ingilizce", "IELTS TOEFL hazirlik",
        "yabanci dil okulu",
        # Sınav
        "sertifika sinav ucreti", "OSYM sinav ucreti",
        "YDS dil sinavi", "surucu kursu",
        "ehliyet sinav ucreti",
        # Sanatsal kurslar
        "muzik kursu enstuman", "gitar piyano dersi",
        "resim atolyesi ders", "dans kursu",
        "fotografcilik kursu",
        # Kırtasiye
        "kirtasiye alisveris", "defter kalem aldim",
        "okul defteri kalem silgi",
        "ders kitabi aldim", "roman akademik kitap",
        "yazici kagidi toner", "hesap makinesi aldim",
        "tablet okul icin", "bilgisayar laptop okul",
        # Mesleki kurslar
        "programlama kursu Python", "veri bilimi kurs",
        "dijital pazarlama kursu", "muhasebe kursu",
        "KPSS hazirlik kursu",
        # OCR fiş formatları
        "KURS UCRETI TOPLAM", "DERSHANE AIDAT ODEME",
        "OZEL DERS UCRETI TOPLAM", "EGITIM BEDELI ODEME",
        "UDEMY KURS SATIN ALMA", "ONLINE EGITIM TUTARI",
        "UNIVERSITE HARC ODEME", "OKUL KAYIT TUTARI",
        "SINAV UCRETI ODEME", "SERTIFIKA PROGRAM BEDELI",
        "KIRTASIYE ALISVERIS TOPLAM", "KITAP SATIN ALMA",
        "EGITIM MATERYALI ODEME", "DERS KITABI TUTARI",
        "MUZIK DERS UCRETI", "DANS KURSU ODEME",
        "DİL KURSU UCRETI", "INGILIZCE DERS ODEME",
    ],

    "Diger": [
        # Finans
        "banka komisyon ucreti", "havale EFT ucreti",
        "kredi karti aidati", "kredi odeme taksit",
        "ATM cekim komisyon", "nakit cekim ATM",
        "doviz bozdurma", "altin gumus satin alma",
        # Sigorta
        "hayat sigortasi", "arac sigortasi kasko",
        "zorunlu trafik sigortasi", "seyahat sigortasi",
        "sigorta primi odeme",
        # Resmi işlemler
        "noter masrafi", "tapu sicil harci",
        "vergi odeme", "belediye vergisi",
        "trafik cezasi", "pasaport harc",
        "nufus mudurlugu", "e-devlet ucret",
        # Kargo
        "kargo ucreti", "Yurtici kargo",
        "MNG kargo", "Aras kargo",
        "PTT kargo posta", "koli paket gonderme",
        # Hediye
        "hediye satin alma", "dogum gunu hediyesi",
        "dugun hediyesi", "cicek gonderme",
        "gift card hediye karti",
        # Elektronik servis
        "bilgisayar tamiri", "telefon ekran tamiri",
        "elektronik servis", "yazici murekkep kartus",
        # Yatırım
        "hisse senedi alim", "kripto para",
        "bagis yardim kurum", "BES odeme emeklilik",
        # Genel
        "cesitli harcama", "diger gider",
        "nakit odeme cesitli", "genel gider odeme",
        # OCR fiş formatları
        "KARGO UCRETI TOPLAM", "PTT POSTA ODEME",
        "NOTER UCRETI TOPLAM", "VERGI ODEME MAKBUZU",
        "SIGORTA PRIM ODEME", "KASKO ODEME TUTARI",
        "ATM CEKIM ISLEMI", "BANKA KOMISYON",
        "HAVALE EFT ISLEMI", "KREDI ODEME TUTARI",
        "HEDIYE SATIN ALMA", "CICEK GONDERME ODEME",
        "TELEFON TAMIR UCRETI", "ELEKTRONIK SERVIS",
        "TRAFIK CEZASI ODEME", "E-DEVLET ODEME",
        "CESITLI ALISVERIS TOPLAM", "GENEL GIDER",
    ],
}

# Veri hazirla
texts = []
labels = []
for category, examples in data.items():
    for text in examples:
        texts.append(text)
        labels.append(category)

total = len(texts)
cats = len(data)
print(f"Toplam: {total} ornek, {cats} kategori")
for cat, examples in data.items():
    print(f"  {cat}: {len(examples)} ornek")

# Model egitimi
clf = ExpenseClassifier()
clf.train(texts, labels)
print("\nModel egitildi ve kaydedildi (model.pkl, vectorizer.pkl).")

# Test — normal + OCR tarzı
test_cases = [
    # Normal
    ("Migros alisverisi", "Market"),
    ("BIM market", "Market"),
    ("haftalik pazar alisverisi", "Market"),
    ("Yemeksepeti siparis", "Yeme ve Icme"),
    ("Starbucks kahve", "Yeme ve Icme"),
    ("restoran yemek", "Yeme ve Icme"),
    ("elektrik faturasi", "Faturalar"),
    ("Netflix abonelik", "Faturalar"),
    ("Turkcell fatura", "Faturalar"),
    ("Uber yolculuk", "Ulasim"),
    ("Shell benzin", "Ulasim"),
    ("metro kart yukleme", "Ulasim"),
    ("ucak bileti", "Ulasim"),
    ("kira odemesi", "Kira ve Ev"),
    ("IKEA mobilya", "Kira ve Ev"),
    ("apartman aidati", "Kira ve Ev"),
    ("eczane ilac", "Saglik"),
    ("dis hekimi", "Saglik"),
    ("doktor muayene", "Saglik"),
    ("spor salonu uyelik", "Saglik"),
    ("gym uyelik", "Saglik"),
    ("sinema bileti", "Eglence"),
    ("konser bileti", "Eglence"),
    ("bowling oynadim", "Eglence"),
    ("LC Waikiki giysi", "Giyim"),
    ("ayakkabi aldim", "Giyim"),
    ("Zara elbise", "Giyim"),
    ("Trendyol giyim", "Giyim"),
    ("universite harc", "Egitim"),
    ("Udemy kurs", "Egitim"),
    ("dershane aylik", "Egitim"),
    ("kargo ucreti", "Diger"),
    ("banka komisyon", "Diger"),
    ("hediye satin alma", "Diger"),
    # OCR tarzı büyük harf
    ("TOPLAM MIGROS", "Market"),
    ("TOPLAM STARBUCKS", "Yeme ve Icme"),
    ("ELEKTRIK FATURASI TOPLAM", "Faturalar"),
    ("TOPLAM SHELL AKARYAKIT", "Ulasim"),
    ("KIRA ODEME MAKBUZU", "Kira ve Ev"),
    ("ECZANE FATURASI TOPLAM", "Saglik"),
    ("SINEMA BILETI TOPLAM", "Eglence"),
    ("LC WAIKIKI ALISVERIS TOPLAM", "Giyim"),
    ("UDEMY KURS SATIN ALMA", "Egitim"),
    ("KARGO UCRETI TOPLAM", "Diger"),
    # Belirsiz/zor
    ("dogalgaz fatura odeme", "Faturalar"),
    ("taksi uber yolculuk", "Ulasim"),
    ("eczane recete", "Saglik"),
    ("pilates yoga ders", "Saglik"),
    ("tiyatro bileti", "Eglence"),
]

print("\n--- TEST SONUCLARI ---")
dogru = 0
for text, beklenen in test_cases:
    tahmin = clf.model.predict(clf.vectorizer.transform([text]))[0]
    ok = "OK" if tahmin == beklenen else "YANLIS"
    if tahmin == beklenen:
        dogru += 1
    else:
        print(f"  [{ok}] '{text}' -> {tahmin} (beklenen: {beklenen})")

print(f"\nBasari: {dogru}/{len(test_cases)} ({100*dogru//len(test_cases)}%)")
