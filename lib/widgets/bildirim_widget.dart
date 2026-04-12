// İstenen iş akışı için bildirim widget'ı
// Bu widget, tüm sistem bildirimlerini gösterir

import 'dart:async';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BildirimWidget extends StatefulWidget {
  final String? kullaniciRolu;

  const BildirimWidget({
    Key? key, 
    this.kullaniciRolu,
  }) : super(key: key);

  @override
  State<BildirimWidget> createState() => _BildirimWidgetState();
}

class _BildirimWidgetState extends State<BildirimWidget> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bildirimler = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _bildirimleriGetir();
  }

  Future<void> _bildirimleriGetir() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from(DbTables.bildirimler)
          .select('''
            *,
            model:triko_takip(id, marka, item_no)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        bildirimler = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Bildirim getirme hatası: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _bildirimOkunduIsaretle(String bildirimId) async {
    try {
      await supabase
          .from(DbTables.bildirimler)
          .update({'okundu': true})
          .eq('id', bildirimId);
      
      if (!mounted) return;
      setState(() {
        final index = bildirimler.indexWhere((b) => b['id'] == bildirimId);
        if (index != -1) {
          bildirimler[index]['okundu'] = true;
        }
      });
    } catch (e) {
      debugPrint('Bildirim okundu işaretleme hatası: $e');
    }
  }

  Future<void> _tumBildirimleriOkunduIsaretle() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from(DbTables.bildirimler)
          .update({'okundu': true})
          .eq('user_id', user.id)
          .eq('okundu', false);
      
      if (!mounted) return;
      setState(() {
        for (var bildirim in bildirimler) {
          bildirim['okundu'] = true;
        }
      });

      if (mounted) {
        context.showSuccessSnackBar('Tüm bildirimler okundu olarak işaretlendi');
      }
    } catch (e) {
      debugPrint('Toplu bildirim okundu hatası: $e');
    }
  }

  Widget _buildBildirimItem(Map<String, dynamic> bildirim) {
    final tip = bildirim['tip'] ?? '';
    final okundu = bildirim['okundu'] ?? false;
    final tarih = bildirim['created_at'] != null 
        ? DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(bildirim['created_at']))
        : '';

    Color tipRengi = Colors.blue;
    IconData tipIcon = Icons.info;
    
    switch (tip) {
      case 'atama_bekliyor':
        tipRengi = Colors.orange;
        tipIcon = Icons.assignment_outlined;
        break;
      case 'atama_onaylandi':
        tipRengi = Colors.green;
        tipIcon = Icons.check_circle_outline;
        break;
      case 'atama_reddedildi':
        tipRengi = Colors.red;
        tipIcon = Icons.cancel_outlined;
        break;
      case 'uretim_tamamlandi':
        tipRengi = Colors.purple;
        tipIcon = Icons.done_all;
        break;
      case 'kalite_onay':
        tipRengi = Colors.teal;
        tipIcon = Icons.verified_outlined;
        break;
      case 'kalite_red':
        tipRengi = Colors.red;
        tipIcon = Icons.warning_outlined;
        break;
      case 'sevkiyat_hazir':
        tipRengi = Colors.indigo;
        tipIcon = Icons.local_shipping_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: okundu ? 1 : 3,
      color: okundu ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: () {
          if (!okundu) {
            _bildirimOkunduIsaretle(bildirim['id']);
          }
          // Model detayına git (opsiyonel)
          if (bildirim['model_id'] != null) {
            // Navigator.push context ile model detayına gidebilir
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tipRengi.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tipIcon,
                  color: tipRengi,
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
                              fontWeight: okundu ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!okundu)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bildirim['mesaj'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    if (bildirim['model'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Model: ${bildirim['model']['marka']} - ${bildirim['model']['item_no']}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      tarih,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirimler')),
        body: const LoadingWidget(),
      );
    }

    final okunmamisSayi = bildirimler.where((b) => !(b['okundu'] ?? false)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bildirimler ${okunmamisSayi > 0 ? '($okunmamisSayi)' : ''}'),
        actions: [
          if (okunmamisSayi > 0)
            TextButton(
              onPressed: _tumBildirimleriOkunduIsaretle,
              child: const Text(
                'Tümünü Okundu İşaretle',
                style: TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            onPressed: _bildirimleriGetir,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: bildirimler.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz bildiriminiz yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _bildirimleriGetir,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bildirimler.length,
                itemBuilder: (context, index) {
                  return _buildBildirimItem(bildirimler[index]);
                },
              ),
            ),
    );
  }
}

// Bildirim sayısını gösteren badge widget'ı
class BildirimBadge extends StatefulWidget {
  final Widget child;

  const BildirimBadge({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<BildirimBadge> createState() => _BildirimBadgeState();
}

class _BildirimBadgeState extends State<BildirimBadge> {
  final supabase = Supabase.instance.client;
  int okunmamisSayi = 0;

  @override
  void initState() {
    super.initState();
    _okunmamisSayisiniGetir();
    
    // Her 30 saniyede bir kontrol et
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _okunmamisSayisiniGetir();
    });
  }

  Future<void> _okunmamisSayisiniGetir() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from(DbTables.bildirimler)
          .select('id')
          .eq('user_id', user.id)
          .eq('okundu', false);

      if (mounted) {
        setState(() {
          okunmamisSayi = response.length;
        });
      }
    } catch (e) {
      debugPrint('Okunmamış bildirim sayısı getirme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (okunmamisSayi == 0) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Text(
              okunmamisSayi > 99 ? '99+' : okunmamisSayi.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
