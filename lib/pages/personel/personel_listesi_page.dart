import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/pages/personel/personel_detay_page.dart';
import 'package:uretim_takip/pages/personel/personel_ekle_page.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/services/user_helper.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class PersonelListesiPage extends StatefulWidget {
  const PersonelListesiPage({super.key});

  @override
  State<PersonelListesiPage> createState() => _PersonelListesiPageState();
}

class _PersonelListesiPageState extends State<PersonelListesiPage> {
  final TextEditingController _aramaController = TextEditingController();

  List<PersonelModel> _tumPersoneller = [];
  List<PersonelModel> _filtreliPersoneller = [];
  bool _yukleniyor = true;
  String _arama = '';
  String _durumFiltresi = 'aktif';
  String? _kullaniciRolu;
  String? _kullaniciId;

  @override
  void initState() {
    super.initState();
    _hazirla();
    _aramaController.addListener(_filtreUygula);
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _hazirla() async {
    _kullaniciRolu = await getCurrentUserRole();
    _kullaniciId = await getCurrentUserId();
    await _getPersoneller();
  }

  Future<void> _getPersoneller() async {
    setState(() => _yukleniyor = true);
    try {
      final servis = PersonelService();
      final tumKayitlar = await servis.getPersoneller(sadeceAktif: false);
      var gosterilecek = tumKayitlar;
      if (_kullaniciRolu == DbTables.personel && _kullaniciId != null) {
        gosterilecek =
            tumKayitlar.where((p) => p.userId == _kullaniciId).toList();
      }

      if (!mounted) return;
      setState(() {
        _tumPersoneller = gosterilecek;
        _yukleniyor = false;
      });
      _filtreUygula();
    } catch (_) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
    }
  }

  void _filtreUygula() {
    final arama = _aramaController.text.trim().toLowerCase();
    List<PersonelModel> liste = List<PersonelModel>.from(_tumPersoneller);

    if (_durumFiltresi == 'aktif') {
      liste = liste.where((p) => p.aktifMi).toList();
    } else if (_durumFiltresi == 'isten_cikarildi') {
      liste = liste.where((p) => p.istenCikarildiMi).toList();
    } else if (_durumFiltresi == 'pasif') {
      liste = liste.where((p) => p.pasifMi).toList();
    }

    if (arama.isNotEmpty) {
      liste = liste.where((p) {
        return p.tamAd.toLowerCase().contains(arama) ||
            p.telefon.toLowerCase().contains(arama) ||
            p.pozisyon.toLowerCase().contains(arama) ||
            p.departman.toLowerCase().contains(arama) ||
            p.tckn.toLowerCase().contains(arama) ||
            p.email.toLowerCase().contains(arama);
      }).toList();
    }

    if (!mounted) return;
    setState(() {
      _arama = arama;
      _filtreliPersoneller = liste;
    });
  }

