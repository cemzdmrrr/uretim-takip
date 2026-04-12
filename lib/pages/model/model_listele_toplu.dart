// ignore_for_file: invalid_use_of_protected_member
part of 'model_listele.dart';

/// Model listele - toplu islem fonksiyonlari
extension _TopluIslemExt on _ModelListeleState {
  Future<void> _topluIslemYap(String islem) async {
    if (seciliIdler.isEmpty) return;

    switch (islem) {
      case 'durum_guncelle':
        await _topluDurumGuncelle();
        break;
      case 'termin_guncelle':
        await _topluTerminGuncelle();
        break;
      case 'tamamlandi_true':
        await _topluTamamlandiGuncelle(true);
        break;
      case 'tamamlandi_false':
        await _topluTamamlandiGuncelle(false);
        break;
      case 'dokuma_tedarikci_ata':
        await _tedarikciAta('orgu', 'Örgü/Dokuma');
        break;
      case 'konfeksiyon_tedarikci_ata':
        await _tedarikciAta('konfeksiyon', 'Konfeksiyon');
        break;
      case 'yikama_tedarikci_ata':
        await _tedarikciAta('yikama', 'Yıkama');
        break;
      case 'nakis_tedarikci_ata':
        await _tedarikciAta('nakis', 'Nakış');
        break;
      case 'excel_urun_bilgileri':
        await _seciliModelleriUrunBilgileriExcelAktar();
        break;
      case 'excel_uretim_durumu':
        await _seciliModelleriUretimDurumuExcelAktar();
        break;
      case 'sil':
        await _topluSil();
        break;
    }
  }

  // Tedarikçi atama fonksiyonu
  Future<void> _tedarikciAta(String asama, String asamaAdi) async {
    try {
      // Tedarikçileri getir
      final tedarikciler = await supabase
          .from(DbTables.tedarikciler)
          .select('*')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .eq('aktif', true)
          .order('sirket');

      if (tedarikciler.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sistemde aktif tedarikçi bulunamadı.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      String? seciliTedarikciId;
      String? notlar;

      if (!mounted) return;
      final result = await showDialog<Map<String, String?>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text('$asamaAdi Tedarikçisi Ata'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Seçili ${seciliIdler.length} model için $asamaAdi tedarikçisi atanacak:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: '$asamaAdi Tedarikçisi',
                      border: const OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: tedarikciler.map<DropdownMenuItem<String>>((tedarikci) {
                      return DropdownMenuItem<String>(
                        value: tedarikci['id'].toString(),
                        child: Text(tedarikci['sirket'] ?? tedarikci['ad'] ?? 'Tedarikçi'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        seciliTedarikciId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notlar (İsteğe bağlı)',
                      border: OutlineInputBorder(),
                      hintText: 'Atama ile ilgili notlar...',
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      notlar = value;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: seciliTedarikciId == null 
                    ? null 
                    : () => Navigator.pop(ctx, {
                        'tedarikciId': seciliTedarikciId,
                        'notlar': notlar,
                      }),
                child: const Text('Ata'),
              ),
            ],
          ),
        ),
      );

      if (result == null || result['tedarikciId'] == null) return;

      setState(() => yukleniyor = true);

      int basariliAtama = 0;
      int hataliAtama = 0;

      // Aşamaya göre doğru tabloyu belirle
      String tabloAdi;
      switch (asama) {
        case 'dokuma':
        case 'orgu':
          tabloAdi = DbTables.dokumaAtamalari;
          break;
        case 'konfeksiyon':
          tabloAdi = DbTables.konfeksiyonAtamalari;
          break;
        case 'yikama':
          tabloAdi = DbTables.yikamaAtamalari;
          break;
        case 'nakis':
          tabloAdi = DbTables.nakisAtamalari;
          break;
        case 'utu':
          tabloAdi = DbTables.utuAtamalari;
          break;
        default:
          tabloAdi = DbTables.dokumaAtamalari;
      }

      // Seçili modellere tedarikçi ata
      for (String modelId in seciliIdler) {
        try {
          // Önce mevcut atama var mı kontrol et (birden fazla olabilir, sadece ilkini al)
          final mevcutAtamaList = await supabase
              .from(tabloAdi)
              .select('id')
              .eq('model_id', modelId)
              .limit(1);
          
          if (mevcutAtamaList.isNotEmpty) {
            // Güncelle
            await supabase.from(tabloAdi).update({
              'tedarikci_id': int.tryParse(result['tedarikciId'].toString()),
              'durum': 'atandi',
              'notlar': result['notlar'],
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', mevcutAtamaList[0]['id']);
          } else {
            // Yeni kayıt ekle
            await supabase.from(tabloAdi).insert({
              'model_id': modelId,
              'tedarikci_id': int.tryParse(result['tedarikciId'].toString()),
              'durum': 'atandi',
              'notlar': result['notlar'],
              'atama_tarihi': DateTime.now().toIso8601String(),
            });
          }
          
          basariliAtama++;
        } catch (e) {
          debugPrint('Atama hatası (model: $modelId): $e');
          hataliAtama++;
        }
      }

      // Seçimi temizle
      setState(() {
        seciliIdler.clear();
        tumunuSec = false;
        yukleniyor = false;
      });

      // Listeyi yenile
      await modelleriGetir();

      if (mounted) {
        if (hataliAtama == 0) {
          context.showSuccessSnackBar('$basariliAtama model $asamaAdi tedarikçisine atandı.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$basariliAtama başarılı, $hataliAtama hatalı atama.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('$asamaAdi tedarikçi ataması hatası: $e');
      setState(() => yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Atama hatası: $e');
      }
    }
  }

  // Durum güncelleme
  Future<void> _topluDurumGuncelle() async {
    String? seciliYeniDurum;
    
    final durum = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durum Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Seçili ${seciliIdler.length} modelin durumunu güncelleyin:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Yeni Durum',
                border: OutlineInputBorder(),
              ),
              items: durumOptions.where((d) => d != 'Tümü').map((durum) => 
                DropdownMenuItem(value: durum, child: Text(durum))
              ).toList(),
              onChanged: (value) {
                seciliYeniDurum = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, seciliYeniDurum),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );

    if (durum != null) {
      try {
        setState(() => yukleniyor = true);
        
        await supabase
            .from(DbTables.trikoTakip)
            .update({'durum': durum})
            .filter('id', 'in', seciliIdler);

        await modelleriGetir();
        seciliIdler.clear();

        if (mounted) {
          context.showSuccessSnackBar('Durum başarıyla güncellendi');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Güncelleme sırasında hata: $e');
        }
      }
    }
  }

  // Termin tarihi güncelleme
  Future<void> _topluTerminGuncelle() async {
    final tarih = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );

    if (tarih != null) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Termin Tarihi Güncelle'),
          content: Text('Seçili ${seciliIdler.length} modelin termin tarihini "${DateFormat('dd.MM.yyyy').format(tarih)}" olarak güncellemek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Güncelle'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          setState(() => yukleniyor = true);
          
          await supabase
              .from(DbTables.trikoTakip)
              .update({'termin_tarihi': tarih.toIso8601String()})
              .filter('id', 'in', seciliIdler);

          await modelleriGetir();
          seciliIdler.clear();

          if (mounted) {
            context.showSuccessSnackBar('Termin tarihi başarıyla güncellendi');
          }
        } catch (e) {
          if (mounted) {
            context.showErrorSnackBar('Güncelleme sırasında hata: $e');
          }
        }
      }
    }
  }

  // Tamamlandı durumu güncelleme
  Future<void> _topluTamamlandiGuncelle(bool tamamlandi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tamamlandı Durumu Güncelle'),
        content: Text('Seçili ${seciliIdler.length} modeli "${tamamlandi ? "Tamamlandı" : "Devam Ediyor"}" olarak işaretlemek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => yukleniyor = true);
        
        await supabase
            .from(DbTables.trikoTakip)
            .update({'tamamlandi': tamamlandi})
            .filter('id', 'in', seciliIdler);

        await modelleriGetir();
        seciliIdler.clear();

        if (mounted) {
          context.showSuccessSnackBar('Tamamlandı durumu başarıyla güncellendi');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Güncelleme sırasında hata: $e');
        }
      }
    }
  }

