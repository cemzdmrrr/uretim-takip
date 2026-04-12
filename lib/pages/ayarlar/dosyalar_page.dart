import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class DosyalarPage extends StatefulWidget {
  const DosyalarPage({super.key});

  @override
  State<DosyalarPage> createState() => _DosyalarPageState();
}

class _DosyalarPageState extends State<DosyalarPage> {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> dosyalar = [];
  String? aktifKlasorId;
  String aktifKlasorYolu = 'Ana Dizin';
  List<Map<String, dynamic>> breadcrumb = [];
  bool yukleniyor = true;
  bool dosyaYukleniyor = false;
  
  String aramaMetni = '';
  String siralamaKriteri = 'ad'; // 'ad', 'tarih', 'boyut', 'tur'
  bool azalanSiralama = false;
  String filtreTuru = 'hepsi'; // 'hepsi', 'pdf', 'folder', 'doc', 'xls', 'image'

  @override
  void initState() {
    super.initState();
    dosyalariGetir();
  }

  Future<void> dosyalariGetir({String? klasorId}) async {
    setState(() => yukleniyor = true);
    
    try {
      var query = supabase
          .from(DbTables.dosyalar)
          .select('''
            id,
            ad,
            dosya_turu,
            boyut,
            yol,
            ust_klasor_id,
            aciklama,
            olusturan_kullanici_id,
            olusturma_tarihi,
            guncelleme_tarihi,
            genel_erisim,
            son_erisim_tarihi,
            erisim_sayisi,
            mime_type
          ''')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .eq('aktif', true);

      if (klasorId != null) {
        query = query.eq('ust_klasor_id', klasorId);
      } else {
        query = query.isFilter('ust_klasor_id', null);
      }

      final response = await query.order('dosya_turu').order(siralamaKriteri, ascending: !azalanSiralama);
      
      setState(() {
        dosyalar = List<Map<String, dynamic>>.from(response);
        aktifKlasorId = klasorId;
        yukleniyor = false;
      });
      
      // Breadcrumb güncelle
      await breadcrumbGuncelle(klasorId);
      
    } catch (e) {
      if (!mounted) return;
      setState(() => yukleniyor = false);
      debugPrint('DOSYALAR YÜKLEME HATASI: $e'); // Debug için
      if (!mounted) return;
      context.showSnackBar('Dosyalar yüklenirken hata: $e');
    }
  }

  Future<void> breadcrumbGuncelle(String? klasorId) async {
    breadcrumb.clear();
    breadcrumb.add({'ad': 'Ana Dizin', 'id': null});
    
    if (klasorId != null) {
      // Üst klasörleri bul
      String? ustKlasorId = klasorId;
      final List<Map<String, dynamic>> ustKlasorler = [];
      
      while (ustKlasorId != null) {
        final klasor = await supabase
            .from(DbTables.dosyalar)
            .select('id, ad, ust_klasor_id')
            .eq('id', ustKlasorId)
            .single();
            
        ustKlasorler.insert(0, klasor);
        ustKlasorId = klasor['ust_klasor_id'];
      }
      
      breadcrumb.addAll(ustKlasorler);
    }
    
    aktifKlasorYolu = breadcrumb.map((e) => e['ad']).join(' > ');
    setState(() {});
  }

