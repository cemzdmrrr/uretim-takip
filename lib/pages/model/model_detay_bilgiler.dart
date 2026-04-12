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
                _buildEditableField('toplam_adet', 'Toplam Adet', currentModelData?['toplam_adet']?.toString(), isNumber: true),
                _buildEditableField('durum', 'Durum', currentModelData?['durum']),
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
              'Termin & Notlar',
              Icons.event,
              Colors.red,
              [
                _buildEditableField('termin_tarihi', 'Termin Tarihi', utils.formatDate(currentModelData?['termin_tarihi'])),
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
    if (bedenler == null) {
      return const Text('Beden bilgisi yok', style: TextStyle(color: Colors.grey));
    }
    
    Map<String, dynamic> bedenMap = {};
    
    // bedenler JSONB formatını parse et
    if (bedenler is Map) {
      bedenMap = Map<String, dynamic>.from(bedenler);
    } else if (bedenler is String) {
      try {
        // JSON string ise parse et
        bedenMap = Map<String, dynamic>.from(
          (bedenler).isNotEmpty 
            ? Map<String, dynamic>.from(bedenler as dynamic) 
            : {}
        );
      } catch (e) {
        return Text(bedenler, style: const TextStyle(fontSize: 13));
      }
    } else if (bedenler is List) {
      // Liste formatındaysa
      for (var item in bedenler) {
        if (item is Map && item['beden'] != null) {
          bedenMap[item['beden'].toString()] = item['adet'] ?? 0;
        }
      }
    }
    
    if (bedenMap.isEmpty) {
      return const Text('Beden bilgisi yok', style: TextStyle(color: Colors.grey));
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

}
