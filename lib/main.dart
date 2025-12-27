import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  await DataManager.init();
  
  runApp(const HokusFocusApp());
}

// ----------------------------------------
// VERİ YÖNETİCİSİ
// ----------------------------------------
class DataManager {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static int getToplamSureSn() => _prefs.getInt('toplamSureSn') ?? 0;
  static int getToplamOturum() => _prefs.getInt('toplamOturum') ?? 0;
  static int getTamamlananOturum() => _prefs.getInt('tamamlananOturum') ?? 0;
  static int getEnUzunOdakSn() => _prefs.getInt('enUzunOdakSn') ?? 0;
  static double getGenelAkisPuani() => _prefs.getDouble('genelAkisPuani') ?? 0.0;

  static Future<void> oturumKaydet({
    required int sureSn,
    required bool tamamlandi,
    required double akisPuani,
  }) async {
    int mevcutSure = getToplamSureSn();
    await _prefs.setInt('toplamSureSn', mevcutSure + sureSn);

    int mevcutOturum = getToplamOturum();
    await _prefs.setInt('toplamOturum', mevcutOturum + 1);

    if (tamamlandi) {
      int mevcutTamamlanan = getTamamlananOturum();
      await _prefs.setInt('tamamlananOturum', mevcutTamamlanan + 1);
    }

    int mevcutRekor = getEnUzunOdakSn();
    if (sureSn > mevcutRekor) {
      await _prefs.setInt('enUzunOdakSn', sureSn);
    }

    double mevcutOrt = getGenelAkisPuani();
    double yeniOrt = (mevcutOturum == 0) 
        ? akisPuani 
        : ((mevcutOrt * mevcutOturum) + akisPuani) / (mevcutOturum + 1);
    await _prefs.setDouble('genelAkisPuani', yeniOrt);
  }
}

class HokusFocusApp extends StatelessWidget {
  const HokusFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HokusFocus',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F2EA),
        primaryColor: const Color(0xFF2E4035),
        fontFamily: 'Courier', 
        useMaterial3: true,
      ),
      home: const KarsilamaEkrani(),
    );
  }
}

// ----------------------------------------
// 0. EKRAN: KARŞILAMA
// ----------------------------------------
class KarsilamaEkrani extends StatefulWidget {
  const KarsilamaEkrani({super.key});

  @override
  State<KarsilamaEkrani> createState() => _KarsilamaEkraniState();
}

class _KarsilamaEkraniState extends State<KarsilamaEkrani> {
  int _toplamSureSn = 0;
  int _toplamOturum = 0;
  int _enUzunOdak = 0;
  double _akisPuani = 0;
  int _tamamlanan = 0;

  @override
  void initState() {
    super.initState();
    _verileriGuncelle();
  }

  void _verileriGuncelle() {
    setState(() {
      _toplamSureSn = DataManager.getToplamSureSn();
      _toplamOturum = DataManager.getToplamOturum();
      _enUzunOdak = DataManager.getEnUzunOdakSn();
      _akisPuani = DataManager.getGenelAkisPuani();
      _tamamlanan = DataManager.getTamamlananOturum();
    });
  }

  String _formatSaatDk(int saniye) {
    if (saniye < 60) return "${saniye}sn";
    int saat = saniye ~/ 3600;
    int dk = (saniye % 3600) ~/ 60;
    int sn = saniye % 60;
    if (saat > 0) return "${saat}sa ${dk}dk";
    if (sn > 0) return "${dk}dk ${sn}sn";
    return "${dk}dk";
  }

