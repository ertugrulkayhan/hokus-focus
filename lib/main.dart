import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await DataManager.init();
  runApp(const HokusFocusApp());
}




class DataManager {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static int getToplamSureSn() => _prefs.getInt('toplamSureSn') ?? 0;
  static int getToplamOturum() => _prefs.getInt('toplamOturum') ?? 0;
  static int getTamamlananOturum() => _prefs.getInt('tamamlananOturum') ?? 0;
  static int getEnUzunOdakSn() => _prefs.getInt('enUzunOdakSn') ?? 0;
  static double getGenelAkisPuani() =>
      _prefs.getDouble('genelAkisPuani') ?? 0.0;

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


  static Future<void> verileriSifirla() async {
    await _prefs.setInt('toplamSureSn', 0);
    await _prefs.setInt('toplamOturum', 0);
    await _prefs.setInt('tamamlananOturum', 0);
    await _prefs.setInt('enUzunOdakSn', 0);
    await _prefs.setDouble('genelAkisPuani', 0.0);
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

        textTheme: GoogleFonts.poppinsTextTheme(),

        useMaterial3: true,
      ),

      builder: (context, child) {
        return Container(

          color: const Color(0xFFEAEAEA),
          child: Center(
            child: ConstrainedBox(

              constraints: const BoxConstraints(maxWidth: 400),

              child: child,
            ),
          ),
        );
      },

      home: const KarsilamaEkrani(),
    );
  }
}




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
    if (saniye == 0) return "0 dk"; // Skor tabelası etkisi!
    if (saniye < 60) return "${saniye} sn";
    int saat = saniye ~/ 3600;
    int dk = (saniye % 3600) ~/ 60;
    if (saat > 0) return "${saat}sa ${dk}dk";
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 24),
            Text(
              "DURUM ÖZETİ",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E4035),
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFFF5F2EA),
                    title: const Center(
                      child: Text(
                        "SIFIRLA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    content: const Text(
                      "Tüm istatistiklerin silinecek. Bu işlem geri alınamaz.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "VAZGEÇ",
                          style: TextStyle(color: Color(0xFF2E4035)),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await DataManager.verileriSifirla();
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          _verileriGuncelle();
                        },
                        child: const Text("SİL"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 10),
            _buildStatRow(
              "Focus Süresi",
              _formatSaatDk(_toplamSureSn),
              isBold: true,
            ),
            _buildStatRow("Oturumlar", "$_toplamOturum Kez"),
            const SizedBox(height: 10),
            _buildStatRow("En Uzun Focus", _formatSaatDk(_enUzunOdak)),
            _buildStatRow("Tamamlama Oranı", "%$tamamlamaOrani"),
            _buildStatRow("Zaman Hakimiyetin", "%${_akisPuani.toInt()}"),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "KAPAT",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFD65A31),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF5C5B57),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: const Color(0xFF2E4035),
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/tavsan_ikon.png',
                    width: 24,
                    height: 24,
                    color: const Color(0xFF2E4035),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: const Color(0xFF2E4035),
                        letterSpacing: -0.5,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Hokus',
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: 'Focus',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2), // Üst boşluk esnekliği

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/tavsan_ikon.png',
                      width: 100,
                      height: 100,
                      color: const Color(0xFF2E4035),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Toplam Focus Süren",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA09E96),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatSaatDk(
                        _toplamSureSn,
                      ), // Dinamik rekor, sıfırsa "0 dk" basar
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2E4035),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3), // Alt boşluk esnekliği

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E4035).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KurulumEkrani(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E4035),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "BAŞLA",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _istatistikleriGoster,
                      icon: const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFFA09E96),
                        size: 20,
                      ),
                      label: Text(
                        "İstatistikleri Gör",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA09E96),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // En alt emniyet boşluğu
            ],
          ),
        ),
      ),
    );
  }
}




class KurulumEkrani extends StatefulWidget {
  const KurulumEkrani({super.key});

  @override
  State<KurulumEkrani> createState() => _KurulumEkraniState();
}

