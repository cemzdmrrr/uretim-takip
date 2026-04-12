// ignore_for_file: invalid_use_of_protected_member
part of 'odeme_page.dart';

/// Odeme page - dialog, hesaplama ve yardimci metotlar
extension _AksiyonExt on _OdemePageState {
  Future<void> _yeniOdemeEkle() async {
    String tur = 'avans';
    double? tutar;
    String aciklama = '';
    final formKey = GlobalKey<FormState>();
    final tutarController = TextEditingController();
    String? seciliPersonelId = widget.personelId;
    List<Map<String, String>> personelList = [];
    bool yukleniyor = true;
    String? modalDonem = seciliDonem;
    // Personel listesini çek
    try {
      final servis = PersonelService();
      final personeller = await servis.getPersoneller();
      personelList = personeller.map((p) => {'id': p.userId, 'ad': p.ad}).toList();
      if ((seciliPersonelId.trim().isEmpty) && personelList.isNotEmpty) {
        seciliPersonelId = personelList.first['id'];
      }
      yukleniyor = false;
    } catch (e) {
      yukleniyor = false;
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Modal açılırken id boşsa ilk id'yi ata
          if (((seciliPersonelId ?? '').trim().isEmpty) && personelList.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                seciliPersonelId = personelList.first['id'];
              });
            });
          }
          // Personel rolü için sadece kendi adı ve sadece avans türü göster
          final sadeceKendisi = currentUserRole == DbTables.personel;
          final sadeceAvans = currentUserRole == DbTables.personel;
          final filteredPersonelList = sadeceKendisi
              ? personelList.where((p) => p['id'] == currentUserId).toList()
              : personelList;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.payment, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Yeni Avans/Ödeme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  yukleniyor
                      ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                      : Form(
                          key: formKey,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  children: [
                                    // Dönem seçici
                                    DonemSecici(
                                      seciliDonem: modalDonem,
                                      onDonemChanged: (donem) {
                                        setState(() => modalDonem = donem);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      initialValue: seciliPersonelId,
                                      items: filteredPersonelList
                                          .map((p) => DropdownMenuItem(
                                                value: p['id'],
                                                child: Text(p['ad'] ?? '', style: const TextStyle(color: Colors.blue)),
                                              ))
                                          .toList(),
                                      onChanged: sadeceKendisi ? null : (v) => setState(() => seciliPersonelId = v),
                                      decoration: InputDecoration(
                                        labelText: 'Personel Seç',
                                        labelStyle: const TextStyle(color: Colors.blue),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.blue.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.blue.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      initialValue: tur,
                                      items: sadeceAvans
                                          ? [const DropdownMenuItem(value: 'avans', child: Text('Avans', style: TextStyle(color: Colors.blue)))]
                                          : const [
                                              DropdownMenuItem(value: 'avans', child: Text('Avans', style: TextStyle(color: Colors.blue))),
                                              DropdownMenuItem(value: 'prim', child: Text('Prim', style: TextStyle(color: Colors.blue))),
                                              DropdownMenuItem(value: DbTables.mesai, child: Text('Fazla Mesai', style: TextStyle(color: Colors.blue))),
                                              DropdownMenuItem(value: 'ikramiye', child: Text('İkramiye', style: TextStyle(color: Colors.blue))),
                                              DropdownMenuItem(value: 'kesinti', child: Text('Kesinti', style: TextStyle(color: Colors.blue))),
                                            ],
                                      onChanged: sadeceAvans ? null : (v) => tur = v ?? 'avans',
                                      decoration: InputDecoration(
                                        labelText: 'Tür',
                                        labelStyle: const TextStyle(color: Colors.blue),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.blue.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.blue.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: tutarController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Tutar',
                                        labelStyle: const TextStyle(color: Colors.blue),
                                        prefixIcon: const Icon(Icons.attach_money, color: Colors.blue),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.blue.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.blue.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      style: const TextStyle(color: Colors.blue),
                                      validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                                      onChanged: (v) => tutar = double.tryParse(v),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Açıklama',
                                        labelStyle: const TextStyle(color: Colors.blue),
                                        prefixIcon: const Icon(Icons.note, color: Colors.blue),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.blue.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.blue.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      style: const TextStyle(color: Colors.blue),
                                      onChanged: (v) => aciklama = v,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('İptal', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() != true) return;
                            if (tutar == null) return;
                            if ((seciliPersonelId ?? '').trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Geçerli bir personel seçiniz!')),
                              );
                              return;
                            }
                            // Giriş yapan kullanıcının id'sini al
                            final currentUser = Supabase.instance.client.auth.currentUser;
                            final userId = currentUser?.id;
                            if (userId == null || userId.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Kullanıcı oturum bilgisi alınamadı!')),
                              );
                              return;
                            }
                            debugPrint('Kayıt için seçili personel id: "$seciliPersonelId"');
                            // Dönem'e göre tarih hesapla
                            DateTime odemeTarihi;
                            if (modalDonem != null && modalDonem!.isNotEmpty) {
                              final parts = modalDonem!.split('-');
                              final yil = int.tryParse(parts[0]) ?? DateTime.now().year;
                              final ay = int.tryParse(parts[1]) ?? DateTime.now().month;
                              final now = DateTime.now();
                              if (yil == now.year && ay == now.month) {
                                odemeTarihi = now;
                              } else {
                                odemeTarihi = DateTime(yil, ay, 1);
                              }
                            } else {
                              odemeTarihi = DateTime.now();
                            }
                            final odeme = OdemeModel(
                              id: null,
                              personelId: seciliPersonelId!,
                              userId: userId, // Artık oturum açan kullanıcının id'si atanıyor
                              tur: tur,
                              tutar: tutar!,
                              aciklama: aciklama,
                              tarih: odemeTarihi,
                              durum: 'beklemede',
                              onaylayanId: null,
                            );
                            debugPrint('Gönderilen ödeme map: \x1B[33m\x1B[0m${odeme.toMap()}');
                            try {
                              await OdemeService().addOdeme(odeme);
                              // Bildirim: Personel talep oluşturduğunda tüm adminlere gönder
                              try {
                                final adminList = await Supabase.instance.client
                                    .from(DbTables.userRoles)
                                    .select('user_id')
                                    .eq('role', 'admin')
                                    .eq('aktif', true);
                                for (final admin in adminList) {
                                  await NotificationService().sendNotification(
                                    userId: admin['user_id'],
                                    title: 'Yeni Avans/Ödeme Talebi',
                                    message: '${personel?.ad ?? 'Bir personel'} yeni bir $tur talebinde bulundu.',
                                  );
                                }
                              } catch (bildirimHata) {
                                debugPrint('Bildirim gönderme hatası: $bildirimHata');
                                // Bildirim hatası olsa bile işlemi devam ettir
                              }
                              if (!context.mounted) return;
                              Navigator.pop(ctx);
                              // ignore: use_build_context_synchronously
                              context.showSnackBar('Avans/Ödeme talebi başarıyla oluşturuldu!');
                              _getOdemeler();
                            } catch (e) {
                              debugPrint('Ödeme ekleme hatası: $e');
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Kayıt hatası: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bakiyeCard(String label, double tutar, Color color, {String? altYazi}) {
    return Card(
      color: Colors.blue,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${tutar.toStringAsFixed(2)} TL', style: const TextStyle(fontSize: 16, color: Colors.white)),
            if (altYazi != null) ...[
              const SizedBox(height: 2),
              Text(altYazi, style: const TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }

  IconData _odemeIcon(String tur) {
    switch (tur) {
      case 'avans':
        return Icons.payments;
      case 'prim':
        return Icons.star;
      case DbTables.mesai:
        return Icons.access_time;
      case 'ikramiye':
        return Icons.card_giftcard;
      case 'kesinti':
        return Icons.remove_circle;
      default:
        return Icons.attach_money;
    }
  }

  Color _odemeRenk(String tur) {
    switch (tur) {
      case 'avans':
        return Colors.orange;
      case 'prim':
        return Colors.green;
      case DbTables.mesai:
        return Colors.blue;
      case 'ikramiye':
        return Colors.purple;
      case 'kesinti':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double get saatlikMesaiUcreti {
    if (personel == null) return 0;
    final maas = double.tryParse(personel!.netMaas) ?? 0;
    final gunlukSaat = double.tryParse(personel!.gunlukCalismaSaati) ?? 0;
    if (gunlukSaat == 0) return 0;
    return (maas / 30 / gunlukSaat) * 1.5; // Saatlik mesai için x1.5 çarpanı
  }

  Future<double> _getAylikToplamMesaiUcreti() async {
    if (personel == null) return 0;
    final now = DateTime.now();
    final mesailer = await MesaiService().getMesailerForPersonel(personel!.userId);
    
    final netMaas = double.tryParse(personel!.netMaas) ?? 0;
    final gunlukSaat = double.tryParse(personel!.gunlukCalismaSaati) ?? 0;
    final saatlikUcret = netMaas > 0 && gunlukSaat > 0 ? (netMaas / 30 / gunlukSaat) : 0;
    
    double toplamMesaiUcret = 0;
    
    for (final m in mesailer) {
      if (m.onayDurumu != 'onaylandi') continue;
      // Sadece bu ay içindeki mesaileri hesapla
      if (m.tarih.month == now.month && m.tarih.year == now.year) {
        if (m.saat != null) {
          // Mesai ücretini hesapla - türe göre farklı hesaplama yöntemleri
          double hesaplananUcret = 0;
          
          if (m.mesaiTuru == 'Pazar') {
            // Pazar mesaisi: Günlük net maaş x 2 (saat bazında değil, günlük sabit ücret)
            final gunlukNetMaas = netMaas / 30;
            hesaplananUcret = gunlukNetMaas * 2.0;
          } else if (m.mesaiTuru == 'Bayram') {
            // Bayram mesaisi: Saatlik ücret x database'den gelen çarpan x saat
            final carpan = m.carpan ?? 1.5;
            hesaplananUcret = saatlikUcret * carpan * m.saat!;
          } else if (m.mesaiTuru == 'Saatlik') {
            // Saatlik mesai: Saatlik ücret x 1.5 x saat
            hesaplananUcret = saatlikUcret * 1.5 * m.saat!;
          }
          
          // Yemek ücreti mesai hesaplamasına dahil edilmiyor, ayrı olarak finansal özette toplanacak
          toplamMesaiUcret += hesaplananUcret;
        }
      }
    }
    
    return toplamMesaiUcret;
  }

  Future<double> _getAylikMesaiYemekUcreti() async {
    if (personel == null) return 0;
    final now = DateTime.now();
    final mesailer = await MesaiService().getMesailerForPersonel(personel!.userId);
    
    double toplamYemekUcreti = 0;
    
    for (final m in mesailer) {
      if (m.onayDurumu != 'onaylandi') continue;
      // Sadece bu ay içindeki mesaileri hesapla
      if (m.tarih.month == now.month && m.tarih.year == now.year) {
        // Pazar ve Bayram mesaileri için yemek ücreti var
        if (m.mesaiTuru == 'Pazar' || m.mesaiTuru == 'Bayram') {
          toplamYemekUcreti += m.yemekUcreti ?? 0;
        }
      }
    }
    
    return toplamYemekUcreti;
  }

  Future<double> _getKesintiTutari() async {
    if (personel == null) return 0;
    final izinler = await IzinService().getIzinlerForPersonel(personel!.userId);
    final maas = double.tryParse(personel!.netMaas) ?? 0;
    const toplamGun = 30; // Standart ay
    final gunlukUcret = maas / toplamGun;
    double toplamKesinti = 0;
    for (final izin in izinler) {
      if (izin.onayDurumu != 'onaylandi') continue;
      if (izin.izinTuru == 'Raporlu') {
        // Raporlu günler için
        final raporluGun = izin.gunSayisi;
        if (raporluGun > 2) {
          final odemeGun = raporluGun - 2;
          // IzinModel'de toplamOdeme ve tedaviSekli yok, sadece günlük ücret ve açıklama ile devam et
          // Tedavi şekli açıklamada aranacak
          double oran = 2 / 3; // Varsayılan ayakta tedavi
          if ((izin.aciklama.toLowerCase().contains('yatarak'))) {
            oran = 1 / 2;
          }
          // Ödenmeyen kısım: (1 - oran)
          toplamKesinti += odemeGun * gunlukUcret * (1 - oran);
        }
      } else if (izin.izinTuru == 'Ücretsiz İzin') {
        toplamKesinti += gunlukUcret * izin.gunSayisi;
      }
      // Diğer izin türlerinde kesinti yok
    }
    return toplamKesinti;
  }

  Future<bool> kullaniciAdminMi() async {
    return currentUserRole == 'admin';
  }

  Future<double> _getAylikYolUcreti() async {
    if (personel == null) return 0;
    // Personel tablosundaki yol ücreti + eğer varsa ek yol ücretleri
    final yolUcreti = double.tryParse(personel!.yolUcreti) ?? 0;
    return yolUcreti;
  }
}