  void _istatistikleriGoster() {
    _verileriGuncelle();
    int tamamlamaOrani = _toplamOturum > 0 
        ? ((_tamamlanan / _toplamOturum) * 100).toInt() 
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: const Text("DURUM ÖZETİ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035), fontSize: 18, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 10),
            _buildStatRow("Odak Süresi", _formatSaatDk(_toplamSureSn), isBold: true),
            _buildStatRow("Oturumlar", "$_toplamOturum Kez"),
            const SizedBox(height: 10),
            _buildStatRow("En Uzun Odak", _formatSaatDk(_enUzunOdak)),
            _buildStatRow("Tamamlama Oranı", "%$tamamlamaOrani"),
            _buildStatRow("Ritim Uyumu", "%${_akisPuani.toInt()}"),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("KAPAT", style: TextStyle(color: Color(0xFFD65A31), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF5C5B57), fontSize: 14)),
          Text(value, style: TextStyle(
            color: const Color(0xFF2E4035), 
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            fontSize: isBold ? 18 : 14
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // --- YENİ BAŞLIK (LOGO TARZI) ---
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  // Ortak stiller (Font ailesi, boyut, renk, italiklik)
                  style: const TextStyle(
                    fontFamily: 'Serif',
                    fontStyle: FontStyle.italic,
                    fontSize: 56,
                    letterSpacing: -2.0,
                    color: Color(0xFF2E4035), // Koyu yeşil ana renk
                  ),
                  children: const <TextSpan>[
                    // 1. Kısım: Hokus (Daha zarif ve ince)
                    TextSpan(
                      text: 'Hokus',
                      style: TextStyle(fontWeight: FontWeight.w400), // Normal kalınlık
                    ),
                    // 2. Kısım: Focus (Vurgulu ve kalın - Odak noktası)
                    TextSpan(
                      text: 'Focus',
                      style: TextStyle(fontWeight: FontWeight.w900), // Ekstra kalın
                    ),
                  ],
                ),
              ),
              // -------------------------------
              const SizedBox(height: 40),
              const Text(
                "Odaklanmak için uğraşma.\nSen sadece ritme eşlik et,\nZihnin odaklanmak zorunda kalacak...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Serif', 
                  fontStyle: FontStyle.italic, 
                  fontSize: 18, 
                  color: Color(0xFF5C5B57), 
                  height: 1.5, 
                  fontWeight: FontWeight.w400
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => const KurulumEkrani())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4035),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                    shadowColor: const Color(0x40000000),
                  ),
                  child: const Text("BAŞLA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _istatistikleriGoster,
                  icon: const Icon(Icons.bar_chart, color: Color(0xFF2E4035)),
                  label: const Text("İSTATİSTİKLER", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF2E4035))),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              const Text("v1.2", style: TextStyle(color: Color(0x4DA09E96), fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------
// 1. EKRAN: KALİBRASYON
// ----------------------------------------
class KurulumEkrani extends StatefulWidget {
  const KurulumEkrani({super.key});

  @override
  State<KurulumEkrani> createState() => _KurulumEkraniState();
}

class _KurulumEkraniState extends State<KurulumEkrani> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _dkController = TextEditingController();
  final TextEditingController _snController = TextEditingController();
  final TextEditingController _toplamDkController = TextEditingController();
  final TextEditingController _hedefAdetHesapController = TextEditingController();
  final TextEditingController _hedefController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dkController.dispose();
    _snController.dispose();
    _toplamDkController.dispose();
    _hedefAdetHesapController.dispose();
    _hedefController.dispose();
    super.dispose();
  }

  void _baslat() {
    // 1. Önce Hedef Sayısını alıyoruz (Bölme işlemi için gerekli)
    int hedef = int.tryParse(_hedefController.text.isNotEmpty ? _hedefController.text : _hedefAdetHesapController.text) ?? 1;
    
    // Hedef 0 veya boş girildiyse hatayı önlemek için en az 1 yapalım
    if (hedef < 1) hedef = 1;

    double birimSureDk = 0.0;
    
    if (_tabController.index == 0) {
       // --- TAB 1: BİRİM SÜRE MODU ---
       // Kullanıcı "1 tanesi kaç dk sürer" onu giriyor. Aynen alıyoruz.
       double dk = double.tryParse(_dkController.text) ?? 0;
       double sn = double.tryParse(_snController.text) ?? 0;
       birimSureDk = dk + (sn / 60); 
    } else {
       // --- TAB 2: TOPLAM SÜRE MODU (DÜZELTME BURADA) ---
       // Kullanıcı "Toplam 30 dk sürecek" dediyse ve hedef 10 ise;
       // Birim süre = 30 / 10 = 3 dk olmalı.
       double toplamDk = double.tryParse(_toplamDkController.text) ?? 0.0;
       birimSureDk = toplamDk / hedef;
    }

    // Kokpit ekranına her zaman hesaplanmış "Birim Süre"yi gönderiyoruz.
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (context) => KokpitEkrani(
          hedefSureDk: birimSureDk,
          hedefMiktar: hedef,
        )
      )
    );
  }

  void _olcumYap() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const OlcumDialog(),
    ).then((value) {
      if (value != null && value is int) {
        setState(() {
          _dkController.text = (value ~/ 60).toString();
          _snController.text = (value % 60).toString();
          _tabController.animateTo(0); 
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E4035)),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KarsilamaEkrani())),
        ),
        title: const Text("KALİBRASYON", style: TextStyle(color: Color(0xFF2E4035), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(30), 
                border: Border.all(color: const Color(0x1A2E4035))
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF2E4035), 
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFA09E96),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1),
                labelPadding: EdgeInsets.zero, 
                tabs: const [
                  Tab(child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0), 
                    child: Text("BİRİM SÜRE"), 
                  )),
                  Tab(child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text("TOPLAM SÜRE"),
                  )),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text("1 birim (sayfa/soru) ne kadar sürer?", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5C5B57))),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: _dkController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration("DK"))),
                            const SizedBox(width: 10),
                            const Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: _snController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration("SN"))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _olcumYap, 
                          icon: const Icon(Icons.timer, size: 18), 
                          label: const Text("Bilmiyorum, Şimdi Ölç", style: TextStyle(fontWeight: FontWeight.bold)), 
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD65A31)),
                        ),
                        const SizedBox(height: 30),
                        const Align(alignment: Alignment.centerLeft, child: Text("Hedef Miktar", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035)))),
                        const SizedBox(height: 8),
                        TextField(controller: _hedefController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration("Hedef Soru/Sayfa Sayısı")),
                      ],
                    ),
                  ),

                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text("Bu oturum toplam ne kadar sürer?", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5C5B57))),
                        const SizedBox(height: 30),
                        const Align(alignment: Alignment.centerLeft, child: Text("Oturum Süresi", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035)))),
                        const SizedBox(height: 8),
                        TextField(controller: _toplamDkController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration("DK")),
                        const SizedBox(height: 20),
                        const Align(alignment: Alignment.centerLeft, child: Text("Hedef Miktar", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035)))),
                        const SizedBox(height: 8),
                        TextField(controller: _hedefAdetHesapController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration("Hedef Soru/Sayfa Sayısı")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _baslat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4035), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("FOCUS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ),
             const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, 
      hintStyle: TextStyle(color: const Color(0xFFA09E96).withValues(alpha: 0.5), fontSize: 14),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
    );
  }
}

