import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/tedarikci_model.dart';
import 'package:uretim_takip/services/tedarikci_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/supabase_config.dart';

class TedarikciEklePage extends StatefulWidget {
  final TedarikciModel? tedarikci; // Düzenleme için

  const TedarikciEklePage({Key? key, this.tedarikci}) : super(key: key);

  @override
  State<TedarikciEklePage> createState() => _TedarikciEklePageState();
}

class _TedarikciEklePageState extends State<TedarikciEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _sirketController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _parolaController = TextEditingController();
  final _tedarikciTipiController = TextEditingController();
  final _faaliyetController = TextEditingController();
  final _durumController = TextEditingController();
  final _vergiNoController = TextEditingController();
  final _ibanNoController = TextEditingController();

  bool _yukleniyor = false;
  bool _parolaGoster = false;
  bool _kullaniciOlustur = true; // Varsayılan olarak kullanıcı oluşturulsun

  bool get _duzenlemeModunda => widget.tedarikci != null;

  @override
  void initState() {
    super.initState();
    if (_duzenlemeModunda) {
      _formVeriDoldur();
    } else {
      // Varsayılan değerler
      _tedarikciTipiController.text = 'Üretici';
      _durumController.text = 'aktif';
    }
  }

  void _formVeriDoldur() {
    final tedarikci = widget.tedarikci!;
    _adController.text = tedarikci.ad;
    _soyadController.text = tedarikci.soyad ?? '';
    _sirketController.text = tedarikci.sirket ?? '';
    _telefonController.text = tedarikci.telefon;
    _emailController.text = tedarikci.email ?? '';
    _tedarikciTipiController.text = tedarikci.tedarikciTipi;
    _faaliyetController.text = tedarikci.faaliyet ?? '';
    _durumController.text = tedarikci.durum;
    _vergiNoController.text = tedarikci.vergiNo ?? '';
    _ibanNoController.text = tedarikci.ibanNo ?? '';
  }

  Future<void> _tedarikciKaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _yukleniyor = true;
    });

    try {
      final email = _emailController.text.trim();
      final parola = _parolaController.text.trim();
      
      // Yeni tedarikci eklerken ve kullanıcı oluşturma seçiliyse
      String? createdUserId;
      if (!_duzenlemeModunda && _kullaniciOlustur && email.isNotEmpty && parola.isNotEmpty) {
        // 1. Önce Supabase Auth'ta kullanıcı oluştur
        try {
          final authResponse = await Supabase.instance.client.auth.admin.createUser(
            AdminUserAttributes(
              email: email,
              password: parola,
              emailConfirm: true, // Email onaysız giriş yapabilsin
            ),
          );
          
          if (authResponse.user != null) {
            createdUserId = authResponse.user!.id;
            debugPrint('✅ Kullanıcı oluşturuldu: $createdUserId');
          }
        } catch (authError) {
          // Admin API çalışmazsa normal signUp dene
          debugPrint('⚠️ Admin API hatası, normal signUp deneniyor: $authError');
          try {
            final signUpResponse = await Supabase.instance.client.auth.signUp(
              email: email,
              password: parola,
            );
            createdUserId = signUpResponse.user?.id;
            debugPrint('✅ Kullanıcı signUp ile oluşturuldu');
          } catch (signUpError) {
            debugPrint('⚠️ SignUp hatası: $signUpError');
            // Kullanıcı zaten varsa devam et
            if (!signUpError.toString().contains('already registered')) {
              rethrow;
            }
          }
        }

        // 2. Kullanıcıyı firma_kullanicilari ve user_roles'a ekle
        if (createdUserId != null) {
          final adminClient = SupabaseConfig.adminClient;
          try {
            // firma_kullanicilari tablosuna ekle (adminClient ile RLS bypass)
            final firmaId = TenantManager.instance.firmaId;
            if (firmaId != null) {
              await adminClient.from(DbTables.firmaKullanicilari).upsert({
                'firma_id': firmaId,
                'user_id': createdUserId,
                'rol': 'kullanici',
                'aktif': true,
              }, onConflict: 'firma_id,user_id');
              debugPrint('✅ Tedarikci firmaya eklendi: $firmaId');
            }
          } catch (e) {
            debugPrint('⚠️ firma_kullanicilari ekleme hatası: $e');
          }

          try {
            // user_roles tablosuna ekle (adminClient ile RLS bypass)
            await adminClient.from(DbTables.userRoles).upsert({
              'user_id': createdUserId,
              'role': 'diger',
              'aktif': true,
            }, onConflict: 'user_id');
            debugPrint('✅ Tedarikci rolü eklendi');
          } catch (e) {
            debugPrint('⚠️ user_roles ekleme hatası: $e');
          }
        }
      }

      // 2. Tedarikci verilerini hazırla
      final tedarikciVerileri = <String, dynamic>{
        'ad': _adController.text.trim(),
        'soyad': _soyadController.text.trim().isEmpty ? null : _soyadController.text.trim(),
        'sirket': _sirketController.text.trim().isEmpty ? null : _sirketController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'email': email.isEmpty ? null : email,
        'tedarikci_tipi': _tedarikciTipiController.text.trim().isEmpty ? 'Üretici' : _tedarikciTipiController.text.trim(),
        'faaliyet': _faaliyetController.text.trim().isEmpty ? null : _faaliyetController.text.trim(),
        'durum': _durumController.text.trim().isEmpty ? 'aktif' : _durumController.text.trim(),
        'vergi_no': _vergiNoController.text.trim().isEmpty ? null : _vergiNoController.text.trim(),
        'iban_no': _ibanNoController.text.trim().isEmpty ? null : _ibanNoController.text.trim(),
      };

      // 3. Tedarikci kaydı oluştur/güncelle
      if (_duzenlemeModunda) {
        await TedarikciService.tedarikciGuncelle(widget.tedarikci!.id!, tedarikciVerileri);
      } else {
        await TedarikciService.tedarikciEkle(tedarikciVerileri);
      }

      if (mounted) {
        String mesaj = _duzenlemeModunda 
            ? 'Tedarikçi başarıyla güncellendi' 
            : 'Tedarikçi başarıyla eklendi';
        
        if (!_duzenlemeModunda && _kullaniciOlustur && email.isNotEmpty && parola.isNotEmpty) {
          mesaj += '\n✅ Kullanıcı hesabı oluşturuldu. Tedarikçi artık giriş yapabilir.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mesaj),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Hata: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      appBar: AppBar(
        title: Text(_duzenlemeModunda ? 'Tedarikçi Düzenle' : 'Yeni Tedarikçi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_yukleniyor)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _tedarikciKaydet,
              icon: Icon(_duzenlemeModunda ? Icons.update : Icons.save),
              label: Text(_duzenlemeModunda ? 'Güncelle' : 'Kaydet'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // Temel Bilgiler Kartı
              _buildSectionCard(
                title: 'Temel Bilgiler',
                icon: Icons.person,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _adController,
                          label: 'Ad',
                          isRequired: true,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ad gerekli';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _soyadController,
                          label: 'Soyad',
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  
                  _buildTextFormField(
                    controller: _sirketController,
                    label: 'Şirket/Firma Adı',
                    prefixIcon: Icons.business,
                  ),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _telefonController,
                          label: 'Telefon',
                          isRequired: true,
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Telefon gerekli';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _emailController,
                          label: 'E-posta',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (_kullaniciOlustur && !_duzenlemeModunda) {
                              if (value == null || value.isEmpty) {
                                return 'Kullanıcı oluşturmak için e-posta gerekli';
                              }
                            }
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Geçerli bir e-posta adresi girin';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Kullanıcı Hesabı Bölümü (Sadece yeni eklemede)
                  if (!_duzenlemeModunda) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_circle, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Kullanıcı Hesabı',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _kullaniciOlustur,
                                onChanged: (value) {
                                  setState(() {
                                    _kullaniciOlustur = value;
                                  });
                                },
                                activeThumbColor: Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _kullaniciOlustur 
                                ? 'Tedarikçi için giriş yapabilir kullanıcı hesabı oluşturulacak.'
                                : 'Kullanıcı hesabı oluşturulmayacak.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          if (_kullaniciOlustur) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _parolaController,
                              obscureText: !_parolaGoster,
                              decoration: InputDecoration(
                                labelText: 'Parola',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_parolaGoster ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _parolaGoster = !_parolaGoster;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                helperText: 'En az 6 karakter',
                              ),
                              validator: (value) {
                                if (_kullaniciOlustur) {
                                  if (value == null || value.isEmpty) {
                                    return 'Parola gerekli';
                                  }
                                  if (value.length < 6) {
                                    return 'Parola en az 6 karakter olmalı';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 20),
              
              // İş Bilgileri Kartı
              _buildSectionCard(
                title: 'İş Bilgileri',
                icon: Icons.work,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          controller: _tedarikciTipiController,
                          label: 'Tedarikçi Türü',
                          isRequired: true,
                          prefixIcon: Icons.category,
                          items: ['Üretici', 'İthalatçı', 'Distribütör', 'Bayi', 'Hizmet Sağlayıcı', 'İplik Firması', 'Aksesuar Firması', 'Diğer'],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tedarikçi türü gerekli';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          controller: _faaliyetController,
                          label: 'Faaliyet Alanı',
                          prefixIcon: Icons.business_center,
                          items: ['Tekstil', 'İplik', 'Örgü', 'Dokuma', 'Konfeksiyon', 'Nakış', 'Ütü Paket', 'Yıkama', 'İlik Düğme', 'Aksesuar', 'Makine', 'Kimyasal', 'Ambalaj', 'Lojistik', 'Diğer'],
                        ),
                      ),
                    ],
                  ),
                  
                  _buildDropdownField(
                    controller: _durumController,
                    label: 'Durum',
                    isRequired: true,
                    prefixIcon: Icons.toggle_on,
                    items: ['aktif', 'pasif', 'beklemede'],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Durum gerekli';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Mali Bilgiler Kartı
              _buildSectionCard(
                title: 'Mali Bilgiler',
                icon: Icons.account_balance,
                children: [
                  _buildTextFormField(
                    controller: _vergiNoController,
                    label: 'Vergi Numarası',
                    prefixIcon: Icons.receipt,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  
                  _buildTextFormField(
                    controller: _ibanNoController,
                    label: 'IBAN Numarası',
                    prefixIcon: Icons.account_balance_wallet,
                    hintText: 'TR33 0006 1005 1978 6457 8413 26',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\s]')),
                      LengthLimitingTextInputFormatter(34),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Alt İptal butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _yukleniyor ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text(
                    'İptal',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bölüm kartı widget'ı
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Geliştirilmiş text form field
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isRequired = false,
    String? hintText,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(
            color: isRequired ? Colors.red.shade700 : Colors.grey.shade700,
            fontWeight: isRequired ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
      ),
    );
  }

  // Dropdown field widget'ı
  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(
            color: isRequired ? Colors.red.shade700 : Colors.grey.shade700,
            fontWeight: isRequired ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            controller.text = newValue ?? '';
          });
        },
        validator: validator,
      ),
    );
  }

  // Alt butonlar

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _sirketController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _tedarikciTipiController.dispose();
    _faaliyetController.dispose();
    _durumController.dispose();
    _vergiNoController.dispose();
    _ibanNoController.dispose();
    super.dispose();
  }
}
