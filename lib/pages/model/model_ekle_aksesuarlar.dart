part of 'model_ekle.dart';

/// Aksesuarlar tab extension for _ModelEkleState.
extension _AksesuarlarTabExt on _ModelEkleState {
  Widget _buildAksesuarlarTab() {
    return Column(
      children: [
        // Üst kısım - Ekle butonu
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border(bottom: BorderSide(color: Colors.teal.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.category, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                'Seçili Aksesuarlar: ${_selectedAksesuarlar.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _showYeniAksesuarEkleDialog,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Yeni Aksesuar Oluştur'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showMevcutAksesuarSecDialog,
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('Mevcut Aksesuardan Seç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Aksesuar listesi
        Expanded(
          child: _selectedAksesuarlar.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Henüz aksesuar eklenmemiş',
                          style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Mevcut aksesuarlardan seçebilir veya yeni aksesuar oluşturabilirsiniz.',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _selectedAksesuarlar.length,
                  itemBuilder: (context, index) {
                    final item = _selectedAksesuarlar[index];
                    final aksesuar = item['aksesuar'] as Map<String, dynamic>;
                    final int adetPerModel = item['adet_per_model'] as int;
                    final double birimFiyat =
                        (aksesuar['birim_fiyat'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(Icons.category, color: Colors.teal),
                        ),
                        title: Text(
                          aksesuar['ad'] ?? 'Aksesuar',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (aksesuar['sku'] != null)
                              Text('SKU: ${aksesuar['sku']}',
                                  style: const TextStyle(fontSize: 12)),
                            Text(
                              'Birim Fiyat: ₺${birimFiyat.toStringAsFixed(2)} | Model Başına: $adetPerModel adet',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Adet değiştirme
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                initialValue: adetPerModel.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Adet',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  final newAdet = int.tryParse(value) ?? 1;
                                  setState(() {
                                    _selectedAksesuarlar[index]['adet_per_model'] = newAdet < 1 ? 1 : newAdet;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedAksesuarlar.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Mevcut aksesuarlardan seçme dialog'u
  void _showMevcutAksesuarSecDialog() async {
    List<dynamic> tumAksesuarlar = [];
    try {
      final response = await _supabase
          .from(DbTables.aksesuarlar)
          .select('*')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .eq('durum', 'aktif');
      tumAksesuarlar = response;
    } catch (e) {
      debugPrint('Aksesuarlar yüklenemedi: $e');
    }

    if (tumAksesuarlar.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Henüz aksesuar tanımlanmamış. Önce yeni aksesuar oluşturun.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Zaten eklenenler hariç
    final ekliIdler = _selectedAksesuarlar
        .map((e) => (e['aksesuar'] as Map<String, dynamic>)['id'])
        .toSet();
    final filtrelenmis = tumAksesuarlar
        .where((a) => !ekliIdler.contains(a['id']))
        .toList();

    if (filtrelenmis.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm mevcut aksesuarlar zaten eklenmiş.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    dynamic secilenAksesuar;
    int adetPerModel = 1;
    List<Map<String, dynamic>> secilenBedenler = [];

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Aksesuar Seçin'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Aksesuar',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: filtrelenmis.map<DropdownMenuItem>((aksesuar) {
                        final fiyat = (aksesuar['birim_fiyat'] as num?)?.toDouble() ?? 0.0;
                        return DropdownMenuItem(
                          value: aksesuar,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  aksesuar['ad'] ?? 'Aksesuar',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '₺${fiyat.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setDialogState(() {
                          secilenAksesuar = value;
                          secilenBedenler = [];
                        });
                        // Seçilen aksesuarın bedenlerini getir
                        if (value != null) {
                          try {
                            final bedenResponse = await _supabase
                                .from(DbTables.aksesuarBedenler)
                                .select('beden, stok_miktari')
                                .eq('aksesuar_id', value['id'])
                                .eq('durum', 'aktif');
                            setDialogState(() {
                              secilenBedenler = List<Map<String, dynamic>>.from(bedenResponse);
                            });
                          } catch (e) {
                            debugPrint('Beden bilgisi getirilemedi: $e');
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Model Başına Adet',
                        border: OutlineInputBorder(),
                        helperText: 'Her bir model için kaç adet kullanılacak?',
                      ),
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setDialogState(() {
                          adetPerModel = int.tryParse(value) ?? 1;
                        });
                      },
                    ),
                    if (secilenAksesuar != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (secilenAksesuar['sku'] != null)
                              Text('SKU: ${secilenAksesuar['sku']}', style: const TextStyle(fontSize: 13)),
                            if (secilenAksesuar['marka'] != null)
                              Text('Marka: ${secilenAksesuar['marka']}', style: const TextStyle(fontSize: 13)),
                            Text(
                              'Birim Fiyat: ₺${((secilenAksesuar['birim_fiyat'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Beden bilgisi gösterimi
                    if (secilenBedenler.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.straighten, size: 16, color: Colors.teal),
                                SizedBox(width: 6),
                                Text('Beden Stok Durumu',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...secilenBedenler.map((b) {
                              final bedenAdi = b['beden']?.toString() ?? '';
                              final stok = (b['stok_miktari'] as int? ?? 0);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(bedenAdi, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                    Text(
                                      '$stok adet',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: stok > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: secilenAksesuar != null
                    ? () {
                        setState(() {
                          _selectedAksesuarlar.add({
                            'aksesuar': Map<String, dynamic>.from(secilenAksesuar),
                            'adet_per_model': adetPerModel < 1 ? 1 : adetPerModel,
                          });
                        });
                        Navigator.pop(dialogContext);
                      }
                    : null,
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Yeni aksesuar oluşturma dialog'u (hem depoya hem modele ekler)
  void _showYeniAksesuarEkleDialog() {
    final skuController = TextEditingController();
    final adController = TextEditingController();
    final markaController = TextEditingController();
    final renkController = TextEditingController();
    final renkKoduController = TextEditingController();
    final birimController = TextEditingController(text: 'adet');
    final birimFiyatController = TextEditingController();
    final malzemeController = TextEditingController();
    final aciklamaController = TextEditingController();
    final minimumStokController = TextEditingController(text: '10');
    int adetPerModel = 1;
    final List<Map<String, dynamic>> bedenListesi = [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Yeni Aksesuar Oluştur'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: skuController,
                            decoration: const InputDecoration(
                              labelText: 'SKU Kodu *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: adController,
                            decoration: const InputDecoration(
                              labelText: 'Aksesuar Adı *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: markaController,
                            decoration: const InputDecoration(
                              labelText: 'Marka',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: malzemeController,
                            decoration: const InputDecoration(
                              labelText: 'Malzeme',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: renkController,
                            decoration: const InputDecoration(
                              labelText: 'Renk',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: renkKoduController,
                            decoration: const InputDecoration(
                              labelText: 'Renk Kodu',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: birimController,
                            decoration: const InputDecoration(
                              labelText: 'Birim',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: birimFiyatController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Birim Fiyat (TL)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: minimumStokController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Stok Uyarısı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: aciklamaController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama (Opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    // ─── BEDEN YÖNETİMİ ───
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bedenler',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showBedenEkleDialogInline(setDialogState, bedenListesi),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Yeni Beden Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (bedenListesi.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: bedenListesi.asMap().entries.map((entry) {
                            final int index = entry.key;
                            final Map<String, dynamic> beden = entry.value;
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                border: index > 0
                                    ? Border(top: BorderSide(color: Colors.grey.shade300))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Beden: ${beden['beden']}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Stok: ${beden['stok_miktari']} adet',
                                          style: TextStyle(
                                            color: (beden['stok_miktari'] as int) > 0
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _showBedenDuzenleDialogInline(
                                        index, beden, setDialogState, bedenListesi),
                                    tooltip: 'Düzenle',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setDialogState(() {
                                        bedenListesi.removeAt(index);
                                      });
                                    },
                                    tooltip: 'Sil',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (bedenListesi.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          'Henüz beden eklenmemiş (opsiyonel)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Bu Model İçin Adet (Model Başına)',
                        border: OutlineInputBorder(),
                        helperText: 'Her bir model için kaç adet kullanılacak?',
                      ),
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        adetPerModel = int.tryParse(value) ?? 1;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (skuController.text.trim().isEmpty ||
                      adController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('SKU ve Aksesuar adı gerekli'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    // Toplam stok hesapla
                    int toplamStok = 0;
                    for (var beden in bedenListesi) {
                      toplamStok += (beden['stok_miktari'] as int? ?? 0);
                    }

                    // Aksesuarı veritabanına kaydet
                    final aksesuarData = {
                      'sku': skuController.text.trim(),
                      'ad': adController.text.trim(),
                      'marka': markaController.text.trim().isNotEmpty
                          ? markaController.text.trim()
                          : null,
                      'renk': renkController.text.trim().isNotEmpty
                          ? renkController.text.trim()
                          : null,
                      'renk_kodu': renkKoduController.text.trim().isNotEmpty
                          ? renkKoduController.text.trim()
                          : null,
                      'birim': birimController.text.trim().isNotEmpty
                          ? birimController.text.trim()
                          : 'adet',
                      'birim_fiyat': double.tryParse(
                              birimFiyatController.text.replaceAll(',', '.')) ??
                          0.0,
                      'malzeme': malzemeController.text.trim().isNotEmpty
                          ? malzemeController.text.trim()
                          : null,
                      'aciklama': aciklamaController.text.trim().isNotEmpty
                          ? aciklamaController.text.trim()
                          : null,
                      'minimum_stok':
                          int.tryParse(minimumStokController.text) ?? 10,
                      'durum': 'aktif',
                      'miktar': toplamStok,
                      'firma_id': TenantManager.instance.requireFirmaId,
                    };

                    final result = await _supabase
                        .from(DbTables.aksesuarlar)
                        .insert(aksesuarData)
                        .select()
                        .single();

                    final aksesuarId = result['id'];

                    // Beden kayıtlarını aksesuar_bedenler tablosuna ekle
                    if (bedenListesi.isNotEmpty) {
                      for (var beden in bedenListesi) {
                        await _supabase.from(DbTables.aksesuarBedenler).insert({
                          'aksesuar_id': aksesuarId,
                          'beden': beden['beden'],
                          'stok_miktari': beden['stok_miktari'] as int? ?? 0,
                          'durum': 'aktif',
                          'firma_id': TenantManager.instance.requireFirmaId,
                        });
                      }
                      debugPrint('Aksesuar bedenleri kaydedildi: ${bedenListesi.length} beden');
                    }

                    // Modele ekle
                    setState(() {
                      _selectedAksesuarlar.add({
                        'aksesuar': Map<String, dynamic>.from(result),
                        'adet_per_model': adetPerModel < 1 ? 1 : adetPerModel,
                      });
                    });

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Aksesuar oluşturuldu ve modele eklendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      String hataMesaji = '$e';
                      if (hataMesaji.contains('aksesuarlar_sku_key') || hataMesaji.contains('duplicate key')) {
                        hataMesaji = 'Bu SKU kodu zaten kullanılıyor. Lütfen farklı bir SKU girin veya "Mevcut Aksesuardan Seç" ile ekleyin.';
                      }
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(hataMesaji),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Oluştur ve Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Beden ekleme alt dialog'u
  void _showBedenEkleDialogInline(
      StateSetter setDialogState, List<Map<String, dynamic>> bedenListesi) {
    final bedenController = TextEditingController();
    final stokController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Beden Ekle'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bedenController,
                decoration: const InputDecoration(
                  labelText: 'Beden',
                  hintText: 'Örn: S, M, L, XL, 75cm, 18mm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stokController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Başlangıç Stok Miktarı',
                  border: OutlineInputBorder(),
                  suffix: Text('adet'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (bedenController.text.trim().isNotEmpty) {
                final bool bedenMevcut = bedenListesi.any((b) =>
                    b['beden'].toString().toLowerCase() ==
                    bedenController.text.trim().toLowerCase());
                if (bedenMevcut) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Bu beden zaten eklenmiş'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                setDialogState(() {
                  bedenListesi.add({
                    'beden': bedenController.text.trim(),
                    'stok_miktari': int.tryParse(stokController.text) ?? 0,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  /// Beden düzenleme alt dialog'u
  void _showBedenDuzenleDialogInline(int index, Map<String, dynamic> beden,
      StateSetter setDialogState, List<Map<String, dynamic>> bedenListesi) {
    final bedenController = TextEditingController(text: beden['beden']);
    final stokController =
        TextEditingController(text: beden['stok_miktari'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Beden Düzenle'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bedenController,
                decoration: const InputDecoration(
                  labelText: 'Beden',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stokController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stok Miktarı',
                  border: OutlineInputBorder(),
                  suffix: Text('adet'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (bedenController.text.trim().isNotEmpty) {
                setDialogState(() {
                  bedenListesi[index] = {
                    ...beden,
                    'beden': bedenController.text.trim(),
                    'stok_miktari': int.tryParse(stokController.text) ?? 0,
                  };
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
}