class OlcumDialog extends StatefulWidget {
  const OlcumDialog({super.key});

  @override
  State<OlcumDialog> createState() => _OlcumDialogState();
}

class _OlcumDialogState extends State<OlcumDialog> {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  bool _basladi = false;

  @override
  void dispose() {
    if (_basladi && _timer.isActive) _timer.cancel();
    super.dispose();
  }

  void _baslatBitir() {
    if (!_basladi) {
      setState(() { _basladi = true; });
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) { setState(() {}); });
    } else {
      _stopwatch.stop();
      _timer.cancel();
      Navigator.pop(context, _stopwatch.elapsed.inSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    String sureStr = "${(_stopwatch.elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}";
    
    return AlertDialog(
      backgroundColor: const Color(0xFFF5F2EA),
      title: const Text("SÜRE ÖLÇÜMÜ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            !_basladi 
            ? "Şimdi 1 sayfa/soru çözmeye başla ve butona bas. Bitince tekrar bas."
            : "İşin bitince durdur.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(sureStr, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: _baslatBitir,
            style: ElevatedButton.styleFrom(
              backgroundColor: _basladi ? const Color(0xFFD65A31) : const Color(0xFF2E4035),
              foregroundColor: Colors.white
            ),
            child: Text(_basladi ? "BİTTİ (DURDUR)" : "BAŞLA"),
          ),
        )
      ],
    );
  }
}

// ----------------------------------------
// 2. EKRAN: KOKPİT (YENİ İKONLU VE DÖNÜŞLÜ)
// ----------------------------------------
class KokpitEkrani extends StatefulWidget {
  final double hedefSureDk; 
  final int hedefMiktar; 

  const KokpitEkrani({
    super.key, 
    required this.hedefSureDk, 
    required this.hedefMiktar,
  });

  @override
  State<KokpitEkrani> createState() => _KokpitEkraniState();
}

