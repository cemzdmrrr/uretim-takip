import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:flutter/services.dart';
import 'package:uretim_takip/services/beden_service.dart';
import 'package:uretim_takip/models/beden_models.dart';

/// Beden bazlı üretim girişi dialog'u
class BedenUretimDialog extends StatefulWidget {
  final String modelId;
  final String modelAdi;
  final int atamaId;
  final String asama; // 'dokuma', 'konfeksiyon', vb.
  final int? tedarikciId;

  const BedenUretimDialog({
    super.key,
    required this.modelId,
    required this.modelAdi,
    required this.atamaId,
    required this.asama,
    this.tedarikciId,
  });

  @override
  State<BedenUretimDialog> createState() => _BedenUretimDialogState();
}

class _BedenUretimDialogState extends State<BedenUretimDialog> {
  final BedenService _bedenService = BedenService();
  List<ModelBedenDagilimi> hedefler = [];
  Map<String, BedenUretimTakip> mevcutUretim = {};
  Map<String, TextEditingController> uretilenControllers = {};
  Map<String, TextEditingController> fireControllers = {};
  bool yukleniyor = true;
  bool kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => yukleniyor = true);
    
    try {
      // Mevcut üretim verilerini getir
      final uretimList = await _bedenService.getAsamaBedenTakip(widget.asama, widget.atamaId);
      for (final u in uretimList) {
        mevcutUretim[u.bedenKodu] = u;
      }
      
      // ⭐ ÖNCEKİ AŞAMADAN GELEN HEDEF ADETLERİ (ÖNCELİKLİ)
      // Eğer bu konfeksiyon veya sonraki bir aşamaysa, önceki aşamadan gerçekleşen adetleri al
      if (widget.asama != 'dokuma') {
        try {
          final oncekiAdetler = await _bedenService.getOncekiAsamaGerceklesenAdetler(
            widget.modelId,
            widget.asama,
          );
          
          if (oncekiAdetler.isNotEmpty) {
            debugPrint('✅ ${widget.asama} için önceki aşamadan gelen adetler: $oncekiAdetler');
            // Önceki aşamadan gelen adetleri hedef olarak kullan
            hedefler = oncekiAdetler.entries.map((e) => ModelBedenDagilimi(
              id: 0,
              modelId: widget.modelId,
              bedenKodu: e.key,
              siparisAdedi: e.value, // Fire düşülmüş adet
            )).toList();
            
            // Beden sırasına göre sırala
            hedefler.sort((a, b) {
              const bedenSirasi = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL'];
              final aIndex = bedenSirasi.indexOf(a.bedenKodu);
              final bIndex = bedenSirasi.indexOf(b.bedenKodu);
              if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
              if (aIndex >= 0) return -1;
              if (bIndex >= 0) return 1;
              return a.bedenKodu.compareTo(b.bedenKodu);
            });
          } else {
            debugPrint('⚠️ ${widget.asama} için önceki aşamada henüz üretim tamamlanmamış');
          }
        } catch (e) {
          debugPrint('⚠️ Önceki aşama adetleri alınamadı: $e');
        }
      }
      
      // Eğer hala hedef yoksa, model_beden_dagilimi'dan al (dokuma için veya fallback)
      if (hedefler.isEmpty) {
        hedefler = await _bedenService.getModelBedenDagilimi(widget.modelId);
        debugPrint('model_beden_dagilimi tablosundan: ${hedefler.length} beden bulundu');
      }
      
      // Controller'ları oluştur
      for (final hedef in hedefler) {
        final mevcut = mevcutUretim[hedef.bedenKodu];
        uretilenControllers[hedef.bedenKodu] = TextEditingController(
          text: mevcut?.uretilenAdet.toString() ?? '0',
        );
        fireControllers[hedef.bedenKodu] = TextEditingController(
          text: mevcut?.fireAdet.toString() ?? '0',
        );
      }
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Veri yükleme hatası: $e');
      }
    }
    
    if (mounted) setState(() => yukleniyor = false);
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

  IconData _getAsamaIcon() {
    switch (widget.asama) {
      case 'dokuma': return Icons.grain;
      case 'konfeksiyon': return Icons.content_cut;
      case 'yikama': return Icons.water_drop;
      case 'utu': return Icons.iron;
      case 'ilik_dugme': return Icons.radio_button_checked;
      default: return Icons.precision_manufacturing;
    }
  }

  int _getToplamHedef() {
    return hedefler.fold(0, (sum, h) => sum + h.siparisAdedi);
  }

  int _getToplamUretilen() {
    int toplam = 0;
    for (final c in uretilenControllers.values) {
      toplam += int.tryParse(c.text) ?? 0;
    }
    return toplam;
  }

  int _getToplamFire() {
    int toplam = 0;
    for (final c in fireControllers.values) {
      toplam += int.tryParse(c.text) ?? 0;
    }
    return toplam;
  }

  Future<void> _kaydet() async {
    setState(() => kaydediliyor = true);
    
    try {
      // Beden bazlı üretim verilerini hazırla
      final Map<String, Map<String, int>> bedenVerileri = {};
      
      for (final hedef in hedefler) {
        final uretilen = int.tryParse(uretilenControllers[hedef.bedenKodu]?.text ?? '') ?? 0;
        final fire = int.tryParse(fireControllers[hedef.bedenKodu]?.text ?? '') ?? 0;
        
        bedenVerileri[hedef.bedenKodu] = {
          'hedef_adet': hedef.siparisAdedi,
          'uretilen_adet': uretilen,
          'fire_adet': fire,
        };
      }
      
      // Toplu kaydet
      await _bedenService.updateUretimBedenlerToplu(
        asama: widget.asama,
        atamaId: widget.atamaId,
        bedenVerileri: bedenVerileri,
      );
      
      // ✨ ÖNEMLİ: Aşama tamamlandığında, sonraki aşamaya adet aktar
      debugPrint('🚀 Aşama tamamlandı: ${widget.asama}');
      debugPrint('   Model ID: ${widget.modelId}');
      debugPrint('   Sonraki aşamaya adet transferi başlatılıyor...');
      
      try {
        await _bedenService.updateSonrakiAsamaHedefAdetler(
          modelId: widget.modelId,
          tamamlananAsama: widget.asama,
        );
        debugPrint('   ✅ Adet transferi başarılı!');
      } catch (e, stackTrace) {
        debugPrint('   ⚠️ Adet transferi hatası: $e');
        debugPrint('   Stack trace: $stackTrace');
        // Bu hata kritik değil, devam et
        // ANCAK kullanıcıya göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uyarı: Sonraki aşamaya adet aktarılamadı: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      
      if (mounted) {
        context.showSuccessSnackBar('Üretim verileri kaydedildi');
        Navigator.of(context).pop(true); // true = başarılı
      }
    } catch (e) {
      debugPrint('Kayıt hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Kayıt hatası: $e');
      }
    }
    
    if (mounted) setState(() => kaydediliyor = false);
  }

  void _hepsiniTamamla() {
    for (final hedef in hedefler) {
      uretilenControllers[hedef.bedenKodu]?.text = hedef.siparisAdedi.toString();
    }
    setState(() {});
  }

  void _temizle() {
    for (final c in uretilenControllers.values) {
      c.text = '0';
    }
    for (final c in fireControllers.values) {
      c.text = '0';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final toplamHedef = _getToplamHedef();
    final toplamUretilen = _getToplamUretilen();
    final toplamFire = _getToplamFire();
    final toplamKalan = toplamHedef - toplamUretilen - toplamFire;
    final tamamlanmaOrani = toplamHedef > 0 ? (toplamUretilen / toplamHedef * 100) : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            _buildHeader(),
            
            // İçerik
            Flexible(
              child: yukleniyor
                  ? const LoadingWidget()
                  : hedefler.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Özet kart
                              _buildOzetKart(toplamHedef, toplamUretilen, toplamFire, toplamKalan, tamamlanmaOrani),
                              const SizedBox(height: 16),
                              
                              // Hızlı işlem butonları
                              _buildHizliIslemler(),
                              const SizedBox(height: 16),
                              
                              // Beden tablosu
                              _buildBedenTablosu(),
                            ],
                          ),
                        ),
            ),
            
            // Alt butonlar
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(_getAsamaIcon(), color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getAsamaAdi()} Üretim Girişi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.modelAdi,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            const Text(
              'Bu model için beden dağılımı tanımlanmamış.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Önce sipariş ekranından beden adetlerini girin.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOzetKart(int hedef, int uretilen, int fire, int kalan, double oran) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOzetItem('Hedef', hedef, Colors.blue),
                _buildOzetItem('Üretilen', uretilen, Colors.green),
                _buildOzetItem('Fire', fire, Colors.red),
                _buildOzetItem('Kalan', kalan, kalan <= 0 ? Colors.green : Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            // İlerleme çubuğu
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (oran / 100).clamp(0, 1),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        oran >= 100 ? Colors.green : Colors.blue,
                      ),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '%${oran.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: oran >= 100 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOzetItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildHizliIslemler() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('Temizle'),
          onPressed: _temizle,
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.done_all, size: 18),
          label: const Text('Hepsini Tamamla'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: _hepsiniTamamla,
        ),
      ],
    );
  }

  Widget _buildBedenTablosu() {
    return Card(
      elevation: 1,
      child: Column(
        children: [
          // Tablo başlığı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('Beden', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Hedef', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Üretilen Adet', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Fire', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Kalan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
          // Beden satırları
          ...hedefler.map((hedef) => _buildBedenSatiri(hedef)),
        ],
      ),
    );
  }

  Widget _buildBedenSatiri(ModelBedenDagilimi hedef) {
    final uretilen = int.tryParse(uretilenControllers[hedef.bedenKodu]?.text ?? '') ?? 0;
    final fire = int.tryParse(fireControllers[hedef.bedenKodu]?.text ?? '') ?? 0;
    final kalan = hedef.siparisAdedi - uretilen - fire;
    final tamamlandi = kalan <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: tamamlandi ? Colors.green.shade50 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Beden
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tamamlandi ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(6),
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
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
          
          // Üretilen
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: uretilenControllers[hedef.bedenKodu],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          
          // Fire
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: fireControllers[hedef.bedenKodu],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  isDense: true,
                  filled: true,
                  fillColor: fire > 0 ? Colors.red.shade50 : Colors.white,
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: fire > 0 ? Colors.red : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          
          // Kalan
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: kalan <= 0 
                    ? Colors.green.withValues(alpha: 0.2) 
                    : kalan < 0 
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                kalan.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kalan <= 0 ? Colors.green : kalan < 0 ? Colors.red : Colors.orange.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: kaydediliyor ? null : () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: kaydediliyor 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(kaydediliyor ? 'Kaydediliyor...' : 'Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: kaydediliyor ? null : _kaydet,
          ),
        ],
      ),
    );
  }
}

/// Beden üretim dialog'unu açan yardımcı fonksiyon
Future<bool?> showBedenUretimDialog(
  BuildContext context, {
  required String modelId,
  required String modelAdi,
  required int atamaId,
  required String asama,
  int? tedarikciId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => BedenUretimDialog(
      modelId: modelId,
      modelAdi: modelAdi,
      atamaId: atamaId,
      asama: asama,
      tedarikciId: tedarikciId,
    ),
  );
}
