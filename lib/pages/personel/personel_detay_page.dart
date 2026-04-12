import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/pages/personel/personel_ekle_page.dart';
import 'package:uretim_takip/pages/muhasebe/odeme_page.dart';
import 'package:uretim_takip/pages/muhasebe/izin_page.dart';
import 'package:uretim_takip/pages/muhasebe/mesai_page.dart';
import 'package:uretim_takip/pages/muhasebe/puantaj_tablo_page.dart';
import 'package:uretim_takip/pages/personel/personel_arsiv_page.dart';
import 'package:uretim_takip/pages/ayarlar/sistem_ayarlari_page.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonelDetayPage extends StatefulWidget {
  final String id;
  const PersonelDetayPage({super.key, required this.id});

  @override
  State<PersonelDetayPage> createState() => _PersonelDetayPageState();
}

class _PersonelDetayPageState extends State<PersonelDetayPage> with SingleTickerProviderStateMixin {
  PersonelModel? personel;
  bool yukleniyor = true;
  TabController? _tabController;
  String? currentUserRole;
  String? seciliDonem;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _getPersonel();
    _getCurrentUserRole();
  }

  Future<void> _getPersonel() async {
    if (!mounted) return; // mounted kontrolü ekle
    setState(() => yukleniyor = true);
    debugPrint('PersonelDetayPage._getPersonel: widget.id=${widget.id}');
    final servis = PersonelService();
    final p = await servis.getPersonelById(widget.id);
    debugPrint('PersonelDetayPage._getPersonel: personel=${p?.ad} ${p?.soyad}');
    if (mounted) { // mounted kontrolü ekle
      setState(() {
        personel = p;
        yukleniyor = false;
      });
    }
  }

  Future<void> _getCurrentUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client
        .from(DbTables.userRoles)
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();
    if (mounted) { // mounted kontrolü ekle
      setState(() {
        currentUserRole = response?['role'] ?? 'user';
      });
    }
  }

  Future<void> personelSil(BuildContext context, PersonelModel? personel) async {
    if (personel == null) {
      context.showSnackBar('Personel bilgisi bulunamadı.');
      return;
    }
    try {
      // Soft delete - personeli pasif yap
      await PersonelService().deletePersonel(personel.tckn);
      if (!context.mounted) return;
      context.showSuccessSnackBar('Personel başarıyla pasif yapıldı. Raporlarda veriler görünmeye devam edecek.');
      // Silme sonrası listeye geri dön
      if (mounted) {
        Navigator.of(context).pop(true); // true = liste yenilensin
      }
    } catch (e) {
      if (!context.mounted) return;
      context.showErrorSnackBar('İşlem başarısız: $e');
    }
  }

  Future<void> _cikisYap() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Tüm sayfaları temizle ve giriş sayfasına dön
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login, // veya giriş sayfanızın route'u
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Çıkış yapılırken hata oluştu: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (personel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Personel Detay', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue),
        body: const Center(child: Text('Personel bulunamadı.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Detay', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white), // <-- back arrow white
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Bilgiler'),
            Tab(text: 'Avans/Ödeme'),
            Tab(text: 'İzin'),
            Tab(text: 'Mesai'),
            Tab(text: 'Puantaj'),
            Tab(text: 'Arşiv'),
          ],
        ),
        actions: [
          if (currentUserRole == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Sistem Ayarları',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SistemAyarlariPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Düzenle',
              onPressed: () async {
                final guncellenen = await Navigator.push<PersonelModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonelEklePage(
                      mevcut: personel,
                    ),
                  ),
                );
                if (guncellenen != null) {
                  setState(() { personel = guncellenen; });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              tooltip: 'Sil',
              onPressed: () async {
                final onay = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Personeli Sil', style: TextStyle(color: Colors.blue)),
                    content: const Text('Bu personeli silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.blue)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text('İptal', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text('Sil', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (onay == true && personel != null) {
                  if (!context.mounted) return;
                  personelSil(context, personel);
                }
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış',
            onPressed: () async {
              final onay = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap', style: TextStyle(color: Colors.blue)),
                  content: const Text('Oturumu kapatmak istediğinize emin misiniz?', style: TextStyle(color: Colors.blue)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(backgroundColor: Colors.grey),
                      child: const Text('İptal', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Çıkış', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (onay == true) {
                await _cikisYap();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab İçerikleri
          Expanded(
            child: TabBarView(
        controller: _tabController,
        children: [
          // Bilgiler sekmesi
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final padding = isMobile ? 12.0 : 24.0;
              
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İsim başlığı
                        isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, color: Colors.blue, size: 28),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${personel!.ad} ${personel!.soyad}'.trim(),
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.blue, size: 32),
                                  const SizedBox(width: 12),
                                  Text('${personel!.ad} ${personel!.soyad}'.trim(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                        const Divider(height: 32),
                        
                        // Kişisel Bilgiler
                        Text('Kişisel Bilgiler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18, color: Colors.blue.shade700)),
                        const SizedBox(height: 8),
                        _infoRow(Icons.badge, 'TCKN', personel!.tckn, isMobile: isMobile),
                        _infoRow(Icons.work, 'Pozisyon', personel!.pozisyon, isMobile: isMobile),
                        _infoRow(Icons.apartment, 'Departman', personel!.departman, isMobile: isMobile),
                        _infoRow(Icons.email, 'E-posta', personel!.email, isMobile: isMobile),
                        _infoRow(Icons.phone, 'Telefon', personel!.telefon, isMobile: isMobile),
                        _infoRow(Icons.calendar_today, 'İşe Başlangıç', _formatDate(personel!.iseBaslangic), isMobile: isMobile),
                        _infoRow(Icons.home, 'Adres', personel!.adres, isMobile: isMobile),
                        
                        const Divider(height: 32),
                        Text('Maaş ve Ödemeler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18, color: Colors.blue.shade700)),
                        const SizedBox(height: 8),
                        _infoRow(Icons.monetization_on, 'Brüt Maaş', _formatMoney(personel!.brutMaas), isMobile: isMobile),
                        _infoRow(Icons.monetization_on_outlined, 'Net Maaş', _formatMoney(personel!.netMaas), isMobile: isMobile),
                        _infoRow(Icons.confirmation_number, 'SGK Sicil No', personel!.sgkSicilNo, isMobile: isMobile),
                        _infoRow(Icons.access_time, 'Günlük Çalışma Saati', _formatHour(personel!.gunlukCalismaSaati), isMobile: isMobile),
                        _infoRow(Icons.calendar_view_week, 'Haftalık Çalışma Günü', _formatDay(personel!.haftalikCalismaGunu), isMobile: isMobile),
                        _infoRow(Icons.directions_bus, 'Yol Ücreti', _formatMoney(personel!.yolUcreti), isMobile: isMobile),
                        _infoRow(Icons.restaurant, 'Yemek Ücreti', _formatMoney(personel!.yemekUcreti), isMobile: isMobile),
                        _infoRow(Icons.card_giftcard, 'Ekstra Prim', _formatMoney(personel!.ekstraPrim), isMobile: isMobile),
                        _infoRow(Icons.money, 'Elden Maaş', _formatMoney(personel!.eldenMaas), isMobile: isMobile),
                        _infoRow(Icons.account_balance, 'Bankadan Alınan Tutar', _formatMoney(personel!.bankaMaas), isMobile: isMobile),
                        
                        const Divider(height: 32),
                        Text('Yıllık İzin Hakkı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18, color: Colors.blue.shade700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.beach_access, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text('${personel!.yillikIzinHakki} gün', style: TextStyle(fontSize: isMobile ? 16 : 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Avans/Ödeme sekmesi
          (personel?.userId.trim().isEmpty ?? true)
              ? const Center(
                  child: Text(
                    'Personel ID bulunamadı. Avans/Ödeme işlemleri için geçerli bir personel seçiniz.',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : OdemePage(key: ValueKey('odeme_${seciliDonem ?? 'all'}'), personelId: personel!.userId, initialDonem: seciliDonem),
          // İzin sekmesi
          IzinPage(key: ValueKey('izin_${seciliDonem ?? 'all'}'), personelId: personel!.userId, personelAd: '${personel!.ad} ${personel!.soyad}', initialDonem: seciliDonem),
          // Mesai sekmesi
          MesaiPage(key: ValueKey('mesai_${seciliDonem ?? 'all'}'), personelId: personel!.userId, personelAd: '${personel!.ad} ${personel!.soyad}', initialDonem: seciliDonem),
          // Puantaj sekmesi
          PuantajTabloPage(personelId: personel!.userId, personelAd: '${personel!.ad} ${personel!.soyad}'),
          // Arşiv sekmesi
          PersonelArsivPage(personelId: personel!.userId, personelAd: '${personel!.ad} ${personel!.soyad}'),
        ],
      ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isMobile = false}) {
    final displayValue = value.isEmpty ? '-' : value;
    
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 6),
                Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(displayValue, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(displayValue, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  /// Para formatı: 12500.50 -> ₺12.500,50
  String _formatMoney(String value) {
    if (value.isEmpty) return '-';
    final num? parsed = num.tryParse(value);
    if (parsed == null) return value;
    // Binlik ayracı ve ondalık formatı
    final formatted = parsed.toStringAsFixed(2)
        .replaceAll('.', ',')
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '₺$formatted';
  }

  /// Saat formatı: 8 -> 8 saat
  String _formatHour(String value) {
    if (value.isEmpty) return '-';
    return '$value saat';
  }

  /// Gün formatı: 5 -> 5 gün
  String _formatDay(String value) {
    if (value.isEmpty) return '-';
    return '$value gün';
  }

  /// Tarih formatı: 2024-01-15 -> 15.01.2024
  String _formatDate(String value) {
    if (value.isEmpty) return '-';
    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return value; // Parse edilemezse olduğu gibi döndür
    }
  }
}
