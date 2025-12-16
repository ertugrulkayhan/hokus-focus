import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart'; // YENİ EKLENDİ: Klavye için gerekli

void main() {
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
      home: const KurulumEkrani(),
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

  void _baslat() {
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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("RİTİM KALİBRASYONU", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E4035))),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4DA09E96)),
                ),
                child: const Text(
                  "Kendine bir birim belirle (1 Soru, 1 Sayfa vb.).\nAcele etmeden, en rahat hızında bu işi yap ve geçen süreyi aşağıya gir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF2E4035), fontSize: 14, height: 1.5),
                ),
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
            ],
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
  Duration _gecenSure = Duration.zero;
  int _tamamlananAdet = 0;
  late DateTime _baslangicZamani;
  bool _oyunBitti = false;
  bool _duraklatildi = false;

  // YENİ EKLENDİ: KLAVYE ODAGI
  final FocusNode _klavyeOdagi = FocusNode();

  // Rüzgar Efekti için Kontrolcü
  late AnimationController _efektController;
  late Animation<double> _efektOpaklik;
  late Animation<double> _efektHareket;

  @override
  void initState() {
    super.initState();
    _baslangicZamani = DateTime.now();

    // Rüzgar Efekti
    _efektController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _efektOpaklik = Tween<double>(begin: 0.0, end: 0.0).animate(_efektController);
    _efektHareket = Tween<double>(begin: 0.0, end: -40.0).animate(_efektController);

    _ticker = createTicker((elapsed) {
      if (_oyunBitti || _duraklatildi) return;
      setState(() {
        _gecenSure = DateTime.now().difference(_baslangicZamani);
      });
      _hakemKontrolu();
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _efektController.dispose();
    _klavyeOdagi.dispose(); // ODAĞI KAPAT
    super.dispose();
  }

  void _hakemKontrolu() {
    double fark = _tavsanAdetKonumu() - _tamamlananAdet;
    if (fark >= 4.0) {
      _oyunuBitir(kazandiMi: false);
    }
  }

  void _durdur() {
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
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E4035),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
              ),
              onPressed: () {
                _baslangicZamani = DateTime.now().subtract(_gecenSure);
                setState(() {
                  _duraklatildi = false;
                });
                Navigator.pop(context);
                
                // Pop-up kapanınca odağı tekrar klavyeye veriyoruz
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

    // RÜZGAR EFEKTİNİ TETİKLE
    _efektController.reset();
    _efektOpaklik = Tween<double>(begin: 0.8, end: 0.0).animate(CurvedAnimation(parent: _efektController, curve: Curves.easeOut));
    _efektHareket = Tween<double>(begin: 0.0, end: -50.0).animate(CurvedAnimation(parent: _efektController, curve: Curves.easeOut));
    _efektController.forward();

    // STOK LİMİTİ (TAM 4 BİRİM)
    double potansiyelYeniBen = (_tamamlananAdet + 1).toDouble();
    double potansiyelFark = potansiyelYeniBen - _tavsanAdetKonumu();

    if (potansiyelFark > 4.0) {
      double yeniTavsanKonumu = potansiyelYeniBen - 4.0;
      int yeniMs = (yeniTavsanKonumu * widget.birimSureSn * 1000).floor();
      _baslangicZamani = DateTime.now().subtract(Duration(milliseconds: yeniMs));
      _gecenSure = Duration(milliseconds: yeniMs);
      
      setState(() {
        _tamamlananAdet++;
      });
      
      if (_tamamlananAdet >= widget.hedefSayi) {
        _oyunuBitir(kazandiMi: true);
      }
      return; 
    }

    if (_tamamlananAdet < widget.hedefSayi) {
      setState(() {
        _tamamlananAdet++;
      });
      if (_tamamlananAdet >= widget.hedefSayi) {
        _oyunuBitir(kazandiMi: true);
      }
    }
  }

  void _oyunuBitir({required bool kazandiMi}) {
    _oyunBitti = true;
    _ticker.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EA),
        title: Text(kazandiMi ? "HEDEF TAMAMLANDI" : "RİTMİ KAYBETTİN ⚠️", 
          style: TextStyle(color: kazandiMi ? const Color(0xFF2E4035) : Colors.red, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          kazandiMi 
            ? "Planlanan miktar işlendi. Ritim korundu." 
            : "Odağın dağıldı. Tavşan seni geride bıraktı.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E4035), foregroundColor: Colors.white),
              child: const Text("TAMAM"),
            ),
          )
        ],
      ),
    );
  }

  double _tavsanAdetKonumu() {
    return _gecenSure.inMilliseconds / (widget.birimSureSn * 1000);
  }

  String _farkHesapla() {
    double farkAdet = _tamamlananAdet - _tavsanAdetKonumu();
    if (farkAdet > 4.0) farkAdet = 4.0;
    int farkSaniye = (farkAdet * widget.birimSureSn).round(); 
    String isaret = farkSaniye >= 0 ? "+" : "-";
    int mutlakSaniye = farkSaniye.abs();
    return "$isaret ${mutlakSaniye ~/ 60}:${(mutlakSaniye % 60).toString().padLeft(2, '0')}";
  }

  Color _durumRengi() {
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
            child: Container(
              width: 2, height: 10, color: const Color(0xFFA09E96),
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

    // YENİ EKLENDİ: KEYBOARD LISTENER
    return KeyboardListener(
      focusNode: _klavyeOdagi,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
          _birimTamamla();
        }
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: FloatingActionButton.extended(
            onPressed: _durdur,
            backgroundColor: const Color(0xFFD65A31), 
            icon: const Icon(Icons.pause, color: Colors.white),
            label: const Text("DURDUR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ÜST BÖLÜM (Slogan & Çıkış)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("KAÇIRMA KAPTIRMA KAPATMA", 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 3, color: Color(0xFFA09E96))),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.close, color: Color(0xFFA09E96)), onPressed: () => Navigator.pop(context)),
                        const SizedBox(width: 24), 
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: GestureDetector(
                  onTap: _birimTamamla,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 360, height: 360,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // ------------------------------
                            // KATMAN 1: DÖNEN DÜNYA
                            // ------------------------------
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
                                      // YÖRÜNGE ÇEMBERİ
                                      Container(
                                        width: 280, height: 280,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle, 
                                          border: Border.all(color: const Color(0x4DA09E96), width: 2)
                                        ),
                                        child: Stack(children: _buildCeltikler()),
                                      ),
                                      
                                      // TAVŞAN 
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
                            
                            // ------------------------------
                            // KATMAN 2: RÜZGAR EFEKTİ
                            // ------------------------------
                            AnimatedBuilder(
                              animation: _efektController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _efektOpaklik.value,
                                  child: Transform.translate(
                                    offset: Offset(_efektHareket.value, -0.83 * 140), 
                                    child: Transform.rotate(
                                      angle: -math.pi / 2, 
                                      child: const Icon(Icons.air, size: 50, color: Color(0x662E4035)), 
                                    ),
                                  ),
                                );
                              },
                            ),

                            // ------------------------------
                            // KATMAN 3: SEN (OK İMLECİ - SABİT)
                            // ------------------------------
                            Align(
                              alignment: const Alignment(0, -0.83), 
                              child: Transform.rotate(
                                angle: math.pi / 2, 
                                child: const Icon(Icons.navigation, size: 32, color: Color(0xFF2E4035)),
                              ), 
                            ),

                            // ------------------------------
                            // KATMAN 4: ORTA SAYAÇ
                            // ------------------------------
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
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}