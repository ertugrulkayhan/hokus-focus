import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const HokusFocusApp());
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
class KarsilamaEkrani extends StatelessWidget {
  const KarsilamaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity, 
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                const Text(
                  "HokusFocus v1.1",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Serif', 
                    fontStyle: FontStyle.italic, 
                    fontSize: 48, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -1.0, 
                    color: Color(0xFF2E4035),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "KAÇIRMA - KASMA - KOPMA",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 2.0, 
                    color: Color(0xFFD65A31)
                  ),
                ),
                
                const SizedBox(height: 40),
                
                const Text(
                  "Odaklanmak için uğraşma.\nSen sadece ritme eşlik et,\nZihnin odaklanmak zorunda kalacak...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF2E4035), height: 1.5, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 40),

                const Text(
                  "NASIL ÇALIŞIR?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1, color: Color(0xFF2E4035)),
                ),
                const SizedBox(height: 15),
                _buildOrtaliMetin("1. ÖLÇ", "1 birim işi en rahat hızında ne kadar sürede yapıyorsun? Süreyi gir."),
                const SizedBox(height: 15),
                _buildOrtaliMetin("2. BAS", "Her birimi bitirdiğinde ekrana dokun."),
                const SizedBox(height: 15),
                _buildOrtaliMetin("3. DENGELE", "Tavşanla arandaki mesafeyi koru."),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 25.0),
                  child: Divider(color: Color(0x40A09E96), endIndent: 50, indent: 50),
                ),

                const Text(
                  "KURALIMIZ NET:",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1, color: Color(0xFFD65A31)),
                ),
                const SizedBox(height: 15),
                _buildOrtaliKural("Rehavete kapılıp ritmi", "KAÇIRMA."),
                const SizedBox(height: 8),
                _buildOrtaliKural("Acele edip kendini", "KASMA."),
                const SizedBox(height: 8),
                _buildOrtaliKural("Yarıda bırakıp odaktan", "KOPMA."), 
                
                const SizedBox(height: 50),
                
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => const KurulumEkrani())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4035),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                    shadowColor: const Color(0x40000000),
                  ),
                  child: const Text("BAŞLA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrtaliMetin(String baslik, String icerik) {
    return Column(
      children: [
        Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035), fontSize: 14)),
        const SizedBox(height: 4),
        Text(icerik, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF5C5B57), fontSize: 14, height: 1.3)),
      ],
    );
  }

  Widget _buildOrtaliKural(String onEk, String kelime) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(fontSize: 15, color: Color(0xFF2E4035), fontFamily: 'Courier'),
        children: [
          TextSpan(text: "$onEk "),
          TextSpan(text: kelime, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ----------------------------------------
// 1. EKRAN: KURULUM
// ----------------------------------------
class KurulumEkrani extends StatefulWidget {
  const KurulumEkrani({super.key});

  @override
  State<KurulumEkrani> createState() => _KurulumEkraniState();
}

class _KurulumEkraniState extends State<KurulumEkrani> {
  final TextEditingController _dkController = TextEditingController();
  final TextEditingController _snController = TextEditingController();
  final TextEditingController _hedefController = TextEditingController();

  @override
  void dispose() {
    _dkController.dispose();
    _snController.dispose();
    _hedefController.dispose();
    super.dispose();
  }

  void _baslat() {
    FocusScope.of(context).unfocus();
    int dakika = int.tryParse(_dkController.text) ?? 0;
    int saniye = int.tryParse(_snController.text) ?? 0;
    int hedef = int.tryParse(_hedefController.text) ?? 0;
    int birimSureSaniye = (dakika * 60) + saniye;

    if (birimSureSaniye <= 0 || hedef <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen geçerli değerler girin.")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KokpitEkrani(
          birimSureSn: birimSureSaniye,
          hedefSayi: hedef,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // resizeToAvoidBottomInset: Klavye çıkınca ekranı sıkıştırır, kapatınca açar.
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E4035)),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KarsilamaEkrani())),
        ),
      ),
      body: GestureDetector(
        // Ekrana dokununca klavyeyi kapatır (Focus'u alır)
        onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
                FocusManager.instance.primaryFocus?.unfocus();
            }
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity, // Tüm ekranı kapla
          child: SingleChildScrollView(
            // physics: ClampingScrollPhysics(), // Yaylanmayı kapatır (Bazen görsel hatayı çözer)
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20), // Üst boşluk
                const Text("RİTİM KALİBRASYONU", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E4035))),
                const SizedBox(height: 16),
                const Text(
                  "Kendine bir birim belirle (1 Soru, 1 Sayfa vb.).\nAcele etmeden, en rahat hızında bu işi yap ve geçen süreyi gir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF5C5B57), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 40),
                const Align(alignment: Alignment.centerLeft, child: Text("1 Birim Süresi", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035)))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _dkController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration("DK"))),
                    const SizedBox(width: 10),
                    const Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _snController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration("SN"))),
                  ],
                ),
                const SizedBox(height: 24),
                const Align(alignment: Alignment.centerLeft, child: Text("Hedef Miktar (Adet)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035)))),
                const SizedBox(height: 8),
                TextField(controller: _hedefController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration("Sayfa/Soru vb.")),
                const SizedBox(height: 50),
                SizedBox(
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
                const SizedBox(height: 40), // Alt boşluk (Klavye payı için güvenli alan)
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, 
      hintStyle: TextStyle(color: const Color(0xFFA09E96).withOpacity(0.5), fontSize: 14),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
    );
  }
}