  Future<void> dosyaYukle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => dosyaYukleniyor = true);
      
      try {
        final file = result.files.first;
        final fileBytes = file.bytes!;
        final fileName = file.name;
        final extension = fileName.split('.').last.toLowerCase();
        
        // Dosya yolunu oluştur
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = aktifKlasorId != null 
            ? 'folders/$aktifKlasorId/${timestamp}_$fileName'
            : 'files/${timestamp}_$fileName';

        // Supabase Storage'a yükle
        await supabase.storage
            .from(DbTables.dosyalar)
            .uploadBinary(storagePath, fileBytes);

        // Veritabanına kaydet
        await supabase.from(DbTables.dosyalar).insert({
          'ad': fileName,
          'dosya_turu': _getDosyaTuru(extension),
          'boyut': file.size,
          'yol': storagePath,
          'ust_klasor_id': aktifKlasorId,
          'mime_type': _getMimeType(extension),
          'olusturan_kullanici_id': supabase.auth.currentUser?.id,
        });

        if (!mounted) return;
        context.showSnackBar('Dosya başarıyla yüklendi');
        
        dosyalariGetir(klasorId: aktifKlasorId);
        
      } catch (e) {
        if (!mounted) return;
        context.showSnackBar('Dosya yüklenirken hata: $e');
      } finally {
        setState(() => dosyaYukleniyor = false);
      }
    }
  }

  String _getDosyaTuru(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return 'pdf';
      case 'doc':
      case 'docx': return 'doc';
      case 'xls':
      case 'xlsx': return 'xls';
      case 'jpg':
      case 'jpeg':
      case 'png': return 'image';
      default: return 'pdf';
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }

  Future<void> yeniKlasorOlustur() async {
    final TextEditingController controller = TextEditingController();
    
    final sonuc = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Klasör'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Klasör Adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (sonuc != null && sonuc.isNotEmpty) {
      try {
        await supabase.from(DbTables.dosyalar).insert({
          'ad': sonuc,
          'dosya_turu': 'folder',
          'boyut': 0,
          'yol': 'folders/${DateTime.now().millisecondsSinceEpoch}_$sonuc/',
          'ust_klasor_id': aktifKlasorId,
          'olusturan_kullanici_id': supabase.auth.currentUser?.id,
        });

        if (!mounted) return;
        context.showSnackBar('Klasör başarıyla oluşturuldu');
        
        dosyalariGetir(klasorId: aktifKlasorId);
        
      } catch (e) {
        if (!mounted) return;
        context.showSnackBar('Klasör oluşturulurken hata: $e');
      }
    }
  }

  Future<void> dosyaAc(Map<String, dynamic> dosya) async {
    if (dosya['dosya_turu'] == 'folder') {
      // Klasöre gir
      dosyalariGetir(klasorId: dosya['id']);
    } else {
      // Dosyayı aç
      try {
        // Erişim sayısını artır
        await supabase
            .from(DbTables.dosyalar)
            .update({
              'erisim_sayisi': (dosya['erisim_sayisi'] ?? 0) + 1,
              'son_erisim_tarihi': DateTime.now().toIso8601String(),
            })
            .eq('id', dosya['id']);

        // Dosya URL'ini al (public bucket için)
        final url = supabase.storage
            .from(DbTables.dosyalar)
            .getPublicUrl(dosya['yol']);

        // Dosyayı aç
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          context.showSnackBar('Dosya açılamadı');
        }
      } catch (e) {
        if (!mounted) return;
        context.showSnackBar('Dosya açılırken hata: $e');
      }
    }
  }

  Future<void> dosyaYenidenAdlandir(Map<String, dynamic> dosya) async {
    final TextEditingController controller = TextEditingController(text: dosya['ad']);
    
    final sonuc = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Yeni Ad',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (sonuc != null && sonuc.isNotEmpty && sonuc != dosya['ad']) {
      try {
        await supabase
            .from(DbTables.dosyalar)
            .update({'ad': sonuc})
            .eq('id', dosya['id']);

        if (!mounted) return;
        context.showSnackBar('Dosya yeniden adlandırıldı');
        
        dosyalariGetir(klasorId: aktifKlasorId);
        
      } catch (e) {
        if (!mounted) return;
        context.showSnackBar('Yeniden adlandırma hatası: $e');
      }
    }
  }

  Future<void> dosyaSil(Map<String, dynamic> dosya) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dosya Sil'),
        content: Text('${dosya['ad']} dosyasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        // Soft delete
        await supabase
            .from(DbTables.dosyalar)
            .update({
              'aktif': false,
              'guncelleme_tarihi': DateTime.now().toIso8601String(),
            })
            .eq('id', dosya['id']);

        // Storage'dan da sil
        if (dosya['dosya_turu'] != 'folder') {
          await supabase.storage
              .from(DbTables.dosyalar)
              .remove([dosya['yol']]);
        }

        if (!mounted) return;
        context.showSnackBar('Dosya silindi');
        
        dosyalariGetir(klasorId: aktifKlasorId);
        
      } catch (e) {
        if (!mounted) return;
        context.showSnackBar('Silme hatası: $e');
      }
    }
  }

  List<Map<String, dynamic>> get filtreliDosyalar {
    var sonuc = List<Map<String, dynamic>>.from(dosyalar);
    
    // Arama filtresi
    if (aramaMetni.isNotEmpty) {
      sonuc = sonuc.where((dosya) =>
          dosya['ad'].toString().toLowerCase().contains(aramaMetni.toLowerCase())).toList();
    }
    
    // Tür filtresi
    if (filtreTuru != 'hepsi') {
      if (filtreTuru == 'image') {
        sonuc = sonuc.where((dosya) => ['jpg', 'jpeg', 'png'].contains(dosya['dosya_turu'])).toList();
      } else {
        sonuc = sonuc.where((dosya) => dosya['dosya_turu'] == filtreTuru).toList();
      }
    }
    
    return sonuc;
  }

  IconData _getDosyaIkonu(String dosyaTuru) {
    switch (dosyaTuru) {
      case 'folder': return Icons.folder;
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': return Icons.description;
      case 'xls': return Icons.table_chart;
      case 'image': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getDosyaRengi(String dosyaTuru) {
    switch (dosyaTuru) {
      case 'folder': return Colors.blue;
      case 'pdf': return Colors.red;
      case 'doc': return Colors.blue;
      case 'xls': return Colors.green;
      case 'image': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _formatBoyut(int? boyut) {
    if (boyut == null || boyut == 0) return '';
    
    if (boyut < 1024) return '$boyut B';
    if (boyut < 1024 * 1024) return '${(boyut / 1024).toStringAsFixed(1)} KB';
    if (boyut < 1024 * 1024 * 1024) return '${(boyut / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(boyut / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosya Yönetimi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            tooltip: 'Yeni Klasör',
            onPressed: yeniKlasorOlustur,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Dosya Yükle',
            onPressed: dosyaYukleniyor ? null : dosyaYukle,
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Icon(Icons.folder_open, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    aktifKlasorYolu,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (aktifKlasorId != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Geri',
                    onPressed: () {
                      final ustKlasor = breadcrumb.length > 1 
                          ? breadcrumb[breadcrumb.length - 2]
                          : null;
                      dosyalariGetir(klasorId: ustKlasor?['id']);
                    },
                  ),
              ],
            ),
          ),
          
          // Arama ve filtreler
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Dosya ara...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => aramaMetni = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tür',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: filtreTuru,
                    items: const [
                      DropdownMenuItem(value: 'hepsi', child: Text('Hepsi')),
                      DropdownMenuItem(value: 'folder', child: Text('Klasörler')),
                      DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      DropdownMenuItem(value: 'doc', child: Text('Word')),
                      DropdownMenuItem(value: 'xls', child: Text('Excel')),
                      DropdownMenuItem(value: 'image', child: Text('Resim')),
                    ],
                    onChanged: (value) => setState(() => filtreTuru = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sırala',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: siralamaKriteri,
                    items: const [
                      DropdownMenuItem(value: 'ad', child: Text('İsim')),
                      DropdownMenuItem(value: 'olusturma_tarihi', child: Text('Tarih')),
                      DropdownMenuItem(value: 'boyut', child: Text('Boyut')),
                      DropdownMenuItem(value: 'dosya_turu', child: Text('Tür')),
                    ],
                    onChanged: (value) {
                      setState(() => siralamaKriteri = value!);
                      dosyalariGetir(klasorId: aktifKlasorId);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(azalanSiralama ? Icons.arrow_downward : Icons.arrow_upward),
                  onPressed: () {
                    setState(() => azalanSiralama = !azalanSiralama);
                    dosyalariGetir(klasorId: aktifKlasorId);
                  },
                ),
              ],
            ),
          ),
          
          // Dosya listesi
          Expanded(
            child: yukleniyor
                ? const LoadingWidget()
                : dosyaYukleniyor
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Dosya yükleniyor...'),
                          ],
                        ),
                      )
                    : filtreliDosyalar.isEmpty
                        ? const Center(child: Text('Dosya bulunamadı'))
                        : ListView.builder(
                            itemCount: filtreliDosyalar.length,
                            itemBuilder: (context, index) {
                              final dosya = filtreliDosyalar[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: Icon(
                                    _getDosyaIkonu(dosya['dosya_turu']),
                                    color: _getDosyaRengi(dosya['dosya_turu']),
                                    size: 32,
                                  ),
                                  title: Text(
                                    dosya['ad'],
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (dosya['aciklama'] != null)
                                        Text(dosya['aciklama']),
                                      Row(
                                        children: [
                                          Text(
                                            DateFormat('dd.MM.yyyy HH:mm')
                                                .format(DateTime.parse(dosya['olusturma_tarihi'])),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (dosya['boyut'] != null && dosya['boyut'] > 0) ...[
                                            const Text(' • '),
                                            Text(
                                              _formatBoyut(dosya['boyut']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                          if (dosya['erisim_sayisi'] != null && dosya['erisim_sayisi'] > 0) ...[
                                            const Text(' • '),
                                            Text(
                                              '${dosya['erisim_sayisi']} görüntüleme',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'ac',
                                        child: Row(
                                          children: [
                                            Icon(Icons.open_in_new),
                                            SizedBox(width: 8),
                                            Text('Aç'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'yeniden_adlandir',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit),
                                            SizedBox(width: 8),
                                            Text('Yeniden Adlandır'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'sil',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Sil', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'ac':
                                          dosyaAc(dosya);
                                          break;
                                        case 'yeniden_adlandir':
                                          dosyaYenidenAdlandir(dosya);
                                          break;
                                        case 'sil':
                                          dosyaSil(dosya);
                                          break;
                                      }
                                    },
                                  ),
                                  onTap: () => dosyaAc(dosya),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
