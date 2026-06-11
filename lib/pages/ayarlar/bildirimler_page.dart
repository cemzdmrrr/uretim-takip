import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/bildirim_navigation_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Gelişmiş Bildirimler Sayfası
class BildirimlerPage extends StatefulWidget {
  const BildirimlerPage({super.key});

  @override
  State<BildirimlerPage> createState() => _BildirimlerPageState();
}

class _BildirimlerPageState extends State<BildirimlerPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _bildirimService = BildirimService();

  late TabController _tabController;
  List<Map<String, dynamic>> _tumBildirimler = [];
  List<Map<String, dynamic>> _okunmamisBildirimler = [];
  bool _isLoading = true;
  String _selectedFilter = 'tumu';
  String? _userRole;

  final List<Map<String, dynamic>> _filterOptions = [
    {'value': 'tumu', 'label': 'Tümü', 'icon': Icons.all_inbox},
    {
      'value': 'atama_bekliyor',
      'label': 'Atama Bekliyor',
      'icon': Icons.pending_actions
    },
    {
      'value': 'atama_onaylandi',
      'label': 'Onaylanan',
      'icon': Icons.check_circle
    },
    {'value': 'atama_reddedildi', 'label': 'Reddedilen', 'icon': Icons.cancel},
    {'value': 'uretim_tamamlandi', 'label': 'Üretim', 'icon': Icons.done_all},
    {'value': 'kalite_onay', 'label': 'Kalite', 'icon': Icons.verified},
    {
      'value': 'sevkiyat_hazir',
      'label': 'Sevkiyat',
      'icon': Icons.local_shipping
    },
    {'value': 'izin_talebi', 'label': 'İzin', 'icon': Icons.event_available},
    {'value': 'mesai_talebi', 'label': 'Mesai', 'icon': Icons.more_time},
    {'value': 'avans_talebi', 'label': 'Avans', 'icon': Icons.payments},
    {'value': 'stok_uyari', 'label': 'Stok', 'icon': Icons.inventory},
    {'value': 'termin_uyari', 'label': 'Termin', 'icon': Icons.schedule},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBildirimler();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBildirimler() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Kullanıcı rolünü al
      final userRole = await _supabase
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', currentUser.id)
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .maybeSingle();

      _userRole = userRole?['role'];

      List<Map<String, dynamic>> bildirimler;

      if (_userRole == 'admin') {
        // Admin tüm bildirimleri görür
        final response = await _supabase
            .from(DbTables.bildirimler)
            .select('*')
            .eq('firma_id', TenantManager.instance.requireFirmaId)
            .order('created_at', ascending: false)
            .limit(200);
        bildirimler = List<Map<String, dynamic>>.from(response);
      } else {
        // Normal kullanıcı kendi bildirimlerini görür
        bildirimler = await _bildirimService.tumBildirimleriGetir(
          currentUser.id,
          limit: 200,
        );
      }

      setState(() {
        _tumBildirimler = bildirimler;
        _okunmamisBildirimler =
            bildirimler.where((b) => b['okundu'] == false).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Bildirimler yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredBildirimler {
    final list =
        _tabController.index == 0 ? _tumBildirimler : _okunmamisBildirimler;
    if (_selectedFilter == 'tumu') return list;
    return list.where((b) => b['tip'] == _selectedFilter).toList();
  }

  Future<void> _markAsRead(String bildirimId) async {
    await _bildirimService.bildirimOkundu(bildirimId);
    await _loadBildirimler();
  }

  Future<void> _handleBildirimTap(Map<String, dynamic> bildirim) async {
    final bildirimId = bildirim['id']?.toString();
    if (bildirim['okundu'] == false && bildirimId != null) {
      await _markAsRead(bildirimId);
    }
    if (!mounted) return;

    final navigated = BildirimNavigationService.navigate(context, bildirim);
    if (!navigated) {
      _showBildirimDetay(bildirim);
    }
  }

  Future<void> _markAllAsRead() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    await _bildirimService.tumBildirimlerOkundu(currentUser.id);
    await _loadBildirimler();

    if (mounted) {
      context.showSuccessSnackBar('Tüm bildirimler okundu olarak işaretlendi');
    }
  }

  Future<void> _deleteBildirim(String bildirimId) async {
    try {
      await _supabase.from(DbTables.bildirimler).delete().eq('id', bildirimId);
      await _loadBildirimler();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bildirim silindi'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint('❌ Bildirim silme hatası: $e');
    }
  }

  Future<void> _deleteAllRead() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_sweep, color: Colors.orange.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Okunanları Sil'),
          ],
        ),
        content: const Text(
            'Tüm okunmuş bildirimler silinecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final currentUser = _supabase.auth.currentUser;
        if (currentUser == null) return;

        await _supabase
            .from(DbTables.bildirimler)
            .delete()
            .eq('user_id', currentUser.id)
            .eq('okundu', true);

        await _loadBildirimler();

        if (mounted) {
          context.showSuccessSnackBar('Okunmuş bildirimler silindi');
        }
      } catch (e) {
        debugPrint('❌ Toplu silme hatası: $e');
      }
    }
  }

  Future<void> _showYeniBildirimDialog() async {
    final baslikController = TextEditingController();
    final mesajController = TextEditingController();
    final aramaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final currentUser = _supabase.auth.currentUser;
    List<Map<String, dynamic>> kullanicilar = [];
    final Set<String> seciliUserIds = {};
    bool tumFirma = false;
    bool gonderiliyor = false;
    String arama = '';

    try {
      kullanicilar = await _bildirimService.aktifFirmaKullanicilariniGetir();
    } catch (e) {
      debugPrint('Alıcı listesi yüklenemedi: $e');
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
            final filtreliKullanicilar = kullanicilar.where((k) {
              final metin = [
                k['tam_ad'],
                k['email'],
                k['departman'],
                k['role'],
                k['user_id'],
              ].whereType<Object>().join(' ').toLowerCase();
              return metin.contains(arama.toLowerCase());
            }).toList();

            Future<void> gonder() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final alicilar = tumFirma
                  ? kullanicilar.map((k) => k['user_id'].toString()).toList()
                  : seciliUserIds.toList();
              if (alicilar.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('En az bir alıcı seçin')),
                );
                return;
              }

              setDialogState(() => gonderiliyor = true);
              try {
                await _bildirimService.kullanicilaraBildirimGonder(
                  userIds: alicilar,
                  baslik: baslikController.text.trim(),
                  mesaj: mesajController.text.trim(),
                  tip: 'genel',
                  ekBilgi: {
                    'sender_user_id': currentUser?.id,
                    'target': {
                      'type': 'genel',
                      'page': 'bildirim_detay',
                    },
                  },
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bildirim gönderildi')),
                );
                await _loadBildirimler();
              } catch (e) {
                debugPrint('Bildirim gönderme hatası: $e');
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Bildirim gönderilemedi: $e')),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => gonderiliyor = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Yeni Bildirim Gönder'),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: baslikController,
                          decoration: const InputDecoration(
                            labelText: 'Başlık',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Başlık girin'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: mesajController,
                          decoration: const InputDecoration(
                            labelText: 'Mesaj',
                            prefixIcon: Icon(Icons.notes),
                          ),
                          maxLines: 4,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Mesaj girin'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: tumFirma,
                          title: const Text('Tüm firmaya gönder'),
                          subtitle:
                              Text('${kullanicilar.length} aktif kullanıcı'),
                          onChanged: (value) {
                            setDialogState(() {
                              tumFirma = value;
                              if (value) seciliUserIds.clear();
                            });
                          },
                        ),
                        if (!tumFirma) ...[
                          TextField(
                            controller: aramaController,
                            decoration: const InputDecoration(
                              labelText: 'Kullanıcı ara',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) =>
                                setDialogState(() => arama = value),
                          ),
                          const SizedBox(height: 12),
                          if (seciliUserIds.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: seciliUserIds.map((userId) {
                                final kullanici = kullanicilar.firstWhere(
                                  (k) => k['user_id'].toString() == userId,
                                  orElse: () => {'user_id': userId},
                                );
                                final label = _kullaniciGorunenAdi(kullanici);
                                return InputChip(
                                  label: Text(label),
                                  onDeleted: () {
                                    setDialogState(() {
                                      seciliUserIds.remove(userId);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 260),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtreliKullanicilar.length,
                              itemBuilder: (context, index) {
                                final kullanici = filtreliKullanicilar[index];
                                final userId = kullanici['user_id'].toString();
                                final secili = seciliUserIds.contains(userId);
                                return CheckboxListTile(
                                  dense: true,
                                  value: secili,
                                  title: Text(_kullaniciGorunenAdi(kullanici)),
                                  subtitle: Text(
                                    [
                                      kullanici['departman'],
                                      kullanici['role'],
                                      kullanici['email'],
                                    ]
                                        .where((v) =>
                                            v != null &&
                                            v.toString().trim().isNotEmpty)
                                        .join(' • '),
                                  ),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        seciliUserIds.add(userId);
                                      } else {
                                        seciliUserIds.remove(userId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      gonderiliyor ? null : () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                ElevatedButton.icon(
                  onPressed: gonderiliyor ? null : gonder,
                  icon: gonderiliyor
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );

    baslikController.dispose();
    mesajController.dispose();
    aramaController.dispose();
  }

  String _kullaniciGorunenAdi(Map<String, dynamic> kullanici) {
    final tamAd = kullanici['tam_ad']?.toString() ?? '';
    if (tamAd.trim().isNotEmpty) return tamAd;
    final email = kullanici['email']?.toString() ?? '';
    if (email.trim().isNotEmpty) return email;
    return kullanici['user_id']?.toString() ?? 'Kullanıcı';
  }

  IconData _getBildirimIcon(String? tip) {
    switch (tip) {
      case 'atama_bekliyor':
        return Icons.pending_actions_rounded;
      case 'atama_onaylandi':
        return Icons.check_circle_rounded;
      case 'atama_reddedildi':
        return Icons.cancel_rounded;
      case 'uretim_tamamlandi':
        return Icons.done_all_rounded;
      case 'kalite_onay':
        return Icons.verified_rounded;
      case 'kalite_red':
        return Icons.thumb_down_rounded;
      case 'sevkiyat_hazir':
        return Icons.local_shipping_rounded;
      case 'stok_uyari':
        return Icons.inventory_rounded;
      case 'termin_uyari':
        return Icons.schedule_rounded;
      case 'izin_talebi':
        return Icons.event_available_rounded;
      case 'mesai_talebi':
        return Icons.more_time_rounded;
      case 'avans_talebi':
        return Icons.payments_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getBildirimColor(String? tip) {
    switch (tip) {
      case 'atama_bekliyor':
        return Colors.orange;
      case 'atama_onaylandi':
        return Colors.green;
      case 'atama_reddedildi':
        return Colors.red;
      case 'uretim_tamamlandi':
        return Colors.blue;
      case 'kalite_onay':
        return Colors.purple;
      case 'kalite_red':
        return Colors.red.shade700;
      case 'sevkiyat_hazir':
        return Colors.teal;
      case 'stok_uyari':
        return Colors.amber;
      case 'termin_uyari':
        return Colors.deepOrange;
      case 'izin_talebi':
        return Colors.indigo;
      case 'mesai_talebi':
        return Colors.cyan;
      case 'avans_talebi':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getBildirimTipLabel(String? tip) {
    switch (tip) {
      case 'atama_bekliyor':
        return 'Atama Bekliyor';
      case 'atama_onaylandi':
        return 'Atama Onaylandı';
      case 'atama_reddedildi':
        return 'Atama Reddedildi';
      case 'uretim_tamamlandi':
        return 'Üretim Tamamlandı';
      case 'kalite_onay':
        return 'Kalite Onay';
      case 'kalite_red':
        return 'Kalite Red';
      case 'sevkiyat_hazir':
        return 'Sevkiyat Hazır';
      case 'stok_uyari':
        return 'Stok Uyarısı';
      case 'termin_uyari':
        return 'Termin Uyarısı';
      case 'izin_talebi':
        return 'İzin Talebi';
      case 'mesai_talebi':
        return 'Mesai Talebi';
      case 'avans_talebi':
        return 'Avans Talebi';
      default:
        return 'Genel';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'Az önce';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} dakika önce';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} saat önce';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} gün önce';
      } else {
        return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (_) => setState(() {}),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.all_inbox, size: 18),
                  const SizedBox(width: 8),
                  Text('Tümü (${_tumBildirimler.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread, size: 18),
                  const SizedBox(width: 8),
                  Text('Okunmamış (${_okunmamisBildirimler.length})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Yeni Bildirim Gönder',
              onPressed: _showYeniBildirimDialog,
            ),
          if (_okunmamisBildirimler.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tümünü Okundu İşaretle',
              onPressed: _markAllAsRead,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete_read') {
                _deleteAllRead();
              } else if (value == 'refresh') {
                _loadBildirimler();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Yenile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Okunanları Sil'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre çubuğu
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(filter['label'] as String),
                        ],
                      ),
                      selectedColor: const Color(0xFF1565C0),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter['value'] as String;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          // Bildirimler listesi
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredBildirimler.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadBildirimler,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBildirimler.length,
                          itemBuilder: (context, index) {
                            final bildirim = _filteredBildirimler[index];
                            return _buildBildirimCard(bildirim);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _tabController.index == 0
                ? 'Henüz bildirim yok'
                : 'Okunmamış bildirim yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bildirimler burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBildirimCard(Map<String, dynamic> bildirim) {
    final isOkunmamis = bildirim['okundu'] == false;
    final tip = bildirim['tip'] as String?;
    final color = _getBildirimColor(tip);

    return Dismissible(
      key: Key(bildirim['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bildirimi Sil'),
            content: const Text('Bu bildirimi silmek istiyor musunuz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteBildirim(bildirim['id'].toString()),
      child: GestureDetector(
        onTap: () => _handleBildirimTap(bildirim),
        onLongPress: () => _showBildirimDetay(bildirim),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isOkunmamis
                ? Border.all(color: color.withValues(alpha: 0.3), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Sol kenar renk göstergesi
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getBildirimIcon(tip),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bildirim['baslik'] ?? 'Bildirim',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isOkunmamis
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              if (isOkunmamis)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bildirim['mesaj'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getBildirimTipLabel(tip),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(bildirim['created_at']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBildirimDetay(Map<String, dynamic> bildirim) {
    final tip = bildirim['tip'] as String?;
    final color = _getBildirimColor(tip);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.1), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getBildirimIcon(tip), color: color, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bildirim['baslik'] ?? 'Bildirim',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getBildirimTipLabel(tip),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bildirim['mesaj'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Meta bilgiler
                    if (bildirim['asama'] != null) ...[
                      _buildMetaItem(Icons.layers, 'Aşama', bildirim['asama']),
                    ],
                    if (bildirim['model_id'] != null) ...[
                      _buildMetaItem(
                          Icons.inventory_2, 'Model ID', bildirim['model_id']),
                    ],
                    _buildMetaItem(
                      Icons.schedule,
                      'Tarih',
                      _formatDate(bildirim['created_at']),
                    ),
                    _buildMetaItem(
                      bildirim['okundu'] == true
                          ? Icons.mark_email_read
                          : Icons.mark_email_unread,
                      'Durum',
                      bildirim['okundu'] == true ? 'Okundu' : 'Okunmadı',
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteBildirim(bildirim['id'].toString());
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Tamam'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
