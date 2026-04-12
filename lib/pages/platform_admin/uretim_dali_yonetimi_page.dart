import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

/// Platform Admin - Üretim Dalı Tanım Yönetimi Sayfası.
class UretimDaliYonetimiPage extends StatefulWidget {
  const UretimDaliYonetimiPage({super.key});

  @override
  State<UretimDaliYonetimiPage> createState() =>
      _UretimDaliYonetimiPageState();
}

class _UretimDaliYonetimiPageState extends State<UretimDaliYonetimiPage> {
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _dallar = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      _dallar = await PlatformAdminService.uretimDallariGetir();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üretim Dalı Yönetimi'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _dallar.isEmpty
              ? const Center(child: Text('Henüz üretim dalı tanımı yok'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dallar.length,
                  itemBuilder: (context, index) {
                    final dal = _dallar[index];
                    final aktif = dal['aktif'] == true;
                    final dalKodu =
                        dal['tekstil_dali']?.toString() ?? dal['dal_kodu']?.toString() ?? '';
                    final dalAdi = dal['dal_adi']?.toString() ?? dalKodu;
                    final aciklama = dal['aciklama']?.toString();
                    final asamalar = dal['uretim_asamalari'];
                    final asamaSayisi = asamalar is List ? asamalar.length : 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: aktif
                              ? const Color(0xFFE65100).withAlpha(50)
                              : Colors.grey.withAlpha(50),
                        ),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: aktif
                              ? const Color(0xFFE65100).withAlpha(25)
                              : Colors.grey.withAlpha(25),
                          child: Icon(
                            Icons.factory,
                            color: aktif
                                ? const Color(0xFFE65100)
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              dalAdi,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                dalKodu,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            if (aciklama != null && aciklama.isNotEmpty) ...[
                              Expanded(
                                child: Text(
                                  aciklama,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '$asamaSayisi aşama',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: aktif,
                          onChanged: (val) =>
                              _durumDegistir(dal['id'] as String, val),
                          activeTrackColor: const Color(0xFFE65100),
                        ),
                        children: [
                          if (asamalar is List && asamalar.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const Text(
                                    'Üretim Aşamaları',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      for (int i = 0;
                                          i < asamalar.length;
                                          i++)
                                        Chip(
                                          avatar: CircleAvatar(
                                            backgroundColor: const Color(
                                                    0xFFE65100)
                                                .withAlpha(25),
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFE65100),
                                              ),
                                            ),
                                          ),
                                          label: Text(
                                            asamalar[i] is Map
                                                ? asamalar[i]['asama_adi']
                                                        ?.toString() ??
                                                    asamalar[i].toString()
                                                : asamalar[i].toString(),
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _durumDegistir(String dalId, bool aktif) async {
    try {
      await PlatformAdminService.uretimDaliGuncelle(
          dalId, {'aktif': aktif});
      await _verileriYukle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
