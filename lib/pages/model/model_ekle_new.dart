import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/theme/app_theme.dart';

class ModelEkle extends StatefulWidget {
  const ModelEkle({Key? key}) : super(key: key);

  @override
  State<ModelEkle> createState() => _ModelEkleState();
}

class _ModelEkleState extends State<ModelEkle> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = false;

  // Form Controllers
  final _markaController = TextEditingController();
  final _itemNoController = TextEditingController();
  final _modelAdiController = TextEditingController();
  final _koleksiyonController = TextEditingController();
  final _iplikKarisimiController = TextEditingController();
  final _iplikMarkasiController = TextEditingController();
  final _iplikRenkKoduController = TextEditingController();
  final _iplikNumarasiController = TextEditingController();
  final _desenDetayiController = TextEditingController();
  final _renkKombinasyonuController = TextEditingController();
  final _gramajController = TextEditingController();
  final _orguFirmasiController = TextEditingController();
  final _iplikTedarikciController = TextEditingController();
  final _boyahaneController = TextEditingController();
  final _ilikDugmeController = TextEditingController();
  final _konfeksiyonController = TextEditingController();
  final _utuPresController = TextEditingController();
  final _yikamaController = TextEditingController();
  final _igneNoController = TextEditingController();
  final _gaugeController = TextEditingController();
  final _teknikGramajController = TextEditingController();
  final _ozelTalimatlarController = TextEditingController();
  final _genelNotlarController = TextEditingController();

  // Dropdown'lar yerine manuel giriş controller'ları
  final _sezonController = TextEditingController();
  final _urunKategorisiController = TextEditingController();
  final _trikoTipiController = TextEditingController();
  final _cinsiyetController = TextEditingController();
  final _yasGrubuController = TextEditingController();
  final _yakaTipiController = TextEditingController();
  final _kolTipiController = TextEditingController();
  final _anaIplikTuruController = TextEditingController();
  final _iplikKalinligiController = TextEditingController();
  final _desenTipiController = TextEditingController();
  final _makineTipiController = TextEditingController();
  final _orguSikligiController = TextEditingController();
  final _durumController = TextEditingController();

  // Date fields
  DateTime? _siparisTarihi;
  DateTime? _terminTarihi;

  // Beden dağılımı - Dinamik liste
  final List<Map<String, dynamic>> _bedenler = [
    {'beden': 'S', 'adet': 0, 'bedenController': TextEditingController(text: 'S'), 'adetController': TextEditingController()},
    {'beden': 'M', 'adet': 0, 'bedenController': TextEditingController(text: 'M'), 'adetController': TextEditingController()},
    {'beden': 'L', 'adet': 0, 'bedenController': TextEditingController(text: 'L'), 'adetController': TextEditingController()},
  ];

  @override
  void dispose() {
    _markaController.dispose();
    _itemNoController.dispose();
    _modelAdiController.dispose();
    _koleksiyonController.dispose();
    _iplikKarisimiController.dispose();
    _iplikMarkasiController.dispose();
    _iplikRenkKoduController.dispose();
    _iplikNumarasiController.dispose();
    _desenDetayiController.dispose();
    _renkKombinasyonuController.dispose();
    _gramajController.dispose();
    _orguFirmasiController.dispose();
    _iplikTedarikciController.dispose();
    _boyahaneController.dispose();
    _ilikDugmeController.dispose();
    _konfeksiyonController.dispose();
    _utuPresController.dispose();
    _yikamaController.dispose();
    _igneNoController.dispose();
    _gaugeController.dispose();
    _teknikGramajController.dispose();
    _ozelTalimatlarController.dispose();
    _genelNotlarController.dispose();
    
    // Yeni manuel giriş controller'ları
    _sezonController.dispose();
    _urunKategorisiController.dispose();
    _trikoTipiController.dispose();
    _cinsiyetController.dispose();
    _yasGrubuController.dispose();
    _yakaTipiController.dispose();
    _kolTipiController.dispose();
    _anaIplikTuruController.dispose();
    _iplikKalinligiController.dispose();
    _desenTipiController.dispose();
    _makineTipiController.dispose();
    _orguSikligiController.dispose();
    _durumController.dispose();
    
    // Beden controller'larını dispose et
    for (var beden in _bedenler) {
      beden['bedenController']?.dispose();
      beden['adetController']?.dispose();
    }
    
    super.dispose();
  }

  int _calculateTotalQuantity() {
    int total = 0;
    for (var beden in _bedenler) {
      final controller = beden['adetController'] as TextEditingController;
      if (controller.text.isNotEmpty) {
        total += int.tryParse(controller.text) ?? 0;
      }
    }
    return total;
  }

  Future<void> _saveModel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Beden dağılımını JSON formatına çevir
      final bedenDagilimi = <String, dynamic>{};
      for (var beden in _bedenler) {
        final bedenController = beden['bedenController'] as TextEditingController;
        final adetController = beden['adetController'] as TextEditingController;
        if (bedenController.text.isNotEmpty && adetController.text.isNotEmpty) {
          final adet = int.tryParse(adetController.text) ?? 0;
          if (adet > 0) {
            bedenDagilimi[bedenController.text.trim()] = adet;
          }
        }
      }

      final modelData = {
        'marka': _markaController.text,
        'item_no': _itemNoController.text,
        'model_adi': _modelAdiController.text,
        'sezon': _sezonController.text,
        'koleksiyon': _koleksiyonController.text,
        'urun_kategorisi': _urunKategorisiController.text,
        'triko_tipi': _trikoTipiController.text,
        'cinsiyet': _cinsiyetController.text,
        'yas_grubu': _yasGrubuController.text,
        'yaka_tipi': _yakaTipiController.text,
        'kol_tipi': _kolTipiController.text,
        'ana_iplik_turu': _anaIplikTuruController.text,
        'iplik_karisimi': _iplikKarisimiController.text,
        'iplik_kalinligi': _iplikKalinligiController.text,
        'iplik_markasi': _iplikMarkasiController.text,
        'iplik_renk_kodu': _iplikRenkKoduController.text,
        'iplik_numarasi': _iplikNumarasiController.text,
        'desen_tipi': _desenTipiController.text,
        'desen_detayi': _desenDetayiController.text,
        'renk_kombinasyonu': _renkKombinasyonuController.text,
        'bedenler': bedenDagilimi,
        'toplam_adet': _calculateTotalQuantity(),
        'gramaj': _gramajController.text,
        'orgu_firmasi': _orguFirmasiController.text,
        'iplik_tedarikci': _iplikTedarikciController.text,
        'boyahane': _boyahaneController.text,
        'ilik_dugme_metal_aksesuar': _ilikDugmeController.text,
        'konfeksiyon_firmasi': _konfeksiyonController.text,
        'utu_pres_firmasi': _utuPresController.text,
        'yikama_firmasi': _yikamaController.text,
        'makine_tipi': _makineTipiController.text,
        'igne_no': _igneNoController.text,
        'gauge': _gaugeController.text,
        'orgu_sikligi': _orguSikligiController.text,
        'teknik_gramaj': _teknikGramajController.text,
        'siparis_tarihi': _siparisTarihi?.toIso8601String(),
        'termin_tarihi': _terminTarihi?.toIso8601String(),
        'durum': _durumController.text.isNotEmpty ? _durumController.text : 'Beklemede',
        'ozel_talimatlar': _ozelTalimatlarController.text,
        'genel_notlar': _genelNotlarController.text,
      };

      await _supabase.from(DbTables.trikoTakip).insert(modelData);

      if (mounted) {
        context.showSuccessSnackBar('Model başarıyla kaydedildi!');
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('Hata: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Triko/Dokuma Modeli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveModel,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Temel Model Bilgileri
                    _buildSectionTitle('1. Temel Model Bilgileri'),
                    _buildTextFormField(
                      controller: _markaController,
                      label: 'Marka *',
                      validator: (value) => value?.isEmpty ?? true ? 'Marka gerekli' : null,
                    ),
                    _buildTextFormField(
                      controller: _itemNoController,
                      label: 'Model Kodu *',
                      hint: 'örn: TRK001-2025',
                      validator: (value) => value?.isEmpty ?? true ? 'Model kodu gerekli' : null,
                    ),
                    _buildTextFormField(
                      controller: _modelAdiController,
                      label: 'Model Adı',
                      hint: 'örn: Basic Crew Neck Sweater',
                    ),
                    _buildTextFormField(
                      controller: _sezonController,
                      label: 'Sezon',
                      hint: 'örn: İlkbahar/Yaz, Sonbahar/Kış, Tüm Sezon',
                    ),
                    _buildTextFormField(
                      controller: _koleksiyonController,
                      label: 'Koleksiyon',
                      hint: 'örn: 2025 Kış Koleksiyonu',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 2. Ürün Detayları
                    _buildSectionTitle('2. Ürün Detayları'),
                    _buildTextFormField(
                      controller: _urunKategorisiController,
                      label: 'Ürün Kategorisi',
                      hint: 'örn: Kazak, Hırka, Yelek, Elbise, Pantolon',
                    ),
                    _buildTextFormField(
                      controller: _trikoTipiController,
                      label: 'Triko Tipi',
                      hint: 'örn: Düz örgü, Rib, Kablo, Jakarlı, Fair Isle',
                    ),
                    _buildTextFormField(
                      controller: _cinsiyetController,
                      label: 'Cinsiyet',
                      hint: 'örn: Erkek, Kadın, Çocuk, Unisex',
                    ),
                    _buildTextFormField(
                      controller: _yasGrubuController,
                      label: 'Yaş Grubu',
                      hint: 'örn: Yetişkin, Çocuk (2-12), Bebek (0-2)',
                    ),
                    _buildTextFormField(
                      controller: _yakaTipiController,
                      label: 'Yaka Tipi',
                      hint: 'örn: Bisiklet yaka, V yaka, Polo yaka, Balıkçı yaka',
                    ),
                    _buildTextFormField(
                      controller: _kolTipiController,
                      label: 'Kol Tipi',
                      hint: 'örn: Uzun kol, Kısa kol, Kolsuz, 3/4 kol',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 3. İplik ve Materyal
                    _buildSectionTitle('3. İplik ve Materyal Bilgileri'),
                    _buildTextFormField(
                      controller: _anaIplikTuruController,
                      label: 'Ana İplik Türü',
                      hint: 'örn: Pamuk, Yün, Akrilik, Kaşmir, Alpaka',
                    ),
                    _buildTextFormField(
                      controller: _iplikKarisimiController,
                      label: 'İplik Karışımı',
                      hint: 'örn: %50 Pamuk %50 Akrilik',
                    ),
                    _buildTextFormField(
                      controller: _iplikKalinligiController,
                      label: 'İplik Kalınlığı',
                      hint: 'örn: Fine (İnce), Medium (Orta), Chunky (Kalın)',
                    ),
                    _buildTextFormField(
                      controller: _iplikMarkasiController,
                      label: 'İplik Markası',
                      hint: 'örn: Pamukkale, Kartopu, Nako',
                    ),
                    _buildTextFormField(
                      controller: _iplikRenkKoduController,
                      label: 'İplik Renk Kodu',
                      hint: 'Pantone/RAL renk kodları',
                    ),
                    _buildTextFormField(
                      controller: _iplikNumarasiController,
                      label: 'İplik Numarası',
                      hint: 'örn: Ne 20/1, Ne 30/1',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 4. Renk ve Desen
                    _buildSectionTitle('4. Renk ve Desen'),
                    _buildTextFormField(
                      controller: _desenTipiController,
                      label: 'Desen Tipi',
                      hint: 'örn: Düz, Çizgili, Noktalı, Jakarlı desen, Argyle',
                    ),
                    _buildTextFormField(
                      controller: _desenDetayiController,
                      label: 'Desen Detayı',
                      hint: 'Desen açıklaması veya kodu',
                    ),
                    _buildTextFormField(
                      controller: _renkKombinasyonuController,
                      label: 'Renk Kombinasyonu',
                      hint: 'Ana renk + yardımcı renkler',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 5. Beden Dağılımı
                    _buildSectionTitle('5. Beden Dağılımı'),
                    _buildBedenDagilimi(),
                    
                    const SizedBox(height: 20),
                    
                    // 6. Ölçü Bilgileri
                    _buildSectionTitle('6. Ölçü Bilgileri'),
                    _buildTextFormField(
                      controller: _gramajController,
                      label: 'Gramaj',
                      hint: 'örn: 200g/m², 350g/m²',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 7. Üretim Zinciri
                    _buildSectionTitle('7. Üretim Zinciri'),
                    _buildTextFormField(
                      controller: _orguFirmasiController,
                      label: 'Örgü Firması',
                      hint: 'Hangi firma örgüyü yapacak',
                    ),
                    _buildTextFormField(
                      controller: _iplikTedarikciController,
                      label: 'İplik Tedarikçi',
                      hint: 'İplik nereden gelecek',
                    ),
                    _buildTextFormField(
                      controller: _boyahaneController,
                      label: 'Boyahane',
                      hint: 'Boyama işlemi yapılacak yer',
                    ),
                    _buildTextFormField(
                      controller: _ilikDugmeController,
                      label: 'İlik Düğme/Metal Aksesuar',
                      hint: 'Aksesuar takılacak yer',
                    ),
                    _buildTextFormField(
                      controller: _konfeksiyonController,
                      label: 'Konfeksiyon Firması',
                      hint: 'Dikiş ve birleştirme',
                    ),
                    _buildTextFormField(
                      controller: _utuPresController,
                      label: 'Ütü/Pres Firması',
                      hint: 'Finishing işlemleri',
                    ),
                    _buildTextFormField(
                      controller: _yikamaController,
                      label: 'Yıkama Firması',
                      hint: 'Özel yıkama gerektiriyorsa',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 8. Teknik Örgü Bilgileri
                    _buildSectionTitle('8. Teknik Örgü Bilgileri'),
                    _buildTextFormField(
                      controller: _makineTipiController,
                      label: 'Makine Tipi',
                      hint: 'örn: Yuvarlak örgü, Düz örgü, Raschel',
                    ),
                    _buildTextFormField(
                      controller: _igneNoController,
                      label: 'İğne No',
                      hint: 'örn: E7, E10, E12, E14',
                    ),
                    _buildTextFormField(
                      controller: _gaugeController,
                      label: 'Gauge',
                      hint: 'örn: 5gg, 7gg, 12gg, 14gg',
                    ),
                    _buildTextFormField(
                      controller: _orguSikligiController,
                      label: 'Örgü Sıklığı',
                      hint: 'örn: Gevşek, Normal, Sıkı',
                    ),
                    _buildTextFormField(
                      controller: _teknikGramajController,
                      label: 'Teknik Gramaj',
                      hint: 'örn: 200g/m², 350g/m²',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 9. Tarihler ve Durum
                    _buildSectionTitle('9. Tarihler ve Durum'),
                    _buildDatePicker(
                      label: 'Sipariş Tarihi',
                      selectedDate: _siparisTarihi,
                      onDateSelected: (date) => setState(() => _siparisTarihi = date),
                    ),
                    _buildDatePicker(
                      label: 'Termin Tarihi',
                      selectedDate: _terminTarihi,
                      onDateSelected: (date) => setState(() => _terminTarihi = date),
                    ),
                    _buildTextFormField(
                      controller: _durumController,
                      label: 'Durum',
                      hint: 'örn: Beklemede, Planlama, Üretim, Tamamlandı, İptal',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 10. Notlar
                    _buildSectionTitle('10. Notlar ve Talimatlar'),
                    _buildTextFormField(
                      controller: _ozelTalimatlarController,
                      label: 'Özel Talimatlar',
                      hint: 'Model için özel notlar',
                      maxLines: 3,
                    ),
                    _buildTextFormField(
                      controller: _genelNotlarController,
                      label: 'Genel Notlar',
                      hint: 'Genel açıklamalar',
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveModel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Modeli Kaydet', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal),
          ),
        ),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required void Function(DateTime) onDateSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            locale: const Locale('tr'),
          );
          if (date != null) {
            onDateSelected(date);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDate != null
                    ? '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}'
                    : label,
                style: TextStyle(
                  color: selectedDate != null ? Colors.black : Colors.grey,
                ),
              ),
              const Icon(Icons.calendar_today),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBedenDagilimi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Toplam Adet: ${_calculateTotalQuantity()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addBeden,
              icon: const Icon(Icons.add),
              label: const Text('Beden Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Beden listesi
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bedenler.length,
          itemBuilder: (context, index) {
            final beden = _bedenler[index];
            final bedenController = beden['bedenController'] as TextEditingController;
            final adetController = beden['adetController'] as TextEditingController;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  // Beden input
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: bedenController,
                      decoration: InputDecoration(
                        labelText: 'Beden',
                        hintText: 'örn: S, M, L, 38, 40',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Adet input
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: adetController,
                      decoration: InputDecoration(
                        labelText: 'Adet',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}), // Toplam hesaplamak için
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Sil butonu
                  IconButton(
                    onPressed: _bedenler.length > 1 ? () => _removeBeden(index) : null,
                    icon: const Icon(Icons.delete),
                    color: AppTheme.errorColor,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _addBeden() {
    setState(() {
      _bedenler.add({
        'beden': '',
        'adet': 0,
        'bedenController': TextEditingController(),
        'adetController': TextEditingController(),
      });
    });
  }

  void _removeBeden(int index) {
    if (_bedenler.length > 1) {
      setState(() {
        _bedenler[index]['bedenController']?.dispose();
        _bedenler[index]['adetController']?.dispose();
        _bedenler.removeAt(index);
      });
    }
  }
}
