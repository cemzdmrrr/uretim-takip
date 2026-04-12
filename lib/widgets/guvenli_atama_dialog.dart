// GÜVENLİ ÜRETİM ATAMA DIALOG'U
// Email bazlı atama ile firma izolasyonu

import 'package:flutter/material.dart';
import 'package:uretim_takip/services/uretim_zinciri_service.dart';

class GuvenliAtamaDialog extends StatefulWidget {
  final List<String> seciliModelIdleri;
  final String varsayilanAsama;

  const GuvenliAtamaDialog({
    Key? key,
    required this.seciliModelIdleri,
    this.varsayilanAsama = 'dokuma',
  }) : super(key: key);

  @override
  State<GuvenliAtamaDialog> createState() => _GuvenliAtamaDialogState();
}

class _GuvenliAtamaDialogState extends State<GuvenliAtamaDialog> {
  final _service = UretimZinciriService();
  final _notlarController = TextEditingController();
  
  String? _seciliAsama;
  String? _seciliPersonelEmail;
  List<Map<String, dynamic>> _personeller = [];
  bool _yukleniyor = false;
  bool _atamaYapiliyor = false;

  @override
  void initState() {
    super.initState();
    _seciliAsama = widget.varsayilanAsama;
    _personelleriYukle();
  }

  Future<void> _personelleriYukle() async {
    if (_seciliAsama == null) return;
    
    setState(() => _yukleniyor = true);
    
    try {
      final atolyeler = await _service.getStagePersonnel(_seciliAsama!);
      
      // Atölye verilerini personel formatına çevir
      final List<Map<String, dynamic>> personeller = atolyeler.map((atolye) {
        return {
          'email': atolye['email'] ?? '${atolye['atolye_adi']?.toString().toLowerCase().replaceAll(' ', '')}@atolye.com',
          'display_name': atolye['atolye_adi'] ?? 'Bilinmeyen Atölye',
          'firma_adi': atolye['atolye_turu'] ?? 'Genel',
          'telefon': atolye['telefon'],
          'adres': atolye['adres'],
          'kapasitesi': atolye['kapasitesi'],
          'atolye_id': atolye['id'],
        };
      }).toList();
      
      // Duplicate email'leri temizle - benzersiz email'ler al
      final Map<String, Map<String, dynamic>> benzersizPersoneller = {};
      for (final personel in personeller) {
        final email = personel['email'] as String;
        if (!benzersizPersoneller.containsKey(email)) {
          benzersizPersoneller[email] = personel;
        } else {
          // Eğer aynı email tekrar gelirse, daha detaylı olanı koru
          final mevcut = benzersizPersoneller[email]!;
          if ((personel['display_name'] as String? ?? '').length > 
              (mevcut['display_name'] as String? ?? '').length) {
            benzersizPersoneller[email] = personel;
          }
        }
      }
      
      setState(() {
        _personeller = benzersizPersoneller.values.toList()
          ..sort((a, b) => (a['display_name'] ?? '').toString()
              .compareTo((b['display_name'] ?? '').toString()));
        _seciliPersonelEmail = null; // Reset selection
      });
    } catch (e) {
      debugPrint('Atölye listesi yükleme hatası: $e');
      _showError('Atölye listesi yüklenemedi: $e');
    }
    
    setState(() => _yukleniyor = false);
  }



