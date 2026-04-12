import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:flutter/services.dart';
import 'package:uretim_takip/models/beden_models.dart';
import 'package:uretim_takip/services/beden_service.dart';

/// Beden bazlı adet girişi widget'ı
class BedenAdetGirisi extends StatefulWidget {
  final String modelId;
  final String? baslik;
  final bool readOnly;
  final Function(Map<String, int> bedenAdetleri)? onChanged;
  final Map<String, int>? initialValues;

  const BedenAdetGirisi({
    super.key,
    required this.modelId,
    this.baslik,
    this.readOnly = false,
    this.onChanged,
    this.initialValues,
  });

  @override
  State<BedenAdetGirisi> createState() => _BedenAdetGirisiState();
}

class _BedenAdetGirisiState extends State<BedenAdetGirisi> {
  final BedenService _bedenService = BedenService();
  List<BedenTanimi> bedenler = [];
  Map<String, TextEditingController> controllers = {};
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => yukleniyor = true);
    
    // Beden tanımlarını yükle
    bedenler = await _bedenService.getBedenTanimlari();
    
    // Mevcut değerleri yükle
    Map<String, int> mevcutDegerler = {};
    
    if (widget.initialValues != null) {
      mevcutDegerler = widget.initialValues!;
    } else {
      // Model için kayıtlı beden dağılımını getir
      final dagilim = await _bedenService.getModelBedenDagilimi(widget.modelId);
      for (final d in dagilim) {
        mevcutDegerler[d.bedenKodu] = d.siparisAdedi;
      }
    }
    
    // Controller'ları oluştur
    for (final beden in bedenler) {
      controllers[beden.bedenKodu] = TextEditingController(
        text: mevcutDegerler[beden.bedenKodu]?.toString() ?? '',
      );
    }
    
    setState(() => yukleniyor = false);
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, int> _getBedenAdetleri() {
    final result = <String, int>{};
    for (final entry in controllers.entries) {
      final adet = int.tryParse(entry.value.text) ?? 0;
      if (adet > 0) {
        result[entry.key] = adet;
      }
    }
    return result;
  }

  int _getToplamAdet() {
    int toplam = 0;
    for (final controller in controllers.values) {
      toplam += int.tryParse(controller.text) ?? 0;
    }
    return toplam;
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const LoadingWidget();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(Icons.straighten, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  widget.baslik ?? 'Beden Adetleri',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Toplam: ${_getToplamAdet()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Beden giriş alanları - Grid şeklinde
            LayoutBuilder(
              builder: (context, constraints) {
                // Ekran genişliğine göre sütun sayısı
                int crossAxisCount = 3;
                if (constraints.maxWidth > 600) crossAxisCount = 4;
                if (constraints.maxWidth > 900) crossAxisCount = 6;
                
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: bedenler.map((beden) {
                    return SizedBox(
                      width: (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount,
                      child: _buildBedenInput(beden),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedenInput(BedenTanimi beden) {
    final controller = controllers[beden.bedenKodu];
    final hasValue = (int.tryParse(controller?.text ?? '') ?? 0) > 0;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: hasValue ? Colors.blue : Colors.grey.shade300,
          width: hasValue ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: hasValue ? Colors.blue.shade50 : Colors.white,
      ),
      child: Column(
        children: [
          // Beden etiketi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: hasValue ? Colors.blue : Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Text(
              beden.bedenKodu,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasValue ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
          // Adet girişi
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: controller,
              enabled: !widget.readOnly,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasValue ? Colors.blue.shade800 : Colors.grey,
              ),
              onChanged: (value) {
                setState(() {});
                widget.onChanged?.call(_getBedenAdetleri());
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Üretim aşaması için beden adet girişi (hedef ve üretilen ayrı)
class UretimBedenGirisi extends StatefulWidget {
  final String modelId;
  final int atamaId;
  final String asama; // 'dokuma', 'konfeksiyon', vb.
  final Function(Map<String, int> uretilenler, Map<String, int> fireler)? onChanged;

  const UretimBedenGirisi({
    super.key,
    required this.modelId,
    required this.atamaId,
    required this.asama,
    this.onChanged,
  });

  @override
  State<UretimBedenGirisi> createState() => _UretimBedenGirisiState();
}

class _UretimBedenGirisiState extends State<UretimBedenGirisi> {
  final BedenService _bedenService = BedenService();
  List<ModelBedenDagilimi> hedefler = [];
  Map<String, BedenUretimTakip> mevcutUretim = {};
  Map<String, TextEditingController> uretilenControllers = {};
  Map<String, TextEditingController> fireControllers = {};
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => yukleniyor = true);
    
    try {
      // Hedef beden dağılımını getir
      hedefler = await _bedenService.getModelBedenDagilimi(widget.modelId);
      
      // Mevcut üretim verilerini getir
      final uretimList = await _bedenService.getAsamaBedenTakip(widget.asama, widget.atamaId);
      for (final u in uretimList) {
        mevcutUretim[u.bedenKodu] = u;
      }
      
      // Controller'ları oluştur
      for (final hedef in hedefler) {
        final mevcut = mevcutUretim[hedef.bedenKodu];
        uretilenControllers[hedef.bedenKodu] = TextEditingController(
          text: mevcut?.uretilenAdet.toString() ?? '',
        );
        fireControllers[hedef.bedenKodu] = TextEditingController(
          text: mevcut?.fireAdet.toString() ?? '',
        );
      }
    } catch (e) {
      debugPrint('UretimBedenGirisi yükleme hatası: $e');
    }
    
    setState(() => yukleniyor = false);
  }

  @override
  void dispose() {
    for (final c in uretilenControllers.values) {
      c.dispose();
    }
    for (final c in fireControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, int> _getUretilenler() {
    final result = <String, int>{};
    for (final entry in uretilenControllers.entries) {
      result[entry.key] = int.tryParse(entry.value.text) ?? 0;
    }
    return result;
  }

  Map<String, int> _getFireler() {
    final result = <String, int>{};
    for (final entry in fireControllers.entries) {
      result[entry.key] = int.tryParse(entry.value.text) ?? 0;
    }
    return result;
  }

  String _getAsamaAdi() {
    switch (widget.asama) {
      case 'dokuma': return 'Dokuma/Örme';
      case 'konfeksiyon': return 'Konfeksiyon';
      case 'yikama': return 'Yıkama';
      case 'utu': return 'Ütü';
      case 'ilik_dugme': return 'İlik Düğme';
      default: return widget.asama;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const LoadingWidget();
    }

    if (hedefler.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.warning_amber, size: 48, color: Colors.orange.shade300),
              const SizedBox(height: 12),
              const Text(
                'Bu model için beden dağılımı tanımlanmamış.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Önce sipariş ekranından beden adetlerini girin.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Icon(Icons.precision_manufacturing, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  '${_getAsamaAdi()} Üretim Girişi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tablo başlıkları
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 1, child: Text('Beden', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Hedef', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Üretilen', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Fire', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Kalan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Beden satırları
            ...hedefler.map((hedef) => _buildBedenRow(hedef)),
            
            const SizedBox(height: 16),
            
            // Toplam satırı
            _buildToplamRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildBedenRow(ModelBedenDagilimi hedef) {
    final uretilenController = uretilenControllers[hedef.bedenKodu];
    final fireController = fireControllers[hedef.bedenKodu];
    final uretilen = int.tryParse(uretilenController?.text ?? '') ?? 0;
    final fire = int.tryParse(fireController?.text ?? '') ?? 0;
    final kalan = hedef.siparisAdedi - uretilen - fire;
    
    Color kalanRenk = Colors.grey;
    if (kalan == 0) {
      kalanRenk = Colors.green;
    }
    else if (kalan < 0) {
      kalanRenk = Colors.red;
    }
    else if (kalan > 0) {
      kalanRenk = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: uretilen > 0 ? Colors.green.shade50 : Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Beden
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hedef.bedenKodu,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Hedef
          Expanded(
            flex: 1,
            child: Text(
              hedef.siparisAdedi.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          
          // Üretilen
          Expanded(
            flex: 2,
            child: TextField(
              controller: uretilenController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {});
                widget.onChanged?.call(_getUretilenler(), _getFireler());
              },
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Fire
          Expanded(
            flex: 1,
            child: TextField(
              controller: fireController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
                fillColor: Colors.red.shade50,
                filled: fire > 0,
              ),
              style: TextStyle(color: fire > 0 ? Colors.red : null),
              onChanged: (value) {
                setState(() {});
                widget.onChanged?.call(_getUretilenler(), _getFireler());
              },
            ),
          ),
          
          // Kalan
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: kalanRenk.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                kalan.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kalanRenk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToplamRow() {
    int toplamHedef = 0;
    int toplamUretilen = 0;
    int toplamFire = 0;
    
    for (final hedef in hedefler) {
      toplamHedef += hedef.siparisAdedi;
      toplamUretilen += int.tryParse(uretilenControllers[hedef.bedenKodu]?.text ?? '') ?? 0;
      toplamFire += int.tryParse(fireControllers[hedef.bedenKodu]?.text ?? '') ?? 0;
    }
    
    final toplamKalan = toplamHedef - toplamUretilen - toplamFire;
    final tamamlanmaOrani = toplamHedef > 0 ? (toplamUretilen / toplamHedef * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToplamItem('Hedef', toplamHedef, Colors.grey),
              _buildToplamItem('Üretilen', toplamUretilen, Colors.green),
              _buildToplamItem('Fire', toplamFire, Colors.red),
              _buildToplamItem('Kalan', toplamKalan, Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          // İlerleme çubuğu
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tamamlanma', style: TextStyle(fontSize: 12)),
                  Text('${tamamlanmaOrani.toStringAsFixed(1)}%', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: tamamlanmaOrani / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  tamamlanmaOrani >= 100 ? Colors.green : Colors.blue,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToplamItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
