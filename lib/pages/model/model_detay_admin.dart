// ignore_for_file: invalid_use_of_protected_member
part of 'model_detay.dart';

/// Admin operations (restart, update, delete stages) for _ModelDetayState.
extension _AdminIslemlerExt on _ModelDetayState {
  // ============ ADMIN İŞLEM FONKSİYONLARI ============

  /// Aşamayı yeniden başlat (tamamlanmış aşamayı bekleyen durumuna çevir)
  Future<void> _yenidenBaslatDialog(Map<String, dynamic> asama) async {
    final asamaAdi = asama['ad'] ?? asama['asama_adi'] ?? asama['asamaAdi'] ?? 'Bilinmeyen';
    final asamaKodu = asama['kod'] ?? asama['asama_kodu'] ?? asama['asamaKodu'] ?? '';
    final tabloAdi = utils.getTabloAdi(asamaKodu);
    
    if (tabloAdi == null) {
      context.showErrorSnackBar('Bu aşama için tablo bulunamadı');
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Aşamayı Yeniden Başlat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$asamaAdi aşamasını yeniden başlatmak istiyor musunuz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem aşamadaki tüm atamaları "bekleyen" durumuna çevirecek.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.refresh),
            label: const Text('Yeniden Başlat'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await supabase.from(tabloAdi).update({
          'durum': 'bekleyen',
          'tamamlanan_adet': 0,
          'tamamlama_tarihi': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('model_id', widget.modelId);

        if (mounted) {
          context.showSuccessSnackBar('✅ $asamaAdi aşaması yeniden başlatıldı');
          await verileriGetir();
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Hata: $e');
        }
      }
    }
  }

  /// Aşamadaki tüm atamaları sil
  Future<void> _tumAtamalariSilDialog(Map<String, dynamic> asama) async {
    final asamaAdi = asama['ad'] ?? asama['asama_adi'] ?? asama['asamaAdi'] ?? 'Bilinmeyen';
    final asamaKodu = asama['kod'] ?? asama['asama_kodu'] ?? asama['asamaKodu'] ?? '';
    final tabloAdi = utils.getTabloAdi(asamaKodu);
    
    if (tabloAdi == null) {
      context.showErrorSnackBar('Bu aşama için tablo bulunamadı');
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Tüm Atamaları Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$asamaAdi aşamasındaki TÜM atamaları silmek istiyor musunuz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DİKKAT: Bu işlem geri alınamaz! Tüm atama kayıtları silinecek.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Tümünü Sil'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await supabase.from(tabloAdi).delete().eq('model_id', widget.modelId);

        if (mounted) {
          context.showSuccessSnackBar('✅ $asamaAdi aşamasındaki tüm atamalar silindi');
          Navigator.pop(context); // Dialog'u kapat
          await verileriGetir();
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Hata: $e');
        }
      }
    }
  }

