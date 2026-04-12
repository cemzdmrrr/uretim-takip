import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonemSecici extends StatefulWidget {
  final String? seciliDonem;
  final Function(String?) onDonemChanged;
  final bool showAll;

  const DonemSecici({
    super.key,
    this.seciliDonem,
    required this.onDonemChanged,
    this.showAll = true,
  });

  @override
  State<DonemSecici> createState() => _DonemSeciciState();
}

class _DonemSeciciState extends State<DonemSecici> {
  List<Map<String, dynamic>> donemler = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _loadDonemler();
  }

  Future<void> _loadDonemler() async {
    try {
      final client = Supabase.instance.client;
      
      // Önce tablo yapısını kontrol et
      try {
        final testResponse = await client
            .from(DbTables.donemler)
            .select('*')
            .limit(1);
        debugPrint('Donemler tablo yapısı: $testResponse');
      } catch (e) {
        debugPrint('Donemler tablosu kontrol hatası: $e');
      }
      
      // Yeni yapıyı dene
      try {
        final response = await client
            .from(DbTables.donemler)
            .select('id, yil, ay, donem_adi, durum')
            .order('yil', ascending: false)
            .order('ay', ascending: false);
        
        setState(() {
          donemler = List<Map<String, dynamic>>.from(response);
          yukleniyor = false;
        });
        return;
      } catch (e) {
        debugPrint('Yeni yapı sorgusu hatası: $e');
      }
      
      // Eski yapıyı dene (fallback)
      try {
        final response = await client
            .from(DbTables.donemler)
            .select('*')
            .order('baslangic_tarihi', ascending: false);
        
        setState(() {
          donemler = List<Map<String, dynamic>>.from(response);
          yukleniyor = false;
        });
        return;
      } catch (e) {
        debugPrint('Eski yapı sorgusu hatası: $e');
      }
      
      // Hiçbiri çalışmazsa boş liste
      setState(() {
        donemler = [];
        yukleniyor = false;
      });
      
    } catch (e) {
      debugPrint('Dönem yükleme genel hatası: $e');
      setState(() {
        donemler = [];
        yukleniyor = false;
      });
    }
  }

  Future<String?> getAktifDonem() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from(DbTables.donemler)
          .select('donem_adi')
          .eq('durum', 'aktif')
          .maybeSingle();
      
      return response?['donem_adi'];
    } catch (e) {
      return null;
    }
  }

  String _getDuramRenk(String durum) {
    switch (durum) {
      case 'aktif':
        return 'AKTİF';
      case 'tamamlandi':
        return 'TAMAMLANDI';
      case 'arsivlendi':
        return 'ARŞİV';
      default:
        return durum.toUpperCase();
    }
  }

  Color _getDurumRengi(String durum) {
    switch (durum) {
      case 'aktif':
        return Colors.green;
      case 'tamamlandi':
        return Colors.orange;
      case 'arsivlendi':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const SizedBox(
        width: 140,
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Geçici çözüm: Basit dropdown
    final List<DropdownMenuItem<String>> menuItems = [];
    
    if (widget.showAll) {
      menuItems.add(const DropdownMenuItem<String>(
        value: null,
        child: Text('Tüm Dönemler'),
      ));
    }
    
    // Eğer dönem verisi yoksa sadece "Tüm Dönemler" göster
    if (donemler.isEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
        child: DropdownButtonFormField<String>(
          initialValue: null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Dönem Seçin',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: menuItems,
          onChanged: widget.onDonemChanged,
        ),
      );
    }

    // Normal dönemleri ekle
    final Set<String> eklenenDonemler = {}; // Tekrar eden değerleri önlemek için
    
    menuItems.addAll(donemler.map((donem) {
      // Yeni yapı için
      String donemAdi = donem['donem_adi'] ?? '';
      String durum = donem['durum'] ?? '';
      String displayText = '';
      
      if (donem['yil'] != null && donem['ay'] != null) {
        // Yeni yapı
        final yil = donem['yil']?.toString() ?? '';
        final ay = donem['ay']?.toString().padLeft(2, '0') ?? '';
        displayText = '$yil-$ay';
        if (donemAdi.isEmpty) donemAdi = displayText;
      } else {
        // Eski yapı için fallback
        donemAdi = donem['kod'] ?? donem['ad'] ?? donemAdi;
        displayText = donem['ad'] ?? donemAdi;
        durum = donem['aktif'] == true ? 'aktif' : 'tamamlandi';
      }
      
      // Boş değerler için fallback
      if (donemAdi.isEmpty) donemAdi = 'Dönem-${donem['id'] ?? ''}';
      if (displayText.isEmpty) displayText = donemAdi;
      
      // Tekrar eden değerleri önle
      if (eklenenDonemler.contains(donemAdi)) {
        donemAdi = '$donemAdi-${donem['id'] ?? DateTime.now().millisecondsSinceEpoch}';
      }
      eklenenDonemler.add(donemAdi);
      
      return DropdownMenuItem<String>(
        value: donemAdi,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayText,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (durum == 'aktif') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDurumRengi(durum),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getDuramRenk(durum),
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList());

    // Seçili dönemin items listesinde olup olmadığını kontrol et
    String? validSeciliDonem = widget.seciliDonem;
    if (validSeciliDonem != null && 
        !menuItems.any((item) => item.value == validSeciliDonem)) {
      validSeciliDonem = null; // Geçersizse null yap
      // Callback ile parent widget'a geçersiz dönemin temizlendiğini bildir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        {
          widget.onDonemChanged(null);
        }
      });
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      child: DropdownButtonFormField<String>(
        initialValue: validSeciliDonem,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Dönem Seçin',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: menuItems,
        onChanged: widget.onDonemChanged,
      ),
    );
  }
}

// Kullanım için yardımcı sınıf
class DonemHelper {
  static Future<String?> getAktifDonem() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from(DbTables.donemler)
          .select('donem_adi')
          .eq('durum', 'aktif')
          .maybeSingle();
      
      return response?['donem_adi'];
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllDonemler() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from(DbTables.donemler)
          .select('*')
          .order('yil', ascending: false)
          .order('ay', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  static String formatDonemTarihi(String? donem) {
    if (donem == null) return 'Tüm Dönemler';
    return donem;
  }

  static String ayAdi(int ay) {
    const aylar = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return ay >= 1 && ay <= 12 ? aylar[ay] : ay.toString();
  }
}
