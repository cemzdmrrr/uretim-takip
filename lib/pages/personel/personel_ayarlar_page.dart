import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/services/supabase_service.dart';

class PersonelAyarlarPage extends StatefulWidget {
  const PersonelAyarlarPage({Key? key}) : super(key: key);

  @override
  State<PersonelAyarlarPage> createState() => _PersonelAyarlarPageState();
}

class _PersonelAyarlarPageState extends State<PersonelAyarlarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _formKey = GlobalKey<FormState>();

  // Şirket Bilgileri
  final _sirketAdiController = TextEditingController();
  final _vergiNumarasiController = TextEditingController();
  final _ticSicilNoController = TextEditingController();
  final _adresController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bankaAdiController = TextEditingController();
  final _yetkiliBilgiController = TextEditingController();

  // SGK & Vergi Ayarları
  final _sgkIsverenOranController = TextEditingController();
  final _sgkIsciOranController = TextEditingController();
  final _issizlikIsverenController = TextEditingController();
  final _issizlikIsciController = TextEditingController();
  final _gelirVergisiMinController = TextEditingController();
  final _gelirVergisiMaxController = TextEditingController();
  final _damgaVergisiOranController = TextEditingController();
  final _asgariUcretController = TextEditingController();

  // Bordro Ayarları
  final _yemekYardimController = TextEditingController();
  final _yolYardimController = TextEditingController();
  final _cocukYardimController = TextEditingController();
  final _egitimYardimController = TextEditingController();
  final _irsaliyeVardiyaController = TextEditingController();
  final _fazlaMesaiFizikselController = TextEditingController();
  final _fazlaMesaiZihinselController = TextEditingController();

  // Çalışma Ayarları
  final _gunlukCalismaSaatiController = TextEditingController();
  final _haftalikCalismaSaatiController = TextEditingController();
  final _aylikCalismaSaatiController = TextEditingController();
  final _mesaiUcretKatsayiController = TextEditingController();
  final _gece2230_0600Controller = TextEditingController();
  final _pazarTatilController = TextEditingController();
  final _resmiTatilController = TextEditingController();

  // İzin Ayarları
  final _yillikIzinController = TextEditingController();
  final _hastalikIzinController = TextEditingController();
  final _dogumIzinController = TextEditingController();
  final _babalikIzinController = TextEditingController();
  final _evlilikIzinController = TextEditingController();
  final _olumIzinController = TextEditingController();
  final _askerlikIzinController = TextEditingController();
  final _mazeretIzinController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all controllers
    _sirketAdiController.dispose();
    _vergiNumarasiController.dispose();
    _ticSicilNoController.dispose();
    _adresController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _ibanController.dispose();
    _bankaAdiController.dispose();
    _yetkiliBilgiController.dispose();
    _sgkIsverenOranController.dispose();
    _sgkIsciOranController.dispose();
    _issizlikIsverenController.dispose();
    _issizlikIsciController.dispose();
    _gelirVergisiMinController.dispose();
    _gelirVergisiMaxController.dispose();
    _damgaVergisiOranController.dispose();
    _asgariUcretController.dispose();
    _yemekYardimController.dispose();
    _yolYardimController.dispose();
    _cocukYardimController.dispose();
    _egitimYardimController.dispose();
    _irsaliyeVardiyaController.dispose();
    _fazlaMesaiFizikselController.dispose();
    _fazlaMesaiZihinselController.dispose();
    _gunlukCalismaSaatiController.dispose();
    _haftalikCalismaSaatiController.dispose();
    _aylikCalismaSaatiController.dispose();
    _mesaiUcretKatsayiController.dispose();
    _gece2230_0600Controller.dispose();
    _pazarTatilController.dispose();
    _resmiTatilController.dispose();
    _yillikIzinController.dispose();
    _hastalikIzinController.dispose();
    _dogumIzinController.dispose();
    _babalikIzinController.dispose();
    _evlilikIzinController.dispose();
    _olumIzinController.dispose();
    _askerlikIzinController.dispose();
    _mazeretIzinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Şirket bilgilerini yükle
      final companyData = await SupabaseService.getCompanySettings();
      if (companyData != null) {
        _sirketAdiController.text = companyData['unvan'] ?? '';
        _vergiNumarasiController.text = companyData['vergi_no'] ?? '';
        _ticSicilNoController.text = companyData['sicil_no'] ?? '';
        _adresController.text = companyData['adres'] ?? '';
        _telefonController.text = companyData['telefon'] ?? '';
        _emailController.text = companyData['email'] ?? '';
        _ibanController.text = companyData['iban'] ?? '';
        _bankaAdiController.text = companyData['banka'] ?? '';
        _yetkiliBilgiController.text = companyData['yetkili'] ?? '';
      }

      // Sistem ayarlarını yükle
      final systemData = await SupabaseService.getSystemSettings();
      if (systemData.isNotEmpty) {
        _sgkIsverenOranController.text =
            systemData['sgk_isveren_prim_orani'] ?? '20.5';
        _sgkIsciOranController.text =
            systemData['sgk_isci_prim_orani'] ?? '14.0';
        _issizlikIsverenController.text =
            systemData['issizlik_isveren_prim_orani'] ?? '2.0';
        _issizlikIsciController.text =
            systemData['issizlik_isci_prim_orani'] ?? '1.0';
        _gelirVergisiMinController.text = '15.0'; // Sabit değer
        _gelirVergisiMaxController.text = '40.0'; // Sabit değer
        _damgaVergisiOranController.text =
            systemData['damga_vergisi_orani'] ?? '0.759';
        _asgariUcretController.text = systemData['asgari_ucret'] ?? '17002.0';

        // Bordro ayarları
        _yemekYardimController.text = systemData['yemek_yardim'] ?? '0';
        _yolYardimController.text = systemData['yol_yardim'] ?? '0';
        _cocukYardimController.text = systemData['cocuk_yardim'] ?? '0';
        _egitimYardimController.text = systemData['egitim_yardim'] ?? '0';
        _irsaliyeVardiyaController.text = systemData['irsaliye_vardiya'] ?? '0';
        _fazlaMesaiFizikselController.text =
            systemData['mesai_carpani'] ?? '1.5';
        _fazlaMesaiZihinselController.text =
            systemData['mesai_carpani'] ?? '1.5';

        // Çalışma ayarları
        _gunlukCalismaSaatiController.text =
            systemData['gunluk_calisma_saati'] ?? '8';
        _haftalikCalismaSaatiController.text =
            systemData['haftalik_calisma_saati'] ?? '45';
        _aylikCalismaSaatiController.text =
            systemData['aylik_calisma_saati'] ?? '180';
        _mesaiUcretKatsayiController.text =
            systemData['mesai_carpani'] ?? '1.5';
        _gece2230_0600Controller.text =
            systemData['gece_vardiya_carpani'] ?? '1.25';
        _pazarTatilController.text = systemData['pazar_carpani'] ?? '1.5';
        _resmiTatilController.text = systemData['bayram_carpani'] ?? '2.0';

        // İzin ayarları
        _yillikIzinController.text = systemData['yillik_izin_gunu'] ?? '14';
        _hastalikIzinController.text = systemData['hastalik_izin'] ?? '18';
        _dogumIzinController.text = systemData['dogum_izin'] ?? '112';
        _babalikIzinController.text = systemData['babalik_izin'] ?? '5';
        _evlilikIzinController.text = systemData['evlilik_izin'] ?? '3';
        _olumIzinController.text = systemData['olum_izin'] ?? '3';
        _askerlikIzinController.text = systemData['askerlik_izin'] ?? '0';
        _mazeretIzinController.text = systemData['mazeret_izin'] ?? '0';
      }
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Ayarlar yüklenirken hata: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Şirket bilgilerini kaydet
      final companyData = {
        'sirket_adi': _sirketAdiController.text,
        'vergi_numarasi': _vergiNumarasiController.text,
        'ticaret_sicil_no': _ticSicilNoController.text,
        'adres': _adresController.text,
        'telefon': _telefonController.text,
        'email': _emailController.text,
        'iban': _ibanController.text,
        'banka_adi': _bankaAdiController.text,
        'yetkili_bilgi': _yetkiliBilgiController.text,
        'vergi_dairesi': 'Belirtilmemiş',
        'sgk_sicil_no': '',
        'faaliyet': 'Genel',
        'kurulus_yili': '2024',
        'web': '',
      };

      // Sistem ayarlarını kaydet
      final systemData = {
        'sgk_isveren_prim_orani': _sgkIsverenOranController.text,
        'sgk_isci_prim_orani': _sgkIsciOranController.text,
        'issizlik_isveren_prim_orani': _issizlikIsverenController.text,
        'issizlik_isci_prim_orani': _issizlikIsciController.text,
        'damga_vergisi_orani': _damgaVergisiOranController.text,
        'asgari_ucret': _asgariUcretController.text,
        'yemek_yardim': _yemekYardimController.text,
        'yol_yardim': _yolYardimController.text,
        'cocuk_yardim': _cocukYardimController.text,
        'egitim_yardim': _egitimYardimController.text,
        'irsaliye_vardiya': _irsaliyeVardiyaController.text,
        'mesai_carpani': _fazlaMesaiFizikselController.text,
        'gunluk_calisma_saati': _gunlukCalismaSaatiController.text,
        'haftalik_calisma_saati': _haftalikCalismaSaatiController.text,
        'aylik_calisma_saati': _aylikCalismaSaatiController.text,
        'gece_vardiya_carpani': _gece2230_0600Controller.text,
        'pazar_carpani': _pazarTatilController.text,
        'bayram_carpani': _resmiTatilController.text,
        'yillik_izin_gunu': _yillikIzinController.text,
        'hastalik_izin': _hastalikIzinController.text,
        'dogum_izin': _dogumIzinController.text,
        'babalik_izin': _babalikIzinController.text,
        'evlilik_izin': _evlilikIzinController.text,
        'olum_izin': _olumIzinController.text,
        'askerlik_izin': _askerlikIzinController.text,
        'mazeret_izin': _mazeretIzinController.text,
      };

      final companySuccess =
          await SupabaseService.saveCompanySettings(companyData);
      final systemSuccess =
          await SupabaseService.saveSystemSettings(systemData);

      if (companySuccess && systemSuccess) {
        if (!mounted) return;
        context.showSuccessSnackBar('Ayarlar başarıyla kaydedildi');
      } else {
        if (!mounted) return;
        context.showErrorSnackBar('Ayarlar kaydedilirken hata oluştu');
      }
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text(
          'Personel Ayarları',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _saveSettings,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Kaydet'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F3D91), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x262563EB),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderText(),
                              const SizedBox(height: 12),
                              _buildHeaderMetrics()
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(flex: 3, child: _buildHeaderText()),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildHeaderMetrics()),
                            ],
                          ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF475569),
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tabs: const [
                        Tab(text: 'Şirket'),
                        Tab(text: 'SGK ve Vergi'),
                        Tab(text: 'Bordro'),
                        Tab(text: 'Çalışma'),
                        Tab(text: 'İzin'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCompanyTab(),
                        _buildTaxTab(),
                        _buildPayrollTab(),
                        _buildWorkingTab(),
                        _buildLeaveTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personel sistem ayarları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Şirket bilgileri, SGK oranları, bordro parametreleri ve izin kuralları bu ekranda yönetilir.',
          style: TextStyle(
            color: Color(0xFFDCE7FF),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniMetric(label: 'Sekme', value: '5'),
          _MiniMetric(label: 'Alan', value: '30+'),
          _MiniMetric(label: 'Kapsam', value: 'Bordro • SGK • İzin'),
        ],
      ),
    );
  }

  Widget _buildCompanyTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          _buildCard(
            'Şirket Bilgileri',
            [
              _buildTextField(
                controller: _sirketAdiController,
                label: 'Şirket Adı',
                icon: Icons.business,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Şirket adı gerekli' : null,
              ),
              _buildTextField(
                controller: _vergiNumarasiController,
                label: 'Vergi Numarası',
                icon: Icons.receipt_long,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vergi numarası gerekli' : null,
              ),
              _buildTextField(
                controller: _ticSicilNoController,
                label: 'Ticaret Sicil No',
                icon: Icons.assignment,
              ),
              _buildTextField(
                controller: _adresController,
                label: 'Adres',
                icon: Icons.location_on,
                maxLines: 3,
              ),
              _buildTextField(
                controller: _telefonController,
                label: 'Telefon',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'E-mail',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Banka Bilgileri',
            [
              _buildTextField(
                controller: _ibanController,
                label: 'IBAN',
                icon: Icons.account_balance,
              ),
              _buildTextField(
                controller: _bankaAdiController,
                label: 'Banka Adı',
                icon: Icons.account_balance,
              ),
              _buildTextField(
                controller: _yetkiliBilgiController,
                label: 'Yetkili Bilgi',
                icon: Icons.person,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaxTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          _buildCard(
            'SGK Primleri (%)',
            [
              _buildTextField(
                controller: _sgkIsverenOranController,
                label: 'SGK İşveren Oranı',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                suffixText: '%',
              ),
              _buildTextField(
                controller: _sgkIsciOranController,
                label: 'SGK İşçi Oranı',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                suffixText: '%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'İşsizlik Sigortası (%)',
            [
              _buildTextField(
                controller: _issizlikIsverenController,
                label: 'İşsizlik İşveren',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                suffixText: '%',
              ),
              _buildTextField(
                controller: _issizlikIsciController,
                label: 'İşsizlik İşçi',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                suffixText: '%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Vergi Oranları',
            [
              _buildTextField(
                controller: _gelirVergisiMinController,
                label: 'Gelir Vergisi Min',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                suffixText: '%',
              ),
              _buildTextField(
                controller: _gelirVergisiMaxController,
                label: 'Gelir Vergisi Max',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                suffixText: '%',
              ),
              _buildTextField(
                controller: _damgaVergisiOranController,
                label: 'Damga Vergisi',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                suffixText: '%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Asgari Ücret',
            [
              _buildTextField(
                controller: _asgariUcretController,
                label: 'Asgari Ücret (2024)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                suffixText: '₺',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          _buildCard(
            'Yardımlar (₺)',
            [
              _buildTextField(
                controller: _yemekYardimController,
                label: 'Yemek Yardımı',
                icon: Icons.restaurant,
                keyboardType: TextInputType.number,
                suffixText: '₺',
              ),
              _buildTextField(
                controller: _yolYardimController,
                label: 'Yol Yardımı',
                icon: Icons.directions_car,
                keyboardType: TextInputType.number,
                suffixText: '₺',
              ),
              _buildTextField(
                controller: _cocukYardimController,
                label: 'Çocuk Yardımı',
                icon: Icons.child_care,
                keyboardType: TextInputType.number,
                suffixText: '₺',
              ),
              _buildTextField(
                controller: _egitimYardimController,
                label: 'Eğitim Yardımı',
                icon: Icons.school,
                keyboardType: TextInputType.number,
                suffixText: '₺',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Ek Ödemeler',
            [
              _buildTextField(
                controller: _irsaliyeVardiyaController,
                label: 'İrsaliye/Vardiya Primi',
                icon: Icons.receipt,
                keyboardType: TextInputType.number,
                suffixText: '₺',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Fazla Mesai Çarpanları',
            [
              _buildTextField(
                controller: _fazlaMesaiFizikselController,
                label: 'Fiziksel İş Çarpanı',
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _fazlaMesaiZihinselController,
                label: 'Zihinsel İş Çarpanı',
                icon: Icons.psychology,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          _buildCard(
            'Çalışma Saatleri',
            [
              _buildTextField(
                controller: _gunlukCalismaSaatiController,
                label: 'Günlük Çalışma Saati',
                icon: Icons.access_time,
                keyboardType: TextInputType.number,
                suffixText: 'saat',
              ),
              _buildTextField(
                controller: _haftalikCalismaSaatiController,
                label: 'Haftalık Çalışma Saati',
                icon: Icons.date_range,
                keyboardType: TextInputType.number,
                suffixText: 'saat',
              ),
              _buildTextField(
                controller: _aylikCalismaSaatiController,
                label: 'Aylık Çalışma Saati',
                icon: Icons.calendar_month,
                keyboardType: TextInputType.number,
                suffixText: 'saat',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Ücret Çarpanları',
            [
              _buildTextField(
                controller: _mesaiUcretKatsayiController,
                label: 'Mesai Ücreti Katsayısı',
                icon: Icons.calculate,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _gece2230_0600Controller,
                label: 'Gece Vardiyası (22:30-06:00)',
                icon: Icons.nightlight,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _pazarTatilController,
                label: 'Pazar/Tatil Çarpanı',
                icon: Icons.weekend,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _resmiTatilController,
                label: 'Resmi Tatil Çarpanı',
                icon: Icons.celebration,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          _buildCard(
            'Yıllık İzin Hakları (Gün)',
            [
              _buildTextField(
                controller: _yillikIzinController,
                label: 'Yıllık İzin',
                icon: Icons.beach_access,
                keyboardType: TextInputType.number,
                suffixText: 'gün',
              ),
              _buildTextField(
                controller: _hastalikIzinController,
                label: 'Hastalık İzni',
                icon: Icons.local_hospital,
                keyboardType: TextInputType.number,
                suffixText: 'gün',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Özel İzinler (Gün)',
            [
              _buildTextField(
                controller: _dogumIzinController,
                label: 'Doğum İzni',
                icon: Icons.child_friendly,
                keyboardType: TextInputType.number,
                suffixText: 'gün',
              ),
              _buildTextField(
                controller: _babalikIzinController,
                label: 'Babalık İzni',
                icon: Icons.family_restroom,
                keyboardType: TextInputType.number,
                suffixText: 'gün',
              ),
              _buildTextField(
                controller: _evlilikIzinController,
                label: 'Evlilik İzni',
                icon: Icons.favorite,
                keyboardType: TextInputType.number,
                suffixText: 'gün',
              ),
              _buildTextField(
                controller: _olumIzinController,
                label: 'Ölüm İzni',
                icon: Icons.sentiment_very_dissatisfied,
                keyboardType: TextInputType.number,
                suffixText: 'gün',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Diğer İzinler (Gün)',
            [
              _buildTextField(
                controller: _askerlikIzinController,
                label: 'Askerlik İzni',
                icon: Icons.security,
                keyboardType: TextInputType.number,
                suffixText: 'gün',
              ),
              _buildTextField(
                controller: _mazeretIzinController,
                label: 'Mazeret İzni',
                icon: Icons.help_outline,
                keyboardType: TextInputType.number,
                suffixText: 'gün',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? suffixText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          suffixText: suffixText,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFDCE7FF),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
