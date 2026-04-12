part of 'uretim_asama_dashboard.dart';

// Arama Delegate sınıfı
class _AsamaModelAramaDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> tumModeller;
  final Color asamaRengi;

  _AsamaModelAramaDelegate({
    required this.tumModeller,
    required this.asamaRengi,
  });

  @override
  String get searchFieldLabel => 'Model ara...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = tumModeller.where((atama) {
      final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
      if (model == null) return false;
      final marka = (model['marka'] ?? '').toString().toLowerCase();
      final itemNo = (model['item_no'] ?? '').toString().toLowerCase();
      final renk = (model['renk'] ?? '').toString().toLowerCase();
      final q = query.toLowerCase();
      return marka.contains(q) || itemNo.contains(q) || renk.contains(q);
    }).take(10).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final atama = suggestions[index];
        final model = atama[DbTables.trikoTakip] as Map<String, dynamic>;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: asamaRengi,
            child: const Icon(Icons.inventory, color: Colors.white),
          ),
          title: Text('${model['marka']} - ${model['item_no']}'),
          subtitle: Text('Renk: ${model['renk']} • Adet: ${model['adet']}'),
          onTap: () => close(context, model['item_no'] ?? model['marka'] ?? ''),
        );
      },
    );
  }
}

// ==========================================
// BEDEN BAZLI ÜRETİM TAMAMLA DİALOG - GENERIC
// ==========================================
class _BedenUretimTamamlaDialogGeneric extends StatefulWidget {
  final String modelId;
  final String modelAdi;
  final int atamaId;
  final Map<String, dynamic> atama;
  final Map<String, dynamic> model;
  final SupabaseClient supabase;
  final String asamaAdi;
  final String asamaDisplayName;
  final String atamaTablosu;
  final Color asamaRengi;
  final VoidCallback onComplete;
  final Future<void> Function(Map<String, dynamic>, {required int tamamlananAdet}) onKaliteKontrolOlustur;
  final Future<void> Function(Map<String, dynamic>, {required int tamamlananAdet}) onSevkiyatOlustur;

  const _BedenUretimTamamlaDialogGeneric({
    required this.modelId,
    required this.modelAdi,
    required this.atamaId,
    required this.atama,
    required this.model,
    required this.supabase,
    required this.asamaAdi,
    required this.asamaDisplayName,
    required this.atamaTablosu,
    required this.asamaRengi,
    required this.onComplete,
    required this.onKaliteKontrolOlustur,
    required this.onSevkiyatOlustur,
  });

  @override
  State<_BedenUretimTamamlaDialogGeneric> createState() => _BedenUretimTamamlaDialogGenericState();
}

