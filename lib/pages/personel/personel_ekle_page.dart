import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/supabase_config.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class PersonelEklePage extends StatefulWidget {
  final PersonelModel? mevcut;
  final String? userId; // Kullanıcıdan gelen userId
  const PersonelEklePage({super.key, this.mevcut, this.userId});

  @override
  State<PersonelEklePage> createState() => _PersonelEklePageState();
}

class _PersonelEklePageState extends State<PersonelEklePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController adController;
  late TextEditingController soyadController;
  late TextEditingController tcknController;
  late TextEditingController pozisyonController;
  late TextEditingController departmanController;
  late TextEditingController emailController;
  late TextEditingController telefonController;
  late TextEditingController iseBaslangicController;
  late TextEditingController brutMaasController;
  late TextEditingController sgkSicilNoController;
  late TextEditingController gunlukCalismaSaatiController;
  late TextEditingController haftalikCalismaGunuController;
  late TextEditingController yolUcretiController;
  late TextEditingController yemekUcretiController;
  late TextEditingController ekstraPrimController;
  late TextEditingController eldenMaasController;
  late TextEditingController bankaMaasController;
  late TextEditingController adresController;
  late TextEditingController netMaasController;
  late TextEditingController yillikIzinHakkiController;
  late TextEditingController passwordController;
  String seciliRol = DbTables.personel;
  bool yolUcretiVar = false;
  bool yemekUcretiVar = false;
  bool ekstraPrimVar = false;
  bool eldenMaasVar = false;

  @override
  void initState() {
    super.initState();
    adController = TextEditingController(text: widget.mevcut?.ad ?? '');
    soyadController = TextEditingController(text: widget.mevcut?.soyad ?? '');
    tcknController = TextEditingController(text: widget.mevcut?.tckn ?? '');
    pozisyonController = TextEditingController(text: widget.mevcut?.pozisyon ?? '');
    departmanController = TextEditingController(text: widget.mevcut?.departman ?? '');
    emailController = TextEditingController(text: widget.mevcut?.email ?? '');
    telefonController = TextEditingController(text: widget.mevcut?.telefon ?? '');
    iseBaslangicController = TextEditingController(text: widget.mevcut?.iseBaslangic ?? '');
    brutMaasController = TextEditingController(text: widget.mevcut?.brutMaas ?? '');
    sgkSicilNoController = TextEditingController(text: widget.mevcut?.sgkSicilNo ?? '');
    gunlukCalismaSaatiController = TextEditingController(text: widget.mevcut?.gunlukCalismaSaati ?? '');
    haftalikCalismaGunuController = TextEditingController(text: widget.mevcut?.haftalikCalismaGunu ?? '');
    yolUcretiController = TextEditingController(text: widget.mevcut?.yolUcreti ?? '');
    yemekUcretiController = TextEditingController(text: widget.mevcut?.yemekUcreti ?? '');
    ekstraPrimController = TextEditingController(text: widget.mevcut?.ekstraPrim ?? '');
    eldenMaasController = TextEditingController(text: widget.mevcut?.eldenMaas ?? '');
    bankaMaasController = TextEditingController(text: widget.mevcut?.bankaMaas ?? '');
    adresController = TextEditingController(text: widget.mevcut?.adres ?? '');
    netMaasController = TextEditingController(text: widget.mevcut?.netMaas ?? '');
    yillikIzinHakkiController = TextEditingController(text: widget.mevcut?.yillikIzinHakki ?? '14');
    passwordController = TextEditingController();
    seciliRol = DbTables.personel;
    yolUcretiVar = widget.mevcut?.yolUcreti != null && widget.mevcut!.yolUcreti != '';
    yemekUcretiVar = widget.mevcut?.yemekUcreti != null && widget.mevcut!.yemekUcreti != '';
    ekstraPrimVar = widget.mevcut?.ekstraPrim != null && widget.mevcut!.ekstraPrim != '';
    eldenMaasVar = widget.mevcut?.eldenMaas != null && widget.mevcut!.eldenMaas != '';
  }

  @override
  void dispose() {
    adController.dispose();
    soyadController.dispose();
    tcknController.dispose();
    pozisyonController.dispose();
    departmanController.dispose();
    emailController.dispose();
    telefonController.dispose();
    iseBaslangicController.dispose();
    brutMaasController.dispose();
    sgkSicilNoController.dispose();
    gunlukCalismaSaatiController.dispose();
    haftalikCalismaGunuController.dispose();
    yolUcretiController.dispose();
    yemekUcretiController.dispose();
    ekstraPrimController.dispose();
    eldenMaasController.dispose();
    bankaMaasController.dispose();
    adresController.dispose();
    netMaasController.dispose();
    yillikIzinHakkiController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool duzenleme = widget.mevcut != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(duzenleme ? Icons.edit : Icons.person_add, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              duzenleme ? 'Personel Düzenle' : 'Yeni Personel Ekle',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header bilgi kartı
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      duzenleme ? 'Personel Bilgilerini Güncelle' : 'Yeni Personel Kaydı',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      duzenleme 
                                        ? 'Mevcut personel bilgilerini güncelleyin.'
                                        : 'Tüm gerekli alanları doldurarak yeni personel ekleyin.',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Ana form alanları
                  isMobile 
                    ? _buildMobileLayout(duzenleme)
                    : _buildDesktopLayout(duzenleme),
                  
                  const SizedBox(height: 32),
                  
                  // Kaydet butonu
                  _buildSaveButton(duzenleme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool duzenleme) {
    return Column(
      children: [
        _buildKisiselBilgilerSection(duzenleme),
        const SizedBox(height: 20),
        _buildIletisimSection(),
        const SizedBox(height: 20),
        _buildIsBilgileriSection(),
        const SizedBox(height: 20),
        _buildMaasBilgileriSection(),
        const SizedBox(height: 20),
        _buildEkOdemelerSection(),
      ],
    );
  }

  Widget _buildDesktopLayout(bool duzenleme) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildKisiselBilgilerSection(duzenleme)),
            const SizedBox(width: 20),
            Expanded(child: _buildIletisimSection()),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildIsBilgileriSection()),
            const SizedBox(width: 20),
            Expanded(child: _buildMaasBilgileriSection()),
          ],
        ),
        const SizedBox(height: 20),
        _buildEkOdemelerSection(),
      ],
    );
  }
  Widget _buildKisiselBilgilerSection(bool duzenleme) {
    return _buildSection(
      title: 'Kişisel Bilgiler',
      icon: Icons.person,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: adController,
                label: 'Ad',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: soyadController,
                label: 'Soyad',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: tcknController,
          label: 'TCKN',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          enabled: !duzenleme,
          validator: (v) => v == null || v.length != 11 ? '11 haneli TCKN giriniz' : null,
        ),
        if (!duzenleme) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: emailController,
            label: 'E-posta (Kullanıcı Girişi)',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty ? 'E-posta zorunlu' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: passwordController,
            label: 'Parola',
            icon: Icons.lock,
            obscureText: true,
            validator: (v) => v == null || v.length < 6 ? 'En az 6 karakterli parola girin' : null,
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: adresController,
          label: 'Adres',
          icon: Icons.home,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildIletisimSection() {
    return _buildSection(
      title: 'İletişim Bilgileri',
      icon: Icons.contact_phone,
      children: [
        _buildTextField(
          controller: emailController,
          label: 'E-posta',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: telefonController,
          label: 'Telefon',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildIsBilgileriSection() {
    return _buildSection(
      title: 'İş Bilgileri',
      icon: Icons.work,
      children: [
        _buildTextField(
          controller: pozisyonController,
          label: 'Pozisyon',
          icon: Icons.badge,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: departmanController,
          label: 'Departman',
          icon: Icons.apartment,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: iseBaslangicController,
          label: 'İşe Başlangıç Tarihi (GG.AA.YYYY)',
          icon: Icons.calendar_today,
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: sgkSicilNoController,
          label: 'SGK Sicil No',
          icon: Icons.card_membership,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: gunlukCalismaSaatiController,
                label: 'Günlük Çalışma Saati',
                icon: Icons.schedule,
                keyboardType: TextInputType.number,
                suffix: 'saat',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: haftalikCalismaGunuController,
                label: 'Haftalık Çalışma Günü',
                icon: Icons.date_range,
                keyboardType: TextInputType.number,
                suffix: 'gün',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: yillikIzinHakkiController,
          label: 'Yıllık İzin Hakkı',
          icon: Icons.beach_access,
          keyboardType: TextInputType.number,
          suffix: 'gün',
        ),
      ],
    );
  }

  Widget _buildMaasBilgileriSection() {
    return _buildSection(
      title: 'Maaş Bilgileri',
      icon: Icons.attach_money,
      children: [
        _buildTextField(
          controller: brutMaasController,
          label: 'Brüt Maaş',
          icon: Icons.money,
          keyboardType: TextInputType.number,
          suffix: '₺',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: netMaasController,
          label: 'Net Maaş',
          icon: Icons.account_balance_wallet,
          keyboardType: TextInputType.number,
          suffix: '₺',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: bankaMaasController,
                label: 'Bankadan Alınan Tutar',
                icon: Icons.account_balance,
                keyboardType: TextInputType.number,
                suffix: '₺',
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calculate, color: Colors.blue.shade700),
              ),
              tooltip: 'Elden maaşı otomatik hesapla',
              onPressed: () {
                final net = double.tryParse(netMaasController.text) ?? 0;
                final banka = double.tryParse(bankaMaasController.text) ?? 0;
                if (net > 0 && banka >= 0) {
                  final elden = (net - banka).toStringAsFixed(2);
                  eldenMaasController.text = (elden == '0.00' || net < banka) ? '' : elden;
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: eldenMaasController,
          label: 'Elden Maaş',
          icon: Icons.money_off,
          keyboardType: TextInputType.number,
          suffix: '₺',
        ),
      ],
    );
  }
  Widget _buildEkOdemelerSection() {
    return _buildSection(
      title: 'Ek Ödemeler',
      icon: Icons.add_card,
      children: [
        // Yol Ücreti
        _buildSwitchTile(
          title: 'Yol Ücreti',
          subtitle: 'Aylık yol ücreti veriliyor mu?',
          value: yolUcretiVar,
          onChanged: (v) => setState(() => yolUcretiVar = v),
          icon: Icons.directions_car,
        ),
        if (yolUcretiVar) ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: yolUcretiController,
            label: 'Aylık Yol Ücreti',
            icon: Icons.directions_car,
            keyboardType: TextInputType.number,
            suffix: '₺',
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Yemek Ücreti
        _buildSwitchTile(
          title: 'Yemek Ücreti',
          subtitle: 'Aylık yemek ücreti veriliyor mu?',
          value: yemekUcretiVar,
          onChanged: (v) => setState(() => yemekUcretiVar = v),
          icon: Icons.restaurant,
        ),
        if (yemekUcretiVar) ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: yemekUcretiController,
            label: 'Aylık Yemek Ücreti',
            icon: Icons.restaurant,
            keyboardType: TextInputType.number,
            suffix: '₺',
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Ekstra Prim
        _buildSwitchTile(
          title: 'Ekstra Prim',
          subtitle: 'Aylık ekstra prim veriliyor mu?',
          value: ekstraPrimVar,
          onChanged: (v) => setState(() => ekstraPrimVar = v),
          icon: Icons.star,
        ),
        if (ekstraPrimVar) ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: ekstraPrimController,
            label: 'Aylık Ekstra Prim',
            icon: Icons.star,
            keyboardType: TextInputType.number,
            suffix: '₺',
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    bool enabled = true,
    int maxLines = 1,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.blue.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? Colors.blue.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? Colors.blue.shade700 : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blue.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool duzenleme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState?.validate() ?? false) {
            await _savePersonel(duzenleme);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(duzenleme ? Icons.update : Icons.save),
            const SizedBox(width: 8),
            Text(
              duzenleme ? 'Bilgileri Güncelle' : 'Personeli Kaydet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePersonel(bool duzenleme) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Kaydediliyor...'),
                ],
              ),
            ),
          ),
        ),
      );

      final eldenMaasDegeri = eldenMaasVar ? eldenMaasController.text : '';
      String userId = widget.userId ?? '';
      
      // Eğer yeni personel ekleniyorsa önce kullanıcı oluştur
      if (!duzenleme && userId.isEmpty) {
        try {
          // Admin kontrolü
          final currentUser = Supabase.instance.client.auth.currentUser;
          final adminCheck = currentUser != null ? await Supabase.instance.client
            .from(DbTables.userRoles)
            .select('role, aktif')
            .eq('user_id', currentUser.id)
            .maybeSingle() : null;
          if (currentUser == null || adminCheck == null || adminCheck['role'] != 'admin' || adminCheck['aktif'] != true) {
            if (!mounted) return;
            Navigator.pop(context); // Loading'i kapat
            context.showErrorSnackBar('Bu işlemi yapmak için yetkiniz yok.');
            return;
          }
          
          // Kullanıcı oluştur (adminClient ile)
          final adminClient = SupabaseConfig.adminClient;
          final response = await adminClient.auth.admin.createUser(
            AdminUserAttributes(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              emailConfirm: true,
            ),
          );
          if (response.user != null) {
            userId = response.user!.id;
            // user_roles tablosuna ekle
            await Supabase.instance.client.from(DbTables.userRoles).insert({
              'user_id': userId,
              'role': DbTables.personel,
              'aktif': true,
            });
          } else {
            if (!mounted) return;
            Navigator.pop(context); // Loading'i kapat
            context.showErrorSnackBar('Kullanıcı oluşturulamadı');
            return;
          }
        } catch (e) {
          if (e is AuthException && e.code == 'user_already_exists') {
            // Kullanıcı zaten varsa userId'yi bul ve user_roles tablosuna ekle
            final existingUser = await Supabase.instance.client
              .from(DbTables.users)
              .select('id')
              .eq('email', emailController.text.trim())
              .single();
            userId = existingUser['id'];
            await Supabase.instance.client.from(DbTables.userRoles).insert({
              'user_id': userId,
              'role': DbTables.personel,
              'aktif': true,
            });
          } else {
            if (!mounted) return;
            Navigator.pop(context); // Loading'i kapat
            context.showErrorSnackBar('Kullanıcı oluşturulamadı: $e');
            return;
          }
        }
      }

      // Personeli firma_kullanicilari'na ekle
      if (!duzenleme && userId.isNotEmpty) {
        try {
          final firmaId = TenantManager.instance.firmaId;
          if (firmaId != null) {
            await Supabase.instance.client.from(DbTables.firmaKullanicilari).upsert({
              'firma_id': firmaId,
              'user_id': userId,
              'rol': 'personel',
              'aktif': true,
            }, onConflict: 'firma_id,user_id');
            debugPrint('✅ Personel firmaya eklendi: $firmaId');
          }
        } catch (e) {
          debugPrint('⚠️ firma_kullanicilari ekleme hatası: $e');
        }
      }
      
      // İşe giriş tarihi formatını kontrol et ve kaydet
      String iseBaslangic = iseBaslangicController.text.trim();
      // GG.AA.YYYY formatı ise YYYY-MM-DD'ye çevir
      if (iseBaslangic.contains('.') && iseBaslangic.length == 10) {
        final parts = iseBaslangic.split('.');
        if (parts.length == 3) {
          iseBaslangic = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
      
      final yeniPersonel = PersonelModel(
        userId: userId,
        ad: adController.text,
        soyad: soyadController.text,
        tckn: tcknController.text,
        pozisyon: pozisyonController.text,
        departman: departmanController.text,
        email: emailController.text,
        telefon: telefonController.text,
        iseBaslangic: iseBaslangic,
        brutMaas: brutMaasController.text,
        sgkSicilNo: sgkSicilNoController.text,
        gunlukCalismaSaati: gunlukCalismaSaatiController.text,
        haftalikCalismaGunu: haftalikCalismaGunuController.text,
        yolUcreti: yolUcretiVar ? yolUcretiController.text : '',
        yemekUcreti: yemekUcretiVar ? yemekUcretiController.text : '',
        ekstraPrim: ekstraPrimVar ? ekstraPrimController.text : '',
        eldenMaas: (eldenMaasDegeri.isEmpty || num.tryParse(eldenMaasDegeri) == null) ? '0' : eldenMaasDegeri,
        bankaMaas: bankaMaasController.text,
        adres: adresController.text,
        netMaas: netMaasController.text,
        yillikIzinHakki: yillikIzinHakkiController.text,
      );
      
      if (duzenleme) {
        await PersonelService().updatePersonel(yeniPersonel);
        if (!mounted) return;
        Navigator.pop(context); // Loading'i kapat
        Navigator.pop(context, yeniPersonel);
      } else {
        await PersonelService().addPersonel(yeniPersonel);
        if (!mounted) return;
        Navigator.pop(context); // Loading'i kapat
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(duzenleme ? 'Personel güncellendi.' : 'Personel kaydedildi.'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      // Personel ekleme işlemi tamamlandıktan sonra kendi users tablosuna da kayıt ekle/güncelle
      if (!duzenleme && userId.isNotEmpty) {
        try {
          // Her durumda role alanını zorunlu olarak güncelle
          await Supabase.instance.client
            .from(DbTables.users)
            .upsert({
              'id': userId,
              'email': emailController.text.trim(),
              'role': DbTables.personel,
            }, onConflict: 'id');
        } catch (e) {
          debugPrint('Kendi users tablosuna upsert hatası: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Loading'i kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Hata: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
