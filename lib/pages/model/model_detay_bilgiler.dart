// ignore_for_file: invalid_use_of_protected_member
part of 'model_detay.dart';

/// Model bilgileri tab'i - bilgi goruntuleme ve duzenleme
extension _BilgilerExt on _ModelDetayState {
  Widget _buildModelBilgileriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temel Model Bilgileri
            _buildSectionCard(
              'Temel Bilgiler',
              Icons.info_outline,
              Colors.blue,
              [
                _buildEditableField('marka', 'Marka', currentModelData?['marka']),
                _buildEditableField('item_no', 'Item No', currentModelData?['item_no']),
                _buildEditableField('model_adi', 'Model Adı', currentModelData?['model_adi']),
                _buildEditableField('uretim_dali', 'Üretim Dalı', currentModelData?['uretim_dali']),
                _buildEditableField('toplam_adet', 'Toplam Adet', currentModelData?['toplam_adet']?.toString(), isNumber: true),
                _buildEditableField('durum', 'Durum', currentModelData?['durum']),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Beden Dağılımı
            _buildSectionCard(
              'Beden Dağılımı',
              Icons.straighten,
              Colors.green,
              [
                _buildBedenDagilimi(currentModelData?['bedenler']),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sezon ve Kategori Bilgileri
            _buildSectionCard(
              'Sezon & Kategori',
              Icons.calendar_today,
              Colors.purple,
              [
                _buildEditableField('sezon', 'Sezon', currentModelData?['sezon']),
                _buildEditableField('koleksiyon', 'Koleksiyon', currentModelData?['koleksiyon']),
                _buildEditableField('urun_kategorisi', 'Ürün Kategorisi', currentModelData?['urun_kategorisi']),
                _buildEditableField('triko_tipi', DalFormConfig.urunTipiEtiketi(_modelUretimDali), currentModelData?['triko_tipi']),
                _buildEditableField('cinsiyet', 'Cinsiyet', currentModelData?['cinsiyet']),
                _buildEditableField('yas_grubu', 'Yaş Grubu', currentModelData?['yas_grubu']),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tasarım Detayları
            _buildSectionCard(
              'Tasarım Detayları',
              Icons.design_services,
              Colors.orange,
              [
                _buildEditableField('yaka_tipi', 'Yaka Tipi', currentModelData?['yaka_tipi']),
                _buildEditableField('kol_tipi', 'Kol Tipi', currentModelData?['kol_tipi']),
                _buildEditableField('desen_tipi', 'Desen Tipi', currentModelData?['desen_tipi']),
                _buildEditableField('desen_detayi', 'Desen Detayı', currentModelData?['desen_detayi']),
                _buildEditableField('renk', 'Renk', currentModelData?['renk']),
                _buildEditableField('renk_kombinasyonu', 'Renk Kombinasyonu', currentModelData?['renk_kombinasyonu']),
              ],
            ),
            
            // İplik Bilgileri (sadece ilgili dallar)
            if (DalFormConfig.iplikBolumuGoster(_modelUretimDali)) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'İplik Bilgileri',
              Icons.texture,
              Colors.teal,
              [
                _buildEditableField('ana_iplik_turu', 'Ana İplik Türü', currentModelData?['ana_iplik_turu']),
                _buildEditableField('iplik_karisimi', 'İplik Karışımı', currentModelData?['iplik_karisimi']),
                _buildEditableField('iplik_kalinligi', 'İplik Kalınlığı', currentModelData?['iplik_kalinligi']),
                _buildEditableField('iplik_markasi', 'İplik Markası', currentModelData?['iplik_markasi']),
                _buildEditableField('iplik_renk_kodu', 'İplik Renk Kodu', currentModelData?['iplik_renk_kodu']),
                _buildEditableField('iplik_numarasi', 'İplik Numarası', currentModelData?['iplik_numarasi']),
              ],
            ),
            ],
            
            // Teknik Bilgiler (sadece triko/örme dalları)
            if (DalFormConfig.teknikOrguGoster(_modelUretimDali)) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'Teknik Bilgiler',
              Icons.settings,
              Colors.indigo,
              [
                _buildEditableField('makine_tipi', 'Makine Tipi', currentModelData?['makine_tipi']),
                _buildEditableField('igne_no', 'İğne No', currentModelData?['igne_no']),
                _buildEditableField('gauge', 'Gauge', currentModelData?['gauge']),
                _buildEditableField('orgu_sikligi', 'Örgü Sıklığı', currentModelData?['orgu_sikligi']),
                _buildEditableField('gramaj', 'Gramaj', currentModelData?['gramaj']),
                _buildEditableField('teknik_gramaj', 'Teknik Gramaj', currentModelData?['teknik_gramaj']),
              ],
            ),
            ],
            
            const SizedBox(height: 16),
            
            // Termin ve Notlar
            _buildSectionCard(
              'Tarihler & Notlar',
              Icons.event,
              Colors.red,
              [
                _buildDateField('siparis_tarihi', 'Sipariş Tarihi'),
                _buildDateField('termin_tarihi', 'Termin Tarihi'),
                _buildEditableField('ozel_talimatlar', 'Özel Talimatlar', currentModelData?['ozel_talimatlar'], isMultiline: true),
                _buildEditableField('genel_notlar', 'Genel Notlar', currentModelData?['genel_notlar'], isMultiline: true),
              ],
            ),
            
            // Kaydet Butonu (düzenleme modunda)
            if (_isEditing && kullaniciRolu == 'admin') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveModelBilgileri,
                  icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String key, String label, String? value, {bool isNumber = false, bool isMultiline = false}) {
    if (_isEditing && kullaniciRolu == 'admin') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          initialValue: value ?? '',
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: isNumber ? TextInputType.number : (isMultiline ? TextInputType.multiline : TextInputType.text),
          maxLines: isMultiline ? 3 : 1,
          onChanged: (newValue) {
            currentModelData?[key] = isNumber ? int.tryParse(newValue) : newValue;
          },
        ),
      );
    }
    return _buildInfoRow(label, value);
  }

  /// Tarih alanları için gün/ay/yıl formatında date picker
  Widget _buildDateField(String key, String label) {
    final rawValue = currentModelData?[key];
    final DateTime? currentDate = rawValue != null ? DateTime.tryParse(rawValue.toString()) : null;
    final String displayValue = currentDate != null
        ? DateFormat('dd.MM.yyyy').format(currentDate)
        : '-';

    if (_isEditing && kullaniciRolu == 'admin') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: currentDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              locale: const Locale('tr'),
            );
            if (date != null) {
              setState(() {
                currentModelData?[key] = date.toIso8601String();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentDate != null
                      ? DateFormat('dd.MM.yyyy').format(currentDate)
                      : label,
                  style: TextStyle(
                    color: currentDate != null ? Colors.black : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    }
    return _buildInfoRow(label, displayValue);
  }

  Future<void> _saveModelBilgileri() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      await supabase
          .from(DbTables.trikoTakip)
          .update(currentModelData!)
          .eq('id', widget.modelId);
      
      if (!mounted) return;
      context.showSuccessSnackBar('✅ Model bilgileri başarıyla güncellendi');
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      
      await verileriGetir();
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
      setState(() => _isSaving = false);
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // Beden dağılımını gösteren widget
  Widget _buildBedenDagilimi(dynamic bedenler) {
    if (bedenler == null && !_isEditing) {
      return const Text('Beden bilgisi yok', style: TextStyle(color: Colors.grey));
    }
    
    Map<String, dynamic> bedenMap = {};
    
    // bedenler JSONB formatını parse et
    if (bedenler is Map) {
      bedenMap = Map<String, dynamic>.from(bedenler);
    } else if (bedenler is String) {
      try {
        bedenMap = Map<String, dynamic>.from(
          (bedenler).isNotEmpty 
            ? Map<String, dynamic>.from(bedenler as dynamic) 
            : {}
        );
      } catch (e) {
        if (!_isEditing) return Text(bedenler, style: const TextStyle(fontSize: 13));
      }
    } else if (bedenler is List) {
      for (var item in bedenler) {
        if (item is Map && item['beden'] != null) {
          bedenMap[item['beden'].toString()] = item['adet'] ?? 0;
        }
      }
    }
    
    if (bedenMap.isEmpty && !_isEditing) {
      return const Text('Beden bilgisi yok', style: TextStyle(color: Colors.grey));
    }

    // Düzenleme modu
    if (_isEditing && kullaniciRolu == 'admin') {
      return _buildEditableBedenDagilimi(bedenMap);
    }
    
    // Toplam adeti hesapla
    int toplamAdet = 0;
    bedenMap.forEach((key, value) {
      toplamAdet += (value is int) ? value : (int.tryParse(value.toString()) ?? 0);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: bedenMap.entries.map((entry) {
            final adet = (entry.value is int) ? entry.value : (int.tryParse(entry.value.toString()) ?? 0);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$adet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Toplam: $toplamAdet adet',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableBedenDagilimi(Map<String, dynamic> bedenMap) {
    // Toplam adeti hesapla
    int toplamAdet = 0;
    bedenMap.forEach((key, value) {
      toplamAdet += (value is int) ? value : (int.tryParse(value.toString()) ?? 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...bedenMap.entries.map((entry) {
          final adet = (entry.value is int) ? entry.value : (int.tryParse(entry.value.toString()) ?? 0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: adet.toString(),
                    decoration: InputDecoration(
                      labelText: 'Adet',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final yeniAdet = int.tryParse(value) ?? 0;
                      if (currentModelData?['bedenler'] is Map) {
                        (currentModelData!['bedenler'] as Map)[entry.key] = yeniAdet;
                      }
                      // Toplam adeti güncelle ve UI'yi yenile
                      int yeniToplam = 0;
                      if (currentModelData?['bedenler'] is Map) {
                        (currentModelData!['bedenler'] as Map).forEach((k, v) {
                          yeniToplam += (v is int) ? v : (int.tryParse(v.toString()) ?? 0);
                        });
                      }
                      setState(() {
                        currentModelData?['toplam_adet'] = yeniToplam;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (currentModelData?['bedenler'] is Map) {
                        (currentModelData!['bedenler'] as Map).remove(entry.key);
                        // Toplam güncelle
                        int yeniToplam = 0;
                        (currentModelData!['bedenler'] as Map).forEach((k, v) {
                          yeniToplam += (v is int) ? v : (int.tryParse(v.toString()) ?? 0);
                        });
                        currentModelData?['toplam_adet'] = yeniToplam;
                      }
                    });
                  },
                  child: const Icon(Icons.remove_circle, color: Colors.red, size: 22),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          'Toplam: $toplamAdet adet',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final bedenController = TextEditingController();
            final adetController = TextEditingController();
            final result = await showDialog<Map<String, int>>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Yeni Beden Ekle'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: bedenController,
                      decoration: const InputDecoration(labelText: 'Beden (ör: XL)', border: OutlineInputBorder()),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: adetController,
                      decoration: const InputDecoration(labelText: 'Adet', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                  ElevatedButton(
                    onPressed: () {
                      final beden = bedenController.text.trim();
                      final adet = int.tryParse(adetController.text) ?? 0;
                      if (beden.isNotEmpty) {
                        Navigator.pop(ctx, {beden: adet});
                      }
                    },
                    child: const Text('Ekle'),
                  ),
                ],
              ),
            );
            if (result != null) {
              setState(() {
                if (currentModelData?['bedenler'] == null) {
                  currentModelData?['bedenler'] = <String, dynamic>{};
                }
                if (currentModelData?['bedenler'] is Map) {
                  (currentModelData!['bedenler'] as Map).addAll(result);
                  int yeniToplam = 0;
                  (currentModelData!['bedenler'] as Map).forEach((k, v) {
                    yeniToplam += (v is int) ? v : (int.tryParse(v.toString()) ?? 0);
                  });
                  currentModelData?['toplam_adet'] = yeniToplam;
                }
              });
            }
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Beden Ekle'),
        ),
      ],
    );
  }

}