class _KurulumEkraniState extends State<KurulumEkrani>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _dkController = TextEditingController();
  final TextEditingController _snController = TextEditingController();
  final TextEditingController _toplamDkController = TextEditingController();
  final TextEditingController _hedefAdetHesapController =
      TextEditingController();
  final TextEditingController _hedefController = TextEditingController();
  bool _sonsuzMod = false;

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


    int hedef = _sonsuzMod
        ? 0
        : (int.tryParse(
                _hedefController.text.isNotEmpty
                    ? _hedefController.text
                    : _hedefAdetHesapController.text,
              ) ??
              1);


    if (!_sonsuzMod && hedef < 1) hedef = 1;

    double birimSureDk = 0.0;

    if (_tabController.index == 0) {

      double dk = double.tryParse(_dkController.text) ?? 0;
      double sn = double.tryParse(_snController.text) ?? 0;
      birimSureDk = dk + (sn / 60);
    } else {

      double toplamDk = double.tryParse(_toplamDkController.text) ?? 0.0;


      birimSureDk = (hedef > 0) ? toplamDk / hedef : 0.5;
    }


    if (birimSureDk <= 0) birimSureDk = 0.5;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => KokpitEkrani(
          hedefSureDk: birimSureDk,
          hedefMiktar:
              hedef, // Burası artık 0 gidebilecek (Sonsuz Mod için şifremiz bu)
        ),
      ),
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
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const KarsilamaEkrani()),
          ),
        ),
        title: const Text(
          "KALİBRASYON",
          style: TextStyle(
            color: Color(0xFF2E4035),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
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
                border: Border.all(color: const Color(0x1A2E4035)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF2E4035),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFA09E96),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text("BİRİM SÜRE"),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text("TOPLAM SÜRE"),
                    ),
                  ),
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
                        const Text(
                          "1 birim (sayfa/soru) ne kadar sürer?",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF5C5B57)),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dkController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: _inputDecoration("DK"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              ":",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _snController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: _inputDecoration("SN"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _olcumYap,
                          icon: const Icon(Icons.timer, size: 18),
                          label: const Text(
                            "Bilmiyorum, Şimdi Ölç",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD65A31),
                          ),
                        ),
                        const SizedBox(height: 30),


                        SwitchListTile(
                          title: const Text(
                            "Hedefsiz (Sonsuz) Mod",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E4035),
                            ),
                          ),
                          subtitle: const Text(
                            "Sınır yok, sen durdurana kadar devam eder.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          value: _sonsuzMod,
                          activeThumbColor: const Color(0xFFD65A31),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() {
                              _sonsuzMod = val;
                            });
                          },
                        ),


                        if (!_sonsuzMod) ...[
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Hedef Miktar",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E4035),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _hedefController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: _inputDecoration(
                              "Hedef Soru/Sayfa Sayısı",
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Bu oturum toplam ne kadar sürer?",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF5C5B57)),
                        ),
                        const SizedBox(height: 30),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Oturum Süresi",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E4035),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _toplamDkController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: _inputDecoration("DK"),
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Hedef Miktar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E4035),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hedefAdetHesapController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: _inputDecoration(
                            "Hedef Soru/Sayfa Sayısı",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF2E4035,
                      ).withOpacity(0.3), // Hafif yeşil gölge
                      blurRadius: 20, // Gölgenin yayılması (Flu)
                      offset: const Offset(0, 10), // Gölgenin aşağı kayması
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _baslat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4035),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 22),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0, // Kendi gölgesini kapattık, özel gölge verdik
                  ),
                  child: Text(
                    "FOCUS",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
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
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFFA09E96).withOpacity(0.5),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF2E4035), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
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
      setState(() {
        _basladi = true;
      });
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {});
      });
    } else {
      _stopwatch.stop();
      _timer.cancel();
      Navigator.pop(context, _stopwatch.elapsed.inSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    String sureStr =
        "${(_stopwatch.elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}";

    return AlertDialog(
      backgroundColor: const Color(0xFFF5F2EA),
      title: const Text(
        "SÜRE ÖLÇÜMÜ",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            !_basladi
                ? "Şimdi butona bas ve 1 sayfa/soru çözmeye başla. Bitince tekrar bas."
                : "İşin bitince durdur.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            sureStr,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: _baslatBitir,
            style: ElevatedButton.styleFrom(
              backgroundColor: _basladi
                  ? const Color(0xFFD65A31)
                  : const Color(0xFF2E4035),
              foregroundColor: Colors.white,
            ),
            child: Text(_basladi ? "BİTTİ (DURDUR)" : "BAŞLA"),
          ),
        ),
      ],
    );
  }
}




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