// ----------------------------------------
// 2. EKRAN: KOKPİT
// ----------------------------------------
class KokpitEkrani extends StatefulWidget {
  final int birimSureSn;
  final int hedefSayi;
  const KokpitEkrani({super.key, required this.birimSureSn, required this.hedefSayi});

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

  // Akış Puanı Hesaplama
  double _toplamUyumlulukPuani = 0.0; 

  late AnimationController _efektController;
  late Animation<double> _efektOpaklik;
  late Animation<double> _efektHareket;

  @override
  void initState() {
    super.initState();
    _gercekSureKronometresi.start(); 

    _efektController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _efektOpaklik = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _efektController, curve: Curves.easeOut)
    );
    
    _efektHareket = Tween<double>(begin: 0.0, end: -40.0).animate(
      CurvedAnimation(parent: _efektController, curve: Curves.easeOut)
    );

    _ticker = createTicker((elapsed) {
      if (_oyunBitti || _duraklatildi) return;
      if (_ilkEtkilesimYapildi && _tavsanBaslangicReferansi != null) {
        setState(() {
          _oyunZamani = DateTime.now().difference(_tavsanBaslangicReferansi!);
        });
        _hakemKontrolu();
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _efektController.dispose();
    _klavyeOdagi.dispose();
    super.dispose();
  }

  void _hakemKontrolu() {
    if (!_ilkEtkilesimYapildi) return;
    double fark = _tavsanAdetKonumu() - _tamamlananAdet;
    if (fark >= 4.0) {
      _oyunuBitir(kazandiMi: false, baslik: "KOPTUN");
    }
  }

  void _cikisSor() {
    _gercekSureKronometresi.stop();
    setState(() {
      _duraklatildi = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: const Text("KAÇACAK MISIN?", 
          style: TextStyle(color: Color(0xFFD65A31), fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "Oturumu sonlandırmak istediğine emin misin?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
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
    setState(() {
      _duraklatildi = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: const Text("NEDEN DURDUN?", 
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "Akış bozuldu. Odak soğuyor.\nBu yaptığın ritme ihanet.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E4035),
                foregroundColor: Colors.white,
              ),
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
        _tavsanBaslangicReferansi = DateTime.now(); 
        _oyunZamani = Duration.zero;
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
      int yeniMs = (yeniTavsanKonumu * widget.birimSureSn * 1000).floor();
      _tavsanBaslangicReferansi = DateTime.now().subtract(Duration(milliseconds: yeniMs));
      _oyunZamani = Duration(milliseconds: yeniMs);
      setState(() { _tamamlananAdet++; });
      if (_tamamlananAdet >= widget.hedefSayi) _oyunuBitir(kazandiMi: true, baslik: "HEDEF TAMAMLANDI");
      return; 
    }

    if (_tamamlananAdet < widget.hedefSayi) {
      setState(() { _tamamlananAdet++; });
      if (_tamamlananAdet >= widget.hedefSayi) _oyunuBitir(kazandiMi: true, baslik: "HEDEF TAMAMLANDI");
    }
  }

  void _efektCalistir() {
    _efektController.reset();
    _efektController.forward();
  }

  void _oyunuBitir({required bool kazandiMi, required String baslik}) {
    _oyunBitti = true;
    _ticker.stop();
    _gercekSureKronometresi.stop(); 

    int gercekSaniye = _gercekSureKronometresi.elapsed.inSeconds;
    int beklenenSaniye = widget.birimSureSn * _tamamlananAdet; 
    int farkSaniye = beklenenSaniye - gercekSaniye;
    
    String performansMesaji = "";
    if (baslik == "HEDEF TAMAMLANDI") {
        if (farkSaniye > 0) {
        int dk = farkSaniye ~/ 60;
        int sn = farkSaniye % 60;
        performansMesaji = "Beklenenden ${dk > 0 ? '$dk dk ' : ''}$sn sn erken tamamladın.";
        } else {
        int mutlakFark = farkSaniye.abs();
        int dk = mutlakFark ~/ 60;
        int sn = mutlakFark % 60;
        performansMesaji = "Beklenenden ${dk > 0 ? '$dk dk ' : ''}$sn sn geç tamamladın.";
        }
    } else if (baslik == "KOPTUN") {
        performansMesaji = "Odağın dağıldı. Tavşan seni geride bıraktı.";
    } else {
        performansMesaji = "Oturumu kendi isteğinle sonlandırdın.";
    }

    Duration gercekGecenSure = _gercekSureKronometresi.elapsed;
    String sureStr = "${gercekGecenSure.inMinutes}:${(gercekGecenSure.inSeconds % 60).toString().padLeft(2, '0')}";
    double ortalamaSn = _tamamlananAdet > 0 ? gercekGecenSure.inMilliseconds / _tamamlananAdet / 1000 : 0;
    
    double akisPuaniYuzde = _tamamlananAdet > 0 
        ? (_toplamUyumlulukPuani / _tamamlananAdet) * 100 
        : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: Text(baslik, 
          style: TextStyle(
            color: (baslik == "HEDEF TAMAMLANDI") ? const Color(0xFF2E4035) : Colors.red, 
            fontWeight: FontWeight.bold, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              performansMesaji,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: (baslik == "HEDEF TAMAMLANDI") ? const Color(0xFF2E4035) : Colors.black54),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Süre:", style: TextStyle(color: Color(0xFFA09E96))),
                Text(sureStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035))),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Ort. Hız:", style: TextStyle(color: Color(0xFFA09E96))),
                Text("${ortalamaSn.toStringAsFixed(1)} sn", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4035))),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Akış Puanı:", style: TextStyle(color: Color(0xFFA09E96))),
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

  double _tavsanAdetKonumu() {
    if (!_ilkEtkilesimYapildi) return 0.0;
    return _oyunZamani.inMilliseconds / (widget.birimSureSn * 1000);
  }

  String _farkHesapla() {
    if (!_ilkEtkilesimYapildi) return "00:00";
    double farkAdet = _tamamlananAdet - _tavsanAdetKonumu();
    if (farkAdet > 4.0) farkAdet = 4.0;
    int farkSaniye = (farkAdet * widget.birimSureSn).round(); 
    String isaret = farkSaniye >= 0 ? "+" : "-";
    int mutlakSaniye = farkSaniye.abs();
    return "$isaret ${mutlakSaniye ~/ 60}:${(mutlakSaniye % 60).toString().padLeft(2, '0')}";
  }

  Color _durumRengi() {
    if (!_ilkEtkilesimYapildi) return const Color(0xFFA09E96);
    return (_tamamlananAdet >= _tavsanAdetKonumu()) ? const Color(0xFF6B8E23) : const Color(0xFFD65A31);
  }

  Alignment _tavsanRelativePozisyonu() {
    double tavsanYol = _tavsanAdetKonumu();
    double aciRadyan = tavsanYol * (math.pi / 4);
    double finalAci = (-math.pi / 2) + aciRadyan;
    double yaricapOrani = 0.90; 
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
                                          Align(
                                            alignment: _tavsanRelativePozisyonu(), 
                                            child: Transform.rotate(
                                              angle: -val, 
                                              child: const Icon(Icons.cruelty_free, size: 32, color: Color(0xFF2E4035)),
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
                                      // RÜZGAR EFEKTİ (DÜZELTME: SADECE BAŞLADIYSA GÖZÜKÜR)
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
                                    Text("$_tamamlananAdet / ${widget.hedefSayi}", style: const TextStyle(fontSize: 24, color: Color(0xFFA09E96))),
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