  Future<void> _atamaYap() async {
    if (_seciliPersonelEmail == null || _seciliAsama == null) {
      _showError('Lütfen personel ve aşama seçin');
      return;
    }

    setState(() => _atamaYapiliyor = true);

    try {
      // Model ID'leri UUID string formatında kullan (triko_takip tablosu UUID kullanıyor)
      final result = await _service.assignModelsToUser(
        modelIds: widget.seciliModelIdleri,
        assigneeEmail: _seciliPersonelEmail!,
        stageName: _seciliAsama!,
        notes: _notlarController.text.trim(),
      );

      if (result['success'] == true) {
        // Başarılı atama sonrası detaylı bilgi döndür
        if (!mounted) return;
        Navigator.of(context).pop({
          'success': true,
          'message': '${result['assigned_count']} model başarıyla atandı',
          'assignee': _seciliPersonelEmail,
          'stage': _seciliAsama,
          'assigned_count': result['assigned_count'],
          'model_ids': widget.seciliModelIdleri,
          'refresh_needed': true, // Dashboard'ları yenilemek için flag
        });
      } else {
        _showError(result['error'] ?? 'Atama işlemi başarısız');
      }
    } catch (e) {
      _showError('Atama hatası: $e');
    }

    setState(() => _atamaYapiliyor = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.assignment_ind, color: Colors.blue),
          SizedBox(width: 8),
          Text('Güvenli Model Atama'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seçili model sayısı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.seciliModelIdleri.length} model atanacak',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Üretim aşaması seçimi
            const Text(
              'Üretim Aşaması',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _seciliAsama,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings),
              ),
              items: const [
                DropdownMenuItem(value: 'dokuma', child: Text('🧵 Dokuma/Örgü')),
                DropdownMenuItem(value: 'konfeksiyon', child: Text('✂️ Konfeksiyon')),
                DropdownMenuItem(value: 'yikama', child: Text('🧼 Yıkama')),
                DropdownMenuItem(value: 'nakis', child: Text('🎨 Nakış')),
                DropdownMenuItem(value: 'ilik_dugme', child: Text('🔘 İlik Düğme')),
                DropdownMenuItem(value: 'utu', child: Text('🔥 Ütü')),
                DropdownMenuItem(value: 'kalite_kontrol', child: Text('✅ Kalite Kontrol')),
                DropdownMenuItem(value: 'sevkiyat', child: Text('📦 Sevkiyat')),
              ],
              onChanged: (value) {
                setState(() {
                  _seciliAsama = value;
                  _seciliPersonelEmail = null;
                });
                _personelleriYukle();
              },
            ),
            const SizedBox(height: 16),

            // Personel seçimi
            const Text(
              'Atanacak Personel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            
            if (_yukleniyor)
              Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Personeller yükleniyor...'),
                    ],
                  ),
                ),
              )
            else if (_personeller.isEmpty)
              Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.orange.shade50,
                ),
                child: Center(
                  child: Text(
                    'Bu aşamada aktif personel bulunamadı',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _seciliPersonelEmail,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Personel seçin...',
                ),
                items: _personeller.map((atolye) {
                  final email = atolye['email'] as String;
                  final atolyeAdi = atolye['display_name'] as String? ?? email;
                  final atolyeTuru = atolye['firma_adi'] as String? ?? '';
                  final telefon = atolye['telefon'] as String?;
                  final kapasitesi = atolye['kapasitesi']?.toString();
                  
                  String itemText = atolyeAdi;
                  if (atolyeTuru.isNotEmpty) itemText += ' - $atolyeTuru';
                  if (telefon != null && telefon.isNotEmpty) itemText += ' ($telefon)';
                  if (kapasitesi != null) itemText += ' [Kapasite: $kapasitesi]';
                  
                  // Debug için email'i de göster (geliştirme aşamasında)
                  itemText += ' [$email]';
                  
                  return DropdownMenuItem<String>(
                    value: email,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        itemText,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toSet().toList(), // Set kullanarak duplicate'ları temizle
                onChanged: (value) {
                  setState(() => _seciliPersonelEmail = value);
                },
              ),
            
            const SizedBox(height: 16),

            // Notlar
            const Text(
              'Atama Notları (İsteğe bağlı)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notlarController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Atama ile ilgili notlar...',
              ),
              maxLines: 3,
            ),

            // Güvenlik bilgisi
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sadece yetkilendirilmiş personel bu modelleri görebilecek',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _atamaYapiliyor ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _atamaYapiliyor || _seciliPersonelEmail == null 
              ? null 
              : _atamaYap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _atamaYapiliyor
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Atanıyor...'),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_turned_in, size: 16),
                    SizedBox(width: 4),
                    Text('Ata'),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notlarController.dispose();
    super.dispose();
  }
}

// Kullanım örneği:
/*
// Model listesi sayfasında:
Future<void> _guvenliAtamaYap() async {
  if (_seciliModeller.isEmpty) {
    context.showSnackBar('Lütfen atanacak modelleri seçin');
    return;
  }

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => GuvenliAtamaDialog(
      seciliModelIdleri: _seciliModeller,
      varsayilanAsama: 'dokuma',
    ),
  );

  if (result != null && result['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: Colors.green,
      ),
    );
    
    // Listeyi yenile
    _modelleriYenile();
    
    // Seçimi temizle
    setState(() => _seciliModeller.clear());
  }
}
*/