  // Toplu silme
  Future<void> _topluSil() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modelleri Sil'),
        content: Text('Seçili ${seciliIdler.length} modeli silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => yukleniyor = true);
        
        // Önce ilişkili atamaları sil (foreign key constraint önlemek için)
        final atamaTablolari = [
          DbTables.dokumaAtamalari,
          DbTables.konfeksiyonAtamalari,
          DbTables.nakisAtamalari,
          DbTables.yikamaAtamalari,
          DbTables.ilikDugmeAtamalari,
          DbTables.utuAtamalari,
          DbTables.kaliteKontrolAtamalari,
          DbTables.paketlemeAtamalari,
          DbTables.sevkiyatKayitlari,
        ];
        
        for (final tablo in atamaTablolari) {
          try {
            await supabase.from(tablo).delete().filter('model_id', 'in', seciliIdler);
          } catch (e) {
            // Tablo yoksa veya kayıt yoksa devam et
          }
        }
        
        // Modelleri sil
        await supabase
            .from(DbTables.trikoTakip)
            .delete()
            .filter('id', 'in', seciliIdler);

        // Önce local listeden kaldır
        if (!mounted) return;
        setState(() {
          modeller.removeWhere((m) => seciliIdler.contains(m['id'].toString()));
          filtreliModeller.removeWhere((m) => seciliIdler.contains(m['id'].toString()));
        });
        
        seciliIdler.clear();
        await modelleriGetir();

        if (mounted) {
          context.showSuccessSnackBar('Seçili modeller başarıyla silindi');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Silme işlemi sırasında hata: $e');
        }
      }
    }
  }

}
