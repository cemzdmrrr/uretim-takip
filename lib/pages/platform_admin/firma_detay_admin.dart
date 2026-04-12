import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';
import 'package:intl/intl.dart';

/// Platform Admin - Firma Detay ve Yönetim Sayfası.
class FirmaDetayAdminPage extends StatefulWidget {
  final String firmaId;

  const FirmaDetayAdminPage({super.key, required this.firmaId});

  @override
  State<FirmaDetayAdminPage> createState() => _FirmaDetayAdminPageState();
}

class _FirmaDetayAdminPageState extends State<FirmaDetayAdminPage>
    with SingleTickerProviderStateMixin {
  bool _yukleniyor = true;
  Map<String, dynamic>? _firma;
  List<Map<String, dynamic>> _kullanicilar = [];
  List<Map<String, dynamic>> _moduller = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _verileriYukle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final sonuclar = await Future.wait([
        PlatformAdminService.firmaDetayGetir(widget.firmaId),
        PlatformAdminService.firmaKullanicilariGetir(widget.firmaId),
        PlatformAdminService.firmaModulleriGetir(widget.firmaId),
      ]);

      setState(() {
        _firma = sonuclar[0] as Map<String, dynamic>?;
        _kullanicilar = sonuclar[1] as List<Map<String, dynamic>>;
        _moduller = sonuclar[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firmaAdi = _firma?['firma_adi']?.toString() ?? 'Firma Detay';

    return Scaffold(
      appBar: AppBar(
        title: Text(firmaAdi),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Genel Bilgi', icon: Icon(Icons.info_outline, size: 18)),
            Tab(
                text: 'Kullanıcılar',
                icon: Icon(Icons.people_outline, size: 18)),
            Tab(
                text: 'Modüller',
                icon: Icon(Icons.extension_outlined, size: 18)),
          ],
        ),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _firma == null
              ? const Center(child: Text('Firma bulunamadı'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGenelBilgi(),
                    _buildKullanicilar(),
                    _buildModuller(),
                  ],
                ),
    );
  }

  Widget _buildGenelBilgi() {
    final aktif = _firma!['aktif'] == true;
    final tarihStr = _firma!['created_at']?.toString();
    final kayitTarihi = tarihStr != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(tarihStr))
        : '-';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Durum & Aksiyon kartı
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: aktif ? Colors.green : Colors.red,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  aktif ? Icons.check_circle : Icons.cancel,
                  color: aktif ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aktif ? 'Firma Aktif' : 'Firma Pasif',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: aktif ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      Text(
                        'Kayıt: $kayitTarihi',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _firmaDurumDegistir(!aktif),
                  icon: Icon(aktif ? Icons.block : Icons.check),
                  label: Text(aktif ? 'Pasif Yap' : 'Aktif Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: aktif ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Firma bilgileri
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firma Bilgileri',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                _bilgiSatir('Firma Kodu', _firma!['firma_kodu']),
                _bilgiSatir('Vergi No', _firma!['vergi_no']),
                _bilgiSatir('Vergi Dairesi', _firma!['vergi_dairesi']),
                _bilgiSatir('Sektör', _firma!['sektor']),
                _bilgiSatir('Faaliyet', _firma!['faaliyet']),
                _bilgiSatir('Yetkili', _firma!['yetkili']),
                _bilgiSatir('Telefon', _firma!['telefon']),
                _bilgiSatir('E-posta', _firma!['email']),
                _bilgiSatir('Adres', _firma!['adres']),
                _bilgiSatir('Web', _firma!['web']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Özet istatistikler
        Row(
          children: [
            Expanded(
              child: _ozetKart(
                'Kullanıcılar',
                '${_kullanicilar.length}',
                Icons.people,
                const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ozetKart(
                'Aktif Modüller',
                '${_moduller.where((m) => m['aktif'] == true).length}',
                Icons.extension,
                const Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bilgiSatir(String etiket, dynamic deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              etiket,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              deger?.toString() ?? '-',
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetKart(String baslik, String deger, IconData ikon, Color renk) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(ikon, color: renk, size: 28),
            const SizedBox(height: 8),
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKullanicilar() {
    if (_kullanicilar.isEmpty) {
      return const Center(child: Text('Henüz kullanıcı yok'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kullanicilar.length,
      itemBuilder: (context, index) {
        final k = _kullanicilar[index];
        final aktif = k['aktif'] == true;
        final email = k['email']?.toString() ?? '-';
        final ad = k['ad']?.toString() ?? '';
        final soyad = k['soyad']?.toString() ?? '';
        final displayName = k['display_name']?.toString() ?? '';
        final rol = k['rol']?.toString() ?? '-';

        String gorunenIsim;
        if (ad.isNotEmpty || soyad.isNotEmpty) {
          gorunenIsim = '$ad $soyad'.trim();
        } else if (displayName.isNotEmpty && displayName != email) {
          gorunenIsim = displayName;
        } else {
          gorunenIsim = email;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  aktif ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25),
              child: Icon(
                Icons.person,
                color: aktif ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(gorunenIsim),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gorunenIsim != email)
                  Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text('Rol: $rol'),
              ],
            ),
            trailing: Chip(
              label: Text(
                aktif ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  color: aktif ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                ),
              ),
              backgroundColor:
                  aktif ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuller() {
    if (_moduller.isEmpty) {
      return const Center(child: Text('Henüz modül aktivasyonu yok'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _moduller.length,
      itemBuilder: (context, index) {
        final m = _moduller[index];
        final aktif = m['aktif'] == true;
        final modulData = m['modul_tanimlari'] as Map?;
        final modulKodu = modulData?['modul_kodu']?.toString() ?? '-';
        final modulAdi = modulData?['modul_adi']?.toString() ?? 'Bilinmeyen Modül';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: aktif
                  ? const Color(0xFF6A1B9A).withAlpha(25)
                  : Colors.grey.withAlpha(25),
              child: Icon(
                Icons.extension,
                color: aktif ? const Color(0xFF6A1B9A) : Colors.grey,
              ),
            ),
            title: Text(modulAdi),
            subtitle: Text(modulKodu),
            trailing: Chip(
              label: Text(
                aktif ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  color: aktif ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                ),
              ),
              backgroundColor:
                  aktif ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
            ),
          ),
        );
      },
    );
  }

  Future<void> _firmaDurumDegistir(bool yeniDurum) async {
    final firmaAdi = _firma?['firma_adi'] ?? '';
    final islem = yeniDurum ? 'aktif' : 'pasif';

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Firma $islem yapılsın mı?'),
        content: Text(
            '"$firmaAdi" firması $islem durumuna geçirilecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: yeniDurum ? Colors.green : Colors.red,
            ),
            child: Text(yeniDurum ? 'Aktif Yap' : 'Pasif Yap'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      await PlatformAdminService.firmaDurumDegistir(
          widget.firmaId, yeniDurum);
      await _verileriYukle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firma $islem yapıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
