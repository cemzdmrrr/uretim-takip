import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

class UretimDaliYonetimiPage extends StatefulWidget {
  const UretimDaliYonetimiPage({super.key});

  @override
  State<UretimDaliYonetimiPage> createState() => _UretimDaliYonetimiPageState();
}

class _UretimDaliYonetimiPageState extends State<UretimDaliYonetimiPage> {
  bool _yukleniyor = true;
  bool _islemSuruyor = false;
  List<Map<String, dynamic>> _dallar = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    if (mounted) {
      setState(() => _yukleniyor = true);
    }
    try {
      _dallar = await PlatformAdminService.uretimDallariGetir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('Üretim Dalı Yönetimi'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _verileriYukle,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHero(),
                  const SizedBox(height: 20),
                  if (_dallar.isEmpty)
                    _buildEmptyState()
                  else
                    ..._dallar.map(_buildDalCard),
                ],
              ),
            ),
    );
  }

  Widget _buildHero() {
    final aktif = _dallar.where((item) => item['aktif'] == true).length;
    final toplamAsama = _dallar.fold<int>(0, (toplam, item) {
      final asamalar = item['uretim_asamalari'];
      return toplam + (asamalar is List ? asamalar.length : 0);
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9A3412), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Üretim dalı kataloğu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aktif dalları ve aşama yapılarını merkezi olarak gözden geçirin.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _heroStat(
                  'Toplam dal', '${_dallar.length}', Icons.category_outlined),
              _heroStat('Aktif', '$aktif', Icons.check_circle_outline),
              _heroStat('Pasif', '${_dallar.length - aktif}',
                  Icons.pause_circle_outline),
              _heroStat(
                  'Toplam aşama', '$toplamAsama', Icons.alt_route_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDalCard(Map<String, dynamic> item) {
    final aktif = item['aktif'] == true;
    final dalKodu =
        item['tekstil_dali']?.toString() ?? item['dal_kodu']?.toString() ?? '-';
    final dalAdi = item['dal_adi']?.toString() ?? dalKodu;
    final aciklama = item['aciklama']?.toString() ?? '';
    final asamalar = item['uretim_asamalari'];
    final asamaListesi = asamalar is List ? asamalar : const [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: aktif ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.precision_manufacturing_outlined,
            color: aktif ? const Color(0xFFC2410C) : const Color(0xFF64748B),
          ),
        ),
        title: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              dalAdi,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            _pill(dalKodu, const Color(0xFFE2E8F0), const Color(0xFF334155)),
            _pill(
              aktif ? 'Aktif' : 'Pasif',
              aktif ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              aktif ? const Color(0xFF15803D) : const Color(0xFF64748B),
            ),
            _pill(
              '${asamaListesi.length} aşama',
              const Color(0xFFFFEDD5),
              const Color(0xFFC2410C),
            ),
          ],
        ),
        subtitle: aciklama.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  aciklama,
                  style: const TextStyle(color: Color(0xFF475569), height: 1.4),
                ),
              ),
        trailing: Switch(
          value: aktif,
          onChanged: _islemSuruyor
              ? null
              : (value) => _durumDegistir(item['id'] as String, value),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (asamaListesi.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bu üretim dalı için aşama tanımı bulunmuyor.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < asamaListesi.length; i++)
                  _asamaChip(i + 1, _asamaEtiketi(asamaListesi[i])),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_tree_outlined, size: 42, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Henüz üretim dalı tanımı yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Servis tarafında dal tanımları geldiğinde burada listelenecek.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _asamaChip(int index, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC2410C),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9A3412),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _asamaEtiketi(dynamic asama) {
    if (asama is Map) {
      return asama['asama_adi']?.toString() ?? asama.toString();
    }
    return asama?.toString() ?? '-';
  }

  Future<void> _durumDegistir(String dalId, bool aktif) async {
    try {
      setState(() => _islemSuruyor = true);
      await PlatformAdminService.uretimDaliGuncelle(dalId, {'aktif': aktif});
      await _verileriYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
  }
}
