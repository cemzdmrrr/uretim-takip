import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ModelKritikleriDialog extends StatefulWidget {
  final dynamic modelId;
  final String modelMarka;
  final String modelItemNo;

  const ModelKritikleriDialog({
    Key? key,
    required this.modelId,
    required this.modelMarka,
    required this.modelItemNo,
  }) : super(key: key);

  @override
  State<ModelKritikleriDialog> createState() => _ModelKritikleriDialogState();
}

class _ModelKritikleriDialogState extends State<ModelKritikleriDialog> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> kritikler = [];
  bool yukleniyor = true;
  bool yeniKritikEkleniyor = false;

  // Yeni kritik form alanları
  final TextEditingController _baslikController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  String _secilikritikTuru = 'genel';
  String _seciliOncelik = 'orta';

  final List<String> kritikTurleri = [
    'genel', 'uretim', 'kalite', 'maliyet', 'teslimat'
  ];

  final List<String> oncelikler = [
    'dusuk', 'orta', 'yuksek', 'kritik'
  ];

  @override
  void initState() {
    super.initState();
    _kritikleriGetir();
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  Future<void> _kritikleriGetir() async {
    try {
      setState(() {
        yukleniyor = true;
      });

      // Model ID'yi UUID string olarak kullan (triko_takip tablosu UUID kullanıyor)
      final String modelIdStr = widget.modelId.toString();

      final response = await supabase
          .from(DbTables.modelKritikleri)
          .select('*')
          .eq('model_id', modelIdStr)
          .order('olusturma_tarihi', ascending: false);

      setState(() {
        kritikler = List<Map<String, dynamic>>.from(response);
        yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        yukleniyor = false;
      });
      if (mounted) {
        context.showErrorSnackBar('Kritikler yüklenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _yeniKritikEkle() async {
    if (_baslikController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kritik başlığı boş olamaz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        context.showErrorSnackBar('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Model ID'yi UUID string olarak kullan
      final String modelIdStr = widget.modelId.toString();

      await supabase.from(DbTables.modelKritikleri).insert({
        'model_id': modelIdStr,
        'kritik_baslik': _baslikController.text.trim(),
        'kritik_aciklama': _aciklamaController.text.trim(),
        'kritik_turu': _secilikritikTuru,
        'oncelik': _seciliOncelik,
        'durum': 'aktif',
        'olusturan_kullanici_id': user.id,
      });

      // Form alanlarını temizle
      _baslikController.clear();
      _aciklamaController.clear();
      _secilikritikTuru = 'genel';
      _seciliOncelik = 'orta';

      setState(() {
        yeniKritikEkleniyor = false;
      });

      // Kritikleri yeniden yükle
      await _kritikleriGetir();

      if (mounted) {
        context.showSuccessSnackBar('Kritik başarıyla eklendi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Kritik eklenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _kritigiGuncelle(int kritikId, Map<String, dynamic> guncelData) async {
    try {
      await supabase
          .from(DbTables.modelKritikleri)
          .update(guncelData)
          .eq('id', kritikId);

      await _kritikleriGetir();

      if (mounted) {
        context.showSuccessSnackBar('Kritik başarıyla güncellendi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Kritik güncellenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _kritigiSil(int kritikId) async {
    try {
      await supabase
          .from(DbTables.modelKritikleri)
          .delete()
          .eq('id', kritikId);

      await _kritikleriGetir();

      if (mounted) {
        context.showSuccessSnackBar('Kritik başarıyla silindi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Kritik silinirken hata oluştu: $e');
      }
    }
  }

  Color _getOncelikRengi(String oncelik) {
    switch (oncelik) {
      case 'kritik':
        return Colors.red;
      case 'yuksek':
        return Colors.orange;
      case 'orta':
        return Colors.yellow[700]!;
      case 'dusuk':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getOncelikText(String oncelik) {
    switch (oncelik) {
      case 'kritik':
        return 'KRİTİK';
      case 'yuksek':
        return 'YÜKSEK';
      case 'orta':
        return 'ORTA';
      case 'dusuk':
        return 'DÜŞÜK';
      default:
        return oncelik.toUpperCase();
    }
  }

  String _getKritikTuruText(String tur) {
    switch (tur) {
      case 'uretim':
        return 'Üretim';
      case 'kalite':
        return 'Kalite';
      case 'maliyet':
        return 'Maliyet';
      case 'teslimat':
        return 'Teslimat';
      case 'genel':
        return 'Genel';
      default:
        return tur;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Model Kritikleri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        '${widget.modelMarka} - ${widget.modelItemNo}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),

            // Yeni kritik ekleme butonu
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        yeniKritikEkleniyor = !yeniKritikEkleniyor;
                      });
                    },
                    icon: Icon(yeniKritikEkleniyor ? Icons.close : Icons.add),
                    label: Text(yeniKritikEkleniyor ? 'İptal' : 'Yeni Kritik Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yeniKritikEkleniyor ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Yeni kritik ekleme formu
            if (yeniKritikEkleniyor) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yeni Kritik Bilgisi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Kritik başlığı
                    TextFormField(
                      controller: _baslikController,
                      decoration: InputDecoration(
                        labelText: 'Kritik Başlığı *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8
                        ),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    
                    // Kritik açıklaması
                    TextFormField(
                      controller: _aciklamaController,
                      decoration: InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    
                    // Kritik türü ve öncelik
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _secilikritikTuru,
                            decoration: InputDecoration(
                              labelText: 'Kritik Türü',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8
                              ),
                            ),
                            items: kritikTurleri.map((tur) => DropdownMenuItem(
                              value: tur,
                              child: Text(_getKritikTuruText(tur)),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _secilikritikTuru = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _seciliOncelik,
                            decoration: InputDecoration(
                              labelText: 'Öncelik',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8
                              ),
                            ),
                            items: oncelikler.map((oncelik) => DropdownMenuItem(
                              value: oncelik,
                              child: Text(_getOncelikText(oncelik)),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _seciliOncelik = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _yeniKritikEkle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Kritik Ekle'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Kritikler listesi
            Expanded(
              child: yukleniyor
                  ? const LoadingWidget()
                  : kritikler.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Bu model için kritik bilgi bulunamadı',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: kritikler.length,
                          itemBuilder: (context, index) {
                            final kritik = kritikler[index];
                            return _buildKritikKarti(kritik);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKritikKarti(Map<String, dynamic> kritik) {
    final olusturmaTarihi = DateTime.parse(kritik['olusturma_tarihi']);
    final tarihFormatter = DateFormat('dd.MM.yyyy HH:mm');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım - Başlık ve öncelik
            Row(
              children: [
                Expanded(
                  child: Text(
                    kritik['kritik_baslik'] ?? 'Başlık Yok',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOncelikRengi(kritik['oncelik']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getOncelikText(kritik['oncelik']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'cozuldu':
                        _kritigiGuncelle(kritik['id'], {
                          'durum': 'cozuldu',
                          'cozum_tarihi': DateTime.now().toIso8601String(),
                        });
                        break;
                      case 'aktif':
                        _kritigiGuncelle(kritik['id'], {
                          'durum': 'aktif',
                          'cozum_tarihi': null,
                          'cozum_aciklamasi': null,
                        });
                        break;
                      case 'sil':
                        _showDeleteConfirmation(kritik['id']);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (kritik['durum'] == 'aktif')
                      const PopupMenuItem(
                        value: 'cozuldu',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Çözüldü olarak işaretle'),
                          ],
                        ),
                      ),
                    if (kritik['durum'] == 'cozuldu')
                      const PopupMenuItem(
                        value: 'aktif',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Aktif olarak işaretle'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'sil',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Kritik türü ve durum
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getKritikTuruText(kritik['kritik_turu']),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kritik['durum'] == 'cozuldu' ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kritik['durum'] == 'cozuldu' ? Icons.check_circle : Icons.warning,
                        size: 12,
                        color: kritik['durum'] == 'cozuldu' ? Colors.green[700] : Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kritik['durum'] == 'cozuldu' ? 'Çözüldü' : 'Aktif',
                        style: TextStyle(
                          color: kritik['durum'] == 'cozuldu' ? Colors.green[700] : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Açıklama
            if (kritik['kritik_aciklama'] != null && kritik['kritik_aciklama'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  kritik['kritik_aciklama'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],

            // Tarih bilgisi
            const SizedBox(height: 12),
            Text(
              'Oluşturulma: ${tarihFormatter.format(olusturmaTarihi)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            
            // Çözüm tarihi (varsa)
            if (kritik['cozum_tarihi'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Çözüm: ${tarihFormatter.format(DateTime.parse(kritik['cozum_tarihi']))}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int kritikId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kritik Sil'),
        content: const Text('Bu kritiği silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _kritigiSil(kritikId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}