class _KokpitEkraniState extends State<KokpitEkrani> with TickerProviderStateMixin {
  late Ticker _ticker;
  Duration _oyunZamani = Duration.zero; 
  bool _ilkEtkilesimYapildi = false; 
  DateTime? _tavsanBaslangicReferansi; 
  int _tamamlananAdet = 0;
  final Stopwatch _gercekSureKronometresi = Stopwatch();
  bool _oyunBitti = false;
  bool _duraklatildi = false;
  final FocusNode _klavyeOdagi = FocusNode();

  double _toplamUyumlulukPuani = 0.0; 

  late AnimationController _efektController;
  late Animation<double> _efektOpaklik;
  late Animation<double> _efektHareket;

  @override
  void initState() {
    super.initState();
    
    _efektController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _efektOpaklik = Tween<double>(begin: 0.8, end: 0.0).animate(CurvedAnimation(parent: _efektController, curve: Curves.easeOut));
    _efektHareket = Tween<double>(begin: 0.0, end: -40.0).animate(CurvedAnimation(parent: _efektController, curve: Curves.easeOut));

    _ticker = createTicker((elapsed) {
      if (_oyunBitti || _duraklatildi) return;
      
      if (_tavsanBaslangicReferansi != null) {
        var simdi = DateTime.now();
        var gecenSure = simdi.difference(_tavsanBaslangicReferansi!);
        
        // --- YENİ MANTIK BAŞLANGICI ---
        // 1. Tavşanın doğal (süreye bağlı) yerini hesapla
        int birimMs = (widget.hedefSureDk * 60).toInt() * 1000;
        double rawProgress = gecenSure.inMilliseconds / birimMs;
        double tavsanKonum = rawProgress - 1.0;
        
        // 2. Sınırı kontrol et (Senin konumun - 4.0)
        double altSinir = _tamamlananAdet - 4.0;
        
        // 3. Eğer tavşan sınırdan gerideyse, ZAMANI ileri sar!
        if (tavsanKonum < altSinir) {
          // Tavşanı zorla alt sınıra taşıyacak yeni süreyi hesapla
          double hedefRaw = altSinir + 1.0; 
          int hedefMs = (hedefRaw * birimMs).toInt();
          
          // Başlangıç referansını kaydır (Zaman borcunu sil)
          _tavsanBaslangicReferansi = simdi.subtract(Duration(milliseconds: hedefMs));
          
          // Oyun zamanını güncelle
          _oyunZamani = Duration(milliseconds: hedefMs);
        } else {
           // Her şey yolundaysa normal akışa devam
           _oyunZamani = gecenSure;
        }
        // --- YENİ MANTIK BİTİŞİ ---

        setState(() {}); // Ekranı yenile
        _hakemKontrolu();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _rehberGoster());
  }

  void _rehberGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: const Text("NASIL ÇALIŞIR?", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2E4035), letterSpacing: 1), textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 48, color: Color(0xFFD65A31)),
            SizedBox(height: 20),
            // 1. Madde
            Text("1. Her birim (sayfa/soru) bittiğinde ekrana dokun.", style: TextStyle(fontSize: 16, color: Color(0xFF2E4035)), textAlign: TextAlign.center),
            SizedBox(height: 15),
            // 2. Madde
            Text("2. Tavşanla bağını koparma.", style: TextStyle(fontSize: 16, color: Color(0xFF2E4035)), textAlign: TextAlign.center),
            SizedBox(height: 20),
            // Alt Bilgi
            Text("Süre sen 'HAZIRIM' diyince başlayacak.", style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _oyunuBaslat();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E4035), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              child: const Text("HAZIRIM", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          )
        ],
      ),
    );
  }

  void _oyunuBaslat() {
    setState(() {
      _tavsanBaslangicReferansi = DateTime.now();
      _oyunZamani = Duration.zero;
      
      // Dakikayı saniyeye çevirip avans olarak ekliyoruz
      
      
      // BURASI ÖNEMLİ: İlk etkileşimi FALSE yapıyoruz ki rüzgar izi hemen çıkmasın!
      _ilkEtkilesimYapildi = false; 
    });

    _gercekSureKronometresi.start();
    _ticker.start();
    _klavyeOdagi.requestFocus();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _efektController.dispose();
    _klavyeOdagi.dispose();
    super.dispose();
  }

  void _hakemKontrolu() {
    if (_oyunZamani.inMilliseconds == 0 || _oyunBitti) return;

    // 1. Tavşanın güncel konumunu al
    double tavsanKonum = _tavsanAdetKonumu();
    
    // 2. Senin konumun
    double benimKonum = _tamamlananAdet.toDouble();

    // 3. Tavşan ne kadar önde?
    double fark = tavsanKonum - benimKonum;

    // 4. Eğer Tavşan 4 birimden (180 derece) fazla fark attıysa DÜDÜĞÜ ÇAL!
    if (fark >= 4.0) {
      // İşte burası senin o "sarı kutucuklu" görseldeki kodunu tetikler.
      _oyunuBitir(kazandiMi: false, baslik: "KOPTUN");
    }
  }

  void _cikisSor() {
    _gercekSureKronometresi.stop();
    setState(() { _duraklatildi = true; });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: const Text("KAÇACAK MISIN?", style: TextStyle(color: Color(0xFFD65A31), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text("Oturumu sonlandırmak istediğine emin misin?", textAlign: TextAlign.center),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  _gercekSureKronometresi.start();
                  if (_ilkEtkilesimYapildi && _tavsanBaslangicReferansi != null) {
                      _tavsanBaslangicReferansi = DateTime.now().subtract(_oyunZamani);
                  }
                  setState(() { _duraklatildi = false; });
                  Navigator.pop(context);
                  _klavyeOdagi.requestFocus();
                },
                child: const Text("HAYIR", style: TextStyle(color: Color(0xFF2E4035), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD65A31), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context); 
                  _oyunuBitir(kazandiMi: false, baslik: "OTURUM SONA ERDİ");
                },
                child: const Text("EVET"),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _durdur() {
    _gercekSureKronometresi.stop(); 
    setState(() { _duraklatildi = true; });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: const Text("NEDEN DURDUN?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text("Akış bozuldu. Odak soğuyor.\nBu yaptığın ritme ihanet.", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E4035), foregroundColor: Colors.white),
              onPressed: () {
                if (_ilkEtkilesimYapildi) {
                  _tavsanBaslangicReferansi = DateTime.now().subtract(_oyunZamani);
                }
                _gercekSureKronometresi.start(); 
                setState(() { _duraklatildi = false; });
                Navigator.pop(context);
                _klavyeOdagi.requestFocus();
              },
              child: const Text("RİTME DÖN"),
            ),
          )
        ],
      ),
    );
  }

  void _birimTamamla() {
    if (_oyunBitti || _duraklatildi) return;

    if (!_ilkEtkilesimYapildi) {
      setState(() {
        _ilkEtkilesimYapildi = true;
        // BURADA SIFIRLAMA YAPMIYORUZ! Tavşan koşmaya devam ediyor, biz sadece katıldık.
        _tamamlananAdet++;
        _toplamUyumlulukPuani += 1.0; 
      });
      _efektCalistir();
      return;
    }

    double tavsanKonumu = _tavsanAdetKonumu();
    double potansiyelYeniBen = (_tamamlananAdet + 1).toDouble();
    double fark = (potansiyelYeniBen - tavsanKonumu).abs();
    
    double anlikPuan = (4.0 - fark) / 4.0;
    if (anlikPuan < 0) anlikPuan = 0;
    _toplamUyumlulukPuani += anlikPuan;

    _efektCalistir();

    double potansiyelFark = potansiyelYeniBen - tavsanKonumu;

    if (potansiyelFark > 4.0) {
      double yeniTavsanKonumu = potansiyelYeniBen - 4.0;
      int yeniMs = (yeniTavsanKonumu * (widget.hedefSureDk * 60).toInt() * 1000).floor();
      _tavsanBaslangicReferansi = DateTime.now().subtract(Duration(milliseconds: yeniMs));
      _oyunZamani = Duration(milliseconds: yeniMs);
      setState(() { _tamamlananAdet++; });
      if (_tamamlananAdet >= widget.hedefMiktar) _oyunuBitir(kazandiMi: true, baslik: "HEDEF TAMAMLANDI");
      return; 
    }

    if (_tamamlananAdet < widget.hedefMiktar) {
      setState(() { _tamamlananAdet++; });
      if (_tamamlananAdet >= widget.hedefMiktar) _oyunuBitir(kazandiMi: true, baslik: "HEDEF TAMAMLANDI");
    }
  }

  void _efektCalistir() {
    _efektController.reset();
    _efektController.forward();
  }

  void _oyunuBitir({required bool kazandiMi, required String baslik}) async {
    _oyunBitti = true;
    _ticker.stop();
    _gercekSureKronometresi.stop(); 

    // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
    // Hesaplamada kullanılacak adet sayısını belirliyoruz.
    // Eğer "KOPTUN" ise, başarısız olunan o son turu da paydaya (+1) ekliyoruz.
    int hesaplananAdet = _tamamlananAdet;
    if (baslik == "KOPTUN") {
      hesaplananAdet += 1;
    }
    // --- DEĞİŞİKLİK BURADA BİTİYOR ---

    int gercekSaniye = _gercekSureKronometresi.elapsed.inSeconds;
    
    // DÜZELTME: Bölerken artık _tamamlananAdet yerine hesaplananAdet kullanıyoruz
    double akisPuaniYuzde = hesaplananAdet > 0 ? (_toplamUyumlulukPuani / hesaplananAdet) * 100 : 0;

    await DataManager.oturumKaydet(
      sureSn: gercekSaniye, 
      tamamlandi: kazandiMi, 
      akisPuani: akisPuaniYuzde
    );

    String formatSureDetayli(int toplamSn) {
      if (toplamSn < 60) return "$toplamSn sn";
      int dk = toplamSn ~/ 60;
      int sn = toplamSn % 60;
      if (dk > 0) return "$dk dk $sn sn";
      return "$sn sn";
    }

    String gercekGecenSureStr = formatSureDetayli(gercekSaniye);
    
    // DÜZELTME: Ortalama hız hesaplarken de yeni adeti kullanıyoruz (Adil olması için)
    double ortalamaSn = hesaplananAdet > 0 ? gercekSaniye / hesaplananAdet : 0;
    String ortalamaHizStr = formatSureDetayli(ortalamaSn.round());

    // Burası değişmedi, beklenen süre hala tamamlanana göre hesaplanıyor
    int beklenenSaniye = (widget.hedefSureDk * 60).toInt() * _tamamlananAdet; 
    int farkSaniye = beklenenSaniye - gercekSaniye;
    String performansMesaji = "";
    
    if (baslik == "HEDEF TAMAMLANDI") {
        if (farkSaniye > 0) {
          performansMesaji = "Beklenenden ${formatSureDetayli(farkSaniye)} erken tamamladın.";
        } else {
          performansMesaji = "Beklenenden ${formatSureDetayli(farkSaniye.abs())} geç tamamladın.";
        }
    } else if (baslik == "KOPTUN") {
        performansMesaji = "Odağın dağıldı. Tavşan seni geride bıraktı.";
    } else {
        performansMesaji = "Oturumu kendi isteğinle sonlandırdın.";
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: Text(baslik, style: TextStyle(color: (baslik == "HEDEF TAMAMLANDI") ? const Color(0xFF2E4035) : Colors.red, fontWeight: FontWeight.bold, fontSize: 22), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(performansMesaji, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: (baslik == "HEDEF TAMAMLANDI") ? const Color(0xFF2E4035) : Colors.black54)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _buildSonucSatiri("Süre:", gercekGecenSureStr),
            const SizedBox(height: 8),
            _buildSonucSatiri("Ort. Hız:", ortalamaHizStr),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Ritim Uyumu:", style: TextStyle(color: Color(0xFFA09E96))),
                Text("%${akisPuaniYuzde.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD65A31))),
            ]),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () { 
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const KarsilamaEkrani()), (route) => false); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E4035), foregroundColor: Colors.white),
              child: const Text("TAMAM"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSonucSatiri(String baslik, String deger) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(baslik, style: const TextStyle(color: Color(0xFFA09E96))),
        Text(deger, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035))),
    ]);
  }

  double _tavsanAdetKonumu() {
    // Tavşan konumu hesaplanırken "- 1.0" yaparak onu görsel olarak 1 tur geriye attık.
    // Bu senin "1 birim süre Avans" mantığınla görselin eşleşmesini sağlıyor.
    // Tavşan arkadan geliyor, sen 0. turdan başlıyorsun ama +1 birim süren var.
    double rawProgress = _oyunZamani.inMilliseconds / ((widget.hedefSureDk * 60).toInt() * 1000);
    return rawProgress - 1.0; 
  }

  String _farkHesapla() {
    double farkAdet = _tamamlananAdet - _tavsanAdetKonumu();
    if (farkAdet > 4.0) farkAdet = 4.0;
    int farkSaniye = (farkAdet * (widget.hedefSureDk * 60).toInt()).round(); 
    String isaret = farkSaniye >= 0 ? "+" : "-";
    int mutlakSaniye = farkSaniye.abs();
    return "$isaret ${mutlakSaniye ~/ 60}:${(mutlakSaniye % 60).toString().padLeft(2, '0')}";
  }

  Color _durumRengi() {
    // Burada early return'ü kaldırdık, sayaç hemen renkli görünsün.
    return (_tamamlananAdet >= _tavsanAdetKonumu()) ? const Color(0xFF6B8E23) : const Color(0xFFD65A31);
  }

  Alignment _tavsanRelativePozisyonu() {
    double tavsanYol = _tavsanAdetKonumu();
    double aciRadyan = tavsanYol * (math.pi / 4);
    double finalAci = (-math.pi / 2) + aciRadyan;
    double yaricapOrani = 0.88;
    return Alignment(math.cos(finalAci) * yaricapOrani, math.sin(finalAci) * yaricapOrani);
  }

  List<Widget> _buildCeltikler() {
    List<Widget> celtikler = [];
    for (int i = 0; i < 8; i++) {
      double aci = (i * 45) * (math.pi / 180);
      celtikler.add(
        Transform.rotate(
          angle: aci,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(width: 2, height: 10, color: const Color(0xFFA09E96)),
          ),
        ),
      );
    }
    return celtikler;
  }

  @override
  Widget build(BuildContext context) {
    double dunyaDonusAcisi = -_tamamlananAdet * (math.pi / 4);

    return KeyboardListener(
      focusNode: _klavyeOdagi,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
          _birimTamamla();
        }
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            _birimTamamla(); 
            _klavyeOdagi.requestFocus(); 
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned(
                bottom: 30, left: 0, right: 0,
                child: Center(
                  child: FloatingActionButton.extended(
                    onPressed: _durdur,
                    backgroundColor: const Color(0xFFD65A31), 
                    icon: const Icon(Icons.pause, color: Colors.white),
                    label: const Text("DURDUR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFFA09E96), size: 30), 
                            onPressed: _cikisSor
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 360, height: 360,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder(
                                  tween: Tween<double>(end: dunyaDonusAcisi), 
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  builder: (context, val, child) {
                                    return Transform.rotate(
                                      angle: val,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 280, height: 280,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle, 
                                              border: Border.all(color: const Color(0x4DA09E96), width: 2)
                                            ),
                                            child: Stack(children: _buildCeltikler()),
                                          ),
                                          
                                          // --- YENİ TAVŞAN İKONU (DÖNEN) ---
                                          Align(
                                            alignment: _tavsanRelativePozisyonu(), 
                                            child: Transform.rotate(
                                              angle: (_tavsanAdetKonumu() * (math.pi / 4)),
                                              child: Image.asset(
                                                'assets/images/tavsan_ikon.png', 
                                                width: 45, 
                                                height: 45,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                
                                Align(
                                  alignment: const Alignment(0, -0.83), 
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // RÜZGAR İZİ: Sadece ilk etkileşim yapıldıysa görünür
                                      if (_ilkEtkilesimYapildi) 
                                        AnimatedBuilder(
                                          animation: _efektController,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity: _efektOpaklik.value,
                                              child: Transform.translate(
                                                offset: Offset(-35.0 + _efektHareket.value, 0),
                                                child: Transform.rotate(
                                                  angle: -math.pi / 2, 
                                                  child: const Icon(Icons.air, size: 30, color: Color(0x662E4035)),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      Transform.rotate(
                                        angle: math.pi / 2, 
                                        child: const Icon(Icons.navigation, size: 32, color: Color(0xFF2E4035)),
                                      ), 
                                    ],
                                  ),
                                ),

                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_farkHesapla(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _durumRengi())),
                                    const SizedBox(height: 10),
                                    Text("$_tamamlananAdet / ${widget.hedefMiktar}", style: const TextStyle(fontSize: 24, color: Color(0xFFA09E96))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
