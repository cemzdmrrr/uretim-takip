import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/pages/ayarlar/bildirimler_page.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Gelişmiş Bildirim popup widget'ı - Ana sayfada ve panellerde kullanılır
class BildirimPopup extends StatefulWidget {
  const BildirimPopup({Key? key}) : super(key: key);

  @override
  State<BildirimPopup> createState() => _BildirimPopupState();
}

class _BildirimPopupState extends State<BildirimPopup> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _bildirimService = BildirimService();
  List<Map<String, dynamic>> _bildirimler = [];
  int _okunmamisSayisi = 0;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  StreamSubscription? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadBildirimler();
    _startRealtimeListener();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _startRealtimeListener() {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;
      
      String? firmaId;
      try {
        firmaId = TenantManager.instance.requireFirmaId;
      } catch (_) {
        return;
      }

      _realtimeSubscription = _supabase
          .from(DbTables.bildirimler)
          .stream(primaryKey: ['id'])
          .eq('firma_id', firmaId)
          .order('created_at', ascending: false)
          .limit(50)
          .listen((data) {
            if (!mounted) return;
            _processRealtimeData(List<Map<String, dynamic>>.from(data));
          }, onError: (e) {
            debugPrint('Bildirim realtime hatası: $e');
            // Fallback: periodic check
            _startPeriodicCheck();
          });
    } catch (e) {
      debugPrint('Realtime listener başlatılamadı: $e');
      _startPeriodicCheck();
    }
  }

  void _processRealtimeData(List<Map<String, dynamic>> data) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;
      
      final userRole = await _supabase
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', currentUser.id)
          .maybeSingle();
      
      List<Map<String, dynamic>> bildirimler;
      if (userRole != null && userRole['role'] == 'admin') {
        bildirimler = data;
      } else {
        bildirimler = data.where((b) => b['user_id'] == currentUser.id).toList();
      }
      
      final okunmamis = bildirimler.where((b) => b['okundu'] == false).length;
      final previousOkunmamis = _okunmamisSayisi;
      
      if (mounted) {
        setState(() {
          _bildirimler = bildirimler;
          _okunmamisSayisi = okunmamis;
        });
        
        if (okunmamis > previousOkunmamis && previousOkunmamis > 0) {
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
        }
      }
    } catch (e) {
      debugPrint('Realtime data processing hatası: $e');
    }
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadBildirimler();
        _startPeriodicCheck();
      }
    });
  }

  Future<void> _loadBildirimler() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      if (mounted) setState(() => _isLoading = true);

      // Admin ise tüm bildirimleri getir, değilse sadece kendi bildirimlerini
      final userRole = await _supabase
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      List<Map<String, dynamic>> bildirimler;
      
      String? firmaId;
      try {
        firmaId = TenantManager.instance.requireFirmaId;
      } catch (_) {
        firmaId = null;
      }
      
      if (userRole != null && userRole['role'] == 'admin' && firmaId != null) {
        // Admin firma bazında tüm bildirimleri görebilir
        final response = await _supabase
            .from(DbTables.bildirimler)
            .select('*')
            .eq('firma_id', firmaId)
            .order('created_at', ascending: false)
            .limit(50);
        bildirimler = List<Map<String, dynamic>>.from(response);
      } else {
        // Normal kullanıcı sadece kendi bildirimlerini görür
        bildirimler = await _bildirimService.tumBildirimleriGetir(currentUser.id);
      }

      final okunmamis = bildirimler.where((b) => b['okundu'] == false).length;
      final previousOkunmamis = _okunmamisSayisi;

      if (mounted) {
        setState(() {
          _bildirimler = bildirimler;
          _okunmamisSayisi = okunmamis;
          _isLoading = false;
        });

        // Yeni bildirim geldiyse animasyon göster
        if (okunmamis > previousOkunmamis && previousOkunmamis > 0) {
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Bildirimler yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String bildirimId) async {
    await _bildirimService.bildirimOkundu(bildirimId);
    await _loadBildirimler();
  }

  Future<void> _markAllAsRead() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    await _bildirimService.tumBildirimlerOkundu(currentUser.id);
    await _loadBildirimler();
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
      default:
        return Colors.grey;
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
        return '${diff.inMinutes} dk önce';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} saat önce';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} gün önce';
      } else {
        return '${date.day}.${date.month}.${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: PopupMenuButton<String>(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
              if (_okunmamisSayisi > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        _okunmamisSayisi > 99 ? '99+' : _okunmamisSayisi.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Bildirimler',
          onOpened: _loadBildirimler,
          offset: const Offset(0, 50),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: 380,
            minWidth: 340,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          color: Colors.white,
          itemBuilder: (context) {
            if (_isLoading) {
              return [
                const PopupMenuItem(
                  enabled: false,
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Yükleniyor...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ];
            }

            final List<PopupMenuEntry<String>> items = [];

            // Başlık
            items.add(
              PopupMenuItem(
                enabled: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFF1565C0),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Bildirimler',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (_okunmamisSayisi > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_okunmamisSayisi yeni',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );

            items.add(const PopupMenuDivider(height: 1));

            if (_bildirimler.isEmpty) {
              items.add(
                const PopupMenuItem(
                  enabled: false,
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Bildirim yok',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              // Bildirimler listesi
              for (var bildirim in _bildirimler.take(8)) {
                final isOkunmamis = bildirim['okundu'] == false;
                final tip = bildirim['tip'] as String?;
                final color = _getBildirimColor(tip);
                
                items.add(
                  PopupMenuItem(
                    value: bildirim['id'].toString(),
                    padding: EdgeInsets.zero,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOkunmamis ? color.withValues(alpha: 0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isOkunmamis 
                            ? Border.all(color: color.withValues(alpha: 0.2))
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getBildirimIcon(tip),
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                          fontWeight: isOkunmamis ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isOkunmamis)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bildirim['mesaj'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(bildirim['created_at']),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
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
                  ),
                );
              }
            }

            items.add(const PopupMenuDivider(height: 1));

            // Alt butonlar
            items.add(
              PopupMenuItem(
                enabled: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      if (_okunmamisSayisi > 0)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _markAllAsRead();
                            },
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text('Tümünü Oku', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BildirimlerPage()),
                            );
                          },
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Tümünü Gör', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            return items;
          },
          onSelected: (bildirimId) {
            _markAsRead(bildirimId);
          },
        ),
      ),
    );
  }
}
