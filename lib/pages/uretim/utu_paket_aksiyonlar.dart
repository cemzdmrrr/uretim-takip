// ignore_for_file: invalid_use_of_protected_member
part of 'utu_paket_dashboard.dart';

/// Temel aksiyonlar (onayla, reddet, başla) ve detay görünümü for _UtuPaketDashboardState.
extension _AksiyonlarExt on _UtuPaketDashboardState {
  // ============ AKSİYONLAR ============

  Future<void> _onayla(Map<String, dynamic> atama, String tip) async {
    try {
      final tablo = tip == 'utu' ? DbTables.utuAtamalari : DbTables.paketlemeAtamalari;
      await supabase.from(tablo).update({
        'durum': 'onaylandi',
        'onay_tarihi': DateTime.now().toIso8601String(),
      }).eq('id', atama['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Atama onaylandı'), backgroundColor: Colors.green),
        );
        // Onaylanan sekmesine otomatik geç
        _tabController.animateTo(1);
        _verileriYukle();
      }
    } catch (e) {
      _hataGoster('Onaylama hatası: $e');
    }
  }

  Future<void> _reddet(Map<String, dynamic> atama, String tip) async {
    final sebepController = TextEditingController();

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Red Sebebi'),
        content: TextField(
          controller: sebepController,
          decoration: const InputDecoration(
            labelText: 'Red sebebini yazın',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (sonuc == true) {
      try {
        final tablo = tip == 'utu' ? DbTables.utuAtamalari : DbTables.paketlemeAtamalari;
        await supabase.from(tablo).update({
          'durum': 'reddedildi',
          'red_sebebi': sebepController.text,
        }).eq('id', atama['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Atama reddedildi'),
                backgroundColor: Colors.orange),
          );
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Red hatası: $e');
      }
    }
  }

  Future<void> _basla(Map<String, dynamic> atama, String tip) async {
    // Paketleme için özel başlatma dialogu göster
    if (tip == 'paketleme') {
      await _paketlemeyeBaslaDialogu(atama);
      return;
    }

    try {
      final tablo = tip == 'utu' ? DbTables.utuAtamalari : DbTables.paketlemeAtamalari;
      await supabase.from(tablo).update({
        'durum': 'devam_ediyor',
      }).eq('id', atama['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('İşlem başlatıldı'), backgroundColor: Colors.blue),
        );
        _verileriYukle();
      }
    } catch (e) {
      _hataGoster('Başlatma hatası: $e');
    }
  }

  // ============ DETAY GÖRÜNÜMÜ ============

  void _atamaDetayGoster(Map<String, dynamic> atama, String tip) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              Text('${tip == 'utu' ? 'Ütü' : 'Paketleme'} Detayı',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(height: 32),
              _buildDetayRow('Marka', model?['marka'] ?? '-'),
              _buildDetayRow('Model No', model?['item_no'] ?? '-'),
              _buildDetayRow('Renk', model?['renk'] ?? '-'),
              _buildDetayRow('Toplam Adet', '${model?['adet'] ?? '-'}'),
              _buildDetayRow('Talep Edilen',
                  '${atama['talep_edilen_adet'] ?? atama['adet'] ?? '-'}'),
              _buildDetayRow(
                  'Tamamlanan', '${atama['tamamlanan_adet'] ?? '-'}'),
              _buildDetayRow(
                  'Durum', _durumMetni(atama['durum'] ?? 'bekleyen')),
              if (atama['atama_tarihi'] != null)
                _buildDetayRow('Atama Tarihi',
                    dateFormat.format(DateTime.parse(atama['atama_tarihi']))),
              if (atama['tamamlama_tarihi'] != null)
                _buildDetayRow(
                    'Tamamlama',
                    dateFormat
                        .format(DateTime.parse(atama['tamamlama_tarihi']))),
              if (atama['notlar'] != null &&
                  atama['notlar'].toString().isNotEmpty)
                _buildDetayRow('Notlar', atama['notlar']),
              if (atama['red_sebebi'] != null &&
                  atama['red_sebebi'].toString().isNotEmpty)
                _buildDetayRow('Red Sebebi', atama['red_sebebi']),
            ],
          ),
        ),
      ),
    );
  }
}
