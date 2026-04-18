import 'package:flutter/material.dart';
import 'package:uretim_takip/services/sayfa_yetki_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

/// Firma seviyesinde sayfa yetki yönetimi sayfası.
/// Her firma için hangi sayfaların aktif olacağını belirler.
class FirmaSayfaYetkiYonetimiPage extends StatefulWidget {
  const FirmaSayfaYetkiYonetimiPage({super.key});

  @override
  State<FirmaSayfaYetkiYonetimiPage> createState() =>
      _FirmaSayfaYetkiYonetimiPageState();
}

class _FirmaSayfaYetkiYonetimiPageState
    extends State<FirmaSayfaYetkiYonetimiPage> {
  Set<String> _aktifSayfalar = {};
  bool _yukleniyor = true;
  bool _kaydediyor = false;
  String? _firmaAdi;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      _firmaAdi = TenantManager.instance.firmaDetay?['firma_adi']?.toString() ??
          TenantManager.instance.firmaAdi;
      final yetkiler = await SayfaYetkiService.firmaYetkileriniGetir(firmaId);
      setState(() {
        _aktifSayfalar = yetkiler;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Yüklenirken hata: $e');
      }
    }
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediyor = true);
    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      await SayfaYetkiService.firmaYetkileriniKaydet(firmaId, _aktifSayfalar);
      if (mounted) {
        context.showSuccessSnackBar('Firma sayfa yetkileri kaydedildi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Kaydetme hatası: $e');
      }
    } finally {
      setState(() => _kaydediyor = false);
    }
  }

  void _tumunuSec() {
    setState(() {
      _aktifSayfalar = SayfaRegistry.tumSayfalar.map((s) => s.kod).toSet();
    });
  }

  void _tumunuKaldir() {
    setState(() {
      _aktifSayfalar = {};
    });
  }

  void _kategoriTopluIslem(String kategori, bool sec) {
    setState(() {
      final sayfalar = SayfaRegistry.kategoriyeGore(kategori);
      for (final sayfa in sayfalar) {
        if (sec) {
          _aktifSayfalar.add(sayfa.kod);
        } else {
          _aktifSayfalar.remove(sayfa.kod);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma Sayfa Yetkileri'),
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        actions: [
          _kaydediyor
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Kaydet',
                  onPressed: _kaydet,
                ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                _buildHeader(),
                // Kategori listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: SayfaRegistry.tumKategoriler.length,
                    itemBuilder: (context, index) {
                      final kategori = SayfaRegistry.tumKategoriler[index];
                      return _buildKategoriKarti(kategori);
                    },
                  ),
                ),
                // Kaydet butonu
                _buildKaydetButonu(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final toplamSayfa = SayfaRegistry.tumSayfalar.length;
    final aktifSayfa = _aktifSayfalar.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, color: Color(0xFF5C6BC0), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _firmaAdi ?? 'Firma',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Firmanız için hangi sayfaların görünür olacağını belirleyin',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$aktifSayfa / $toplamSayfa sayfa aktif',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C6BC0),
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _tumunuSec,
                icon: const Icon(Icons.select_all, size: 16),
                label:
                    const Text('Tümünü Aç', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _tumunuKaldir,
                icon: const Icon(Icons.deselect, size: 16),
                label: const Text('Tümünü Kapat',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
          if (_aktifSayfalar.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hiç sayfa seçilmezse tüm sayfalar görünür olur (varsayılan davranış).',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKaydetButonu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _kaydediyor ? null : _kaydet,
          icon: _kaydediyor
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label:
              Text(_kaydediyor ? 'Kaydediliyor...' : 'Firma Yetkilerini Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C6BC0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildKategoriKarti(String kategori) {
    final sayfalar = SayfaRegistry.kategoriyeGore(kategori);
    final hepsiSecili =
        sayfalar.every((s) => _aktifSayfalar.contains(s.kod));
    final hicSecili =
        sayfalar.every((s) => !_aktifSayfalar.contains(s.kod));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          // Kategori header
          InkWell(
            onTap: () => _kategoriTopluIslem(kategori, !hepsiSecili),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: hepsiSecili
                    ? const Color(0xFF5C6BC0).withValues(alpha: 0.1)
                    : hicSecili
                        ? Colors.grey[50]
                        : Colors.orange.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Icon(
                    hepsiSecili
                        ? Icons.check_circle
                        : hicSecili
                            ? Icons.cancel_outlined
                            : Icons.remove_circle_outline,
                    color: hepsiSecili
                        ? const Color(0xFF5C6BC0)
                        : hicSecili
                            ? Colors.grey
                            : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kategori,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hepsiSecili
                            ? const Color(0xFF5C6BC0)
                            : Colors.grey[800],
                      ),
                    ),
                  ),
                  Text(
                    '${sayfalar.where((s) => _aktifSayfalar.contains(s.kod)).length}/${sayfalar.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          // Sayfa toggle'lar
          ...sayfalar.map((sayfa) {
            final aktif = _aktifSayfalar.contains(sayfa.kod);
            return SwitchListTile(
              dense: true,
              secondary: Icon(sayfa.ikon,
                  size: 20,
                  color: aktif
                      ? const Color(0xFF5C6BC0)
                      : Colors.grey[400]),
              title: Text(sayfa.etiket,
                  style: TextStyle(
                      fontSize: 13,
                      color:
                          aktif ? Colors.black87 : Colors.grey[500])),
              subtitle: Text(sayfa.kod,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey[400])),
              value: aktif,
              activeColor: const Color(0xFF5C6BC0),
              onChanged: (val) {
                setState(() {
                  if (val) {
                    _aktifSayfalar.add(sayfa.kod);
                  } else {
                    _aktifSayfalar.remove(sayfa.kod);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
