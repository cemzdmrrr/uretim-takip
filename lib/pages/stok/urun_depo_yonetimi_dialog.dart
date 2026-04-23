// ignore_for_file: invalid_use_of_protected_member
part of 'urun_depo_yonetimi.dart';

/// Urun depo yonetimi - dialog ve widget metotlari
extension _DialogWidgetExt on _UrunDepoYonetimiPageState {
  void _urunEkleDialog(String kaliteTipi) {
    final formKey = GlobalKey<FormState>();
    String? secilenMarka;
    String? secilenModel;
    String? secilenRenk;
    int adet = 1;
    String aciklama = '';
    List<Map<String, dynamic>> modelListesi = [];
    List<String> renkListesi = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            '$kaliteTipi Ürün Ekle',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _UrunDepoYonetimiPageState.siyah,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // MARKA SEÇİMİ
                  Text(
                    'Marka Seç',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _UrunDepoYonetimiPageState.siyah,
                        ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<String>>(
                    future: _markalariGetir(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final markalar = snapshot.data!;
                      if (markalar.isEmpty) {
                        return const Text('Tamamlanmış sipariş bulunamadı');
                      }

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'Bir marka seç',
                          prefixIcon: const Icon(Icons.store,
                              color: _UrunDepoYonetimiPageState.siyah),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: _UrunDepoYonetimiPageState.siyah),
                          ),
                          filled: true,
                          fillColor: _UrunDepoYonetimiPageState.beyaz,
                        ),
                        initialValue: secilenMarka,
                        items: markalar.map((marka) {
                          return DropdownMenuItem(
                            value: marka,
                            child: Text(marka),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setStateDialog(() {
                            secilenMarka = value;
                            secilenModel = null;
                          });

                          if (value != null) {
                            final modeller = await _modellerGetir(value);
                            setStateDialog(() {
                              modelListesi = modeller;
                            });
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Lütfen marka seçin' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // MODEL SEÇİMİ
                  if (secilenMarka != null) ...[
                    Text(
                      'Model Seç',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _UrunDepoYonetimiPageState.siyah,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        // Benzersiz model listesi oluştur
                        final benzersizModeller =
                            <String, Map<String, dynamic>>{};
                        for (var model in modelListesi) {
                          final itemNo = model['item_no']?.toString() ?? '';
                          if (itemNo.isNotEmpty &&
                              !benzersizModeller.containsKey(itemNo)) {
                            benzersizModeller[itemNo] = model;
                          }
                        }

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: 'Bir model seç',
                            prefixIcon: const Icon(Icons.checkroom,
                                color: _UrunDepoYonetimiPageState.siyah),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: _UrunDepoYonetimiPageState.siyah),
                            ),
                            filled: true,
                            fillColor: _UrunDepoYonetimiPageState.beyaz,
                          ),
                          initialValue: secilenModel,
                          items: benzersizModeller.entries.map((entry) {
                            final itemNo = entry.key;
                            final toplamAdet = modelListesi
                                .where(
                                    (m) => m['item_no']?.toString() == itemNo)
                                .fold<int>(
                                    0,
                                    (sum, m) =>
                                        sum + ((m['adet'] as int?) ?? 0));
                            final label = '$itemNo ($toplamAdet adet)';
                            return DropdownMenuItem(
                              value: itemNo,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              secilenModel = value;
                              secilenRenk = null;
                              // Seçilen modele ait renkleri listele
                              final renkler = modelListesi
                                  .where(
                                      (m) => m['item_no']?.toString() == value)
                                  .map((m) => m['renk']?.toString() ?? '')
                                  .where((r) => r.isNotEmpty)
                                  .toSet()
                                  .toList();
                              renkListesi = renkler;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Lütfen model seçin' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // RENK SEÇİMİ
                  if (secilenModel != null) ...[
                    Text(
                      'Renk Seç',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _UrunDepoYonetimiPageState.siyah,
                          ),
                    ),
                    const SizedBox(height: 8),
                    renkListesi.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _UrunDepoYonetimiPageState.acikGri,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                                'Bu model için renk bilgisi bulunamadı'),
                          )
                        : DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              hintText: 'Bir renk seç',
                              prefixIcon: const Icon(Icons.palette,
                                  color: _UrunDepoYonetimiPageState.siyah),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: _UrunDepoYonetimiPageState.siyah),
                              ),
                              filled: true,
                              fillColor: _UrunDepoYonetimiPageState.beyaz,
                            ),
                            initialValue: secilenRenk,
                            items: renkListesi.map((renk) {
                              return DropdownMenuItem(
                                value: renk,
                                child: Text(renk),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateDialog(() {
                                secilenRenk = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Lütfen renk seçin' : null,
                          ),
                    const SizedBox(height: 20),
                  ],

                  // ADET
                  Text(
                    'Adet',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _UrunDepoYonetimiPageState.siyah,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: '1',
                      prefixIcon: const Icon(Icons.shopping_cart,
                          color: _UrunDepoYonetimiPageState.siyah),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: _UrunDepoYonetimiPageState.siyah),
                      ),
                      filled: true,
                      fillColor: _UrunDepoYonetimiPageState.beyaz,
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: '1',
                    onChanged: (value) {
                      setStateDialog(() {
                        adet = int.tryParse(value) ?? 1;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adet girin';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Adet 0\'dan büyük olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // AÇIKLAMA
                  Text(
                    'Açıklama (İsteğe Bağlı)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _UrunDepoYonetimiPageState.siyah,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Örn: Lekeyle geldi, Renk sorunu',
                      prefixIcon: const Icon(Icons.note,
                          color: _UrunDepoYonetimiPageState.siyah),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: _UrunDepoYonetimiPageState.siyah),
                      ),
                      filled: true,
                      fillColor: _UrunDepoYonetimiPageState.beyaz,
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setStateDialog(() {
                        aciklama = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal',
                  style: TextStyle(color: _UrunDepoYonetimiPageState.siyah)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Seçilen modelin id'sini bul (item_no ve renk'e göre)
                  final secilenModelData = modelListesi.firstWhere(
                    (m) =>
                        m['item_no'].toString() == secilenModel &&
                        m['renk']?.toString() == secilenRenk,
                    orElse: () => {},
                  );
                  final modelId = secilenModelData['id']?.toString();
                  if (modelId == null) {
                    context.showErrorSnackBar('Model bulunamadı');
                    return;
                  }
                  await _urunDepoEkle(
                    modelId: modelId,
                    kaliteTipi: kaliteTipi,
                    adet: adet,
                    aciklama: aciklama,
                    marka: secilenMarka,
                    renk: secilenRenk,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _UrunDepoYonetimiPageState.siyah,
                foregroundColor: _UrunDepoYonetimiPageState.beyaz,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _urunDepoEkle({
    required String modelId,
    required String kaliteTipi,
    required int adet,
    required String aciklama,
    String? marka,
    String? renk,
  }) async {
    try {
      await _supabase.from(DbTables.urunDepo).insert({
        'model_id': modelId,
        'kalite_tipi': kaliteTipi,
        'adet': adet,
        'aciklama': aciklama.isEmpty ? null : aciklama,
        'marka': marka,
        'renk': renk,
        'satildi': false,
        'satilan_adet': 0,
        'satilan_tutar': 0,
        'created_at': DateTime.now().toIso8601String(),
        'firma_id': _firmaId,
      });

      debugPrint('Ürün depoya eklendi: $kaliteTipi - $adet adet');
      await urunDepoListesiniGetir();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla eklendi'),
            backgroundColor: _UrunDepoYonetimiPageState.siyah,
          ),
        );
      }
    } catch (e) {
      debugPrint('Ürün ekleme hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  Future<void> _urunSil(String urunId) async {
    try {
      await _supabase
          .from(DbTables.urunDepo)
          .delete()
          .eq('firma_id', _firmaId)
          .eq('id', urunId);

      debugPrint('Ürün silindi: $urunId');
      await urunDepoListesiniGetir();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün silindi'),
            backgroundColor: _UrunDepoYonetimiPageState.siyah,
          ),
        );
      }
    } catch (e) {
      debugPrint('Ürün silme hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  // SATIŞ İŞLEMİ
  void _satisDialog(Map<String, dynamic> urun) {
    final formKey = GlobalKey<FormState>();
    final int mevcutAdet = (urun['adet'] as int?) ?? 0;
    final int satilanAdet = (urun['satilan_adet'] as int?) ?? 0;
    final int kalanAdet = mevcutAdet - satilanAdet;
    int satilacakAdet = 1;
    double satilacakTutar = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.sell, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Satış Yap',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÜRÜN BİLGİSİ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _UrunDepoYonetimiPageState.acikGri,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (urun['marka'] != null)
                          Text(
                            'Marka: ${urun['marka']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (urun['renk'] != null) Text('Renk: ${urun['renk']}'),
                        Text('Kalan Stok: $kalanAdet adet'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SATIŞ ADEDİ
                  const Text(
                    'Satılacak Adet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Kaç adet satıldı?',
                      prefixIcon: const Icon(Icons.shopping_cart),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: '1',
                    onChanged: (value) {
                      satilacakAdet = int.tryParse(value) ?? 1;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adet girin';
                      }
                      final adet = int.tryParse(value);
                      if (adet == null || adet <= 0) {
                        return 'Geçerli bir adet girin';
                      }
                      if (adet > kalanAdet) {
                        return 'En fazla $kalanAdet adet satılabilir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // SATIŞ TUTARI
                  const Text(
                    'Satış Tutarı (TL)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Toplam tutar',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'TL',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      satilacakTutar =
                          double.tryParse(value.replaceAll(',', '.')) ?? 0;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen tutar girin';
                      }
                      final tutar = double.tryParse(value.replaceAll(',', '.'));
                      if (tutar == null || tutar <= 0) {
                        return 'Geçerli bir tutar girin';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _satisKaydet(
                    urun: urun,
                    satilacakAdet: satilacakAdet,
                    satilacakTutar: satilacakTutar,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Satışı Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _satisKaydet({
    required Map<String, dynamic> urun,
    required int satilacakAdet,
    required double satilacakTutar,
  }) async {
    try {
      final urunId = urun['id'].toString();
      final mevcutSatilanAdet = (urun['satilan_adet'] as int?) ?? 0;
      final mevcutSatilanTutar =
          ((urun['satilan_tutar'] ?? 0) as num).toDouble();
      final mevcutAdet = (urun['adet'] as int?) ?? 0;

      final yeniSatilanAdet = mevcutSatilanAdet + satilacakAdet;
      final yeniSatilanTutar = mevcutSatilanTutar + satilacakTutar;
      final tamamenSatildi = yeniSatilanAdet >= mevcutAdet;

      // Ürün depo tablosunu güncelle
      await _supabase
          .from(DbTables.urunDepo)
          .update({
            'satilan_adet': yeniSatilanAdet,
            'satilan_tutar': yeniSatilanTutar,
            'satildi': tamamenSatildi,
            'satis_tarihi': DateTime.now().toIso8601String(),
          })
          .eq('firma_id', _firmaId)
          .eq('id', urunId);

      debugPrint('Satış kaydedildi: $satilacakAdet adet, $satilacakTutar TL');
      await urunDepoListesiniGetir();

      if (mounted) {
        context.showSuccessSnackBar(
            '$satilacakAdet adet satış kaydedildi (${satilacakTutar.toStringAsFixed(2)} TL)');
      }
    } catch (e) {
      debugPrint('Satış hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Satış hatası: $e');
      }
    }
  }

  List<Map<String, dynamic>> _filtreliUrunler(String kaliteTipi) {
    final aramaMetni = arama.trim().toLowerCase();
    return urunDepoListesi
        .where((urun) =>
            urun['kalite_tipi'] == kaliteTipi &&
            (aramaMetni.isEmpty ||
                [
                  urun['marka'],
                  urun['renk'],
                  urun['aciklama'],
                  urun['kalite_tipi'],
                ].any((value) =>
                    value?.toString().toLowerCase().contains(aramaMetni) ??
                    false)))
        .toList();
  }

  Widget _urunTabi(String kaliteTipi) {
    final filtrelUrunler = _filtreliUrunler(kaliteTipi);
    final toplam = filtrelUrunler.fold<int>(
        0, (sum, item) => sum + ((item['adet'] as int?) ?? 0));
    final satilan = filtrelUrunler.fold<int>(
        0, (sum, item) => sum + ((item['satilan_adet'] as int?) ?? 0));
    final kalan = toplam - satilan;

    return LayoutBuilder(
      builder: (context, constraints) {
        final kisaEkran = constraints.maxHeight < 540;
        final ustBolum = [
          _buildUrunAracCubugu(kaliteTipi),
          const SizedBox(height: 12),
          _buildUrunOzetleri(filtrelUrunler.length, toplam, satilan, kalan),
          const SizedBox(height: 12),
        ];

        if (kisaEkran) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...ustBolum,
                SizedBox(
                  height: constraints.maxHeight < 420
                      ? 260
                      : constraints.maxHeight * 0.52,
                  child: _buildUrunListeAlani(filtrelUrunler, kaliteTipi),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...ustBolum,
              Expanded(child: _buildUrunListeAlani(filtrelUrunler, kaliteTipi)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUrunAracCubugu(String kaliteTipi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 760;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: dar ? constraints.maxWidth : 360,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Marka, renk veya açıklama ara',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => arama = value),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _urunEkleDialog(kaliteTipi),
                icon: const Icon(Icons.add_circle_outline),
                label: Text('$kaliteTipi Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _UrunDepoYonetimiPageState.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUrunOzetleri(
      int urunSayisi, int toplam, int satilan, int kalan) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final kartlar = [
          _buildOzetKutusu('Ürün', '$urunSayisi', Icons.inventory_2_outlined,
              _UrunDepoYonetimiPageState.primaryColor),
          _buildOzetKutusu(
              'Toplam', '$toplam', Icons.all_inbox, const Color(0xFF7C3AED)),
          _buildOzetKutusu('Satılan', '$satilan', Icons.sell_outlined,
              _UrunDepoYonetimiPageState.successColor),
          _buildOzetKutusu('Kalan', '$kalan', Icons.pending_actions,
              _UrunDepoYonetimiPageState.warningColor),
        ];

        if (constraints.maxWidth < 520) {
          return Column(
            children: kartlar
                .map((kart) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: kart,
                    ))
                .toList(),
          );
        }

        if (constraints.maxWidth < 900) {
          final width = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kartlar
                .map((kart) => SizedBox(width: width, child: kart))
                .toList(),
          );
        }

        return Row(
          children: kartlar
              .map((kart) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: kart,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildOzetKutusu(
      String baslik, String deger, IconData icon, Color renk) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: renk, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deger,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrunListeAlani(
      List<Map<String, dynamic>> urunler, String kaliteTipi) {
    if (yukleniyor) return const LoadingWidget();
    if (urunler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: _UrunDepoYonetimiPageState.siyah.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz $kaliteTipi ürün eklenmedi',
              style: TextStyle(
                color: _UrunDepoYonetimiPageState.siyah.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 84),
      itemCount: urunler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _urunKartiUygulama(urunler[index]),
    );
  }

  Widget _buildMiniBilgi(String baslik, String deger) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          Text(
            deger,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumEtiketi(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatUrunTarihi(dynamic value) {
    final text = value?.toString().trim() ?? '';
    final tarih = DateTime.tryParse(text);
    if (tarih == null) return '-';
    return DateFormat('dd.MM.yyyy').format(tarih);
  }

  Widget _urunKartiUygulama(Map<String, dynamic> urun) {
    final mevcutAdet = (urun['adet'] as int?) ?? 0;
    final satilanAdet = (urun['satilan_adet'] as int?) ?? 0;
    final satilanTutar = ((urun['satilan_tutar'] ?? 0) as num).toDouble();
    final kalanAdet = mevcutAdet - satilanAdet;
    final tamamenSatildi = kalanAdet <= 0 || urun['satildi'] == true;
    final durumRenk = tamamenSatildi
        ? _UrunDepoYonetimiPageState.successColor
        : _UrunDepoYonetimiPageState.primaryColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 720;
          final bilgi = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: durumRenk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tamamenSatildi
                      ? Icons.check_circle_outline
                      : Icons.inventory_2_outlined,
                  color: durumRenk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${urun['marka'] ?? 'Marka yok'} / ${urun['renk'] ?? 'Renk yok'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDurumEtiketi(
                          tamamenSatildi ? 'Satıldı' : 'Stokta',
                          durumRenk,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMiniBilgi('Toplam', '$mevcutAdet'),
                        _buildMiniBilgi('Satılan', '$satilanAdet'),
                        _buildMiniBilgi('Kalan', '$kalanAdet'),
                        _buildMiniBilgi(
                            'Tarih', _formatUrunTarihi(urun['created_at'])),
                        if (satilanTutar > 0)
                          _buildMiniBilgi(
                              'Satış', '${satilanTutar.toStringAsFixed(2)} TL'),
                      ],
                    ),
                    if (urun['aciklama'] != null &&
                        urun['aciklama'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        urun['aciklama'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final aksiyonlar = _buildUrunAksiyonlari(urun, kalanAdet);
          if (dar) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bilgi,
                const SizedBox(height: 10),
                aksiyonlar,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: bilgi),
              const SizedBox(width: 12),
              aksiyonlar,
            ],
          );
        },
      ),
    );
  }

  Widget _buildUrunAksiyonlari(Map<String, dynamic> urun, int kalanAdet) {
    final tamamenSatildi = kalanAdet <= 0 || urun['satildi'] == true;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (!tamamenSatildi)
          ElevatedButton.icon(
            onPressed: () => _satisDialog(urun),
            icon: const Icon(Icons.sell, size: 18),
            label: const Text('Satış Yap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _UrunDepoYonetimiPageState.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        if (tamamenSatildi)
          _buildDurumEtiketi(
              'Satıldı', _UrunDepoYonetimiPageState.successColor),
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sil'),
                content:
                    const Text('Bu ürünü silmek istediğinizden emin misiniz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () {
                      _urunSil(urun['id'].toString());
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Sil',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.delete_outline),
          color: _UrunDepoYonetimiPageState.dangerColor,
          tooltip: 'Sil',
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _urunKartiUygulamaLegacy(Map<String, dynamic> urun) {
    final bool satildi = urun['satildi'] == true;
    final int mevcutAdet = (urun['adet'] as int?) ?? 0;
    final int satilanAdet = (urun['satilan_adet'] as int?) ?? 0;
    final double satilanTutar =
        ((urun['satilan_tutar'] ?? 0) as num).toDouble();
    final int kalanAdet = mevcutAdet - satilanAdet;
    final bool tamamenSatildi = kalanAdet <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: satildi || tamamenSatildi
          ? Colors.green.shade50
          : _UrunDepoYonetimiPageState.beyaz,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: satildi || tamamenSatildi
                  ? Colors.green
                  : _UrunDepoYonetimiPageState.siyah,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MARKA VE RENK
              Row(
                children: [
                  if (urun['marka'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _UrunDepoYonetimiPageState.siyah,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        urun['marka'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _UrunDepoYonetimiPageState.beyaz,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (urun['renk'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _UrunDepoYonetimiPageState.acikGri,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _UrunDepoYonetimiPageState.siyah
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        urun['renk'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: _UrunDepoYonetimiPageState.siyah,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    DateFormat('dd.MM.yyyy').format(
                      DateTime.parse(urun['created_at'] ?? ''),
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: _UrunDepoYonetimiPageState.siyah,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ADET BİLGİLERİ
              Row(
                children: [
                  // TOPLAM ADET
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _UrunDepoYonetimiPageState.acikGri,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Toplam: $mevcutAdet',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _UrunDepoYonetimiPageState.siyah,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // SATILAN ADET
                  if (satilanAdet > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Satılan: $satilanAdet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // KALAN ADET
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kalanAdet > 0
                          ? Colors.blue.shade50
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Kalan: $kalanAdet',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kalanAdet > 0
                            ? Colors.blue.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),

              // SATIŞ TUTARI (varsa)
              if (satilanTutar > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money,
                          size: 16, color: Colors.green.shade700),
                      Text(
                        'Satış Tutarı: ${satilanTutar.toStringAsFixed(2)} ?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // AÇIKLAMA
              if (urun['aciklama'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  urun['aciklama'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: _UrunDepoYonetimiPageState.siyah,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              // BUTONLAR
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // SATILDI BUTONU
                  if (kalanAdet > 0)
                    ElevatedButton.icon(
                      onPressed: () => _satisDialog(urun),
                      icon: const Icon(Icons.sell, size: 18),
                      label: const Text('Satış Yap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (tamamenSatildi)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'SATILDI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // SİL BUTONU
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sil'),
                          content: const Text(
                              'Bu ürünü silmek istediğinizden emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () {
                                _urunSil(urun['id'].toString());
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Sil',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Sil',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