class _BedenUretimTamamlaDialogGenericState extends State<_BedenUretimTamamlaDialogGeneric> {
  final BedenService _bedenService = BedenService();
  List<ModelBedenDagilimi> hedefler = [];
  Map<String, TextEditingController> uretilenControllers = {};
  Map<String, TextEditingController> fireControllers = {};
  final notlarController = TextEditingController();
  bool yukleniyor = true;
  bool kaydediliyor = false;
  bool bedenTablosuVar = true;
  bool firedenDus = false; // Fire miktarını adetten düşmek için checkbox işaretlenmeli

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => yukleniyor = true);
    
    try {
      // ⭐ ÖNEMLİ: Dokuma hariç tüm aşamalar için önceki aşamadan fire düşülmüş adetleri al
      if (widget.asamaAdi != 'dokuma') {
        debugPrint('🔄 ${widget.asamaAdi} için önceki aşamadan adetler alınıyor...');
        final oncekiAdetler = await _bedenService.getOncekiAsamaGerceklesenAdetler(
          widget.modelId,
          widget.asamaAdi,
        );
        
        if (oncekiAdetler.isNotEmpty) {
          debugPrint('✅ Önceki aşamadan ${oncekiAdetler.length} beden alındı: $oncekiAdetler');
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
          bedenTablosuVar = true;
        } else {
          debugPrint('⚠️ Önceki aşamadan adet bulunamadı, model_beden_dagilimi kullanılacak');
        }
      }
      
      // Dokuma için veya önceki aşamadan adet alınamazsa:
      // 1. Önce model_beden_dagilimi tablosundan dene
      if (hedefler.isEmpty) {
        hedefler = await _bedenService.getModelBedenDagilimi(widget.modelId);
        debugPrint('model_beden_dagilimi tablosundan: ${hedefler.length} beden bulundu');
      }
      
      // 2. Tablo boşsa, widget.model içinden bedenler JSON'u oku
      if (hedefler.isEmpty && widget.model['bedenler'] != null) {
        try {
          final bedenlerData = widget.model['bedenler'];
          debugPrint('Model bedenler verisi: $bedenlerData (${bedenlerData.runtimeType})');
          
          if (bedenlerData is Map) {
            final bedenlerJson = bedenlerData as Map<String, dynamic>;
            bedenlerJson.forEach((bedenKodu, adet) {
              final adetInt = adet is int ? adet : int.tryParse(adet.toString()) ?? 0;
              if (adetInt > 0) {
                hedefler.add(ModelBedenDagilimi(
                  id: 0,
                  modelId: widget.modelId,
                  bedenKodu: bedenKodu,
                  siparisAdedi: adetInt,
                ));
              }
            });
            debugPrint('Model parametresinden ${hedefler.length} beden okundu');
          }
        } catch (e) {
          debugPrint('Model bedenler okuma hatası: $e');
        }
      }
      
      // Beden sırasına göre sırala
      if (hedefler.isNotEmpty) {
        hedefler.sort((a, b) {
          const bedenSirasi = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL'];
          final aIndex = bedenSirasi.indexOf(a.bedenKodu);
          final bIndex = bedenSirasi.indexOf(b.bedenKodu);
          if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
          if (aIndex >= 0) return -1;
          if (bIndex >= 0) return 1;
          return a.bedenKodu.compareTo(b.bedenKodu);
        });
        bedenTablosuVar = true;
      }
      
      // 3. Hala boşsa, toplam adet ile tek satır oluştur
      if (hedefler.isEmpty) {
        bedenTablosuVar = false;
        final toplamAdet = widget.atama['kabul_edilen_adet'] ?? 
                          widget.atama['talep_edilen_adet'] ?? 
                          widget.atama['adet'] ?? 0;
        hedefler = [
          ModelBedenDagilimi(
            id: 0,
            modelId: widget.modelId,
            bedenKodu: 'TOPLAM',
            siparisAdedi: toplamAdet,
          )
        ];
      }
      
      // Beden takip tablosu adı
      final bedenTakipTablosu = '${widget.asamaAdi}_beden_takip';
      
      // Mevcut üretim verilerini getir (tablo varsa)
      List<BedenUretimTakip> mevcutUretim = [];
      try {
        mevcutUretim = await _bedenService.getAsamaBedenTakip(widget.asamaAdi, widget.atamaId);
      } catch (e) {
        debugPrint('Beden takip tablosu okunamadı ($bedenTakipTablosu): $e');
      }
      
      // Controller'ları oluştur
      for (final hedef in hedefler) {
        final mevcut = mevcutUretim.firstWhere(
          (u) => u.bedenKodu == hedef.bedenKodu,
          orElse: () => BedenUretimTakip(
            id: 0, atamaId: widget.atamaId, modelId: widget.modelId,
            bedenKodu: hedef.bedenKodu, hedefAdet: hedef.siparisAdedi,
          ),
        );
        uretilenControllers[hedef.bedenKodu] = TextEditingController(
          text: mevcut.uretilenAdet > 0 ? mevcut.uretilenAdet.toString() : '',
        );
        fireControllers[hedef.bedenKodu] = TextEditingController(
          text: mevcut.fireAdet > 0 ? mevcut.fireAdet.toString() : '',
        );
      }
    } catch (e) {
      debugPrint('Beden verileri yüklenemedi: $e');
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
    notlarController.dispose();
    super.dispose();
  }

  int _toplamUretilen() {
    int toplam = 0;
    for (final c in uretilenControllers.values) {
      toplam += int.tryParse(c.text) ?? 0;
    }
    return toplam;
  }

  int _toplamFire() {
    int toplam = 0;
    for (final c in fireControllers.values) {
      toplam += int.tryParse(c.text) ?? 0;
    }
    return toplam;
  }

  void _hepsiniTamamla() {
    for (final hedef in hedefler) {
      uretilenControllers[hedef.bedenKodu]?.text = hedef.siparisAdedi.toString();
    }
    setState(() {});
  }

  Future<void> _kaydet({bool kismiKayit = false}) async {
    setState(() => kaydediliyor = true);
    
    try {
      final toplamUretilen = _toplamUretilen();
      final toplamFire = _toplamFire();
      
      if (toplamUretilen <= 0) {
        throw Exception('En az bir beden için üretilen adet giriniz');
      }
      
      // Fire varsa ve firedenDus seçeneği aktifse, onay sor
      if (toplamFire > 0 && firedenDus && !kismiKayit) {
        final onay = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text('Fire Adeti Düşülsün mü?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toplam fire: $toplamFire adet'),
                const SizedBox(height: 12),
                const Text('Fire miktarı sonraki aşamaya geçecek adetten düşülecektir.'),
                const SizedBox(height: 8),
                Text('Sonraki aşamaya geçecek net adet: ${toplamUretilen - toplamFire}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Fire Düşme'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Evet, Düş'),
              ),
            ],
          ),
        );
        
        if (onay == null) {
          setState(() => kaydediliyor = false);
          return;
        }
        
        // Kullanıcının seçimine göre firedenDus güncelle
        firedenDus = onay;
      }
      
      // Beden bazlı verileri kaydet (eğer gerçek beden tablosu varsa)
      if (bedenTablosuVar) {
        final Map<String, Map<String, int>> bedenVerileri = {};
        for (final hedef in hedefler) {
          bedenVerileri[hedef.bedenKodu] = {
            'hedef_adet': hedef.siparisAdedi,
            'uretilen_adet': int.tryParse(uretilenControllers[hedef.bedenKodu]?.text ?? '') ?? 0,
            'fire_adet': int.tryParse(fireControllers[hedef.bedenKodu]?.text ?? '') ?? 0,
          };
        }
        
        try {
          await _bedenService.updateUretimBedenlerToplu(
            asama: widget.asamaAdi,
            atamaId: widget.atamaId,
            modelId: widget.modelId,
            bedenVerileri: bedenVerileri,
          );
        } catch (e) {
          debugPrint('Beden takip kaydedilemedi: $e');
        }
      }
      
      // Durum belirleme
      final String yeniDurum;
      if (kismiKayit) {
        yeniDurum = 'kismi_tamamlandi';
      } else {
        yeniDurum = 'tamamlandi';
      }
      
      // Sonraki aşamaya geçecek net adet (fire düşülürse)
      final int netAdet = firedenDus ? (toplamUretilen - toplamFire) : toplamUretilen;
      
      // Atama tablosunu güncelle
      final Map<String, dynamic> updateData = {
        'tamamlanan_adet': toplamUretilen,
        'durum': yeniDurum,
        'tamamlama_tarihi': yeniDurum == 'tamamlandi' ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
        'notlar': notlarController.text.isNotEmpty 
          ? '${widget.atama['notlar'] ?? ''}\n[BEDEN BAZLI] ${notlarController.text}${toplamFire > 0 ? ' (Fire: $toplamFire${firedenDus ? " - Adetten düşüldü" : ""})' : ''}'
          : widget.atama['notlar'],
      };
      
      // fire_adet sütununu eklemeyi dene
      try {
        await widget.supabase
            .from(widget.atamaTablosu)
            .update({...updateData, 'fire_adet': toplamFire})
            .eq('id', widget.atamaId);
      } catch (e) {
        debugPrint('fire_adet sütunu yok, onsuz güncelleniyor: $e');
        await widget.supabase
            .from(widget.atamaTablosu)
            .update(updateData)
            .eq('id', widget.atamaId);
      }
      
      // Sonraki aşamaya gönder (kısmi veya tam tamamlandığında)
      if (netAdet > 0) {
        // Güncellenmiş atama verisi - net adet kullan
        final updatedAtama = {...widget.atama, 'tamamlanan_adet': netAdet, 'fire_adet': toplamFire, 'kismi': kismiKayit};
        
        // Konfeksiyon tamamlandığında kalite kontrole gönder (sevkiyata değil!)
        if (widget.asamaAdi == 'konfeksiyon') {
          await widget.onKaliteKontrolOlustur(updatedAtama, tamamlananAdet: netAdet);
        } else if (widget.asamaAdi == 'yikama' || widget.asamaAdi == 'kalite_kontrol') {
          // Yıkama ve kalite kontrolden sevkiyata gönder
          await widget.onSevkiyatOlustur(updatedAtama, tamamlananAdet: netAdet);
        } else {
          // Diğer aşamalardan kalite kontrole gönder
          await widget.onKaliteKontrolOlustur(updatedAtama, tamamlananAdet: netAdet);
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        
        String mesaj = yeniDurum == 'tamamlandi' 
          ? '✅ ${widget.asamaDisplayName} tamamlandı!'
          : '✅ Kısmi kayıt yapıldı: $toplamUretilen adet, sonraki aşamaya $netAdet adet gönderildi';
        
        if (toplamFire > 0) {
          mesaj += ' (Fire: $toplamFire${firedenDus ? ", Net: $netAdet" : ""})';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mesaj),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
    
    setState(() => kaydediliyor = false);
  }

  @override
  Widget build(BuildContext context) {
    final toplamHedef = hedefler.fold<int>(0, (sum, h) => sum + h.siparisAdedi);
    final toplamUretilen = _toplamUretilen();
    final toplamFire = _toplamFire();
    final toplamKalan = toplamHedef - toplamUretilen - toplamFire;
    final oran = toplamHedef > 0 ? (toplamUretilen / toplamHedef * 100) : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.asamaRengi,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.checklist, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.asamaDisplayName} Üretim Girişi',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(widget.modelAdi,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // İçerik
            Flexible(
              child: yukleniyor
                ? const LoadingWidget()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Özet kart
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildOzetItem('Hedef', toplamHedef, Colors.blue),
                                    _buildOzetItem('Üretilen', toplamUretilen, Colors.green),
                                    _buildOzetItem('Fire', toplamFire, Colors.red),
                                    _buildOzetItem('Kalan', toplamKalan, Colors.orange),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: (oran / 100).clamp(0, 1),
                                          backgroundColor: Colors.grey.shade200,
                                          minHeight: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('%${oran.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                // Fire düşme seçeneği
                                if (toplamFire > 0) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: firedenDus,
                                          onChanged: (v) => setState(() => firedenDus = v ?? true),
                                          activeColor: Colors.orange,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Fire miktarını adetten düş',
                                                style: TextStyle(fontWeight: FontWeight.bold)),
                                              Text(
                                                firedenDus 
                                                  ? 'Sonraki aşamaya ${toplamUretilen - toplamFire} adet geçecek'
                                                  : 'Sonraki aşamaya $toplamUretilen adet geçecek (fire dahil)',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Hızlı işlem
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Hepsini Tamamla'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: _hepsiniTamamla,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Beden verisi yoksa uyarı göster
                        if (!bedenTablosuVar)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bu model için beden dağılımı tanımlanmamış. Toplam adet üzerinden işlem yapılacak.',
                                    style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Beden tablosu
                        Card(
                          child: Column(
                            children: [
                              // Başlık
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: widget.asamaRengi,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.straighten, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Beden Bazlı Üretim', 
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                              
                              // ÜST SATIR: Sipariş Adetleri (Read-Only)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.shopping_cart, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text('SİPARİŞ ADETLERİ', 
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('Salt Okunur', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: hedefler.map((h) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(h.bedenKodu, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                            const SizedBox(height: 2),
                                            Text(h.siparisAdedi.toString(), 
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // ALT SATIR: Üretilen Adet Girişi
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.edit, size: 16, color: widget.asamaRengi),
                                        const SizedBox(width: 4),
                                        Text('ÜRETİLEN ADETLER', 
                                          style: TextStyle(fontSize: 12, color: widget.asamaRengi, fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: widget.asamaRengi.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('Giriş Yapılabilir', style: TextStyle(fontSize: 10, color: widget.asamaRengi)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ...hedefler.map((h) => _buildBedenGirisRow(h)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        TextField(
                          controller: notlarController,
                          decoration: const InputDecoration(
                            labelText: 'Notlar (İsteğe Bağlı)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
            ),
            
            // Alt butonlar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sol tarafta kısmi kaydet
                  TextButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Kısmi Kaydet'),
                    onPressed: kaydediliyor ? null : () => _kaydet(kismiKayit: true),
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: kaydediliyor
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle),
                        label: Text(kaydediliyor ? 'Tamamlanıyor...' : 'Üretimi Tamamla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.asamaRengi,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        onPressed: kaydediliyor ? null : () => _kaydet(kismiKayit: false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOzetItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildBedenGirisRow(ModelBedenDagilimi hedef) {
    final uretilen = int.tryParse(uretilenControllers[hedef.bedenKodu]?.text ?? '') ?? 0;
    final fire = int.tryParse(fireControllers[hedef.bedenKodu]?.text ?? '') ?? 0;
    final kalan = hedef.siparisAdedi - uretilen - fire;
    final tamamlandi = kalan <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tamamlandi ? Colors.green.shade50 : Colors.grey.shade50,
        border: Border.all(color: tamamlandi ? Colors.green.shade300 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Beden etiketi
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: tamamlandi ? Colors.green : widget.asamaRengi,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(hedef.bedenKodu, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          
          // Hedef (read-only gösterim)
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text('Hedef', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Text(hedef.siparisAdedi.toString(), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          
          // Üretilen (giriş alanı)
          Expanded(
            flex: 2,
            child: TextField(
              controller: uretilenControllers[hedef.bedenKodu],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Üretilen',
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.asamaRengi),
              onChanged: (_) => setState(() {}),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Fire (giriş alanı)
          SizedBox(
            width: 70,
            child: TextField(
              controller: fireControllers[hedef.bedenKodu],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Fire',
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                filled: true,
                fillColor: fire > 0 ? Colors.red.shade50 : Colors.white,
              ),
              style: TextStyle(fontSize: 14, color: fire > 0 ? Colors.red : Colors.grey.shade700),
              onChanged: (_) => setState(() {}),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Kalan gösterimi
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: tamamlandi ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text('Kalan', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Text(kalan.toString(), 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                    color: tamamlandi ? Colors.green : Colors.orange.shade800,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
