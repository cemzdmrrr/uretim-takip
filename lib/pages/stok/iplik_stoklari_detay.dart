part of 'iplik_stoklari.dart';

/// Detail view and utility methods for _IplikStoklariPageState.
extension _IplikDetayExt on _IplikStoklariPageState {

  Future<void> _iplikDetayGoster(Map<String, dynamic> stok) async {
    try {
      // Bu ipliğin tüm hareketlerini getir
      final hareketler = await supabase
          .from(DbTables.iplikHareketleri)
          .select('*')
          .eq('iplik_id', stok['id'])
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Sabit Başlık
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD2B48C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'İplik Detayları: ${stok['ad']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Kaydırılabilir İçerik Alanı
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // İplik Bilgileri Kartı - Kompakt Tasarım
                        Container(
                          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Başlık
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: Color(0xFFD2B48C), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'İplik Bilgileri',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFD2B48C),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Bilgiler - Kompakt grid düzeni
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildKompaktDetayRow('İplik', stok['ad']),
                                            _buildKompaktDetayRow('Renk', stok['renk'] ?? '-'),
                                            _buildKompaktDetayRow('Lot No', stok['lot_no'] ?? '-'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildKompaktDetayRow('Miktar', '${stok['miktar']} ${stok['birim'] ?? 'kg'}'),
                                            if (stok['birim_fiyat'] != null)
                                              _buildKompaktDetayRow('Birim Fiyat', '${_getParaBirimiSembolu(stok['para_birimi'])}${(stok['birim_fiyat'] as num).toStringAsFixed(2)}'),
                                            _buildKompaktDetayRow('Tarih', _formatKisaTarih(stok['created_at'])),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Hareket Geçmişi Kartı
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Card(
                            elevation: 2,
                            child: Column(
                              children: [
                                // Başlık bölümü
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD2B48C).withValues(alpha: 0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.history, color: Color(0xFFD2B48C), size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Hareket Geçmişi',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFD2B48C),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD2B48C),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${hareketler.length} kayıt',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Hareket listesi - Sabit yükseklik yerine flexible
                                if (hareketler.isEmpty)
                                  SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.history_outlined,
                                            size: 64,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Henüz hareket kaydı bulunmuyor',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'İlk stok hareketi yapıldığında burada görünecek',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  // Hareket kartları - Her biri ayrı widget olarak
                                  Column(
                                    children: hareketler.map((hareket) {
                                      final hareketRenk = _getHareketRenk(hareket['hareket_tipi']);
                                      final hareketIcon = _getHareketIcon(hareket['hareket_tipi']);
                                      final hareketBaslik = _getHareketBaslik(hareket['hareket_tipi']);
                                      
                                      return Container(
                                        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                        child: Card(
                                          elevation: 2,
                                          shadowColor: hareketRenk.withValues(alpha: 0.2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: hareketRenk.withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                // İkon ve renk çizgisi
                                                Container(
                                                  width: 4,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color: hareketRenk,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: hareketRenk.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    hareketIcon,
                                                    color: hareketRenk,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                
                                                // Hareket detayları
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Hareket tipi ve miktar
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              hareketBaslik,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: hareketRenk.withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              '${hareket['miktar']} ${stok['birim'] ?? 'kg'}',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 13,
                                                                color: hareketRenk,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      
                                                      // Açıklama
                                                      if (hareket['aciklama'] != null)
                                                        Padding(
                                                          padding: const EdgeInsets.only(bottom: 4),
                                                          child: Text(
                                                            hareket['aciklama'],
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[700],
                                                            ),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      
                                                      // Tarih
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.schedule,
                                                            size: 12,
                                                            color: Colors.grey[500],
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            _formatTarih(hareket['created_at']),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey[500],
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                
                                // Alt özet bilgisi
                                if (hareketler.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildHareketOzet(
                                          'Giriş',
                                          hareketler.where((h) => h['hareket_tipi'] == 'giris').length,
                                          Colors.green,
                                          Icons.call_received,
                                        ),
                                        _buildHareketOzet(
                                          'Çıkış',
                                          hareketler.where((h) => h['hareket_tipi'] == 'cikis').length,
                                          Colors.red,
                                          Icons.call_made,
                                        ),
                                        _buildHareketOzet(
                                          'Transfer',
                                          hareketler.where((h) => h['hareket_tipi'] == 'transfer').length,
                                          Colors.blue,
                                          Icons.swap_horiz,
                                        ),
                                        _buildHareketOzet(
                                          'Sayım',
                                          hareketler.where((h) => h['hareket_tipi'] == 'sayim').length,
                                          Colors.orange,
                                          Icons.inventory,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Aşağıda biraz boşluk bırak
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Sabit Alt Butonlar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _stokDuzenle(stok);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Düzenle'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      Container(width: 1, height: 20, color: Colors.grey[300]),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _cikisModalGoster(stok);
                          },
                          icon: const Icon(Icons.call_made, size: 18),
                          label: const Text('Çıkış'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                      Container(width: 1, height: 20, color: Colors.grey[300]),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Kapat'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Detay yüklenirken hata: $e');
      }
    }
  }

  Widget _buildHareketOzet(String baslik, int sayi, Color renk, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: renk,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sayi.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: renk,
            fontSize: 14,
          ),
        ),
        Text(
          baslik,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildKompaktDetayRow(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Text(
            deger,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _formatKisaTarih(String? tarihStr) {
    if (tarihStr == null) return '-';
    try {
      final tarih = DateTime.parse(tarihStr);
      return '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}';
    } catch (e) {
      return tarihStr.split('T')[0];
    }
  }

  String _getParaBirimiSembolu(String? paraBirimi) {
    switch (paraBirimi) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'TL':
      default:
        return '₺';
    }
  }


  String _formatTarih(String? tarihStr) {
    if (tarihStr == null) return '-';
    try {
      final tarih = DateTime.parse(tarihStr);
      return '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year} ${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return tarihStr.split('T')[0];
    }
  }

  Color _getHareketRenk(String hareketTipi) {
    switch (hareketTipi) {
      case 'giris':
        return Colors.green;
      case 'cikis':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      case 'sayim':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getHareketIcon(String hareketTipi) {
    switch (hareketTipi) {
      case 'giris':
        return Icons.call_received;
      case 'cikis':
        return Icons.call_made;
      case 'transfer':
        return Icons.swap_horiz;
      case 'sayim':
        return Icons.inventory;
      default:
        return Icons.help;
    }
  }

  String _getHareketBaslik(String hareketTipi) {
    switch (hareketTipi) {
      case 'giris':
        return 'Stok Girişi';
      case 'cikis':
        return 'Stok Çıkışı';
      case 'transfer':
        return 'Transfer';
      case 'sayim':
        return 'Sayım Düzeltmesi';
      default:
        return 'Bilinmeyen Hareket';
    }
  }
}
