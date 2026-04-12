import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/pages/personel/personel_detay_page.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/pages/personel/personel_ekle_page.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/services/user_helper.dart';

class PersonelListesiPage extends StatefulWidget {
  const PersonelListesiPage({super.key});

  @override
  State<PersonelListesiPage> createState() => _PersonelListesiPageState();
}

class _PersonelListesiPageState extends State<PersonelListesiPage> {
  List<PersonelModel> personeller = [];
  List<PersonelModel> filtreliPersoneller = [];
  bool yukleniyor = true;
  final TextEditingController _aramaController = TextEditingController();
  String _arama = '';
  String? _kullaniciRolu;
  String? _kullaniciId;

  @override
  void initState() {
    super.initState();
    _hazirla();
    _aramaController.addListener(_onAramaChanged);
  }

  Future<void> _hazirla() async {
    _kullaniciRolu = await getCurrentUserRole();
    _kullaniciId = await getCurrentUserId();
    await _getPersoneller();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  void _onAramaChanged() {
    setState(() {
      _arama = _aramaController.text.toLowerCase();
      filtreliPersoneller = personeller.where((p) {
        return '${p.ad} ${p.soyad}'.toLowerCase().contains(_arama) ||
            p.telefon.toLowerCase().contains(_arama) ||
            p.pozisyon.toLowerCase().contains(_arama) ||
            p.departman.toLowerCase().contains(_arama) ||
            p.tckn.toLowerCase().contains(_arama) ||
            p.email.toLowerCase().contains(_arama);
      }).toList();
    });
  }

  Future<void> _getPersoneller() async {
    try {
      final servis = PersonelService();
      final personeller = await servis.getPersoneller();
      List<PersonelModel> gosterilecek = personeller;
      if (_kullaniciRolu == DbTables.personel && _kullaniciId != null) {
        gosterilecek = personeller.where((p) => p.userId == _kullaniciId).toList();
      }
      setState(() {
        this.personeller = gosterilecek;
        yukleniyor = false;
        filtreliPersoneller = gosterilecek;
      });
    } catch (e) {
      setState(() {
        yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;
    
    // Eğer personel rolündeyse, sadece kendi kaydını görebilsin ve ekleme butonu görünmesin
    if (_kullaniciRolu == DbTables.personel) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kişisel Bilgilerim', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: yukleniyor
            ? const LoadingWidget()
            : ListView.builder(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                itemCount: filtreliPersoneller.length,
                itemBuilder: (context, index) {
                  final p = filtreliPersoneller[index];
                  return _buildPersonelCard(p, isMobile, canTap: false);
                },
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Listesi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: isMobile ? null : [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getPersoneller,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : Column(
              children: [
                // Arama alanı
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 12 : 16, 
                    isMobile ? 12 : 16, 
                    isMobile ? 12 : 16, 
                    0
                  ),
                  child: TextField(
                    controller: _aramaController,
                    decoration: InputDecoration(
                      hintText: isMobile 
                          ? 'Personel ara...' 
                          : 'Personel ara... (isim, telefon, pozisyon, departman, tckn, email)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _arama.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _aramaController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Sonuç sayısı
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      Text(
                        '${filtreliPersoneller.length} personel',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Spacer(),
                      if (!isMobile)
                        TextButton.icon(
                          onPressed: _getPersoneller,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Yenile'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Liste
                Expanded(
                  child: isMobile || isTablet
                      ? _buildListView(isMobile)
                      : _buildGridView(),
                ),
              ],
            ),
      floatingActionButton: _kullaniciRolu == DbTables.personel
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: Text(isMobile ? 'Ekle' : 'Personel Ekle'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonelEklePage()),
                );
                if (result == true) {
                  _getPersoneller();
                }
              },
            ),
    );
  }

  Widget _buildListView(bool isMobile) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
      itemCount: filtreliPersoneller.length,
      itemBuilder: (context, index) {
        final p = filtreliPersoneller[index];
        return _buildPersonelCard(p, isMobile, canTap: true);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: filtreliPersoneller.length,
      itemBuilder: (context, index) {
        final p = filtreliPersoneller[index];
        return _buildPersonelCard(p, false, canTap: true);
      },
    );
  }

  Widget _buildPersonelCard(PersonelModel p, bool isMobile, {required bool canTap}) {
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canTap ? () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonelDetayPage(id: p.userId),
            ),
          );
          if (result == 'deleted' || result == true) {
            _getPersoneller();
          }
        } : null,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: isMobile ? _buildMobileCardContent(p) : _buildDesktopCardContent(p),
        ),
      ),
    );
  }

  Widget _buildMobileCardContent(PersonelModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              radius: 24,
              child: Text(
                '${p.ad.isNotEmpty ? p.ad[0] : ''}${p.soyad.isNotEmpty ? p.soyad[0] : ''}',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.ad} ${p.soyad}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.pozisyon,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
        const Divider(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildInfoChip(Icons.phone, p.telefon),
            _buildInfoChip(Icons.apartment, p.departman),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopCardContent(PersonelModel p) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          radius: 28,
          child: Text(
            '${p.ad.isNotEmpty ? p.ad[0] : ''}${p.soyad.isNotEmpty ? p.soyad[0] : ''}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${p.ad} ${p.soyad}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.work, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      p.pozisyon,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      p.telefon,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.apartment, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      p.departman,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