  int _say(String durum) {
    if (durum == 'aktif') {
      return _tumPersoneller.where((p) => p.aktifMi).length;
    }
    if (durum == 'isten_cikarildi') {
      return _tumPersoneller.where((p) => p.istenCikarildiMi).length;
    }
    if (durum == 'pasif') {
      return _tumPersoneller.where((p) => p.pasifMi).length;
    }
    return _tumPersoneller.length;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 720;
    final canManage = _kullaniciRolu != DbTables.personel;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(
          canManage ? 'Personel Yönetimi' : 'Kişisel Bilgilerim',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _getPersoneller,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _yukleniyor
          ? const LoadingWidget()
          : Column(
              children: [
                _buildTopSection(isMobile, canManage),
                Expanded(
                  child: _filtreliPersoneller.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.people_alt_outlined,
                          mesaj: 'Gösterilecek personel bulunamadı',
                          altMesaj: 'Arama veya durum filtresini değiştirin.',
                        )
                      : _buildContent(isMobile),
                ),
              ],
            ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonelEklePage(),
                  ),
                );
                if (result == true) {
                  _getPersoneller();
                }
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(isMobile ? 'Ekle' : 'Yeni Personel'),
            )
          : null,
    );
  }

  Widget _buildTopSection(bool isMobile, bool canManage) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 14 : 20, 16, isMobile ? 14 : 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7ECF3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSummaryTile(
                icon: Icons.groups_2_outlined,
                label: 'Toplam',
                value: _tumPersoneller.length.toString(),
                color: const Color(0xFF2563EB),
              ),
              _buildSummaryTile(
                icon: Icons.verified_user_outlined,
                label: 'Aktif',
                value: _say('aktif').toString(),
                color: const Color(0xFF0F9D58),
              ),
              if (canManage)
                _buildSummaryTile(
                  icon: Icons.person_off_outlined,
                  label: 'İşten Çıkarılan',
                  value: _say('isten_cikarildi').toString(),
                  color: const Color(0xFFF57C00),
                ),
              if (canManage)
                _buildSummaryTile(
                  icon: Icons.delete_outline,
                  label: 'Pasif',
                  value: _say('pasif').toString(),
                  color: const Color(0xFF6B7280),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _aramaController,
            decoration: InputDecoration(
              hintText: 'İsim, telefon, pozisyon, departman, TCKN, e-posta',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _arama.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => _aramaController.clear(),
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD9E2F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD9E2F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          _buildSegmentedFilter(canManage),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilter(bool canManage) {
    final items = <Map<String, String>>[
      {'key': 'aktif', 'label': 'Aktif'},
      if (canManage) {'key': 'isten_cikarildi', 'label': 'İşten Çıkarılan'},
      if (canManage) {'key': 'pasif', 'label': 'Pasif'},
      if (canManage) {'key': 'tum', 'label': 'Tümü'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: items.map((item) {
            final selected = _durumFiltresi == item['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() => _durumFiltresi = item['key']!);
                  _filtreUygula();
                },
                child: Container(
                  constraints: const BoxConstraints(minWidth: 110),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['label']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (isMobile) {
      return ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _filtreliPersoneller.length,
        itemBuilder: (context, index) {
          return _buildPersonelCard(_filtreliPersoneller[index], true);
        },
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1500 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: width > 1500 ? 1.68 : 1.52,
      ),
      itemCount: _filtreliPersoneller.length,
      itemBuilder: (context, index) {
        return _buildPersonelCard(_filtreliPersoneller[index], false);
      },
    );
  }

  Widget _buildPersonelCard(PersonelModel personel, bool isMobile) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonelDetayPage(id: personel.userId),
            ),
          );
          if (result == true || result == 'deleted') {
            _getPersoneller();
          }
        },
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4EAF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isMobile ? 48 : 56,
                    height: isMobile ? 48 : 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _inisyaller(personel),
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personel.tamAd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          personel.pozisyon.isEmpty ? 'Pozisyon tanımlı değil' : personel.pozisyon,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDurumBadge(personel),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildMetaChip(Icons.apartment_outlined, personel.departman),
                  _buildMetaChip(Icons.phone_outlined, personel.telefon),
                  _buildMetaChip(Icons.email_outlined, personel.email),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5EAF3)),
                ),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  children: [
                    _buildMetric('İşe Başlangıç', _formatDate(personel.iseBaslangic)),
                    _buildMetric('Net Maaş', _formatMoney(personel.netMaas)),
                    if (personel.istenCikarildiMi)
                      _buildMetric(
                        'Çıkış Tarihi',
                        _formatDate(personel.istenCikisTarihi),
                      ),
                  ],
                ),
              ),
              if (personel.istenCikarildiMi && personel.istenCikisNedeni.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  personel.istenCikisNedeni,
                  maxLines: isMobile ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurumBadge(PersonelModel personel) {
    Color bg;
    Color fg;
    String text;

    if (personel.istenCikarildiMi) {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
      text = 'İşten Çıkarıldı';
    } else if (personel.pasifMi) {
      bg = const Color(0xFFE5E7EB);
      fg = const Color(0xFF4B5563);
      text = 'Pasif';
    } else {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      text = 'Aktif';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String value) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  String _inisyaller(PersonelModel personel) {
    final ad = personel.ad.trim();
    final soyad = personel.soyad.trim();
    return '${ad.isNotEmpty ? ad[0] : ''}${soyad.isNotEmpty ? soyad[0] : ''}';
  }

  String _formatMoney(String value) {
    if (value.trim().isEmpty) return '-';
    final parsed = num.tryParse(value);
    if (parsed == null) return value;
    final text = parsed
        .toStringAsFixed(2)
        .replaceAll('.', ',')
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '₺$text';
  }

  String _formatDate(String value) {
    if (value.trim().isEmpty) return '-';
    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }
}
