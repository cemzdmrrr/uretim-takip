import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class IplikSiparisTakipPage extends StatefulWidget {
  const IplikSiparisTakipPage({super.key});

  @override
  State<IplikSiparisTakipPage> createState() => _IplikSiparisTakipPageState();
}

class _IplikSiparisTakipPageState extends State<IplikSiparisTakipPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> siparisler = [];
  bool _yukleniyor = false;
  String aramaMetni = '';

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);

    try {
      // Basit sipariş takip view'inden veri çek
      final siparisVeri = await supabase
          .from(DbTables.vSiparisTakip)
          .select()
          .order('created_at', ascending: false);

      setState(() {
        siparisler = List<Map<String, dynamic>>.from(siparisVeri);
      });

      debugPrint('Sipariş takip verileri yüklendi: ${siparisler.length} adet');
    } catch (e) {
      debugPrint('Sipariş takip verisi yüklenirken hata: $e');
      if (mounted) {
        context.showErrorSnackBar('Veri yükleme hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtreliSiparisler = siparisler.where((siparis) {
      if (aramaMetni.isEmpty) return true;
      final arama = aramaMetni.toLowerCase();
      return siparis['siparis_no']?.toString().toLowerCase().contains(arama) ==
              true ||
          siparis['iplik_adi']?.toString().toLowerCase().contains(arama) ==
              true ||
          _siparisRengi(siparis).toLowerCase().contains(arama) ||
          siparis['tedarikci_adi']?.toString().toLowerCase().contains(arama) ==
              true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Başlık ve arama
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD2B48C),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.track_changes,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'İplik Sipariş Takip Sistemi',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _verileriYukle,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Sipariş No, İplik Adı veya Tedarikçi Ara...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => aramaMetni = value);
                  },
                ),
              ],
            ),
          ),

          // İstatistik kartları
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                    child: _buildIstatistikKart(
                        'Toplam', siparisler.length.toString(), Colors.blue)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildIstatistikKart(
                        'Beklemede',
                        siparisler
                            .where((s) => s['takip_durumu'] == 'beklemede')
                            .length
                            .toString(),
                        Colors.orange)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildIstatistikKart(
                        'Tamamlanan',
                        siparisler
                            .where((s) => s['takip_durumu'] == 'tamamlandi')
                            .length
                            .toString(),
                        Colors.green)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildIstatistikKart(
                        'Geciken',
                        siparisler
                            .where((s) => s['takip_durumu'] == 'gecikti')
                            .length
                            .toString(),
                        Colors.red)),
              ],
            ),
          ),

          // Sipariş listesi
          Expanded(
            child: _yukleniyor
                ? const LoadingWidget()
                : filtreliSiparisler.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Sipariş bulunamadı'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtreliSiparisler.length,
                        itemBuilder: (context, index) {
                          final siparis = filtreliSiparisler[index];
                          return _buildSiparisKart(siparis);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildIstatistikKart(String baslik, String deger, Color renk) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              deger,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            Text(
              baslik,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiparisKart(Map<String, dynamic> siparis) {
    final takipDurumu = siparis['takip_durumu'] ?? 'beklemede';
    final durum = _getDurumBilgi(takipDurumu);
    final teslimYuzdesi =
        (siparis['teslim_yuzdesi'] as num?)?.toDouble() ?? 0.0;
    final siparisRengi = _siparisRengi(siparis);

    // Miktar hesaplamaları
    final siparisMiktari = (siparis['miktar'] as num?)?.toDouble() ?? 0.0;
    final teslimMiktari =
        (siparis['teslim_miktari'] as num?)?.toDouble() ?? 0.0;
    final kalanMiktar = siparisMiktari - teslimMiktari;
    final birim = siparis['birim'] ?? 'kg';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: durum['renk'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(durum['ikon'], color: durum['renk']),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${siparis['siparis_no']} - ${siparis['iplik_adi']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (siparisRengi.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2B48C).withValues(alpha: 0.16),
                        border: Border.all(
                          color: const Color(0xFFD2B48C).withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        siparisRengi,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B6B3F),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Tedarikçi: ${siparis['tedarikci_adi'] ?? 'Belirtilmemiş'}'),
                Text(
                  'Renk: ${siparisRengi.isNotEmpty ? siparisRengi : 'Belirtilmemiş'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: siparisRengi.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                    color: siparisRengi.isNotEmpty ? const Color(0xFF8B6B3F) : Colors.grey,
                  ),
                ),
                Text('Sipariş: ${siparisMiktari.toStringAsFixed(1)} $birim'),
                if (teslimMiktari > 0) ...[
                  Text('Teslim: ${teslimMiktari.toStringAsFixed(1)} $birim'),
                  Text(
                    'Kalan: ${kalanMiktar.toStringAsFixed(1)} $birim',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kalanMiktar > 0 ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
                Text('Termin: ${_formatTarih(siparis['termin_tarihi'])}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: durum['renk'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    durum['metin'],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                if (teslimYuzdesi > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '%${teslimYuzdesi.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: teslimYuzdesi >= 100 ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // İlerleme çubuğu ve miktar bilgisi
          if (teslimYuzdesi > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: teslimYuzdesi / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(durum['renk']),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${teslimMiktari.toStringAsFixed(1)} $birim teslim edildi',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (kalanMiktar > 0)
                        Text(
                          '${kalanMiktar.toStringAsFixed(1)} $birim kaldı',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Aksiyon butonları
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _siparisDetayGoster(siparis),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Detay'),
                  ),
                ),
                const SizedBox(width: 8),
                if (takipDurumu == 'beklemede' || kalanMiktar > 0)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _teslimatEkle(siparis),
                      icon: const Icon(Icons.add_box),
                      label: const Text('Teslimat Gir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (takipDurumu == 'beklemede' || kalanMiktar > 0)
                  const SizedBox(width: 8),
                if (takipDurumu == 'beklemede' || kalanMiktar > 0)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _siparisiBitir(siparis),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Tamamlandı'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD2B48C),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _siparisRengi(Map<String, dynamic> siparis) {
    final renk = siparis['renk']?.toString().trim();
    if (renk == null || renk.isEmpty) {
      return '';
    }
    return renk;
  }

  Map<String, dynamic> _getDurumBilgi(String durum) {
    switch (durum) {
      case 'beklemede':
        return {
          'renk': Colors.orange,
          'ikon': Icons.hourglass_empty,
          'metin': 'Beklemede'
        };
      case 'tamamlandi':
        return {
          'renk': Colors.green,
          'ikon': Icons.check_circle,
          'metin': 'Tamamlandı'
        };
      case 'gecikti':
        return {'renk': Colors.red, 'ikon': Icons.warning, 'metin': 'Gecikti'};
      default:
        return {'renk': Colors.grey, 'ikon': Icons.help, 'metin': 'Bilinmiyor'};
    }
  }

  String _formatTarih(String? tarihStr) {
    if (tarihStr == null) return '-';
    try {
      final tarih = DateTime.parse(tarihStr);
      return DateFormat('dd.MM.yyyy').format(tarih);
    } catch (e) {
      return tarihStr;
    }
  }

  Future<void> _teslimatEkle(Map<String, dynamic> siparis) async {
    final miktarController = TextEditingController();
    final lotNoController = TextEditingController();
    DateTime teslimatTarihi = DateTime.now();
    String kaliteDurumu = 'onaylandi';

    // Sipariş ve teslim bilgilerini hesapla
    final siparisMiktari = (siparis['miktar'] as num).toDouble();
    final mevcutTeslim = (siparis['teslim_miktari'] as num?)?.toDouble() ?? 0.0;
    final kalanMiktar = siparisMiktari - mevcutTeslim;

    // Varsayılan olarak kalan miktarı göster
    miktarController.text = kalanMiktar.toStringAsFixed(1);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Teslimat Ekle - ${siparis['siparis_no']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sipariş özet bilgileri
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📦 Sipariş Özeti',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          'Toplam Miktar: ${siparisMiktari.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}'),
                      Text(
                          'Teslim Edilen: ${mevcutTeslim.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}'),
                      Text(
                        'Kalan Miktar: ${kalanMiktar.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kalanMiktar > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: miktarController,
                  decoration: InputDecoration(
                    labelText: 'Teslim Edilen Miktar *',
                    border: const OutlineInputBorder(),
                    helperText:
                        'Maksimum: ${kalanMiktar.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}',
                    helperStyle: const TextStyle(color: Colors.orange),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lotNoController,
                  decoration: const InputDecoration(
                    labelText: 'Lot/Parti No',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: kaliteDurumu,
                  decoration: const InputDecoration(
                    labelText: 'Kalite Durumu',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'onaylandi', child: Text('Onaylandı')),
                    DropdownMenuItem(
                        value: 'beklemede',
                        child: Text('Kalite Kontrolü Bekliyor')),
                    DropdownMenuItem(
                        value: 'sartli_kabul', child: Text('Şartlı Kabul')),
                    DropdownMenuItem(
                        value: 'reddedildi', child: Text('Reddedildi')),
                  ],
                  onChanged: (value) =>
                      setState(() => kaliteDurumu = value ?? 'onaylandi'),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final tarih = await showDatePicker(
                      context: context,
                      initialDate: teslimatTarihi,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (tarih != null) {
                      setState(() => teslimatTarihi = tarih);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Teslimat Tarihi',
                      border: OutlineInputBorder(),
                    ),
                    child:
                        Text(DateFormat('dd.MM.yyyy').format(teslimatTarihi)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final miktar = double.tryParse(miktarController.text);
                  if (miktar == null || miktar <= 0) {
                    throw 'Geçerli bir miktar girin';
                  }

                  // %100 sınır kontrolü
                  if (miktar > kalanMiktar) {
                    throw 'Teslim miktarı kalan miktardan (${kalanMiktar.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}) fazla olamaz!';
                  }

                  final toplamTeslim = mevcutTeslim + miktar;
                  final teslimYuzdesi = (toplamTeslim / siparisMiktari) * 100;
                  final teslimEdildi = toplamTeslim >= siparisMiktari;

                  // Sipariş bilgilerini güncelle
                  await supabase.from(DbTables.iplikSiparisleri).update({
                    'teslim_miktari': toplamTeslim,
                    'teslim_yuzdesi': teslimYuzdesi,
                    'teslim_tarihi':
                        teslimatTarihi.toIso8601String().split('T')[0],
                    'teslim_edildi': teslimEdildi,
                    'lot_no': lotNoController.text.trim().isNotEmpty
                        ? lotNoController.text.trim()
                        : null,
                    'kalite_durumu': kaliteDurumu,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', siparis['id']);

                  // İplik stoklarına otomatik ekle
                  final stokData = {
                    'ad': siparis['iplik_adi'],
                    'renk': siparis['renk'],
                    'lot_no': lotNoController.text.trim().isNotEmpty
                        ? lotNoController.text.trim()
                        : null,
                    'miktar': miktar,
                    'birim': siparis['birim'] ?? 'kg',
                    'birim_fiyat': siparis['birim_fiyat'],
                    'para_birimi': siparis['para_birimi'] ?? 'TL',
                    'tedarikci_id': siparis['tedarikci_id'],
                    'created_at': DateTime.now().toIso8601String(),
                    'firma_id': TenantManager.instance.requireFirmaId,
                  };

                  if (siparis['birim_fiyat'] != null) {
                    stokData['toplam_deger'] =
                        miktar * (siparis['birim_fiyat'] as num).toDouble();
                  }

                  final stokResponse = await supabase
                      .from(DbTables.iplikStoklari)
                      .insert(stokData)
                      .select('id')
                      .single();

                  // İplik hareketi kaydı ekle
                  await supabase.from(DbTables.iplikHareketleri).insert({
                    'iplik_id': stokResponse['id'],
                    'hareket_tipi': 'giris',
                    'miktar': miktar,
                    'aciklama':
                        'Sipariş teslimatından otomatik stok girişi - ${siparis['siparis_no']}',
                    'firma_id': TenantManager.instance.requireFirmaId,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    await _verileriYukle();

                    final kalanYeni = siparisMiktari - toplamTeslim;
                    String mesaj = 'Teslimat başarıyla kaydedildi.';

                    if (teslimEdildi) {
                      mesaj += ' 🎉 Sipariş %100 tamamlandı!';
                    } else {
                      mesaj +=
                          ' Kalan miktar: ${kalanYeni.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'} (%${(100 - teslimYuzdesi).toStringAsFixed(1)})';
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(mesaj),
                        backgroundColor:
                            teslimEdildi ? Colors.green : Colors.blue,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  context.showErrorSnackBar('Hata: $e');
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _siparisiBitir(Map<String, dynamic> siparis) async {
    try {
      // Sipariş ve teslim bilgilerini hesapla
      final siparisMiktari = (siparis['miktar'] as num?)?.toDouble() ?? 0.0;
      final mevcutTeslim =
          (siparis['teslim_miktari'] as num?)?.toDouble() ?? 0.0;
      final kalanMiktar = siparisMiktari - mevcutTeslim;
      final teslimYuzdesi =
          siparisMiktari > 0 ? (mevcutTeslim / siparisMiktari) * 100 : 0.0;

      String mesaj =
          'Siparişi tamamlandı olarak işaretlemek istediğinizden emin misiniz?\n\n';
      mesaj += 'Sipariş: ${siparis['siparis_no']}\n';
      mesaj += 'İplik: ${siparis['iplik_adi']}\n';
      mesaj +=
          'Toplam Miktar: ${siparisMiktari.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}\n';
      mesaj +=
          'Teslim Edilen: ${mevcutTeslim.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}\n';

      if (kalanMiktar > 0) {
        mesaj += '\n⚠️ DİKKAT: Sipariş tam teslim edilmemiş!\n';
        mesaj +=
            'Kalan Miktar: ${kalanMiktar.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'} (%${(100 - teslimYuzdesi).toStringAsFixed(1)})\n';
        mesaj +=
            '\nBu işlem siparişi eksik kalsa da tamamlandı olarak işaretleyecektir.';
      } else {
        mesaj += '\n✅ Sipariş tam teslim edilmiş.';
      }

      final onay = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Siparişi Bitir'),
          content: Text(mesaj),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2B48C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tamamlandı İşaretle'),
            ),
          ],
        ),
      );

      if (onay == true) {
        // Sipariş durumunu tamamlandı olarak güncelle
        await supabase.from(DbTables.iplikSiparisleri).update({
          'takip_durumu': 'tamamlandi',
          'teslim_edildi': true,
          'kapanma_tarihi': DateTime.now().toIso8601String().split('T')[0],
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', siparis['id']);

        if (mounted) {
          await _verileriYukle();

          String basariMesaji =
              '✅ Sipariş ${siparis['siparis_no']} tamamlandı olarak işaretlendi!';
          if (kalanMiktar > 0) {
            basariMesaji +=
                '\n⚠️ Kalan miktar: ${kalanMiktar.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}';
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(basariMesaji),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  void _siparisDetayGoster(Map<String, dynamic> siparis) {
    // Miktar hesaplamaları
    final siparisMiktari = (siparis['miktar'] as num?)?.toDouble() ?? 0.0;
    final teslimMiktari =
        (siparis['teslim_miktari'] as num?)?.toDouble() ?? 0.0;
    final kalanMiktar = siparisMiktari - teslimMiktari;
    final teslimYuzdesi =
        siparisMiktari > 0 ? (teslimMiktari / siparisMiktari) * 100 : 0.0;
    final birim = siparis['birim'] ?? 'kg';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sipariş Detayları - ${siparis['siparis_no']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetayRow(
                  'İplik Adı', siparis['iplik_adi']?.toString() ?? '-'),
              _buildDetayRow('Renk', siparis['renk']?.toString() ?? '-'),

              // Miktar bilgileri - özel düzen
              const Divider(),
              const Text('📦 Miktar Bilgileri',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildDetayRow('Sipariş Miktarı',
                  '${siparisMiktari.toStringAsFixed(1)} $birim'),
              _buildDetayRow('Teslim Edilen',
                  '${teslimMiktari.toStringAsFixed(1)} $birim'),
              _buildDetayRow('Kalan Miktar',
                  '${kalanMiktar.toStringAsFixed(1)} $birim${kalanMiktar > 0 ? ' (${(100 - teslimYuzdesi).toStringAsFixed(1)}%)' : ' ✅'}',
                  color: kalanMiktar > 0 ? Colors.orange : Colors.green),
              if (teslimMiktari > 0)
                _buildDetayRow(
                    'Teslim Oranı', '%${teslimYuzdesi.toStringAsFixed(1)}',
                    color: teslimYuzdesi >= 100 ? Colors.green : Colors.blue),

              const Divider(),
              const Text('🏪 Tedarikçi Bilgileri',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildDetayRow(
                  'Tedarikçi', siparis['tedarikci_adi']?.toString() ?? '-'),
              _buildDetayRow(
                  'Telefon', siparis['tedarikci_telefon']?.toString() ?? '-'),

              const Divider(),
              const Text('📅 Tarih Bilgileri',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildDetayRow(
                  'Termin Tarihi', _formatTarih(siparis['termin_tarihi'])),
              _buildDetayRow(
                  'Teslim Tarihi', _formatTarih(siparis['teslim_tarihi'])),

              const Divider(),
              const Text('ℹ️ Diğer Bilgiler',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildDetayRow('Lot No', siparis['lot_no']?.toString() ?? '-'),
              _buildDetayRow(
                  'Kalite Durumu', siparis['kalite_durumu']?.toString() ?? '-'),
              _buildDetayRow(
                  'Durum', _getDurumBilgi(siparis['takip_durumu'])['metin']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetayRow(String baslik, String deger, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$baslik:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: TextStyle(
                color: color,
                fontWeight: color != null ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