class _KokpitEkraniState extends State<KokpitEkrani>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  Duration _oyunZamani = Duration.zero;
  bool _ilkEtkilesimYapildi = false;
  DateTime? _tavsanBaslangicReferansi;
  int _tamamlananAdet = 0;
  final Stopwatch _gercekSureKronometresi = Stopwatch();
  bool _oyunBitti = false;
  bool _duraklatildi = false;
  final FocusNode _klavyeOdagi = FocusNode();


  Duration _toplamMolaSuresi = Duration.zero;



  Duration _gecikmeSuresi = Duration.zero;
  DateTime? _gecikmeBaslangicZamani;

  late AnimationController _efektController;
  late Animation<double> _efektOpaklik;
  late Animation<double> _efektHareket;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _efektController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _efektOpaklik = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _efektController, curve: Curves.easeOut));
    _efektHareket = Tween<double>(
      begin: 0.0,
      end: -40.0,
    ).animate(CurvedAnimation(parent: _efektController, curve: Curves.easeOut));

    _ticker = createTicker((elapsed) {
      if (_oyunBitti || _duraklatildi) return;

      if (_tavsanBaslangicReferansi != null) {
        var simdi = DateTime.now();
        var gecenSure = simdi.difference(_tavsanBaslangicReferansi!);


        int birimMs = (widget.hedefSureDk * 60).toInt() * 1000;
        double rawProgress = gecenSure.inMilliseconds / birimMs;
        double tavsanKonum = rawProgress - 1.0;


        double altSinir = _tamamlananAdet - 4.0;


        if (tavsanKonum < altSinir) {
          double hedefRaw = altSinir + 1.0;
          int hedefMs = (hedefRaw * birimMs).toInt();
          _tavsanBaslangicReferansi = simdi.subtract(
            Duration(milliseconds: hedefMs),
          );
          _oyunZamani = Duration(milliseconds: hedefMs);
        } else {
          _oyunZamani = gecenSure;
        }



        double benimKonum = _tamamlananAdet.toDouble();
        double guncelTavsanKonumu = _tavsanAdetKonumu();

        if (guncelTavsanKonumu > benimKonum) {

          if (_gecikmeBaslangicZamani == null) {
            _gecikmeBaslangicZamani = DateTime.now();
          }
        } else {

          if (_gecikmeBaslangicZamani != null) {

            Duration buGecikme = DateTime.now().difference(
              _gecikmeBaslangicZamani!,
            );
            _gecikmeSuresi += buGecikme;
            _gecikmeBaslangicZamani = null; // Sayacı sıfırla
          }
        }

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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2EA),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "NASIL ÇALIŞIR?",
                style: TextStyle(
                  fontWeight: FontWeight.w900, // En kalın
                  fontSize: 28, // Boyutu büyüttük (26 -> 28)
                  color: Color(0xFF2E4035),
                  letterSpacing: 0.5, // Harfleri sıkılaştırdık (Tombik efekt)
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),


              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _buildRehberAdim(
                    iconWidget: const Icon(
                      Icons.auto_stories,
                      size: 28,
                      color: Color(0xFF2E4035),
                    ),
                    title: "ÇÖZ / OKU",
                    desc: "İşini tamamla",
                  ),


                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Icon(
                      Icons.arrow_right_alt_rounded,
                      color: Color(0xFFD65A31),
                      size: 32,
                    ),
                  ),


                  _buildRehberAdim(
                    iconWidget: const Icon(
                      Icons.touch_app_rounded,
                      size: 28,
                      color: Color(0xFFD65A31),
                    ),
                    title: "DOKUN",
                    desc: "Ekrana bas",
                    highlight: true,
                  ),


                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Icon(
                      Icons.arrow_right_alt_rounded,
                      color: Color(0xFFD65A31),
                      size: 32,
                    ),
                  ),


                  _buildRehberAdim(
                    iconWidget: Image.asset(
                      'assets/images/tavsan_ikon.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                    title: "ÖNDE KAL",
                    desc: "Tavşanı Geç",
                  ),
                ],
              ),

              const SizedBox(height: 32),


              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "İşin bitince ekrana dokun; gerideysen yetiş, öndeysen fark at.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5C5B57),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),


              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E4035).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8), // Gölge aşağı düşer
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _oyunuBaslat();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4035),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                    ), // Daha yüksek buton
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0, // Kendi gölgesini kapattık, özel gölge verdik
                  ),
                  child: const Text(
                    "HAZIRIM",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 18, // Yazıyı büyüttük
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildRehberAdim({
    required Widget iconWidget,
    required String title,
    required String desc,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Container(
          width: 64, // Sabit Genişlik
          height: 64, // Sabit Yükseklik
          padding: const EdgeInsets.all(8), // Tavşana yer açmak için az padding
          decoration: BoxDecoration(
            color: highlight
                ? const Color(0xFFD65A31).withValues(alpha: 0.1)
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: highlight ? const Color(0xFFD65A31) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (!highlight)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Center(child: iconWidget),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: highlight
                ? const Color(0xFFD65A31)
                : const Color(0xFF2E4035),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFA09E96),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _oyunuBaslat() {
    setState(() {
      _tavsanBaslangicReferansi = DateTime.now();
      _oyunZamani = Duration.zero;
      _ilkEtkilesimYapildi = false;

      _gecikmeSuresi = Duration.zero;
      _gecikmeBaslangicZamani = null;
    });

    _gercekSureKronometresi.start();
    _ticker.start();
    _klavyeOdagi.requestFocus();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _ticker.dispose();
    _efektController.dispose();
    _klavyeOdagi.dispose();
    super.dispose();
  }

  void _hakemKontrolu() {
    if (_oyunZamani.inMilliseconds == 0 || _oyunBitti) return;
    double tavsanKonum = _tavsanAdetKonumu();
    double benimKonum = _tamamlananAdet.toDouble();
    double fark = tavsanKonum - benimKonum;

    if (fark >= 4.0) {
      _oyunuBitir(kazandiMi: false, baslik: "KOPTUN");
    }
  }

  Future<bool> _cikisIstegi() async {
    _ticker.stop();
    _gercekSureKronometresi.stop();



    if (_gecikmeBaslangicZamani != null) {
      Duration buGecikme = DateTime.now().difference(_gecikmeBaslangicZamani!);
      _gecikmeSuresi += buGecikme;
      _gecikmeBaslangicZamani = null;
    }

    DateTime diyalogAcilisZamani = DateTime.now();
    bool sonsuzMod = widget.hedefMiktar == 0;

    String baslik = sonsuzMod ? "BİTİRİYOR MUSUN?" : "KAÇACAK MISIN?";
    String icerik = sonsuzMod
        ? "Gayet iyi ilerledin. Oturumu şimdi sonlandırmak ister misin?"
        : "Oturumu sonlandırmak istediğine emin misin?";

    String negatifButon = sonsuzMod ? "Evet, Bitir" : "Evet, gitmem gerek";
    Color baslikRengi = sonsuzMod
        ? const Color(0xFF2E4035)
        : const Color(0xFFD65A31);

    bool? cikisYapilsinMi = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2EA),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                baslik,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: baslikRengi,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                icerik,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF5C5B57),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4035),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    "HAYIR, DEVAM ET",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA09E96),
                ),
                child: Text(
                  negatifButon,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (cikisYapilsinMi == true) {
      _oyunuBitir(
        kazandiMi: sonsuzMod ? true : false,
        baslik: sonsuzMod ? "OTURUM TAMAMLANDI" : "OTURUM SONA ERDİ",
      );
      return true;
    } else {
      if (_tavsanBaslangicReferansi != null) {
        Duration beklemeSuresi = DateTime.now().difference(diyalogAcilisZamani);
        _tavsanBaslangicReferansi = _tavsanBaslangicReferansi!.add(
          beklemeSuresi,
        );
        _toplamMolaSuresi += beklemeSuresi;
      }
      _ticker.start();
      _gercekSureKronometresi.start();
      return false;
    }
  }

  void _durdur() {
    _gercekSureKronometresi.stop();
    setState(() {
      _duraklatildi = true;
    });


    if (_gecikmeBaslangicZamani != null) {
      Duration buGecikme = DateTime.now().difference(_gecikmeBaslangicZamani!);
      _gecikmeSuresi += buGecikme;
      _gecikmeBaslangicZamani = null;
    }

    DateTime molaBaslangic = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Timer.periodic(const Duration(seconds: 1), (timer) {
              if (!context.mounted) {
                timer.cancel();
              } else {
                setDialogState(() {});
              }
            });

            Duration gecenSure = DateTime.now().difference(molaBaslangic);
            String molaSuresiStr =
                "${gecenSure.inMinutes.toString().padLeft(2, '0')}:${(gecenSure.inSeconds % 60).toString().padLeft(2, '0')}";

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F2EA),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pause_circle_outline,
                      size: 56,
                      color: Color(0xFF2E4035),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "DURAKLATILDI",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD65A31),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Geçen Mola Süresi",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5C5B57),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      molaSuresiStr,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E4035),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tavşan seni bekliyor.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFA09E96),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_tavsanBaslangicReferansi != null) {
                            Duration buMolaSuresi = DateTime.now().difference(
                              molaBaslangic,
                            );
                            _tavsanBaslangicReferansi =
                                _tavsanBaslangicReferansi!.add(buMolaSuresi);
                            _toplamMolaSuresi += buMolaSuresi;
                          }
                          _gercekSureKronometresi.start();
                          setState(() {
                            _duraklatildi = false;
                          });
                          Navigator.pop(context);
                          _klavyeOdagi.requestFocus();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E4035),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "RİTME DÖN",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _birimTamamla() {
    if (_oyunBitti || _duraklatildi) return;

    if (!_ilkEtkilesimYapildi) {
      setState(() {
        _ilkEtkilesimYapildi = true;
        _tamamlananAdet++;

      });
      _efektCalistir();
      return;
    }

    _efektCalistir();


    double tavsanKonumu = _tavsanAdetKonumu();
    double potansiyelYeniBen = (_tamamlananAdet + 1).toDouble();
    double potansiyelFark = potansiyelYeniBen - tavsanKonumu;


    if (potansiyelFark > 4.0) {
      double yeniTavsanKonumu = potansiyelYeniBen - 4.0;
      int yeniMs = (yeniTavsanKonumu * (widget.hedefSureDk * 60).toInt() * 1000)
          .floor();

      _tavsanBaslangicReferansi = DateTime.now().subtract(
        Duration(milliseconds: yeniMs),
      );
      _oyunZamani = Duration(milliseconds: yeniMs);
    }

    setState(() {
      _tamamlananAdet++;
    });

    if (widget.hedefMiktar > 0 && _tamamlananAdet >= widget.hedefMiktar) {
      _oyunuBitir(kazandiMi: true, baslik: "HEDEF TAMAMLANDI");
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



    if (_gecikmeBaslangicZamani != null) {
      Duration buGecikme = DateTime.now().difference(_gecikmeBaslangicZamani!);
      _gecikmeSuresi += buGecikme;
    }


    double toplamGecenSureMs = _gercekSureKronometresi.elapsedMilliseconds
        .toDouble();
    if (toplamGecenSureMs <= 0) toplamGecenSureMs = 1;


    double cezaMs = _gecikmeSuresi.inMilliseconds.toDouble();


    double hamPuan = 100.0 - ((cezaMs / toplamGecenSureMs) * 100);

    if (hamPuan < 0) hamPuan = 0;
    if (hamPuan > 100) hamPuan = 100;

    double akisPuaniYuzde = hamPuan; // Artık gerçek hakimiyet puanı bu.



    int hesaplananAdet = _tamamlananAdet;
    if (baslik == "KOPTUN") {
      hesaplananAdet += 1;
    }

    int gercekSaniye = _gercekSureKronometresi.elapsed.inSeconds;

    await DataManager.oturumKaydet(
      sureSn: gercekSaniye,
      tamamlandi: kazandiMi,
      akisPuani: akisPuaniYuzde,
    );

    String formatSureDetayli(int toplamSn) {
      if (toplamSn < 60) return "$toplamSn sn";
      int dk = toplamSn ~/ 60;
      int sn = toplamSn % 60;
      if (dk > 0) return "$dk dk $sn sn";
      return "$sn sn";
    }

    String gercekGecenSureStr = formatSureDetayli(gercekSaniye);
    String molaSuresiStr = formatSureDetayli(_toplamMolaSuresi.inSeconds);
    double ortalamaSn = hesaplananAdet > 0 ? gercekSaniye / hesaplananAdet : 0;
    String ortalamaHizStr = formatSureDetayli(ortalamaSn.round());

    int beklenenSaniye = (widget.hedefSureDk * 60).toInt() * _tamamlananAdet;
    int farkSaniye = beklenenSaniye - gercekSaniye;
    String performansMesaji = "";

    if (baslik == "HEDEF TAMAMLANDI") {
      if (farkSaniye > 0) {
        performansMesaji =
            "Beklenenden ${formatSureDetayli(farkSaniye)} erken tamamladın.";
      } else {
        performansMesaji =
            "Beklenenden ${formatSureDetayli(farkSaniye.abs())} geç tamamladın.";
      }
    } else if (baslik == "KOPTUN") {
      performansMesaji = "Odağın dağıldı. Tavşan seni geride bıraktı.";
    } else if (baslik == "OTURUM SONA ERDİ" || baslik == "PES ETTİN") {
      performansMesaji = "Oturumu kendi isteğinle sonlandırdın.";
    } else if (baslik == "OTURUM TAMAMLANDI") {
      performansMesaji = "Sonsuz modda harika bir odaklanma sergiledin.";
    } else {
      performansMesaji = "Oturum sona erdi.";
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2EA),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kazandiMi
                      ? const Color(0xFF6B8E23).withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  kazandiMi
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_dissatisfied_rounded,
                  size: 48,
                  color: kazandiMi ? const Color(0xFF6B8E23) : Colors.red,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                baslik,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: kazandiMi
                      ? const Color(0xFF2E4035)
                      : const Color(0xFFD65A31),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                performansMesaji,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5C5B57),
                ),
              ),
              const SizedBox(height: 24),


              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E4035),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      "ZAMAN HAKİMİYETİ",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "%${akisPuaniYuzde.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),


              Row(
                children: [
                  Expanded(
                    child: _buildResultBox(
                      Icons.timer_outlined,
                      gercekGecenSureStr,
                      "Toplam Süre",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildResultBox(
                      Icons.pause_circle_outline,
                      molaSuresiStr,
                      "Mola Süresi",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildResultBox(
                      Icons.speed,
                      ortalamaHizStr,
                      "Ort. Hız",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KarsilamaEkrani(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4035),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "ANA MENÜ",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildResultBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A2E4035)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFA09E96)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: const Color(0xFF2E4035),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: const Color(0xFFA09E96),
            ),
          ),
        ],
      ),
    );
  }

  double _tavsanAdetKonumu() {
    double rawProgress =
        _oyunZamani.inMilliseconds / ((widget.hedefSureDk * 60).toInt() * 1000);
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
    return (_tamamlananAdet >= _tavsanAdetKonumu())
        ? const Color(0xFF6B8E23)
        : const Color(0xFFD65A31);
  }

  Alignment _tavsanRelativePozisyonu() {
    double tavsanYol = _tavsanAdetKonumu();
    double aciRadyan = tavsanYol * (math.pi / 4);
    double finalAci = (-math.pi / 2) + aciRadyan;
    double yaricapOrani = 0.88;
    return Alignment(
      math.cos(finalAci) * yaricapOrani,
      math.sin(finalAci) * yaricapOrani,
    );
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
            child: Container(
              width: 2,
              height: 10,
              color: const Color(0xFFA09E96),
            ),
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
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.space) {
          _birimTamamla();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F2EA),
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () {
            _birimTamamla();
            _klavyeOdagi.requestFocus();
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD65A31).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _durdur();
                      },
                      icon: const Icon(Icons.pause, size: 28),
                      label: Text(
                        "DURDUR",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD65A31),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 32),
                            color: const Color(
                              0xFF2E4035,
                            ).withValues(alpha: 0.5),
                            tooltip: "Çıkış",
                            onPressed: () {
                              _cikisIstegi();
                            },
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 320,
                            height: 320,
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
                                            width: 300,
                                            height: 300,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF2E4035,
                                                ).withValues(alpha: 0.05),
                                                width: 24,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 250,
                                            height: 250,
                                            child: Stack(
                                              children: _buildCeltikler(),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                _tavsanRelativePozisyonu(),
                                            child: Transform.rotate(
                                              angle:
                                                  (_tavsanAdetKonumu() *
                                                  (math.pi / 4)),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFFD65A31,
                                                      ).withValues(alpha: 0.3),
                                                      blurRadius: 20,
                                                      spreadRadius: -5,
                                                    ),
                                                  ],
                                                ),
                                                child: Image.asset(
                                                  'assets/images/tavsan_ikon.png',
                                                  width: 75,
                                                  height: 75,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _farkHesapla(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w900,
                                        color: _durumRengi(),
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2E4035,
                                        ).withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        widget.hedefMiktar > 0
                                            ? "$_tamamlananAdet / ${widget.hedefMiktar}"
                                            : "$_tamamlananAdet",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2E4035),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: const Alignment(0, -0.72),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (_ilkEtkilesimYapildi)
                                        AnimatedBuilder(
                                          animation: _efektController,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity: _efektOpaklik.value,
                                              child: Transform.translate(
                                                offset: Offset(
                                                  -35.0 + _efektHareket.value,
                                                  0,
                                                ),
                                                child: Transform.rotate(
                                                  angle: -math.pi / 2,
                                                  child: const Icon(
                                                    Icons.air,
                                                    size: 30,
                                                    color: Color(0x662E4035),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      Transform.rotate(
                                        angle: math.pi / 2,
                                        child: const Icon(
                                          Icons.navigation,
                                          size: 36,
                                          color: Color(0xFF2E4035),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
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
