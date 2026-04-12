import 'package:flutter/material.dart';
import 'package:uretim_takip/services/donem_service.dart';

class YeniDonemDialog extends StatefulWidget {
  final String kullaniciId;
  final VoidCallback? onDonemEklendi;

  const YeniDonemDialog({
    Key? key,
    required this.kullaniciId,
    this.onDonemEklendi,
  }) : super(key: key);

  @override
  State<YeniDonemDialog> createState() => _YeniDonemDialogState();
}

class _YeniDonemDialogState extends State<YeniDonemDialog> {
  final _formKey = GlobalKey<FormState>();
  int? secilenYil;
  int? secilenAy;
  bool yukleniyor = false;

  final List<int> yillar = List.generate(10, (index) => DateTime.now().year - 2 + index);
  final List<Map<String, dynamic>> aylar = [
    {'value': 1, 'name': 'Ocak'},
    {'value': 2, 'name': 'Şubat'},
    {'value': 3, 'name': 'Mart'},
    {'value': 4, 'name': 'Nisan'},
    {'value': 5, 'name': 'Mayıs'},
    {'value': 6, 'name': 'Haziran'},
    {'value': 7, 'name': 'Temmuz'},
    {'value': 8, 'name': 'Ağustos'},
    {'value': 9, 'name': 'Eylül'},
    {'value': 10, 'name': 'Ekim'},
    {'value': 11, 'name': 'Kasım'},
    {'value': 12, 'name': 'Aralık'},
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    secilenYil = now.year;
    secilenAy = now.month;
  }

  Future<void> _donemEkle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => yukleniyor = true);

    try {
      final sonuc = await DonemService.yeniDonemEkle(
        yil: secilenYil!,
        ay: secilenAy!,
        kullaniciId: widget.kullaniciId,
      );

      if (!mounted) return;

      if (sonuc['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sonuc['message']),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        if (widget.onDonemEklendi != null) {
          widget.onDonemEklendi!();
        }
        
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sonuc['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.calendar_month, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          const Text('Yeni Dönem Ekle'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yeni dönem eklediğinizde:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Mevcut aktif dönem tamamlanacak'),
              const Text('• Tüm personel için yeni dönem kayıtları oluşturulacak'),
              const Text('• Eski veriler korunacak'),
              const SizedBox(height: 24),
              
              // Yıl Seçimi
              DropdownButtonFormField<int>(
                initialValue: secilenYil,
                decoration: const InputDecoration(
                  labelText: 'Yıl',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: yillar.map((yil) {
                  return DropdownMenuItem(
                    value: yil,
                    child: Text(yil.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => secilenYil = value);
                },
                validator: (value) {
                  if (value == null) return 'Yıl seçiniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Ay Seçimi
              DropdownButtonFormField<int>(
                initialValue: secilenAy,
                decoration: const InputDecoration(
                  labelText: 'Ay',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                items: aylar.map((ay) {
                  return DropdownMenuItem<int>(
                    value: ay['value'] as int,
                    child: Text(ay['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => secilenAy = value);
                },
                validator: (value) {
                  if (value == null) return 'Ay seçiniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Seçilen dönem önizlemesi
              if (secilenYil != null && secilenAy != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Oluşturulacak dönem: $secilenYil-${secilenAy!.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: yukleniyor ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: yukleniyor ? null : _donemEkle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          child: yukleniyor
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Dönem Ekle'),
        ),
      ],
    );
  }
}