  /// Tek atama durumunu değiştir
  Future<void> _tekAtamaDurumDegistirDialog(Map<String, dynamic> atama, String asamaKodu) async {
    final tabloAdi = utils.getTabloAdi(asamaKodu);
    if (tabloAdi == null) return;

    String secilenDurum = atama['durum'] ?? 'bekleyen';
    
    final durumlar = [
      {'kod': 'bekleyen', 'ad': 'Bekleyen', 'renk': Colors.grey},
      {'kod': 'atandi', 'ad': 'Atandı', 'renk': Colors.orange},
      {'kod': 'onaylandi', 'ad': 'Onaylandı', 'renk': Colors.blue},
      {'kod': 'devam_ediyor', 'ad': 'Devam Ediyor', 'renk': Colors.amber},
      {'kod': 'uretimde', 'ad': 'Üretimde', 'renk': Colors.purple},
      {'kod': 'tamamlandi', 'ad': 'Tamamlandı', 'renk': Colors.green},
      {'kod': 'reddedildi', 'ad': 'Reddedildi', 'renk': Colors.red},
    ];

    final yeniDurum = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Durum Değiştir'),
            ],
          ),
          content: RadioGroup<String>(
            groupValue: secilenDurum,
            onChanged: (value) {
              setState(() => secilenDurum = value!);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: durumlar.map((d) => RadioListTile<String>(
                title: Text(d['ad'] as String),
                value: d['kod'] as String,
                activeColor: d['renk'] as Color,
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, secilenDurum),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (yeniDurum != null && yeniDurum != atama['durum']) {
      try {
        final updateData = <String, dynamic>{
          'durum': yeniDurum,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (yeniDurum == 'tamamlandi') {
          updateData['tamamlama_tarihi'] = DateTime.now().toIso8601String();
        }

        await supabase.from(tabloAdi).update(updateData).eq('id', atama['id']);

        if (mounted) {
          context.showSuccessSnackBar('✅ Durum güncellendi');
          Navigator.pop(context); // Dialog'u kapat
          await verileriGetir();
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Hata: $e');
        }
      }
    }
  }

  /// Tek atamayı sil
  Future<void> _tekAtamaSilDialog(Map<String, dynamic> atama, String asamaKodu) async {
    final tabloAdi = utils.getTabloAdi(asamaKodu);
    if (tabloAdi == null) return;

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Atamayı Sil'),
          ],
        ),
        content: const Text('Bu atama kaydını silmek istiyor musunuz?\n\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Sil'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await supabase.from(tabloAdi).delete().eq('id', atama['id']);

        if (mounted) {
          context.showSuccessSnackBar('✅ Atama silindi');
          Navigator.pop(context); // Dialog'u kapat
          await verileriGetir();
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Hata: $e');
        }
      }
    }
  }

  /// Aşama kodundan tablo adını döndür
  /// Atanmış adet: Sadece dokuma (ilk aşama) atamalarının toplamı
  /// Üretim dokumadan başladığı için üretime giren toplam adet = dokuma atamaları
  int _getTotalAtananAdet() {
    int toplam = 0;
    for (var atama in dokumaAtamalari) {
      toplam += (atama['adet'] ?? atama['talep_edilen_adet'] ?? 0) as int;
    }
    return toplam;
  }

  /// Tamamlanan adet: Ütü (son aşama) tamamlanan adetlerin toplamı
  /// Üretim ütüden çıktığında tamamlanmış sayılır
  int _getTotalTamamlananAdet() {
    int toplam = 0;
    for (var atama in utuAtamalari) {
      toplam += (atama['tamamlanan_adet'] ?? 0) as int;
    }
    return toplam;
  }




  void _showAtamaDialog(String asamaKey) {
    final adetController = TextEditingController();
    String? secilenKullaniciId;
    Map<String, dynamic>? secilenKullanici; // Seçilen kullanıcının tam bilgisi
    List<Map<String, dynamic>> kullanicilar = [];
    bool loading = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Kullanıcıları yükle
          if (loading) {
            _loadUsers(asamaKey).then((users) {
              setState(() {
                kullanicilar = users;
                loading = false;
              });
            });
          }
          
          return AlertDialog(
            title: Text('${utils.getAsamaDisplayName(asamaKey)} - Yeni Atama'),
            content: SizedBox(
              width: 500, // Daha geniş yap
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Model: ${currentModelData?['marka']} - ${currentModelData?['item_no']}'),
                    const SizedBox(height: 8),
                    Text(
                      'Aşama: ${utils.getAsamaDisplayName(asamaKey)} (${_getRequiredRolesForStage(asamaKey).join(', ')})',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                    
                    // Beden Dağılımı Bilgisi
                    if (currentModelData?['bedenler'] != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.straighten, size: 18, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Beden Dağılımı',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildBedenDagilimi(currentModelData?['bedenler']),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Kullanıcı seçimi
                    const Text(
                      'Atanacak Kullanıcı:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),
                  loading
                      ? const LoadingWidget()
                      : SizedBox(
                          width: double.infinity,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Kullanıcı seçin',
                            ),
                            initialValue: secilenKullaniciId,
                            items: kullanicilar.map((user) {
                              return DropdownMenuItem<String>(
                                value: user['id'],
                                child: SizedBox(
                                  width: 400, // Dropdown item genişliği
                                  child: Text(
                                    '${user['email']} [${user['role']}]',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                secilenKullaniciId = value;
                                // Seçilen kullanıcının tam bilgisini bul
                                secilenKullanici = kullanicilar.firstWhere(
                                  (user) => user['id'] == value,
                                  orElse: () => {},
                                );
                              });
                            },
                          ),
                        ),
                  
                  const SizedBox(height: 16),
                  
                  // Adet girişi
                  const Text(
                    'Atanacak Adet:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: adetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Adet girin',
                      helperText: 'Kalan: ${(currentModelData?['toplam_adet'] ?? 0) - _getTotalAtananAdet()}',
                    ),
                    onChanged: (value) {
                      setState(() {}); // Buton durumunu güncellemek için
                    },
                  ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: secilenKullaniciId != null && adetController.text.isNotEmpty
                    ? () => _atamaYap(asamaKey, secilenKullaniciId!, int.tryParse(adetController.text) ?? 0, userInfo: secilenKullanici)
                    : null,
                child: const Text('Atama Yap'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadUsers(String asamaKey) async {
    try {
      // Aşamaya göre gerekli rolleri belirle
      final List<String> gerekliRoller = _getRequiredRolesForStage(asamaKey);
      
      debugPrint('🔍 _loadUsers başladı - asamaKey: $asamaKey, gerekli roller: $gerekliRoller');
      
      
      // Tüm tedarikcileri al ve faaliyet alanına göre filtrele
      final allTedarikciler = await supabase
          .from(DbTables.tedarikciler)
          .select('id, ad, soyad, sirket, email, faaliyet, telefon')
          .eq('durum', 'aktif'); // Sadece aktif tedarikciler
      
      List<Map<String, dynamic>> users = [];
      
      debugPrint('🔍 _loadUsers: Tüm tedarikciler sayısı: ${allTedarikciler.length}, gerekli roller: $gerekliRoller');
      
      // Tedarikcileri users listesine ekle (faaliyet alanına göre filtrele)
      for (var tedarikci in allTedarikciler) {
        final faaliyet = tedarikci['faaliyet']?.toString().trim() ?? '';
        
        // Faaliyet alanı gerekli roller listesinde var mı kontrol et
        final bool isRoleRequired = gerekliRoller.any((rol) => 
          rol.toLowerCase() == faaliyet.toLowerCase()
        );
        
        if (!isRoleRequired) {
          continue; // Bu tedarikciyi atla
        }
        String displayName = '';
        
        // Şirket adı varsa onu kullan, yoksa ad-soyad birleştir
        if (tedarikci['sirket'] != null && tedarikci['sirket'].isNotEmpty) {
          displayName = tedarikci['sirket'];
        } else if (tedarikci['ad'] != null) {
          displayName = tedarikci['ad'];
          if (tedarikci['soyad'] != null && tedarikci['soyad'].isNotEmpty) {
            displayName += ' ${tedarikci['soyad']}';
          }
        }
        
        if (displayName.isNotEmpty) {
          // İletişim bilgisi ekle
          if (tedarikci['email'] != null && tedarikci['email'].isNotEmpty) {
            displayName += ' (${tedarikci['email']})';
          } else if (tedarikci['telefon'] != null && tedarikci['telefon'].isNotEmpty) {
            displayName += ' (${tedarikci['telefon']})';
          }
          
          // Faaliyet alanını da göster
          displayName += ' [${tedarikci['faaliyet'] ?? 'Belirtilmemiş'}]';
          
          // Tedarikci ID'sini UUID formatına dönüştür
          // UUID formatı: 8-4-4-4-12 karakterde hex değer
          final String tedarikciIdStr = tedarikci['id'].toString().padLeft(8, '0');
          final String tedarikciUuid = '00000000-0000-0000-0000-${tedarikciIdStr.padLeft(12, '0')}';
          
          users.add({
            'id': tedarikciUuid, 
            'email': displayName,
            'role': tedarikci['faaliyet'] ?? 'firma',
            'is_tedarikci': true,
            'tedarikci_id': tedarikci['id'], // Orijinal tedarikci ID'si
          });
        }
      }
      
      // Eğer tedarikcilerden kullanıcı bulunamazsa, user_roles tablosundan yedek olarak al
      if (users.isEmpty) {
        final allUserRoles = await supabase
            .from(DbTables.userRoles)
            .select('user_id, role');
        
        // user_roles'daki kullanıcıları da ekle (rol gerekliyse)
        for (var userRole in allUserRoles) {
          final userId = userRole['user_id'];
          final role = userRole['role']?.toString() ?? '';
          
          // Rol gerekli mi kontrol et
          final bool isRoleRequired = gerekliRoller.any((requiredRole) => 
            requiredRole.toLowerCase() == role.toLowerCase()
          );
          
          if (!isRoleRequired) {
            continue; // Bu rolü atla
          }
          
          // Bu kullanıcı zaten users listesinde var mı kontrol et
          final bool alreadyExists = users.any((user) => user['id'] == userId);
          
          if (!alreadyExists) {
            // Mevcut oturumdaki kullanıcının email'ini al
            final currentUser = supabase.auth.currentUser;
            String email = 'Kullanıcı ($role)';
            
            if (currentUser?.id == userId && currentUser?.email != null) {
              email = currentUser!.email!;
            } else {
              email = 'Kullanıcı ${userId.substring(0, 8)}... ($role)';
            }
            
            users.add({
              'id': userId,
              'email': email,
              'role': role,
            });
          }
        }
      }
      
      // Debug: Bulduğumuz kullanıcıları göster
      debugPrint('✅ _loadUsers: Bulduğumuz kullanıcı sayısı: ${users.length}');
      for (var user in users) {
        debugPrint('   - ${user['email']} (${user['role']})');
      }
      
      // Test kullanıcıları sadece gerçekten veri yoksa ekle
      if (users.isEmpty) {
        debugPrint('⚠️ _loadUsers: Gerçek veri bulunamadı, test verisi kullanılıyor');
        users = _createTestUsersForStage(asamaKey);
      }
      
      return users;
    } catch (e, stackTrace) {
      // Hata durumunda debug log göster
      debugPrint('❌ _loadUsers hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      // Hata durumunda aşamaya uygun test kullanıcıları döndür
      return _createTestUsersForStage(asamaKey);
    }
  }

  // Aşamaya göre test kullanıcıları oluşturur
  List<Map<String, dynamic>> _createTestUsersForStage(String asamaKey) {
    switch (asamaKey) {
      case 'orgu':
        return [
          {
            'id': 'test-orgu-1',
            'email': 'Akdeniz Örgü Tekstil Ltd. Şti.',
            'role': 'orgu_firma',
          },
          {
            'id': 'test-dokuma-1',
            'email': 'Marmara Dokuma San. ve Tic. A.Ş.',
            'role': 'dokuma_firma',
          },
        ];
      case 'konfeksiyon':
        return [
          {
            'id': 'test-konfeksiyon-1',
            'email': 'İstanbul Konfeksiyon Atölyesi',
            'role': 'konfeksiyon_firma',
          },
          {
            'id': 'test-konfeksiyon-2',
            'email': 'Ege Tekstil Konfeksiyon Ltd.',
            'role': 'konfeksiyon_firma',
          },
        ];
      case 'nakis':
        return [
          {
            'id': 'test-nakis-1',
            'email': 'Sanat Nakış Atölyesi',
            'role': 'nakis_firma',
          },
          {
            'id': 'test-nakis-2',
            'email': 'Bursa Nakış ve Süsleme Ltd.',
            'role': 'nakis_firma',
          },
        ];
      case 'yikama':
        return [
          {
            'id': 'test-yikama-1',
            'email': 'Temiz Yıkama Fabrikası',
            'role': 'yikama_firma',
          },
          {
            'id': 'test-yikama-2',
            'email': 'Karadeniz Tekstil Yıkama A.Ş.',
            'role': 'yikama_firma',
          },
        ];
      case 'ilik_dugme':
        return [
          {
            'id': 'test-ilik-1',
            'email': 'Düğme Dünyası San. Tic. Ltd.',
            'role': 'ilik_dugme_firma',
          },
          {
            'id': 'test-ilik-2',
            'email': 'Aksesuvar Plus İlik Düğme',
            'role': 'ilik_dugme_firma',
          },
        ];
      case 'utu':
        return [
          {
            'id': 'test-utu-1',
            'email': 'Profesyonel Ütü Hizmetleri',
            'role': 'utu_firma',
          },
          {
            'id': 'test-utu-2',
            'email': 'Ankara Ütü ve Paketleme A.Ş.',
            'role': 'utu_firma',
          },
        ];
      default:
        return [
          {
            'id': 'test-genel-1',
            'email': 'Genel Tekstil Firması Ltd.',
            'role': 'firma',
          },
        ];
    }
  }

  // Aşamaya göre gerekli rolleri döndürür
  List<String> _getRequiredRolesForStage(String asamaKey) {
    switch (asamaKey) {
      case 'orgu':
        return ['Örgü', 'Dokuma', 'orgu_firma', 'dokuma_firma'];
      case 'konfeksiyon':
        return ['Konfeksiyon', 'konfeksiyon_firma'];
      case 'nakis':
        return ['Nakış', 'nakis_firma'];
      case 'yikama':
        return ['Yıkama', 'yikama_firma'];
      case 'ilik_dugme':
        return ['İlik Düğme', 'Düğme', 'ilik_dugme_firma'];
      case 'utu':
        return ['Ütü', 'Pres', 'utu_firma', 'ütü paket'];
      default:
        return ['firma']; // Genel firma rolü
    }
  }

  Future<void> _atamaYap(String asamaKey, String kullaniciId, int adet, {Map<String, dynamic>? userInfo}) async {
    if (adet <= 0) {
      context.showErrorSnackBar('Geçerli bir adet giriniz');
      return;
    }
    
    try {
      final String tableName = utils.getTableNameForStage(asamaKey);
      
      // Mevcut atama kontrolü - aynı model için herhangi bir atama var mı?
      final mevcutAtama = await supabase
          .from(tableName)
          .select('id, durum, tedarikci_id, tamamlanan_adet, talep_edilen_adet')
          .eq('model_id', widget.modelId)
          .maybeSingle();

      if (mevcutAtama != null) {
        // Mevcut atama var - kullanıcıya sor
        final bool isTamamlandi = mevcutAtama['durum'] == 'tamamlandi';
        final int mevcutTamamlanan = mevcutAtama['tamamlanan_adet'] ?? 0;
        final int mevcutTalep = mevcutAtama['talep_edilen_adet'] ?? 0;
        final int yeniToplam = isTamamlandi ? (mevcutTalep + adet) : adet;
        
        if (!mounted) return;
        final devamEt = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isTamamlandi ? Colors.blue.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isTamamlandi ? Icons.add_circle_outline : Icons.warning_amber_rounded, 
                    color: isTamamlandi ? Colors.blue.shade600 : Colors.orange.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(isTamamlandi ? 'Ek Atama Yap' : 'Mevcut Atama Var'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isTamamlandi 
                  ? 'Bu model için önceki atama tamamlanmış. Ek atama yapmak ister misiniz?'
                  : 'Bu model için zaten aktif bir atama bulunuyor.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mevcut Durum: ${mevcutAtama['durum']}'),
                      Text('Mevcut Talep: $mevcutTalep adet'),
                      Text('Tamamlanan: $mevcutTamamlanan adet'),
                      if (isTamamlandi) ...[
                        const Divider(),
                        Text('Eklenen: $adet adet', style: const TextStyle(color: Colors.blue)),
                        Text('Yeni Toplam: $yeniToplam adet', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(isTamamlandi 
                  ? 'Mevcut adete $adet adet eklenecek ve üretim devam edecek.'
                  : 'Mevcut atamayı güncellemek ister misiniz?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTamamlandi ? Colors.blue : Colors.orange,
                ),
                child: Text(isTamamlandi ? 'Ek Atama Yap' : 'Güncelle'),
              ),
            ],
          ),
        );

        if (devamEt == true) {
          // Mevcut atamayı güncelle
          final Map<String, dynamic> updateData = {
            'durum': 'atandi',
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          // Tamamlanmış atamaya ek yapılıyorsa mevcut adete ekle, tamamlanan_adet korunsun
          if (isTamamlandi) {
            updateData['adet'] = yeniToplam;
            updateData['talep_edilen_adet'] = yeniToplam;
            // tamamlanan_adet değişmez - kaldığı yerden devam eder
          } else {
            updateData['adet'] = adet;
            updateData['talep_edilen_adet'] = adet;
          }
          
          // Tedarikci bilgisi varsa ekle (try-catch ile güvenli)
          if (userInfo != null && userInfo['is_tedarikci'] == true && userInfo['tedarikci_id'] != null) {
            try {
              updateData['tedarikci_id'] = userInfo['tedarikci_id'];
            } catch (e) {
              // tedarikci_id eklenemedi
            }
          }
          
          try {
            await supabase.from(tableName).update(updateData).eq('id', mevcutAtama['id']);
          } catch (e) {
            // tedarikci_id hatası varsa onu çıkarıp tekrar dene
            if (e.toString().contains('tedarikci_id')) {
              updateData.remove('tedarikci_id');
              await supabase.from(tableName).update(updateData).eq('id', mevcutAtama['id']);
            } else {
              rethrow;
            }
          }

          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTamamlandi 
                ? '✅ ${utils.getAsamaDisplayName(asamaKey)} - $adet adet eklendi (Toplam: $yeniToplam adet)'
                : '✅ ${utils.getAsamaDisplayName(asamaKey)} ataması güncellendi ($adet adet)'),
              backgroundColor: Colors.green,
            ),
          );
          await _atamaKayitlariniGetir();
          return;
        } else {
          return; // İptal edildi
        }
      }
      
      final Map<String, dynamic> insertData = {
        'model_id': widget.modelId,
        'adet': adet,
        'talep_edilen_adet': adet,
        'tamamlanan_adet': 0,
        'durum': 'atandi',
        'created_at': DateTime.now().toIso8601String(),
        'firma_id': TenantManager.instance.requireFirmaId,
      };
      
      // UUID formatı kontrolü - test kullanıcıları için geçersiz UUID'ler var
      final bool isValidUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(kullaniciId);
      
      // Eğer tedarikci seçildiyse, tedarikci_id alanına yaz
      if (userInfo != null && userInfo['is_tedarikci'] == true) {
        insertData['tedarikci_id'] = userInfo['tedarikci_id'];
        // atanan_kullanici_id ekleme - null olarak bırak
      } else if (isValidUuid) {
        // Sadece geçerli UUID ise atanan_kullanici_id'ye yaz
        insertData['atanan_kullanici_id'] = kullaniciId;
      }
      // Geçersiz UUID (test kullanıcısı) - hiçbir ID alanı ekleme
      
      try {
        await supabase.from(tableName).insert(insertData);
      } catch (e) {
        // tedarikci_id veya atanan_kullanici_id sütunu yoksa bunları çıkarıp tekrar dene
        if (e.toString().contains('tedarikci_id') || e.toString().contains('atanan_kullanici_id')) {
          insertData.remove('tedarikci_id');
          insertData.remove('atanan_kullanici_id');
          await supabase.from(tableName).insert(insertData);
        } else {
          rethrow;
        }
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      
      context.showSuccessSnackBar('✅ ${utils.getAsamaDisplayName(asamaKey)} ataması başarıyla yapıldı ($adet adet)');
      
      await _atamaKayitlariniGetir();
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      context.showErrorSnackBar('Hata: $e');
    }
  }

  Future<void> _atamaKabulEt(Map<String, dynamic> atama, String asamaKey) async {
    try {
      final atamaId = atama['id'];
      final String tableName = utils.getTableNameForStage(asamaKey);
      
      // Admin kabul ederse doğrudan üretime al
      // Tedarikçi kabul ederse 'onaylandi' olsun, sonra üretime başlasın
      final yeniDurum = kullaniciRolu == 'admin' ? 'uretimde' : 'onaylandi';
      
      await supabase
          .from(tableName)
          .update({
            'durum': yeniDurum,
            'onay_tarihi': DateTime.now().toIso8601String(),
            'uretim_baslangic_tarihi': yeniDurum == 'uretimde' ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', atamaId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(yeniDurum == 'uretimde' 
            ? '✅ Atama başarıyla kabul edildi - Üretime alındı'
            : '✅ Atama kabul edildi - Onay bekliyor'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _atamaKayitlariniGetir();
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }

  void _showTamamlamaDialog(Map<String, dynamic> atama, String asamaKey) {
    final tamamlananController = TextEditingController();
    final talepEdilenAdet = atama['adet'] ?? atama['talep_edilen_adet'] ?? 0;
    final mevcutTamamlanan = atama['tamamlanan_adet'] ?? 0;
    final kalanAdet = talepEdilenAdet - mevcutTamamlanan;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$asamaKey Aşaması - Adet Tamamlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Talep Edilen: $talepEdilenAdet'),
            Text('Mevcut Tamamlanan: $mevcutTamamlanan'),
            Text('Kalan: $kalanAdet'),
            const SizedBox(height: 16),
            TextFormField(
              controller: tamamlananController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Bu İşlemde Tamamlanan Adet',
                border: const OutlineInputBorder(),
                helperText: 'Maksimum: $kalanAdet',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => _tamamlamayiKaydet(
              atama, 
              asamaKey, 
              int.tryParse(tamamlananController.text) ?? 0,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _tamamlamayiKaydet(Map<String, dynamic> atama, String asamaKey, int yeniTamamlananAdet) async {
    if (yeniTamamlananAdet <= 0) {
      Navigator.pop(context);
      context.showErrorSnackBar('Geçerli bir adet giriniz');
      return;
    }
    
    try {
      final atamaId = atama['id'];
      final String tableName = utils.getTableNameForStage(asamaKey);
      
      final mevcutTamamlanan = atama['tamamlanan_adet'] ?? 0;
      final yeniToplamTamamlanan = mevcutTamamlanan + yeniTamamlananAdet;
      final talepEdilenAdet = atama['adet'] ?? atama['talep_edilen_adet'] ?? 0;
      
      if (yeniToplamTamamlanan > talepEdilenAdet) {
        Navigator.pop(context);
        context.showErrorSnackBar('Tamamlanan adet talep edilenden fazla olamaz');
        return;
      }
      
      String yeniDurum = 'uretimde';
      bool modelTamamlandi = false;
      
      if (yeniToplamTamamlanan >= talepEdilenAdet) {
        yeniDurum = 'tamamlandi';
        modelTamamlandi = true;
      }
      
      await supabase
          .from(tableName)
          .update({
            'tamamlanan_adet': yeniToplamTamamlanan,
            'durum': yeniDurum,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', atamaId);
      
      // ✅ MODEL TAMAMLANDIĞINDA MALİYET HESAPLA VE RAPORLA ENTEGRE ET
      if (modelTamamlandi) {
        final maliyetServisi = ModelMaliyetHesaplamaServisi();
        final maliyetBilgisi = await maliyetServisi.modelTamamlandiMaliyetiHesapla(
          modelId: widget.modelId,
          tamamlananAdet: yeniToplamTamamlanan,
        );

        if (maliyetBilgisi != null) {
          debugPrint('💰 Model Maliyet Raporu:');
          debugPrint('   - Toplam Maliyet: ₺${maliyetBilgisi['toplam_maliyet']?.toStringAsFixed(2) ?? '0.00'}');
          debugPrint('   - Satış Geliri: ₺${maliyetBilgisi['toplam_satis_geliri']?.toStringAsFixed(2) ?? '0.00'}');
          debugPrint('   - Kar/Zarar: ₺${maliyetBilgisi['toplam_kar_zarar']?.toStringAsFixed(2) ?? '0.00'}');
        }
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ +$yeniTamamlananAdet adet tamamlandı (Toplam: $yeniToplamTamamlanan)${modelTamamlandi ? '\n💰 Maliyet raporu oluşturuldu!' : ''}'),
          backgroundColor: modelTamamlandi ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
      
      await _atamaKayitlariniGetir();
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      context.showErrorSnackBar('Hata: $e');
    }
  }
}
